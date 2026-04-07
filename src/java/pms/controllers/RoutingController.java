package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.RoutingDAO;
import pms.model.RoutingDTO;
import pms.model.RoutingStepDAO;
import pms.model.RoutingStepDTO;

/**
 * RoutingController – Servlet quản lý Quy Trình Sản Xuất (Routing).
 *
 * Routing là tập hợp các bước sản xuất (RoutingStep) cần thực hiện để tạo ra một sản phẩm.
 * Ví dụ: Routing "Lắp ráp xe đạp" gồm các bước: Hàn khung → Sơn → Lắp bánh → Kiểm tra.
 *
 * Chức năng:
 *   - listRouting / searchRouting : Xem và tìm kiếm quy trình
 *   - addRouting                  : Thêm quy trình mới
 *   - deleteRouting               : Xóa quy trình (nếu không còn được dùng)
 *   - loadUpdateRouting           : Tải thông tin quy trình lên form sửa
 *   - saveUpdateRouting           : Lưu thay đổi tên quy trình
 *   - viewRoutingDetail           : Xem chi tiết quy trình kèm danh sách bước
 *
 * Sử dụng session flash message (setFlash/consumeFlash) để truyền thông báo qua redirect.
 */
public class RoutingController extends HttpServlet {

    /**
     * Điểm xử lý chung cho mọi request.
     * Khởi tạo cả RoutingDAO và RoutingStepDAO dùng chung.
     * Tất cả lỗi đều redirect về listRouting với flash error.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "listRouting"
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "listRouting";
        }
        action = action.trim(); // Loại khoảng trắng thừa

        RoutingDAO dao       = new RoutingDAO();       // DAO cho bảng Routing
        RoutingStepDAO stepDao = new RoutingStepDAO(); // DAO cho bảng RoutingStep

        try {
            switch (action) {

                case "listRouting":
                case "list":
                case "searchRouting": {
                    // Tìm kiếm quy trình theo tên keyword (hoặc hiển thị tất cả nếu không có)
                    String keyword = normalize(request.getParameter("keyword")); // Từ khóa đã làm sạch
                    List<RoutingDTO> list = getFilteredRoutingList(dao, keyword); // Lọc danh sách

                    // Giữ lại keyword để hiển thị lại trên ô tìm kiếm
                    request.setAttribute("keyword", keyword);

                    // Đọc flash message từ session (đặt bởi các action redirect về đây)
                    request.setAttribute("msg",   consumeFlash(request, "routingMsg"));
                    request.setAttribute("error", consumeFlash(request, "routingError"));

                    request.setAttribute("listRouting", list);
                    request.getRequestDispatcher("listRouting.jsp").forward(request, response);
                    break;
                }

                case "addRouting": {
                    // Thêm quy trình mới với tên được cung cấp
                    String addName = normalize(request.getParameter("routingName")); // Tên quy trình

                    if (addName.isEmpty()) {
                        // Validate: tên không được rỗng
                        setFlash(request, "routingError", "Tên quy trình không được để trống.");

                    } else if (dao.insertRouting(new RoutingDTO(0, addName))) {
                        // INSERT thành công → flash message thành công
                        setFlash(request, "routingMsg", "Đã thêm quy trình thành công.");

                    } else {
                        // INSERT thất bại (trùng tên hoặc lỗi DB)
                        setFlash(request, "routingError", "Không thể thêm quy trình.");
                    }

                    // Redirect để ngăn F5 submit lại
                    response.sendRedirect("RoutingController?action=listRouting");
                    break;
                }

                case "deleteRouting": {
                    // Xóa quy trình theo routingId
                    int delId = Integer.parseInt(request.getParameter("routingId"));

                    // RoutingDTO(id, "") – tên rỗng vì chỉ cần ID để xóa
                    if (dao.deleteRouting(new RoutingDTO(delId, ""))) {
                        setFlash(request, "routingMsg", "Đã xóa quy trình thành công.");
                    } else {
                        // Thất bại thường do có WorkOrder đang dùng routing này (foreign key)
                        setFlash(request, "routingError",
                            "Không thể xóa quy trình này. Dữ liệu có thể đang được sử dụng ở công đoạn khác.");
                    }

                    response.sendRedirect("RoutingController?action=listRouting");
                    break;
                }

                case "loadUpdateRouting": {
                    // Tải thông tin quy trình cần sửa và hiển thị form edit inline trên trang danh sách
                    int updId   = Integer.parseInt(request.getParameter("routingId"));
                    String keyword = normalize(request.getParameter("keyword")); // Giữ keyword hiện tại

                    RoutingDTO routingEdit = dao.getRoutingById(updId); // Lấy routing cần edit
                    if (routingEdit == null) {
                        // Không tìm thấy → báo lỗi và về danh sách
                        setFlash(request, "routingError", "Không tìm thấy quy trình cần cập nhật.");
                        response.sendRedirect("RoutingController?action=listRouting");
                        break;
                    }

                    List<RoutingDTO> list = getFilteredRoutingList(dao, keyword);
                    request.setAttribute("routingEdit", routingEdit); // Item đang được edit (để hiện modal/form)
                    request.setAttribute("keyword",     keyword);
                    request.setAttribute("msg",         consumeFlash(request, "routingMsg"));
                    request.setAttribute("error",       consumeFlash(request, "routingError"));
                    request.setAttribute("listRouting", list);
                    request.getRequestDispatcher("listRouting.jsp").forward(request, response);
                    break;
                }

                case "viewRoutingDetail": {
                    // Xem chi tiết quy trình: tên quy trình + danh sách các bước (RoutingStep)
                    int routingId      = Integer.parseInt(request.getParameter("routingId"));
                    String keyword     = normalize(request.getParameter("keyword"));

                    RoutingDTO routingDetail = dao.getRoutingById(routingId); // Lấy thông tin routing
                    if (routingDetail == null) {
                        setFlash(request, "routingError", "Không tìm thấy quy trình cần xem chi tiết.");
                        response.sendRedirect("RoutingController?action=listRouting");
                        break;
                    }

                    List<RoutingDTO> list = getFilteredRoutingList(dao, keyword);

                    // Lấy tất cả các bước của routing này (sắp xếp theo thứ tự bước)
                    List<RoutingStepDTO> routingSteps = stepDao.getRoutingStepsByRoutingId(routingId);

                    request.setAttribute("routingDetail", routingDetail); // Thông tin quy trình
                    request.setAttribute("routingSteps",  routingSteps);  // Danh sách bước chi tiết
                    request.setAttribute("keyword",       keyword);
                    request.setAttribute("msg",           consumeFlash(request, "routingMsg"));
                    request.setAttribute("error",         consumeFlash(request, "routingError"));
                    request.setAttribute("listRouting",   list);
                    request.getRequestDispatcher("listRouting.jsp").forward(request, response);
                    break;
                }

                case "saveUpdateRouting": {
                    // Lưu tên quy trình đã chỉnh sửa
                    int uId       = Integer.parseInt(request.getParameter("routingId")); // ID quy trình
                    String uName  = normalize(request.getParameter("routingName"));     // Tên mới

                    if (uName.isEmpty()) {
                        setFlash(request, "routingError", "Tên quy trình không được để trống.");
                    } else if (dao.updateRouting(new RoutingDTO(uId, uName))) {
                        // UPDATE thành công
                        setFlash(request, "routingMsg", "Đã cập nhật quy trình thành công.");
                    } else {
                        setFlash(request, "routingError", "Không thể cập nhật quy trình.");
                    }

                    response.sendRedirect("RoutingController?action=listRouting");
                    break;
                }

                default:
                    // Action không xác định → về danh sách
                    response.sendRedirect("RoutingController?action=listRouting");
                    break;
            }

        } catch (Exception e) {
            // Mọi lỗi (parse số, DB…) → flash error và redirect về danh sách
            e.printStackTrace();
            setFlash(request, "routingError", "Đã xảy ra lỗi khi xử lý quy trình sản xuất.");
            response.sendRedirect("RoutingController?action=listRouting");
        }
    }

    /** Xử lý HTTP GET */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả servlet */
    @Override
    public String getServletInfo() {
        return "Routing Controller";
    }

