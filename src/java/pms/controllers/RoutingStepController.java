package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
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
 * RoutingStepController – Servlet quản lý Bước Sản Xuất (Routing Step).
 *
 * Mỗi Routing gồm nhiều RoutingStep (bước) được thực hiện theo thứ tự.
 * Ví dụ: Routing "Lắp ráp xe đạp" → Step 1: Hàn khung, Step 2: Sơn, Step 3: Lắp bánh.
 *
 * Các action:
 *   - listRoutingStep / searchRoutingStep : Hiển thị, lọc theo tên bước và/hoặc routing
 *   - addRoutingStep                      : Thêm bước mới vào routing
 *   - deleteRoutingStep                   : Xóa bước theo stepId
 *   - loadUpdateRoutingStep               : Tải bước lên form sửa
 *   - saveUpdateRoutingStep               : Lưu thay đổi bước
 */
public class RoutingStepController extends HttpServlet {

    /**
     * Điểm xử lý chung. Khai báo cả RoutingStepDAO và RoutingDAO dùng chung.
     * Toàn bộ lỗi in ra console (chưa có flash message – hạn chế hiện tại).
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định "listRoutingStep"
        String action = request.getParameter("action");
        if (action == null || action.isEmpty()) {
            action = "listRoutingStep";
        }

        RoutingStepDAO dao = new RoutingStepDAO(); // DAO cho bảng RoutingStep
        RoutingDAO rDao    = new RoutingDAO();       // DAO cho bảng Routing (dropdown)

        try {
            switch (action) {

                case "listRoutingStep":
                case "searchRoutingStep": {
                    // Hiển thị danh sách bước, hỗ trợ lọc theo tên bước và/hoặc routing
                    String keyword         = request.getParameter("keyword");         // Từ khóa tên bước
                    String searchRoutingId = request.getParameter("searchRoutingId"); // Lọc theo routing

                    List<RoutingStepDTO> listStep    = dao.getAllRoutingStep(); // Tất cả bước
                    List<RoutingDTO> listRouting     = rDao.getAllRouting();    // Tất cả routing cho dropdown

                    // Lọc client-side nếu có keyword hoặc searchRoutingId
                    if ((keyword != null && !keyword.trim().isEmpty())
                            || (searchRoutingId != null && !searchRoutingId.isEmpty())) {

                        String lowerKeyword = keyword != null ? keyword.toLowerCase() : "";
                        List<RoutingStepDTO> filtered = new ArrayList<>();

                        for (RoutingStepDTO s : listStep) {
                            String stepName = s.getStepName();

                            // Điều kiện 1: khớp keyword trong tên bước (bỏ qua nếu keyword rỗng)
                            boolean matchKeyword = (keyword == null || keyword.trim().isEmpty())
                                    || (stepName != null && stepName.toLowerCase().contains(lowerKeyword));

                            // Điều kiện 2: khớp routing ID (bỏ qua nếu không có searchRoutingId)
                            boolean matchRouting = (searchRoutingId == null || searchRoutingId.isEmpty())
                                    || String.valueOf(s.getRoutingId()).equals(searchRoutingId);

                            if (matchKeyword && matchRouting) {
                                filtered.add(s); // Đưa vào kết quả nếu khớp cả hai điều kiện
                            }
                        }
                        listStep = filtered; // Dùng danh sách đã lọc
                    }

                    request.setAttribute("listStep",      listStep);
                    request.setAttribute("listRouting",   listRouting);
                    request.setAttribute("keyword",       keyword != null ? keyword : ""); // Giữ lại keyword
                    request.setAttribute("searchRoutingId", searchRoutingId != null ? searchRoutingId : "");
                    request.getRequestDispatcher("listRoutingStep.jsp").forward(request, response);
                    break;
                }

                case "addRoutingStep": {
                    // Thêm bước mới; isInspected là checkbox (null = chưa tick = false)
                    int rId      = Integer.parseInt(request.getParameter("routingId"));  // Routing cha
                    String sName = request.getParameter("stepName");                      // Tên bước
                    int time     = Integer.parseInt(request.getParameter("estimatedTime")); // Thời gian ước tính (phút)
                    boolean isInsp = request.getParameter("isInspected") != null;         // Có phải bước kiểm tra không

                    // id=0 → DB tự sinh
                    dao.insertRoutingStep(new RoutingStepDTO(0, rId, sName, time, isInsp));
                    response.sendRedirect("MainController?action=listRoutingStep");
                    break;
                }

                case "deleteRoutingStep": {
                    // Xóa bước theo stepId
                    int delId = Integer.parseInt(request.getParameter("stepId"));
                    dao.deleteRoutingStep(delId); // Xóa khỏi DB
                    response.sendRedirect("MainController?action=listRoutingStep");
                    break;
                }

                case "loadUpdateRoutingStep": {
                    // Tải thông tin bước cần sửa lên form edit inline
                    int updId = Integer.parseInt(request.getParameter("stepId"));
                    request.setAttribute("stepEdit",    dao.getRoutingStepById(updId)); // Bước cần sửa
                    request.setAttribute("listStep",    dao.getAllRoutingStep());        // Danh sách còn lại
                    request.setAttribute("listRouting", rDao.getAllRouting());           // Dropdown routing
                    request.getRequestDispatcher("listRoutingStep.jsp").forward(request, response);
                    break;
                }

                case "saveUpdateRoutingStep": {
                    // Lưu thay đổi bước sản xuất
                    int uId      = Integer.parseInt(request.getParameter("stepId"));    // ID bước
                    int uRId     = Integer.parseInt(request.getParameter("routingId")); // Routing cha (có thể thay đổi)
                    String uName = request.getParameter("stepName");                    // Tên mới
                    int uTime    = Integer.parseInt(request.getParameter("estimatedTime")); // Thời gian mới
                    boolean uInsp = request.getParameter("isInspected") != null;           // Checkbox

                    dao.updateRoutingStep(new RoutingStepDTO(uId, uRId, uName, uTime, uInsp)); // UPDATE DB
                    response.sendRedirect("MainController?action=listRoutingStep");
                    break;
                }
            }

        } catch (Exception e) {
            // In stack trace để debug; chưa có flash message cho người dùng
            e.printStackTrace();
        }
    }

    /** Xử lý HTTP GET – xem danh sách, tải form sửa */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – thêm, xóa, cập nhật bước sản xuất */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}
