package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.TenantDAO;
import pms.model.TenantDTO;
import pms.model.UserDTO;
import pms.utils.TenantContext;
import pms.utils.MultiTenantDBUtils;

/**
 * TenantController – Servlet quản lý Tenant (Khách thuê) trong hệ thống Multi-Tenant.
 *
 * Hệ thống Multi-Tenant cho phép nhiều tổ chức (tenant) cùng dùng chung một codebase
 * nhưng mỗi tenant có database riêng biệt. TenantController quản lý:
 *
 *   - Tạo tenant mới và đăng ký connection pool riêng (MultiTenantDBUtils)
 *   - Kích hoạt / vô hiệu hóa tenant
 *   - Chuyển đổi giữa các tenant (switchTenant) trong một session
 *
 * Phân quyền:
 *   - Chỉ admin mới có quyền thao tác trên TenantController.
 *   - TenantContext.setTenantId() được gọi khi admin đăng nhập để đặt tenant ngữ cảnh.
 *
 * TenantContext là ThreadLocal lưu tenantId của request hiện tại,
 * giúp MultiTenantDBUtils chọn đúng database connection cho request đó.
 *
 * Chức năng:
 *   - list       : Xem danh sách tất cả tenant
 *   - add        : Hiển thị form thêm tenant mới
 *   - saveAdd    : Lưu tenant mới và đăng ký DB connection pool
 *   - activate   : Kích hoạt tenant đã bị vô hiệu hóa
 *   - deactivate : Vô hiệu hóa tenant (xóa khỏi connection pool)
 *   - switch     : Admin chuyển sang ngữ cảnh tenant khác trong session
 */
