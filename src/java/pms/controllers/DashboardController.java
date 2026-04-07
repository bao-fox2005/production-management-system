package pms.controllers;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.DashboardDAO;
import pms.model.DashboardDTO;

/**
 * DashboardController – Servlet hiển thị trang tổng quan (Dashboard) của hệ thống.
 *
 * Trang Dashboard hiển thị các thống kê tổng hợp (KPI) khác nhau tùy theo vai trò:
 *   - Admin : Xem toàn bộ thống kê của hệ thống (đơn hàng, tồn kho, lệnh sản xuất…)
 *   - Worker: Chỉ xem thống kê liên quan đến bản thân (lệnh được giao, tiến độ…)
 *   - Khác  : Xem thống kê đầy đủ mặc định
 */
public class DashboardController extends HttpServlet {

    /**
     * serialVersionUID là bắt buộc cho các class Serializable (HttpServlet implements Serializable).
     * Khai báo tường minh để tránh cảnh báo compiler và đảm bảo tương thích khi deploy lại.
     */
    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Đọc action từ request (mặc định là "view") và chuyển đến method tương ứng,
     * sau đó forward kết quả đến Dashboard.jsp.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 để hỗ trợ tiếng Việt
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action; nếu không có thì mặc định là "view" (xem dashboard)
        String action = request.getParameter("action");
        if (action == null) action = "view";

        // Phân luồng – hiện chỉ có một action duy nhất là "view"
        switch (action) {
            case "view":
            default:
                viewDashboard(request); // Nạp dữ liệu thống kê vào request
                break;
        }

        // Forward đến trang Dashboard.jsp để hiển thị dữ liệu
        request.getRequestDispatcher("Dashboard.jsp").forward(request, response);
    }

    /**
     * Lấy dữ liệu thống kê phù hợp với vai trò người dùng và đặt vào request attribute.
     *
     * Logic phân quyền:
     *   - Nếu user là admin → gọi loadDashboardStats() để lấy toàn bộ thống kê
     *   - Nếu user là worker/employee/user → gọi loadWorkerDashboardStats(userId) chỉ lấy
     *     thống kê cá nhân của người đó
     *   - Nếu không có session user → load mặc định full stats
     *
     * @param request HttpServletRequest để đọc session user và set attribute kết quả
     */
    private void viewDashboard(HttpServletRequest request) {
        // Lấy đối tượng user từ session (được lưu khi đăng nhập)
        pms.model.UserDTO user = (pms.model.UserDTO) request.getSession().getAttribute("user");

        DashboardDAO dao = new DashboardDAO(); // Tạo DAO để truy vấn DB

        if (user != null) {
            String userRole = user.getRole(); // Lấy vai trò: "admin", "employee", "worker", "user"

            // Kiểm tra vai trò admin (không phân biệt hoa thường để an toàn)
            boolean isAdmin = "admin".equalsIgnoreCase(userRole);

            // Kiểm tra vai trò công nhân/nhân viên (nhiều tên khác nhau có thể dùng)
            boolean isWorker = "employee".equalsIgnoreCase(userRole)
                    || "worker".equalsIgnoreCase(userRole)
                    || "user".equalsIgnoreCase(userRole);

            DashboardDTO data;
            if (isAdmin) {
                // Admin xem tất cả thống kê toàn hệ thống
                data = dao.loadDashboardStats();
            } else if (isWorker) {
                // Worker chỉ xem thống kê liên quan đến ID của chính họ
                data = dao.loadWorkerDashboardStats(user.getId());
            } else {
                // Vai trò không xác định → load đầy đủ làm mặc định an toàn
                data = dao.loadDashboardStats();
            }

            // Đưa dữ liệu vào request để Dashboard.jsp đọc và hiển thị
            request.setAttribute("dashboardData", data);
            request.setAttribute("isAdmin", isAdmin);   // JSP dùng để ẩn/hiện các section admin
            request.setAttribute("isWorker", isWorker); // JSP dùng để hiển thị view worker

        } else {
            // Không có user trong session (truy cập trực tiếp mà chưa login)
            // → Load thống kê mặc định và coi như không phải admin hay worker
            DashboardDTO data = dao.loadDashboardStats();
            request.setAttribute("dashboardData", data);
            request.setAttribute("isAdmin", false);
            request.setAttribute("isWorker", false);
        }
    }

    /** Xử lý HTTP GET – người dùng truy cập Dashboard bằng URL */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – ít dùng cho Dashboard, nhưng vẫn delegate về processRequest */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Dashboard Controller";
    }
}
