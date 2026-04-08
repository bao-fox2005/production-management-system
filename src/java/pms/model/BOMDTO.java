package pms.model;

import java.sql.Timestamp;
import java.util.List;

public class BOMDTO {

    private int bomId;
    private int productItemId;
    private String productName;
    private String bomVersion;
    private String status;
    private Timestamp createdDate;
    private String notes;
    private List<BOMDetailDTO> details;

    public BOMDTO() {
    }

    public BOMDTO(int bomId, int productItemId, String productName, String bomVersion, String status, Timestamp createdDate, String notes) {
        this.bomId = bomId;
        this.productItemId = productItemId;
        this.productName = productName;
        this.bomVersion = bomVersion;
        this.status = status;
        this.createdDate = createdDate;
        this.notes = notes;
    }

    public int getBomId() {
        return bomId;
    }

    public void setBomId(int bomId) {
        this.bomId = bomId;
    }

    public int getProductItemId() {
        return productItemId;
    }

    public void setProductItemId(int productItemId) {
        this.productItemId = productItemId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getBomVersion() {
        return bomVersion;
    }

    public void setBomVersion(String bomVersion) {
        this.bomVersion = bomVersion;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public boolean isActive() {
        return "active".equals(status);
    }

    public Timestamp getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(Timestamp createdDate) {
        this.createdDate = createdDate;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public List<BOMDetailDTO> getDetails() {
        return details;
    }

    public void setDetails(List<BOMDetailDTO> details) {
        this.details = details;
    }
}
