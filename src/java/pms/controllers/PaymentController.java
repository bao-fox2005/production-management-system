package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.PaymentDTO;
import pms.utils.PaymentService;

/**
 * PaymentController – Servlet quản lý toàn bộ quy trình Thanh Toán.
 *
 * Hỗ trợ hai chế độ hoạt động:
 *   1. Standard (HTML)   : Forward đến JSP hiển thị trang web bình thường
 *   2. AJAX / API (JSON) : Phản hồi JSON cho các request từ JavaScript
 *
 * Các action hỗ trợ:
 *   - list            : Xem toàn bộ danh sách payment
 *   - pending         : Chỉ xem payment chưa thanh toán
 *   - paid            : Chỉ xem payment đã thanh toán
 *   - search          : Tìm kiếm payment theo từ khóa
 *   - createQr        : Tạo QR code thanh toán ngân hàng
 *   - refreshQr       : Làm mới QR code đã hết hạn
 *   - checkStatus     : Kiểm tra trạng thái payment (trả JSON, dùng cho polling AJAX)
 *   - confirmPayment  : Xác nhận thủ công rằng payment đã thanh toán
 *   - cancelPayment   : Hủy payment
 *
 * Kỹ thuật đặc biệt:
 *   - PaymentService được khởi tạo một lần trong init() và reuse (Singleton per servlet)
 *   - Response object được lưu vào request attribute "__httpResponse" để các
 *     method private có thể dùng khi cần (workaround cho thiếu DI)
 *   - CẢNH BÁO: url là instance field – không thread-safe
 */
public class PaymentController extends HttpServlet {

    /**
     * CẢNH BÁO: instance field – không thread-safe.
     * Giữ nguyên để tương thích với logic hiện tại.
     */
    String url = "";

    /**
     * PaymentService là service layer xử lý logic nghiệp vụ payment:
     * tạo QR, kiểm tra trạng thái, xác nhận, hủy…
     */
    private PaymentService paymentService;

    /**
     * Khởi tạo PaymentService một lần khi servlet được deploy.
     * Cách này tốt hơn khởi tạo mới trong mỗi request (tiết kiệm tài nguyên).
     */
    @Override
    public void init() throws ServletException {
        this.paymentService = new PaymentService(); // Khởi tạo service layer
    }

    /**
     * Điểm xử lý chung. Lưu response vào request attribute để method private truy cập.
     * Xác định AJAX hay standard request ngay từ đầu.
     * Đặc biệt: nếu là AJAX request từ trang bill và không có action → mặc định createQr.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        url = null; // Reset url trước mỗi request
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lưu response vào request attribute để các method private có thể dùng khi cần
        // (Workaround vì Java không cho phép truyền response qua chain call thông thường)
        request.setAttribute("__httpResponse", response);

        String action = request.getParameter("action");
        boolean ajax  = isAjaxRequest(request);  // Kiểm tra có phải AJAX request không
        String source = request.getParameter("source"); // Trang nguồn gọi (ví dụ: "bill")

        if (action != null) {
            action = action.trim();
        }

        // Nếu AJAX từ trang bill mà không có action → mặc định là tạo QR
        if ((action == null || action.isEmpty()) && ajax && "bill".equalsIgnoreCase(source)) {
            action = "createQr";
        }

        // Fallback cuối cùng
        if (action == null || action.isEmpty()) {
            action = "list";
        }

        // Phân luồng theo action
        switch (action) {
            case "list":
                listPayments(request);                          // Toàn bộ payment
                break;
            case "createQr":
                createQrPayment(request, response);             // Tạo QR code
                break;
            case "refreshQr":
                refreshQrPayment(request);                      // Làm mới QR đã hết hạn
                break;
            case "checkStatus":
                checkPaymentStatus(request, response);          // Kiểm tra trạng thái (JSON)
                return; // Return sớm – method này tự ghi response
            case "confirmPayment":
                confirmPayment(request);                        // Xác nhận thanh toán thủ công
                break;
            case "cancelPayment":
                cancelPayment(request);                         // Hủy payment
                break;
            case "search":
                searchPayments(request);                        // Tìm kiếm payment
                break;
            case "pending":
                listPendingPayments(request);                   // Chỉ hiện payment chưa thanh toán
                break;
            case "paid":
                listPaidPayments(request);                      // Chỉ hiện payment đã thanh toán
                break;
        }

        // Kiểm tra response đã được commit chưa (bởi các method AJAX bên trong)
        // Nếu đã commit thì không forward/redirect để tránh lỗi "response already committed"
        if (response.isCommitted()) {
            return;
        }

        // Thực hiện redirect hoặc forward tùy theo url được set bởi các method
        if (url != null && url.startsWith("redirect:")) {
            response.sendRedirect(url.substring(9));
        } else if (url != null && !url.isEmpty()) {
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Tải toàn bộ danh sách payment và forward đến payment-list.jsp.
     */
    private void listPayments(HttpServletRequest request) {
        ArrayList<PaymentDTO> list = paymentService.getAllPayments(); // Lấy tất cả payment từ DB
        request.setAttribute("paymentList", list);
        url = "payment-list.jsp";
    }

