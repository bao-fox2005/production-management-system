package pms.utils;

import pms.model.PaymentDTO;
import pms.model.UserDAO;
import pms.model.UserDTO;

public class EmailNotificationHelper {

    private final SystemConfigService configService;
    private final EmailService emailService;

    public EmailNotificationHelper() {
        this.configService = new SystemConfigService();
        this.emailService = configService.createEmailService();
    }

    private String getAdminEmail() {
        return configService.getAdminEmail();
    }

    public void notifyWorkOrderCompleted(int woId, String productName, int quantity, int completedByUserId) {
        String adminEmail = getAdminEmail();
        if (!isValidEmail(adminEmail)) {
            return;
        }

        String employeeName = getEmployeeName(completedByUserId);
        String subject = "[PMS] Lenh san xuat hoan thanh - WO#" + woId;
        String body = buildWorkOrderEmail(woId, productName, quantity, employeeName);

        try {
            emailService.sendEmail(adminEmail, subject, body);
        } catch (Exception e) {
            System.err.println("Failed to send work order email: " + e.getMessage());
        }
    }

    public void notifyPaymentReceived(PaymentDTO payment) {
        String adminEmail = getAdminEmail();
        if (!isValidEmail(adminEmail)) {
            return;
        }

        String billCode = "HD" + String.format("%06d", payment.getBillId());
        String subject = "[PMS] Thanh toan thanh cong - Hoa don #" + billCode;
        String body = buildPaymentEmail(payment, billCode);

        try {
            emailService.sendEmail(adminEmail, subject, body);
        } catch (Exception e) {
            System.err.println("Failed to send payment email: " + e.getMessage());
        }
    }

    public void notifyBillCreated(int billId, double amount, int customerId) {
        String adminEmail = getAdminEmail();
        if (!isValidEmail(adminEmail)) {
            return;
        }

        String customerName = getCustomerName(customerId);
        String billCode = "HD" + String.format("%06d", billId);
        String subject = "[PMS] Hoa don moi duoc tao - #" + billCode;
        String body = buildNewBillEmail(billCode, customerName, amount);

        try {
            emailService.sendEmail(adminEmail, subject, body);
        } catch (Exception e) {
            System.err.println("Failed to send new bill email: " + e.getMessage());
        }
    }

    private boolean isValidEmail(String email) {
        return email != null && !email.isEmpty() && !email.contains("your-email");
    }

    private String getEmployeeName(int userId) {
        if (userId <= 0) return "Nhan vien he thong";
        try {
            UserDAO udao = new UserDAO();
            UserDTO user = udao.SearchByID(userId);
            return user != null ? user.getFullName() : "Nhan vien";
        } catch (Exception e) {
            return "Nhan vien";
        }
    }

    private String getCustomerName(int customerId) {
        if (customerId <= 0) return "Khach hang";
        try {
            pms.model.CustomerDAO cdao = new pms.model.CustomerDAO();
            pms.model.CustomerDTO c = cdao.SearchByCustomerID(String.valueOf(customerId));
            return c != null ? c.getCustomer_name() : "Khach hang #" + customerId;
        } catch (Exception e) {
            return "Khach hang #" + customerId;
        }
    }

    private String buildWorkOrderEmail(int woId, String productName, int quantity, String employeeName) {
        return "<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>"
                + "<div style='background:#7c3aed;color:white;padding:20px;text-align:center;'>"
                + "<h1 style='margin:0;font-size:1.3rem;'>Lenh San Xuat Hoan Thanh</h1>"
                + "</div>"
                + "<div style='padding:24px;'>"
                + "<p>Xin chao Admin,</p>"
                + "<p>Mot lenh san xuat da duoc hoan thanh va san pham da san sang giao.</p>"
                + "<table style='width:100%;border-collapse:collapse;margin:20px 0;background:#f9fafb;border-radius:8px;overflow:hidden;'>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>Ma WO:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>WO#" + woId + "</td></tr>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>San pham:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + (productName != null ? productName : "-") + "</td></tr>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>So luong:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + quantity + " san pham</td></tr>"
                + "<tr><td style='padding:12px 16px;'><b>Nhan vien hoan thanh:</b></td><td style='padding:12px 16px;'>" + employeeName + "</td></tr>"
                + "</table>"
                + "<p>Vui long kiem tra va xu ly buoc tiep theo.</p>"
                + "<hr style='border:none;border-top:1px solid #e5e7eb;margin:20px 0;'>"
                + "<p style='color:#6b7280;font-size:12px;text-align:center;'>He thong tu dong - Production Management System</p>"
                + "</div>"
                + "</div>";
    }

