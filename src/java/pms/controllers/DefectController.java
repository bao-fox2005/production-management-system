package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.DefectReasonDAO;
import pms.model.DefectReasonDTO;

/**
 * DefectController – Servlet quản lý Nguyên Nhân Lỗi Sản Phẩm (Defect Reason).
 *
 * Nguyên nhân lỗi (DefectReason) là danh mục dùng để phân loại các lỗi
 * phát sinh trong quá trình sản xuất (ví dụ: "Lỗi cắt", "Lỗi hàn", "Lỗi sơn"…).
 * Danh mục này được dùng khi nhật ký QC ghi nhận sản phẩm lỗi.
 *
 * Chức năng:
 *   - list / listDefectReason: Xem và tìm kiếm nguyên nhân lỗi
 *   - searchDefectReason     : Redirect về list với keyword
 *   - addDefectReason        : Thêm nguyên nhân lỗi mới
 *   - deleteDefectReason     : Xóa nguyên nhân lỗi
 *   - loadUpdateDefectReason : Tải thông tin lên form sửa
 *   - saveUpdateDefectReason : Lưu thay đổi tên nguyên nhân lỗi
 *
 * URL mapping: /DefectController
 * Sử dụng flash message (session) để truyền thông báo qua redirect.
 */
@WebServlet(name = "DefectController", urlPatterns = {"/DefectController"})
public class DefectController extends HttpServlet {

