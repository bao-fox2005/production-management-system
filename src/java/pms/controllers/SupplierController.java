package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.SupplierDAO;
import pms.model.SupplierDTO;

/**
 * SupplierController – Servlet quản lý danh sách Nhà cung cấp (Supplier).
 *
 * Các chức năng:
 *   - listSupplier / searchSupplier : Hiển thị và tìm kiếm nhà cung cấp
 *   - addSupplier                   : Thêm nhà cung cấp mới
 *   - deleteSupplier                : Xóa nhà cung cấp theo ID
 *   - loadUpdateSupplier            : Tải thông tin nhà cung cấp lên form sửa
 *   - saveUpdateSupplier            : Lưu thay đổi nhà cung cấp
 *
 * URL mapping: /SupplierController
 */
@WebServlet(name = "SupplierController", urlPatterns = {"/SupplierController"})
public class SupplierController extends HttpServlet {

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Khai báo SupplierDAO dùng chung cho toàn bộ request.
     * Toàn bộ logic được bọc trong try-catch để tránh crash server khi có lỗi.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 cho response (request không cần vì dữ liệu form nhỏ)
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "listSupplier"
        String action = request.getParameter("action");
        if (action == null) action = "listSupplier";

        // Tạo DAO dùng chung cho mọi nhánh xử lý trong request này
        SupplierDAO sdao = new SupplierDAO();

        try {
            switch (action) {

                case "listSupplier":
                case "searchSupplier":
                    // Tìm kiếm nhà cung cấp theo tên hoặc số điện thoại
                    String keyword = request.getParameter("keyword");
                    ArrayList<SupplierDTO> list = sdao.SupplierList(); // Lấy toàn bộ danh sách

                    if (keyword != null && !keyword.trim().isEmpty()) {
                        // Lọc trong Java: chứa keyword trong tên hoặc SĐT
                        ArrayList<SupplierDTO> filtered = new ArrayList<>();
                        for (SupplierDTO s : list) {
                            String name  = s.getSupplierName();
                            String phone = s.getContactPhone();
                            boolean matchName  = name  != null && name.toLowerCase().contains(keyword.toLowerCase());
                            boolean matchPhone = phone != null && phone.contains(keyword);
                            if (matchName || matchPhone) {
                                filtered.add(s); // Giữ lại nếu khớp tên hoặc SĐT
                            }
                        }
                        list = filtered; // Dùng danh sách đã lọc thay thế
                    }

                    request.setAttribute("supplierList", list); // Đưa kết quả vào request
                    request.getRequestDispatcher("SearchSupplier.jsp").forward(request, response);
                    break;

                case "addSupplier":
                    // Tạo SupplierDTO ngay trên 1 dòng và INSERT vào DB
                    // id=0 vì DB sẽ tự sinh (AUTO_INCREMENT / IDENTITY)
                    sdao.Add(new SupplierDTO(0,
                            request.getParameter("supplierName"),   // Tên nhà cung cấp
                            request.getParameter("contactPhone"))); // Số điện thoại liên hệ

                    // Redirect về danh sách sau khi thêm (ngăn F5 submit lại)
                    response.sendRedirect("MainController?action=listSupplier");
                    break;

                case "deleteSupplier":
                    // Parse ID nhà cung cấp và gọi DAO xóa
                    sdao.Delete(Integer.parseInt(request.getParameter("id")));
                    response.sendRedirect("MainController?action=listSupplier");
                    break;

                case "loadUpdateSupplier":
                    // Tải thông tin nhà cung cấp cần sửa và hiển thị form edit inline
                    request.setAttribute("supplierEdit",
                            sdao.SearchByID(Integer.parseInt(request.getParameter("id")))); // Item cần edit
                    request.setAttribute("supplierList", sdao.SupplierList()); // Danh sách bên cạnh
                    request.getRequestDispatcher("SearchSupplier.jsp").forward(request, response);
                    break;

                case "saveUpdateSupplier":
                    // Tạo DTO với id và dữ liệu mới rồi UPDATE trong DB
                    sdao.Update(new SupplierDTO(
                            Integer.parseInt(request.getParameter("id")), // ID nhà cung cấp
                            request.getParameter("supplierName"),          // Tên mới
                            request.getParameter("contactPhone")));        // SĐT mới
                    response.sendRedirect("MainController?action=listSupplier");
                    break;
            }

        } catch (Exception e) {
            // In stack trace ra console để debug; trong production nên ghi log file
            e.printStackTrace();
        }
    }

    /** Xử lý HTTP GET – xem danh sách, tải form sửa */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processRequest(req, resp);
    }

    /** Xử lý HTTP POST – thêm, xóa, cập nhật nhà cung cấp */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processRequest(req, resp);
    }
}
