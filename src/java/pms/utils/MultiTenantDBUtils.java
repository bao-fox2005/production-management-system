package pms.utils;

import java.io.Serializable;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class MultiTenantDBUtils implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final Map<String, TenantConnection> TENANT_CONNECTIONS = new HashMap<>();

    public static class TenantConnection implements Serializable {
        private static final long serialVersionUID = 1L;
        public final String tenantId;
        public final String dbName;
        public final String dbUser;
        public final String dbPassword;
        public final String host;

        public TenantConnection(String tenantId, String host, String dbName, String dbUser, String dbPassword) {
            this.tenantId = tenantId;
            this.host = host;
            this.dbName = dbName;
            this.dbUser = dbUser;
            this.dbPassword = dbPassword;
        }
    }

    private static volatile MultiTenantDBUtils instance;

    private MultiTenantDBUtils() {}

    public static MultiTenantDBUtils getInstance() {
        if (instance == null) {
            synchronized (MultiTenantDBUtils.class) {
                if (instance == null) instance = new MultiTenantDBUtils();
            }
        }
        return instance;
    }

    public void registerTenant(String tenantId, String host, String dbName, String dbUser, String dbPassword) {
        TENANT_CONNECTIONS.put(tenantId, new TenantConnection(tenantId, host, dbName, dbUser, dbPassword));
    }

    public void unregisterTenant(String tenantId) {
        TENANT_CONNECTIONS.remove(tenantId);
    }

    public Connection getConnection() throws ClassNotFoundException, SQLException {
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || tenantId.isEmpty()) {
            return getDefaultConnection();
        }
        TenantConnection tc = TENANT_CONNECTIONS.get(tenantId);
        if (tc == null) {
            throw new SQLException("Tenant '" + tenantId + "' chua duoc dang ky trong he thong.");
        }
        return getConnectionForTenant(tc);
    }

    public Connection getConnectionForTenant(String tenantId) throws ClassNotFoundException, SQLException {
        TenantConnection tc = TENANT_CONNECTIONS.get(tenantId);
        if (tc == null) {
            throw new SQLException("Tenant '" + tenantId + "' khong ton tai.");
        }
        return getConnectionForTenant(tc);
    }

    public Connection getDefaultConnection() throws ClassNotFoundException, SQLException {
        return getConnectionForTenant("default");
    }

    private Connection getConnectionForTenant(TenantConnection tc) throws ClassNotFoundException, SQLException {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        allowLegacySqlServerTls();
        String url = "jdbc:sqlserver://" + tc.host + ":1433;"
                + "databaseName=" + tc.dbName + ";"
                + "encrypt=false;"
                + "trustServerCertificate=true;";
        return DriverManager.getConnection(url, tc.dbUser, tc.dbPassword);
    }

    private void allowLegacySqlServerTls() {
        try {
            java.security.Security.setProperty("jdk.tls.client.protocols", "TLSv1,TLSv1.1,TLSv1.2");
            java.security.Security.setProperty("https.protocols", "TLSv1,TLSv1.1,TLSv1.2");
            String disabledAlgorithms = java.security.Security.getProperty("jdk.tls.disabledAlgorithms");
            if (disabledAlgorithms != null) {
                String updatedAlgorithms = disabledAlgorithms
                        .replace("TLSv1, ", "")
                        .replace(", TLSv1", "")
                        .replace("TLSv1", "")
                        .replace("TLSv1.1, ", "")
                        .replace(", TLSv1.1", "")
                        .replace("TLSv1.1", "")
                        .replace(", ,", ",")
                        .trim();
                if (updatedAlgorithms.endsWith(",")) {
                    updatedAlgorithms = updatedAlgorithms.substring(0, updatedAlgorithms.length() - 1).trim();
                }
                java.security.Security.setProperty("jdk.tls.disabledAlgorithms", updatedAlgorithms);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public Map<String, TenantConnection> getAllTenants() {
        return new HashMap<>(TENANT_CONNECTIONS);
    }

    public boolean isTenantRegistered(String tenantId) {
        return TENANT_CONNECTIONS.containsKey(tenantId);
    }

    public int getConnectionCount() {
        return TENANT_CONNECTIONS.size();
    }
}
