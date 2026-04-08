package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import pms.utils.DBUtils;

public class PaymentDAO {

    private boolean isMissingPaymentTable(Exception e) {
        return e != null
                && e.getMessage() != null
                && e.getMessage().toLowerCase().contains("invalid object name 'payment'");
    }

    public boolean insertPayment(PaymentDTO payment) {
        String sql = "INSERT INTO Payment (bill_id, amount, payment_method, status, "
                + "transaction_id, qr_code_data, created_at, expires_at, bank_bin, "
                + "bank_account, bank_account_name, customer_name, customer_email) "
                + "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, payment.getBillId());
            ps.setDouble(2, payment.getAmount());
            ps.setString(3, payment.getPaymentMethod());
            ps.setString(4, payment.getStatus());
            ps.setString(5, payment.getTransactionId());
            ps.setString(6, payment.getQrCodeData());
            ps.setTimestamp(7, payment.getCreatedAt());
            ps.setTimestamp(8, payment.getExpiresAt());
            ps.setString(9, payment.getBankBin());
            ps.setString(10, payment.getBankAccount());
            ps.setString(11, payment.getBankAccountName());
            ps.setString(12, payment.getCustomerName());
            ps.setString(13, payment.getCustomerEmail());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return false;
    }

    public boolean updatePaymentStatus(int paymentId, String status, String transactionId) {
        String sql = "UPDATE Payment SET status = ?, transaction_id = ?, paid_at = GETDATE() WHERE payment_id = ?";
        if (transactionId == null) {
            sql = "UPDATE Payment SET status = ?, paid_at = GETDATE() WHERE payment_id = ?";
        }
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            if (transactionId != null) {
                ps.setString(2, transactionId);
                ps.setInt(3, paymentId);
            } else {
                ps.setInt(2, paymentId);
            }
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return false;
    }

    public boolean updateQrCode(int paymentId, String qrCodeData, Timestamp expiresAt) {
        String sql = "UPDATE Payment SET qr_code_data = ?, expires_at = ?, status = 'PENDING' WHERE payment_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, qrCodeData);
            ps.setTimestamp(2, expiresAt);
            ps.setInt(3, paymentId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return false;
    }

    public boolean expirePayments() {
        String sql = "UPDATE Payment SET status = 'EXPIRED' WHERE status = 'PENDING' AND expires_at < GETDATE()";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            return ps.executeUpdate() >= 0;
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return false;
    }

    public boolean markAsPaid(int paymentId, String transactionId) {
        return updatePaymentStatus(paymentId, "PAID", transactionId);
    }

    public boolean cancelPayment(int paymentId) {
        return updatePaymentStatus(paymentId, "CANCELLED", null);
    }

    public PaymentDTO getPaymentById(int paymentId) {
        String sql = "SELECT * FROM Payment WHERE payment_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, paymentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return null;
    }

    public PaymentDTO getPaymentByBillId(int billId) {
        String sql = "SELECT * FROM Payment WHERE bill_id = ? AND status = 'PENDING' ORDER BY created_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, billId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return null;
    }

    public PaymentDTO getLatestPaymentByBillId(int billId) {
        String sql = "SELECT TOP 1 * FROM Payment WHERE bill_id = ? ORDER BY created_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, billId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return null;
    }

    public ArrayList<PaymentDTO> getPaymentsByStatus(String status) {
        ArrayList<PaymentDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Payment WHERE status = ? ORDER BY created_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSet(rs));
                }
            }
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return list;
    }

    public ArrayList<PaymentDTO> getAllPayments() {
        ArrayList<PaymentDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Payment ORDER BY created_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSet(rs));
            }
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return list;
    }

    public ArrayList<PaymentDTO> searchPayments(String keyword) {
        ArrayList<PaymentDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Payment WHERE "
                + "(CAST(payment_id AS VARCHAR) LIKE ? OR "
                + "CAST(bill_id AS VARCHAR) LIKE ? OR "
                + "transaction_id LIKE ? OR "
                + "customer_name LIKE ?) "
                + "ORDER BY created_at DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            String kw = "%" + keyword + "%";
            ps.setString(1, kw);
            ps.setString(2, kw);
            ps.setString(3, kw);
            ps.setString(4, kw);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSet(rs));
                }
            }
        } catch (Exception e) {
            if (!isMissingPaymentTable(e)) {
                e.printStackTrace();
            }
        }
        return list;
    }

    private PaymentDTO mapResultSet(ResultSet rs) throws Exception {
        PaymentDTO p = new PaymentDTO();
        p.setPaymentId(rs.getInt("payment_id"));
        p.setBillId(rs.getInt("bill_id"));
        p.setAmount(rs.getDouble("amount"));
        p.setPaymentMethod(rs.getString("payment_method"));
        p.setStatus(rs.getString("status"));
        p.setTransactionId(rs.getString("transaction_id"));
        p.setQrCodeData(rs.getString("qr_code_data"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setExpiresAt(rs.getTimestamp("expires_at"));
        p.setPaidAt(rs.getTimestamp("paid_at"));
        p.setBankBin(rs.getString("bank_bin"));
        p.setBankAccount(rs.getString("bank_account"));
        p.setBankAccountName(rs.getString("bank_account_name"));
        p.setCustomerName(rs.getString("customer_name"));
        p.setCustomerEmail(rs.getString("customer_email"));
        return p;
    }
}