    /**
     * Điểm xử lý chung. Tất cả lỗi bắt buộc redirect về listDefectReason với flash error.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "listDefectReason"
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) action = "listDefectReason";
        action = action.trim();

        DefectReasonDAO dao = new DefectReasonDAO(); // DAO để thao tác với bảng DefectReason

        try {
            switch (action) {

                case "listDefectReason":
                case "listDefect":
                case "list": {
                    // Hiển thị danh sách nguyên nhân lỗi, lọc theo keyword
                    String keyword = normalize(request.getParameter("keyword")); // Từ khóa tìm kiếm
                    List<DefectReasonDTO> list = dao.getAllDefectReasons(); // Lấy tất cả từ DB

                    // Lọc client-side nếu có keyword (không phân biệt hoa thường)
                    if (!keyword.isEmpty()) {
                        String normalizedKeyword = keyword.toLowerCase();
                        list.removeIf(d -> d == null
                                || d.getReasonName() == null
                                || !d.getReasonName().toLowerCase().contains(normalizedKeyword));
                    }

                    request.setAttribute("keyword", keyword);                           // Giữ keyword trên form
                    request.setAttribute("listD",   list);                             // Danh sách kết quả
                    request.setAttribute("msg",     consumeFlash(request, "defectReasonMsg"));   // Flash thành công
                    request.setAttribute("error",   consumeFlash(request, "defectReasonError")); // Flash lỗi
                    request.getRequestDispatcher("listDefectReason.jsp").forward(request, response);
                    break;
                }

                case "searchDefectReason":
                case "search":
                    // Redirect về list với keyword được encode an toàn vào URL
                    response.sendRedirect("DefectController?action=listDefectReason&keyword="
                            + java.net.URLEncoder.encode(normalize(request.getParameter("keyword")), "UTF-8"));
                    break;

                case "addDefectReason": {
                    // Thêm nguyên nhân lỗi mới
                    String reasonName = normalize(request.getParameter("reasonName")); // Tên nguyên nhân

                    if (reasonName.isEmpty()) {
                        // Validate: tên không được rỗng
                        setFlash(request, "defectReasonError", "Tên nguyên nhân lỗi không được để trống.");

                    } else if (dao.insertDefectReasons(new DefectReasonDTO(0, reasonName))) {
                        // INSERT thành công (id=0 → DB tự sinh)
                        setFlash(request, "defectReasonMsg", "Đã thêm nguyên nhân lỗi thành công.");

                    } else {
                        // INSERT thất bại (trùng tên hoặc lỗi DB)
                        setFlash(request, "defectReasonError", "Không thể thêm nguyên nhân lỗi.");
                    }

                    response.sendRedirect("DefectController?action=listDefectReason");
                    break;
                }

                case "deleteDefectReason": {
                    // Xóa nguyên nhân lỗi theo defectId
                    int delId = Integer.parseInt(request.getParameter("defectId"));

                    // DefectReasonDTO(id, null) – tên null vì chỉ cần ID để xóa
                    if (dao.deleteDefectReasons(new DefectReasonDTO(delId, null))) {
                        setFlash(request, "defectReasonMsg", "Đã xóa nguyên nhân lỗi thành công.");
                    } else {
                        // Thất bại: có thể do khóa ngoại (lỗi này đang được dùng ở màn hình khác)
                        setFlash(request, "defectReasonError",
                            "Không thể xóa nguyên nhân lỗi này. Dữ liệu có thể đang được sử dụng ở màn hình khác.");
                    }

                    response.sendRedirect("DefectController?action=listDefectReason");
                    break;
                }

                case "loadUpdateDefectReason": {
                    // Tải thông tin nguyên nhân lỗi cần sửa lên form edit inline
                    String keyword = normalize(request.getParameter("keyword")); // Giữ keyword hiện tại của trang

                    DefectReasonDTO defectEdit = dao.getDefectReasonById(
                            Integer.parseInt(request.getParameter("defectId"))); // Lấy defect cần edit

                    if (defectEdit == null) {
                        // Không tìm thấy → flash error và về danh sách
                        setFlash(request, "defectReasonError", "Không tìm thấy nguyên nhân lỗi cần sửa.");
                        response.sendRedirect("DefectController?action=listDefectReason");
                        break;
                    }

                    // Lấy danh sách và lọc theo keyword đang có
                    List<DefectReasonDTO> list = dao.getAllDefectReasons();
                    if (!keyword.isEmpty()) {
                        String normalizedKeyword = keyword.toLowerCase();
                        list.removeIf(d -> d == null
                                || d.getReasonName() == null
                                || !d.getReasonName().toLowerCase().contains(normalizedKeyword));
                    }

                    request.setAttribute("defectEdit", defectEdit); // Item đang được edit
                    request.setAttribute("listD",      list);
                    request.setAttribute("keyword",    keyword);
                    request.setAttribute("msg",        consumeFlash(request, "defectReasonMsg"));
                    request.setAttribute("error",      consumeFlash(request, "defectReasonError"));
                    request.getRequestDispatcher("listDefectReason.jsp").forward(request, response);
                    break;
                }

                case "saveUpdateDefectReason": {
                    // Lưu tên nguyên nhân lỗi đã chỉnh sửa
                    int uId           = Integer.parseInt(request.getParameter("defectId")); // ID cần cập nhật
                    String reasonName = normalize(request.getParameter("reasonName"));      // Tên mới

                    if (reasonName.isEmpty()) {
                        setFlash(request, "defectReasonError", "Tên nguyên nhân lỗi không được để trống.");

                    } else if (dao.updateDefectReasons(new DefectReasonDTO(uId, reasonName))) {
                        setFlash(request, "defectReasonMsg", "Đã cập nhật nguyên nhân lỗi thành công.");

                    } else {
                        setFlash(request, "defectReasonError", "Không thể cập nhật nguyên nhân lỗi.");
                    }

                    response.sendRedirect("DefectController?action=listDefectReason");
                    break;
                }

                default:
                    response.sendRedirect("DefectController?action=listDefectReason");
                    break;
            }

        } catch (Exception e) {
            // Bất kỳ lỗi nào (parse số, DB…) → flash error và redirect về danh sách
            e.printStackTrace();
            setFlash(request, "defectReasonError", "Đã xảy ra lỗi khi xử lý nguyên nhân lỗi.");
            response.sendRedirect("DefectController?action=listDefectReason");
        }
    }

    /** Xử lý HTTP GET */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processRequest(req, resp);
    }

    /** Xử lý HTTP POST */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processRequest(req, resp);
    }

    /**
     * Làm sạch chuỗi: trim và trả về "" nếu null.
     *
     * @param value Chuỗi cần làm sạch
     * @return Chuỗi sau trim, không bao giờ null
     */
    private String normalize(String value) {
        return value != null ? value.trim() : "";
    }

    /**
     * Lưu flash message vào session để tồn tại qua redirect.
     *
     * @param request HttpServletRequest để lấy session
     * @param key     Tên key trong session
     * @param value   Nội dung thông báo
     */
    private void setFlash(HttpServletRequest request, String key, String value) {
        request.getSession().setAttribute(key, value); // Lưu vào session
    }

    /**
     * Đọc và xóa flash message từ session (one-time use).
     *
     * @param request HttpServletRequest để lấy session
     * @param key     Tên key trong session
     * @return Nội dung thông báo, hoặc null nếu không có
     */
    private String consumeFlash(HttpServletRequest request, String key) {
        Object value = request.getSession().getAttribute(key);
        if (value != null) {
            request.getSession().removeAttribute(key); // Xóa sau khi đọc để không hiện lại
            return value.toString();
        }
        return null;
    }
}
