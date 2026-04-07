package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class QcInspectionDAO {

    public boolean insertInspection(QcInspectionDTO qc) {
        String sql = "INSERT INTO QC_Inspection "
                   + "(wo_id, step_id, inspector_user_id, inspection_result, "
                   + "quantity_inspected, quantity_passed, quantity_failed, notes) "
                   + "VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ensureQcInspectionTable(conn);
            ps.setInt(1, qc.getWoId());
            ps.setInt(2, qc.getStepId());
            ps.setInt(3, qc.getInspectorUserId());
            ps.setString(4, qc.getInspectionResult());
            ps.setInt(5, qc.getQuantityInspected());
            ps.setInt(6, qc.getQuantityPassed());
            ps.setInt(7, qc.getQuantityFailed());
            ps.setString(8, qc.getNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<QcInspectionDTO> getAllInspections() {
        List<QcInspectionDTO> list = new ArrayList<>();
        String sql = "SELECT qc.*, i.item_name as wo_name, s.step_name, u.full_name as inspector_name "
                   + "FROM QC_Inspection qc "
                   + "LEFT JOIN Work_Order wo ON qc.wo_id = wo.wo_id "
                   + "LEFT JOIN Item i ON wo.product_item_id = i.item_id "
                   + "LEFT JOIN Routing_Step s ON qc.step_id = s.step_id "
                   + "LEFT JOIN Users u ON qc.inspector_user_id = u.user_id "
                   + "ORDER BY qc.inspection_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ensurePs = conn.prepareStatement(ensureQcInspectionTableSql())) {
            ensurePs.execute();
        } catch (Exception e) {
            e.printStackTrace();
        }
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapInspection(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<QcInspectionDTO> getInspectionsByWo(int woId) {
        List<QcInspectionDTO> list = new ArrayList<>();
        String sql = "SELECT qc.*, i.item_name as wo_name, s.step_name, u.full_name as inspector_name "
                   + "FROM QC_Inspection qc "
                   + "LEFT JOIN Work_Order wo ON qc.wo_id = wo.wo_id "
                   + "LEFT JOIN Item i ON wo.product_item_id = i.item_id "
                   + "LEFT JOIN Routing_Step s ON qc.step_id = s.step_id "
                   + "LEFT JOIN Users u ON qc.inspector_user_id = u.user_id "
                   + "WHERE qc.wo_id = ? "
                   + "ORDER BY qc.inspection_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ensureQcInspectionTable(conn);
            ps.setInt(1, woId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapInspection(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<QcInspectionDTO> getInspectionsByResult(String result) {
        List<QcInspectionDTO> list = new ArrayList<>();
        String sql = "SELECT qc.*, i.item_name as wo_name, s.step_name, u.full_name as inspector_name "
                   + "FROM QC_Inspection qc "
                   + "LEFT JOIN Work_Order wo ON qc.wo_id = wo.wo_id "
                   + "LEFT JOIN Item i ON wo.product_item_id = i.item_id "
                   + "LEFT JOIN Routing_Step s ON qc.step_id = s.step_id "
                   + "LEFT JOIN Users u ON qc.inspector_user_id = u.user_id "
                   + "WHERE qc.inspection_result = ? "
                   + "ORDER BY qc.inspection_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ensureQcInspectionTable(conn);
            ps.setString(1, result);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapInspection(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean deleteInspection(int inspectionId) {
        String sql = "DELETE FROM QC_Inspection WHERE inspection_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ensureQcInspectionTable(conn);
            ps.setInt(1, inspectionId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public int getTotalInspected() {
        String sql = "SELECT ISNULL(SUM(quantity_inspected), 0) FROM QC_Inspection";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ensureQcInspectionTable(conn);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTotalFailed() {
        String sql = "SELECT ISNULL(SUM(quantity_failed), 0) FROM QC_Inspection WHERE inspection_result = 'FAIL'";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ensureQcInspectionTable(conn);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public double getOverallPassRate() {
        int total = getTotalInspected();
        if (total == 0) return 0;
        int passed = getTotalInspected() - getTotalFailed();
        return Math.round((double) passed / total * 100.0);
    }

    private void ensureQcInspectionTable(Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(ensureQcInspectionTableSql())) {
            ps.execute();
        }
    }

    private String ensureQcInspectionTableSql() {
        return "IF OBJECT_ID('QC_Inspection', 'U') IS NULL "
                + "BEGIN "
                + "CREATE TABLE QC_Inspection ("
                + "inspection_id INT PRIMARY KEY IDENTITY(1,1), "
                + "wo_id INT NOT NULL, "
                + "step_id INT NOT NULL, "
                + "inspector_user_id INT NOT NULL, "
                + "inspection_result VARCHAR(20) NOT NULL, "
                + "quantity_inspected INT NOT NULL DEFAULT 0, "
                + "quantity_passed INT NOT NULL DEFAULT 0, "
                + "quantity_failed INT NOT NULL DEFAULT 0, "
                + "notes NVARCHAR(500) NULL, "
                + "inspection_date DATETIME NOT NULL DEFAULT GETDATE(), "
                + "FOREIGN KEY (wo_id) REFERENCES Work_Order(wo_id), "
                + "FOREIGN KEY (step_id) REFERENCES Routing_Step(step_id), "
                + "FOREIGN KEY (inspector_user_id) REFERENCES Users(user_id)"
                + ") END";
    }

    private QcInspectionDTO mapInspection(ResultSet rs) {
        QcInspectionDTO dto = new QcInspectionDTO();
        try {
            dto.setInspectionId(rs.getInt("inspection_id"));
            dto.setWoId(rs.getInt("wo_id"));
            dto.setStepId(rs.getInt("step_id"));
            dto.setInspectorUserId(rs.getInt("inspector_user_id"));
            dto.setInspectionResult(rs.getString("inspection_result"));
            dto.setQuantityInspected(rs.getInt("quantity_inspected"));
            dto.setQuantityPassed(rs.getInt("quantity_passed"));
            dto.setQuantityFailed(rs.getInt("quantity_failed"));
            dto.setNotes(rs.getString("notes"));
            dto.setInspectionDate(rs.getDate("inspection_date"));
            dto.setWoName(rs.getString("wo_name"));
            dto.setStepName(rs.getString("step_name"));
            dto.setInspectorName(rs.getString("inspector_name"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return dto;
    }
}
