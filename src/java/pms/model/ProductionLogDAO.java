package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class ProductionLogDAO {

    public List<ProductionLogDTO> getAllLogs() {
        List<ProductionLogDTO> list = new ArrayList<>();
        // FOX/UI: JOIN lay stepName va defectName
        String sql = "SELECT l.*, s.step_name, d.reason_name FROM Production_Log l "
                   + "LEFT JOIN Routing_Step s ON l.step_id = s.step_id "
                   + "LEFT JOIN Defect_Reason d ON l.defect_id = d.defect_id ORDER BY l.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ProductionLogDTO log = new ProductionLogDTO();
                log.setLogId(rs.getInt("log_id"));
                log.setWoId(rs.getInt("wo_id"));
                log.setStepId(rs.getInt("step_id"));
                // Lay workerUserId (neu co)
                try { log.setWorkerUserId(rs.getInt("worker_user_id")); } catch (Exception e) {}
                // Lay so luong: uu tien cot moi quantity_done, neu khong co thi dung produced_quantity
                try {
                    log.setQuantityDone(rs.getInt("quantity_done"));
                    log.setQuantityDefective(rs.getInt("quantity_defective"));
                } catch (Exception e) {
                    // Ban cu: dung cot produced_quantity
                    log.setProducedQuantity(rs.getInt("produced_quantity"));
                }
                int defect = rs.getInt("defect_id");
                if (rs.wasNull()) {
                    log.setDefectId(null);
                } else {
                    log.setDefectId(defect);
                }
                log.setLogDate(rs.getDate("log_date"));
                // FOX/UI display fields
                log.setStepName(rs.getString("step_name"));
                String defectName = rs.getString("reason_name");
                log.setDefectName(defectName != null ? defectName : "OK");
                list.add(log);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertLog(ProductionLogDTO log) {
        // FOX/UI: dung cot moi quantity_done va quantity_defective
        String sql = "INSERT INTO Production_Log(wo_id, step_id, worker_user_id, quantity_done, quantity_defective, defect_id) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, log.getWoId());
            ps.setInt(2, log.getStepId());
            ps.setInt(3, log.getWorkerUserId());
            ps.setInt(4, log.getQuantityDone());
            ps.setInt(5, log.getQuantityDefective());
            if (log.getDefectId() == null) {
                ps.setNull(6, Types.INTEGER);
            } else {
                ps.setInt(6, log.getDefectId());
            }
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            // Neu cot moi chua co thi dung cau SQL cu
            String sqlFallback = "INSERT INTO Production_Log(wo_id, step_id, worker_user_id, produced_quantity, defect_id) VALUES (?, ?, ?, ?, ?)";
            try (Connection conn = DBUtils.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sqlFallback)) {
                ps.setInt(1, log.getWoId());
                ps.setInt(2, log.getStepId());
                ps.setInt(3, log.getWorkerUserId());
                ps.setInt(4, log.getProducedQuantity());
                if (log.getDefectId() == null) {
                    ps.setNull(5, Types.INTEGER);
                } else {
                    ps.setInt(5, log.getDefectId());
                }
                return ps.executeUpdate() > 0;
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        }
        return false;
    }

    public boolean updateLog(ProductionLogDTO log) {
        String sql = "UPDATE Production_Log SET produced_quantity = ?, defect_id = ? WHERE log_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, log.getProducedQuantity());
            if (log.getDefectId() == null) {
                ps.setNull(2, Types.INTEGER);
            } else {
                ps.setInt(2, log.getDefectId());
            }
            ps.setInt(3, log.getLogId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteLog(int logId) {
        String sql = "DELETE FROM Production_Log WHERE log_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, logId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
