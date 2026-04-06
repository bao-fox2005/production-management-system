package pms.model;

import java.sql.Date;
import java.sql.Timestamp;

public class PaymentDTO {

    private int paymentId;
    private int billId;
    private double amount;
    private String paymentMethod; // QR, CASH, BANK_TRANSFER
    private String status; // PENDING, PAID, EXPIRED, CANCELLED
    private String transactionId;
    private String qrCodeData;
    private Timestamp createdAt;
    private Timestamp expiresAt;
    private Timestamp paidAt;
    private String bankBin;
    private String bankAccount;
    private String bankAccountName;
    private String customerName;
    private String customerEmail;

    public PaymentDTO() {
    }

    public PaymentDTO(int paymentId, int billId, double amount, String paymentMethod,
            String status, String transactionId, Timestamp createdAt, Timestamp expiresAt) {
        this.paymentId = paymentId;
        this.billId = billId;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
        this.status = status;
        this.transactionId = transactionId;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
    }

    public int getPaymentId() { return paymentId; }
    public void setPaymentId(int paymentId) { this.paymentId = paymentId; }

    public int getBillId() { return billId; }
    public void setBillId(int billId) { this.billId = billId; }

    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }

    public String getQrCodeData() { return qrCodeData; }
    public void setQrCodeData(String qrCodeData) { this.qrCodeData = qrCodeData; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Timestamp expiresAt) { this.expiresAt = expiresAt; }

    public Timestamp getPaidAt() { return paidAt; }
    public void setPaidAt(Timestamp paidAt) { this.paidAt = paidAt; }

    public String getBankBin() { return bankBin; }
    public void setBankBin(String bankBin) { this.bankBin = bankBin; }

    public String getBankAccount() { return bankAccount; }
    public void setBankAccount(String bankAccount) { this.bankAccount = bankAccount; }

    public String getBankAccountName() { return bankAccountName; }
    public void setBankAccountName(String bankAccountName) { this.bankAccountName = bankAccountName; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String customerEmail) { this.customerEmail = customerEmail; }

    public boolean isExpired() {
        if (expiresAt == null) return false;
        return new java.util.Date().after(expiresAt);
    }

    public boolean isPaid() {
        return "PAID".equals(status);
    }
}
