package pms.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import pms.utils.TenantContext;

public class TenantFilter implements Filter {

    private FilterConfig filterConfig;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        this.filterConfig = filterConfig;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        try {
            HttpServletRequest httpRequest = (HttpServletRequest) request;
            HttpSession session = httpRequest.getSession(false);

            // Lay tenant tu session (duoc set khi switch tenant)
            String tenantCode = null;
            if (session != null) {
                tenantCode = (String) session.getAttribute("currentTenant");
            }

            // Neu chua co tenant trong session, mac dinh la "default"
            if (tenantCode == null || tenantCode.isEmpty()) {
                tenantCode = "default";
            }

            // Dat tenant vao ThreadLocal de DBUtils.getConnection() su dung
            TenantContext.setTenantId(tenantCode);

            chain.doFilter(request, response);
        } finally {
            // Don dep ThreadLocal sau khi request hoan tat
            TenantContext.clear();
        }
    }

    @Override
    public void destroy() {
        this.filterConfig = null;
    }
}
