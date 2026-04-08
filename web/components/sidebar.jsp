<%-- 
  Shared Sidebar Component for PMS System
  Include this file in all JSP pages that need the sidebar
  
  Usage:
    String activePage = "dashboard"; // Set the current active page identifier
    boolean isAdmin = "admin".equalsIgnoreCase(userRole); // Set before including
    UserDTO user = (UserDTO) session.getAttribute("user");
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
--%>

<!-- Sidebar -->
<aside id="sidebar" class="fixed inset-y-0 left-0 z-30 flex h-screen w-72 -translate-x-full flex-col bg-slate-900 text-white transition-transform duration-300 lg:static lg:translate-x-0">
    <!-- Logo -->
    <div class="flex h-16 shrink-0 items-center gap-3 border-b border-slate-800 px-6">
        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-teal-500/10">
            <svg class="h-6 w-6 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
            </svg>
        </div>
        <div>
            <p class="text-sm font-semibold tracking-wide">PMS System</p>
            <p class="text-xs text-slate-400">Production Management</p>
        </div>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 overflow-y-auto py-4 px-3 space-y-1">
        <!-- Tổng Quan -->
        <p class="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Tổng Quan</p>
        <a href="DashboardController" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "dashboard".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"/></svg>
            Dashboard
        </a>

        <!-- Sản Xuất -->
        <p class="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-slate-400 mt-4">Sản Xuất</p>
        <a href="MainController?action=listWorkOrder" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "workorder".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
            Lệnh Sản Xuất
        </a>
        <a href="ProductionLogController" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "productionlog".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            Nhật Ký Sản Xuất
        </a>
        <a href="QcController?action=list" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "qc".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            Kiểm Tra Chất Lượng
        </a>
        <a href="kanban.jsp" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "kanban".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7"/></svg>
            Kanban Board
        </a>
        <a href="production-gantt.jsp" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "gantt".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            Lịch Sản Xuất
        </a>

        <!-- Quản Lý -->
        <p class="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-slate-400 mt-4">Quản Lý</p>
        <a href="MainController?action=listBOM" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "bom".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
            Định Mức (BOM)
        </a>
        <a href="MainController?action=listRouting" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "routing".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
            Quy Trình Sản Xuất
        </a>
        <a href="DefectController?action=listDefectReason" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "defect".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
            Nguyên Nhân Lỗi
        </a>
        <a href="MainController?action=listBill" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "bill".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            Quản Lý Hóa Đơn
        </a>

        <!-- Danh Mục -->
        <p class="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-slate-400 mt-4">Danh Mục</p>
        <a href="ItemController?action=list" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "item".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            Vật Tư / Sản Phẩm
        </a>
        <a href="CustomerController?action=listCustomer" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "customer".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
            Khách Hàng
        </a>
        <a href="SupplierController?action=listSupplier" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "supplier".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
            Nhà Cung Cấp
        </a>
        <a href="SearchPurchaseOrder.jsp" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "purchaseorder".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            Đơn Đặt Hàng
        </a>

        <% if (isAdmin) { %>
        <!-- Hệ Thống (Admin Only) -->
        <p class="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-slate-400 mt-4">Hệ Thống</p>
        <a href="UserController?action=list" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "user".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            Người Dùng
        </a>
        <a href="TenantController?action=list" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "tenant".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/></svg>
            Quản Lý Tenant
        </a>
        <a href="email-settings.jsp" class="nav-item flex items-center gap-3 px-3 py-2.5 rounded-lg <%= "admin".equals(activePage) ? "bg-teal-500/20 text-teal-300 font-medium" : "text-slate-300 hover:bg-slate-800" %>">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/></svg>
            Cấu Hình Email
        </a>
        <% } %>
    </nav>

    <!-- User Section -->
    <div class="shrink-0 border-t border-slate-800 p-4">
        <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-full bg-teal-500 flex items-center justify-center font-bold text-white">
                <%= userName.substring(0,1).toUpperCase() %>
            </div>
            <div class="flex-1 min-w-0">
                <p class="font-semibold text-sm truncate"><%= userName %></p>
                <p class="text-xs text-slate-400"><%= userRole %></p>
            </div>
        </div>
    </div>
</aside>

<!-- Sidebar Overlay for Mobile -->
<div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>
