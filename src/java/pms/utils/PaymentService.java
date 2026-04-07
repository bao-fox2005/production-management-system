package pms.utils;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import pms.model.BillDAO;
import pms.model.BillDTO;
import pms.model.CustomerDAO;
import pms.model.CustomerDTO;
import pms.model.PaymentDAO;
import pms.model.PaymentDTO;

public class PaymentService {

    private static final int DEFAULT_QR_EXPIRE_MINUTES = 1440; // 24h
    private static final int MAX_QR_EXPIRE_MINUTES = 1440;     // hard cap 24h

    private final PaymentDAO paymentDAO;
    private final QrCodeGenerator qrGenerator;
    private final EmailService emailService;
    private final SystemConfigService configService;

    private String defaultBankBin;
    private String defaultBankAccount;
    private String defaultBankAccountName;

    public PaymentService() {
        this.paymentDAO = new PaymentDAO();
        this.qrGenerator = new QrCodeGenerator();
        this.configService = new SystemConfigService();
        this.emailService = configService.createEmailService();
        loadBankConfig();
    }

    public PaymentService(EmailService emailService) {
        this.paymentDAO = new PaymentDAO();
        this.qrGenerator = new QrCodeGenerator();
        this.configService = new SystemConfigService();
        this.emailService = emailService;
        loadBankConfig();
    }

    private void loadBankConfig() {
        this.defaultBankBin = getConfigOrDefault(configService.getBankBin(), "970406");
        this.defaultBankAccount = getConfigOrDefault(configService.getBankAccount(), "1234567890");
        this.defaultBankAccountName = getConfigOrDefault(configService.getBankAccountName(), "CONG TY TNHH PMS");
    }

    private String getConfigOrDefault(String value, String defaultValue) {
        return (value != null && !value.trim().isEmpty()) ? value.trim() : defaultValue;
    }

    public PaymentDTO createQrPayment(int billId, double amount, int expireMinutes,
            String customerName, String customerEmail) {
        return createQrPayment(billId, amount, expireMinutes, customerName, customerEmail,
                null, null, null);
    }

    public PaymentDTO createQrPayment(int billId, double amount, int expireMinutes,
            String customerName, String customerEmail,
            String bankBin, String bankAccount, String bankAccountName) {

        if (amount <= 0) {
            throw new IllegalArgumentException("So tien thanh toan phai lon hon 0.");
        }
        if (billId <= 0) {
            throw new IllegalArgumentException("Bill ID khong hop le.");
        }

        if (expireMinutes <= 0) {
            expireMinutes = configService.getQrExpireMinutes();
        }
        if (expireMinutes <= 0) {
            expireMinutes = DEFAULT_QR_EXPIRE_MINUTES;
        }
        if (expireMinutes > MAX_QR_EXPIRE_MINUTES) {
            expireMinutes = MAX_QR_EXPIRE_MINUTES;
        }
        if (expireMinutes < DEFAULT_QR_EXPIRE_MINUTES) {
            expireMinutes = DEFAULT_QR_EXPIRE_MINUTES;
        }

        String bankBinToUse = getConfigOrDefault(bankBin, defaultBankBin);
        String bankAccountToUse = getConfigOrDefault(bankAccount, defaultBankAccount);
        String bankAccountNameToUse = getConfigOrDefault(bankAccountName, defaultBankAccountName);

        String billCode = "HD" + String.format("%06d", billId);
        String transactionId = generateTransactionId(billId);

        Timestamp now = new Timestamp(System.currentTimeMillis());
        Timestamp expires = new Timestamp(System.currentTimeMillis() + expireMinutes * 60 * 1000L);

        String qrBase64 = null;
        String qrVietQrUrl = null;
        try {
            qrVietQrUrl = qrGenerator.generateVietQrUrl(
                    bankBinToUse,
                    bankAccountToUse,
                    bankAccountNameToUse,
                    amount,
                    billCode
            );
            qrBase64 = qrGenerator.imageUrlToBase64(qrVietQrUrl);
        } catch (Exception e) {
            System.err.println("Loi tao QR: " + e.getMessage());
            throw new RuntimeException("Loi tao ma QR: " + e.getMessage(), e);
        }

        String fullQrData = (qrBase64 != null ? qrBase64 : "") + "|QR_URL|" + (qrVietQrUrl != null ? qrVietQrUrl : "");

        PaymentDTO payment = new PaymentDTO();
        payment.setBillId(billId);
        payment.setAmount(amount);
        payment.setPaymentMethod("QR");
        payment.setStatus("PENDING");
        payment.setTransactionId(transactionId);
        payment.setQrCodeData(fullQrData);
        payment.setCreatedAt(now);
        payment.setExpiresAt(expires);
        payment.setBankBin(bankBinToUse);
        payment.setBankAccount(bankAccountToUse);
        payment.setBankAccountName(bankAccountNameToUse);
        payment.setCustomerName(customerName);
        payment.setCustomerEmail(customerEmail);

        boolean success = paymentDAO.insertPayment(payment);
        if (!success) {
            payment.setPaymentId(0);
            return payment;
        }

        PaymentDTO persistedPayment = paymentDAO.getLatestPaymentByBillId(billId);
        return persistedPayment != null ? persistedPayment : payment;
    }

