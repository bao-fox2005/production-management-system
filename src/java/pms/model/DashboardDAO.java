package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class DashboardDAO {

    public DashboardDTO loadDashboardStats() {
        DashboardDTO dto = new DashboardDTO(); 
        
        dto.setTotalWorkOrders(countRows("Work_Order"));
        dto.setWorkOrdersNew(countByStatus("Work_Order", "status", "New"));
        dto.setWorkOrdersInProgress(countByStatus("Work_Order", "status", "InProgress"));
        dto.setWorkOrdersDone(countByStatus("Work_Order", "status", "Done"));
        dto.setWorkOrdersCancelled(countByStatus("Work_Order", "status", "Cancelled"));
        
        dto.setTotalProductionLogs(countRows("Production_Log"));
        dto.setLogsToday(countToday("Production_Log", "log_date"));
        
        dto.setTotalItems(countRows("Item"));
        dto.setLowStockItems(countLowStock());
        
        dto.setTotalBills(countRows("Bill"));
        dto.setTotalRevenueThisMonth(getRevenueThisMonth());
        
        dto.setTotalUsers(countRows("Users"));
        dto.setActiveUsers(countByStatus("Users", "status", "active"));
        
        dto.setTotalPurchaseOrders(countRows("Purchase_Order"));
        dto.setPurchaseOrdersPending(countByStatus("Purchase_Order", "status", "Pending"));
        
        dto.setRecentWorkOrders(getRecentWorkOrders());
        dto.setRecentLogs(getRecentLogs());
        dto.setLowStockList(getLowStockItems());
        dto.setMonthlyRevenue(getMonthlyRevenueData());
        
        return dto;
    }
    
    public DashboardDTO loadWorkerDashboardStats(int workerUserId) {
        DashboardDTO dto = new DashboardDTO();
        
        // Worker chỉ thấy lệnh sản xuất đang chạy
        dto.setTotalWorkOrders(countWorkerWorkOrders(workerUserId));
        dto.setWorkOrdersInProgress(countWorkerWorkOrdersByStatus(workerUserId, "InProgress"));
        dto.setWorkOrdersDone(countWorkerWorkOrdersByStatus(workerUserId, "Done"));
        
        // Worker chỉ thấy nhật ký của mình
        dto.setTotalProductionLogs(countWorkerLogs(workerUserId));
        dto.setLogsToday(countWorkerLogsToday(workerUserId));
        
        // Worker không thấy thông tin tài chính
        dto.setTotalBills(0);
        dto.setTotalRevenueThisMonth(0);
        dto.setMonthlyRevenue(new ArrayList<>());
        
        // Worker không thấy thông tin quản lý
        dto.setTotalItems(0);
        dto.setLowStockItems(0);
        dto.setLowStockList(new ArrayList<>());
        dto.setTotalUsers(0);
        dto.setActiveUsers(0);
        dto.setTotalPurchaseOrders(0);
        dto.setPurchaseOrdersPending(0);
        
        // Worker thấy lệnh sản xuất liên quan
        dto.setRecentWorkOrders(getWorkerWorkOrders(workerUserId));
        dto.setRecentLogs(getWorkerLogs(workerUserId));
        
        return dto;
    }

    private int countRows(String table) {
        String sql = "SELECT COUNT(*) FROM " + table;
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private int countByStatus(String table, String column, String status) {
        String sql = "SELECT COUNT(*) FROM " + table + " WHERE " + column + " = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private int countToday(String table, String dateColumn) {
        String sql = "SELECT COUNT(*) FROM " + table + " WHERE CAST(" + dateColumn + " AS DATE) = CAST(GETDATE() AS DATE)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private int countLowStock() {
        String sql = "SELECT COUNT(*) FROM Item WHERE stock_quantity <= min_stock_level";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private double getRevenueThisMonth() {
        String sql = "SELECT ISNULL(SUM(total_amount), 0) FROM Bill "
                   + "WHERE MONTH(bill_date) = MONTH(GETDATE()) AND YEAR(bill_date) = YEAR(GETDATE())";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getDouble(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private List<WorkOrderDTO> getRecentWorkOrders() {
        List<WorkOrderDTO> list = new ArrayList<>();
        String sql = "SELECT TOP 5 wo.*, i.item_name, r.routing_name "
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
                try {
                    wo.setStart_date(rs.getString("start_date"));
                    wo.setDue_date(rs.getString("due_date"));
                } catch (Exception e) {}
                list.add(wo);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private List<ProductionLogDTO> getRecentLogs() {
        List<ProductionLogDTO> list = new ArrayList<>();
        String sql = "SELECT TOP 5 l.*, s.step_name, u.full_name, wo.order_quantity "
                   + "FROM Production_Log l "
                   + "LEFT JOIN Routing_Step s ON l.step_id = s.step_id "
                   + "LEFT JOIN Users u ON l.worker_user_id = u.user_id "
                   + "LEFT JOIN Work_Order wo ON l.wo_id = wo.wo_id "
                   + "ORDER BY l.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ProductionLogDTO log = new ProductionLogDTO();
                log.setLogId(rs.getInt("log_id"));
                log.setWoId(rs.getInt("wo_id"));
                log.setStepId(rs.getInt("step_id"));
                log.setStepName(rs.getString("step_name"));
                log.setWorkerName(rs.getString("full_name"));
                log.setProducedQuantity(rs.getInt("order_quantity"));
                log.setLogDate(rs.getDate("log_date"));
                list.add(log);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private List<ItemDTO> getLowStockItems() {
        List<ItemDTO> list = new ArrayList<>();
        String sql = "SELECT TOP 5 * FROM Item WHERE stock_quantity <= min_stock_level ORDER BY stock_quantity ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ItemDTO item = new ItemDTO(
                    rs.getInt("item_id"),
                    rs.getString("item_name"),
                    rs.getString("item_type"),
                    rs.getInt("stock_quantity"),
                    rs.getString("unit"),
                    rs.getString("description"),
                    rs.getInt("min_stock_level"),
                    rs.getString("image_base64")
                );
                list.add(item);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private List<double[]> getMonthlyRevenueData() {
        List<double[]> data = new ArrayList<>();
        String sql = "SELECT MONTH(bill_date) as m, SUM(total_amount) as t "
                   + "FROM Bill WHERE YEAR(bill_date) = YEAR(GETDATE()) "
                   + "GROUP BY MONTH(bill_date) ORDER BY MONTH(bill_date)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                data.add(new double[]{rs.getInt("m"), rs.getDouble("t")});
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return data;
    }

    public int countTodayDefects() {
        String sql = "SELECT COUNT(*) FROM Defect_Reason";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    // Worker-specific methods
    private int countWorkerWorkOrders(int workerUserId) {
        String sql = "SELECT COUNT(DISTINCT wo.wo_id) FROM Work_Order wo "
                   + "INNER JOIN Production_Log pl ON wo.wo_id = pl.wo_id "
                   + "WHERE pl.worker_user_id = ? AND wo.status IN ('New', 'InProgress', 'Done')";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, workerUserId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    private int countWorkerWorkOrdersByStatus(int workerUserId, String status) {
        String sql = "SELECT COUNT(DISTINCT wo.wo_id) FROM Work_Order wo "
                   + "INNER JOIN Production_Log pl ON wo.wo_id = pl.wo_id "
                   + "WHERE pl.worker_user_id = ? AND wo.status = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, workerUserId);
            ps.setString(2, status);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    private int countWorkerLogs(int workerUserId) {
        String sql = "SELECT COUNT(*) FROM Production_Log WHERE worker_user_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, workerUserId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    private int countWorkerLogsToday(int workerUserId) {
        String sql = "SELECT COUNT(*) FROM Production_Log "
                   + "WHERE worker_user_id = ? AND CAST(log_date AS DATE) = CAST(GETDATE() AS DATE)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, workerUserId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    private List<WorkOrderDTO> getWorkerWorkOrders(int workerUserId) {
        List<WorkOrderDTO> list = new ArrayList<>();
        String sql = "SELECT TOP 5 wo.*, i.item_name, r.routing_name "
                   + "FROM Work_Order wo "
                   + "INNER JOIN Production_Log pl ON wo.wo_id = pl.wo_id "
                   + "LEFT JOIN Item i ON wo.product_item_id = i.item_id "
                   + "LEFT JOIN Routing r ON wo.routing_id = r.routing_id "
                   + "WHERE pl.worker_user_id = ? "
                   + "GROUP BY wo.wo_id, wo.product_item_id, wo.routing_id, wo.order_quantity, wo.status, wo.start_date, wo.due_date, wo.completed_date, wo.notes, i.item_name, r.routing_name "
                   + "ORDER BY wo.wo_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, workerUserId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    WorkOrderDTO wo = new WorkOrderDTO();
                    wo.setWo_id(rs.getInt("wo_id"));
                    wo.setProduct_item_id(rs.getInt("product_item_id"));
                    wo.setRouting_id(rs.getInt("routing_id"));
                    wo.setOrder_quantity(rs.getInt("order_quantity"));
                    wo.setStatus(rs.getString("status"));
                    wo.setProductName(rs.getString("item_name"));
                    wo.setRoutingName(rs.getString("routing_name"));
                    try {
                        wo.setStart_date(rs.getString("start_date"));
                        wo.setDue_date(rs.getString("due_date"));
                    } catch (Exception e) {}
                    list.add(wo);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    
    private List<ProductionLogDTO> getWorkerLogs(int workerUserId) {
        List<ProductionLogDTO> list = new ArrayList<>();
        String sql = "SELECT TOP 5 l.*, s.step_name, u.full_name, wo.order_quantity "
                   + "FROM Production_Log l "
                   + "LEFT JOIN Routing_Step s ON l.step_id = s.step_id "
                   + "LEFT JOIN Users u ON l.worker_user_id = u.user_id "
                   + "LEFT JOIN Work_Order wo ON l.wo_id = wo.wo_id "
                   + "WHERE l.worker_user_id = ? "
                   + "ORDER BY l.log_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, workerUserId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                ProductionLogDTO log = new ProductionLogDTO();
                log.setLogId(rs.getInt("log_id"));
                log.setWoId(rs.getInt("wo_id"));
                log.setStepId(rs.getInt("step_id"));
                log.setStepName(rs.getString("step_name"));
                log.setWorkerName(rs.getString("full_name"));
                log.setProducedQuantity(rs.getInt("order_quantity"));
                log.setLogDate(rs.getDate("log_date"));
                list.add(log);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}
