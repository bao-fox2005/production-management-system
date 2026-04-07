package pms.model;

import java.io.Serializable;
import java.sql.Date;

public class TenantDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private int tenantId;
    private String tenantCode;
    private String tenantName;
    private String dbHost;
    private String dbName;
    private String dbUser;
    private String dbPassword;
    private String smtpHost;
    private String smtpUser;
    private String contactEmail;
    private String contactPhone;
    private String address;
    private String subscriptionPlan;
    private Date expirationDate;
    private boolean active;
    private Date createdDate;
    private String notes;

    public TenantDTO() {}

    public int getTenantId() { return tenantId; }
    public void setTenantId(int tenantId) { this.tenantId = tenantId; }

    public String getTenantCode() { return tenantCode; }
    public void setTenantCode(String tenantCode) { this.tenantCode = tenantCode; }

    public String getTenantName() { return tenantName; }
    public void setTenantName(String tenantName) { this.tenantName = tenantName; }

    public String getDbHost() { return dbHost; }
    public void setDbHost(String dbHost) { this.dbHost = dbHost; }

    public String getDbName() { return dbName; }
    public void setDbName(String dbName) { this.dbName = dbName; }

    public String getDbUser() { return dbUser; }
    public void setDbUser(String dbUser) { this.dbUser = dbUser; }

    public String getDbPassword() { return dbPassword; }
    public void setDbPassword(String dbPassword) { this.dbPassword = dbPassword; }

    public String getSmtpHost() { return smtpHost; }
    public void setSmtpHost(String smtpHost) { this.smtpHost = smtpHost; }

    public String getSmtpUser() { return smtpUser; }
    public void setSmtpUser(String smtpUser) { this.smtpUser = smtpUser; }

    public String getContactEmail() { return contactEmail; }
    public void setContactEmail(String contactEmail) { this.contactEmail = contactEmail; }

    public String getContactPhone() { return contactPhone; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getSubscriptionPlan() { return subscriptionPlan; }
    public void setSubscriptionPlan(String subscriptionPlan) { this.subscriptionPlan = subscriptionPlan; }

    public Date getExpirationDate() { return expirationDate; }
    public void setExpirationDate(Date expirationDate) { this.expirationDate = expirationDate; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Date getCreatedDate() { return createdDate; }
    public void setCreatedDate(Date createdDate) { this.createdDate = createdDate; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public boolean isExpired() {
        if (expirationDate == null) return false;
        java.util.Date now = new java.util.Date();
        return expirationDate.compareTo(now) < 0;
    }

    public String getPlanBadgeClass() {
        if (subscriptionPlan == null) return "bg-gray-100 text-gray-600";
        switch (subscriptionPlan.toLowerCase()) {
            case "enterprise": return "bg-purple-100 text-purple-700";
            case "professional": return "bg-blue-100 text-blue-700";
            case "basic": return "bg-green-100 text-green-700";
            case "trial": return "bg-yellow-100 text-yellow-700";
            default: return "bg-gray-100 text-gray-600";
        }
    }
}
