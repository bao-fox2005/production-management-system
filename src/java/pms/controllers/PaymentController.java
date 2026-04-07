package pms.controllers;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.BillDAO;
import pms.model.BillDTO;
import pms.model.CustomerDAO;
import pms.model.CustomerDTO;
import pms.model.PaymentDTO;
import pms.model.WorkOrderDAO;
import pms.utils.EmailService;
import pms.utils.NotificationService;
import pms.utils.PaymentService;
import pms.utils.SystemConfigService;

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
                listPayments(request);
                break;
            case "saveBankConfig":
                saveBankConfig(request);
                break;
            case "saveBankAccounts":
                saveBankAccounts(request);
                break;
            case "switchActiveAccountQuick":
                switchActiveAccountQuick(request);
                break;
            case "createQr":
                createQrPayment(request, response);
                break;
            case "refreshQr":
                refreshQrPayment(request);
                break;
            case "checkStatus":
                checkPaymentStatus(request, response);
                return;
            case "confirmPayment":
                confirmPayment(request);
                break;
            case "cancelPayment":
                cancelPayment(request);
                break;
            case "search":
            case "pending":
            case "paid":
                request.setAttribute("msg", "Màn hình này hiện dùng để quản lý thông tin nhận tiền. Lịch sử thanh toán vẫn được giữ trong hệ thống.");
                listPayments(request);
                break;
            default:
                listPayments(request);
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

    private void listPayments(HttpServletRequest request) {
        bindBankConfigView(request);
        request.setAttribute("activePage", "payment-config");
        request.setAttribute("pageTitle", "Quản lý thanh toán");
        url = "payment-list.jsp";
    }

    private void bindBankConfigView(HttpServletRequest request) {
        SystemConfigService configService = new SystemConfigService();

        String serialized = configService.getConfig("BANK_RECEIVER_ACCOUNTS", "");
        java.util.List<String[]> accounts = parseAccounts(serialized);

        if (accounts.isEmpty()) {
            String bankBin = configService.getConfig("BANK_PRIMARY_BIN", configService.getConfig("BANK_BIN", "970406"));
            String bankAccount = configService.getConfig("BANK_PRIMARY_ACCOUNT", configService.getConfig("BANK_ACCOUNT", "1234567890"));
            String bankAccountName = configService.getConfig("BANK_PRIMARY_ACCOUNT_NAME", configService.getConfig("BANK_ACCOUNT_NAME", "CONG TY TNHH PMS"));
            accounts.add(new String[]{"A1", sanitizeBankField(bankBin), sanitizeBankField(bankAccount), sanitizeBankField(bankAccountName)});

            String altBankBin = configService.getConfig("BANK_ALT_BIN", "");
            String altBankAccount = configService.getConfig("BANK_ALT_ACCOUNT", "");
            String altBankAccountName = configService.getConfig("BANK_ALT_ACCOUNT_NAME", "");
            if (!isBlank(altBankBin) && !isBlank(altBankAccount) && !isBlank(altBankAccountName)) {
                accounts.add(new String[]{"A2", sanitizeBankField(altBankBin), sanitizeBankField(altBankAccount), sanitizeBankField(altBankAccountName)});
            }
            serialized = serializeAccounts(accounts);
            configService.setConfig("BANK_RECEIVER_ACCOUNTS", serialized);
        }

        String activeId = configService.getConfig("BANK_ACTIVE_ACCOUNT_ID", "");
        if (!containsAccount(accounts, activeId)) {
            activeId = !accounts.isEmpty() ? accounts.get(0)[0] : "";
            configService.setConfig("BANK_ACTIVE_ACCOUNT_ID", activeId);
        }

        // Backward-compatible attrs cho JSP cũ
        String[] first = !accounts.isEmpty() ? accounts.get(0) : new String[]{"A1", "970406", "1234567890", "CONG TY TNHH PMS"};
        String[] second = accounts.size() > 1 ? accounts.get(1) : new String[]{"", "", "", ""};

        request.setAttribute("bankBin", first[1]);
        request.setAttribute("bankAccount", first[2]);
        request.setAttribute("bankAccountName", first[3]);
        request.setAttribute("altBankBin", second[1]);
        request.setAttribute("altBankAccount", second[2]);
        request.setAttribute("altBankAccountName", second[3]);
        request.setAttribute("primaryProfile", second[0].equals(activeId) ? "ALT" : "PRIMARY");

        request.setAttribute("bankAccountsData", serialized);
        request.setAttribute("bankActiveAccountId", activeId);
    }

    private void saveBankConfig(HttpServletRequest request) {
        String bankBin = request.getParameter("bank_bin") != null ? request.getParameter("bank_bin").trim() : "";
        String bankAccount = request.getParameter("bank_account") != null ? request.getParameter("bank_account").trim() : "";
        String bankAccountName = request.getParameter("bank_account_name") != null ? request.getParameter("bank_account_name").trim() : "";

        String altBankBin = request.getParameter("alt_bank_bin") != null ? request.getParameter("alt_bank_bin").trim() : "";
        String altBankAccount = request.getParameter("alt_bank_account") != null ? request.getParameter("alt_bank_account").trim() : "";
        String altBankAccountName = request.getParameter("alt_bank_account_name") != null ? request.getParameter("alt_bank_account_name").trim() : "";

        String primaryProfile = request.getParameter("primary_profile");
        primaryProfile = "ALT".equalsIgnoreCase(primaryProfile) ? "ALT" : "PRIMARY";

        if (bankBin.isEmpty() || bankAccount.isEmpty() || bankAccountName.isEmpty()) {
            request.setAttribute("error", "Vui lòng nhập đầy đủ thông tin cho ngân hàng chính.");
            request.setAttribute("bankBin", bankBin);
            request.setAttribute("bankAccount", bankAccount);
            request.setAttribute("bankAccountName", bankAccountName);
            request.setAttribute("altBankBin", altBankBin);
            request.setAttribute("altBankAccount", altBankAccount);
            request.setAttribute("altBankAccountName", altBankAccountName);
            request.setAttribute("primaryProfile", primaryProfile);
            request.setAttribute("activePage", "payment-config");
            request.setAttribute("pageTitle", "Quản lý thanh toán");
            url = "payment-list.jsp";
            return;
        }

        if ("ALT".equals(primaryProfile)
                && (altBankBin.isEmpty() || altBankAccount.isEmpty() || altBankAccountName.isEmpty())) {
            request.setAttribute("error", "Đã chọn ngân hàng phụ làm mặc định, vui lòng nhập đầy đủ thông tin ngân hàng phụ.");
            request.setAttribute("bankBin", bankBin);
            request.setAttribute("bankAccount", bankAccount);
            request.setAttribute("bankAccountName", bankAccountName);
            request.setAttribute("altBankBin", altBankBin);
            request.setAttribute("altBankAccount", altBankAccount);
            request.setAttribute("altBankAccountName", altBankAccountName);
            request.setAttribute("primaryProfile", primaryProfile);
            request.setAttribute("activePage", "payment-config");
            request.setAttribute("pageTitle", "Quản lý thanh toán");
            url = "payment-list.jsp";
            return;
        }

        SystemConfigService configService = new SystemConfigService();

        boolean ok = true;
        ok &= configService.setConfig("BANK_PRIMARY_BIN", bankBin);
        ok &= configService.setConfig("BANK_PRIMARY_ACCOUNT", bankAccount);
        ok &= configService.setConfig("BANK_PRIMARY_ACCOUNT_NAME", bankAccountName);

        ok &= configService.setConfig("BANK_ALT_BIN", altBankBin);
        ok &= configService.setConfig("BANK_ALT_ACCOUNT", altBankAccount);
        ok &= configService.setConfig("BANK_ALT_ACCOUNT_NAME", altBankAccountName);
        ok &= configService.setConfig("BANK_PRIMARY_PROFILE", primaryProfile);

        String activeBin = "ALT".equals(primaryProfile) ? altBankBin : bankBin;
        String activeAccount = "ALT".equals(primaryProfile) ? altBankAccount : bankAccount;
        String activeAccountName = "ALT".equals(primaryProfile) ? altBankAccountName : bankAccountName;

        ok &= configService.setConfig("BANK_BIN", activeBin);
        ok &= configService.setConfig("BANK_ACCOUNT", activeAccount);
        ok &= configService.setConfig("BANK_ACCOUNT_NAME", activeAccountName);

        if (ok) {
            request.setAttribute("msg", "Đã lưu thông tin ngân hàng và cập nhật tài khoản nhận tiền mặc định.");
        } else {
            request.setAttribute("error", "Có lỗi khi lưu cấu hình ngân hàng. Vui lòng thử lại.");
        }

        listPayments(request);
    }

    private void saveBankAccounts(HttpServletRequest request) {
        String rawAccounts = request.getParameter("accounts_data");
        String activeId = request.getParameter("active_account_id");

        java.util.List<String[]> accounts = parseAccounts(rawAccounts);
        if (accounts.isEmpty()) {
            request.setAttribute("error", "Phải có ít nhất một tài khoản nhận tiền hợp lệ.");
            listPayments(request);
            return;
        }

        if (!containsAccount(accounts, activeId)) {
            activeId = accounts.get(0)[0];
        }

        String[] active = findAccount(accounts, activeId);
        if (active == null) {
            request.setAttribute("error", "Không xác định được tài khoản nhận tiền đang hoạt động.");
            listPayments(request);
            return;
        }

        SystemConfigService configService = new SystemConfigService();
        boolean ok = true;

        String serialized = serializeAccounts(accounts);
        ok &= configService.setConfig("BANK_RECEIVER_ACCOUNTS", serialized);
        ok &= configService.setConfig("BANK_ACTIVE_ACCOUNT_ID", activeId);

        // Hệ thống QR hiện tại dùng BANK_* nên luôn đồng bộ theo active account
        ok &= configService.setConfig("BANK_BIN", active[1]);
        ok &= configService.setConfig("BANK_ACCOUNT", active[2]);
        ok &= configService.setConfig("BANK_ACCOUNT_NAME", active[3]);

        // Giữ tương thích config cũ
        String[] first = accounts.get(0);
        String[] second = accounts.size() > 1 ? accounts.get(1) : new String[]{"", "", "", ""};
        ok &= configService.setConfig("BANK_PRIMARY_BIN", first[1]);
        ok &= configService.setConfig("BANK_PRIMARY_ACCOUNT", first[2]);
        ok &= configService.setConfig("BANK_PRIMARY_ACCOUNT_NAME", first[3]);
        ok &= configService.setConfig("BANK_ALT_BIN", second[1]);
        ok &= configService.setConfig("BANK_ALT_ACCOUNT", second[2]);
        ok &= configService.setConfig("BANK_ALT_ACCOUNT_NAME", second[3]);
        ok &= configService.setConfig("BANK_PRIMARY_PROFILE", second[0].equals(activeId) ? "ALT" : "PRIMARY");

        if (ok) {
            request.setAttribute("msg", "Đã cập nhật danh sách tài khoản nhận tiền và chuyển tài khoản hoạt động thành công.");
        } else {
            request.setAttribute("error", "Không thể lưu danh sách tài khoản nhận tiền. Vui lòng thử lại.");
        }
        listPayments(request);
    }

    private void switchActiveAccountQuick(HttpServletRequest request) {
        String activeId = request.getParameter("active_account_id") != null
                ? request.getParameter("active_account_id").trim() : "";
        String redirect = request.getParameter("redirect") != null
                ? request.getParameter("redirect").trim() : "";

        if (redirect.isEmpty() || redirect.contains("://")) {
            redirect = "MainController?action=listBill";
        }

        SystemConfigService configService = new SystemConfigService();
        java.util.List<String[]> accounts = parseAccounts(configService.getConfig("BANK_RECEIVER_ACCOUNTS", ""));
        if (accounts.isEmpty()) {
            url = "redirect:" + redirect;
            return;
        }

        if (!containsAccount(accounts, activeId)) {
            activeId = accounts.get(0)[0];
        }

        String[] active = findAccount(accounts, activeId);
        if (active == null) {
            active = accounts.get(0);
            activeId = active[0];
        }

        configService.setConfig("BANK_ACTIVE_ACCOUNT_ID", activeId);
        configService.setConfig("BANK_BIN", active[1]);
        configService.setConfig("BANK_ACCOUNT", active[2]);
        configService.setConfig("BANK_ACCOUNT_NAME", active[3]);

        request.getSession().setAttribute("msg", "Đã chuyển nhanh tài khoản nhận tiền mặc định.");
        url = "redirect:" + redirect;
    }

    private java.util.List<String[]> parseAccounts(String raw) {
        java.util.List<String[]> accounts = new java.util.ArrayList<>();
        if (raw == null || raw.trim().isEmpty()) {
            return accounts;
        }

        String[] rows = raw.split(";;");
        for (String row : rows) {
            if (row == null || row.trim().isEmpty()) {
                continue;
            }
            // Tách đúng theo delimiter "||" (literal), không phải regex alternation
            String[] parts = row.split("\\|\\|", -1);
            if (parts.length < 4) {
                continue;
            }
            String id = sanitizeBankField(parts[0]);
            String bin = sanitizeBankField(parts[1]);
            String account = sanitizeBankField(parts[2]);
            String accountName = sanitizeBankField(parts[3]);
            if (isBlank(id) || isBlank(bin) || isBlank(account) || isBlank(accountName)) {
                continue;
            }
            accounts.add(new String[]{id, bin, account, accountName});
        }
        return accounts;
    }

    private String serializeAccounts(java.util.List<String[]> accounts) {
        StringBuilder sb = new StringBuilder();
        for (String[] a : accounts) {
            if (a == null || a.length < 4) {
                continue;
            }
            String id = sanitizeBankField(a[0]);
            String bin = sanitizeBankField(a[1]);
            String account = sanitizeBankField(a[2]);
            String accountName = sanitizeBankField(a[3]);
            if (isBlank(id) || isBlank(bin) || isBlank(account) || isBlank(accountName)) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(";;");
            }
            sb.append(id).append("||").append(bin).append("||").append(account).append("||").append(accountName);
        }
        return sb.toString();
    }

    private String sanitizeBankField(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("||", " ").replace(";;", " ").trim();
    }

    private boolean containsAccount(java.util.List<String[]> accounts, String id) {
        return findAccount(accounts, id) != null;
    }

    private String[] findAccount(java.util.List<String[]> accounts, String id) {
        if (accounts == null || id == null) {
            return null;
        }
        for (String[] a : accounts) {
            if (a != null && a.length >= 4 && id.equals(a[0])) {
                return a;
            }
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
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
            String bankBin       = request.getParameter("bank_bin");
            String bankAccount   = request.getParameter("bank_account");
            String bankOwner     = request.getParameter("bank_account_name");

            // Đặt giá trị mặc định nếu không có
            if (customerName  == null) customerName  = "Khach hang";
            if (customerEmail == null) customerEmail = "";

            // Tạo QR payment thông qua service layer (cho phép chọn tài khoản nhận tiền từ bill.jsp)
            PaymentDTO payment = paymentService.createQrPayment(billId, amount, expireMinutes,
                    customerName, customerEmail, bankBin, bankAccount, bankOwner);

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
        boolean ajax = isAjaxRequest(request);
        String source = request.getParameter("source");

        try {
            int paymentId     = Integer.parseInt(request.getParameter("payment_id")); // ID payment cần làm mới
            int expireMinutes = 15; // Mặc định 15 phút

            String expireStr = request.getParameter("expire_minutes");
            if (expireStr != null && !expireStr.isEmpty()) {
                expireMinutes = Integer.parseInt(expireStr); // Override thời gian hết hạn
            }

            boolean success = paymentService.refreshQrCode(paymentId, expireMinutes); // Làm mới QR
            if (success) {
                PaymentDTO updated = paymentService.getPaymentInfo(paymentId);

                if (ajax) {
                    try {
                        writeQrJson(responseFrom(request), true, updated,
                                "QR code da duoc tao lai thanh cong!", 200);
                    } catch (IOException ignored) {}
                    return;
                }

                request.setAttribute("msg", "QR code da duoc lam moi! Thoi gian dem nguoc da duoc reset.");
                request.setAttribute("payment", updated);
                if ("bill".equalsIgnoreCase(source)) {
                    url = "redirect:MainController?action=listBill&msg="
                            + java.net.URLEncoder.encode("QR code da duoc tao lai thanh cong!", "UTF-8");
                    return;
                }
            } else {
                String error = "Khong the lam moi QR! Hoa don da duoc thanh toan hoac khong ton tai.";
                if (ajax) {
                    try {
                        writeQrJson(responseFrom(request), false, null, error, 400);
                    } catch (IOException ignored) {}
                    return;
                }

                request.setAttribute("error", error);
                if ("bill".equalsIgnoreCase(source)) {
                    url = "redirect:MainController?action=listBill&error="
                            + java.net.URLEncoder.encode(error, "UTF-8");
                    return;
                }
            }

        } catch (Exception e) {
            String error = "Loi: " + e.getMessage();
            if (ajax) {
                try {
                    writeQrJson(responseFrom(request), false, null, error, 500);
                } catch (IOException ignored) {}
                return;
            }

            request.setAttribute("error", error);
            if ("bill".equalsIgnoreCase(source)) {
                try {
                    url = "redirect:MainController?action=listBill&error="
                            + java.net.URLEncoder.encode(error, "UTF-8");
                } catch (Exception encodeEx) {
                    url = "redirect:MainController?action=listBill&error=Loi%20tao%20lai%20QR";
                }
                return;
            }
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
                handleAfterPaymentConfirmed(payment, request);

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

    private void handleAfterPaymentConfirmed(PaymentDTO payment, HttpServletRequest request) {
        if (payment == null || payment.getBillId() <= 0) {
            return;
        }

        try {
            BillDAO billDAO = new BillDAO();
            BillDTO bill = billDAO.SearchByBillID(String.valueOf(payment.getBillId()));
            if (bill == null) {
                return;
            }

            billDAO.updateBillStatusPaid(bill.getBill_id(), new Timestamp(System.currentTimeMillis()));

            if (bill.getWo_id() > 0) {
                WorkOrderDAO workOrderDAO = new WorkOrderDAO();
                workOrderDAO.updateWorkOrderStatusOnly(bill.getWo_id(), "ChoSX");
            }

            CustomerDTO customer = null;
            if (bill.getCustomer_id() > 0) {
                customer = new CustomerDAO().SearchByCustomerID(String.valueOf(bill.getCustomer_id()));
            }

            String customerEmail = customer != null && customer.getEmail() != null && !customer.getEmail().trim().isEmpty()
                    ? customer.getEmail().trim()
                    : (payment.getCustomerEmail() != null ? payment.getCustomerEmail().trim() : "");
            String customerName = customer != null && customer.getCustomer_name() != null && !customer.getCustomer_name().trim().isEmpty()
                    ? customer.getCustomer_name().trim()
                    : (payment.getCustomerName() != null ? payment.getCustomerName().trim() : "");
            if (customerName == null || customerName.trim().isEmpty()) {
                customerName = "Quý khách";
            }

            SystemConfigService configService = new SystemConfigService();
            EmailService emailService = configService.createEmailService();
            if (emailService != null && emailService.isConfigured()
                    && customerEmail != null && !customerEmail.trim().isEmpty()) {
                String billCode = String.valueOf(bill.getBill_id());
                String baseUrl = buildBaseUrl(request);
                String viewLink = baseUrl + "/BillController?action=viewPublicBill&bill_id=" + billCode;
                String downloadLink = baseUrl + "/BillController?action=downloadPublicBill&bill_id=" + billCode;
                String amountText = String.format("%,.0f VND", payment.getAmount() > 0 ? payment.getAmount() : bill.getTotal_amount());
                String paidAtText = payment.getPaidAt() != null
                        ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(payment.getPaidAt())
                        : new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());

                StringBuilder body = new StringBuilder();
                body.append("<!DOCTYPE html><html><head><meta charset='UTF-8'></head><body style='margin:0;padding:20px;background:#f8fafc;font-family:Segoe UI,Arial,sans-serif'>")
                        .append("<div style='max-width:760px;margin:0 auto;background:#fff;border:1px solid #dbeafe;border-radius:14px;overflow:hidden'>")
                        .append("<div style='background:linear-gradient(120deg,#0f766e,#0284c7);padding:18px 22px;color:#fff'>")
                        .append("<div style='font-size:12px;letter-spacing:.1em;opacity:.9'>PAYMENT CONFIRMED</div>")
                        .append("<h2 style='margin:8px 0 0'>Hóa đơn #").append(escapeHtml(billCode)).append(" đã thanh toán</h2>")
                        .append("</div>")
                        .append("<div style='padding:20px'>")
                        .append("<p>Xin chào <strong>").append(escapeHtml(customerName)).append("</strong>, PMS đã xác nhận thanh toán thành công.</p>")
                        .append("<table style='width:100%;border-collapse:collapse;margin:16px 0'>")
                        .append("<tr><td style='border:1px solid #e5e7eb;padding:10px'><b>Mã hóa đơn</b></td><td style='border:1px solid #e5e7eb;padding:10px'>#").append(escapeHtml(billCode)).append("</td></tr>")
                        .append("<tr><td style='border:1px solid #e5e7eb;padding:10px'><b>Số tiền</b></td><td style='border:1px solid #e5e7eb;padding:10px'>").append(amountText).append("</td></tr>")
                        .append("<tr><td style='border:1px solid #e5e7eb;padding:10px'><b>Thời gian thanh toán</b></td><td style='border:1px solid #e5e7eb;padding:10px'>").append(escapeHtml(paidAtText)).append("</td></tr>")
                        .append("<tr><td style='border:1px solid #e5e7eb;padding:10px'><b>Trạng thái</b></td><td style='border:1px solid #e5e7eb;padding:10px;color:#047857;font-weight:700'>ĐÃ THANH TOÁN</td></tr>")
                        .append("</table>")
                        .append("<div style='margin-top:16px'>")
                        .append("<a href='").append(viewLink).append("' style='display:inline-block;margin-right:8px;background:#0f766e;color:#fff;padding:10px 14px;border-radius:8px;text-decoration:none'>Xem hóa đơn</a>")
                        .append("<a href='").append(downloadLink).append("' style='display:inline-block;background:#1d4ed8;color:#fff;padding:10px 14px;border-radius:8px;text-decoration:none'>Tải hóa đơn</a>")
                        .append("</div>")
                        .append("</div></div></body></html>");

                boolean customerMailSent = emailService.sendEmail(
                        customerEmail,
                        "[PMS] Đã xác nhận thanh toán hóa đơn #" + billCode,
                        body.toString()
                );
                if (!customerMailSent) {
                    System.err.println("Không gửi được email xác nhận thanh toán tới khách hàng: "
                            + customerEmail + " - " + emailService.getLastError());
                }
            }

            NotificationService.notifyPaymentCompletedGlobal(
                    payment.getPaymentId(),
                    payment.getAmount() > 0 ? payment.getAmount() : bill.getTotal_amount());

        } catch (Exception e) {
            request.setAttribute("msg", "Xac nhan thanh toan thanh cong, nhung mot so tiep noi sau thanh toan bi loi.");
            e.printStackTrace();
        }
    }

    private String buildBaseUrl(HttpServletRequest request) {
        if (request == null) {
            return "";
        }
        String scheme = request.getScheme();
        String host = request.getServerName();
        int port = request.getServerPort();
        boolean defaultPort = ("http".equalsIgnoreCase(scheme) && port == 80)
                || ("https".equalsIgnoreCase(scheme) && port == 443);
        return scheme + "://" + host + (defaultPort ? "" : ":" + port) + request.getContextPath();
    }

    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
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
