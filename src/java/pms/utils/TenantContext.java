package pms.utils;

import java.io.Serializable;

public class TenantContext implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final ThreadLocal<String> currentTenant = new ThreadLocal<>();

    public static void setTenantId(String tenantId) {
        currentTenant.set(tenantId);
    }

    public static String getTenantId() {
        return currentTenant.get();
    }

    public static void clear() {
        currentTenant.remove();
    }

    public static boolean hasTenant() {
        return currentTenant.get() != null;
    }
}
