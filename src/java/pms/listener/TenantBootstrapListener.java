package pms.listener;

import java.util.List;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import pms.model.TenantDAO;
import pms.model.TenantDTO;
import pms.utils.MultiTenantDBUtils;

public class TenantBootstrapListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("[TenantBootstrap] Dang khoi dong he thong multi-tenant...");

        // Register default tenant voi DB hien tai
        MultiTenantDBUtils.getInstance().registerTenant(
            "default",
            "localhost",
            "FactoryERD",
            "SA",
            "12345"
        );
        System.out.println("[TenantBootstrap] Default tenant da duoc dang ky.");

        // Load va register tat ca active tenants tu database
        try {
            TenantDAO tenantDAO = new TenantDAO();
            List<TenantDTO> tenants = tenantDAO.getAllTenants();
            int registered = 0;
            for (TenantDTO t : tenants) {
                if (t.isActive() && !t.isExpired() && t.getDbHost() != null && t.getDbName() != null) {
                    MultiTenantDBUtils.getInstance().registerTenant(
                        t.getTenantCode(),
                        t.getDbHost(),
                        t.getDbName(),
                        t.getDbUser(),
                        t.getDbPassword()
                    );
                    registered++;
                }
            }
            System.out.println("[TenantBootstrap] Da dang ky " + registered + " tenant(s) tu database.");
        } catch (Exception e) {
            System.err.println("[TenantBootstrap] Loi khi load tenants: " + e.getMessage());
        }

        System.out.println("[TenantBootstrap] Hoan tat.");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("[TenantBootstrap] Unregistering all tenant connections...");
        MultiTenantDBUtils.getInstance().getAllTenants().keySet().forEach(
            MultiTenantDBUtils.getInstance()::unregisterTenant
        );
    }
}