    /**
     * Làm sạch chuỗi: trim và trả về chuỗi rỗng nếu null.
     * Dùng để xử lý mọi tham số chuỗi nhận từ request.
     *
     * @param value Chuỗi đầu vào (có thể null)
     * @return Chuỗi sau khi trim, không bao giờ null
     */
    private String normalize(String value) {
        return value != null ? value.trim() : "";
    }

    /**
     * Lấy danh sách toàn bộ Routing rồi lọc theo keyword.
     * Nếu keyword rỗng thì trả về toàn bộ danh sách.
     *
     * @param dao     RoutingDAO để query DB
     * @param keyword Từ khóa tìm kiếm (đã trim, có thể rỗng)
     * @return Danh sách Routing khớp keyword
     */
    private List<RoutingDTO> getFilteredRoutingList(RoutingDAO dao, String keyword) {
        List<RoutingDTO> list = dao.getAllRouting(); // Lấy tất cả quy trình
        if (!keyword.isEmpty()) {
            String normalizedKeyword = keyword.toLowerCase();
            // Loại bỏ các phần tử không chứa keyword trong tên quy trình
            list.removeIf(r -> r == null
                    || r.getRoutingName() == null
                    || !r.getRoutingName().toLowerCase().contains(normalizedKeyword));
        }
        return list;
    }

    /**
     * Lưu một flash message vào session với key cụ thể.
     * Flash message tồn tại qua redirect và bị xóa sau khi đọc (consumeFlash).
     *
     * @param request HttpServletRequest để lấy session
     * @param key     Tên attribute trong session
     * @param value   Nội dung thông báo
     */
    private void setFlash(HttpServletRequest request, String key, String value) {
        request.getSession().setAttribute(key, value); // Lưu vào session để tồn tại qua redirect
    }

    /**
     * Đọc và XÓA flash message từ session (one-time read).
     * Sau khi đọc, attribute bị xóa khỏi session để tránh hiển thị lại lần sau.
     *
     * @param request HttpServletRequest để lấy session
     * @param key     Tên attribute trong session
     * @return Nội dung thông báo, hoặc null nếu không có
     */
    private String consumeFlash(HttpServletRequest request, String key) {
        Object value = request.getSession().getAttribute(key);
        if (value != null) {
            request.getSession().removeAttribute(key); // Xóa sau khi đọc (flash = chỉ hiển thị 1 lần)
            return value.toString();
        }
        return null; // Không có flash message
    }
}
