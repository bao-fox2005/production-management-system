package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import pms.utils.DBUtils;

public class UserDAO {

    private UserDTO mapResultSet(ResultSet rs) throws Exception {
        return new UserDTO(
                rs.getInt("user_id"),
                rs.getString("username"),
                rs.getString("password_hash"),
                rs.getString("role"),
                rs.getString("full_name"),
                rs.getString("email"),
                rs.getString("phone"),
                rs.getString("status"),
                rs.getTimestamp("created_date")
        );
    }

    private UserDTO SearchByColumn(String column, String value) {
        String sql = "SELECT * FROM Users WHERE " + column + " = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, value);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public UserDTO SearchByName(String username) {
        return SearchByColumn("username", username);
    }

    public UserDTO SearchByID(int id) {
        String s_id = id + "";
        return SearchByColumn("user_id", s_id);
    }

    public UserDTO Login(String username, String password) {
        String sql = "SELECT * FROM Users WHERE username = ? AND password_hash = ? AND status = 'active'";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSet(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public ArrayList<UserDTO> getAllUsers() {
        ArrayList<UserDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Users ORDER BY created_date DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSet(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ArrayList<UserDTO> getUsersByRole(String role) {
        ArrayList<UserDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Users WHERE role = ? ORDER BY created_date DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, role);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSet(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ArrayList<UserDTO> getUsersByStatus(String status) {
        ArrayList<UserDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Users WHERE status = ? ORDER BY created_date DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSet(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean Add(UserDTO u) {
        String sql = "INSERT INTO Users (username, password_hash, role, full_name, email, phone, status) VALUES(?,?,?,?,?,?,?)";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getPassword());
            ps.setString(3, u.getRole());
            ps.setString(4, u.getFullName());
            ps.setString(5, u.getEmail());
            ps.setString(6, u.getPhone());
            ps.setString(7, u.getStatus() != null ? u.getStatus() : "active");
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean Update(UserDTO u) {
        String sql = "UPDATE Users SET username = ?, password_hash = ?, role = ?, full_name = ?, email = ?, phone = ?, status = ? WHERE user_id = ?";
        try (Connection con = DBUtils.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, u.getUsername());
            ps.setString(2, u.getPassword());
            ps.setString(3, u.getRole());
            ps.setString(4, u.getFullName());
            ps.setString(5, u.getEmail());
            ps.setString(6, u.getPhone());
            ps.setString(7, u.getStatus());
            ps.setInt(8, u.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateStatus(int userId, String status) {
        String sql = "UPDATE Users SET status = ? WHERE user_id = ?";
        try (Connection con = DBUtils.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean lockUser(int userId) {
        return updateStatus(userId, "inactive");
    }

    public boolean unlockUser(int userId) {
        return updateStatus(userId, "active");
    }

    public boolean resetPassword(int userId, String newPassword) {
        String sql = "UPDATE Users SET password_hash = ? WHERE user_id = ?";
        try (Connection con = DBUtils.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newPassword);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean changePassword(int userId, String oldPassword, String newPassword) {
        String sql = "UPDATE Users SET password_hash = ? WHERE user_id = ? AND password_hash = ?";
        try (Connection con = DBUtils.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, newPassword);
            ps.setInt(2, userId);
            ps.setString(3, oldPassword);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public boolean verifyPassword(int userId, String password) {
        String sql = "SELECT COUNT(*) FROM Users WHERE user_id = ? AND password_hash = ?";
        try (Connection con = DBUtils.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean Delete(int userId) {
        String sql = "DELETE FROM Users WHERE user_id = ?";
        try (Connection con = DBUtils.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean isUsernameExists(String username, Integer excludeUserId) {
        String sql = "SELECT COUNT(*) FROM Users WHERE username = ?";
        if (excludeUserId != null) {
            sql += " AND user_id != " + excludeUserId;
        }
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public int GetCurrentID() {
        String sql = "SELECT MAX(user_id) as max_id FROM Users";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                int maxId = rs.getInt("max_id");
                return maxId > 0 ? maxId : 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public void ReseedSQL() {
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement("DBCC CHECKIDENT ('Users', RESEED, " + GetCurrentID() + ")")) {
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
