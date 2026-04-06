package pms.model;

public class RoutingStepDTO {

    private int stepId;
    private int routingId;
    private String stepName;
    private int estimatedTime;
    private boolean isInspected;

    public RoutingStepDTO() {
    }

    public RoutingStepDTO(int stepId, int routingId, String stepName, int estimatedTime, boolean isInspected) {
        this.stepId = stepId;
        this.routingId = routingId;
        this.stepName = stepName;
        this.estimatedTime = estimatedTime;
        this.isInspected = isInspected;
    }

    public int getStepId() {
        return stepId;
    }

    public void setStepId(int stepId) {
        this.stepId = stepId;
    }

    public int getRoutingId() {
        return routingId;
    }

    public void setRoutingId(int routingId) {
        this.routingId = routingId;
    }

    public String getStepName() {
        return stepName;
    }

    public void setStepName(String stepName) {
        this.stepName = stepName;
    }

    public int getEstimatedTime() {
        return estimatedTime;
    }

    public void setEstimatedTime(int estimatedTime) {
        this.estimatedTime = estimatedTime;
    }

    public boolean isIsInspected() {
        return isInspected;
    }

    public void setIsInspected(boolean isInspected) {
        this.isInspected = isInspected;
    }

}
