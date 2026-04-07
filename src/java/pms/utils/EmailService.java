package pms.utils;

import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.util.Properties;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

public class EmailService implements Serializable {

    private static final long serialVersionUID = 1L;

    private String smtpHost;
    private String smtpPort;
    private String smtpUser;
    private String smtpPassword;
    private String lastError;

    public EmailService() {
    }

    public EmailService(String smtpHost, String smtpPort, String smtpUser, String smtpPassword) {
        this.smtpHost = smtpHost;
        this.smtpPort = smtpPort;
        this.smtpUser = smtpUser;
        this.smtpPassword = smtpPassword;
    }

    public boolean sendEmail(String to, String subject, String body) {
        lastError = null;
        if (to == null || to.trim().isEmpty()) {
            lastError = "Email nhận không được để trống.";
            System.err.println("EmailService: " + lastError);
            return false;
        }
        if (subject == null) subject = "(Khong co tieu de)";
        if (body == null) body = "";

        Session session = null;
        MimeMessage message = null;
        try {
            session = createSession();
            message = new MimeMessage(session);

            InternetAddress fromAddress = new InternetAddress();
            fromAddress.setAddress(smtpUser.trim());
            fromAddress.setPersonal("PMS System", "UTF-8");
            message.setFrom(fromAddress);

            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to.trim()));
            message.setSubject(subject, "UTF-8");
            message.setContent(body, "text/html; charset=UTF-8");
            message.setHeader("X-Mailer", "PMS-EmailService/1.0");

