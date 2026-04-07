package pms.model;

public class PurchaseOrderDTO {
    private int poId;
    private int itemId;
    private int quantityRequested;
    private String status;
    private String orderDate;
    private String itemName;

    public PurchaseOrderDTO() {}

    public PurchaseOrderDTO(int poId, int itemId, int quantityRequested, String status, String orderDate) {
        this.poId = poId;
        this.itemId = itemId;
        this.quantityRequested = quantityRequested;
        this.status = status;
        this.orderDate = orderDate;
    }

    public int getPoId() { return poId; }
    public void setPoId(int poId) { this.poId = poId; }
    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }
    public int getQuantityRequested() { return quantityRequested; }
    public void setQuantityRequested(int quantityRequested) { this.quantityRequested = quantityRequested; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getOrderDate() { return orderDate; }
    public void setOrderDate(String orderDate) { this.orderDate = orderDate; }
    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }
}
