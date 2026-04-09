<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, java.util.ArrayList, pms.model.WorkOrderDTO, pms.model.UserDTO, java.text.SimpleDateFormat, java.util.Calendar, java.util.Date"%>
<%!
    // Kiểm tra ô ngày có nằm trong khoảng [startStr, endStr] không
    boolean isInRange(String startStr, String endStr, int year, int month, int day) {
        if (startStr == null || startStr.trim().isEmpty()) return false;
        try {
            int[] s = parseDateParts(startStr);
            int[] e = (endStr != null && !endStr.trim().isEmpty()) ? parseDateParts(endStr) : s;
            int[] cur = {year, month, day}; // month is 0-based (Calendar.MONTH)
            return !isBefore(cur, s) && !isAfter(cur, e);
        } catch (Exception ex) { return false; }
    }

    boolean isMatchingDate(String dateStr, int year, int month, int day) {
        if (dateStr == null || dateStr.trim().isEmpty()) return false;
        try {
            int[] p = parseDateParts(dateStr);
            return p[0] == year && p[1] == month && p[2] == day;
        } catch (Exception e) { return false; }
    }

    int[] parseDateParts(String s) throws Exception {
        String ymd = s.split(" ")[0];
        String[] p = ymd.split("-");
        return new int[]{Integer.parseInt(p[0]), Integer.parseInt(p[1]) - 1, Integer.parseInt(p[2])};
    }

    boolean isBefore(int[] a, int[] b) {
        if (a[0] != b[0]) return a[0] < b[0];
        if (a[1] != b[1]) return a[1] < b[1];
        return a[2] < b[2];
    }
    boolean isAfter(int[] a, int[] b) {
        if (a[0] != b[0]) return a[0] > b[0];
        if (a[1] != b[1]) return a[1] > b[1];
        return a[2] > b[2];
    }

    String fmtDate(String raw) {
        if (raw == null || raw.trim().isEmpty()) return "";
        try {
            String ymd = raw.split(" ")[0];
            String[] p = ymd.split("-");
            return p[2] + "/" + p[1];
        } catch (Exception e) { return raw; }
    }
    String fmtDateFull(String raw) {
        if (raw == null || raw.trim().isEmpty()) return "";
        try {
            String ymd = raw.split(" ")[0];
            String[] p = ymd.split("-");
            return p[2] + "/" + p[1] + "/" + p[0];
        } catch (Exception e) { return raw; }
    }

    // Trả về class CSS cho wo-item theo status
    String woClass(String status) {
        if (status == null) return "wo-new";
        if (status.equalsIgnoreCase("InProgress") || status.equalsIgnoreCase("In Progress")) return "wo-progress";
        if (status.equalsIgnoreCase("Done") || status.equalsIgnoreCase("Completed")) return "wo-done";
        if (status.equalsIgnoreCase("Cancelled")) return "wo-cancelled";
        return "wo-new";
    }

    // Kiểm tra lệnh có xuất hiện trên ô ngày không (theo trạng thái)
    boolean woAppearOnDay(WorkOrderDTO wo, int year, int month, int day) {
        String status = wo.getStatus();
        if (status == null) return false;
        if (status.equalsIgnoreCase("InProgress") || status.equalsIgnoreCase("In Progress")) {
            String s = wo.getStart_date();
            String e = wo.getDue_date();
            if (s == null || s.trim().isEmpty()) s = wo.getCreated_date();
            if (e == null || e.trim().isEmpty()) e = s;
            return isInRange(s, e, year, month, day);
        }
        if (status.equalsIgnoreCase("Done") || status.equalsIgnoreCase("Completed")) {
            return isMatchingDate(wo.getCompleted_date(), year, month, day);
        }
        if (status.equalsIgnoreCase("Cancelled")) {
            return isMatchingDate(wo.getDue_date() != null && !wo.getDue_date().isEmpty() ? wo.getDue_date() : wo.getCreated_date(), year, month, day);
        }
        // New / Ready / WaitMaterial
        String d = wo.getStart_date();
        if (d == null || d.trim().isEmpty()) d = wo.getCreated_date();
        return isMatchingDate(d, year, month, day);
    }
