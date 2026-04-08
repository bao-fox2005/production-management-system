package pms.model;

public class RoutingDTO {

    private int routingId;
    private String routingName;

    public RoutingDTO() {
    }

    public RoutingDTO(int routingId, String routingName) {
        this.routingId = routingId;
        this.routingName = routingName;
    }

    public int getRoutingId() {
        return routingId;
    }

    public void setRoutingId(int routingId) {
        this.routingId = routingId;
    }

    public String getRoutingName() {
        return routingName;
    }

    public void setRoutingName(String routingName) {
        this.routingName = routingName;
    }

}
