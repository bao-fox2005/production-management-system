<%--
  ===== productionlog.jsp – Nhật Ký Sản Xuất =====
  Mục đích    : Hiển thị lịch sử báo cáo sản lượng từ công nhân (ProductionLog).
                Tích hợp modal "Tạo báo cáo" cho phép công nhân nhập số lượng đạt/lỗi.
  Request attributes nhận từ MainController (action=listProduction):
    - "listLogs"    (List<ProductionLogDTO>) : Tất cả bản ghi nhật ký sản xuất
    - "listWO"      (List<WorkOrderDTO>)     : Danh sách Work Order chưa hoàn thành (dropdown chọn lệnh)
    - "listSteps"   (List<RoutingStepDTO>)   : Tất cả công đoạn (dropdown chọn công đoạn)
    - "listDefects" (List<DefectDTO>)        : Danh mục lý do lỗi (dropdown chọn nguyên nhân)
    - "msg"         (String)                 : Flash thông báo thành công
    - "error"       (String)                 : Thông báo lỗi
  Session attributes đọc:
    - session["user"]     (UserDTO) : Thông tin người dùng đang đăng nhập
    - session["darkMode"] (Boolean) : Dark mode
    - session["lang"]     (String)  : Ngôn ngữ
  KPI stats tính tại runtime:
    - totalLogs  : Tổng số bản ghi nhật ký
    - totalOK    : Tổng sản phẩm đạt (sum of quantity_done)
    - totalNG    : Tổng sản phẩm lỗi (sum of quantity_defective)
    - countActiveWO: Lệnh đang sản xuất (status != "Completed")
  Modal (logModal):
    - openLogModal() / closeLogModal() : Hiển thị/ẩn modal tạo báo cáo
    - Đóng modal khi click vào backdrop
  Form submit log: POST → MainController?action=addLog
    Input: workOrderId, stepId, quantityDone, quantityDefective, defectId
  Phân quyền  : Tất cả người dùng đăng nhập (công nhân chủ yếu sử dụng chức năng này).
