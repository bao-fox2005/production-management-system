package pms.controllers;

import java.io.IOException;
import java.util.Properties;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.UserDTO;
import pms.utils.EmailService;
import pms.utils.SystemConfigService;

/**
 * AdminController – Servlet quản lý cấu hình hệ thống dành riêng cho Admin.
 * Hiện tại xử lý: cấu hình SMTP (máy chủ email) và gửi email thử nghiệm.
 *
 * URL mapping: /AdminController
 * Các action hỗ trợ:
 *   - saveSmtpConfig  : Lưu cấu hình SMTP vào bộ nhớ ứng dụng (ServletContext)
 *   - sendTestEmail   : Gửi email thử để kiểm tra cấu hình SMTP
 *   - (mặc định)      : Hiển thị trang cài đặt email
 */
@WebServlet(name = "AdminController", urlPatterns = {"/AdminController"})
public class AdminController extends HttpServlet {

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Đọc cấu hình SMTP từ ServletContext (hoặc tải mới nếu chưa có),
     * rồi phân luồng theo tham số "action".
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 cho response và request để hỗ trợ tiếng Việt
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy thông tin người dùng đang đăng nhập từ session
        HttpSession session = request.getSession();
        UserDTO user = (UserDTO) session.getAttribute("user");

        // Lấy action từ request; nếu null thì dùng chuỗi rỗng để vào nhánh default
        String action = request.getParameter("action");
        if (action == null) {
            action = "";
        }

        // Đọc cấu hình SMTP từ SystemConfig (DB)
        SystemConfigService configService = new SystemConfigService();
        Properties smtpConfig = loadSmtpConfig(configService);

        // Phân luồng theo action
        switch (action) {
            case "saveSmtpConfig":
                // Lưu cấu hình SMTP mới vào SystemConfig
                saveSmtpConfig(request, configService, smtpConfig);
                request.setAttribute("msg", "Cấu hình email đã được lưu thành công!");
                break;

            case "sendTestEmail":
                // Gửi email thử trực tiếp, trả về kết quả dạng plain text (AJAX)
                // Dùng return để không forward tiếp xuống bên dưới
                sendTestEmail(request, response);
                return;

            default:
                // Không có action cụ thể → hiển thị trang cài đặt email
                break;
        }

