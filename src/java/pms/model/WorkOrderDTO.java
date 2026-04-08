package pms.model;

import java.io.Serializable;

public class WorkOrderDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private int wo_id;
    private int product_item_id;
    private int routing_id;
    private int order_quantity;
    private String status;
    private int customerId;
    private String orderDate;
    private String start_date;
    private String due_date;
    private String completed_date;
    private String created_date;
    private String notes;

    private String productName;
    private String routingName;
    private String customerName;
    private String workerName;

    public WorkOrderDTO() {}

    public int getWo_id() { return wo_id; }
    public void setWo_id(int wo_id) { this.wo_id = wo_id; }

    public int getProduct_item_id() { return product_item_id; }
    public void setProduct_item_id(int product_item_id) { this.product_item_id = product_item_id; }

    public int getRouting_id() { return routing_id; }
    public void setRouting_id(int routing_id) { this.routing_id = routing_id; }

    public int getOrder_quantity() { return order_quantity; }
    public void setOrder_quantity(int order_quantity) { this.order_quantity = order_quantity; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }

    public String getOrderDate() { return orderDate; }
    public void setOrderDate(String orderDate) { this.orderDate = orderDate; }

    public String getStart_date() { return start_date; }
    public void setStart_date(String start_date) { this.start_date = start_date; }

    public String getDue_date() { return due_date; }
    public void setDue_date(String due_date) { this.due_date = due_date; }

    public String getCompleted_date() { return completed_date; }
    public void setCompleted_date(String completed_date) { this.completed_date = completed_date; }
    
    public String getCreated_date() { return created_date; }
    public void setCreated_date(String created_date) { this.created_date = created_date; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getRoutingName() { return routingName; }
    public void setRoutingName(String routingName) { this.routingName = routingName; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getWorkerName() { return workerName; }
    public void setWorkerName(String workerName) { this.workerName = workerName; }

    // ==============================================================
    // HÀM HIỂN THỊ UI CHO DASHBOARD VÀ CÁC TRANG KHÁC
    // ==============================================================
    public String getStatusLabel() {
        if (status == null) return "Unknown";
        if (status.equalsIgnoreCase("New")) return "Mới";
        if (status.equalsIgnoreCase("WaitMaterial")) return "Chờ vật tư";
        if (status.equalsIgnoreCase("Ready")) return "Sẵn sàng";
        if (status.equalsIgnoreCase("InProgress") || status.equalsIgnoreCase("In Progress")) return "Đang Sản Xuất";
        if (status.equalsIgnoreCase("Done") || status.equalsIgnoreCase("Completed")) return "Hoàn Thành";
        if (status.equalsIgnoreCase("Cancelled")) return "Đã Hủy";
        return status;
    }

    public String getStatusBadgeClass() {
        if (status == null) return "bg-gray-100 text-gray-600";
        if (status.equalsIgnoreCase("New")) return "bg-blue-100 text-blue-700";
        if (status.equalsIgnoreCase("WaitMaterial")) return "bg-rose-100 text-rose-700";
        if (status.equalsIgnoreCase("Ready")) return "bg-sky-100 text-sky-700";
        if (status.equalsIgnoreCase("InProgress") || status.equalsIgnoreCase("In Progress")) return "bg-yellow-100 text-yellow-700";
        if (status.equalsIgnoreCase("Done") || status.equalsIgnoreCase("Completed")) return "bg-green-100 text-green-700";
        if (status.equalsIgnoreCase("Cancelled")) return "bg-red-100 text-red-700";
        return "bg-gray-100 text-gray-600";
    }
}