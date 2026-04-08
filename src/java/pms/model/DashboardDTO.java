package pms.model;

import java.io.Serializable;
import java.util.List;

public class DashboardDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private int totalWorkOrders;
    private int workOrdersNew;
    private int workOrdersInProgress;
    private int workOrdersDone;
    private int workOrdersCancelled;

    private int totalProductionLogs;
    private int logsToday;

    private int totalDefects;
    private int defectsToday;

    private int totalItems;
    private int lowStockItems;

    private int totalBills;
    private double totalRevenueThisMonth;

    private int totalUsers;
    private int activeUsers;

    private int totalPurchaseOrders;
    private int purchaseOrdersPending;

    private List<WorkOrderDTO> recentWorkOrders;
    private List<ProductionLogDTO> recentLogs;
    private List<ItemDTO> lowStockList;
    private List<double[]> monthlyRevenue;

    private String generatedAt;

    public DashboardDTO() {
        this.generatedAt = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date());
    }

    public int getTotalWorkOrders() { return totalWorkOrders; }
    public void setTotalWorkOrders(int v) { this.totalWorkOrders = v; }

    public int getWorkOrdersNew() { return workOrdersNew; }
    public void setWorkOrdersNew(int v) { this.workOrdersNew = v; }

    public int getWorkOrdersInProgress() { return workOrdersInProgress; }
    public void setWorkOrdersInProgress(int v) { this.workOrdersInProgress = v; }

    public int getWorkOrdersDone() { return workOrdersDone; }
    public void setWorkOrdersDone(int v) { this.workOrdersDone = v; }

    public int getWorkOrdersCancelled() { return workOrdersCancelled; }
    public void setWorkOrdersCancelled(int v) { this.workOrdersCancelled = v; }

    public int getTotalProductionLogs() { return totalProductionLogs; }
    public void setTotalProductionLogs(int v) { this.totalProductionLogs = v; }

    public int getLogsToday() { return logsToday; }
    public void setLogsToday(int v) { this.logsToday = v; }

    public int getTotalDefects() { return totalDefects; }
    public void setTotalDefects(int v) { this.totalDefects = v; }

    public int getDefectsToday() { return defectsToday; }
    public void setDefectsToday(int v) { this.defectsToday = v; }

    public int getTotalItems() { return totalItems; }
    public void setTotalItems(int v) { this.totalItems = v; }

    public int getLowStockItems() { return lowStockItems; }
    public void setLowStockItems(int v) { this.lowStockItems = v; }

    public int getTotalBills() { return totalBills; }
    public void setTotalBills(int v) { this.totalBills = v; }

    public double getTotalRevenueThisMonth() { return totalRevenueThisMonth; }
    public void setTotalRevenueThisMonth(double v) { this.totalRevenueThisMonth = v; }

    public int getTotalUsers() { return totalUsers; }
    public void setTotalUsers(int v) { this.totalUsers = v; }

    public int getActiveUsers() { return activeUsers; }
    public void setActiveUsers(int v) { this.activeUsers = v; }

    public int getTotalPurchaseOrders() { return totalPurchaseOrders; }
    public void setTotalPurchaseOrders(int v) { this.totalPurchaseOrders = v; }

    public int getPurchaseOrdersPending() { return purchaseOrdersPending; }
    public void setPurchaseOrdersPending(int v) { this.purchaseOrdersPending = v; }

    public List<WorkOrderDTO> getRecentWorkOrders() { return recentWorkOrders; }
    public void setRecentWorkOrders(List<WorkOrderDTO> v) { this.recentWorkOrders = v; }

    public List<ProductionLogDTO> getRecentLogs() { return recentLogs; }
    public void setRecentLogs(List<ProductionLogDTO> v) { this.recentLogs = v; }

    public List<ItemDTO> getLowStockList() { return lowStockList; }
    public void setLowStockList(List<ItemDTO> v) { this.lowStockList = v; }

    public List<double[]> getMonthlyRevenue() { return monthlyRevenue; }
    public void setMonthlyRevenue(List<double[]> v) { this.monthlyRevenue = v; }

    public String getGeneratedAt() { return generatedAt; }
    public void setGeneratedAt(String v) { this.generatedAt = v; }

    public int getCompletionRate() {
        if (totalWorkOrders == 0) return 0;
        return (int) Math.round((double) workOrdersDone / totalWorkOrders * 100);
    }

    public int getInProgressRate() {
        if (totalWorkOrders == 0) return 0;
        return (int) Math.round((double) workOrdersInProgress / totalWorkOrders * 100);
    }

    public String getFormattedRevenue() {
        return String.format("%,.0f", totalRevenueThisMonth);
    }
}