    /**
     * Tải danh sách payment chưa thanh toán (trạng thái: PENDING).
     */
    private void listPendingPayments(HttpServletRequest request) {
        ArrayList<PaymentDTO> list = paymentService.getPendingPayments(); // Chỉ lấy PENDING
        request.setAttribute("paymentList", list);
        url = "payment-list.jsp";
    }

    /**
     * Tải danh sách payment đã thanh toán (trạng thái: PAID).
     */
    private void listPaidPayments(HttpServletRequest request) {
        ArrayList<PaymentDTO> list = paymentService.getPaidPayments(); // Chỉ lấy PAID
        request.setAttribute("paymentList", list);
        url = "payment-list.jsp";
    }

    /**
     * Tạo QR code thanh toán ngân hàng cho một hóa đơn.
     * Hỗ trợ cả AJAX (trả JSON) và standard (redirect/forward đến payment-qr.jsp).
     *
     * Luồng:
     *   1. Parse bill_id, amount, expire_minutes, customer info
     *   2. Gọi PaymentService.createQrPayment()
     *   3. Nếu thành công: trả QR data (JSON hoặc redirect đến trang QR)
     *   4. Nếu thất bại: báo lỗi theo chế độ (JSON hoặc HTML)
     *
     * @param request  Chứa bill_id, amount, expire_minutes, customer_name, customer_email, source
     * @param response HttpServletResponse để ghi JSON nếu là AJAX request
     */
    private void createQrPayment(HttpServletRequest request, HttpServletResponse response) {
        boolean ajax = isAjaxRequest(request); // Xác định chế độ phản hồi
        String source = request.getParameter("source"); // "bill" hoặc null

        try {
            if (ajax) {
                // AJAX: thiết lập content type cho JSON response
                response.setCharacterEncoding("UTF-8");
                response.setContentType("application/json;charset=UTF-8");
            }

            int billId         = Integer.parseInt(request.getParameter("bill_id"));  // ID hóa đơn
            double amount      = Double.parseDouble(request.getParameter("amount")); // Số tiền
            int expireMinutes  = 15; // Mặc định QR hết hạn sau 15 phút

            // Override thời gian hết hạn nếu được cung cấp
            String expireStr = request.getParameter("expire_minutes");
            if (expireStr != null && !expireStr.isEmpty()) {
                expireMinutes = Integer.parseInt(expireStr);
            }

            String customerName  = request.getParameter("customer_name");  // Tên khách hàng
            String customerEmail = request.getParameter("customer_email"); // Email khách hàng

            // Đặt giá trị mặc định nếu không có
            if (customerName  == null) customerName  = "Khach hang";
            if (customerEmail == null) customerEmail = "";

            // Tạo QR payment thông qua service layer
            PaymentDTO payment = paymentService.createQrPayment(billId, amount, expireMinutes,
                    customerName, customerEmail);

            if (payment != null) {
                if ("bill".equalsIgnoreCase(source) && ajax) {
                    // Từ trang bill, AJAX: trả JSON với thông tin QR
                    writeQrJson(response, true, payment, payment.getPaymentId() > 0
                            ? "QR code da duoc tao thanh cong!"
                            : "Da tao QR tam thoi. He thong se hien thi QR ngay ca khi CSDL chua co bang Payment.", 200);
                    return;
                }
                if ("bill".equalsIgnoreCase(source)) {
                    // Từ trang bill, standard: redirect đến trang QR
                    if (payment.getPaymentId() > 0) {
                        url = "redirect:payment-qr.jsp?payment_id=" + payment.getPaymentId() + "&from=bill";
                    } else {
                        request.setAttribute("msg", "Da tao QR tam thoi...");
                        request.setAttribute("payment", payment);
                        url = "payment-qr.jsp";
                    }
                    return;
                }
                // Từ trang khác: forward đến payment-qr.jsp với thông tin QR
                request.setAttribute("msg", "QR code da duoc tao thanh cong!");
                request.setAttribute("payment", payment);
                url = "payment-qr.jsp";
                return;

            } else {
                // Tạo QR thất bại
                if ("bill".equalsIgnoreCase(source) && ajax) {
                    writeQrJson(response, false, null, "Khong the tao QR thanh toan!", 500);
                    return;
                }
                if ("bill".equalsIgnoreCase(source)) {
                    url = "redirect:MainController?action=listBill&error="
                            + java.net.URLEncoder.encode("Khong the tao QR thanh toan!", "UTF-8");
                    return;
                }
                request.setAttribute("error", "Khong the tao QR thanh toan!");
            }

        } catch (Exception e) {
            String errorMessage = "Loi: " + e.getMessage();
            if (ajax) {
                // AJAX: ghi JSON lỗi
                try { writeQrJson(response, false, null, errorMessage, 500); } catch (Exception ignored) {}
                return;
            }
            if ("bill".equalsIgnoreCase(source)) {
                try {
                    url = "redirect:MainController?action=listBill&error="
                            + java.net.URLEncoder.encode(errorMessage, "UTF-8");
                } catch (Exception encodeEx) {
                    url = "redirect:MainController?action=listBill&error=Loi%20tao%20QR";
                }
                return;
            }
            request.setAttribute("error", errorMessage);
            e.printStackTrace();
        }
        listPayments(request); // Fallback: hiển thị lại danh sách
    }

