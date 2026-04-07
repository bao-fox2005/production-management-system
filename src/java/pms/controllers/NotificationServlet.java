package pms.controllers;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.UserDTO;
import pms.utils.NotificationService;
import pms.utils.NotificationService.Notification;

/**
 * NotificationServlet – Servlet phục vụ thông báo real-time cho người dùng.
 *
 * Sử dụng hai kỹ thuật khác nhau tùy vào HTTP method:
 *
 * HTTP GET – Server-Sent Events (SSE):
 *   - Kết nối long-polling/streaming: browser mở một request GET duy nhất
 *     và server liên tục đẩy dữ liệu về theo định dạng "text/event-stream".
 *   - Gửi ngay các thông báo tồn đọng (existing notifications) khi kết nối.
 *   - Gửi heartbeat mỗi 15 giây để giữ kết nối sống.
 *   - Kiểm tra session timeout (getMaxInactiveInterval) và thông báo khi hết hạn.
 *   - Nếu session bị hủy (user đăng xuất), gửi event "logout" và đóng kết nối.
 *
 * HTTP POST – JSON API:
 *   - Xử lý các action quản lý thông báo: markRead, markAllRead, getCount, getAll, clear.
 *   - Phản hồi JSON (application/json).
 *
 * Dữ liệu thông báo được lưu trong bộ nhớ (NotificationService – in-memory store),
 * không ghi vào DB, nên sẽ bị reset khi server restart.
 */
