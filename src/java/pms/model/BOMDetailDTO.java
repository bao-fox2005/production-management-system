package pms.model;

public class BOMDetailDTO {

    private int bomDetailId;
    private int bomId;
    private int materialItemId;
    private String materialName;
    private double quantityRequired;
    private String unit;
    private double wastePercent;
    private String notes;

    public BOMDetailDTO() {
    }

    public BOMDetailDTO(int bomDetailId, int bomId, int materialItemId, String materialName, double quantityRequired, String unit, double wastePercent, String notes) {
        this.bomDetailId = bomDetailId;
        this.bomId = bomId;
        this.materialItemId = materialItemId;
        this.materialName = materialName;
        this.quantityRequired = quantityRequired;
        this.unit = unit;
        this.wastePercent = wastePercent;
        this.notes = notes;
    }

    public int getBomDetailId() {
        return bomDetailId;
    }

    public void setBomDetailId(int bomDetailId) {
        this.bomDetailId = bomDetailId;
    }

    public int getBomId() {
        return bomId;
    }

    public void setBomId(int bomId) {
        this.bomId = bomId;
    }

    public int getMaterialItemId() {
        return materialItemId;
    }

    public void setMaterialItemId(int materialItemId) {
        this.materialItemId = materialItemId;
    }

    public String getMaterialName() {
        return materialName;
    }

    public void setMaterialName(String materialName) {
        this.materialName = materialName;
    }

    public double getQuantityRequired() {
        return quantityRequired;
    }

    public void setQuantityRequired(double quantityRequired) {
        this.quantityRequired = quantityRequired;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public double getWastePercent() {
        return wastePercent;
    }

    public void setWastePercent(double wastePercent) {
        this.wastePercent = wastePercent;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }
}
