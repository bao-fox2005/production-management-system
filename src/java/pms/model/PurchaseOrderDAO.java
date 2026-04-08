package pms.model;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class PurchaseOrderDAO {

    public List<PurchaseOrderDTO> getAllPurchaseOrders() {
        List<PurchaseOrderDTO> list = new ArrayList<>();
        String sql = "SELECT po.*, i.item_name FROM Purchase_Order po "
                   + "JOIN Item i ON po.item_id = i.item_id "
                   + "ORDER BY po.po_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                PurchaseOrderDTO po = new PurchaseOrderDTO(
                    rs.getInt("po_id"),
                    rs.getInt("item_id"),
                    rs.getInt("required_quantity"),
                    rs.getString("status"),
                    rs.getString("alert_date")
                );
                po.setItemName(rs.getString("item_name"));
                list.add(po);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertPurchaseOrder(PurchaseOrderDTO po) {
        String sql = "INSERT INTO Purchase_Order (item_id, supplier_id, required_quantity, status, alert_date) VALUES(?, 1, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, po.getItemId());
            ps.setInt(2, po.getQuantityRequested());
            ps.setString(3, normalizeStatus(po.getStatus()));
            ps.setString(4, po.getOrderDate());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public PurchaseOrderDTO getPurchaseOrderById(int poId) {
        String sql = "SELECT po.*, i.item_name FROM Purchase_Order po "
                   + "JOIN Item i ON po.item_id = i.item_id "
                   + "WHERE po.po_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    PurchaseOrderDTO po = new PurchaseOrderDTO(
                        rs.getInt("po_id"),
                        rs.getInt("item_id"),
                        rs.getInt("required_quantity"),
                        rs.getString("status"),
                        rs.getString("alert_date")
                    );
                    po.setItemName(rs.getString("item_name"));
                    return po;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateStatus(int poId, String newStatus) {
        String normalizedStatus = normalizeStatus(newStatus);
        PurchaseOrderDTO current = getPurchaseOrderById(poId);
        if (current == null) {
            return false;
        }

        Connection conn = null;
        PreparedStatement psUpdate = null;
        PreparedStatement psStock = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            psUpdate = conn.prepareStatement("UPDATE Purchase_Order SET status = ? WHERE po_id = ?");
            psUpdate.setString(1, normalizedStatus);
            psUpdate.setInt(2, poId);
            boolean updated = psUpdate.executeUpdate() > 0;

            if (!updated) {
                conn.rollback();
                return false;
            }

            if ("Received".equalsIgnoreCase(normalizedStatus)
                    && !"Received".equalsIgnoreCase(current.getStatus())) {
                psStock = conn.prepareStatement(
                        "UPDATE Item SET stock_quantity = ISNULL(stock_quantity, 0) + ? WHERE item_id = ?");
                psStock.setInt(1, current.getQuantityRequested());
                psStock.setInt(2, current.getItemId());
                psStock.executeUpdate();
            }

            conn.commit();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (Exception rollbackEx) {
                rollbackEx.printStackTrace();
            }
        } finally {
            try {
                if (psStock != null) psStock.close();
            } catch (Exception e) {}
            try {
                if (psUpdate != null) psUpdate.close();
            } catch (Exception e) {}
            try {
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                }
            } catch (Exception e) {}
        }
        return false;
    }

    private String normalizeStatus(String status) {
        if (status == null) {
            return "Pending";
        }
        if ("Ordered".equalsIgnoreCase(status) || "Đang nhập".equalsIgnoreCase(status)) {
            return "Ordered";
        }
        if ("Received".equalsIgnoreCase(status) || "Đã nhập".equalsIgnoreCase(status)) {
            return "Received";
        }
        return "Pending";
    }

    public boolean deletePurchaseOrder(int poId) {
        String sql = "DELETE FROM Purchase_Order WHERE po_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}