    /**
     * Kiểm tra xem request có phải là AJAX request không.
     * Điều kiện AJAX: có param "ajax=1" HOẶC header "X-Requested-With: XMLHttpRequest".
     *
     * @param request HttpServletRequest cần kiểm tra
     * @return true nếu là AJAX request
     */
    private boolean isAjaxRequest(HttpServletRequest request) {
        return "1".equals(request.getParameter("ajax"))
                || "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));
    }

    /**
     * Ghi phản hồi JSON cho các action liên quan đến QR payment.
     * Tự build JSON thủ công thay vì dùng thư viện (để tránh phụ thuộc bên ngoài).
     *
     * @param response    HttpServletResponse để ghi JSON
     * @param success     true nếu operation thành công
     * @param payment     PaymentDTO chứa thông tin QR (null nếu thất bại)
     * @param message     Message thành công hoặc lỗi
     * @param statusCode  HTTP status code (200, 400, 500…)
     */
    private void writeQrJson(HttpServletResponse response, boolean success, PaymentDTO payment,
            String message, int statusCode) throws IOException {

        response.reset();                                    // Xóa dữ liệu response cũ (nếu có)
        response.setStatus(statusCode);                     // Đặt HTTP status
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        StringBuilder json = new StringBuilder("{");
        json.append("\"success\":").append(success);         // true / false
        json.append(",\"message\":\"").append(escapeJson(message)).append("\"");

        if (payment != null) {
            // Phân tách QR image base64 và URL (được lưu ghép với separator "|QR_URL|")
            String qrData        = payment.getQrCodeData() != null ? payment.getQrCodeData() : "";
            String qrImageBase64 = qrData;
            String qrVietQrUrl   = "";
            if (qrData.contains("|QR_URL|")) {
                String[] parts = qrData.split("\\|QR_URL\\|", 2);
                qrImageBase64  = parts.length > 0 ? parts[0] : ""; // Base64 PNG của QR
                qrVietQrUrl    = parts.length > 1 ? parts[1] : ""; // URL từ VietQR API
            }

            // Serialize các trường của PaymentDTO sang JSON
            json.append(",\"paymentId\":").append(payment.getPaymentId());
            json.append(",\"billId\":").append(payment.getBillId());
            json.append(",\"amount\":").append(payment.getAmount());
            json.append(",\"status\":\"").append(escapeJson(payment.getStatus())).append("\"");
            json.append(",\"customerName\":\"").append(escapeJson(payment.getCustomerName())).append("\"");
            json.append(",\"customerEmail\":\"").append(escapeJson(payment.getCustomerEmail())).append("\"");
            json.append(",\"bankBin\":\"").append(escapeJson(payment.getBankBin())).append("\"");
            json.append(",\"bankAccount\":\"").append(escapeJson(payment.getBankAccount())).append("\"");
            json.append(",\"bankAccountName\":\"").append(escapeJson(payment.getBankAccountName())).append("\"");
            json.append(",\"expiresAt\":\"").append(payment.getExpiresAt() != null
                    ? escapeJson(payment.getExpiresAt().toString()) : "").append("\"");
            json.append(",\"paidAt\":\"").append(payment.getPaidAt() != null
                    ? escapeJson(payment.getPaidAt().toString()) : "").append("\"");
            json.append(",\"qrImageBase64\":\"").append(escapeJson(qrImageBase64)).append("\"");
            json.append(",\"qrVietQrUrl\":\"").append(escapeJson(qrVietQrUrl)).append("\"");
        }

        json.append("}");
        response.getWriter().write(json.toString()); // Ghi JSON ra response
        response.getWriter().flush();                // Đảm bảo dữ liệu được gửi đi
    }

