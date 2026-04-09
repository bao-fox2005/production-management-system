package pms.utils;

import java.io.Serializable;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

public class SystemConfigService implements Serializable {

    private boolean isMissingSystemConfigTable(Exception e) {
        return e != null
                && e.getMessage() != null
                && e.getMessage().toLowerCase().contains("invalid object name 'systemconfig'");
    }

    private static final Map<String, String> DEFAULT_CONFIG = new HashMap<>();
    static {
        DEFAULT_CONFIG.put("SMTP_HOST", "smtp.gmail.com");
        DEFAULT_CONFIG.put("SMTP_PORT", "587");
        DEFAULT_CONFIG.put("SMTP_USER", "your-email@gmail.com");
        DEFAULT_CONFIG.put("SMTP_PASSWORD", "your-app-password");
        DEFAULT_CONFIG.put("BANK_BIN", "970406");
        DEFAULT_CONFIG.put("BANK_ACCOUNT", "1234567890");
        DEFAULT_CONFIG.put("BANK_ACCOUNT_NAME", "CONG TY TNHH PMS");
        DEFAULT_CONFIG.put("QR_EXPIRE_MINUTES", "15");
        DEFAULT_CONFIG.put("MAX_FILE_SIZE_MB", "10");
        DEFAULT_CONFIG.put("AUTO_PAYMENT_CHECK_SECONDS", "30");
        DEFAULT_CONFIG.put("COMPANY_NAME", "PMS Company");
        DEFAULT_CONFIG.put("COMPANY_PHONE", "0123-456-789");
        DEFAULT_CONFIG.put("COMPANY_ADDRESS", "123 Duong ABC, Quan 1, TP.HCM");
        DEFAULT_CONFIG.put("ADMIN_EMAIL", "");
    }