    private String buildPaymentEmail(PaymentDTO payment, String billCode) {
        String customerName = payment.getCustomerName() != null ? payment.getCustomerName() : "Khach hang";
        String txnId = payment.getTransactionId() != null ? payment.getTransactionId() : "-";

        return "<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>"
                + "<div style='background:#059669;color:white;padding:20px;text-align:center;'>"
                + "<h1 style='margin:0;font-size:1.3rem;'>Thanh Toan Thanh Cong</h1>"
                + "</div>"
                + "<div style='padding:24px;'>"
                + "<p>Xin chao Admin,</p>"
                + "<p>Mot khoan thanh toan da duoc xac nhan thanh cong. Vui long cap nhat trang thai don hang.</p>"
                + "<table style='width:100%;border-collapse:collapse;margin:20px 0;background:#f9fafb;border-radius:8px;overflow:hidden;'>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>Ma hoa don:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + billCode + "</td></tr>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>Khach hang:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + customerName + "</td></tr>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>So tien:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;color:#059669;font-weight:700;'>" + String.format("%,.0f VND", payment.getAmount()) + "</td></tr>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>Ma giao dich:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + txnId + "</td></tr>"
                + "<tr><td style='padding:12px 16px;'><b>Thoi gian:</b></td><td style='padding:12px 16px;'>" + new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date()) + "</td></tr>"
                + "</table>"
                + "<p style='color:#059669;font-weight:600;padding:12px;background:#d1fae5;border-radius:8px;text-align:center;'>Thanh toan da duoc xac nhan!</p>"
                + "<hr style='border:none;border-top:1px solid #e5e7eb;margin:20px 0;'>"
                + "<p style='color:#6b7280;font-size:12px;text-align:center;'>He thong tu dong - Production Management System</p>"
                + "</div>"
                + "</div>";
    }

    private String buildNewBillEmail(String billCode, String customerName, double amount) {
        return "<div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>"
                + "<div style='background:#d97706;color:white;padding:20px;text-align:center;'>"
                + "<h1 style='margin:0;font-size:1.3rem;'>Hoa Don Moi Duoc Tao</h1>"
                + "</div>"
                + "<div style='padding:24px;'>"
                + "<p>Xin chao Admin,</p>"
                + "<p>Mot hoa don moi da duoc tao trong he thong. Vui long xem xet va tao QR thanh toan.</p>"
                + "<table style='width:100%;border-collapse:collapse;margin:20px 0;background:#f9fafb;border-radius:8px;overflow:hidden;'>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>Ma hoa don:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + billCode + "</td></tr>"
                + "<tr><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'><b>Khach hang:</b></td><td style='padding:12px 16px;border-bottom:1px solid #e5e7eb;'>" + (customerName != null ? customerName : "-") + "</td></tr>"
                + "<tr><td style='padding:12px 16px;'><b>Tong gia tri:</b></td><td style='padding:12px 16px;color:#d97706;font-weight:700;'>" + String.format("%,.0f VND", amount) + "</td></tr>"
                + "</table>"
                + "<hr style='border:none;border-top:1px solid #e5e7eb;margin:20px 0;'>"
                + "<p style='color:#6b7280;font-size:12px;text-align:center;'>He thong tu dong - Production Management System</p>"
                + "</div>"
                + "</div>";
    }
}
