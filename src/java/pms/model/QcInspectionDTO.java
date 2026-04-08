package pms.model;

import java.io.Serializable;
import java.sql.Date;

public class QcInspectionDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private int inspectionId;
    private int woId;
    private int stepId;
    private int inspectorUserId;
    private String inspectionResult;
    private int quantityInspected;
    private int quantityPassed;
    private int quantityFailed;
    private String notes;
    private Date inspectionDate;
    private String woName;
    private String stepName;
    private String inspectorName;

    public QcInspectionDTO() {}

    public int getInspectionId() { return inspectionId; }
    public void setInspectionId(int inspectionId) { this.inspectionId = inspectionId; }

    public int getWoId() { return woId; }
    public void setWoId(int woId) { this.woId = woId; }

    public int getStepId() { return stepId; }
    public void setStepId(int stepId) { this.stepId = stepId; }

    public int getInspectorUserId() { return inspectorUserId; }
    public void setInspectorUserId(int inspectorUserId) { this.inspectorUserId = inspectorUserId; }

    public String getInspectionResult() { return inspectionResult; }
    public void setInspectionResult(String inspectionResult) { this.inspectionResult = inspectionResult; }

    public int getQuantityInspected() { return quantityInspected; }
    public void setQuantityInspected(int quantityInspected) { this.quantityInspected = quantityInspected; }

    public int getQuantityPassed() { return quantityPassed; }
    public void setQuantityPassed(int quantityPassed) { this.quantityPassed = quantityPassed; }

    public int getQuantityFailed() { return quantityFailed; }
    public void setQuantityFailed(int quantityFailed) { this.quantityFailed = quantityFailed; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Date getInspectionDate() { return inspectionDate; }
    public void setInspectionDate(Date inspectionDate) { this.inspectionDate = inspectionDate; }

    public String getWoName() { return woName; }
    public void setWoName(String woName) { this.woName = woName; }

    public String getStepName() { return stepName; }
    public void setStepName(String stepName) { this.stepName = stepName; }

    public String getInspectorName() { return inspectorName; }
    public void setInspectorName(String inspectorName) { this.inspectorName = inspectorName; }

    public String getResultLabel() {
        if (inspectionResult == null) return "-";
        switch (inspectionResult) {
            case "PASS": return "Dat";
            case "FAIL": return "Khong Dat";
            case "REWORK": return "Sua lai";
            default: return inspectionResult;
        }
    }

    public String getResultBadgeClass() {
        if (inspectionResult == null) return "bg-gray-100 text-gray-600";
        switch (inspectionResult) {
            case "PASS": return "bg-green-100 text-green-700";
            case "FAIL": return "bg-red-100 text-red-700";
            case "REWORK": return "bg-yellow-100 text-yellow-700";
            default: return "bg-gray-100 text-gray-600";
        }
    }

    public double getPassRate() {
        if (quantityInspected <= 0) return 0;
        return Math.round((double) quantityPassed / quantityInspected * 100.0);
    }
}
