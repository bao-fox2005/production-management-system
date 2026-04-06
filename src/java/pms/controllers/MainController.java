package pms.controllers;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * MainController – Servlet định tuyến trung tâm (Front Controller) của toàn bộ ứng dụng PMS.
 *
 * Mọi request từ JSP đều đi qua MainController trước. Dựa vào tham số "action",
 * MainController xác định controller chuyên biệt nào cần xử lý rồi forward request đến đó.
 *
 * Ví dụ:
 *   action=listBOM         → BOMController
 *   action=loginUser       → UserController
 *   action=listWorkOrder   → WorkOrderController
 *
 * @MultipartConfig: Bật khả năng nhận file upload (multipart/form-data) cho servlet này,
 *   cần thiết khi có form tải file đi qua MainController.
 */
@MultipartConfig
public class MainController extends HttpServlet {

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Đọc tham số "action" và forward request đến controller tương ứng.
     *
     * Nếu không có action → hiển thị trang login.
     * Nếu có action → kiểm tra từ khóa trong action để xác định controller đích.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 cho cả request và response
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Mặc định URL là trang login (nếu không có action)
        String url = "login.jsp";

        // Lấy action từ query string hoặc form data
        String action = request.getParameter("action");

        if (action == null) {
            // Không có action → forward về trang login ngay lập tức
            request.getRequestDispatcher(url).forward(request, response);
            return;
        }

        // Định tuyến: kiểm tra từ khóa trong action để biết cần chuyển đến controller nào
        // Sử dụng contains() thay vì equals() để một controller có thể xử lý nhiều action
        // (ví dụ: "listUser", "addUser", "deleteUser" đều chứa "User" → UserController)

        if (action.contains("User")) {
            url = "UserController";         // Quản lý tài khoản người dùng

        } else if (action.contains("Item")) {
            url = "ItemController";          // Quản lý vật tư, nguyên liệu, sản phẩm

        } else if (action.contains("Bom") || action.contains("BOM")) {
            url = "BOMController";           // Quản lý Bill of Materials (công thức nguyên liệu)

        } else if (action.contains("Supplier")) {
            url = "SupplierController";      // Quản lý nhà cung cấp

        } else if (action.contains("PurchaseOrder")) {
            url = "PurchaseOrderController"; // Quản lý đơn đặt mua vật tư

        } else if (action.contains("RoutingStep")) {
            // Phải kiểm tra RoutingStep TRƯỚC Routing để tránh nhầm
            url = "RoutingStepController";   // Quản lý từng bước trong quy trình sản xuất

        } else if (action.contains("Routing")) {
            url = "RoutingController";        // Quản lý quy trình sản xuất (routing)

        } else if (action.contains("DefectReason") || action.contains("listDefectReason")
                || action.contains("Defect") || action.contains("listDefect")) {
            url = "DefectController";         // Quản lý lỗi sản phẩm và nguyên nhân

        } else if (action.contains("Bill")) {
            url = "BillController";           // Quản lý hóa đơn bán hàng

        } else if (action.contains("Customer")) {
            url = "CustomerController";       // Quản lý khách hàng

        } else if (action.contains("Production") || action.contains("listLog")) {
            url = "ProductionLogController";  // Quản lý nhật ký sản xuất

        } else if (action.contains("WorkOrder")) {
            url = "WorkOrderController";      // Quản lý lệnh sản xuất

        } else if (action.contains("Payment")) {
            url = "PaymentController";        // Quản lý thanh toán

        } else if (action.contains("File")) {
            url = "FileController";           // Quản lý tải lên/tải xuống file
        }

        // Forward request (giữ nguyên tham số) đến controller đã xác định
        // Controller đích sẽ đọc lại "action" từ request để xử lý chi tiết
        request.getRequestDispatcher(url).forward(request, response);
    }

    /** Xử lý HTTP GET – phần lớn các thao tác xem/tìm kiếm dùng GET */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – phần lớn các thao tác thêm/sửa/xóa dùng POST */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Main Controller";
    }
}