public class TenantController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chung.
     * Trước khi phân luồng: nếu là admin thì set TenantContext theo username admin.
     * saveAdd, activate, deactivate, switch đều redirect sau khi xử lý.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Đặt TenantContext cho admin: dùng username làm tenantId mặc định
        HttpSession session = request.getSession(false);
        if (session != null) {
            UserDTO user = (UserDTO) session.getAttribute("user");
            if (user != null && "admin".equalsIgnoreCase(user.getRole())) {
                TenantContext.setTenantId(user.getUsername()); // Đặt context cho request này
            }
        }

        String action = request.getParameter("action");
        if (action == null) action = "list";

        String url = "";

        switch (action) {
            case "list":
                listTenants(request);             // Tải danh sách tenant
                url = "tenant-list.jsp";
                break;
            case "add":
                showAddForm(request);             // Hiển thị form thêm tenant
                url = "tenant-form.jsp";
                break;
            case "saveAdd":
                saveTenant(request);              // Lưu tenant mới
                url = "redirect:TenantController?action=list";
                return; // Đã set url nên return để thực hiện redirect
            case "activate":
                activateTenant(request);          // Kích hoạt tenant
                url = "redirect:TenantController?action=list";
                return;
            case "deactivate":
                deactivateTenant(request);        // Vô hiệu hóa tenant
                url = "redirect:TenantController?action=list";
                return;
            case "switch":
                switchTenant(request);            // Chuyển sang tenant khác
                url = "redirect:DashboardController";
                return;
            default:
                listTenants(request);
                url = "tenant-list.jsp";
                break;
        }

        if (url.startsWith("redirect:")) {
            response.sendRedirect(url.substring(9));
        } else {
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Tải và đưa danh sách tất cả tenant vào request.
     */
    private void listTenants(HttpServletRequest request) {
        TenantDAO dao = new TenantDAO();
        List<TenantDTO> list = dao.getAllTenants(); // Lấy tất cả tenant từ DB
        request.setAttribute("tenants", list);
    }

    /**
     * Chuẩn bị form thêm tenant mới (chỉ set mode để JSP hiển thị form).
     */
    private void showAddForm(HttpServletRequest request) {
        request.setAttribute("mode", "add"); // JSP dùng mode để chọn UI form
    }

    /**
     * Lưu tenant mới vào DB và đăng ký connection pool cho database của tenant đó.
     *
     * Quy trình:
     *   1. Build TenantDTO từ form (thông tin kết nối DB, SMTP, liên hệ…)
     *   2. INSERT vào bảng Tenant
     *   3. Nếu thành công → đăng ký connection pool qua MultiTenantDBUtils.registerTenant()
     *
     * Sau khi đăng ký, mọi request từ tenant này sẽ dùng đúng DB connection của họ.
     *
     * @param request Chứa các tham số: tenantCode, tenantName, dbHost, dbName, dbUser, dbPassword,
     *                smtpHost, smtpUser, contactEmail, contactPhone, address, subscriptionPlan, notes
     */
    private void saveTenant(HttpServletRequest request) {
        try {
            TenantDTO tenant = new TenantDTO();
            tenant.setTenantCode(request.getParameter("tenantCode"));           // Mã định danh tenant
            tenant.setTenantName(request.getParameter("tenantName"));           // Tên hiển thị
            tenant.setDbHost(request.getParameter("dbHost"));                   // Host DB riêng
            tenant.setDbName(request.getParameter("dbName"));                   // Tên DB riêng
            tenant.setDbUser(request.getParameter("dbUser"));                   // Username DB
            tenant.setDbPassword(request.getParameter("dbPassword"));           // Password DB
            tenant.setSmtpHost(request.getParameter("smtpHost"));              // SMTP email server
            tenant.setSmtpUser(request.getParameter("smtpUser"));              // Tài khoản email
            tenant.setContactEmail(request.getParameter("contactEmail"));       // Email liên hệ
            tenant.setContactPhone(request.getParameter("contactPhone"));       // Số điện thoại
            tenant.setAddress(request.getParameter("address"));                 // Địa chỉ
            tenant.setSubscriptionPlan(request.getParameter("subscriptionPlan")); // Gói dịch vụ
            tenant.setNotes(request.getParameter("notes"));                     // Ghi chú thêm
            tenant.setActive(true);                                              // Mặc định kích hoạt ngay

            TenantDAO dao = new TenantDAO();
            boolean success = dao.insertTenant(tenant); // INSERT vào DB

            if (success) {
                // Đăng ký connection pool cho DB riêng của tenant này
                // Sau này mọi request từ tenant sẽ dùng đúng pool này
                MultiTenantDBUtils.getInstance().registerTenant(
                    tenant.getTenantCode(),  // Key để tra cứu pool
                    tenant.getDbHost(),      // Host DB
                    tenant.getDbName(),      // Database name
                    tenant.getDbUser(),      // Username
                    tenant.getDbPassword()   // Password
                );
                request.setAttribute("msg", "Tenant '" + tenant.getTenantName() + "' da duoc tao thanh cong!");
            } else {
                request.setAttribute("error", "Loi khi tao tenant.");
            }

        } catch (Exception e) {
            request.setAttribute("error", "Loi: " + e.getMessage());
        }
    }

    /**
     * Kích hoạt tenant đã bị vô hiệu hóa.
     * Sau khi kích hoạt: đăng ký lại connection pool của tenant đó.
     *
     * @param request Chứa "code" (tenantCode cần kích hoạt)
     */
    private void activateTenant(HttpServletRequest request) {
        String code = request.getParameter("code"); // Mã tenant cần kích hoạt
        if (code == null) return;

        TenantDAO dao = new TenantDAO();
        TenantDTO tenant = dao.getTenantByCode(code); // Lấy thông tin DB của tenant

        if (tenant != null) {
            dao.activateTenant(code); // Cập nhật is_active = true trong DB

            // Tái đăng ký connection pool (có thể đã bị xóa khi deactivate)
            MultiTenantDBUtils.getInstance().registerTenant(
                tenant.getTenantCode(),
                tenant.getDbHost(),
                tenant.getDbName(),
                tenant.getDbUser(),
                tenant.getDbPassword()
            );
            request.setAttribute("msg", "Tenant da duoc kich hoat.");
        }
    }

    /**
     * Vô hiệu hóa tenant.
     * Sau khi vô hiệu hóa:
     *   - Xóa connection pool của tenant khỏi MultiTenantDBUtils
     *   - Xóa TenantContext hiện tại (nếu đang dùng context của tenant này)
     *
     * @param request Chứa "code" (tenantCode cần vô hiệu hóa)
     */
    private void deactivateTenant(HttpServletRequest request) {
        String code = request.getParameter("code");
        if (code == null) return;

        TenantDAO dao = new TenantDAO();
        dao.deactivateTenant(code);                        // Cập nhật is_active = false

        MultiTenantDBUtils.getInstance().unregisterTenant(code); // Đóng và xóa connection pool
        TenantContext.clear();                             // Xóa threadlocal context hiện tại

        request.setAttribute("msg", "Tenant da bi vo hieu hoa.");
    }

    /**
     * Chuyển đổi ngữ cảnh tenant trong session (Admin switching tenant).
     * Nếu tenant hợp lệ (active và chưa expired):
     *   - Đặt TenantContext.tenantId = code (ThreadLocal cho request này)
     *   - Lưu "currentTenant" vào session để các request sau biết đang dùng tenant nào
     *
     * @param request Chứa "code" (tenantCode muốn chuyển sang)
     */
    private void switchTenant(HttpServletRequest request) {
        String code = request.getParameter("code");
        if (code == null) return;

        TenantDAO dao = new TenantDAO();
        TenantDTO tenant = dao.getTenantByCode(code); // Lấy thông tin tenant mục tiêu

        if (tenant != null && tenant.isActive() && !tenant.isExpired()) {
            TenantContext.setTenantId(code); // Đặt context cho request hiện tại

            HttpSession sess = request.getSession(true); // Tạo session mới nếu chưa có
            sess.setAttribute("currentTenant", code);    // Lưu tenantCode vào session

            request.setAttribute("msg", "Da chuyen sang tenant: " + tenant.getTenantName());
        }
    }

    /** Xử lý HTTP GET */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}
