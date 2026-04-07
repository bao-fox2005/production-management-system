package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class RoutingDAO {

    public List<RoutingDTO> getAllRouting() {
        List<RoutingDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM [dbo].[Routing]";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new RoutingDTO(rs.getInt("routing_id"), rs.getString("routing_name")));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertRouting(RoutingDTO routing) {
        String sql = "INSERT INTO [dbo].[Routing] ([routing_name]) VALUES(?)";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, routing.getRoutingName());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateRouting(RoutingDTO routing) {
        String sql = "UPDATE [dbo].[Routing] SET [routing_name] = ? WHERE routing_id = ?";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, routing.getRoutingName());
            ps.setInt(2, routing.getRoutingId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteRouting(RoutingDTO routing) {
        String sql = "DELETE FROM [dbo].[Routing] WHERE routing_id = ?";
        try (Connection conn = DBUtils.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, routing.getRoutingId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public RoutingDTO getRoutingById(int routingId) {
        String sql = "SELECT * FROM [dbo].[Routing] WHERE routing_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, routingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new RoutingDTO(rs.getInt("routing_id"), rs.getString("routing_name"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
