package pms.model;

import java.io.Serializable;
import java.sql.Date;

public class ProductionLogDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private int logId;
    private int woId;
    private int stepId;
    private int workerUserId;
    private int producedQuantity;
    private Integer defectId;
    private Date logDate;
    private String stepName;
    private String defectName;
    private String workerName;
    private int quantityDone;
    private int quantityDefective;

    public ProductionLogDTO() {}

    public int getLogId() { return logId; }
    public void setLogId(int logId) { this.logId = logId; }

    public int getWoId() { return woId; }
    public void setWoId(int woId) { this.woId = woId; }

    public int getStepId() { return stepId; }
    public void setStepId(int stepId) { this.stepId = stepId; }

    public int getWorkerUserId() { return workerUserId; }
    public void setWorkerUserId(int workerUserId) { this.workerUserId = workerUserId; }

    public int getProducedQuantity() { return producedQuantity; }
    public void setProducedQuantity(int producedQuantity) { this.producedQuantity = producedQuantity; }

    public Integer getDefectId() { return defectId; }
    public void setDefectId(Integer defectId) { this.defectId = defectId; }

    public Date getLogDate() { return logDate; }
    public void setLogDate(Date logDate) { this.logDate = logDate; }

    public String getStepName() { return stepName; }
    public void setStepName(String stepName) { this.stepName = stepName; }

    public String getDefectName() { return defectName; }
    public void setDefectName(String defectName) { this.defectName = defectName; }

    public String getWorkerName() { return workerName; }
    public void setWorkerName(String workerName) { this.workerName = workerName; }

    public int getQuantityDone() { return quantityDone; }
    public void setQuantityDone(int quantityDone) { this.quantityDone = quantityDone; }

    public int getQuantityDefective() { return quantityDefective; }
    public void setQuantityDefective(int quantityDefective) { this.quantityDefective = quantityDefective; }
}
