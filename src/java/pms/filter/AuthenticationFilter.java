package pms.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.UserDTO;

public class AuthenticationFilter implements Filter {

    private FilterConfig filterConfig;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        this.filterConfig = filterConfig;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String requestURI = httpRequest.getRequestURI();
        String contextPath = httpRequest.getContextPath();

        String path = requestURI.substring(contextPath.length());

        HttpSession session = httpRequest.getSession(false);
        UserDTO user = null;
        if (session != null) {
            user = (UserDTO) session.getAttribute("user");
        }

        boolean isPublicResource = isPublicPath(path);
        boolean isLoginAction = requestURI.contains("MainController")
                && "loginUser".equals(httpRequest.getParameter("action"));

        if (user == null && !isPublicResource && !isLoginAction) {
            httpResponse.sendRedirect(contextPath + "/login.jsp");
            return;
        }

        if (user != null && !user.isActive()) {
            if (session != null) {
                session.invalidate();
            }
            httpResponse.sendRedirect(contextPath + "/Banned.jsp");
            return;
        }

        if (user != null && !canAccessPath(user, path, httpRequest)) {
            httpResponse.sendRedirect(contextPath + "/DashboardController");
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isPublicPath(String path) {
        String lowerPath = path != null ? path.toLowerCase() : "";
        return "/".equals(path) ||
               "/login.jsp".equals(path) ||
               "/login".equals(path) ||
               "/Banned.jsp".equals(path) ||
               "/BangDieuKien.jsp".equals(path) ||
               "/index.jsp".equals(path) ||
               path.startsWith("/css/") ||
               path.startsWith("/js/") ||
               path.startsWith("/img/") ||
               path.startsWith("/ui/") ||
               path.contains("/AutoCompleteSearch") ||
               path.contains("/NotificationServlet") ||
               lowerPath.endsWith(".css") ||
               lowerPath.endsWith(".js") ||
               lowerPath.endsWith(".png") ||
               lowerPath.endsWith(".jpg") ||
               lowerPath.endsWith(".jpeg") ||
               lowerPath.endsWith(".gif") ||
               lowerPath.endsWith(".svg") ||
               lowerPath.endsWith(".ico") ||
               lowerPath.endsWith(".woff") ||
               lowerPath.endsWith(".woff2") ||
               lowerPath.endsWith(".ttf") ||
               lowerPath.endsWith(".eot");
    }

    private boolean canAccessPath(UserDTO user, String path, HttpServletRequest request) {
        if (user == null) {
            return false;
        }

        String role = user.getRole() != null ? user.getRole().trim().toLowerCase() : "";
        if ("admin".equals(role)) {
            return true;
        }

        if (isWorkerRole(role)) {
            if (isWorkerAllowedPath(path, request)) {
                return true;
            }
            return false;
        }

        return true;
    }

    private boolean isWorkerRole(String role) {
        return "employee".equals(role)
                || "worker".equals(role)
                || "user".equals(role);
    }

    private boolean isWorkerAllowedPath(String path, HttpServletRequest request) {
        if (path == null) {
            return false;
        }

        if ("/DashboardController".equals(path)
                || "/WorkOrderController".equals(path)
                || "/ProductionLogController".equals(path)
                || "/QcController".equals(path)
                || "/KanbanController".equals(path)
                || "/PurchaseOrderController".equals(path)
                || "/FileController".equals(path)
                || "/profile.jsp".equals(path)
                || "/UserController".equals(path)) {
            return true;
        }

        if ("/MainController".equals(path)) {
            String action = request.getParameter("action");
            return "listWorkOrder".equals(action)
                    || "listPurchaseOrder".equals(action)
                    || "searchPurchaseOrder".equals(action)
                    || "addPurchaseOrder".equals(action);
        }

        return false;
    }

    @Override
    public void destroy() {
        this.filterConfig = null;
    }
}
