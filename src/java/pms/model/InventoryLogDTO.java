package pms.model;

import java.io.Serializable;
import java.sql.Date;

public class InventoryLogDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private int logId;
    private int itemId;
    private String itemName;
    private String changeType;
    private int quantityBefore;
    private int quantityChange;
    private int quantityAfter;
    private String referenceType;
    private int referenceId;
    private String reason;
    private int performedBy;
    private String performerName;
    private Date logDate;

    public InventoryLogDTO() {}

    public int getLogId() { return logId; }
    public void setLogId(int logId) { this.logId = logId; }

    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public String getChangeType() { return changeType; }
    public void setChangeType(String changeType) { this.changeType = changeType; }

    public int getQuantityBefore() { return quantityBefore; }
    public void setQuantityBefore(int quantityBefore) { this.quantityBefore = quantityBefore; }

    public int getQuantityChange() { return quantityChange; }
    public void setQuantityChange(int quantityChange) { this.quantityChange = quantityChange; }

    public int getQuantityAfter() { return quantityAfter; }
    public void setQuantityAfter(int quantityAfter) { this.quantityAfter = quantityAfter; }

    public String getReferenceType() { return referenceType; }
    public void setReferenceType(String referenceType) { this.referenceType = referenceType; }

    public int getReferenceId() { return referenceId; }
    public void setReferenceId(int referenceId) { this.referenceId = referenceId; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public int getPerformedBy() { return performedBy; }
    public void setPerformedBy(int performedBy) { this.performedBy = performedBy; }

    public String getPerformerName() { return performerName; }
    public void setPerformerName(String performerName) { this.performerName = performerName; }

    public Date getLogDate() { return logDate; }
    public void setLogDate(Date logDate) { this.logDate = logDate; }

    public String getChangeTypeLabel() {
        if (changeType == null) return "-";
        switch (changeType) {
            case "IN": return "Nhap kho";
            case "OUT": return "Xuat kho";
            case "ADJUST": return "Dieu chinh";
            case "RETURN": return "Tra lai";
            case "DAMAGE": return "Hu hong";
            default: return changeType;
        }
    }

    public String getChangeTypeBadgeClass() {
        if (changeType == null) return "bg-gray-100 text-gray-600";
        switch (changeType) {
            case "IN": return "bg-green-100 text-green-700";
            case "OUT": return "bg-red-100 text-red-700";
            case "ADJUST": return "bg-blue-100 text-blue-700";
            case "RETURN": return "bg-yellow-100 text-yellow-700";
            case "DAMAGE": return "bg-orange-100 text-orange-700";
            default: return "bg-gray-100 text-gray-600";
        }
    }
}