    public boolean refreshQrCode(int paymentId, int expireMinutes) {
        if (paymentId <= 0) {
            return false;
        }

        if (expireMinutes <= 0) {
            expireMinutes = configService.getQrExpireMinutes();
        }
        if (expireMinutes <= 0) {
            expireMinutes = DEFAULT_QR_EXPIRE_MINUTES;
        }
        if (expireMinutes > MAX_QR_EXPIRE_MINUTES) {
            expireMinutes = MAX_QR_EXPIRE_MINUTES;
        }
        if (expireMinutes < DEFAULT_QR_EXPIRE_MINUTES) {
            expireMinutes = DEFAULT_QR_EXPIRE_MINUTES;
        }

        PaymentDTO payment = paymentDAO.getPaymentById(paymentId);
        if (payment == null || paymentId <= 0) {
            return false;
        }

        if ("PAID".equals(payment.getStatus()) || "CANCELLED".equals(payment.getStatus())) {
            return false;
        }

        String bankBin = getConfigOrDefault(payment.getBankBin(), defaultBankBin);
        String bankAccount = getConfigOrDefault(payment.getBankAccount(), defaultBankAccount);
        String bankAccountName = getConfigOrDefault(payment.getBankAccountName(), defaultBankAccountName);

        Timestamp newExpires = new Timestamp(System.currentTimeMillis() + expireMinutes * 60 * 1000L);
        String newTransactionId = generateTransactionId(payment.getBillId());
        String billCode = "HD" + String.format("%06d", payment.getBillId());

        String qrBase64 = null;
        String qrVietQrUrl = null;
        try {
            qrVietQrUrl = qrGenerator.generateVietQrUrl(
                    bankBin, bankAccount, bankAccountName,
                    payment.getAmount(), billCode
            );
            qrBase64 = qrGenerator.imageUrlToBase64(qrVietQrUrl);
        } catch (Exception e) {
            System.err.println("Loi tao QR khi refresh: " + e.getMessage());
            return false;
        }

        String fullQrData = (qrBase64 != null ? qrBase64 : "") + "|QR_URL|" + (qrVietQrUrl != null ? qrVietQrUrl : "");

        boolean updatedQr = paymentDAO.updateQrCode(paymentId, fullQrData, newExpires);
        boolean updatedStatus = paymentDAO.updatePaymentStatus(paymentId, "PENDING", newTransactionId);

        return updatedQr && updatedStatus;
    }

    public boolean confirmPayment(int paymentId, String transactionId) {
        PaymentDTO payment = paymentDAO.getPaymentById(paymentId);
        if (payment == null) {
            return false;
        }

        if ("PAID".equals(payment.getStatus())) {
            return true;
        }

        if ("CANCELLED".equals(payment.getStatus())) {
            return false;
        }

        if (payment.isExpired()) {
            paymentDAO.updatePaymentStatus(paymentId, "EXPIRED", null);
            return false;
        }

        boolean success = paymentDAO.markAsPaid(paymentId, transactionId);
        if (success) {
            sendPaymentEmail(payment, transactionId);
        }

        return success;
    }

    public boolean autoCheckAndExpire() {
        return paymentDAO.expirePayments();
    }

    public PaymentDTO getPaymentInfo(int paymentId) {
        PaymentDTO payment = paymentDAO.getPaymentById(paymentId);
        if (payment != null && payment.isExpired() && "PENDING".equals(payment.getStatus())) {
            paymentDAO.updatePaymentStatus(paymentId, "EXPIRED", null);
            payment.setStatus("EXPIRED");
        }
        return payment;
    }

    public PaymentDTO getPaymentByBill(int billId) {
        return paymentDAO.getPaymentByBillId(billId);
    }

    public ArrayList<PaymentDTO> getPendingPayments() {
        return paymentDAO.getPaymentsByStatus("PENDING");
    }

    public ArrayList<PaymentDTO> getPaidPayments() {
        return paymentDAO.getPaymentsByStatus("PAID");
    }

