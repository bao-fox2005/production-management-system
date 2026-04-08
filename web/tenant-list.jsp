<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.TenantDTO, pms.model.UserDTO, java.text.SimpleDateFormat, java.text.DecimalFormat, pms.utils.NotificationService.Notification"%>
<%
    List<TenantDTO> tenants = (List<TenantDTO>) request.getAttribute("tenants");
    UserDTO user = (UserDTO) session.getAttribute("user");
    List<Notification> notifications = (List<Notification>) session.getAttribute("notifications");
    
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    String filterStatus = request.getParameter("filter");
    
    if (tenants == null) tenants = new java.util.ArrayList<>();
    if (filterStatus == null) filterStatus = "all";
    if (notifications == null) notifications = new java.util.ArrayList<>();
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    
    int countActive = 0;
    int countExpired = 0;
    int countTrial = 0;
    
    for (TenantDTO t : tenants) {
        if (t.isActive() && !t.isExpired()) countActive++;
        else if (t.isExpired()) countExpired++;
        if ("trial".equalsIgnoreCase(t.getSubscriptionPlan())) countTrial++;
    }
    
    int unreadCount = 0;
    for (Notification n : notifications) {
        if (!n.isRead()) unreadCount++;
    }
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String pageTitle = "Quản Lý Tenant";
    String pageSubtitle = "Quản lý các tenant trong hệ thống";
    request.setAttribute("activePage", "tenant");
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    
    String filterParam = request.getParameter("filter");
    if (filterParam == null) filterParam = "all";
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản Lý Tenant - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif'],
                    },
                }
            }
        }
    </script>
    <style>
        * { font-family: 'Inter', 'Segoe UI', Arial, sans-serif; }
        body { overflow-x: hidden; }
        
        .sidebar-fixed {
            position: fixed;
            top: 0;
            left: 0;
            height: 100vh;
            z-index: 40;
        }
        
        .sidebar-header {
            position: sticky;
            top: 0;
            background: #0f172a;
            z-index: 10;
        }
        
        .sidebar-nav {
            flex: 1;
            overflow-y: auto;
            scrollbar-width: thin;
            scrollbar-color: #475569 #1e293b;
        }
        .sidebar-nav::-webkit-scrollbar {
            width: 4px;
        }
        .sidebar-nav::-webkit-scrollbar-track {
            background: #1e293b;
        }
        .sidebar-nav::-webkit-scrollbar-thumb {
            background: #475569;
            border-radius: 2px;
        }
        
        .sidebar-footer {
            position: sticky;
            bottom: 0;
            background: #0f172a;
            z-index: 10;
        }
        
        .main-wrapper {
            margin-left: 0;
            transition: margin-left 0.3s ease;
        }
        @media (min-width: 1024px) {
            .main-wrapper {
                margin-left: 280px;
            }
        }
        
        .kpi-card {
            transition: all 0.2s ease;
        }
        .kpi-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 30px rgba(0,0,0,0.1);
        }
        .dark .kpi-card {
            background: #1e293b;
            border-color: #334155;
        }
        .dark .kpi-card:hover {
            box-shadow: 0 8px 30px rgba(0,0,0,0.3);
        }
        
        .tenant-card {
            transition: all 0.2s ease;
        }
        .tenant-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 30px rgba(0,0,0,0.1);
        }
        .dark .tenant-card {
            background: #1e293b;
            border-color: #334155;
        }
        .dark .tenant-card:hover {
            box-shadow: 0 8px 30px rgba(0,0,0,0.3);
        }
        
        .status-active { background: #d1fae5; color: #047857; }
        .status-expired { background: #fee2e2; color: #b91c1c; }
        .status-inactive { background: #f3f4f6; color: #6b7280; }
        
        .plan-badge {
            display: inline-flex;
            padding: 4px 12px;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
        }
        .plan-enterprise { background: #f3e8ff; color: #7c3aed; }
        .plan-professional { background: #dbeafe; color: #1d4ed8; }
        .plan-basic { background: #d1fae5; color: #047857; }
        .plan-trial { background: #fef3c7; color: #b45309; }
        
        .notif-badge { animation: pulse 2s infinite; }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 antialiased dark:bg-slate-900 dark:text-slate-100">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <!-- Main Content -->
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                    <div>
                        <h1 class="text-2xl font-bold text-slate-800 dark:text-slate-100">Quản Lý Tenant</h1>
                        <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">Quản lý các tenant trong hệ thống</p>
                    </div>
                    <div class="flex items-center gap-3">
                        <select id="filterStatus" onchange="filterByStatus()" class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm">
                            <option value="all" <%= "all".equals(filterParam) ? "selected" : "" %>>Tất cả</option>
                            <option value="active" <%= "active".equals(filterParam) ? "selected" : "" %>>Hoạt động</option>
                            <option value="expired" <%= "expired".equals(filterParam) ? "selected" : "" %>>Hết hạn</option>
                            <option value="trial" <%= "trial".equals(filterParam) ? "selected" : "" %>>Trial</option>
                        </select>
                    </div>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 dark:bg-emerald-900/30 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 dark:bg-red-900/30 dark:border-red-800 text-red-700 dark:text-red-300 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <!-- Stats Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                    <div class="kpi-card rounded-2xl bg-white dark:bg-slate-800 p-5 shadow-sm border-t-4 border-emerald-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">Đang Hoạt Động</p>
                                <p class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-400"><%= countActive %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Tenant active</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl bg-white dark:bg-slate-800 p-5 shadow-sm border-t-4 border-red-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">Đã Hết Hạn</p>
                                <p class="mt-2 text-3xl font-bold text-red-600 dark:text-red-400"><%= countExpired %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Cần gia hạn</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-red-50 dark:bg-red-900/30 text-red-600 dark:text-red-400">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                </svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl bg-white dark:bg-slate-800 p-5 shadow-sm border-t-4 border-amber-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">Đang Trial</p>
                                <p class="mt-2 text-3xl font-bold text-amber-600 dark:text-amber-400"><%= countTrial %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Chưa mua gói</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-50 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                                </svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl bg-white dark:bg-slate-800 p-5 shadow-sm border-t-4 border-blue-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">Tổng Tenant</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= tenants.size() %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Tất cả tenant</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>
                                </svg>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Tenants Grid -->
                <div class="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
                    <% if (tenants.isEmpty()) { %>
                    <div class="col-span-full bg-white dark:bg-slate-800 rounded-2xl p-12 shadow-sm text-center border border-slate-200 dark:border-slate-700">
                        <svg class="w-16 h-16 mx-auto mb-4 text-slate-300 dark:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
                        </svg>
                        <h3 class="text-lg font-semibold text-slate-700 dark:text-slate-200 mb-2">Chưa có tenant nào</h3>
                        <p class="text-slate-500 dark:text-slate-400">Tạo tenant mới để bắt đầu sử dụng hệ thống</p>
                    </div>
                    <% } else { %>
                        <% for (TenantDTO t : tenants) { %>
                            <% 
                                String planClass = "";
                                if ("enterprise".equalsIgnoreCase(t.getSubscriptionPlan())) planClass = "plan-enterprise";
                                else if ("professional".equalsIgnoreCase(t.getSubscriptionPlan())) planClass = "plan-professional";
                                else if ("basic".equalsIgnoreCase(t.getSubscriptionPlan())) planClass = "plan-basic";
                                else if ("trial".equalsIgnoreCase(t.getSubscriptionPlan())) planClass = "plan-trial";
                                else planClass = "bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300";
                                
                                String statusClass = "";
                                String statusText = "";
                                if (t.isExpired()) {
                                    statusClass = "status-expired dark:bg-red-900/30 dark:text-red-400";
                                    statusText = "Đã hết hạn";
                                } else if (t.isActive()) {
                                    statusClass = "status-active dark:bg-emerald-900/30 dark:text-emerald-400";
                                    statusText = "Hoạt động";
                                } else {
                                    statusClass = "status-inactive dark:bg-slate-700 dark:text-slate-400";
                                    statusText = "Không hoạt động";
                                }
                            %>
                            <div class="tenant-card bg-white dark:bg-slate-800 rounded-2xl shadow-sm overflow-hidden border border-slate-200 dark:border-slate-700">
                                <!-- Header -->
                                <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-5">
                                    <div class="flex items-start justify-between">
                                        <div>
                                            <h3 class="text-white font-semibold text-lg"><%= t.getTenantName() != null ? t.getTenantName() : "Tenant" %></h3>
                                            <p class="text-teal-100 text-sm mt-1"><%= t.getTenantCode() != null ? t.getTenantCode() : "" %></p>
                                        </div>
                                        <span class="plan-badge <%= planClass %>"><%= t.getSubscriptionPlan() != null ? t.getSubscriptionPlan() : "N/A" %></span>
                                    </div>
                                </div>
                                
                                <!-- Content -->
                                <div class="p-5 space-y-4">
                                    <!-- Status -->
                                    <div class="flex items-center justify-between">
                                        <span class="text-sm text-slate-500 dark:text-slate-400">Trạng thái</span>
                                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold <%= statusClass %>">
                                            <% if (!t.isExpired() && t.isActive()) { %>
                                            <span class="w-1.5 h-1.5 rounded-full bg-current"></span>
                                            <% } %>
                                            <%= statusText %>
                                        </span>
                                    </div>
                                    
                                    <!-- Contact -->
                                    <div class="space-y-2">
                                        <div class="flex items-center gap-2 text-sm">
                                            <svg class="w-4 h-4 text-slate-400 dark:text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                                            </svg>
                                            <span class="text-slate-600 dark:text-slate-300 truncate"><%= t.getContactEmail() != null ? t.getContactEmail() : "Chưa có" %></span>
                                        </div>
                                        <div class="flex items-center gap-2 text-sm">
                                            <svg class="w-4 h-4 text-slate-400 dark:text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                            </svg>
                                            <span class="text-slate-600 dark:text-slate-300"><%= t.getContactPhone() != null ? t.getContactPhone() : "Chưa có" %></span>
                                        </div>
                                    </div>
                                    
                                    <!-- Expiration -->
                                    <div class="pt-3 border-t border-slate-100 dark:border-slate-700">
                                        <div class="flex items-center justify-between text-sm">
                                            <span class="text-slate-500 dark:text-slate-400">Hết hạn</span>
                                            <span class="<%= t.isExpired() ? "text-red-600 dark:text-red-400 font-semibold" : "text-slate-700 dark:text-slate-200" %>">
                                                <%= t.getExpirationDate() != null ? sdf.format(t.getExpirationDate()) : "Không giới hạn" %>
                                            </span>
                                        </div>
                                    </div>
                                    
                                    <!-- Actions -->
                                    <div class="flex gap-2 pt-3 border-t border-slate-100 dark:border-slate-700">
                                        <a href="TenantController?action=view&id=<%= t.getTenantId() %>" class="flex-1 px-3 py-2 rounded-lg bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 text-sm font-medium text-center hover:bg-slate-200 dark:hover:bg-slate-600 transition-colors">
                                            Chi tiết
                                        </a>
                                        <% if (t.isExpired()) { %>
                                        <a href="TenantController?action=renew&id=<%= t.getTenantId() %>" class="flex-1 px-3 py-2 rounded-lg bg-teal-600 text-white text-sm font-medium text-center hover:bg-teal-700 transition-colors">
                                            Gia hạn
                                        </a>
                                        <% } else { %>
                                        <a href="TenantController?action=edit&id=<%= t.getTenantId() %>" class="flex-1 px-3 py-2 rounded-lg bg-teal-600 text-white text-sm font-medium text-center hover:bg-teal-700 transition-colors">
                                            Chỉnh sửa
                                        </a>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        <% } %>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <script>
        function filterByStatus() {
            var filter = document.getElementById('filterStatus').value;
            window.location.href = 'TenantController?action=list' + (filter !== 'all' ? '&filter=' + filter : '');
        }
    </script>
</body>
</html>