%>
<%
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("workOrders");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");

    if (workOrders == null && request.getAttribute("WORKORDER_CALENDAR_REDIRECT") == null) {
        request.setAttribute("WORKORDER_CALENDAR_REDIRECT", Boolean.TRUE);
        response.sendRedirect("WorkOrderController?action=calendar");
        return;
    }
    if (workOrders == null) workOrders = new ArrayList<>();

    String userRole = user != null ? user.getRole() : "user";
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "calendar";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", "Lịch sản xuất");

    SimpleDateFormat monthSdf = new SimpleDateFormat("MM/yyyy");
    Calendar cal = Calendar.getInstance();
    int currentMonth = cal.get(Calendar.MONTH);
    int currentYear  = cal.get(Calendar.YEAR);

    String monthParam = request.getParameter("month");
    String yearParam  = request.getParameter("year");
    if (monthParam != null && yearParam != null) {
        try {
            currentMonth = Integer.parseInt(monthParam);
            currentYear  = Integer.parseInt(yearParam);
        } catch (Exception e) {}
    }
    cal.set(Calendar.YEAR, currentYear);
    cal.set(Calendar.MONTH, currentMonth);
    cal.set(Calendar.DAY_OF_MONTH, 1);

    int daysInMonth   = cal.getActualMaximum(Calendar.DAY_OF_MONTH);
    int firstDayOfWeek = cal.get(Calendar.DAY_OF_WEEK); // 1=Sun
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lịch sản xuất - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { darkMode: 'class' };</script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .sidebar-header { position: sticky; top: 0; background: #0f172a; z-index: 10; }
        .sidebar-nav { flex: 1; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
        .sidebar-footer { position: sticky; bottom: 0; background: #0f172a; z-index: 10; }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        .section-card { background: rgba(255,255,255,0.95); backdrop-filter: blur(14px); }
        .dark .section-card { background: rgba(15,23,42,0.88); }

        .calendar-day {
            min-height: 120px;
            transition: background-color 0.15s ease;
            cursor: pointer;
        }
        .calendar-day:hover { background-color: #f0fdfa; }
        .dark .calendar-day:hover { background-color: rgba(13,148,136,0.08); }
        .calendar-day.today { background-color: #f0fdfa; box-shadow: inset 0 0 0 2px rgba(13,148,136,0.3); }
        .dark .calendar-day.today { background-color: rgba(13,148,136,0.12); }

        .wo-item {
            font-size: 10px; padding: 3px 6px; border-radius: 5px; margin-bottom: 3px;
            cursor: pointer; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
            font-weight: 600; display: block; text-decoration: none; transition: opacity 0.1s;
            pointer-events: none; /* click handled by day cell */
        }
        .wo-new      { background:#dbeafe; color:#1d4ed8; border-left:3px solid #3b82f6; }
        .wo-progress { background:#fef3c7; color:#b45309; border-left:3px solid #f59e0b; }
        .wo-done     { background:#d1fae5; color:#047857; border-left:3px solid #10b981; }
        .wo-cancelled{ background:#fee2e2; color:#b91c1c; border-left:3px solid #ef4444; text-decoration:line-through; }
        .dark .wo-new      { background:rgba(59,130,246,0.18); color:#93c5fd; }
        .dark .wo-progress { background:rgba(245,158,11,0.18); color:#fcd34d; }
        .dark .wo-done     { background:rgba(16,185,129,0.18); color:#6ee7b7; }
        .dark .wo-cancelled{ background:rgba(239,68,68,0.18); color:#fca5a5; }

        .wo-sub { font-size:9px; opacity:0.75; display:block; margin-top:1px; }

        .more-btn {
            font-size:10px; font-weight:700; color:#6366f1; background:#eef2ff;
            border-radius:5px; padding:2px 6px; margin-top:3px; display:block;
            cursor:pointer; text-align:center; transition:background 0.15s;
            border:none; width:100%;
        }
        .more-btn:hover { background:#e0e7ff; }
        .dark .more-btn { color:#a5b4fc; background:rgba(99,102,241,0.18); }

        /* Modal */
        #dayModal { display:none; position:fixed; inset:0; z-index:999; align-items:center; justify-content:center; }
        #dayModal.open { display:flex; }
        #dayModalBackdrop { position:absolute; inset:0; background:rgba(0,0,0,0.45); backdrop-filter:blur(4px); }
        #dayModalBox {
            position:relative; z-index:1; background:#fff; border-radius:24px; padding:28px;
            width:92%; max-width:540px; max-height:80vh; overflow-y:auto;
            box-shadow:0 24px 64px rgba(0,0,0,0.25);
        }
        .dark #dayModalBox { background:#1e293b; color:#f1f5f9; }
        .wo-modal-row { border-radius:12px; padding:12px 14px; margin-bottom:8px; }
        .wo-modal-row.new      { background:#eff6ff; border-left:4px solid #3b82f6; }
        .wo-modal-row.progress { background:#fffbeb; border-left:4px solid #f59e0b; }
        .wo-modal-row.done     { background:#f0fdf4; border-left:4px solid #10b981; }
        .wo-modal-row.cancelled{ background:#fef2f2; border-left:4px solid #ef4444; }
        .dark .wo-modal-row.new      { background:rgba(59,130,246,0.12); }
        .dark .wo-modal-row.progress { background:rgba(245,158,11,0.12); }
        .dark .wo-modal-row.done     { background:rgba(16,185,129,0.12); }
        .dark .wo-modal-row.cancelled{ background:rgba(239,68,68,0.12); }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark dark-mode-init" : "" %>">
<div class="min-h-screen flex">
    <jsp:include page="components/shared-sidebar.jsp" />
    <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
        <jsp:include page="components/shared-header.jsp" />
        <main class="flex-1 overflow-y-auto bg-slate-100 p-4 dark:bg-slate-900 sm:p-6 lg:p-8">

            <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div>
                    <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Lịch sản xuất</h1>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Bấm vào ô ngày để xem chi tiết các lệnh sản xuất.</p>
                </div>
                <div class="flex gap-2">
                    <a href="WorkOrderController?action=calendar" class="rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm shadow-teal-500/30 transition-colors hover:bg-teal-700">Lịch</a>
                    <a href="WorkOrderController?action=gantt"    class="rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Gantt</a>
                </div>
            </div>

            <% if (msg != null && !msg.trim().isEmpty()) { %>
            <div class="mb-6 flex items-center gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300">
                <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                <%= msg %>
            </div>
            <% } %>

            <!-- Calendar card -->
            <div class="section-card mb-6 overflow-hidden rounded-3xl border border-slate-200/70 shadow-sm dark:border-slate-700/60">
                <!-- Month nav -->
                <div class="flex items-center justify-between border-b border-slate-100 px-4 py-4 dark:border-slate-700/60 sm:px-6">
                    <a href="?month=<%= (currentMonth - 1 + 12) % 12 %>&year=<%= currentMonth == 0 ? currentYear - 1 : currentYear %>"
                       class="rounded-2xl border border-slate-200 p-2 text-slate-600 transition-colors hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
                    </a>
                    <div class="text-center">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400 dark:text-slate-500">Tháng</p>
                        <h2 class="mt-1 text-xl font-bold text-slate-800 dark:text-slate-100"><%= monthSdf.format(cal.getTime()) %></h2>
                    </div>
                    <a href="?month=<%= (currentMonth + 1) % 12 %>&year=<%= currentMonth == 11 ? currentYear + 1 : currentYear %>"
                       class="rounded-2xl border border-slate-200 p-2 text-slate-600 transition-colors hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
                    </a>
                </div>

                <!-- Day headers -->
                <div class="grid grid-cols-7">
                    <% for (String dn : new String[]{"CN","T2","T3","T4","T5","T6","T7"}) { %>
                    <div class="border-b border-slate-100 bg-slate-50 p-3 text-center text-xs font-semibold uppercase text-slate-500 dark:border-slate-700/60 dark:bg-slate-800/80 dark:text-slate-400"><%= dn %></div>
                    <% } %>

                    <!-- Empty cells before first day -->
                    <% for (int i = 1; i < firstDayOfWeek; i++) { %>
                    <div class="calendar-day border-r border-b border-slate-100 bg-slate-50/70 dark:border-slate-700/60 dark:bg-slate-800/40" style="cursor:default"></div>
                    <% } %>

                    <%
                    Calendar dayCal = Calendar.getInstance();
                    dayCal.set(Calendar.YEAR, currentYear);
                    dayCal.set(Calendar.MONTH, currentMonth);
                    Calendar todayCal = Calendar.getInstance();

                    // Pre-build JSON data for JS modal
                    // We'll output a JS array of work orders
                    for (int day = 1; day <= daysInMonth; day++) {
                        dayCal.set(Calendar.DAY_OF_MONTH, day);
                        boolean isToday = (dayCal.get(Calendar.YEAR) == todayCal.get(Calendar.YEAR) &&
                                           dayCal.get(Calendar.MONTH) == todayCal.get(Calendar.MONTH) &&
                                           dayCal.get(Calendar.DAY_OF_MONTH) == todayCal.get(Calendar.DAY_OF_MONTH));

                        // Find orders for this day
                        List<WorkOrderDTO> dayOrders = new ArrayList<>();
                        for (WorkOrderDTO wo : workOrders) {
                            if (woAppearOnDay(wo, currentYear, currentMonth, day)) {
                                dayOrders.add(wo);
                            }
                        }
                        int total     = dayOrders.size();
                        int maxShow   = 3;
                        int overflow  = Math.max(0, total - maxShow);

                        // Build date key yyyy-MM-dd for JS
                        String paddedMonth = String.format("%02d", currentMonth + 1);
                        String paddedDay   = String.format("%02d", day);
                        String dateKey     = currentYear + "-" + paddedMonth + "-" + paddedDay;
                    %>
                    <div class="calendar-day border-r border-b border-slate-100 p-2 dark:border-slate-700/60 <%= isToday ? "today" : "" %>"
                         onclick="openDayDetail('<%= dateKey %>')">
                        <div class="mb-2 flex items-center justify-between">
                            <span class="text-sm font-semibold <%= isToday ? "flex h-7 w-7 items-center justify-center rounded-full bg-teal-500 text-white" : "text-slate-700 dark:text-slate-200" %>"><%= day %></span>
                            <% if (total > 0) { %>
                            <span class="text-[9px] font-bold text-slate-400"><%= total %> lệnh</span>
                            <% } %>
                        </div>
                        <div>
                            <%
                            int shown = 0;
                            for (WorkOrderDTO wo : dayOrders) {
                                if (shown >= maxShow) break;
                                String st = wo.getStatus();
                                String css = woClass(st);
                                // Sub-label
                                String subLabel = "";
                                if (st != null) {
                                    if (st.equalsIgnoreCase("Done") || st.equalsIgnoreCase("Completed")) {
                                        subLabel = "Done: " + fmtDate(wo.getCompleted_date());
                                    } else if (st.equalsIgnoreCase("Cancelled")) {
                                        subLabel = "Hủy: " + fmtDate(wo.getDue_date());
                                    } else if (st.equalsIgnoreCase("InProgress") || st.equalsIgnoreCase("In Progress")) {
                                        subLabel = "Hạn: " + fmtDate(wo.getDue_date());
                                    } else {
                                        subLabel = "Tạo: " + fmtDate(wo.getCreated_date());
                                    }
                                }
                                String prodName = wo.getProductName() != null ? wo.getProductName() : "SP";
                                String shortName = prodName.length() > 10 ? prodName.substring(0,10) + "…" : prodName;
                            %>
                            <span class="wo-item <%= css %>">
                                #<%= wo.getWo_id() %> <%= shortName %>
                                <% if (!subLabel.isEmpty()) { %><span class="wo-sub"><%= subLabel %></span><% } %>
                            </span>
                            <%
                                shown++;
                            }
                            %>
                            <% if (overflow > 0) { %>
                            <button class="more-btn" onclick="event.stopPropagation(); openDayDetail('<%= dateKey %>')">+ <%= overflow %> lệnh nữa</button>
                            <% } %>
                        </div>
                    </div>
                    <% } %>

                    <%
                    int totalCells     = firstDayOfWeek - 1 + daysInMonth;
                    int remainingCells = 7 - (totalCells % 7);
                    if (remainingCells < 7) {
                        for (int i = 0; i < remainingCells; i++) {
                    %>
                    <div class="calendar-day border-r border-b border-slate-100 bg-slate-50/70 dark:border-slate-700/60 dark:bg-slate-800/40" style="cursor:default"></div>
                    <% } } %>
                </div>
            </div>

            <!-- Legend -->
            <div class="section-card rounded-3xl border border-slate-200/70 p-5 shadow-sm dark:border-slate-700/60">
                <div class="flex flex-wrap items-center justify-center gap-4 sm:gap-6">
                    <div class="flex items-center gap-2 text-sm font-semibold text-slate-600 dark:text-slate-300">
                        <span class="h-4 w-4 rounded-[4px] bg-blue-100 ring-1 ring-blue-500 dark:bg-blue-500/20"></span>Mới tạo
                    </div>
                    <div class="flex items-center gap-2 text-sm font-semibold text-slate-600 dark:text-slate-300">
                        <span class="h-4 w-4 rounded-[4px] bg-amber-100 ring-1 ring-amber-500 dark:bg-amber-500/20"></span>Đang sản xuất
                    </div>
                    <div class="flex items-center gap-2 text-sm font-semibold text-slate-600 dark:text-slate-300">
                        <span class="h-4 w-4 rounded-[4px] bg-emerald-100 ring-1 ring-emerald-500 dark:bg-emerald-500/20"></span>Hoàn thành
                    </div>
                    <div class="flex items-center gap-2 text-sm font-semibold text-slate-600 dark:text-slate-300">
                        <span class="h-4 w-4 rounded-[4px] bg-red-100 ring-1 ring-red-500 dark:bg-red-500/20"></span>Đã hủy
                    </div>
                </div>
            </div>
        </main>
    </div>
</div>

<!-- Day Detail Modal -->
<div id="dayModal">
    <div id="dayModalBackdrop" onclick="closeDayDetail()"></div>
    <div id="dayModalBox">
        <div class="mb-5 flex items-center justify-between">
            <div>
                <p class="text-xs font-semibold uppercase tracking-[0.15em] text-slate-400 dark:text-slate-500">Chi tiết ngày</p>
                <h3 id="dayModalTitle" class="mt-1 text-xl font-bold text-slate-900 dark:text-slate-100"></h3>
            </div>
            <button onclick="closeDayDetail()" class="rounded-xl border border-slate-200 p-2 text-slate-500 transition-colors hover:bg-slate-100 dark:border-slate-700 dark:hover:bg-slate-700">
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        </div>
        <div id="dayModalContent"></div>
    </div>
</div>

<!-- JS data layer -->
<script>
const WO_DATA = [
<%
    boolean firstWo = true;
    for (WorkOrderDTO wo : workOrders) {
        if (!firstWo) out.print(",");
        firstWo = false;
        String st    = wo.getStatus() != null ? wo.getStatus() : "";
        String pname = wo.getProductName() != null ? wo.getProductName().replace("\"","\\\"") : "";
        String cname = wo.getCustomerName() != null ? wo.getCustomerName().replace("\"","\\\"") : "";

        // Determine appear dates for JS (minimal: start, end for ranged; single for others)
        String appearStart = "";
        String appearEnd   = "";
        if (st.equalsIgnoreCase("InProgress") || st.equalsIgnoreCase("In Progress")) {
            appearStart = wo.getStart_date() != null && !wo.getStart_date().isEmpty() ? wo.getStart_date().split(" ")[0] : (wo.getCreated_date() != null ? wo.getCreated_date().split(" ")[0] : "");
            appearEnd   = wo.getDue_date() != null && !wo.getDue_date().isEmpty() ? wo.getDue_date().split(" ")[0] : appearStart;
        } else if (st.equalsIgnoreCase("Done") || st.equalsIgnoreCase("Completed")) {
            appearStart = wo.getCompleted_date() != null && !wo.getCompleted_date().isEmpty() ? wo.getCompleted_date().split(" ")[0] : "";
            appearEnd   = appearStart;
        } else if (st.equalsIgnoreCase("Cancelled")) {
            appearStart = wo.getDue_date() != null && !wo.getDue_date().isEmpty() ? wo.getDue_date().split(" ")[0] : (wo.getCreated_date() != null ? wo.getCreated_date().split(" ")[0] : "");
            appearEnd   = appearStart;
        } else {
            appearStart = wo.getStart_date() != null && !wo.getStart_date().isEmpty() ? wo.getStart_date().split(" ")[0] : (wo.getCreated_date() != null ? wo.getCreated_date().split(" ")[0] : "");
            appearEnd   = appearStart;
        }
%>
  {
    id: <%= wo.getWo_id() %>,
    product: "<%= pname %>",
    customer: "<%= cname %>",
    qty: <%= wo.getOrder_quantity() %>,
    status: "<%= st %>",
    statusLabel: "<%= wo.getStatusLabel() %>",
    badgeClass: "<%= wo.getStatusBadgeClass() %>",
    created:   "<%= fmtDateFull(wo.getCreated_date()) %>",
    start:     "<%= fmtDateFull(wo.getStart_date()) %>",
    due:       "<%= fmtDateFull(wo.getDue_date()) %>",
    completed: "<%= fmtDateFull(wo.getCompleted_date()) %>",
    appearStart: "<%= appearStart %>",
    appearEnd:   "<%= appearEnd %>"
  }
<% } %>
];

function dateInRange(dateKey, start, end) {
    if (!start) return false;
    if (!end) end = start;
    return dateKey >= start && dateKey <= end;
}

function openDayDetail(dateKey) {
    const orders = WO_DATA.filter(wo => dateInRange(dateKey, wo.appearStart, wo.appearEnd));
    const parts  = dateKey.split('-');
    const title  = parts[2] + '/' + parts[1] + '/' + parts[0];

    document.getElementById('dayModalTitle').textContent = 'Ngày ' + title;

    const content = document.getElementById('dayModalContent');
    if (orders.length === 0) {
        content.innerHTML = '<p class="text-center text-sm text-slate-400 py-8">Không có lệnh sản xuất nào trong ngày này.</p>';
    } else {
        content.innerHTML = orders.map(wo => {
            const cls = wo.status.toLowerCase().includes('progress') ? 'progress'
                      : wo.status.toLowerCase().includes('done') || wo.status.toLowerCase().includes('complete') ? 'done'
                      : wo.status.toLowerCase().includes('cancel') ? 'cancelled' : 'new';

            let dateLines = '';
            if (wo.created)   dateLines += `<span class="text-xs text-slate-500 dark:text-slate-400">📅 Tạo: <b>\${wo.created}</b></span> `;
            if (wo.start)     dateLines += `<span class="text-xs text-slate-500 dark:text-slate-400">🚀 Bắt đầu: <b>\${wo.start}</b></span> `;
            if (wo.due)       dateLines += `<span class="text-xs text-slate-500 dark:text-slate-400">⏰ Hạn: <b>\${wo.due}</b></span> `;
            if (wo.completed) dateLines += `<span class="text-xs text-emerald-600 dark:text-emerald-400">✅ Hoàn thành: <b>\${wo.completed}</b></span> `;

            const isCompleted = wo.status.toLowerCase().includes('done') || wo.status.toLowerCase().includes('complete');
            const displayStatus = wo.status; // Using raw status like "New", "In Progress"

            return `<div class="mb-4 rounded-xl border border-slate-100 bg-white p-5 shadow-sm dark:border-slate-700/60 dark:bg-slate-800">
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <p class="mb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">Mã Lệnh</p>
                        <p class="text-sm font-bold text-slate-800 dark:text-slate-200">#WO-\${wo.id}</p>
                    </div>
                    <div>
                        <p class="mb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">Trạng Thái</p>
                        <p class="text-sm font-semibold text-slate-800 dark:text-slate-200">\${displayStatus}</p>
                    </div>
                    <div>
                        <p class="mb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">Sản Phẩm</p>
                        <p class="text-sm font-semibold text-slate-800 dark:text-slate-200">\${wo.product}</p>
                    </div>
                    <div>
                        <p class="mb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">Số Lượng</p>
                        <p class="text-sm font-semibold text-slate-800 dark:text-slate-200">\${wo.qty}</p>
                    </div>
                    <div>
                        <p class="mb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">Ngày Bắt Đầu</p>
                        <p class="text-sm font-medium text-slate-800 dark:text-slate-200">\${wo.start ? wo.start : "-"}</p>
                    </div>
                    <div>
                        <p class="mb-1 text-[10px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">Hạn Chót</p>
                        <p class="text-sm font-medium text-slate-800 dark:text-slate-200">\${wo.due ? wo.due : "-"}</p>
                    </div>
                </div>
                <div class="mt-4 flex justify-end border-t border-slate-100 pt-4 dark:border-slate-700/60">
                    <button type="button" onclick="closeDayDetail()"
                       class="rounded-xl border border-slate-200 bg-slate-50 px-5 py-2 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-100 dark:border-slate-600 dark:bg-slate-700 dark:text-slate-200 dark:hover:bg-slate-600">
                        Đóng
                    </button>
                </div>
            </div>`;
        }).join('');
    }
    document.getElementById('dayModal').classList.add('open');
    document.body.style.overflow = 'hidden';
}

function closeDayDetail() {
    document.getElementById('dayModal').classList.remove('open');
    document.body.style.overflow = '';
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDayDetail(); });
</script>
</body>
</html>