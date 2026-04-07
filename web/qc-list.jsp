<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.QcInspectionDTO, pms.model.WorkOrderDTO, pms.model.UserDTO, java.text.SimpleDateFormat, java.text.DecimalFormat"%>
<%
    List<QcInspectionDTO> inspections = (List<QcInspectionDTO>) request.getAttribute("inspections");
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("workOrders");
    UserDTO user = (UserDTO) session.getAttribute("user");
    
    String msg = request.getAttribute("msg") != null ? (String) request.getAttribute("msg") : request.getParameter("msg");
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    String mode = (String) request.getAttribute("mode");
    
    if (inspections == null) inspections = new java.util.ArrayList<>();
    if (workOrders == null) workOrders = new java.util.ArrayList<>();
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    DecimalFormat df = new DecimalFormat("#,###");
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    String activePage = "qc"; // Trang hiện tại cho sidebar
    String pageTitle = "Kiểm Tra Chất Lượng"; // Tiêu đề cho header
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    int totalInspected = 0;
    int totalPassed = 0;
    int totalFailed = 0;
    for (QcInspectionDTO qc : inspections) {
        totalInspected += qc.getQuantityInspected();
        totalPassed += qc.getQuantityPassed();
        totalFailed += qc.getQuantityFailed();
    }
    double passRate = totalInspected > 0 ? (double) totalPassed / totalInspected * 100 : 0;
    
    String filterStatus = request.getParameter("filter");
    if (filterStatus == null) filterStatus = "all";
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kiểm Tra Chất Lượng - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
        .status-pass { background: #d1fae5; color: #047857; }
        .status-fail { background: #fee2e2; color: #b91c1c; }
        .dark .status-pass { background: rgba(16, 185, 129, 0.14); color: #6ee7b7; }
        .dark .status-fail { background: rgba(239, 68, 68, 0.14); color: #fca5a5; }
        .filter-btn { transition: all 0.2s ease; }
        .filter-btn:hover { transform: translateY(-1px); }
        .filter-btn.active { background: #0d9488; color: white; }
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
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
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
            .main-wrapper { margin-left: 280px; }
        }
        .kpi-card { transition: all 0.2s ease; }
        .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08); }
        .dark .kpi-card:hover { box-shadow: 0 20px 45px rgba(2, 6, 23, 0.45); }
        .section-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(12px);
        }
        .dark .section-card {
            background: rgba(15,23,42,0.92);
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <!-- Main Content -->
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-6 flex flex-col gap-4 xl:flex-row xl:items-start xl:justify-between">
                    <div>
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Kiểm tra chất lượng</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Ghi nhận, theo dõi và đánh giá kết quả kiểm tra chất lượng theo từng lệnh sản xuất</p>
                    </div>
                    <button type="button" onclick="openQcModal()" class="inline-flex w-full items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700 sm:w-auto sm:self-start xl:flex-shrink-0">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Tạo kiểm tra
                    </button>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 text-emerald-700 dark:text-emerald-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-700 dark:text-red-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <!-- Stats Cards -->
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-sky-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng kiểm tra</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalInspected %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500"><%= inspections.size() %> lần kiểm tra</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-sky-50 text-sky-600 dark:bg-sky-500/10 dark:text-sky-300 text-2xl">&#128202;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Đạt (PASS)</p>
                                <p class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= totalPassed %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500"><%= String.format("%.1f", passRate) %>% tỷ lệ đạt</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-300 text-2xl">&#10004;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-rose-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Lỗi (FAIL)</p>
                                <p class="mt-2 text-3xl font-bold text-rose-600 dark:text-rose-300"><%= totalFailed %></p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Sản phẩm không đạt</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-rose-50 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300 text-2xl">&#10006;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-teal-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tỷ lệ đạt</p>
                                <p class="mt-2 text-3xl font-bold text-teal-600 dark:text-teal-300"><%= String.format("%.1f", passRate) %>%</p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Chuẩn chất lượng</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 dark:bg-teal-500/10 text-teal-600 dark:text-teal-300 text-2xl">&#9889;</div>
                        </div>
                    </div>
                </div>

                <!-- Actions Row -->
                <div class="mb-6 flex flex-col gap-4 justify-between sm:flex-row sm:items-center">
                    <div class="flex gap-2 flex-wrap">
                        <a href="QcController?action=list&filter=all" class="filter-btn px-4 py-2.5 rounded-2xl border <%= "all".equals(filterStatus) ? "active bg-teal-600 text-white border-teal-600 shadow-sm shadow-teal-500/30" : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800" %>">
                            Tất cả
                        </a>
                        <a href="QcController?action=list&filter=passed" class="filter-btn px-4 py-2.5 rounded-2xl border <%= "passed".equals(filterStatus) ? "active bg-teal-600 text-white border-teal-600 shadow-sm shadow-teal-500/30" : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800" %>">
                            &#10004; Đạt
                        </a>
                        <a href="QcController?action=list&filter=failed" class="filter-btn px-4 py-2.5 rounded-2xl border <%= "failed".equals(filterStatus) ? "active bg-teal-600 text-white border-teal-600 shadow-sm shadow-teal-500/30" : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800" %>">
                            &#10006; Lỗi
                        </a>
                    </div>
                </div>

                <!-- Inspections Table -->
                <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">ID</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Lệnh SX</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Ngày kiểm tra</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Kết quả</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Số lượng KT</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Đạt</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Lỗi</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Ghi chú</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% 
                                List<QcInspectionDTO> filteredList = inspections;
                                if ("passed".equals(filterStatus)) {
                                    filteredList = new java.util.ArrayList<>();
                                    for (QcInspectionDTO qc : inspections) {
                                        if ("PASS".equals(qc.getInspectionResult())) filteredList.add(qc);
                                    }
                                } else if ("failed".equals(filterStatus)) {
                                    filteredList = new java.util.ArrayList<>();
                                    for (QcInspectionDTO qc : inspections) {
                                        if ("FAIL".equals(qc.getInspectionResult())) filteredList.add(qc);
                                    }
                                }
                                
                                if (filteredList.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" class="px-4 py-14 text-center text-slate-400 dark:text-slate-500">
                                        <div class="flex flex-col items-center gap-4">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="font-medium text-slate-700 dark:text-slate-200">Chưa có kết quả kiểm tra nào</p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo phiếu kiểm tra đầu tiên để bắt đầu theo dõi chất lượng</p>
                                            </div>
                                            <button type="button" onclick="openQcModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                </svg>
                                                Tạo kiểm tra
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { 
                                    for (QcInspectionDTO qc : filteredList) {
                                        String resultClass = "PASS".equals(qc.getInspectionResult()) ? "status-pass" : "status-fail";
                                        String resultLabel = "PASS".equals(qc.getInspectionResult()) ? "Đạt" : "Lỗi";
                                %>
                                <tr class="border-b border-slate-50 last:border-0 hover:bg-slate-50 transition-colors">
                                    <td class="px-4 py-3 text-sm font-semibold text-slate-700">#<%= qc.getInspectionId() %></td>
                                    <td class="px-4 py-3 text-sm text-slate-600">
                                        <a href="MainController?action=listWorkOrder" class="text-teal-600 hover:text-teal-800 font-semibold">WO-<%= qc.getWoId() %></a>
                                    </td>
                                    <td class="px-4 py-3 text-sm text-slate-600">
                                        <%= qc.getInspectionDate() != null ? sdf.format(qc.getInspectionDate()) : "-" %>
                                    </td>
                                    <td class="px-4 py-3">
                                        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold <%= resultClass %>">
                                            <%= resultLabel %>
                                        </span>
                                    </td>
                                    <td class="px-4 py-3 text-sm text-right font-semibold text-slate-700"><%= qc.getQuantityInspected() %></td>
                                    <td class="px-4 py-3 text-sm text-right text-emerald-600 font-semibold"><%= qc.getQuantityPassed() %></td>
                                    <td class="px-4 py-3 text-sm text-right <%= qc.getQuantityFailed() > 0 ? "text-red-600" : "text-slate-400" %> font-semibold"><%= qc.getQuantityFailed() %></td>
                                    <td class="px-4 py-3 text-sm text-slate-500 max-w-[200px] truncate"><%= qc.getNotes() != null ? qc.getNotes() : "-" %></td>
                                </tr>
                                <% }} %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>

    <jsp:include page="mobile-nav.jsp" />

    <div id="qcModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card max-h-[90vh] w-full max-w-4xl overflow-y-auto rounded-3xl border border-slate-200 shadow-2xl dark:border-slate-700">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 bg-gradient-to-r from-teal-500 to-teal-600 px-6 py-5 text-white dark:border-slate-700">
                <div>
                    <h3 class="text-lg font-semibold">Tạo kiểm tra chất lượng</h3>
                    <p class="mt-1 text-sm text-teal-50">Nhập thông tin kiểm tra và ghi nhận kết quả ngay tại đây</p>
                </div>
                <button type="button" onclick="closeQcModal()" class="rounded-xl p-2 text-white/80 transition hover:bg-white/10 hover:text-white">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="QcController" method="post" class="space-y-6 p-6 bg-white/90 dark:bg-slate-900/60">
                <input type="hidden" name="action" value="saveAdd">

                <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Lệnh sản xuất <span class="text-red-500">*</span></label>
                        <select name="woId" id="qcWoId" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 transition-all focus:border-teal-500 focus:outline-none focus:ring-4 focus:ring-teal-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100" onchange="updateQcQuantity()">
                            <option value="">-- Chọn lệnh sản xuất --</option>
                            <% for (WorkOrderDTO wo : workOrders) {
                                if (!"Completed".equalsIgnoreCase(wo.getStatus()) && !"Cancelled".equalsIgnoreCase(wo.getStatus())) {
                            %>
                            <option value="<%= wo.getWo_id() %>" data-quantity="<%= wo.getOrder_quantity() %>">
                                WO-<%= wo.getWo_id() %> | <%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %> | SL: <%= wo.getOrder_quantity() %>
                            </option>
                            <% }} %>
                        </select>
                    </div>

                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Công đoạn <span class="text-red-500">*</span></label>
                        <select name="stepId" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 transition-all focus:border-teal-500 focus:outline-none focus:ring-4 focus:ring-teal-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100">
                            <option value="">-- Chọn công đoạn --</option>
                            <% List<pms.model.RoutingStepDTO> steps = (List<pms.model.RoutingStepDTO>) request.getAttribute("steps");
                               if (steps != null) {
                                   for (pms.model.RoutingStepDTO s : steps) { %>
                            <option value="<%= s.getStepId() %>"><%= s.getStepName() %> (<%= s.getEstimatedTime() %> phút)</option>
                            <%     }
                               } %>
                        </select>
                    </div>
                </div>

                <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Tổng số lượng kiểm tra <span class="text-red-500">*</span></label>
                        <input type="number" name="quantityInspected" id="qcQuantityInspected" value="0" min="1" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 transition-all focus:border-teal-500 focus:outline-none focus:ring-4 focus:ring-teal-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100" oninput="calculateQcResults()">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng đạt (PASS) <span class="text-red-500">*</span></label>
                        <input type="number" name="quantityPassed" id="qcQuantityPassed" value="0" min="0" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 transition-all focus:border-teal-500 focus:outline-none focus:ring-4 focus:ring-teal-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100" oninput="calculateQcResults()">
                        <p id="qcPassRate" class="mt-1 text-xs font-medium text-emerald-600 dark:text-emerald-300"></p>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng lỗi (FAIL)</label>
                        <input type="number" name="quantityFailed" id="qcQuantityFailed" value="0" min="0" readonly class="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-slate-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
                        <p id="qcFailRate" class="mt-1 text-xs font-medium text-rose-600 dark:text-rose-300"></p>
                    </div>
                </div>

                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Kết quả kiểm tra <span class="text-red-500">*</span></label>
                    <div class="flex flex-col gap-3 sm:flex-row">
                        <label id="qcPassLabel" class="flex cursor-pointer items-center gap-3 rounded-2xl border-2 border-slate-200 px-5 py-3 transition-all hover:border-emerald-300 dark:border-slate-700">
                            <input type="radio" name="inspectionResult" value="PASS" required class="h-5 w-5 text-emerald-600" onchange="toggleQcResult()">
                            <span class="flex items-center gap-2 font-semibold text-emerald-700 dark:text-emerald-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                                Đạt (PASS)
                            </span>
                        </label>
                        <label id="qcFailLabel" class="flex cursor-pointer items-center gap-3 rounded-2xl border-2 border-slate-200 px-5 py-3 transition-all hover:border-rose-300 dark:border-slate-700">
                            <input type="radio" name="inspectionResult" value="FAIL" class="h-5 w-5 text-rose-600" onchange="toggleQcResult()">
                            <span class="flex items-center gap-2 font-semibold text-rose-700 dark:text-rose-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                                Lỗi (FAIL)
                            </span>
                        </label>
                    </div>
                </div>

                <div id="qcDefectSection" class="hidden">
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Lý do lỗi</label>
                    <select name="defectId" class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 transition-all focus:border-teal-500 focus:outline-none focus:ring-4 focus:ring-teal-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100">
                        <option value="0">-- Không có lỗi cụ thể --</option>
                        <% List<pms.model.DefectDTO> defects = (List<pms.model.DefectDTO>) request.getAttribute("defects");
                           if (defects != null) {
                               for (pms.model.DefectDTO d : defects) { %>
                        <option value="<%= d.getDefectId() %>"><%= d.getReasonName() %></option>
                        <%     }
                           } %>
                    </select>
                </div>

                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Ghi chú</label>
                    <textarea name="notes" rows="3" placeholder="Nhập ghi chú nếu có..." class="w-full resize-none rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 transition-all focus:border-teal-500 focus:outline-none focus:ring-4 focus:ring-teal-500/10 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"></textarea>
                </div>

                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeQcModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Đóng</button>
                    <button type="submit" class="inline-flex items-center justify-center rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">Lưu kết quả</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openQcModal() {
            const modal = document.getElementById('qcModal');
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        }

        function closeQcModal() {
            const modal = document.getElementById('qcModal');
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }

        function calculateQcResults() {
            const total = parseInt(document.getElementById('qcQuantityInspected').value) || 0;
            const passed = parseInt(document.getElementById('qcQuantityPassed').value) || 0;
            const failed = Math.max(0, total - passed);
            document.getElementById('qcQuantityFailed').value = failed;
            document.getElementById('qcPassRate').textContent = total > 0 ? (((passed / total) * 100).toFixed(1) + '% đạt') : '';
            document.getElementById('qcFailRate').textContent = total > 0 ? (((failed / total) * 100).toFixed(1) + '% lỗi') : '';
        }

        function toggleQcResult() {
            const passRadio = document.querySelector('input[name="inspectionResult"][value="PASS"]');
            const failRadio = document.querySelector('input[name="inspectionResult"][value="FAIL"]');
            const passLabel = document.getElementById('qcPassLabel');
            const failLabel = document.getElementById('qcFailLabel');
            const defectSection = document.getElementById('qcDefectSection');

            if (passRadio.checked) {
                passLabel.classList.add('border-emerald-500', 'bg-emerald-50', 'dark:bg-emerald-500/10');
                passLabel.classList.remove('border-slate-200', 'dark:border-slate-700');
                failLabel.classList.remove('border-rose-500', 'bg-rose-50', 'dark:bg-rose-500/10');
                failLabel.classList.add('border-slate-200', 'dark:border-slate-700');
                defectSection.classList.add('hidden');
            } else if (failRadio.checked) {
                failLabel.classList.add('border-rose-500', 'bg-rose-50', 'dark:bg-rose-500/10');
                failLabel.classList.remove('border-slate-200', 'dark:border-slate-700');
                passLabel.classList.remove('border-emerald-500', 'bg-emerald-50', 'dark:bg-emerald-500/10');
                passLabel.classList.add('border-slate-200', 'dark:border-slate-700');
                defectSection.classList.remove('hidden');
            }
        }

        function updateQcQuantity() {
            const woSelect = document.getElementById('qcWoId');
            const selectedOption = woSelect.options[woSelect.selectedIndex];
            const quantity = selectedOption.getAttribute('data-quantity');
            if (quantity) {
                document.getElementById('qcQuantityInspected').value = quantity;
                calculateQcResults();
            }
        }

        document.getElementById('qcModal').addEventListener('click', function (e) {
            if (e.target === this) {
                closeQcModal();
            }
        });
    </script>
</body>
</html>
