<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.ProductionLogDTO, pms.model.QcInspectionDTO, pms.model.WorkOrderDTO, pms.model.RoutingStepDTO, pms.model.DefectDTO, pms.model.UserDTO, java.text.SimpleDateFormat"%>
<%
    List<ProductionLogDTO> listLogs = (List<ProductionLogDTO>) request.getAttribute("listLogs");
    List<QcInspectionDTO> inspections = (List<QcInspectionDTO>) request.getAttribute("inspections");
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("listWO");
    List<RoutingStepDTO> listSteps = (List<RoutingStepDTO>) request.getAttribute("listSteps");
    List<DefectDTO> listDefects = (List<DefectDTO>) request.getAttribute("listDefects");
    
    UserDTO user = (UserDTO) session.getAttribute("user");
    boolean isAdmin = user != null && "admin".equalsIgnoreCase(user.getRole());
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String activeTab = request.getParameter("tab");
    if (activeTab == null) activeTab = "log"; // default to production log

    if (listLogs == null) listLogs = new java.util.ArrayList<>();
    if (inspections == null) inspections = new java.util.ArrayList<>();
    if (workOrders == null) workOrders = new java.util.ArrayList<>();
    if (listSteps == null) listSteps = new java.util.ArrayList<>();
    if (listDefects == null) listDefects = new java.util.ArrayList<>();

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    
    request.setAttribute("activePage", "tracking");
    request.setAttribute("pageTitle", "Báo cáo tiến độ (Shop Floor)");

    // Production KPIs
    int totalLogs = listLogs.size();
    int totalOK = 0, totalNG = 0;
    for (ProductionLogDTO log : listLogs) {
        totalOK += log.getQuantityDone();
        totalNG += log.getQuantityDefective();
    }
    
    // QC KPIs
    Integer totalInspectedAttr = (Integer) request.getAttribute("totalInspected");
    Integer totalFailedAttr = (Integer) request.getAttribute("totalFailed");
    Double passRateAttr = (Double) request.getAttribute("passRate");
    int totalInspected = totalInspectedAttr != null ? totalInspectedAttr : 0;
    int totalFailed = totalFailedAttr != null ? totalFailedAttr : 0;
    int totalPassed = totalInspected - totalFailed;
    double passRate = passRateAttr != null ? passRateAttr : 0;
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Theo dõi Sản xuất & QC - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: { fontFamily: { sans: ['Inter', 'sans-serif'], } }
            }
        }
    </script>
    <style>
        body { font-family: Inter, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .form-input { transition: all 0.2s ease; }
        .form-input:focus { box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1); }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        .kpi-card { transition: all 0.2s ease; }
        .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08); }
        .section-card { background: rgba(255,255,255,0.95); backdrop-filter: blur(12px); }
        .dark .section-card { background: rgba(15,23,42,0.92); }
        .status-pass { background: #d1fae5; color: #047857; }
        .status-fail { background: #fee2e2; color: #b91c1c; }
        .dark .status-pass { background: rgba(16, 185, 129, 0.14); color: #6ee7b7; }
        .dark .status-fail { background: rgba(239, 68, 68, 0.14); color: #fca5a5; }
        
        /* Tabs styling */
        .tab-btn { transition: all 0.2s ease; border-bottom: 2px solid transparent; }
        .tab-btn.active { border-bottom-color: #0d9488; color: #0d9488; font-weight: 600; }
        .dark .tab-btn.active { border-bottom-color: #2dd4bf; color: #2dd4bf; }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Báo cáo tiến độ (Shop Floor)</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Cập nhật tiến độ theo công đoạn và ghi nhận chất lượng phế phẩm</p>
                    </div>
                    <% if (!isAdmin) { %>
                    <div class="flex flex-wrap gap-2">
                        <button onclick="openModal('logModal')" class="inline-flex items-center gap-2 rounded-xl bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-indigo-700">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                            Cập nhật tiến độ
                        </button>
                    </div>
                    <% } %>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-4 p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-700 dark:bg-emerald-500/10 dark:border-emerald-500/20 dark:text-emerald-300 flex items-center gap-3">
                    <%= java.net.URLDecoder.decode(msg, "UTF-8") %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-4 p-4 rounded-2xl bg-red-50 border border-red-200 text-red-700 dark:bg-red-500/10 dark:border-red-500/20 dark:text-red-300 flex items-center gap-3">
                    <%= java.net.URLDecoder.decode(error, "UTF-8") %>
                </div>
                <% } %>

                <!-- Combined KPIs -->
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
                    <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-xs font-semibold text-slate-500 uppercase">SP Đạt (Sản xuất)</p>
                        <p class="mt-2 text-3xl font-bold text-emerald-600"><%= totalOK %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-xs font-semibold text-slate-500 uppercase">SP Lỗi (Sản xuất)</p>
                        <p class="mt-2 text-3xl font-bold text-rose-600"><%= totalNG %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-xs font-semibold text-slate-500 uppercase">Kiểm tra QC</p>
                        <p class="mt-2 text-3xl font-bold text-teal-600"><%= totalInspected %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-xs font-semibold text-slate-500 uppercase">Tỷ lệ Đạt QC</p>
                        <p class="mt-2 text-3xl font-bold text-emerald-600"><%= String.format("%.1f", passRate) %>%</p>
                    </div>
                </div>

                <!-- Unified Tracking History -->
                <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden mb-8">
                    <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
                        <h3 class="font-semibold text-slate-800 dark:text-slate-100">Lịch sử cập nhật tiến độ</h3>
                    </div>
                    <table class="w-full">
                        <thead>
                            <tr class="bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                                <th class="px-6 py-3 text-left text-xs font-semibold uppercase text-slate-500">Loại sự kiện</th>
                                <th class="px-6 py-3 text-left text-xs font-semibold uppercase text-slate-500">Mã lệnh / C.Đoạn</th>
                                <th class="px-6 py-3 text-left text-xs font-semibold uppercase text-slate-500">Tiến độ & Số lượng</th>
                                <th class="px-6 py-3 text-left text-xs font-semibold uppercase text-slate-500">Ghi chú / Phế phẩm</th>
                                <th class="px-6 py-3 text-left text-xs font-semibold uppercase text-slate-500">Thời gian</th>
                            </tr>
                        </thead>
                        <tbody>
<%
    class TrackingEvent implements Comparable<TrackingEvent> {
        public String type; 
        public java.util.Date date;
        public String woId;
        public String stepName;
        public int pass;
        public int fail;
        public int orderQty;
        public String badge;
        public String note;
        public int compareTo(TrackingEvent o) {
            if (this.date == null && o.date == null) return 0;
            if (this.date == null) return 1;
            if (o.date == null) return -1;
            return o.date.compareTo(this.date);
        }
    }
    java.util.List<TrackingEvent> allEvents = new java.util.ArrayList<>();
    for(ProductionLogDTO l : listLogs) {
        TrackingEvent e = new TrackingEvent();
        e.type = "Nhật ký tiến độ";
        e.date = l.getLogDate();
        e.woId = "WO-" + l.getWoId();
        e.stepName = l.getStepName() != null ? l.getStepName() : "Sản xuất";
        e.pass = l.getQuantityDone();
        e.fail = l.getQuantityDefective();
        
        int wQty = 0;
        for (WorkOrderDTO w : workOrders) {
            if (w.getWo_id() == l.getWoId()) {
                wQty = w.getOrder_quantity();
                break;
            }
        }
        e.orderQty = wQty;
        
        e.badge = "text-indigo-600 bg-indigo-50 dark:bg-indigo-500/10";
        e.note = l.getDefectName() != null ? l.getDefectName() : "-";
        allEvents.add(e);
    }
    for(QcInspectionDTO q : inspections) {
        TrackingEvent e = new TrackingEvent();
        e.type = "Kiểm định QC";
        e.date = q.getInspectionDate();
        e.woId = "WO-" + q.getWoId();
        e.stepName = q.getStepName() != null ? q.getStepName() : "QC";
        e.pass = q.getQuantityPassed();
        e.fail = q.getQuantityFailed();
        e.orderQty = q.getQuantityInspected();
        e.badge = "text-teal-600 bg-teal-50 dark:bg-teal-500/10";
        e.note = q.getNotes() != null && !q.getNotes().isEmpty() ? q.getNotes() : "-";
        allEvents.add(e);
    }
    java.util.Collections.sort(allEvents);

    if (allEvents.isEmpty()) {
%>
                                <tr><td colspan="5" class="p-6 text-center text-slate-500">Chưa có dữ liệu hệ thống.</td></tr>
<%  } else {
        for (TrackingEvent e : allEvents) {
%>
                                <tr class="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                    <td class="px-6 py-3">
                                        <span class="px-2.5 py-1 rounded-full text-xs font-semibold <%= e.badge %>">
                                            <%= e.type %>
                                        </span>
                                    </td>
                                    <td class="px-6 py-3">
                                        <div class="text-sm font-semibold text-slate-800 dark:text-slate-200"><%= e.woId %></div>
                                        <div class="text-xs text-slate-500"><%= e.stepName %></div>
                                    </td>
                                    <td class="px-6 py-3">
                                        <div class="text-sm font-semibold text-emerald-600" title="Đạt"><%= e.pass %> Đạt</div>
                                        <div class="text-xs text-slate-500 mt-1 italic">
                                            <%= e.type.contains("QC") ? "Đã kiểm " + e.orderQty : "Đã làm xong " + e.pass + "/" + e.orderQty + " cái" %>
                                        </div>
                                    </td>
                                    <td class="px-6 py-3 text-sm">
                                        <% if (e.fail > 0) { %>
                                        <div class="font-medium text-rose-600 mb-1">Ghi nhận: <%= e.fail %> phế phẩm</div>
                                        <% } %>
                                        <div class="text-slate-500 max-w-xs truncate" title="<%= e.note.replace("\"", "&quot;") %>">
                                            Lý do: <%= e.note %>
                                        </div>
                                    </td>
                                    <td class="px-6 py-3 text-sm text-slate-500 whitespace-nowrap">
                                        <%= e.date != null ? sdf.format(e.date) : "-" %>
                                    </td>
                                </tr>
<%      }
    }
%>
                        </tbody>
                    </table>
                </div>
            </main>
        </div>
    </div>
    
    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>
    <jsp:include page="mobile-nav.jsp" />

    <% if (!isAdmin) { %>
    <!-- MODAL: ADD LOG (Shop Floor Progress) -->
    <div id="logModal" class="hidden fixed inset-0 z-50 items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card w-full max-w-lg rounded-3xl p-6">
            <h3 class="text-lg font-bold mb-1 dark:text-white">Cập nhật tiến độ & Ghi nhận phế phẩm</h3>
            <p class="text-sm text-slate-500 mb-4">Báo cáo số lượng hoàn thành và phế phẩm phát sinh</p>
            <form action="ProductionTrackingController" method="post" class="space-y-4">
                <input type="hidden" name="action" value="addLog">
                <select name="workOrderId" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="">-- Chọn lệnh sản xuất đang chạy --</option>
                    <% for (WorkOrderDTO w : workOrders) { if (!"Completed".equalsIgnoreCase(w.getStatus())) { %>
                    <option value="<%= w.getWo_id() %>">WO-<%= w.getWo_id() %> (Tổng: <%= w.getOrder_quantity() %> cái)</option>
                    <% } } %>
                </select>
                <select name="stepId" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="">-- Chọn công đoạn thực hiện --</option>
                    <% for (RoutingStepDTO s : listSteps) { %>
                    <option value="<%= s.getStepId() %>"><%= s.getStepName() %></option>
                    <% } %>
                </select>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-semibold text-slate-500 mb-1">Số lượng Đạt (Pass)</label>
                        <input type="number" name="quantityDone" min="0" value="0" required class="w-full form-input p-3 rounded-xl border border-slate-300 bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:border-emerald-800 dark:text-emerald-300">
                    </div>
                    <div>
                        <label class="block text-xs font-semibold text-slate-500 mb-1">Phế phẩm (Fail)</label>
                        <input type="number" name="quantityDefective" min="0" value="0" required class="w-full form-input p-3 rounded-xl border border-slate-300 bg-rose-50 text-rose-700 dark:bg-rose-900/20 dark:border-rose-800 dark:text-rose-300">
                    </div>
                </div>
                <div>
                    <label class="block text-xs font-semibold text-slate-500 mb-1">Nguyên nhân lỗi (Nếu có phế phẩm)</label>
                    <select name="defectId" class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                        <option value="0">-- Không có lỗi --</option>
                        <% for (DefectDTO d : listDefects) { %>
                        <option value="<%= d.getDefectId() %>"><%= d.getReasonName() %></option>
                        <% } %>
                    </select>
                </div>
                <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-slate-200 dark:border-slate-700">
                    <button type="button" onclick="closeModal('logModal')" class="px-5 py-2.5 rounded-xl text-slate-600 hover:bg-slate-100 font-medium transition dark:text-slate-300 dark:hover:bg-slate-800">Đóng</button>
                    <button type="submit" class="px-5 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold hover:bg-indigo-700 transition shadow-sm shadow-indigo-500/30">Cập nhật tiến độ</button>
                </div>
            </form>
        </div>
    </div>
    <% } %>

    <script>
        function openModal(id) { document.getElementById(id).classList.remove('hidden'); document.getElementById(id).classList.add('flex'); }
        function closeModal(id) { document.getElementById(id).classList.add('hidden'); document.getElementById(id).classList.remove('flex');}
    </script>
</body>
</html>
