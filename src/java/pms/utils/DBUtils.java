package pms.utils;

import java.io.Serializable;
import java.security.Security;
import java.sql.Connection;
import java.sql.SQLException;

public class DBUtils implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * Lay connection dua tren tenant hien tai trong TenantContext.
     * Neu chua co tenant thi se su dung default (FactoryERD).
     * Tat ca DAO chi can goi DBUtils.getConnection() nhu cu —
     * khong can thay doi gi them.
     */
    public static Connection getConnection() throws ClassNotFoundException, SQLException {
        return MultiTenantDBUtils.getInstance().getConnection();
    }

    /**
     * Lay connection cho tenant cu the (vien khi can override).
     */
    public static Connection getConnectionForTenant(String tenantId)
            throws ClassNotFoundException, SQLException {
        return MultiTenantDBUtils.getInstance().getConnectionForTenant(tenantId);
    }

    /**
     * Lay default connection (System tenant).
     */
    public static Connection getDefaultConnection() throws ClassNotFoundException, SQLException {
        return MultiTenantDBUtils.getInstance().getDefaultConnection();
    }
}
