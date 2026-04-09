package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class BillDAO {

    private BillDTO mapBill(ResultSet rs) throws Exception {
        BillDTO dto = new BillDTO();
        dto.setBill_id(rs.getInt("bill_id"));
        dto.setWo_id(rs.getInt("wo_id"));
        dto.setCustomer_id(rs.getInt("customer_id"));
        dto.setTotal_amount(rs.getDouble("total_amount"));
        dto.setBill_date(rs.getDate("bill_date"));

        try { dto.setStatus(rs.getString("status")); } catch (Exception ignored) { dto.setStatus("pending"); }
        try { dto.setBill_created_at(rs.getTimestamp("bill_created_at")); } catch (Exception ignored) {}
        try { dto.setConfirmed_paid_at(rs.getTimestamp("confirmed_paid_at")); } catch (Exception ignored) {}
        try { dto.setCancelled_at(rs.getTimestamp("cancelled_at")); } catch (Exception ignored) {}
        return dto;
    }

    private BillDTO searchByColumn(String column, String value) {
        String sql = "SELECT * FROM Bill WHERE " + column + " = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, value);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapBill(rs);
                }
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return null;
    }

    public ArrayList<BillDTO> getAllBill() {
        ArrayList<BillDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Bill ORDER BY bill_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapBill(rs));
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return list;
    }

    public boolean InsertBill(BillDTO bill) {
        String sql = "INSERT INTO Bill (wo_id, customer_id, total_amount, bill_date, status, bill_created_at) VALUES (?,?,?,?,?,?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (bill.getWo_id() > 0) {
                ps.setInt(1, bill.getWo_id());
            } else {
                ps.setNull(1, java.sql.Types.INTEGER);
            }
            ps.setInt(2, bill.getCustomer_id());
            ps.setDouble(3, bill.getTotal_amount());
            ps.setDate(4, bill.getBill_date() != null ? bill.getBill_date() : new java.sql.Date(System.currentTimeMillis()));
            ps.setString(5, bill.getStatus() != null ? bill.getStatus() : "pending");
            ps.setTimestamp(6, bill.getBill_created_at() != null ? bill.getBill_created_at() : new Timestamp(System.currentTimeMillis()));
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return false;
    }

    public int insertBillWithLines(BillDTO bill, List<BillLineDTO> lines) {
        String sql = "INSERT INTO Bill (wo_id, customer_id, total_amount, bill_date, status, bill_created_at) VALUES (?,?,?,?,?,?)";
        String legacySql = "INSERT INTO Bill (wo_id, customer_id, total_amount, bill_date) VALUES (?,?,?,?)";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet generatedKeys = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            boolean inserted = false;
            try {
                ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
                bindBillInsert(ps, bill, false);
                inserted = ps.executeUpdate() > 0;
            } catch (Exception insertEx) {
                if (!isLegacyBillSchema(insertEx)) {
                    throw insertEx;
                }
                try { if (ps != null) ps.close(); } catch (Exception ignored) {}
                ps = conn.prepareStatement(legacySql, PreparedStatement.RETURN_GENERATED_KEYS);
                bindBillInsert(ps, bill, true);
                inserted = ps.executeUpdate() > 0;
            }

            if (!inserted) {
                conn.rollback();
                return 0;
            }

            generatedKeys = ps.getGeneratedKeys();
            int newBillId = 0;
            if (generatedKeys.next()) {
                newBillId = generatedKeys.getInt(1);
            }

            if (newBillId <= 0) {
                conn.rollback();
                return 0;
            }

            BillLineDAO lineDAO = new BillLineDAO();
            try {
                if (!lineDAO.insertLines(conn, newBillId, lines)) {
                    conn.rollback();
                    return 0;
                }
            } catch (Exception lineEx) {
                if (!isMissingBillLineTable(lineEx)) {
                    conn.rollback();
                    throw lineEx;
                }
                // Nếu tenant chưa chạy migration Bill_Line, vẫn cho phép tạo Bill
                // để không chặn nghiệp vụ chính.
            }

            conn.commit();
            return newBillId;
        } catch (Exception e) {
            try {
                if (conn != null) conn.rollback();
            } catch (Exception ignored) {}
            System.out.println(e.getMessage());
        } finally {
            try { if (generatedKeys != null) generatedKeys.close(); } catch (Exception ignored) {}
            try { if (ps != null) ps.close(); } catch (Exception ignored) {}
            try {
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                }
            } catch (Exception ignored) {}
        }
        return 0;
    }

    private void bindBillInsert(PreparedStatement ps, BillDTO bill, boolean legacySchema) throws Exception {
        if (bill.getWo_id() > 0) {
            ps.setInt(1, bill.getWo_id());
        } else {
            ps.setNull(1, java.sql.Types.INTEGER);
        }
        ps.setInt(2, bill.getCustomer_id());
        ps.setDouble(3, bill.getTotal_amount());
        ps.setDate(4, bill.getBill_date() != null ? bill.getBill_date() : new java.sql.Date(System.currentTimeMillis()));

        if (!legacySchema) {
            ps.setString(5, bill.getStatus() != null ? bill.getStatus() : "pending");
            ps.setTimestamp(6, bill.getBill_created_at() != null ? bill.getBill_created_at() : new Timestamp(System.currentTimeMillis()));
        }
    }

    private boolean isLegacyBillSchema(Exception e) {
        if (e == null || e.getMessage() == null) {
            return false;
        }
        String msg = e.getMessage().toLowerCase();
        return msg.contains("invalid column name 'status'")
                || msg.contains("invalid column name 'bill_created_at'");
    }

    private boolean isMissingBillLineTable(Exception e) {
        return e != null
                && e.getMessage() != null
                && e.getMessage().toLowerCase().contains("invalid object name 'bill_line'");
    }

    public boolean UpdateBill(BillDTO bill) {
        String sql = "UPDATE Bill SET wo_id = ?, customer_id = ?, total_amount = ?, bill_date = ?, status = ? WHERE bill_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (bill.getWo_id() > 0) {
                ps.setInt(1, bill.getWo_id());
            } else {
                ps.setNull(1, java.sql.Types.INTEGER);
            }
            ps.setInt(2, bill.getCustomer_id());
            ps.setDouble(3, bill.getTotal_amount());
            ps.setDate(4, bill.getBill_date());
            ps.setString(5, bill.getStatus() != null ? bill.getStatus() : "pending");
            ps.setInt(6, bill.getBill_id());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return false;
    }

    public boolean updateBillStatus(int billId, String status) {
        String normalized = normalizeStatus(status);
        String sql = "UPDATE Bill SET status = ?, confirmed_paid_at = CASE WHEN ? = 'paid' THEN GETDATE() ELSE confirmed_paid_at END, "
                + "cancelled_at = CASE WHEN ? = 'cancelled' THEN GETDATE() ELSE cancelled_at END WHERE bill_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, normalized);
            ps.setString(2, normalized);
            ps.setString(3, normalized);
            ps.setInt(4, billId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return false;
    }

    public boolean updateBillStatusPaid(int billId, Timestamp paidAt) {
        String sql = "UPDATE Bill SET status = 'paid', confirmed_paid_at = ?, cancelled_at = NULL WHERE bill_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, paidAt != null ? paidAt : new Timestamp(System.currentTimeMillis()));
            ps.setInt(2, billId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return false;
    }

    public boolean updateBillStatusCancelled(int billId, Timestamp cancelledAt) {
        String sql = "UPDATE Bill SET status = 'cancelled', cancelled_at = ?, confirmed_paid_at = NULL WHERE bill_id = ? AND status = 'pending'";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, cancelledAt != null ? cancelledAt : new Timestamp(System.currentTimeMillis()));
            ps.setInt(2, billId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return false;
    }

    public int cancelPendingBillsOlderThan24h() {
        String sql = "UPDATE Bill SET status = 'cancelled', cancelled_at = GETDATE() "
                + "WHERE status = 'pending' AND bill_created_at < DATEADD(HOUR, -24, GETDATE())";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            return ps.executeUpdate();
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return 0;
    }

    public boolean deleteBill(int id) {
        Connection conn = null;
        PreparedStatement deletePaymentPs = null;
        PreparedStatement deleteLinePs = null;
        PreparedStatement deleteBillPs = null;

        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            // Xóa payment con trước để tránh lỗi FK Payment.bill_id -> Bill.bill_id
            deletePaymentPs = conn.prepareStatement("DELETE FROM Payment WHERE bill_id = ?");
            deletePaymentPs.setInt(1, id);
            deletePaymentPs.executeUpdate();

            // Xóa bill line (nếu tenant đã có bảng Bill_Line)
            try {
                deleteLinePs = conn.prepareStatement("DELETE FROM Bill_Line WHERE bill_id = ?");
                deleteLinePs.setInt(1, id);
                deleteLinePs.executeUpdate();
            } catch (Exception lineEx) {
                if (!isMissingBillLineTable(lineEx)) {
                    throw lineEx;
                }
            }

            // Cuối cùng mới xóa bill cha
            deleteBillPs = conn.prepareStatement("DELETE FROM Bill WHERE bill_id = ?");
            deleteBillPs.setInt(1, id);
            boolean deleted = deleteBillPs.executeUpdate() > 0;

            conn.commit();
            return deleted;
        } catch (Exception e) {
            try {
                if (conn != null) conn.rollback();
            } catch (Exception ignored) {}
            System.out.println(e.getMessage());
        } finally {
            try { if (deletePaymentPs != null) deletePaymentPs.close(); } catch (Exception ignored) {}
            try { if (deleteLinePs != null) deleteLinePs.close(); } catch (Exception ignored) {}
            try { if (deleteBillPs != null) deleteBillPs.close(); } catch (Exception ignored) {}
            try {
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                }
            } catch (Exception ignored) {}
        }
        return false;
    }

    public ArrayList<BillDTO> searchBill(String keyword) {
        ArrayList<BillDTO> list = new ArrayList<>();
        String sql = "SELECT b.* FROM Bill b "
                + "LEFT JOIN Customer c ON b.customer_id = c.customer_id "
                + "WHERE CAST(b.bill_id AS VARCHAR(20)) LIKE ? "
                + "OR CAST(b.wo_id AS VARCHAR(20)) LIKE ? "
                + "OR ISNULL(c.customer_name, '') LIKE ? "
                + "ORDER BY b.bill_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            String kw = "%" + (keyword != null ? keyword.trim() : "") + "%";
            ps.setString(1, kw);
            ps.setString(2, kw);
            ps.setString(3, kw);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapBill(rs));
                }
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return list;
    }

    public BillDTO SearchByBillID(String id) {
        return searchByColumn("bill_id", id);
    }

    public BillDTO SearchByCustomerID(String id) {
        return searchByColumn("customer_id", id);
    }

    public ArrayList<Double> getMonthlyRevenue() {
        ArrayList<Double> revenueList = new ArrayList<>();
        for (int i = 0; i < 12; i++) {
            revenueList.add(0.0);
        }

        String sql = "SELECT MONTH(bill_date) as Month, SUM(total_amount) as Total "
                + "FROM Bill "
                + "WHERE YEAR(bill_date) = YEAR(GETDATE()) AND status = 'paid' "
                + "GROUP BY MONTH(bill_date)";

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                int month = rs.getInt("Month");
                double total = rs.getDouble("Total");
                revenueList.set(month - 1, total);
            }
        } catch (Exception e) {
            System.out.println("Loi load bieu do: " + e.getMessage());
        }
        return revenueList;
    }

    private String normalizeStatus(String status) {
        if (status == null) return "pending";
        String s = status.trim().toLowerCase();
        if ("paid".equals(s)) return "paid";
        if ("cancelled".equals(s) || "canceled".equals(s) || "expired".equals(s)) return "cancelled";
        return "pending";
    }
}
