package pms.model;

import java.sql.Timestamp;

public class BillLineDTO {
    private int lineId;
    private int billId;
    private String itemType;
    private int quantity;
    private double unitPrice;
    private double lineTotal;
    private Timestamp createdAt;

    public BillLineDTO() {
    }

    public BillLineDTO(int lineId, int billId, String itemType, int quantity, double unitPrice, double lineTotal, Timestamp createdAt) {
        this.lineId = lineId;
        this.billId = billId;
        this.itemType = itemType;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.lineTotal = lineTotal;
        this.createdAt = createdAt;
    }

    public int getLineId() {
        return lineId;
    }

    public void setLineId(int lineId) {
        this.lineId = lineId;
    }

    public int getBillId() {
        return billId;
    }

    public void setBillId(int billId) {
        this.billId = billId;
    }

    public String getItemType() {
        return itemType;
    }

    public void setItemType(String itemType) {
        this.itemType = itemType;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public double getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(double unitPrice) {
        this.unitPrice = unitPrice;
    }

    public double getLineTotal() {
        return lineTotal;
    }

    public void setLineTotal(double lineTotal) {
        this.lineTotal = lineTotal;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