--%>
<%@page import="pms.model.ProductionLogDTO"%>
<%@page import="pms.model.WorkOrderDTO"%>
<%@page import="pms.model.RoutingStepDTO"%>
<%@page import="pms.model.DefectDTO"%>
<%@page import="pms.model.UserDTO"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<ProductionLogDTO> listLogs = (List<ProductionLogDTO>) request.getAttribute("listLogs");
    List<WorkOrderDTO> listWO = (List<WorkOrderDTO>) request.getAttribute("listWO");
    List<WorkOrderDTO> activeWOs = (List<WorkOrderDTO>) request.getAttribute("activeWOs");
    Map<Integer, Integer> woProgressMap = (Map<Integer, Integer>) request.getAttribute("woProgressMap");
    List<RoutingStepDTO> listSteps = (List<RoutingStepDTO>) request.getAttribute("listSteps");
    List<DefectDTO> listDefects = (List<DefectDTO>) request.getAttribute("listDefects");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    
    if (listLogs == null) listLogs = new java.util.ArrayList<>();
    if (listWO == null) listWO = new java.util.ArrayList<>();
    if (activeWOs == null) activeWOs = new java.util.ArrayList<>();
    if (woProgressMap == null) woProgressMap = new java.util.HashMap<>();
    if (listSteps == null) listSteps = new java.util.ArrayList<>();
    if (listDefects == null) listDefects = new java.util.ArrayList<>();
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isWorker = "employee".equalsIgnoreCase(userRole)
            || "worker".equalsIgnoreCase(userRole)
            || "user".equalsIgnoreCase(userRole);
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    String activePage = "productionlog"; // Trang hiện tại cho sidebar
    String pageTitle = "Nhật Ký Sản Xuất"; // Tiêu đề cho header
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    // Stats
    int totalLogs = listLogs.size();
    int totalOK = 0, totalNG = 0;
    for (ProductionLogDTO log : listLogs) {
        totalOK += log.getQuantityDone();
        totalNG += log.getQuantityDefective();
    }
    int countActiveWO = 0;
    for (WorkOrderDTO wo : listWO) {
        if (!"Completed".equalsIgnoreCase(wo.getStatus())) countActiveWO++;
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nhật Ký Sản Xuất - PMS</title>
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
        .form-input {
            background: #ffffff;
            border-color: #e2e8f0;
            color: #0f172a;
            transition: all 0.2s ease;
        }
        .form-input:focus {
            border-color: #0d9488;
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1);
        }
        .dark .form-input {
            background: #0f172a;
            border-color: #334155;
            color: #e2e8f0;
        }
        .dark .form-input::placeholder {
            color: #64748b;
        }
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
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Nhật ký sản xuất</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Ghi nhận sản lượng hoàn thành, lỗi phát sinh và theo dõi tiến độ thực tế theo từng công đoạn</p>
                    </div>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 text-emerald-700 dark:text-emerald-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-700 dark:text-red-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <!-- Stats Cards -->
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-teal-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng bản ghi</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalLogs %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 text-teal-600 dark:bg-teal-500/10 dark:text-teal-300 text-2xl">&#128221;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Sản phẩm đạt (OK)</p>
                                <p class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= totalOK %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-300 text-2xl">&#10004;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-rose-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Sản phẩm lỗi (NG)</p>
                                <p class="mt-2 text-3xl font-bold text-red-600 dark:text-red-300"><%= totalNG %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-rose-50 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300 text-2xl">&#10006;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-sky-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Lệnh đang sản xuất</p>
                                <p class="mt-2 text-3xl font-bold text-blue-600 dark:text-blue-300"><%= countActiveWO %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-sky-50 text-sky-600 dark:bg-sky-500/10 dark:text-sky-300 text-2xl">&#128203;</div>
                        </div>
                    </div>
                </div>

                <!-- Đang Sản Xuất (In Progress) -->
                <div class="mb-6 section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                    <div class="p-4 border-b border-slate-100 dark:border-slate-700">
                        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Đang sản xuất</h3>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Danh sách lệnh sản xuất đang chạy và tiến độ</p>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã LSX</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Sản phẩm</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tiến độ</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (activeWOs.isEmpty()) { %>
                                <tr>
                                    <td colspan="4" class="px-4 py-8 text-center text-slate-400">Chưa có lệnh nào đang sản xuất.</td>
                                </tr>
                            <% } else { %>
                                <% for (WorkOrderDTO wo : activeWOs) {
                                    int done = woProgressMap.getOrDefault(wo.getWo_id(), 0);
                                    int req = wo.getOrder_quantity();
                                    boolean theEnd = done >= req;
                                %>
                                <tr class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors">
                                    <td class="px-4 py-3 font-semibold text-teal-600 dark:text-teal-300">#WO-<%= wo.getWo_id() %></td>
                                    <td class="px-4 py-3 font-medium text-slate-700 dark:text-slate-300"><%= wo.getProductName() != null ? wo.getProductName() : "Sản phẩm #" + wo.getProduct_item_id() %></td>
                                    <td class="px-4 py-3">
                                        <div class="flex flex-col items-end">
                                            <span class="text-sm font-semibold <%= theEnd ? "text-emerald-600" : "text-amber-600" %>"><%= done %> / <%= req %></span>
                                            <div class="mt-1.5 h-2 w-24 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
                                                <div class="h-full rounded-full transition-all <%= theEnd ? "bg-emerald-500" : "bg-amber-500" %>" style="width: <%= Math.min(100, Math.max(0, (int)((done/(float)req)*100))) %>%"></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-4 py-3 text-right">
                                        <% if (isWorker) { %>
                                            <% if (theEnd) { %>
                                                <form action="ProductionLogController" method="post" class="inline">
                                                    <input type="hidden" name="action" value="completeWorkOrder">
                                                    <input type="hidden" name="workOrderId" value="<%= wo.getWo_id() %>">
                                                    <button type="submit" class="rounded-xl px-3 py-1.5 bg-emerald-500 text-white font-semibold text-sm hover:bg-emerald-600 transition">Hoàn thành</button>
                                                </form>
                                            <% } else { %>
                                                <button type="button" onclick="openLogModal(<%= wo.getWo_id() %>)" class="rounded-xl px-3 py-1.5 bg-amber-500 text-white font-semibold text-sm hover:bg-amber-600 transition">Báo cáo</button>
                                            <% } %>
                                        <% } else { %>
                                            <span class="text-sm text-slate-400">Chỉ xem</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <% } %>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                            <div class="p-4 border-b border-slate-100 dark:border-slate-700">
                                <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                                    <div>
                                        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Lịch sử báo cáo</h3>
                                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Toàn bộ bản ghi sản lượng theo lệnh và công đoạn</p>
                                    </div>
                                    <div class="flex items-center gap-4">
                                        <div class="relative">
                                            <input type="text" id="logSearchInput" onkeyup="filterLogTable()" placeholder="Tìm kiếm lịch sử..." class="pl-10 pr-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm focus:outline-none focus:border-teal-500 transition-colors">
                                            <svg class="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                                        </div>
                                        <span class="px-3 py-1 rounded-full bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 text-sm font-medium">
                                            <%= totalLogs %> bản ghi
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <div class="overflow-x-auto">
                                <table class="w-full">
                                    <thead>
                                        <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã LSX</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Công đoạn</th>
                                            <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Đạt</th>
                                            <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Lỗi</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Lý do</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Thời gian</th>
                                            <% if (isWorker) { %>
                                            <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tùy chọn</th>
                                            <% } %>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% if (listLogs.isEmpty()) { %>
                                        <tr>
                                            <td colspan="6" class="px-4 py-14 text-center text-slate-400 dark:text-slate-500">
                                                <div class="flex flex-col items-center gap-4">
                                                    <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                        <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                                                        </svg>
                                                    </div>
                                                    <div>
                                                        <p class="font-medium text-slate-700 dark:text-slate-200">Chưa có bản ghi nào</p>
                                                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Bấm báo cáo từ các lệnh dưới phần Đang sản xuất.</p>
                                                    </div>
                                                </div>
                                            </td>
                                        </tr>
                                        <% } else { %>
                                            <% for (ProductionLogDTO log : listLogs) { %>
                                            <tr class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors">
                                                <td class="px-4 py-3">
                                                    <a href="MainController?action=listWorkOrder" class="font-semibold text-teal-600 dark:text-teal-300 hover:text-teal-800 dark:hover:text-teal-200">
                                                        #WO-<%= log.getWoId() %>
                                                    </a>
                                                </td>
                                                <td class="px-4 py-3 text-slate-600 dark:text-slate-300"><%= log.getStepName() != null ? log.getStepName() : "-" %></td>
                                                <td class="px-4 py-3 text-right font-semibold text-emerald-600"><%= log.getQuantityDone() %></td>
                                                <td class="px-4 py-3 text-right font-semibold <%= log.getQuantityDefective() > 0 ? "text-red-600 dark:text-red-300" : "text-slate-400 dark:text-slate-500" %>">
                                                    <%= log.getQuantityDefective() %>
                                                </td>
                                                <td class="px-4 py-3 text-slate-500 dark:text-slate-400 text-sm"><%= log.getDefectName() != null ? log.getDefectName() : "-" %></td>
                                                <td class="px-4 py-3 text-slate-500 dark:text-slate-400 text-sm">
                                                    <%= log.getLogDate() != null ? sdf.format(log.getLogDate()) : "-" %>
                                                </td>
                                                <% if (isWorker) { %>
                                                <td class="px-4 py-3 text-right">
                                                    <form action="ProductionLogController" method="post" onsubmit="return confirm('Xóa báo cáo này?');">
                                                        <input type="hidden" name="action" value="delete">
                                                        <input type="hidden" name="logId" value="<%= log.getLogId() %>">
                                                        <button type="submit" class="text-rose-500 hover:text-rose-700 font-semibold text-sm">Xóa</button>
                                                    </form>
                                                </td>
                                                <% } %>
                                            </tr>
                                            <% } %>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                </div>
            </main>
        </div>
    </div>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>

    <jsp:include page="mobile-nav.jsp" />

    <div id="logModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-3xl border border-slate-200 shadow-2xl dark:border-slate-700">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 bg-gradient-to-r from-amber-500 to-orange-500 px-6 py-5 text-white dark:border-slate-700">
                <div>
                    <h3 class="text-lg font-semibold">Báo cáo sản lượng</h3>
                    <p class="mt-1 text-sm text-amber-50">Nhập số lượng đạt và lỗi cho từng công đoạn</p>
                </div>
                <button type="button" onclick="closeLogModal()" class="rounded-xl p-2 text-white/80 transition hover:bg-white/10 hover:text-white">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="ProductionLogController" method="post" class="space-y-5 p-6 bg-white/90 dark:bg-slate-900/60">
                <input type="hidden" name="action" value="addLog">

                <div class="grid gap-5 md:grid-cols-2">
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Lệnh sản xuất</label>
                        <select name="workOrderId" required class="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                            <option value="">-- Chọn lệnh sản xuất --</option>
                            <% for (WorkOrderDTO wo : listWO) {
                                if (!"Completed".equalsIgnoreCase(wo.getStatus())) {
                            %>
                            <option value="<%= wo.getWo_id() %>">
                                WO-<%= wo.getWo_id() %> | SP#<%= wo.getProduct_item_id() %> | <%= wo.getOrder_quantity() %> cái
                            </option>
                            <% }} %>
                        </select>
                    </div>

                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Công đoạn</label>
                        <select name="stepId" required class="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                            <option value="">-- Chọn công đoạn --</option>
                            <% for (RoutingStepDTO s : listSteps) { %>
                            <option value="<%= s.getStepId() %>"><%= s.getStepName() %></option>
                            <% } %>
                        </select>
                    </div>

                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng đạt (OK)</label>
                        <input type="number" name="quantityDone" value="0" min="0" required class="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng lỗi (NG)</label>
                        <input type="number" name="quantityDefective" value="0" min="0" required class="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                    </div>

                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Lý do lỗi (nếu có)</label>
                        <select name="defectId" class="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                            <option value="0">-- Không có lỗi --</option>
                            <% for (DefectDTO d : listDefects) { %>
                            <option value="<%= d.getDefectId() %>"><%= d.getReasonName() %></option>
                            <% } %>
                        </select>
                    </div>
                </div>

                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeLogModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Đóng</button>
                    <button type="submit" class="inline-flex items-center justify-center rounded-2xl bg-amber-500 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition-all hover:bg-amber-600">Gửi báo cáo</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openLogModal(woId) {
            const modal = document.getElementById('logModal');
            if(woId) {
                const selectElement = document.querySelector('select[name="workOrderId"]');
                if(selectElement) {
                    selectElement.value = woId;
                }
            }
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        }

        function closeLogModal() {
            const modal = document.getElementById('logModal');
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }

        document.getElementById('logModal').addEventListener('click', function (e) {
            if (e.target === this) {
                closeLogModal();
            }
        });
    </script>
</body>
</html>
