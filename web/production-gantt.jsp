<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, java.util.ArrayList, pms.model.WorkOrderDTO, pms.model.UserDTO, java.text.SimpleDateFormat"%>
<%
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("workOrders");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");

    if (workOrders == null && request.getAttribute("WORKORDER_GANTT_REDIRECT") == null) {
        request.setAttribute("WORKORDER_GANTT_REDIRECT", Boolean.TRUE);
        response.sendRedirect("WorkOrderController?action=gantt");
        return;
    }
    if (workOrders == null) workOrders = new ArrayList<>();

    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "gantt";
    String pageTitle = "Biểu đồ Gantt";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

    int newCount = 0;
    int progressCount = 0;
    int doneCount = 0;
    int cancelledCount = 0;

    for (WorkOrderDTO w : workOrders) {
        String status = w.getStatus();
        if ("New".equals(status)) {
            newCount++;
        } else if ("In Progress".equals(status) || "InProgress".equals(status)) {
            progressCount++;
        } else if ("Completed".equals(status) || "Done".equals(status)) {
            doneCount++;
        } else if ("Cancelled".equals(status)) {
            cancelledCount++;
        }
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Biểu đồ Gantt - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class'
        };
    </script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
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
        .kpi-card {
            position: relative;
            overflow: hidden;
        }
        .section-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(14px);
        }
        .dark .section-card {
            background: rgba(15, 23, 42, 0.88);
        }
        .gantt-container {
            overflow-x: auto;
        }
        .gantt-container::-webkit-scrollbar {
            height: 10px;
        }
        .gantt-container::-webkit-scrollbar-track {
            background: rgba(148, 163, 184, 0.15);
            border-radius: 999px;
        }
        .gantt-container::-webkit-scrollbar-thumb {
            background: rgba(100, 116, 139, 0.5);
            border-radius: 999px;
        }
        .gantt-bar {
            height: 30px;
            border-radius: 0.9rem;
            transition: all 0.2s ease;
            cursor: pointer;
            white-space: nowrap;
        }
        .gantt-bar:hover {
            transform: translateY(-1px);
            box-shadow: 0 8px 18px rgba(15, 23, 42, 0.14);
        }
        .gantt-bar-new { background: linear-gradient(135deg, #3b82f6, #60a5fa); }
        .gantt-bar-progress { background: linear-gradient(135deg, #f59e0b, #fbbf24); }
        .gantt-bar-done { background: linear-gradient(135deg, #10b981, #34d399); }
        .gantt-bar-cancelled { background: linear-gradient(135deg, #ef4444, #f87171); }
        .gantt-header th {
            position: sticky;
            top: 0;
            z-index: 10;
        }
        .gantt-row:hover td {
            background: rgba(241, 245, 249, 0.85);
        }
        .dark .gantt-row:hover td {
            background: rgba(30, 41, 59, 0.72);
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
                <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Biểu đồ Gantt</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Theo dõi tiến độ lệnh sản xuất theo trục thời gian và trạng thái thực hiện</p>
                    </div>
                    <div class="flex gap-2">
                        <a href="WorkOrderController?action=calendar" class="rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Lịch</a>
                        <a href="WorkOrderController?action=gantt" class="rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm shadow-teal-500/30 transition-colors hover:bg-teal-700">Gantt</a>
                    </div>
                </div>

                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>

                <div class="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mới</p>
                                <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= newCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Lệnh đang chờ bắt đầu</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-300">●</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-amber-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đang sản xuất</p>
                                <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= progressCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Lệnh đang được xử lý</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-300">●</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Hoàn thành</p>
                                <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= doneCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Lệnh đã kết thúc</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-300">●</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-red-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đã hủy</p>
                                <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= cancelledCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Lệnh ngừng thực hiện</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-300">●</div>
                        </div>
                    </div>
                </div>

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="flex flex-col gap-3 border-b border-slate-200 px-6 py-5 dark:border-slate-700 lg:flex-row lg:items-center lg:justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách lệnh sản xuất</h2>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Biểu diễn tiến độ dự kiến theo số lượng và trạng thái hiện tại</p>
                        </div>
                        <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                            Tổng cộng: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= workOrders.size() %></span> lệnh
                        </div>
                    </div>

                    <% if (workOrders.isEmpty()) { %>
                    <div class="px-6 py-16 text-center text-slate-500 dark:text-slate-400">
                        <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                            <svg class="h-9 w-9" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                            </svg>
                        </div>
                        <p class="mt-4 font-medium text-slate-700 dark:text-slate-200">Chưa có lệnh sản xuất nào</p>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Dữ liệu sẽ hiển thị khi hệ thống có lệnh sản xuất</p>
                    </div>
                    <% } else { %>
                    <div class="border-b border-slate-200 bg-slate-50 px-6 py-4 dark:border-slate-700 dark:bg-slate-800/70">
                        <div class="flex flex-wrap items-center gap-4 text-sm">
                            <div class="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                                <span class="h-3 w-8 rounded-full gantt-bar-new"></span>
                                <span>Mới</span>
                            </div>
                            <div class="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                                <span class="h-3 w-8 rounded-full gantt-bar-progress"></span>
                                <span>Đang sản xuất</span>
                            </div>
                            <div class="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                                <span class="h-3 w-8 rounded-full gantt-bar-done"></span>
                                <span>Hoàn thành</span>
                            </div>
                            <div class="flex items-center gap-2 text-slate-600 dark:text-slate-300">
                                <span class="h-3 w-8 rounded-full gantt-bar-cancelled"></span>
                                <span>Đã hủy</span>
                            </div>
                        </div>
                    </div>

                    <div class="gantt-container">
                        <table class="min-w-[980px] w-full">
                            <thead class="gantt-header">
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/90">
                                    <th class="w-48 bg-slate-50 px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:bg-slate-800/90 dark:text-slate-400">Mã LSX</th>
                                    <th class="w-72 bg-slate-50 px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:bg-slate-800/90 dark:text-slate-400">Sản phẩm</th>
                                    <th class="w-28 bg-slate-50 px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:bg-slate-800/90 dark:text-slate-400">Số lượng</th>
                                    <th class="bg-slate-50 px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:bg-slate-800/90 dark:text-slate-400">Tiến độ dự kiến</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <%
                                int stt = 1;
                                for (WorkOrderDTO wo : workOrders) {
                                    String statusClass = "";
                                    String statusLabel = "";
                                    String badgeClass = "";
                                    String progressClass = "w-3/5";

                                    if ("New".equals(wo.getStatus())) {
                                        statusClass = "gantt-bar-new";
                                        statusLabel = "Mới";
                                        badgeClass = "bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-300";
                                        progressClass = "w-1/5";
                                    } else if ("In Progress".equals(wo.getStatus()) || "InProgress".equals(wo.getStatus())) {
                                        statusClass = "gantt-bar-progress";
                                        statusLabel = "Đang SX";
                                        badgeClass = "bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300";
                                        progressClass = "w-3/5";
                                    } else if ("Completed".equals(wo.getStatus()) || "Done".equals(wo.getStatus())) {
                                        statusClass = "gantt-bar-done";
                                        statusLabel = "Hoàn tất";
                                        badgeClass = "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
                                        progressClass = "w-full";
                                    } else {
                                        statusClass = "gantt-bar-cancelled";
                                        statusLabel = "Hủy";
                                        badgeClass = "bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-300";
                                        progressClass = "w-[10%]";
                                    }
                                %>
                                <tr class="gantt-row transition-colors">
                                    <td class="bg-white px-6 py-4 dark:bg-slate-900/40">
                                        <div class="flex items-center gap-3">
                                            <span class="text-xs font-mono text-slate-400 dark:text-slate-500"><%= stt++ %></span>
                                            <span class="inline-flex items-center rounded-full bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-700 dark:bg-teal-500/10 dark:text-teal-300">#WO-<%= wo.getWo_id() %></span>
                                        </div>
                                    </td>
                                    <td class="bg-white px-6 py-4 dark:bg-slate-900/40">
                                        <div class="flex items-center gap-3">
                                            <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-slate-100 text-sm font-bold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                                                <%= wo.getProductName() != null ? wo.getProductName().substring(0, 1).toUpperCase() : "?" %>
                                            </div>
                                            <div>
                                                <p class="font-semibold text-slate-800 dark:text-slate-100"><%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %></p>
                                                <p class="text-sm text-slate-500 dark:text-slate-400"><%= wo.getRoutingName() != null ? wo.getRoutingName() : "-" %></p>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="bg-white px-6 py-4 text-center dark:bg-slate-900/40">
                                        <span class="text-lg font-bold <%= "Cancelled".equals(wo.getStatus()) ? "text-red-500 line-through" : "text-slate-800 dark:text-slate-100" %>"><%= wo.getOrder_quantity() %></span>
                                    </td>
                                    <td class="bg-white px-6 py-4 dark:bg-slate-900/40">
                                        <div class="flex flex-col gap-3">
                                            <div class="flex items-center justify-between gap-3">
                                                <span class="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold <%= badgeClass %>"><%= statusLabel %></span>
                                                <span class="text-xs text-slate-500 dark:text-slate-400">Dự kiến: <%= wo.getOrder_quantity() * 30 %> phút</span>
                                            </div>
                                            <div class="rounded-2xl bg-slate-100 p-2 dark:bg-slate-800">
                                                <div class="gantt-bar <%= statusClass %> <%= progressClass %> flex items-center px-3 text-xs font-semibold text-white shadow-sm">
                                                    <%= statusLabel %> - <%= wo.getOrder_quantity() %> sản phẩm
                                                </div>
                                            </div>
                                            <div class="flex items-center justify-between text-xs text-slate-400 dark:text-slate-500">
                                                <span>Bắt đầu</span>
                                                <span>Tiến độ hiện tại</span>
                                                <span>Hoàn thành</span>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>
</body>
</html>