            Transport.send(message);
            System.out.println("Email da gui thanh cong den: " + to);
            return true;
        } catch (UnsupportedEncodingException e) {
            lastError = "Lỗi mã hóa email: " + e.getMessage();
            System.err.println("Email encoding error to " + to + ": " + e.getMessage());
            return false;
        } catch (MessagingException e) {
            lastError = buildMessagingError(e);
            System.err.println("Email send failed to " + to + ": " + e.getMessage());
            return false;
        } catch (Exception e) {
            lastError = "Lỗi không xác định khi gửi mail: " + e.getMessage();
            System.err.println("Email send unexpected error to " + to + ": " + e.getMessage());
            return false;
        }
    }

    public boolean sendEmailBcc(String to, String bcc, String subject, String body) {
        if (to == null || to.trim().isEmpty()) {
            return false;
        }
        if (subject == null) subject = "(Khong co tieu de)";
        if (body == null) body = "";

        Session session = null;
        MimeMessage message = null;
        try {
            session = createSession();
            message = new MimeMessage(session);

            InternetAddress fromAddress = new InternetAddress();
            fromAddress.setAddress(smtpUser.trim());
            fromAddress.setPersonal("PMS System", "UTF-8");
            message.setFrom(fromAddress);

            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to.trim()));
            if (bcc != null && !bcc.trim().isEmpty()) {
                message.setRecipients(Message.RecipientType.BCC, InternetAddress.parse(bcc.trim()));
            }
            message.setSubject(subject, "UTF-8");
            message.setContent(body, "text/html; charset=UTF-8");

            Transport.send(message);
            return true;
        } catch (UnsupportedEncodingException e) {
            System.err.println("Email BCC encoding error: " + e.getMessage());
            return false;
        } catch (MessagingException e) {
            System.err.println("Email BCC send failed: " + e.getMessage());
            return false;
        } catch (Exception e) {
            System.err.println("Email BCC unexpected error: " + e.getMessage());
            return false;
        }
    }

    public boolean sendBillPaymentSuccess(String adminEmail, String billCode,
            String customerName, double amount, String transactionId) {
        String subject = "[PMS] Xac nhan thanh toan - Hoa don #" + billCode;
        String body = buildPaymentSuccessEmail(billCode, customerName, amount, transactionId);
        return sendEmail(adminEmail, subject, body);
    }

    public boolean sendOrderCompletionNotification(String adminEmail, String orderCode,
            String customerName, double amount, String employeeName) {
        String subject = "[PMS] Don hang hoan thanh - " + orderCode;
        String body = buildOrderCompletionEmail(orderCode, customerName, amount, employeeName);
        return sendEmail(adminEmail, subject, body);
    }

    public boolean sendWorkOrderCompleted(String adminEmail, int woId, String productName,
            int quantity, String employeeName) {
        String subject = "[PMS] Lenh san xuat hoan thanh - WO#" + woId;
        String body = buildWorkOrderCompletedEmail(woId, productName, quantity, employeeName);
        return sendEmail(adminEmail, subject, body);
    }

    public boolean sendNewBillNotification(String adminEmail, String billCode,
            String customerName, double amount) {
        String subject = "[PMS] Hoa don moi - #" + billCode;
        String body = buildNewBillEmail(billCode, customerName, amount);
        return sendEmail(adminEmail, subject, body);
    }

    // ==================== KHACH HANG NOTIFICATIONS ====================

    public boolean sendCustomerOrderConfirmation(String customerEmail, String customerName,
            int woId, String productName, int quantity, String expectedDate) {
        if (customerEmail == null || customerEmail.trim().isEmpty()) return false;
        String subject = "[PMS] Xac nhan don hang #" + woId;
        String body = buildCustomerOrderConfirmation(woId, customerName, productName, quantity, expectedDate);
        return sendEmail(customerEmail, subject, body);
    }

    public boolean sendCustomerOrderCompletion(String customerEmail, String customerName,
            int woId, String productName, int quantity) {
        if (customerEmail == null || customerEmail.trim().isEmpty()) return false;
        String subject = "[PMS] Don hang #" + woId + " da hoan thanh!";
        String body = buildCustomerOrderCompletion(woId, customerName, productName, quantity);
        return sendEmail(customerEmail, subject, body);
    }

    public boolean sendCustomerPaymentRequest(String customerEmail, String customerName,
            String billCode, double amount, String qrDataUrl, String bankInfo) {
        if (customerEmail == null || customerEmail.trim().isEmpty()) return false;
        String subject = "[PMS] Thanh toan hoa don #" + billCode + " - " + String.format("%,.0f VND", amount);
        String body = buildCustomerPaymentRequest(customerEmail, customerName, billCode, amount, qrDataUrl, bankInfo);
        return sendEmail(customerEmail, subject, body);
    }

    public boolean sendCustomerPaymentConfirmation(String customerEmail, String customerName,
            String billCode, double amount) {
        if (customerEmail == null || customerEmail.trim().isEmpty()) return false;
        String subject = "[PMS] Xac nhan thanh toan hoa don #" + billCode;
        String body = buildCustomerPaymentConfirmation(customerName, billCode, amount);
        return sendEmail(customerEmail, subject, body);
    }

    public boolean sendCustomerShippingNotification(String customerEmail, String customerName,
            int woId, String productName, String shippingInfo) {
        if (customerEmail == null || customerEmail.trim().isEmpty()) return false;
        String subject = "[PMS] Don hang #" + woId + " dang duoc giao!";
        String body = buildCustomerShippingNotification(customerName, woId, productName, shippingInfo);
        return sendEmail(customerEmail, subject, body);
    }

    public boolean sendCustomerDefectAlert(String customerEmail, String customerName,
            int woId, String productName, String defectInfo, String resolutionPlan) {
        if (customerEmail == null || customerEmail.trim().isEmpty()) return false;
        String subject = "[PMS] Thong bao ve san pham loi - Don hang #" + woId;
        String body = buildCustomerDefectAlert(customerName, woId, productName, defectInfo, resolutionPlan);
        return sendEmail(customerEmail, subject, body);
    }

    // ==================== TEMPLATES FOR CUSTOMERS ====================

    private String buildCustomerOrderConfirmation(int woId, String customerName,
            String productName, int quantity, String expectedDate) {
        String name = customerName != null ? escapeHtml(customerName) : "Quy khach";
        String prod = productName != null ? escapeHtml(productName) : "-";
        String date = expectedDate != null ? expectedDate : "Dang xu ly";
        String now = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());

        return htmlDoc(
            "#059669",
            "Xac Nhan Don Hang #" + woId,
            "Cam on " + name + " da dat hang tai PMS System!",
            new String[][] {
                {"Ma don hang", "#" + woId},
                {"San pham", prod},
                {"So luong", String.valueOf(quantity)},
                {"Ngay dat", now},
                {"Ngay giao du kien", date},
            },
            "Chung toi se thong bao ngay khi don hang san sang giao. Vui long thanh toan hoa don truoc khi giao hang.",
            "Xem trang thai don hang"
        );
    }

    private String buildCustomerOrderCompletion(int woId, String customerName,
            String productName, int quantity) {
        String name = customerName != null ? escapeHtml(customerName) : "Quy khach";
        String prod = productName != null ? escapeHtml(productName) : "-";

        return htmlDoc(
            "#2563eb",
            "Don Hang #" + woId + " Da Hoan Thanh!",
            "Xin chao " + name + ", don hang cua ban da duoc hoan thanh va san sang giao!",
            new String[][] {
                {"Ma don hang", "#" + woId},
                {"San pham", prod},
                {"So luong", String.valueOf(quantity)},
                {"Trang thai", "Hoan Thanh"},
            },
            "Chung toi se lien he de sap xep giao hang trong thoi gian som nhat. Cam on ban da tin tuong PMS System!",
            "Lien he ho tro"
        );
    }

    private String buildCustomerPaymentRequest(String customerEmail, String customerName,
            String billCode, double amount, String qrDataUrl, String bankInfo) {
        String name = customerName != null ? escapeHtml(customerName) : "Quy khach";
        String formattedAmount = String.format("%,.0f VND", amount);
        String now = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());

        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:#d97706;padding:28px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.6rem;\">Yeu Cau Thanh Toan</h1>\n");
        sb.append("<p style=\"color:rgba(255,255,255,0.9);margin:8px 0 0;font-size:0.95rem;\">Hoa don #").append(billCode).append("</p>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:28px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>Xin chao <strong>").append(name).append("</strong>,</p>\n");
        sb.append("<p>Chung toi can ban thanh toan hoa don sau:</p>\n");
        sb.append("<div style=\"background:#fef3c7;border-radius:12px;padding:20px;text-align:center;margin:20px 0;\">\n");
        sb.append("<p style=\"margin:0;font-size:0.9rem;color:#92400e;\">So tien can thanh toan</p>\n");
        sb.append("<p style=\"margin:8px 0 0;font-size:2.2rem;font-weight:bold;color:#d97706;\">").append(formattedAmount).append("</p>\n");
        sb.append("</div>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:16px 0;\">\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma hoa don</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">#").append(billCode).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ngay tao</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(now).append("</td></tr>\n");
        if (bankInfo != null) {
            sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Thong tin chuyen khoan</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(escapeHtml(bankInfo)).append("</td></tr>\n");
        }
        sb.append("</table>\n");
        if (qrDataUrl != null && qrDataUrl.contains("data:image")) {
            sb.append("<div style=\"text-align:center;margin:24px 0;\">\n");
            sb.append("<p style=\"font-weight:bold;color:#374151;margin-bottom:12px;\">Quet QR de thanh toan:</p>\n");
            sb.append("<img src=\"").append(qrDataUrl).append("\" alt=\"QR Thanh Toan\" style=\"max-width:220px;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.1);\">\n");
            sb.append("</div>\n");
        }
        sb.append("<div style=\"background:#f3f4f6;border-radius:8px;padding:16px;margin:16px 0;\">\n");
        sb.append("<p style=\"margin:0;font-size:0.85rem;color:#6b7280;\"><b>Luu y:</b> Vui long ghi ro ma hoa don trong noi dung chuyen khoan de chung toi xac nhan nhanh chong.</p>\n");
        sb.append("</div>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">Neu co thac mac, vui long lien he ho tro qua email nay.</p>\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">PMS System - Production Management</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private String buildCustomerPaymentConfirmation(String customerName,
            String billCode, double amount) {
        String name = customerName != null ? escapeHtml(customerName) : "Quy khach";
        String formattedAmount = String.format("%,.0f VND", amount);
        String now = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());

        return htmlDoc(
            "#059669",
            "Xac Nhan Thanh Toan - Hoa Don #" + billCode,
            "Xin chao " + name + ", chung toi da nhan duoc thanh toan cua ban!",
            new String[][] {
                {"Ma hoa don", "#" + billCode},
                {"So tien", formattedAmount},
                {"Thoi gian thanh toan", now},
                {"Trang thai", "Da xac nhan"},
            },
            "Chung toi se tiep tuc xu ly don hang va thong bao cho ban khi san pham san sang. Cam on ban da tin tuong PMS System!",
            "Xem don hang cua toi"
        );
    }

    private String buildCustomerShippingNotification(String customerName,
            int woId, String productName, String shippingInfo) {
        String name = customerName != null ? escapeHtml(customerName) : "Quy khach";
        String prod = productName != null ? escapeHtml(productName) : "-";
        String info = shippingInfo != null ? escapeHtml(shippingInfo) : "Dang giao hang";

        return htmlDoc(
            "#7c3aed",
            "Don Hang #" + woId + " Dang Duoc Giao!",
            "Xin chao " + name + ", don hang cua ban dang trong qua trinh giao hang!",
            new String[][] {
                {"Ma don hang", "#" + woId},
                {"San pham", prod},
                {"Thong tin giao hang", info},
                {"Trang thai", "Dang giao"},
            },
            "Vui long dam bao co nguoi nhan tai dia chi giao hang. Lien he ho tro neu can thay doi thong tin.",
            "Theo doi don hang"
        );
    }

    private String buildCustomerDefectAlert(String customerName,
            int woId, String productName, String defectInfo, String resolutionPlan) {
        String name = customerName != null ? escapeHtml(customerName) : "Quy khach";
        String prod = productName != null ? escapeHtml(productName) : "-";
        String defect = defectInfo != null ? escapeHtml(defectInfo) : "Dang xac dinh";
        String plan = resolutionPlan != null ? escapeHtml(resolutionPlan) : "Dang xu ly";

        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:#dc2626;padding:28px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.6rem;\">Thong Bao San Pham Loi</h1>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:28px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>Xin chao <strong>").append(name).append("</strong>,</p>\n");
        sb.append("<p>Trong qua trinh kiem tra chat luong, chung toi phat hien van de voi san pham trong don hang cua ban:</p>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:20px 0;\">\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma don hang</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">#").append(woId).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>San pham</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(prod).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Van de phat hien</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(defect).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Huong xu ly</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(plan).append("</td></tr>\n");
        sb.append("</table>\n");
        sb.append("<div style=\"background:#fef2f2;border-radius:8px;padding:16px;margin:16px 0;\">\n");
        sb.append("<p style=\"margin:0;font-size:0.9rem;color:#991b1b;\"><b>Chung toi rat tiec ve su bat tien nay.</b> Dong minh se xu ly nhanh chong de dam bao quyen loi cua ban duoc bao toan.</p>\n");
        sb.append("</div>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">PMS System - Production Management</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private String htmlDoc(String headerColor, String title, String intro, String[][] fields,
            String note, String actionLabel) {
        String now = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());
        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:").append(headerColor).append(";padding:28px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.6rem;\">").append(title).append("</h1>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:28px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>").append(intro).append("</p>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:20px 0;\">\n");
        for (String[] row : fields) {
            sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>").append(row[0]).append("</b></td>");
            sb.append("<td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(row[1]).append("</td></tr>\n");
        }
        sb.append("</table>\n");
        sb.append("<p>").append(note != null ? note : "").append("</p>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">PMS System - Production Management</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private Session createSession() {
        String host = smtpHost;
        String user = smtpUser;
        String port = smtpPort;

        if (host == null || host.trim().isEmpty()) {
            throw new IllegalStateException("SMTP host chưa được cấu hình.");
        }
        if (user == null || user.trim().isEmpty()) {
            throw new IllegalStateException("SMTP user chưa được cấu hình.");
        }
        if (smtpPassword == null || smtpPassword.trim().isEmpty()) {
            throw new IllegalStateException("SMTP password/App Password không được để trống.");
        }

        String normalizedHost = host.trim();
        String normalizedPort = (port != null && !port.trim().isEmpty()) ? port.trim() : "587";
        boolean useSsl = "465".equals(normalizedPort);

        Properties props = new Properties();
        props.put("mail.smtp.host", normalizedHost);
        props.put("mail.smtp.port", normalizedPort);
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.ssl.trust", normalizedHost);
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "10000");
        props.put("mail.smtp.writetimeout", "10000");

        if (useSsl) {
            props.put("mail.smtp.ssl.enable", "true");
            props.put("mail.smtp.starttls.enable", "false");
            props.put("mail.smtp.socketFactory.port", normalizedPort);
            props.put("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
            props.put("mail.smtp.socketFactory.fallback", "false");
        } else {
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.starttls.required", "true");
            props.put("mail.smtp.ssl.enable", "false");
        }

        final String smtpUserFinal = user.trim();
        final String smtpPassFinal = smtpPassword;

        Authenticator auth = new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(smtpUserFinal, smtpPassFinal);
            }
        };

        return Session.getInstance(props, auth);
    }

    private String buildMessagingError(MessagingException e) {
        String message = e != null ? e.getMessage() : null;
        String lower = message != null ? message.toLowerCase() : "";

        if (lower.contains("authentication") || lower.contains("auth") || lower.contains("535") || lower.contains("username and password not accepted")) {
            return "Xác thực SMTP thất bại. Nếu dùng Gmail, hãy dùng App Password 16 ký tự thay cho mật khẩu đăng nhập thường.";
        }
        if (lower.contains("couldn't connect") || lower.contains("could not connect") || lower.contains("connect timed out") || lower.contains("connection timed out")) {
            return "Không kết nối được tới máy chủ SMTP. Hãy kiểm tra lại SMTP Host và Port.";
        }
        if (lower.contains("ssl") || lower.contains("tls") || lower.contains("handshake")) {
            return "Kết nối bảo mật SMTP thất bại. Port 587 dùng TLS, còn port 465 dùng SSL.";
        }
        if (message == null || message.trim().isEmpty()) {
            return "Gửi email thất bại do lỗi SMTP không xác định.";
        }
        return "Lỗi SMTP: " + message;
    }

    private String buildOrderCompletionEmail(String orderCode, String customerName,
            double amount, String employeeName) {
        String cust = customerName != null ? escapeHtml(customerName) : "-";
        String emp = employeeName != null ? escapeHtml(employeeName) : "-";
        String formattedAmount = String.format("%,.0f VND", amount);

        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:#2563eb;padding:24px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.5rem;\">Don Hang Hoan Thanh</h1>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:24px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>Xin chao Admin,</p>\n");
        sb.append("<p>Mot don hang da duoc hoan thanh va san sang giao hang.</p>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:20px 0;\">\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma don hang</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(orderCode).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Khach hang</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(cust).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Tong gia tri</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;color:#2563eb;font-weight:bold;\">").append(formattedAmount).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Nhan vien thuc hien</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(emp).append("</td></tr>\n");
        sb.append("</table>\n");
        sb.append("<p>Vui long kiem tra va xac nhan don hang som nhat.</p>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">He thong tu dong - Production Management System</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private String buildPaymentSuccessEmail(String billCode, String customerName,
            double amount, String transactionId) {
        String cust = customerName != null ? escapeHtml(customerName) : "-";
        String txn = transactionId != null ? escapeHtml(transactionId) : "Chua co";
        String formattedAmount = String.format("%,.0f VND", amount);
        String now = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());

        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:#059669;padding:24px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.5rem;\">Thanh Toan Thanh Cong</h1>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:24px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>Xin chao Admin,</p>\n");
        sb.append("<p>Mot khoan thanh toan da duoc xac nhan thanh cong trong he thong.</p>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:20px 0;\">\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma hoa don</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(billCode).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Khach hang</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(cust).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>So tien</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;color:#059669;font-weight:bold;\">").append(formattedAmount).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma giao dich</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(txn).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Thoi gian</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(now).append("</td></tr>\n");
        sb.append("</table>\n");
        sb.append("<div style=\"background:#d1fae5;padding:16px;border-radius:8px;text-align:center;margin:16px 0;\">\n");
        sb.append("<strong style=\"color:#059669;\">Thanh toan da duoc xac nhan. Vui long cap nhat trang thai don hang.</strong>\n");
        sb.append("</div>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">He thong tu dong - Production Management System</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private String buildWorkOrderCompletedEmail(int woId, String productName,
            int quantity, String employeeName) {
        String prod = productName != null ? escapeHtml(productName) : "-";
        String emp = employeeName != null ? escapeHtml(employeeName) : "-";
        String now = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date());

        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:#7c3aed;padding:24px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.5rem;\">Lenh San Xuat Hoan Thanh</h1>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:24px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>Xin chao Admin,</p>\n");
        sb.append("<p>Mot lenh san xuat da duoc hoan thanh trong he thong.</p>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:20px 0;\">\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma WO</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">WO#").append(woId).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>San pham</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(prod).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>So luong</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(quantity).append(" san pham</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Nhan vien hoan thanh</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(emp).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Thoi gian</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(now).append("</td></tr>\n");
        sb.append("</table>\n");
        sb.append("<p>Vui long kiem tra va xu ly buoc tiep theo.</p>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">He thong tu dong - Production Management System</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private String buildNewBillEmail(String billCode, String customerName, double amount) {
        String cust = customerName != null ? escapeHtml(customerName) : "-";
        String formattedAmount = String.format("%,.0f VND", amount);

        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n");
        sb.append("<html>\n");
        sb.append("<head><meta charset=\"UTF-8\"></head>\n");
        sb.append("<body style=\"margin:0;padding:0;font-family:Arial,sans-serif;\">\n");
        sb.append("<div style=\"background:#d97706;padding:24px;text-align:center;\">\n");
        sb.append("<h1 style=\"color:white;margin:0;font-size:1.5rem;\">Hoa Don Moi Duoc Tao</h1>\n");
        sb.append("</div>\n");
        sb.append("<div style=\"padding:24px;max-width:600px;margin:0 auto;background:#fff;\">\n");
        sb.append("<p>Xin chao Admin,</p>\n");
        sb.append("<p>Mot hoa don moi da duoc tao trong he thong. Vui long xem xet va tao QR thanh toan.</p>\n");
        sb.append("<table style=\"width:100%;border-collapse:collapse;margin:20px 0;\">\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Ma hoa don</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(billCode).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Khach hang</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\">").append(cust).append("</td></tr>\n");
        sb.append("<tr><td style=\"padding:12px 16px;border:1px solid #e5e7eb;\"><b>Tong gia tri</b></td><td style=\"padding:12px 16px;border:1px solid #e5e7eb;color:#d97706;font-weight:bold;\">").append(formattedAmount).append("</td></tr>\n");
        sb.append("</table>\n");
        sb.append("<hr style=\"border:none;border-top:1px solid #e5e7eb;margin:20px 0;\">\n");
        sb.append("<p style=\"color:#6b7280;font-size:12px;text-align:center;\">He thong tu dong - Production Management System</p>\n");
        sb.append("</div>\n");
        sb.append("</body>\n");
        sb.append("</html>");
        return sb.toString();
    }

    private static String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#x27;");
    }

    public void setSmtpHost(String smtpHost) { this.smtpHost = smtpHost; }
    public void setSmtpPort(String smtpPort) { this.smtpPort = smtpPort; }
    public void setSmtpUser(String smtpUser) { this.smtpUser = smtpUser; }
    public void setSmtpPassword(String smtpPassword) { this.smtpPassword = smtpPassword; }

    public String getSmtpHost() { return smtpHost; }
    public String getSmtpUser() { return smtpUser; }
    public String getLastError() { return lastError; }

    public boolean isConfigured() {
        return smtpHost != null && !smtpHost.trim().isEmpty()
                && smtpUser != null && !smtpUser.trim().isEmpty();
    }
}
