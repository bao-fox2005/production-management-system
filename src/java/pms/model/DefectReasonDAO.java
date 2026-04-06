package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class DefectReasonDAO {

    public List<DefectReasonDTO> getAllDefectReasons() {
        List<DefectReasonDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM [dbo].[Defect_Reason]";
        try(Connection conn = DBUtils.getConnection();  
                PreparedStatement ps = conn.prepareStatement(sql);  
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new DefectReasonDTO(rs.getInt("defect_id"), rs.getString("reason_name")));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertDefectReasons(DefectReasonDTO defect) {
        String sql = "INSERT INTO [dbo].[Defect_Reason] ([reason_name]) VALUES(?)";
        try( Connection conn = DBUtils.getConnection();  
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, defect.getReasonName());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateDefectReasons(DefectReasonDTO defect) {
        String sql = "UPDATE [dbo].[Defect_Reason] SET [reason_name] = ? WHERE defect_id = ?";
        try( Connection conn = DBUtils.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, defect.getReasonName());
            ps.setInt(2, defect.getDefectId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteDefectReasons(DefectReasonDTO defect) {
        String sql = "DELETE FROM [dbo].[Defect_Reason] WHERE defect_id = ?";
        try(Connection conn = DBUtils.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, defect.getDefectId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public DefectReasonDTO getDefectReasonById(int defectId) {
        String sql = "SELECT * FROM [dbo].[Defect_Reason] WHERE defect_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, defectId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new DefectReasonDTO(rs.getInt("defect_id"), rs.getString("reason_name"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