    public String getConfig(String key) {
        String sql = "SELECT config_value FROM SystemConfig WHERE config_key = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("config_value");
                }
            }
        } catch (Exception e) {
            if (!isMissingSystemConfigTable(e)) {
                e.printStackTrace();
            }
        }
        return DEFAULT_CONFIG.get(key);
    }

    public String getConfig(String key, String defaultValue) {
        String value = getConfig(key);
        return value != null ? value : defaultValue;
    }

    public boolean setConfig(String key, String value) {
        String updateSql = "UPDATE SystemConfig SET config_value = ?, updated_at = GETDATE() WHERE config_key = ?";
        String insertSql = "INSERT INTO SystemConfig (config_key, config_value, description) VALUES (?, ?, ?)";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement updatePs = con.prepareStatement(updateSql)) {
            updatePs.setString(1, value);
            updatePs.setString(2, key);
            int updated = updatePs.executeUpdate();
            if (updated > 0) {
                return true;
            }

            try (PreparedStatement insertPs = con.prepareStatement(insertSql)) {
                insertPs.setString(1, key);
                insertPs.setString(2, value);
                insertPs.setString(3, "Dynamic config");
                return insertPs.executeUpdate() > 0;
            }
        } catch (Exception e) {
            if (!isMissingSystemConfigTable(e)) {
                e.printStackTrace();
            }
        }
        return false;
    }

    public Map<String, String> getAllConfigs() {
        Map<String, String> configs = new HashMap<>(DEFAULT_CONFIG);
        String sql = "SELECT config_key, config_value, description FROM SystemConfig ORDER BY config_key";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                configs.put(rs.getString("config_key"), rs.getString("config_value"));
            }
        } catch (Exception e) {
            if (!isMissingSystemConfigTable(e)) {
                e.printStackTrace();
            }
        }
        return configs;
    }

    public boolean saveAllConfigs(Map<String, String> configs) {
        boolean allSuccess = true;
        for (Map.Entry<String, String> entry : configs.entrySet()) {
            if (!setConfig(entry.getKey(), entry.getValue())) {
                allSuccess = false;
            }
        }
        return allSuccess;
    }

    public boolean initDefaultConfigs() {
        String sql = "SELECT COUNT(*) FROM SystemConfig";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next() && rs.getInt(1) > 0) {
                return true;
            }
        } catch (Exception e) {
            if (!isMissingSystemConfigTable(e)) {
                e.printStackTrace();
            }
        }

        String insertSql = "INSERT INTO SystemConfig (config_key, config_value, description) VALUES(?,?,?)";
        try (Connection con = DBUtils.getConnection()) {
            for (Map.Entry<String, String> entry : DEFAULT_CONFIG.entrySet()) {
                try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                    ps.setString(1, entry.getKey());
                    ps.setString(2, entry.getValue());
                    ps.setString(3, "Auto-generated default");
                    ps.executeUpdate();
                } catch (Exception e) {
                    // ignore duplicate
                }
            }
            return true;
        } catch (Exception e) {
            if (!isMissingSystemConfigTable(e)) {
                e.printStackTrace();
            }
        }
        return false;
    }

    public String getAdminEmail() {
        String configuredAdminEmail = getConfig("ADMIN_EMAIL", "");
        if (configuredAdminEmail != null && !configuredAdminEmail.trim().isEmpty()) {
            return configuredAdminEmail.trim();
        }

        String sql = "SELECT TOP 1 email FROM Users WHERE role = 'admin' AND email IS NOT NULL AND email != '' AND status = 'active'";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getString("email");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    // Convenience getters
    public String getSmtpHost() { return getConfig("SMTP_HOST"); }
    public String getSmtpPort() { return getConfig("SMTP_PORT"); }
    public String getSmtpUser() { return getConfig("SMTP_USER"); }
    public String getSmtpPassword() { return getConfig("SMTP_PASSWORD"); }
    public String getBankBin() { return getConfig("BANK_BIN"); }
    public String getBankAccount() { return getConfig("BANK_ACCOUNT"); }
    public String getBankAccountName() { return getConfig("BANK_ACCOUNT_NAME"); }
    public int getQrExpireMinutes() {
        try {
            return Integer.parseInt(getConfig("QR_EXPIRE_MINUTES", "1440"));
        } catch (Exception e) { return 1440; }
    }
    public String getCompanyName() { return getConfig("COMPANY_NAME"); }
    public String getCompanyPhone() { return getConfig("COMPANY_PHONE"); }
    public String getCompanyAddress() { return getConfig("COMPANY_ADDRESS"); }

    public boolean hasValidSmtpConfig() {
        String host = trimToNull(getSmtpHost());
        String user = trimToNull(getSmtpUser());
        String password = trimToNull(getSmtpPassword());
        String port = trimToNull(getSmtpPort());
        return host != null
                && user != null
                && password != null
                && port != null
                && !isPlaceholderValue(user, "your-email@gmail.com")
                && !isPlaceholderValue(password, "your-app-password");
    }

    public boolean hasValidBankReceiverConfig() {
        String serialized = trimToNull(getConfig("BANK_RECEIVER_ACCOUNTS", ""));
        if (serialized != null) {
            String[] rows = serialized.split(";;");
            for (String row : rows) {
                String current = trimToNull(row);
                if (current == null) {
                    continue;
                }
                String[] parts = current.split("\\|\\|", -1);
                if (parts.length < 4) {
                    continue;
                }
                String bin = trimToNull(parts[1]);
                String account = trimToNull(parts[2]);
                String name = trimToNull(parts[3]);
                if (hasCompleteBankReceiver(bin, account, name)) {
                    return true;
                }
            }
        }

        String bankBin = trimToNull(getBankBin());
        String bankAccount = trimToNull(getBankAccount());
        String bankAccountName = trimToNull(getBankAccountName());
        return hasCompleteBankReceiver(bankBin, bankAccount, bankAccountName);
    }
    private boolean hasCompleteBankReceiver(String bankBin, String bankAccount, String bankAccountName) {
        return bankBin != null
                && bankAccount != null
                && bankAccountName != null
                && !isDefaultBankReceiver(bankBin, bankAccount, bankAccountName);
    }

    private boolean isDefaultBankReceiver(String bankBin, String bankAccount, String bankAccountName) {
        return isPlaceholderValue(bankBin, "970406")
                && isPlaceholderValue(bankAccount, "1234567890")
                && isPlaceholderValue(bankAccountName, "CONG TY TNHH PMS");
    }

    public EmailService createEmailService() {
        EmailService email = new EmailService();
        email.setSmtpHost(getSmtpHost());
        email.setSmtpPort(getSmtpPort());
        email.setSmtpUser(getSmtpUser());
        email.setSmtpPassword(getSmtpPassword());
        return email;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private boolean isPlaceholderValue(String value, String placeholder) {
        String normalized = trimToNull(value);
        String expected = trimToNull(placeholder);
        return normalized != null && expected != null && normalized.equalsIgnoreCase(expected);
    }
}
