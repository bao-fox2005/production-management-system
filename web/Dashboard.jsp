<%@page contentType="text/html" pageEncoding="UTF-8" import="pms.model.DashboardDTO, pms.model.WorkOrderDTO, pms.model.ProductionLogDTO, pms.model.ItemDTO, pms.model.UserDTO, java.util.List, java.text.SimpleDateFormat, java.util.Date, pms.utils.NotificationService.Notification"%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");
    
    DashboardDTO data = (DashboardDTO) request.getAttribute("dashboardData");
    UserDTO user = (UserDTO) session.getAttribute("user");
    List<Notification> notifications = (List<Notification>) session.getAttribute("notifications");
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isWorker = "employee".equalsIgnoreCase(userRole)
            || "worker".equalsIgnoreCase(userRole)
            || "user".equalsIgnoreCase(userRole);
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat sdfTime = new SimpleDateFormat("HH:mm");
    if (data == null) data = new DashboardDTO();
    if (notifications == null) notifications = new java.util.ArrayList<>();
    
    int unreadCount = 0;
    for (Notification n : notifications) {
        if (!n.isRead()) unreadCount++;
    }
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    String activePage = "dashboard"; // Trang hiện tại cho sidebar
    String pageTitle = "Dashboard"; // Tiêu đề cho header
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    boolean hasData = data.getTotalWorkOrders() > 0 || data.getTotalProductionLogs() > 0 || data.getTotalBills() > 0;
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
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
        
        /* Sidebar cố định - cùng shared-sidebar */
        .sidebar-fixed {
            position: fixed;
            top: 0;
            left: 0;
            height: 100vh;
            z-index: 40;
        }
        
        /* Logo cố định trong sidebar */
        .sidebar-header {
            position: sticky;
            top: 0;
            background: #0f172a;
            z-index: 10;
        }
        
        /* Navigation scroll riêng */
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
        
        /* User section cố định */
        .sidebar-footer {
            position: sticky;
            bottom: 0;
            background: #0f172a;
            z-index: 10;
        }
        
        /* Main content area */
        .main-wrapper {
            margin-left: 0;
            transition: margin-left 0.3s ease;
        }
        @media (min-width: 1024px) {
            .main-wrapper {
                margin-left: 280px;
            }
        }
        
        /* Dark mode styles */
        .dark body { background: #0f172a; color: #e2e8f0; }
        .dark .sidebar-fixed { background: #0f172a; }
        .dark .sidebar-header { background: #0f172a; }
        .dark .sidebar-footer { background: #0f172a; }
        
        /* KPI Card */
        .kpi-card { transition: all 0.2s ease; }
        .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(0,0,0,0.1); }
        .dark .kpi-card { background: #1e293b; border-color: #334155; }
        .dark .kpi-card:hover { box-shadow: 0 8px 30px rgba(0,0,0,0.3); }
        
        /* Chart container */
        .chart-container { position: relative; height: 280px; }
        
        /* Status badges */
        .status-new { background: #dbeafe; color: #1d4ed8; }
        .status-progress { background: #fef3c7; color: #b45309; }
        .status-done { background: #d1fae5; color: #047857; }
        .status-cancelled { background: #fee2e2; color: #b91c1c; }
        
        /* Notification badge animation */
        .notif-badge { animation: pulse 2s infinite; }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        
        /* Progress bar */
        .progress-bar {
            transition: width 0.5s ease-in-out;
        }
        
        /* Search box */
        .search-box {
            background: white;
            border: 2px solid #e2e8f0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .search-box:focus-within {
            border-color: #14b8a6;
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1);
        }
        .dark .search-box {
            background: #1e293b;
            border-color: #334155;
        }
        .dark .search-box:focus-within {
            border-color: #14b8a6;
        }
        .dark .search-box input {
            color: #e2e8f0;
        }
        
        /* Dark mode được xử lý bởi Tailwind `dark:` và [`web/js/common.js`](web/js/common.js) */
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
                <!-- KPI Large Cards (3 cards) - Hàng đầu tiên -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    <!-- Lệnh Sản Xuất -->
                    <div class="kpi-card rounded-2xl bg-white p-6 shadow-sm border-t-4 border-teal-500 dark:bg-slate-800">
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <p class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">Lệnh Sản Xuất</p>
                                <p class="mt-2 text-4xl font-bold text-slate-800 dark:text-slate-100"><%= data.getTotalWorkOrders() %></p>
                                <div class="flex items-center gap-2 mt-2">
                                    <span class="text-xs text-emerald-600 font-medium flex items-center gap-1">
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
                                        <%= data.getWorkOrdersDone() %> hoàn thành
                                    </span>
                                </div>
                            </div>
                            <div class="w-14 h-14 rounded-xl bg-teal-50 flex items-center justify-center">
                                <svg class="w-7 h-7 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                            </div>
                        </div>
                        <div class="mt-4">
                            <div class="mb-1 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                                <span>Tỷ lệ hoàn thành</span>
                                <span class="font-semibold"><%= data.getCompletionRate() %>%</span>
                            </div>
                            <div class="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-700">
                                <div class="bg-teal-500 h-2 rounded-full progress-bar" style="width: <%= data.getCompletionRate() %>%"></div>
                            </div>
                        </div>
                    </div>
                    
                    <% if (isAdmin) { %>
                    <!-- Đơn Hàng -->
                    <div class="kpi-card rounded-2xl bg-white p-6 shadow-sm border-t-4 border-blue-500 dark:bg-slate-800">
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <p class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">Đơn Đặt Hàng</p>
                                <p class="mt-2 text-4xl font-bold text-slate-800 dark:text-slate-100"><%= data.getTotalPurchaseOrders() %></p>
                                <div class="flex items-center gap-2 mt-2">
                                    <span class="text-xs text-amber-600 font-medium flex items-center gap-1">
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                        <%= data.getPurchaseOrdersPending() %> chờ xử lý
                                    </span>
                                </div>
                            </div>
                            <div class="w-14 h-14 rounded-xl bg-blue-50 flex items-center justify-center">
                                <svg class="w-7 h-7 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
                            </div>
                        </div>
                        <div class="mt-4">
                            <div class="mb-1 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                                <span>Tỷ lệ hoàn thành</span>
                                <span class="font-semibold"><%= data.getTotalPurchaseOrders() > 0 ? ((data.getTotalPurchaseOrders() - data.getPurchaseOrdersPending()) * 100 / data.getTotalPurchaseOrders()) : 0 %>%</span>
                            </div>
                            <div class="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-700">
                                <div class="bg-blue-500 h-2 rounded-full progress-bar" style="width: <%= data.getTotalPurchaseOrders() > 0 ? ((data.getTotalPurchaseOrders() - data.getPurchaseOrdersPending()) * 100 / data.getTotalPurchaseOrders()) : 0 %>%"></div>
                            </div>
                        </div>
                    </div>

                    <!-- Doanh Thu -->
                    <div class="kpi-card rounded-2xl bg-white p-6 shadow-sm border-t-4 border-emerald-500 dark:bg-slate-800">
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <p class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng Thu (Tháng)</p>
                                <p class="text-3xl font-bold text-emerald-600 mt-2"><%= data.getFormattedRevenue() %></p>
                                <div class="flex items-center gap-2 mt-2">
                                    <span class="text-xs text-emerald-600 font-medium flex items-center gap-1">
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18"/></svg>
                                        Đơn vị: VND
                                    </span>
                                </div>
                            </div>
                            <div class="w-14 h-14 rounded-xl bg-emerald-50 flex items-center justify-center">
                                <svg class="w-7 h-7 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    <% } else { %>
                    <!-- Worker: thay KPI quản trị bằng KPI cá nhân -->
                    <div class="kpi-card rounded-2xl bg-white p-6 shadow-sm border-t-4 border-amber-500 dark:bg-slate-800">
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <p class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">Nhật Ký SX</p>
                                <p class="mt-2 text-4xl font-bold text-slate-800 dark:text-slate-100"><%= data.getTotalProductionLogs() %></p>
                                <div class="flex items-center gap-2 mt-2">
                                    <span class="text-xs text-amber-600 font-medium flex items-center gap-1">
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                        <%= data.getLogsToday() %> log hôm nay
                                    </span>
                                </div>
                            </div>
                            <div class="w-14 h-14 rounded-xl bg-amber-50 flex items-center justify-center">
                                <svg class="w-7 h-7 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>

                    <div class="kpi-card rounded-2xl bg-white p-6 shadow-sm border-t-4 border-emerald-500 dark:bg-slate-800">
                        <div class="flex items-start justify-between">
                            <div class="flex-1">
                                <p class="text-xs font-medium uppercase tracking-wide text-slate-500 dark:text-slate-400">Tỷ Lệ Hoàn Thành</p>
                                <p class="text-3xl font-bold text-emerald-600 mt-2"><%= data.getCompletionRate() %>%</p>
                                <div class="flex items-center gap-2 mt-2">
                                    <span class="text-xs text-emerald-600 font-medium flex items-center gap-1">
                                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                        Theo công việc của bạn
                                    </span>
                                </div>
                            </div>
                            <div class="w-14 h-14 rounded-xl bg-emerald-50 flex items-center justify-center">
                                <svg class="w-7 h-7 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
                
                <% if (isAdmin) { %>
                <!-- Status Cards (4 cards smaller) - Hàng thứ hai -->
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                    <!-- Lỗi -->
                    <div class="kpi-card rounded-xl bg-white p-4 shadow-sm border-t-4 border-red-400 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-medium uppercase text-slate-500 dark:text-slate-400">Lỗi Sản Phẩm</p>
                                <p class="mt-1 text-2xl font-bold text-slate-800 dark:text-slate-100"><%= data.getTotalDefects() %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Danh mục lỗi</p>
                            </div>
                            <div class="w-10 h-10 rounded-lg bg-red-50 flex items-center justify-center">
                                <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Nhật Ký -->
                    <div class="kpi-card rounded-xl bg-white p-4 shadow-sm border-t-4 border-amber-400 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-medium uppercase text-slate-500 dark:text-slate-400">Nhật Ký SX</p>
                                <p class="mt-1 text-2xl font-bold text-slate-800 dark:text-slate-100"><%= data.getTotalProductionLogs() %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500"><%= data.getLogsToday() %> log hôm nay</p>
                            </div>
                            <div class="w-10 h-10 rounded-lg bg-amber-50 flex items-center justify-center">
                                <svg class="w-5 h-5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Hoàn Thành -->
                    <div class="kpi-card rounded-xl bg-white p-4 shadow-sm border-t-4 border-emerald-400 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-medium text-slate-500 uppercase">Tỷ Lệ HT</p>
                                <p class="text-2xl font-bold text-emerald-600 mt-1"><%= data.getCompletionRate() %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Tổng số lệnh SX</p>
                            </div>
                            <div class="w-10 h-10 rounded-lg bg-emerald-50 flex items-center justify-center">
                                <svg class="w-5 h-5 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Hóa Đơn -->
                    <div class="kpi-card rounded-xl bg-white p-4 shadow-sm border-t-4 border-purple-400 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-medium uppercase text-slate-500 dark:text-slate-400">Hóa Đơn</p>
                                <p class="mt-1 text-2xl font-bold text-slate-800 dark:text-slate-100"><%= data.getTotalBills() %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Tổng số hóa đơn</p>
                            </div>
                            <div class="w-10 h-10 rounded-lg bg-purple-50 flex items-center justify-center">
                                <svg class="w-5 h-5 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Charts Row - Biểu đồ lớn -->
                <div class="grid lg:grid-cols-3 gap-6 mb-6">
                    <!-- Revenue Chart -->
                    <div class="lg:col-span-2 rounded-2xl bg-white p-6 shadow-sm dark:bg-slate-800">
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-base font-semibold text-slate-800 dark:text-slate-100">Biểu Đồ Doanh Thu Theo Tháng</h3>
                            <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600 dark:bg-slate-700 dark:text-slate-300"><%= new java.text.SimpleDateFormat("yyyy").format(new Date()) %></span>
                        </div>
                        <div class="chart-container">
                            <canvas id="revenueChart"></canvas>
                        </div>
                    </div>
                    
                    <!-- WO Status Chart -->
                    <div class="rounded-2xl bg-white p-6 shadow-sm dark:bg-slate-800">
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-base font-semibold text-slate-800 dark:text-slate-100">Phân Bổ Trạng Thái WO</h3>
                        </div>
                        <div class="chart-container">
                            <canvas id="woStatusChart"></canvas>
                        </div>
                    </div>
                </div>
                
                <!-- Quick Actions - Phần phụ -->
                <div class="rounded-2xl bg-white p-6 shadow-sm dark:bg-slate-800">
                    <h3 class="mb-4 text-base font-semibold text-slate-800 dark:text-slate-100">Thao Tác Nhanh</h3>
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <a href="MainController?action=addWorkOrder" class="flex flex-col items-center gap-2 rounded-xl border border-slate-200 p-4 transition-all hover:border-teal-300 hover:bg-teal-50 dark:border-slate-700 dark:hover:bg-slate-700/70">
                            <div class="w-12 h-12 rounded-xl bg-teal-100 flex items-center justify-center">
                                <svg class="w-6 h-6 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                            </div>
                            <span class="text-sm font-medium text-slate-700 dark:text-slate-200">Tạo Lệnh SX</span>
                        </a>
                        <a href="MainController?action=listProduction" class="flex flex-col items-center gap-2 rounded-xl border border-slate-200 p-4 transition-all hover:border-amber-300 hover:bg-amber-50 dark:border-slate-700 dark:hover:bg-slate-700/70">
                            <div class="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center">
                                <svg class="w-6 h-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                            <span class="text-sm font-medium text-slate-700 dark:text-slate-200">Nhật Ký SX</span>
                        </a>
                        <a href="MainController?action=listBill" class="flex flex-col items-center gap-2 rounded-xl border border-slate-200 p-4 transition-all hover:border-purple-300 hover:bg-purple-50 dark:border-slate-700 dark:hover:bg-slate-700/70">
                            <div class="w-12 h-12 rounded-xl bg-purple-100 flex items-center justify-center">
                                <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                            </div>
                            <span class="text-sm font-medium text-slate-700 dark:text-slate-200">Tạo Hóa Đơn</span>
                        </a>
                        <a href="SearchPurchaseOrder.jsp" class="flex flex-col items-center gap-2 rounded-xl border border-slate-200 p-4 transition-all hover:border-blue-300 hover:bg-blue-50 dark:border-slate-700 dark:hover:bg-slate-700/70">
                            <div class="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center">
                                <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
                            </div>
                            <span class="text-sm font-medium text-slate-700 dark:text-slate-200">Đơn Đặt Hàng</span>
                        </a>
                    </div>
                </div>
                <% } else { %>
                <!-- Worker summary -->
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                    <div class="rounded-2xl bg-white p-6 shadow-sm dark:bg-slate-800">
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-base font-semibold text-slate-800 dark:text-slate-100">Công việc gần đây</h3>
                            <span class="rounded-full bg-teal-50 px-3 py-1 text-xs font-semibold text-teal-700"><%= data.getRecentWorkOrders() != null ? data.getRecentWorkOrders().size() : 0 %> việc</span>
                        </div>
                        <% if (data.getRecentWorkOrders() != null && !data.getRecentWorkOrders().isEmpty()) { %>
                            <div class="space-y-3">
                                <% for (WorkOrderDTO workOrder : data.getRecentWorkOrders()) { %>
                                <div class="rounded-xl border border-slate-200 p-4 dark:border-slate-700">
                                    <div class="flex items-center justify-between gap-3">
                                        <div>
                                            <p class="font-semibold text-slate-800 dark:text-slate-100"><%= workOrder.getProductName() != null ? workOrder.getProductName() : "Lệnh sản xuất #" + workOrder.getWo_id() %></p>
                                            <p class="text-xs text-slate-500 dark:text-slate-400">Mã WO: <%= workOrder.getWo_id() %></p>
                                        </div>
                                        <span class="rounded-full px-2.5 py-1 text-xs font-semibold <%= "Done".equalsIgnoreCase(workOrder.getStatus()) ? "status-done" : ("InProgress".equalsIgnoreCase(workOrder.getStatus()) ? "status-progress" : "status-new") %>"><%= workOrder.getStatusLabel() %></span>
                                    </div>
                                </div>
                                <% } %>
                            </div>
                        <% } else { %>
                            <p class="text-sm text-slate-500 dark:text-slate-400">Chưa có công việc nào được giao.</p>
                        <% } %>
                    </div>

                    <div class="rounded-2xl bg-white p-6 shadow-sm dark:bg-slate-800">
                        <div class="flex items-center justify-between mb-4">
                            <h3 class="text-base font-semibold text-slate-800 dark:text-slate-100">Nhật ký gần đây</h3>
                            <span class="rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700"><%= data.getRecentLogs() != null ? data.getRecentLogs().size() : 0 %> log</span>
                        </div>
                        <% if (data.getRecentLogs() != null && !data.getRecentLogs().isEmpty()) { %>
                            <div class="space-y-3">
                                <% for (ProductionLogDTO log : data.getRecentLogs()) { %>
                                <div class="rounded-xl border border-slate-200 p-4 dark:border-slate-700">
                                    <p class="font-semibold text-slate-800 dark:text-slate-100"><%= log.getStepName() != null ? log.getStepName() : "Đã ghi nhận" %></p>
                                    <p class="text-xs text-slate-500 dark:text-slate-400">WO: <%= log.getWoId() %> • Số lượng: <%= log.getProducedQuantity() %></p>
                                </div>
                                <% } %>
                            </div>
                        <% } else { %>
                            <p class="text-sm text-slate-500 dark:text-slate-400">Hôm nay chưa có nhật ký sản xuất nào.</p>
                        <% } %>
                    </div>
                </div>

                <div class="rounded-2xl bg-white p-6 shadow-sm dark:bg-slate-800">
                    <h3 class="mb-4 text-base font-semibold text-slate-800 dark:text-slate-100">Thao tác nhanh</h3>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <a href="MainController?action=listProduction" class="flex items-center gap-3 rounded-xl border border-slate-200 p-4 transition-all hover:border-amber-300 hover:bg-amber-50 dark:border-slate-700 dark:hover:bg-slate-700/70">
                            <div class="w-12 h-12 rounded-xl bg-amber-100 flex items-center justify-center">
                                <svg class="w-6 h-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                            <div>
                                <p class="font-medium text-slate-700 dark:text-slate-200">Xem nhật ký sản xuất</p>
                                <p class="text-xs text-slate-500 dark:text-slate-400">Theo dõi việc được giao và tiến độ cá nhân</p>
                            </div>
                        </a>
                        <a href="MainController?action=listWorkOrder" class="flex items-center gap-3 rounded-xl border border-slate-200 p-4 transition-all hover:border-teal-300 hover:bg-teal-50 dark:border-slate-700 dark:hover:bg-slate-700/70">
                            <div class="w-12 h-12 rounded-xl bg-teal-100 flex items-center justify-center">
                                <svg class="w-6 h-6 text-teal-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                            </div>
                            <div>
                                <p class="font-medium text-slate-700 dark:text-slate-200">Xem lệnh sản xuất</p>
                                <p class="text-xs text-slate-500 dark:text-slate-400">Chỉ hiển thị danh sách công việc liên quan</p>
                            </div>
                        </a>
                    </div>
                </div>
                <% } %>
            </main>
        </div>
    </div>

    <script>
        <% if (hasData && isAdmin) { %>
        const revenueCanvas = document.getElementById('revenueChart');
        const statusCanvas = document.getElementById('woStatusChart');

        if (revenueCanvas) {
            const monthLabels = ['T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12'];
            const revenueData = new Array(12).fill(0);
            <% if (data.getMonthlyRevenue() != null) {
                for (double[] row : data.getMonthlyRevenue()) { %>
                    revenueData[Math.floor(<%= row[0] %>) - 1] = <%= (long) row[1] %>;
            <% } } %>

            new Chart(revenueCanvas.getContext('2d'), {
                type: 'bar',
                data: {
                    labels: monthLabels,
                    datasets: [{
                        label: 'Doanh thu (VND)',
                        data: revenueData,
                        backgroundColor: 'rgba(20, 184, 166, 0.7)',
                        borderColor: 'rgba(20, 184, 166, 1)',
                        borderWidth: 1,
                        borderRadius: 6,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { callback: function(value) {
                                if (value >= 1000000) return (value/1000000).toFixed(1) + 'M';
                                if (value >= 1000) return (value/1000).toFixed(0) + 'K';
                                return value;
                            }}
                        }
                    }
                }
            });
        }

        if (statusCanvas) {
            new Chart(statusCanvas.getContext('2d'), {
                type: 'doughnut',
                data: {
                    labels: ['Mới', 'Đang SX', 'Hoàn Thành', 'Đã Hủy'],
                    datasets: [{
                        data: [<%= data.getWorkOrdersNew() %>, <%= data.getWorkOrdersInProgress() %>, <%= data.getWorkOrdersDone() %>, <%= data.getWorkOrdersCancelled() %>],
                        backgroundColor: ['#3b82f6', '#f59e0b', '#10b981', '#ef4444'],
                        borderWidth: 0,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { position: 'bottom', labels: { padding: 16, font: { size: 12 } } } },
                    cutout: '60%',
                }
            });
        }
        <% } %>
    </script>
</body>
</html>
