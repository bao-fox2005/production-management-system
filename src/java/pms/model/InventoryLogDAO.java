package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class InventoryLogDAO {

    public boolean logChange(InventoryLogDTO log) {
        String sql = "INSERT INTO Inventory_Log "
                   + "(item_id, change_type, quantity_before, quantity_change, quantity_after, "
                   + "reference_type, reference_id, reason, performed_by) "
                   + "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, log.getItemId());
            ps.setString(2, log.getChangeType());
            ps.setInt(3, log.getQuantityBefore());
            ps.setInt(4, log.getQuantityChange());
            ps.setInt(5, log.getQuantityAfter());
            ps.setString(6, log.getReferenceType());
            ps.setInt(7, log.getReferenceId());
            ps.setString(8, log.getReason());
            ps.setInt(9, log.getPerformedBy());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<InventoryLogDTO> getAllLogs() {
        List<InventoryLogDTO> list = new ArrayList<>();
        String sql = "SELECT il.*, i.item_name, u.full_name "
                   + "FROM Inventory_Log il "
                   + "LEFT JOIN Item i ON il.item_id = i.item_id "
                   + "LEFT JOIN Users u ON il.performed_by = u.user_id "
                   + "ORDER BY il.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapLog(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<InventoryLogDTO> getLogsByItem(int itemId) {
        List<InventoryLogDTO> list = new ArrayList<>();
        String sql = "SELECT il.*, i.item_name, u.full_name "
                   + "FROM Inventory_Log il "
                   + "LEFT JOIN Item i ON il.item_id = i.item_id "
                   + "LEFT JOIN Users u ON il.performed_by = u.user_id "
                   + "WHERE il.item_id = ? "
                   + "ORDER BY il.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapLog(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<InventoryLogDTO> getLogsByDateRange(String fromDate, String toDate) {
        List<InventoryLogDTO> list = new ArrayList<>();
        String sql = "SELECT il.*, i.item_name, u.full_name "
                   + "FROM Inventory_Log il "
                   + "LEFT JOIN Item i ON il.item_id = i.item_id "
                   + "LEFT JOIN Users u ON il.performed_by = u.user_id "
                   + "WHERE CAST(il.log_date AS DATE) BETWEEN ? AND ? "
                   + "ORDER BY il.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fromDate);
            ps.setString(2, toDate);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapLog(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<InventoryLogDTO> getRecentLogs(int limit) {
        List<InventoryLogDTO> list = new ArrayList<>();
        String sql = "SELECT TOP " + limit + " il.*, i.item_name, u.full_name "
                   + "FROM Inventory_Log il "
                   + "LEFT JOIN Item i ON il.item_id = i.item_id "
                   + "LEFT JOIN Users u ON il.performed_by = u.user_id "
                   + "ORDER BY il.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapLog(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean autoDeductForWorkOrder(int woId, int productItemId, int quantity, int userId, BOMDAO bomDao) {
        try {
            List<BOMDTO> boms = bomDao.getBOMSByProduct(productItemId);
            if (boms == null || boms.isEmpty()) {
                return true;
            }

            BOMDTO activeBom = null;
            for (BOMDTO bom : boms) {
                if ("active".equalsIgnoreCase(bom.getStatus())) {
                    activeBom = bom;
                    break;
                }
            }
            if (activeBom == null && !boms.isEmpty()) {
                activeBom = boms.get(0);
            }
            if (activeBom == null) return true;

            List<BOMDetailDTO> details = activeBom.getDetails();
            if (details == null) return true;

            ItemDAO itemDao = new ItemDAO();

            for (BOMDetailDTO detail : details) {
                double wasteFactor = 1.0 + (detail.getWastePercent() / 100.0);
                int requiredQty = (int) Math.ceil(detail.getQuantityRequired() * quantity * wasteFactor);

                ItemDTO item = itemDao.SearchByID(detail.getMaterialItemId());
                if (item == null) continue;

                int currentStock = item.getStockQuantity();
                int newStock = currentStock - requiredQty;

                InventoryLogDTO log = new InventoryLogDTO();
                log.setItemId(detail.getMaterialItemId());
                log.setChangeType("OUT");
                log.setQuantityBefore(currentStock);
                log.setQuantityChange(-requiredQty);
                log.setQuantityAfter(newStock < 0 ? 0 : newStock);
                log.setReferenceType("WORK_ORDER");
                log.setReferenceId(woId);
                log.setReason("Tu dong tru theo WO#" + woId + " (BOM: " + activeBom.getBomVersion() + ")");
                log.setPerformedBy(userId);

                logChange(log);

                if (newStock >= 0) {
                    itemDao.updateStock(detail.getMaterialItemId(), newStock);

                    if (newStock <= item.getMinStockLevel()) {
                        pms.utils.NotificationService.notifyLowStock(item.getItemName(), newStock);
                    }
                }
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private InventoryLogDTO mapLog(ResultSet rs) {
        InventoryLogDTO dto = new InventoryLogDTO();
        try {
            dto.setLogId(rs.getInt("log_id"));
            dto.setItemId(rs.getInt("item_id"));
            dto.setItemName(rs.getString("item_name"));
            dto.setChangeType(rs.getString("change_type"));
            dto.setQuantityBefore(rs.getInt("quantity_before"));
            dto.setQuantityChange(rs.getInt("quantity_change"));
            dto.setQuantityAfter(rs.getInt("quantity_after"));
            dto.setReferenceType(rs.getString("reference_type"));
            dto.setReferenceId(rs.getInt("reference_id"));
            dto.setReason(rs.getString("reason"));
            dto.setPerformedBy(rs.getInt("performed_by"));
            dto.setPerformerName(rs.getString("full_name"));
            dto.setLogDate(rs.getDate("log_date"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return dto;
    }
}
