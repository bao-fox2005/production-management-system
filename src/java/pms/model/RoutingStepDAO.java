package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class RoutingStepDAO {

    public List<RoutingStepDTO> getAllRoutingStep() {
        List<RoutingStepDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM [dbo].[Routing_Step]";
        try (Connection conn = DBUtils.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql); 
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new RoutingStepDTO(rs.getInt("step_id"), rs.getInt("routing_id"),
                        rs.getString("step_name"), rs.getInt("estimated_time"), rs.getBoolean("is_inspected")));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertRoutingStep(RoutingStepDTO step) {
        String sql = "INSERT INTO [dbo].[Routing_Step] (routing_id, step_name, estimated_time, is_inspected) VALUES(?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, step.getRoutingId());
            ps.setString(2, step.getStepName());
            ps.setInt(3, step.getEstimatedTime());
            ps.setBoolean(4, step.isIsInspected());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateRoutingStep(RoutingStepDTO step) {
        String sql = "UPDATE [dbo].[Routing_Step] SET routing_id = ?, step_name = ?, estimated_time = ?, is_inspected = ? WHERE step_id = ?";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, step.getRoutingId());
            ps.setString(2, step.getStepName());
            ps.setInt(3, step.getEstimatedTime());
            ps.setBoolean(4, step.isIsInspected());
            ps.setInt(5, step.getStepId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteRoutingStep(int stepId) {
        String sql = "DELETE FROM [dbo].[Routing_Step] WHERE step_id = ?";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stepId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public RoutingStepDTO getRoutingStepById(int stepId) {
        String sql = "SELECT * FROM [dbo].[Routing_Step] WHERE step_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stepId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new RoutingStepDTO(
                        rs.getInt("step_id"),
                        rs.getInt("routing_id"),
                        rs.getString("step_name"),
                        rs.getInt("estimated_time"),
                        rs.getBoolean("is_inspected")
                    );
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<RoutingStepDTO> getRoutingStepsByRoutingId(int routingId) {
        List<RoutingStepDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM [dbo].[Routing_Step] WHERE routing_id = ? ORDER BY step_id";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, routingId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new RoutingStepDTO(
                        rs.getInt("step_id"),
                        rs.getInt("routing_id"),
                        rs.getString("step_name"),
                        rs.getInt("estimated_time"),
                        rs.getBoolean("is_inspected")
                    ));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}