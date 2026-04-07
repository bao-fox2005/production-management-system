package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class BillLineDAO {

    public boolean insertLine(Connection conn, BillLineDTO line) throws Exception {
        String sql = "INSERT INTO Bill_Line (bill_id, item_type, quantity, unit_price, line_total) VALUES (?,?,?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, line.getBillId());
            ps.setString(2, line.getItemType());
            ps.setInt(3, line.getQuantity());
            ps.setDouble(4, line.getUnitPrice());
            ps.setDouble(5, line.getLineTotal());
            return ps.executeUpdate() > 0;
        }
    }

    public boolean insertLines(Connection conn, int billId, List<BillLineDTO> lines) throws Exception {
        if (lines == null || lines.isEmpty()) {
            return true;
        }
        for (BillLineDTO line : lines) {
            line.setBillId(billId);
            if (!insertLine(conn, line)) {
                return false;
            }
        }
        return true;
    }

    public List<BillLineDTO> getByBillId(int billId) {
        List<BillLineDTO> list = new ArrayList<>();
        String sql = "SELECT line_id, bill_id, item_type, quantity, unit_price, line_total, created_at FROM Bill_Line WHERE bill_id = ? ORDER BY line_id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, billId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BillLineDTO line = new BillLineDTO();
                    line.setLineId(rs.getInt("line_id"));
                    line.setBillId(rs.getInt("bill_id"));
                    line.setItemType(rs.getString("item_type"));
                    line.setQuantity(rs.getInt("quantity"));
                    line.setUnitPrice(rs.getDouble("unit_price"));
                    line.setLineTotal(rs.getDouble("line_total"));
                    line.setCreatedAt(rs.getTimestamp("created_at"));
                    list.add(line);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean deleteByBillId(Connection conn, int billId) throws Exception {
        String sql = "DELETE FROM Bill_Line WHERE bill_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, billId);
            ps.executeUpdate();
            return true;
        }
    }
}