    /**
     * Escape các ký tự đặc biệt trong JSON string để tránh lỗi parse JSON.
     * Xử lý: backslash, dấu nháy kép, carriage return, newline.
     *
     * @param value Chuỗi cần escape (có thể null → trả "")
     * @return Chuỗi đã escape, an toàn để nhúng vào JSON
     */
    private String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")   // Escape backslash trước
                .replace("\"", "\\\"")        // Escape dấu nháy kép
                .replace("\r", "")            // Xóa carriage return
                .replace("\n", "\\n");        // Escape newline
    }

    /**
     * Làm mới QR code của một payment đã hết hạn.
     * Reset thời gian đếm ngược và tạo QR code mới.
     *
     * @param request Chứa payment_id và expire_minutes (tùy chọn)
     */
    private void refreshQrPayment(HttpServletRequest request) {
        try {
            int paymentId     = Integer.parseInt(request.getParameter("payment_id")); // ID payment cần làm mới
            int expireMinutes = 15; // Mặc định 15 phút

            String expireStr = request.getParameter("expire_minutes");
            if (expireStr != null && !expireStr.isEmpty()) {
                expireMinutes = Integer.parseInt(expireStr); // Override thời gian hết hạn
            }

            boolean success = paymentService.refreshQrCode(paymentId, expireMinutes); // Làm mới QR
            if (success) {
                request.setAttribute("msg", "QR code da duoc lam moi! Thoi gian dem nguoc da duoc reset.");
                // Tải thông tin payment vừa refresh để hiển thị QR mới
                PaymentDTO updated = paymentService.getPaymentInfo(paymentId);
                request.setAttribute("payment", updated);
            } else {
                // Thất bại: hóa đơn đã thanh toán hoặc payment không tồn tại
                request.setAttribute("error", "Khong the lam moi QR! Hoa don da duoc thanh toan hoac khong ton tai.");
            }

        } catch (Exception e) {
            request.setAttribute("error", "Loi: " + e.getMessage());
            e.printStackTrace();
        }
        listPayments(request); // Tải lại danh sách sau khi xử lý
    }

    /**
     * Kiểm tra và trả về trạng thái của một payment cụ thể dưới dạng JSON.
     * Method này được gọi bởi JavaScript polling trên trang QR để tự động phát hiện thanh toán.
     * Trả về JSON với: exists, paymentId, billId, amount, status, remainingSeconds, transactionId, paidAt.
     *
     * @param request  Chứa payment_id
     * @param response HttpServletResponse để ghi JSON
     */
    private void checkPaymentStatus(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json;charset=UTF-8"); // JSON response
        try {
            int paymentId = Integer.parseInt(request.getParameter("payment_id"));
            java.util.Map<String, Object> status = paymentService.getPaymentStatus(paymentId); // Lấy trạng thái

            // Build JSON thủ công từ map trả về
            StringBuilder json = new StringBuilder("{");
            json.append("\"exists\":").append(status.get("exists")); // Payment có tồn tại không

            if (Boolean.TRUE.equals(status.get("exists"))) {
                // Payment tồn tại → trả đầy đủ thông tin
                json.append(",\"paymentId\":").append(status.get("paymentId"));
                json.append(",\"billId\":").append(status.get("billId"));
                json.append(",\"amount\":").append(status.get("amount"));
                json.append(",\"status\":\"").append(status.get("status")).append("\"");
                json.append(",\"paymentMethod\":\"").append(status.get("paymentMethod")).append("\"");
                json.append(",\"remainingSeconds\":").append(status.get("remainingSeconds")); // Giây còn lại

                if (status.get("transactionId") != null) {
                    json.append(",\"transactionId\":\"").append(status.get("transactionId")).append("\"");
                }
                if (status.get("paidAt") != null) {
                    json.append(",\"paidAt\":\"").append(status.get("paidAt")).append("\""); // Thời điểm thanh toán
                }
            }

            json.append("}");
            response.getWriter().write(json.toString());

        } catch (Exception e) {
            // Lỗi: trả JSON error
            response.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    /**
     * Xác nhận thủ công rằng payment đã được thanh toán.
     * Admin sử dụng khi cần xác nhận chuyển khoản thủ công (không qua QR quét tự động).
     * Hỗ trợ AJAX (JSON) và standard (HTML redirect).
     *
     * @param request Chứa payment_id và transaction_id (mã giao dịch ngân hàng)
     */
    private void confirmPayment(HttpServletRequest request) {
        boolean ajax = isAjaxRequest(request);
        String source = request.getParameter("source");

        try {
            int paymentId        = Integer.parseInt(request.getParameter("payment_id"));
            String transactionId = request.getParameter("transaction_id");
            if (transactionId == null) transactionId = ""; // Mặc định rỗng nếu không có

            // Xác nhận thanh toán: cập nhật status → PAID, ghi transactionId và paidAt
            boolean success = paymentService.confirmPayment(paymentId, transactionId);

            if (success) {
                PaymentDTO payment = paymentService.getPaymentInfo(paymentId); // Lấy thông tin đã update

                if (ajax) {
                    // AJAX: trả JSON thành công
                    try {
                        writeQrJson(responseFrom(request), true, payment, "Xac nhan thanh toan thanh cong!", 200);
                    } catch (IOException ignored) {}
                    return;
                }

                if ("bill".equalsIgnoreCase(source)) {
                    url = "redirect:MainController?action=listBill&msg="
                            + java.net.URLEncoder.encode("Xac nhan thanh toan thanh cong!", "UTF-8");
                    return;
                }
                request.setAttribute("msg", "Xac nhan thanh toan thanh cong!");

            } else {
                // Thất bại: QR đã hết hạn hoặc payment không tồn tại
                if (ajax) {
                    try {
                        writeQrJson(responseFrom(request), false, null,
                                "Xac nhan thanh toan that bai! QR co the da het han.", 400);
                    } catch (IOException ignored) {}
                    return;
                }
                if ("bill".equalsIgnoreCase(source)) {
                    url = "redirect:MainController?action=listBill&error="
                            + java.net.URLEncoder.encode("Xac nhan thanh toan that bai! QR co the da het han.", "UTF-8");
                    return;
                }
                request.setAttribute("error", "Xac nhan thanh toan that bai! QR co the da het han.");
            }

        } catch (Exception e) {
            if (ajax) {
                try {
                    writeQrJson(responseFrom(request), false, null, "Loi: " + e.getMessage(), 500);
                } catch (IOException ignored) {}
                return;
            }
            request.setAttribute("error", "Loi: " + e.getMessage());
            e.printStackTrace();
        }
        listPayments(request);
    }

    /**
     * Lấy HttpServletResponse đã được lưu trong request attribute.
     * Dùng để AJAX method private có thể ghi trực tiếp vào response.
     *
     * @param request HttpServletRequest chứa attribute "__httpResponse"
     * @return HttpServletResponse, hoặc null nếu không có
     */
    private HttpServletResponse responseFrom(HttpServletRequest request) {
        Object responseObject = request.getAttribute("__httpResponse");
        return responseObject instanceof HttpServletResponse ? (HttpServletResponse) responseObject : null;
    }

    /**
     * Hủy payment (chuyển trạng thái → CANCELLED).
     *
     * @param request Chứa payment_id cần hủy
     */
    private void cancelPayment(HttpServletRequest request) {
        try {
            int paymentId = Integer.parseInt(request.getParameter("payment_id")); // ID payment cần hủy
            pms.model.PaymentDAO dao = new pms.model.PaymentDAO();
            boolean success = dao.cancelPayment(paymentId); // Gọi DAO cập nhật status → CANCELLED

            if (success) {
                request.setAttribute("msg", "Huy thanh toan thanh cong!");
            } else {
                request.setAttribute("error", "Huy thanh toan that bai!");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Loi: " + e.getMessage());
            e.printStackTrace();
        }
        listPayments(request);
    }

    /**
     * Tìm kiếm payment theo từ khóa và hiển thị kết quả.
     *
     * @param request Chứa "keyword" để tìm kiếm
     */
    private void searchPayments(HttpServletRequest request) {
        String keyword = request.getParameter("keyword");
        ArrayList<PaymentDTO> list = paymentService.searchPayments(keyword); // Gọi service tìm kiếm
        request.setAttribute("paymentList", list);
        request.setAttribute("keyword", keyword); // Giữ keyword để hiển thị lại trên form
        url = "payment-list.jsp";
    }

    /** Xử lý HTTP GET – xem danh sách, QR page */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – tạo QR, xác nhận, hủy */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Payment Controller";
    }
}
