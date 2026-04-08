<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%-- 
  Shared Sidebar Component for PMS System
  Dùng chung cho tất cả các trang JSP
  
  Tự động lấy biến từ session/request, không cần parent JSP set trước.
--%>
<% 
    // Lấy user từ session
    pms.model.UserDTO sidebarUser = (pms.model.UserDTO) session.getAttribute("user");
    String activePage = request.getAttribute("activePage") != null ? (String) request.getAttribute("activePage") : "";
    String userName = sidebarUser != null ? sidebarUser.getUsername() : "User";
    String userRole = sidebarUser != null ? sidebarUser.getRole() : "";
    String normalizedRole = userRole != null ? userRole.trim().toLowerCase() : "";
    boolean isAdmin = "admin".equalsIgnoreCase(normalizedRole);
    boolean isWorker = "employee".equalsIgnoreCase(normalizedRole)
            || "worker".equalsIgnoreCase(normalizedRole)
            || "user".equalsIgnoreCase(normalizedRole);
    boolean canViewDashboard = isAdmin || isWorker;
    boolean canViewWork = isAdmin || isWorker;
    boolean canViewReports = isAdmin || isWorker;
    boolean canManageData = isAdmin;
    boolean canManageSystem = isAdmin;
%>

<!-- Sidebar Cố Định - Shared Component -->
<aside id="sidebar" class="sidebar-fixed w-[280px] shrink-0 bg-slate-900 text-white flex flex-col h-screen shadow-2xl shadow-slate-950/40">
    <!-- Logo Cố Định -->
    <div class="sidebar-header h-16 flex items-center gap-3 px-5 border-b border-slate-700">
        <div class="w-10 h-10 rounded-xl bg-teal-500 flex items-center justify-center shrink-0">
            <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
            </svg>
        </div>
        <div class="min-w-0">
            <p class="font-bold text-sm truncate">Hệ thống PMS</p>
            <p class="text-xs text-slate-400 truncate">Quản lý sản xuất</p>
        </div>
    </div>
    
    <!-- Navigation Scroll Riêng -->
    <nav class="sidebar-nav flex-1 py-4 px-3 space-y-1">
        <% if (canViewDashboard) { %>
        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider">Tổng Quan</p>
        <a href="DashboardController" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "dashboard".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"/></svg>
            Bảng điều khiển
        </a>
        <% } %>

        <% if (canViewWork) { %>
        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider mt-4">Công Việc</p>
        <a href="MainController?action=listWorkOrder" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "workorder".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
            Lệnh sản xuất
        </a>
        <% if (isAdmin) { %>
        <a href="KanbanController" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "kanban".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7"/></svg>
            Bảng tiến độ
        </a>
        <a href="WorkOrderController?action=calendar" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "calendar".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            Lịch sản xuất
        </a>
        <% } %>
        <% } %>

        <% if (canViewReports) { %>
        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider mt-4">Báo Cáo</p>
        <a href="ProductionLogController" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "productionlog".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            Nhật ký sản xuất
        </a>
        <a href="QcController?action=list" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "qc".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            Kiểm tra chất lượng
        </a>
        <% } %>

        <% if (isWorker) { %>
        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider mt-4">Vật Tư</p>
        <a href="MainController?action=listPurchaseOrder" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "purchaseorder".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Đề nghị nhập vật tư
        </a>
        <% } %>

        <% if (canManageData) { %>
        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider mt-4">Quản Lý</p>
        <a href="MainController?action=listBOM" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "bom".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
            Định mức (BOM)
        </a>
        <a href="MainController?action=listPurchaseOrder" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "purchaseorder".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Đề nghị nhập vật tư
        </a>
        <a href="MainController?action=listBill" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "bill".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            Quản lý hóa đơn
        </a>

        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider mt-4">Danh Mục</p>
        <a href="ItemController?action=list" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "item".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            Vật tư / sản phẩm
        </a>
        <a href="CustomerController?action=listCustomer" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "customer".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            Khách hàng
        </a>
        <a href="SupplierController?action=listSupplier" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "supplier".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
            Nhà cung cấp
        </a>
        <a href="listRouting.jsp" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "routing".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
            Quy trình (Routing)
        </a>
        <a href="MainController?action=listRoutingStep" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "routingstep".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
            Công đoạn chi tiết
        </a>
        <a href="DefectController?action=listDefectReason" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "defect".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
            Lý do lỗi
        </a>
        <% } %>

        <% if (canManageSystem) { %>
        <p class="px-3 py-2 text-xs font-semibold text-slate-400 uppercase tracking-wider mt-4">Hệ Thống</p>
        <a href="UserController?action=list" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "user".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            Người dùng
        </a>
        <%-- Ẩn menu Doanh nghiệp và Quản lý file theo yêu cầu nghiệp vụ --%>
        <%--
        <a href="TenantController?action=list" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "tenant".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
            Doanh nghiệp
        </a>
        <a href="file-management.jsp" class="flex items-center gap-3 px-3 py-2.5 rounded-xl <%= "file".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-semibold shadow-inner shadow-teal-900/30 ring-1 ring-teal-400/20" : "text-slate-300 hover:bg-slate-800/90 hover:text-white" %> transition-all duration-200">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"/></svg>
            Quản lý file
        </a>
        --%>
        <% } %>
    </nav>
    
    <!-- User Section Cố Định: avatar + tên + role + dropdown + nút cài đặt -->
    <div class="sidebar-footer border-t border-slate-700 p-4 relative">
        <div class="flex items-center gap-3">
            <button type="button" onclick="toggleSidebarUserMenu()" class="flex-1 flex items-center gap-3 min-w-0 text-left rounded-xl py-2.5 px-2.5 hover:bg-slate-800/90 transition-all duration-200">
                <div class="w-10 h-10 rounded-full bg-teal-500 flex items-center justify-center font-bold shrink-0">
                    <%= userName.length() > 0 ? userName.substring(0,1).toUpperCase() : "U" %>
                </div>
                <div class="flex-1 min-w-0">
                    <p class="font-semibold text-sm truncate"><%= userName %></p>
                    <p class="text-xs text-slate-400 truncate"><%= userRole %></p>
                </div>
                <svg class="w-4 h-4 text-slate-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
            </button>
            <% if (isAdmin) { %>
            <a href="email-settings.jsp" class="w-10 h-10 flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-800/90 hover:text-white transition-all duration-200 shrink-0" title="Cài đặt">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            </a>
            <% } %>
        </div>
        <div id="sidebarUserMenu" class="hidden absolute bottom-full left-2 right-2 mb-1 py-1.5 bg-slate-800 rounded-xl border border-slate-700 shadow-xl z-50">
            <a href="profile.jsp" class="flex items-center gap-2 px-3 py-2.5 rounded-lg text-slate-300 hover:bg-slate-700 text-sm transition-all duration-200">Hồ Sơ Cá Nhân</a>
            <a href="UserController?action=logout" class="flex items-center gap-2 px-3 py-2.5 rounded-lg text-red-400 hover:bg-red-500/20 text-sm transition-all duration-200">Đăng Xuất</a>
        </div>
    </div>
</aside>

<!-- Overlay for Mobile -->
<div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-30 lg:hidden hidden" onclick="toggleSidebar()"></div>
