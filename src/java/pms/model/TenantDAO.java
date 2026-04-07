package pms.model;

import java.io.Serializable;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class TenantDAO {

    private boolean isMissingTenantTable(Exception e) {
        return e != null
                && e.getMessage() != null
                && e.getMessage().toLowerCase().contains("invalid object name 'tenant'");
    }

    public List<TenantDTO> getAllTenants() {
        List<TenantDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Tenant ORDER BY tenant_id DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                TenantDTO t = mapTenant(rs);
                list.add(t);
            }
        } catch (Exception e) {
            if (!isMissingTenantTable(e)) {
                e.printStackTrace();
            }
        }
        return list;
    }

    public TenantDTO getTenantByCode(String code) {
        String sql = "SELECT * FROM Tenant WHERE tenant_code = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapTenant(rs);
            }
        } catch (Exception e) {
            if (!isMissingTenantTable(e)) {
                e.printStackTrace();
            }
        }
        return null;
    }

    public boolean insertTenant(TenantDTO tenant) {
        String sql = "INSERT INTO Tenant (tenant_code, tenant_name, db_host, db_name, db_user, db_password, "
                   + "smtp_host, smtp_user, contact_email, contact_phone, address, "
                   + "subscription_plan, expiration_date, active, notes) "
                   + "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tenant.getTenantCode());
            ps.setString(2, tenant.getTenantName());
            ps.setString(3, tenant.getDbHost());
            ps.setString(4, tenant.getDbName());
            ps.setString(5, tenant.getDbUser());
            ps.setString(6, tenant.getDbPassword());
            ps.setString(7, tenant.getSmtpHost());
            ps.setString(8, tenant.getSmtpUser());
            ps.setString(9, tenant.getContactEmail());
            ps.setString(10, tenant.getContactPhone());
            ps.setString(11, tenant.getAddress());
            ps.setString(12, tenant.getSubscriptionPlan() != null ? tenant.getSubscriptionPlan() : "trial");
            ps.setDate(13, tenant.getExpirationDate() != null ? new java.sql.Date(tenant.getExpirationDate().getTime()) : null);
            ps.setBoolean(14, tenant.isActive());
            ps.setString(15, tenant.getNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateTenant(TenantDTO tenant) {
        String sql = "UPDATE Tenant SET tenant_name=?, db_host=?, db_name=?, db_user=?, db_password=?, "
                   + "smtp_host=?, smtp_user=?, contact_email=?, contact_phone=?, address=?, "
                   + "subscription_plan=?, expiration_date=?, active=?, notes=? "
                   + "WHERE tenant_code=?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tenant.getTenantName());
            ps.setString(2, tenant.getDbHost());
            ps.setString(3, tenant.getDbName());
            ps.setString(4, tenant.getDbUser());
            ps.setString(5, tenant.getDbPassword());
            ps.setString(6, tenant.getSmtpHost());
            ps.setString(7, tenant.getSmtpUser());
            ps.setString(8, tenant.getContactEmail());
            ps.setString(9, tenant.getContactPhone());
            ps.setString(10, tenant.getAddress());
            ps.setString(11, tenant.getSubscriptionPlan() != null ? tenant.getSubscriptionPlan() : "trial");
            ps.setDate(12, tenant.getExpirationDate() != null ? new java.sql.Date(tenant.getExpirationDate().getTime()) : null);
            ps.setBoolean(13, tenant.isActive());
            ps.setString(14, tenant.getNotes());
            ps.setString(15, tenant.getTenantCode());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deactivateTenant(String tenantCode) {
        String sql = "UPDATE Tenant SET active = 0 WHERE tenant_code = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tenantCode);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean activateTenant(String tenantCode) {
        String sql = "UPDATE Tenant SET active = 1 WHERE tenant_code = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tenantCode);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private TenantDTO mapTenant(ResultSet rs) throws Exception {
        TenantDTO t = new TenantDTO();
        t.setTenantId(rs.getInt("tenant_id"));
        t.setTenantCode(rs.getString("tenant_code"));
        t.setTenantName(rs.getString("tenant_name"));
        t.setDbHost(rs.getString("db_host"));
        t.setDbName(rs.getString("db_name"));
        t.setDbUser(rs.getString("db_user"));
        t.setDbPassword(rs.getString("db_password"));
        t.setSmtpHost(rs.getString("smtp_host"));
        t.setSmtpUser(rs.getString("smtp_user"));
        t.setContactEmail(rs.getString("contact_email"));
        t.setContactPhone(rs.getString("contact_phone"));
        t.setAddress(rs.getString("address"));
        t.setSubscriptionPlan(rs.getString("subscription_plan"));
        t.setExpirationDate(rs.getDate("expiration_date"));
        t.setActive(rs.getBoolean("active"));
        t.setCreatedDate(rs.getDate("created_date"));
        t.setNotes(rs.getString("notes"));
        return t;
    }
}