    public ArrayList<PaymentDTO> getExpiredPayments() {
        return paymentDAO.getPaymentsByStatus("EXPIRED");
    }

    public ArrayList<PaymentDTO> getAllPayments() {
        return paymentDAO.getAllPayments();
    }

    public ArrayList<PaymentDTO> searchPayments(String keyword) {
        return paymentDAO.searchPayments(keyword);
    }

    public long getRemainingSeconds(int paymentId) {
        PaymentDTO payment = paymentDAO.getPaymentById(paymentId);
        if (payment == null || payment.getExpiresAt() == null) {
            return 0;
        }
        long remaining = payment.getExpiresAt().getTime() - System.currentTimeMillis();
        return remaining > 0 ? remaining / 1000 : 0;
    }

    public Map<String, Object> getPaymentStatus(int paymentId) {
        Map<String, Object> result = new HashMap<>();
        result.put("exists", false);
        result.put("remainingSeconds", 0);

        if (paymentId <= 0) {
            return result;
        }

        PaymentDTO payment = paymentDAO.getPaymentById(paymentId);
        if (payment == null) {
            return result;
        }

        result.put("exists", true);
        result.put("paymentId", payment.getPaymentId());
        result.put("billId", payment.getBillId());
        result.put("amount", payment.getAmount());
        result.put("status", payment.getStatus());
        result.put("paymentMethod", payment.getPaymentMethod());
        result.put("customerName", payment.getCustomerName());

        if ("PENDING".equals(payment.getStatus()) && payment.getExpiresAt() != null) {
            long remainingMs = payment.getExpiresAt().getTime() - System.currentTimeMillis();
            if (remainingMs <= 0) {
                paymentDAO.updatePaymentStatus(paymentId, "EXPIRED", null);
                result.put("status", "EXPIRED");
                result.put("remainingSeconds", 0);
            } else {
                result.put("remainingSeconds", remainingMs / 1000);
            }
        }

        if ("PAID".equals(payment.getStatus())) {
            result.put("paidAt", payment.getPaidAt());
            result.put("transactionId", payment.getTransactionId());
        }

        return result;
    }

    private String generateTransactionId(int billId) {
        String timestamp = String.valueOf(System.currentTimeMillis());
        int len = timestamp.length();
        return "TXN" + billId + timestamp.substring(len - Math.min(len, 6));
    }

    private void sendPaymentEmail(PaymentDTO payment, String transactionId) {
        if (emailService == null || !emailService.isConfigured()) {
            System.out.println("EmailService chua duoc cau hinh, bo qua gui email.");
            return;
        }

        try {
            String adminEmail = configService.getAdminEmail();
            if (adminEmail == null || adminEmail.isEmpty() || adminEmail.contains("your-email")) {
                System.out.println("Email admin chua duoc cau hinh, bo qua gui email.");
                return;
            }

            String billCode = "HD" + String.format("%06d", payment.getBillId());
            String customerName = payment.getCustomerName();
            BillDTO bill = null;

            if (payment.getBillId() > 0) {
                bill = new BillDAO().SearchByBillID(String.valueOf(payment.getBillId()));
                if (bill != null && bill.getCustomer_id() > 0) {
                    CustomerDTO customer = new CustomerDAO().SearchByCustomerID(String.valueOf(bill.getCustomer_id()));
                    if (customer != null && customer.getCustomer_name() != null && !customer.getCustomer_name().trim().isEmpty()) {
                        customerName = customer.getCustomer_name().trim();
                    }
                }
            }

            if (customerName == null || customerName.trim().isEmpty()) {
                customerName = "Quý khách";
            }

            String baseUrl = configService.getConfig("APP_BASE_URL", "http://localhost:8080/production-management-system").trim();
            if (baseUrl.endsWith("/")) {
                baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
            }
            String viewLink = baseUrl + "/BillController?action=viewPublicBill&bill_id=" + payment.getBillId();
            String downloadLink = baseUrl + "/BillController?action=downloadPublicBill&bill_id=" + payment.getBillId();

            emailService.sendBillPaymentSuccess(
                    adminEmail,
                    billCode,
                    customerName,
                    payment.getAmount(),
                    transactionId,
                    viewLink,
                    downloadLink
            );
        } catch (Exception e) {
            System.err.println("Loi gui email thong bao thanh toan: " + e.getMessage());
        }
    }

    public String getDefaultBankBin() { return defaultBankBin; }
    public String getDefaultBankAccount() { return defaultBankAccount; }
    public String getDefaultBankAccountName() { return defaultBankAccountName; }
    public int getDefaultExpireMinutes() {
        return DEFAULT_QR_EXPIRE_MINUTES;
    }
}
