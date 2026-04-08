package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.DefectReasonDAO;
import pms.model.DefectReasonDTO;

/**
 * DefectReasonController – Servlet quản lý Nguyên Nhân Lỗi (Defect Reason).
 *
 * LƯU Ý: Đây là phiên bản CŨ / đơn giản hơn của DefectController.
 * Không có flash message, không có bộ lọc keyword, không có validate tên rỗng.
 * Các action forward đến các JSP riêng (updateDefectReason.jsp, listDefectReason.jsp).
 *
 * Chức năng:
 *   - listDefectReason     : Hiển thị tất cả nguyên nhân lỗi
 *   - addDefectReason      : Thêm nguyên nhân lỗi mới
 *   - deleteDefectReason   : Xóa nguyên nhân lỗi theo defectId
 *   - loadUpdateDefectReason: Tải form sửa nguyên nhân lỗi
 *   - saveUpdateDefectReason: Lưu tên mới sau khi sửa
 *
 * Toàn bộ lỗi được bắt và in ra console (chưa có phản hồi người dùng).
 */
public class DefectReasonController extends HttpServlet {

    /**
     * Điểm xử lý chung. Mọi lỗi được bắt tại try-catch đầu và chỉ printStackTrace.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định "listDefectReason"
        String action = request.getParameter("action");
        if (action == null) action = "listDefectReason";

        DefectReasonDAO dao = new DefectReasonDAO(); // DAO cho bảng DefectReason

        try {
            switch (action) {

                case "listDefectReason": {
                    // Tải toàn bộ nguyên nhân lỗi (không có lọc keyword)
                    List<DefectReasonDTO> list = dao.getAllDefectReasons();
                    request.setAttribute("listDefect", list);
                    request.getRequestDispatcher("listDefectReason.jsp").forward(request, response);
                    break;
                }

                case "addDefectReason": {
                    // Thêm nguyên nhân lỗi mới; không validate tên rỗng (phiên bản cũ)
                    String addName = request.getParameter("reasonName"); // Tên nguyên nhân
                    dao.insertDefectReasons(new DefectReasonDTO(0, addName)); // id=0 → DB tự sinh
                    response.sendRedirect("MainController?action=listDefectReason");
                    break;
                }

                case "deleteDefectReason": {
                    // Xóa nguyên nhân lỗi; không kiểm tra foreign key (phiên bản cũ)
                    int delId = Integer.parseInt(request.getParameter("defectId"));
                    dao.deleteDefectReasons(new DefectReasonDTO(delId, "")); // tên rỗng vì chỉ cần ID
                    response.sendRedirect("MainController?action=listDefectReason");
                    break;
                }

                case "loadUpdateDefectReason": {
                    // Tải form sửa; forward đến trang riêng updateDefectReason.jsp
                    int updId = Integer.parseInt(request.getParameter("defectId"));
                    request.setAttribute("defectEdit", dao.getDefectReasonById(updId));
                    request.getRequestDispatcher("updateDefectReason.jsp").forward(request, response);
                    break;
                }

                case "saveUpdateDefectReason": {
                    // Lưu tên mới của nguyên nhân lỗi
                    int uId      = Integer.parseInt(request.getParameter("defectId")); // ID cần cập nhật
                    String uName = request.getParameter("reasonName");                  // Tên mới
                    dao.updateDefectReasons(new DefectReasonDTO(uId, uName));
                    response.sendRedirect("MainController?action=listDefectReason");
                    break;
                }
            }

        } catch (Exception e) {
            // Chỉ in lỗi ra console, chưa có thông báo cho người dùng
            e.printStackTrace();
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

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Defect Reason Controller";
    }
}