public class NotificationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Khởi tạo servlet – gọi super.init() để đăng ký với container.
     */
    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config); // Cần thiết để ServletConfig được inject đúng
    }

    /**
     * Xử lý HTTP GET – thiết lập kênh SSE và đẩy thông báo real-time.
     *
     * Quy trình:
     *   1. Set header SSE (text/event-stream, no-cache, keep-alive).
     *   2. Kiểm tra session và user – nếu không hợp lệ thì gửi event error.
     *   3. Gửi toàn bộ thông báo tồn đọng trước (existing).
     *   4. Gửi event "connected" để client biết kết nối thành công.
     *   5. Vòng lặp vô hạn: sleep 5 giây, kiểm tra session, gửi heartbeat.
     *   6. Kết thúc khi: session hết hạn, user đăng xuất, hoặc thread bị interrupt.
     *
     * @param request  HttpServletRequest của kết nối SSE (long-lived)
     * @param response HttpServletResponse dùng để stream SSE events
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt Content-Type SSE (bắt buộc để browser nhận dạng SSE stream)
        response.setContentType("text/event-stream;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Các header chống cache – SSE phải là real-time, không được cache lại
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma",        "no-cache");
        response.setHeader("Expires",       "0");
        response.setHeader("Connection",    "keep-alive");       // Giữ kết nối liên tục
        response.setHeader("Access-Control-Allow-Origin", "*");  // Cho phép cross-origin (CORS)

        // Kiểm tra session hợp lệ (false = không tạo session mới nếu chưa có)
        HttpSession session = request.getSession(false);
        if (session == null) {
            // Không có session → chưa đăng nhập hoặc session đã hết hạn
            response.getWriter().write("data: {\"error\":\"unauthorized\"}\n\n");
            response.getWriter().flush();
            return;
        }

        UserDTO user = (UserDTO) session.getAttribute("user"); // Lấy thông tin user từ session
        if (user == null) {
            response.getWriter().write("data: {\"error\":\"unauthorized\"}\n\n");
            response.getWriter().flush();
            return;
        }

        String username = user.getUsername(); // Username dùng làm key trong NotificationService

        // Gửi các thông báo tồn đọng (đã tạo trước khi client kết nối SSE)
        List<Notification> existing = NotificationService.getNotifications(username);
        PrintWriter out = response.getWriter();
        for (Notification n : existing) {
            out.write(NotificationService.buildSseEvent(n)); // Format: "data: {json}\n\n"
            out.flush();
        }

        // Gửi event "connected" xác nhận kết nối SSE thành công
        out.write("data: {\"type\":\"connected\",\"user\":\"" + username + "\"}\n\n");
        out.flush();

        // Cấu hình vòng lặp SSE
        long lastActivity       = System.currentTimeMillis();       // Thời điểm hoạt động cuối
        long heartbeatInterval  = 15000;                             // Heartbeat mỗi 15 giây
        long sessionTimeout     = session.getMaxInactiveInterval() * 1000L; // Timeout của session (ms)

        try {
            while (true) {
                Thread.sleep(5000); // Ngủ 5 giây giữa mỗi lần kiểm tra

                if (Thread.currentThread().isInterrupted()) break; // Servlet container yêu cầu dừng

                long now = System.currentTimeMillis();

                // Kiểm tra session còn sống không (user có thể đã đăng xuất từ tab khác)
                HttpSession currentSession = request.getSession(false);
                if (currentSession == null || currentSession.getAttribute("user") == null) {
                    out.write("data: {\"type\":\"logout\"}\n\n"); // Báo client user đã logout
                    out.flush();
                    break; // Đóng kết nối SSE
                }

                // Kiểm tra session đã vượt quá thời gian không hoạt động cho phép
                if ((now - lastActivity) > sessionTimeout) {
                    out.write("data: {\"type\":\"timeout\"}\n\n"); // Báo client session timeout
                    out.flush();
                    break;
                }

                // Gửi heartbeat nếu đã qua heartbeatInterval kể từ lần cuối
                if ((now - lastActivity) > heartbeatInterval) {
                    out.write(NotificationService.buildHeartbeatEvent()); // ": heartbeat\n\n"
                    out.flush();
                    lastActivity = now; // Cập nhật thời điểm heartbeat cuối
                }
            }

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // Khôi phục trạng thái interrupted
        } finally {
            try { out.close(); } catch (Exception ignored) {} // Đóng stream khi kết thúc
        }
    }

    /**
     * Xử lý HTTP POST – API JSON quản lý thông báo của người dùng hiện tại.
     *
     * Các action hỗ trợ (tham số "action"):
     *   - markRead   : Đánh dấu một thông báo đã đọc (cần "id" = notification ID)
     *   - markAllRead: Đánh dấu tất cả thông báo đã đọc
     *   - getCount   : Lấy số lượng thông báo chưa đọc (trả {"count": N})
     *   - getAll     : Lấy tất cả thông báo dạng JSON array
     *   - clear      : Xóa toàn bộ thông báo
     *
     * Yêu cầu: phải có session hợp lệ, không thì trả {"error":"unauthorized"}.
     *
     * @param request  Chứa "action" và tùy chọn "id"
     * @param response HttpServletResponse để ghi JSON
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Kiểm tra session hợp lệ
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        UserDTO user = (UserDTO) session.getAttribute("user");
        if (user == null) {
            response.getWriter().write("{\"error\":\"unauthorized\"}");
            return;
        }

        String action   = request.getParameter("action"); // Action quản lý thông báo
        String username = user.getUsername();              // Key trong NotificationService

        if ("markRead".equals(action)) {
            // Đánh dấu một thông báo cụ thể đã đọc
            String notifId = request.getParameter("id"); // ID của thông báo cần đánh dấu
            NotificationService.markRead(username, notifId);
            response.getWriter().write("{\"success\":true}");

        } else if ("markAllRead".equals(action)) {
            // Đánh dấu tất cả thông báo của user này đã đọc
            NotificationService.markAllRead(username);
            response.getWriter().write("{\"success\":true}");

        } else if ("getCount".equals(action)) {
            // Trả về số lượng thông báo chưa đọc (dùng cho badge trên UI)
            int count = NotificationService.getUnreadCount(username);
            response.getWriter().write("{\"count\":" + count + "}");

        } else if ("getAll".equals(action)) {
            // Trả về tất cả thông báo dạng JSON array
            List<Notification> list = NotificationService.getNotifications(username);
            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            for (Notification n : list) {
                if (!first) json.append(",");
                json.append(n.toJson()); // Mỗi Notification tự serialize thành JSON object
                first = false;
            }
            json.append("]");
            response.getWriter().write(json.toString());

        } else if ("clear".equals(action)) {
            // Xóa toàn bộ thông báo của user này khỏi bộ nhớ
            NotificationService.clearNotifications(username);
            response.getWriter().write("{\"success\":true}");

        } else {
            // Action không xác định
            response.getWriter().write("{\"error\":\"unknown action\"}");
        }
    }
}