        // Forward đến trang cài đặt email
        request.setAttribute("activePage", "smtp");
        request.setAttribute("pageTitle", "Cấu hình SMTP");
        request.setAttribute("smtpConfig", smtpConfig);
        request.getRequestDispatcher("email-settings.jsp").forward(request, response);
    }

    /**
     * Tải cấu hình SMTP từ các context-param trong web.xml.
     * Nếu một tham số chưa được cấu hình thì dùng giá trị mặc định (chuỗi rỗng
     * hoặc "587" cho port).
     *
     * @param app ServletContext của ứng dụng, chứa các init-param từ web.xml
     * @return Properties chứa toàn bộ cấu hình SMTP
     */
    private Properties loadSmtpConfig(SystemConfigService configService) {
        Properties props = new Properties();

        props.setProperty("smtp.host", configService.getConfig("SMTP_HOST", ""));
        props.setProperty("smtp.port", configService.getConfig("SMTP_PORT", "587"));
        props.setProperty("smtp.user", configService.getConfig("SMTP_USER", ""));
        props.setProperty("smtp.password", configService.getConfig("SMTP_PASSWORD", ""));
        props.setProperty("admin.email", configService.getConfig("ADMIN_EMAIL", ""));

        return props;
    }

    /**
     * Cập nhật cấu hình SMTP trong bộ nhớ ứng dụng từ dữ liệu form.
     * Chỉ cập nhật các trường không null; mật khẩu chỉ cập nhật nếu người dùng nhập mới.
     *
     * @param request    HttpServletRequest chứa các trường từ form cài đặt SMTP
     * @param configService SystemConfigService để lưu vào database
     * @param smtpConfig Properties hiện tại cần được cập nhật
     */
    private void saveSmtpConfig(HttpServletRequest request, SystemConfigService configService, Properties smtpConfig) {
        // Lấy từng trường từ form submit
        String smtpHost     = request.getParameter("smtp_host");
        String smtpPort     = request.getParameter("smtp_port");
        String smtpUser     = request.getParameter("smtp_user");
        String smtpPassword = request.getParameter("smtp_password");
        String adminEmail   = request.getParameter("admin_email");

        // Cập nhật từng thuộc tính vào Properties; trim() để loại khoảng trắng thừa
        if (smtpHost != null) {
            String value = smtpHost.trim();
            smtpConfig.setProperty("smtp.host", value);
            configService.setConfig("SMTP_HOST", value);
        }
        if (smtpPort != null) {
            String value = smtpPort.trim();
            smtpConfig.setProperty("smtp.port", value);
            configService.setConfig("SMTP_PORT", value);
        }
        if (smtpUser != null) {
            String value = smtpUser.trim();
            smtpConfig.setProperty("smtp.user", value);
            configService.setConfig("SMTP_USER", value);
        }

        // Mật khẩu chỉ cập nhật nếu người dùng nhập giá trị mới (tránh xóa mật khẩu cũ)
        if (smtpPassword != null && !smtpPassword.isEmpty()) {
            smtpConfig.setProperty("smtp.password", smtpPassword);
            configService.setConfig("SMTP_PASSWORD", smtpPassword);
        }

        if (adminEmail != null) {
            String value = adminEmail.trim();
            smtpConfig.setProperty("admin.email", value);
            configService.setConfig("ADMIN_EMAIL", value);
        }

        // In log ra console server để debug
        System.out.println("SMTP Config saved: host=" + smtpConfig.getProperty("smtp.host")
                + ", user=" + smtpConfig.getProperty("smtp.user"));
    }

    /**
     * Gửi email thử nghiệm đến địa chỉ được chỉ định để kiểm tra cấu hình SMTP.
     * Trả về kết quả dạng plain text (dùng cho AJAX call từ trang cài đặt).
     *
     * Luồng xử lý:
     *   1. Validate email đích
     *   2. Lấy thông số SMTP (ưu tiên từ form, fallback sang config đã lưu)
     *   3. Tạo EmailService và kiểm tra cấu hình đủ chưa
     *   4. Gửi email và trả về kết quả
     *
     * @param request  HttpServletRequest chứa test_email và thông số SMTP tùy chọn
     * @param response HttpServletResponse để ghi kết quả plain text
     */
    private void sendTestEmail(HttpServletRequest request, HttpServletResponse response) throws IOException {
        // Trả về plain text thay vì HTML (dùng cho AJAX)
        response.setContentType("text/plain;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        try {
            // Lấy địa chỉ email đích cần gửi thử
            String testEmail = request.getParameter("test_email");

            // Lấy cấu hình SMTP từ SystemConfig
            SystemConfigService configService = new SystemConfigService();
            Properties smtpConfig = loadSmtpConfig(configService);

            // Validate email đích: không null, không rỗng, phải có dấu "@"
            if (testEmail == null || testEmail.trim().isEmpty() || !testEmail.contains("@")) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST); // HTTP 400
                response.getWriter().write("Email không hợp lệ!");
                return;
            }

            // Đọc thông số SMTP từ form (người dùng có thể nhập trực tiếp trên form)
            String smtpHost     = request.getParameter("smtp_host");
            String smtpPort     = request.getParameter("smtp_port");
            String smtpUser     = request.getParameter("smtp_user");
            String smtpPassword = request.getParameter("smtp_password");

            // Fallback: nếu form không cung cấp thì lấy từ config đã lưu
            if (smtpHost == null || smtpHost.trim().isEmpty())
                smtpHost = smtpConfig.getProperty("smtp.host");
            if (smtpPort == null || smtpPort.trim().isEmpty())
                smtpPort = smtpConfig.getProperty("smtp.port");
            if (smtpUser == null || smtpUser.trim().isEmpty())
                smtpUser = smtpConfig.getProperty("smtp.user");
            if (smtpPassword == null || smtpPassword.trim().isEmpty())
                smtpPassword = smtpConfig.getProperty("smtp.password");

            // Khởi tạo EmailService với các thông số SMTP
            EmailService emailService = new EmailService(smtpHost, smtpPort, smtpUser, smtpPassword);

            // Kiểm tra cấu hình đủ chưa trước khi gửi
            if (!emailService.isConfigured() || smtpPassword == null || smtpPassword.trim().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST); // HTTP 400
                response.getWriter().write(
                    "SMTP chưa đủ thông tin. Cần nhập đầy đủ host, port, email gửi và app password.");
                return;
            }

            // Xây dựng nội dung email thử và gửi đi
            String subject = "[PMS] Email Test - Hệ Thống Sản Xuất";
            String body    = buildTestEmailBody(); // Tạo nội dung HTML đẹp
            boolean success = emailService.sendEmail(testEmail.trim(), subject, body);

            if (success) {
                response.getWriter().write("Email test đã được gửi thành công!");
            } else {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST); // HTTP 400
                // Lấy message lỗi cụ thể từ EmailService (ví dụ: authentication failed)
                String smtpError = emailService.getLastError();
                if (smtpError == null || smtpError.trim().isEmpty()) {
                    smtpError = "Gửi email thất bại. Kiểm tra lại smtp host, port, email gửi và app password Gmail.";
                }
                response.getWriter().write(smtpError);
            }

        } catch (Throwable e) {
            // Bắt cả Error lẫn Exception để tránh crash server
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR); // HTTP 500
            response.getWriter().write("Lỗi gửi email thử: " + safeMessage(e));
            e.printStackTrace(); // In stack trace ra console để debug
        }
    }

    /**
     * Trích xuất message lỗi từ Throwable một cách an toàn.
     * Trả về message, tên class của exception, hoặc mô tả mặc định nếu không có gì.
     *
     * @param e Throwable cần lấy message
     * @return Chuỗi mô tả lỗi, không bao giờ null
     */
    private String safeMessage(Throwable e) {
        if (e == null) {
            return "Không xác định. Kiểm tra lại SMTP Host, Port, email gửi và App Password.";
        }

        // Ưu tiên lấy message gốc của exception
        String message = e.getMessage();
        if (message != null && !message.trim().isEmpty()) {
            return message;
        }

        // Nếu message rỗng thì dùng tên class của exception (ví dụ: "SocketTimeoutException")
        String type = e.getClass().getSimpleName();
        if (type != null && !type.trim().isEmpty()) {
            return type;
        }

        // Fallback cuối cùng
        return "Không xác định. Kiểm tra lại SMTP Host, Port, email gửi và App Password.";
    }

    /**
     * Tạo nội dung HTML cho email thử nghiệm.
     * Email có tiêu đề màu xanh, nội dung ngắn gọn và biểu tượng xác nhận thành công.
     *
     * @return Chuỗi HTML hoàn chỉnh dùng làm body email
     */
    private String buildTestEmailBody() {
        StringBuilder sb = new StringBuilder();

        // Bắt đầu HTML với charset UTF-8
        sb.append("<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head>");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">");

        // Header màu xanh teal
        sb.append("<div style=\"background:#14b8a6;padding:32px;text-align:center;\">");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.8rem;\">PMS - Email Test</h1>");
        sb.append("</div>");

        // Vùng nội dung chính
        sb.append("<div style=\"padding:32px;max-width:600px;margin:0 auto;background:#fff;\">");
        sb.append("<p>Xin chào,</p>");
        sb.append("<p>Đây là email test từ <strong>Production Management System</strong>.</p>");
        sb.append("<p>Nếu bạn nhận được email này, cấu hình SMTP đã hoạt động bình thường!</p>");

        // Hộp hiển thị kết quả OK màu xanh lá
        sb.append("<div style=\"background:#f0fdf4;border-radius:12px;padding:20px;margin:24px 0;text-align:center;\">");
        sb.append("<p style=\"margin:0;font-size:2rem;\">&#9989;</p>"); // Icon dấu tích xanh ✅
        sb.append("<p style=\"margin:8px 0 0;color:#059669;font-weight:bold;\">Cấu hình email hoạt động tốt!</p>");
        sb.append("</div>");

        // Đường kẻ phân cách
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:24px 0;\">");

        // Footer
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">Hệ thống tự động - Production Management System</p>");
        sb.append("</div></body></html>");

        return sb.toString();
    }

    /** Xử lý HTTP GET – hiển thị trang cài đặt hoặc gửi test email */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – lưu cấu hình SMTP hoặc gửi test email qua AJAX */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả servlet này trong Servlet container */
    @Override
    public String getServletInfo() {
        return "Admin Controller";
    }
}
