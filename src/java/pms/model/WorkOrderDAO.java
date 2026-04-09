package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class WorkOrderDAO {

    public List<WorkOrderDTO> getAllWorkOrders() {
        List<WorkOrderDTO> result = new ArrayList<>();
        String sql = "SELECT wo.*, i.item_name, r.routing_name "
                   + "FROM Work_Order wo "
                   + "LEFT JOIN Item i ON wo.product_item_id = i.item_id "
                   + "LEFT JOIN Routing r ON wo.routing_id = r.routing_id "
                   + "ORDER BY wo.wo_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                WorkOrderDTO wo = new WorkOrderDTO();
                wo.setWo_id(rs.getInt("wo_id"));
                wo.setProduct_item_id(rs.getInt("product_item_id"));
                wo.setRouting_id(rs.getInt("routing_id"));
                wo.setOrder_quantity(rs.getInt("order_quantity"));
                wo.setStatus(rs.getString("status"));
                wo.setProductName(rs.getString("item_name"));
                wo.setRoutingName(rs.getString("routing_name"));
                
                try { wo.setNotes(rs.getString("notes")); } catch (Exception e) {}
                try { wo.setCustomerName(rs.getString("customer_name")); } catch (Exception e) {}
                try { wo.setCustomerId(rs.getInt("customer_id")); } catch (Exception e) {}
                try { wo.setStart_date(rs.getString("start_date")); } catch (Exception e) {}
                try { wo.setDue_date(rs.getString("due_date")); } catch (Exception e) {}
                try { wo.setCompleted_date(rs.getString("completed_date")); } catch (Exception e) {}
                try { wo.setCreated_date(rs.getString("created_date")); } catch (Exception e) {}
                result.add(wo);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return result;
    }

    public boolean updateWorkOrderStatusOnly(int woId, String status) {
        String sql = "UPDATE Work_Order SET status = ?";
        if ("Done".equals(status)) {
            sql += ", completed_date = CAST(GETDATE() AS DATETIME)";
        }
        sql += " WHERE wo_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, woId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateStatusAndNotes(int woId, String status, String notes) {
        String sql = "UPDATE Work_Order SET status = ?, notes = ? WHERE wo_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, notes);
            ps.setInt(3, woId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    // Chỉ cập nhật notes, không đổi status (tránh vi phạm CHECK constraint)
    public boolean updateNotesOnly(int woId, String notes) {
        String sql = "UPDATE Work_Order SET notes = ? WHERE wo_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, notes);
            ps.setInt(2, woId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean insertWorkOrder(WorkOrderDTO wo) {
        String sql = "INSERT INTO Work_Order(product_item_id, routing_id, order_quantity, status, start_date, due_date) VALUES(?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, wo.getProduct_item_id());
            ps.setInt(2, wo.getRouting_id());
            ps.setInt(3, wo.getOrder_quantity());
            ps.setString(4, wo.getStatus());
            ps.setString(5, wo.getStart_date());
            ps.setString(6, wo.getDue_date());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateWorkOrder(WorkOrderDTO wo) {
        String sql = "UPDATE Work_Order SET product_item_id = ?, routing_id = ?, order_quantity = ?, status = ?, start_date = ?, due_date = ? WHERE wo_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, wo.getProduct_item_id());
            ps.setInt(2, wo.getRouting_id());
            ps.setInt(3, wo.getOrder_quantity());
            ps.setString(4, wo.getStatus());
            ps.setString(5, wo.getStart_date());
            ps.setString(6, wo.getDue_date());
            ps.setInt(7, wo.getWo_id());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteWorkOrder(int id) {
        String sql = "DELETE FROM Work_Order WHERE wo_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public WorkOrderDTO searchById(int id) {
        String sql = "SELECT wo.*, i.item_name, r.routing_name "
                   + "FROM Work_Order wo "
                   + "LEFT JOIN Item i ON wo.product_item_id = i.item_id "
                   + "LEFT JOIN Routing r ON wo.routing_id = r.routing_id "
                   + "WHERE wo.wo_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    WorkOrderDTO wo = new WorkOrderDTO();
                    wo.setWo_id(rs.getInt("wo_id"));
                    wo.setProduct_item_id(rs.getInt("product_item_id"));
                    wo.setRouting_id(rs.getInt("routing_id"));
                    wo.setOrder_quantity(rs.getInt("order_quantity"));
                    wo.setStatus(rs.getString("status"));
                    wo.setProductName(rs.getString("item_name"));
                    wo.setRoutingName(rs.getString("routing_name"));
                    
                    try { wo.setNotes(rs.getString("notes")); } catch (Exception e) {}
                    try { wo.setCustomerName(rs.getString("customer_name")); } catch (Exception e) {}
                    try { wo.setCustomerId(rs.getInt("customer_id")); } catch (Exception e) {}
                    try { wo.setStart_date(rs.getString("start_date")); } catch (Exception e) {}
                    try { wo.setDue_date(rs.getString("due_date")); } catch (Exception e) {}
                    try { wo.setCreated_date(rs.getString("created_date")); } catch (Exception e) {}
                    return wo;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}