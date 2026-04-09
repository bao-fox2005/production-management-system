<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.WorkOrderDTO, pms.model.UserDTO, java.text.SimpleDateFormat, java.util.Date"%>
<%!
    // Hàm hiển thị thời gian rút gọn
    String formatTime(String dbDate) {
        if (dbDate == null || dbDate.isEmpty()) return "Chưa xác định";
        try {
            String datePart = dbDate.split(" ")[0]; 
            String timePart = dbDate.split(" ")[1]; 
            String[] d = datePart.split("-");
            String[] t = timePart.split(":");
            return t[0] + ":" + t[1] + " ngày " + d[2] + "/" + d[1];
        } catch (Exception e) { return dbDate; }
    }
    
    // Kiểm tra quá hạn
    boolean isOverdue(String dueStr) {
        if (dueStr == null || dueStr.isEmpty()) return false;
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            Date due = sdf.parse(dueStr.endsWith(".0") ? dueStr.substring(0, 19) : dueStr.replace("T", " "));
            return due.getTime() < new Date().getTime();
        } catch (Exception e) { return false; }
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    List<WorkOrderDTO> newList = (List<WorkOrderDTO>) request.getAttribute("newList");
    List<WorkOrderDTO> readyList = (List<WorkOrderDTO>) request.getAttribute("readyList");
    List<WorkOrderDTO> inProgressList = (List<WorkOrderDTO>) request.getAttribute("inProgressList");
    List<WorkOrderDTO> doneList = (List<WorkOrderDTO>) request.getAttribute("doneList");
    List<WorkOrderDTO> cancelledList = (List<WorkOrderDTO>) request.getAttribute("cancelledList");
    
    if (newList == null && inProgressList == null) {
        response.sendRedirect("KanbanController");
        return;
    }
    if (readyList == null) readyList = new java.util.ArrayList<>();
    
    UserDTO user = (UserDTO) session.getAttribute("user");
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    int totalOrders = newList.size() + readyList.size() + inProgressList.size() + doneList.size() + cancelledList.size();
    int overdueCount = request.getAttribute("overdueCount") != null ? (Integer) request.getAttribute("overdueCount") : 0;
    
    String keyword = request.getAttribute("keyword") != null ? (String) request.getAttribute("keyword") : "";
    String fromDate = request.getAttribute("fromDate") != null ? (String) request.getAttribute("fromDate") : "";
    String toDate = request.getAttribute("toDate") != null ? (String) request.getAttribute("toDate") : "";
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bảng tiến độ - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { darkMode: 'class' };</script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        * { font-family: 'Inter', 'Segoe UI', Arial, sans-serif; }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .sidebar-header { position: sticky; top: 0; background: #0f172a; z-index: 10; }
        .sidebar-nav { flex: 1; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        
        .kpi-card { position: relative; overflow: hidden; }
        .section-card { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(14px); }
        .dark .section-card { background: rgba(15, 23, 42, 0.88); }
        .form-input { width: 100%; border-radius: 1rem; border: 1px solid rgb(226 232 240); background: rgb(255 255 255 / 0.92); padding: 0.75rem 1rem; color: rgb(15 23 42); transition: all 0.2s ease; }
        .dark .form-input { border-color: rgb(51 65 85); background: rgb(15 23 42 / 0.75); color: rgb(241 245 249); }
        .form-input:focus { border-color: #0d9488; box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1); outline: none; }
        
        .kanban-col { min-height: 520px; }
        .wo-card { cursor: grab; transition: all 0.2s ease; }
        .wo-card:hover { transform: translateY(-2px); }
        .wo-card:active { cursor: grabbing; }
        .wo-card.dragging { opacity: 0.5; transform: rotate(2deg); }
        .drop-zone { min-height: 280px; transition: all 0.2s ease; }
        .drop-zone.drag-over { background-color: rgba(16, 185, 129, 0.08); box-shadow: inset 0 0 0 2px rgba(16, 185, 129, 0.45); }

        /* Animation cảnh báo lệnh trễ */
        .overdue-pulse { animation: pulse-red 2s infinite; border-width: 2px; }
        @keyframes pulse-red {
            0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
            70% { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
            100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
                <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Bảng tiến độ sản xuất</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Cảnh báo trễ hạn và kéo thả để cập nhật trạng thái</p>
                    </div>
                    <div class="rounded-2xl bg-white px-5 py-3 text-sm font-bold shadow-sm border border-slate-200 dark:bg-slate-800 dark:border-slate-700 dark:text-slate-300">
                        Tổng: <span class="text-teal-600 dark:text-teal-400"><%= totalOrders %></span>
                    </div>
                </div>

                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-5 shadow-sm dark:border-slate-700">
                    <form action="KanbanController" method="GET" class="grid gap-4 md:grid-cols-2 lg:grid-cols-[1fr_200px_200px_auto] lg:items-end">
                        <div class="relative">
                            <label class="block text-xs font-semibold text-slate-500 mb-1 ml-1">Mã lệnh / Sản phẩm</label>
                            <input type="text" name="keyword" value="<%= keyword %>" placeholder="Nhập từ khóa..." class="form-input pl-11">
                            <svg class="absolute left-4 bottom-3.5 h-5 w-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                            </svg>
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-500 mb-1 ml-1">Tạo từ ngày</label>
                            <input type="date" name="fromDate" value="<%= fromDate %>" class="form-input text-sm text-slate-500">
                        </div>
                        <div>
                            <label class="block text-xs font-semibold text-slate-500 mb-1 ml-1">Đến ngày</label>
                            <input type="date" name="toDate" value="<%= toDate %>" class="form-input text-sm text-slate-500">
                        </div>
                        <button type="submit" class="rounded-2xl bg-teal-600 px-6 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">Lọc dữ liệu</button>
                    </form>
                </div>

                <div class="grid gap-4 grid-cols-2 md:grid-cols-3 xl:grid-cols-6 mb-6">
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-blue-500 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mới</p>
                        <p class="mt-2 text-2xl font-bold text-slate-900 dark:text-slate-100"><%= newList.size() %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-sky-500 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Chờ SX</p>
                        <p class="mt-2 text-2xl font-bold text-slate-900 dark:text-slate-100"><%= readyList.size() %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-amber-500 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đang sản xuất</p>
                        <p class="mt-2 text-2xl font-bold text-slate-900 dark:text-slate-100"><%= inProgressList.size() %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Hoàn thành</p>
                        <p class="mt-2 text-2xl font-bold text-slate-900 dark:text-slate-100"><%= doneList.size() %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-slate-400 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đã Hủy</p>
                        <p class="mt-2 text-2xl font-bold text-slate-900 dark:text-slate-100"><%= cancelledList.size() %></p>
                    </div>
                    <div class="kpi-card rounded-2xl border border-red-200 border-t-4 border-t-red-600 bg-red-50 p-4 shadow-sm dark:border-red-900/30 dark:bg-red-900/10">
                        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-red-600 dark:text-red-400">Trễ hạn chót</p>
                        <p class="mt-2 text-2xl font-bold text-red-600 dark:text-red-400"><%= overdueCount %></p>
                    </div>
                </div>

                <div class="grid grid-cols-1 gap-5 xl:grid-cols-5">
                    
                    <div class="section-card kanban-col rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                        <div class="mb-4 flex items-center justify-between rounded-2xl bg-blue-50 px-4 py-3 dark:bg-blue-500/10">
                            <div class="flex items-center gap-3">
                                <span class="h-3 w-3 rounded-full bg-blue-500"></span>
                                <div>
                                    <h3 class="font-semibold text-slate-900 dark:text-slate-100">Mới</h3>
                                </div>
                            </div>
                            <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-blue-700 shadow-sm dark:bg-slate-800 dark:text-blue-300"><%= newList.size() %></span>
                        </div>
                        <div id="col-new" class="drop-zone space-y-3 rounded-2xl border border-dashed border-slate-200 bg-slate-50/80 p-2 dark:border-slate-700 dark:bg-slate-800/40"
                             ondrop="handleDrop(event, 'New')" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)">
                            <% for (WorkOrderDTO wo : newList) { 
                                boolean over = isOverdue(wo.getDue_date());
                            %>
                            <div class="wo-card rounded-2xl border <%= over ? "border-red-500 bg-red-50/80 overdue-pulse" : "border-slate-200 bg-white" %> p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
                                 draggable="true"
                                 data-id="<%= wo.getWo_id() %>"
                                 data-status="New"
                                 ondragstart="handleDragStart(event)"
                                 ondragend="handleDragEnd(event)">
                                <div class="mb-3 flex items-start justify-between gap-3">
                                    <span class="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-500/10 dark:text-blue-300">#WO-<%= wo.getWo_id() %></span>
                                    <% if(over) { %>
                                        <span class="rounded-full bg-red-100 px-2.5 py-1 text-[10px] font-bold text-red-600 uppercase">⚠️ Trễ Hạn</span>
                                    <% } else { %>
                                        <span class="rounded-full bg-blue-100 px-2.5 py-1 text-[10px] font-bold text-blue-700 dark:bg-blue-500/10 dark:text-blue-300 uppercase">Mới</span>
                                    <% } %>
                                </div>
                                <p class="text-sm font-bold text-slate-900 dark:text-slate-100"><%= wo.getProductName() != null ? wo.getProductName() : "Sản phẩm #" + wo.getProduct_item_id() %></p>
                                <div class="mt-3 flex flex-col gap-1 border-t border-slate-100 pt-3 dark:border-slate-700">
                                    <p class="text-[11px] font-medium text-slate-500 dark:text-slate-400">Tạo: <%= formatTime(wo.getCreated_date()) %></p>
                                    <p class="text-[11px] font-bold <%= over ? "text-red-600" : "text-amber-600 dark:text-amber-400" %>">Hạn: <%= formatTime(wo.getDue_date()) %></p>
                                </div>
                                <div class="mt-3 flex items-center justify-between gap-3">
                                    <span class="rounded-xl bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:bg-slate-700 dark:text-slate-200">SL: <%= wo.getOrder_quantity() %></span>
                                    <button type="button" onclick="event.stopPropagation(); openKanbanDetail(this)"
                                            data-wo-id="<%= wo.getWo_id() %>"
                                            data-product="<%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %>"
                                            data-routing="<%= wo.getRoutingName() != null ? wo.getRoutingName() : "-" %>"
                                            data-quantity="<%= wo.getOrder_quantity() %>"
                                            data-status="New"
                                            data-start="<%= wo.getStart_date() != null ? wo.getStart_date().substring(0, Math.min(10, wo.getStart_date().length())) : "Chưa xác định" %>"
                                            data-due="<%= wo.getDue_date() != null ? wo.getDue_date().substring(0, Math.min(10, wo.getDue_date().length())) : "Chưa xác định" %>"
                                            data-notes="<%= wo.getNotes() != null ? wo.getNotes() : "" %>"
                                            class="text-xs font-semibold text-teal-600 transition-colors hover:text-teal-700 dark:text-teal-400 dark:hover:text-teal-300">Chi tiết</button>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <!-- Cột Chờ SX (Ready) -->
                    <div class="section-card kanban-col rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                        <div class="mb-4 flex items-center justify-between rounded-2xl bg-sky-50 px-4 py-3 dark:bg-sky-500/10">
                            <div class="flex items-center gap-3">
                                <span class="h-3 w-3 rounded-full bg-sky-500"></span>
                                <div>
                                    <h3 class="font-semibold text-slate-900 dark:text-slate-100">Chờ SX</h3>
                                </div>
                            </div>
                            <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-sky-700 shadow-sm dark:bg-slate-800 dark:text-sky-300"><%= readyList.size() %></span>
                        </div>
                        <div id="col-ready" class="drop-zone space-y-3 rounded-2xl border border-dashed border-slate-200 bg-slate-50/80 p-2 dark:border-slate-700 dark:bg-slate-800/40"
                             ondrop="handleDrop(event, 'Ready')" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)">
                            <% for (WorkOrderDTO wo : readyList) { 
                                boolean over = isOverdue(wo.getDue_date());
                            %>
                            <div class="wo-card rounded-2xl border <%= over ? "border-red-500 bg-red-50/80 overdue-pulse" : "border-slate-200 bg-white" %> p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
                                 draggable="true"
                                 data-id="<%= wo.getWo_id() %>"
                                 data-status="Ready"
                                 ondragstart="handleDragStart(event)"
                                 ondragend="handleDragEnd(event)">
                                <div class="mb-3 flex items-start justify-between gap-3">
                                    <span class="inline-flex items-center rounded-full bg-sky-50 px-3 py-1 text-xs font-semibold text-sky-700 dark:bg-sky-500/10 dark:text-sky-300">#WO-<%= wo.getWo_id() %></span>
                                    <% if(over) { %>
                                        <span class="rounded-full bg-red-100 px-2.5 py-1 text-[10px] font-bold text-red-600 uppercase">⚠️ Trễ Hạn</span>
                                    <% } else { %>
                                        <span class="rounded-full bg-sky-100 px-2.5 py-1 text-[10px] font-bold text-sky-700 dark:bg-sky-500/10 dark:text-sky-300 uppercase">Sẵn sàng</span>
                                    <% } %>
                                </div>
                                <p class="text-sm font-bold text-slate-900 dark:text-slate-100"><%= wo.getProductName() != null ? wo.getProductName() : "Sản phẩm #" + wo.getProduct_item_id() %></p>
                                <div class="mt-3 flex flex-col gap-1 border-t border-slate-100 pt-3 dark:border-slate-700">
                                    <p class="text-[11px] font-medium text-slate-500 dark:text-slate-400">Tạo: <%= formatTime(wo.getCreated_date()) %></p>
                                    <p class="text-[11px] font-bold <%= over ? "text-red-600" : "text-sky-600 dark:text-sky-400" %>">Hạn: <%= formatTime(wo.getDue_date()) %></p>
                                </div>
                                <div class="mt-3 flex items-center justify-between gap-3">
                                    <span class="rounded-xl bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:bg-slate-700 dark:text-slate-200">SL: <%= wo.getOrder_quantity() %></span>
                                    <button type="button" onclick="event.stopPropagation(); openKanbanDetail(this)"
                                            data-wo-id="<%= wo.getWo_id() %>"
                                            data-product="<%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %>"
                                            data-routing="<%= wo.getRoutingName() != null ? wo.getRoutingName() : "-" %>"
                                            data-quantity="<%= wo.getOrder_quantity() %>"
                                            data-status="Ready"
                                            data-start="<%= wo.getStart_date() != null ? wo.getStart_date().substring(0, Math.min(10, wo.getStart_date().length())) : "Chưa xác định" %>"
                                            data-due="<%= wo.getDue_date() != null ? wo.getDue_date().substring(0, Math.min(10, wo.getDue_date().length())) : "Chưa xác định" %>"
                                            data-notes="<%= wo.getNotes() != null ? wo.getNotes() : "" %>"
                                            class="text-xs font-semibold text-teal-600 transition-colors hover:text-teal-700 dark:text-teal-400 dark:hover:text-teal-300">Chi tiết</button>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <div class="section-card kanban-col rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                        <div class="mb-4 flex items-center justify-between rounded-2xl bg-amber-50 px-4 py-3 dark:bg-amber-500/10">
                            <div class="flex items-center gap-3">
                                <span class="h-3 w-3 rounded-full bg-amber-500"></span>
                                <div>
                                    <h3 class="font-semibold text-slate-900 dark:text-slate-100">Đang sản xuất</h3>
                                </div>
                            </div>
                            <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-amber-700 shadow-sm dark:bg-slate-800 dark:text-amber-300"><%= inProgressList.size() %></span>
                        </div>
                        <div id="col-inprogress" class="drop-zone space-y-3 rounded-2xl border border-dashed border-slate-200 bg-slate-50/80 p-2 dark:border-slate-700 dark:bg-slate-800/40"
                             ondrop="handleDrop(event, 'InProgress')" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)">
                            <% for (WorkOrderDTO wo : inProgressList) { 
                                boolean over = isOverdue(wo.getDue_date());
                            %>
                            <div class="wo-card rounded-2xl border <%= over ? "border-red-500 bg-red-50/80 overdue-pulse" : "border-slate-200 bg-white" %> p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
                                 draggable="true"
                                 data-id="<%= wo.getWo_id() %>"
                                 data-status="InProgress"
                                 ondragstart="handleDragStart(event)"
                                 ondragend="handleDragEnd(event)">
                                <div class="mb-3 flex items-start justify-between gap-3">
                                    <span class="inline-flex items-center rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700 dark:bg-amber-500/10 dark:text-amber-300">#WO-<%= wo.getWo_id() %></span>
                                    <% if(over) { %>
                                        <span class="rounded-full bg-red-100 px-2.5 py-1 text-[10px] font-bold text-red-600 uppercase">⚠️ Trễ Hạn</span>
                                    <% } else { %>
                                        <span class="rounded-full bg-amber-100 px-2.5 py-1 text-[10px] font-bold text-amber-700 dark:bg-amber-500/10 dark:text-amber-300 uppercase">Đang chạy</span>
                                    <% } %>
                                </div>
                                <p class="text-sm font-bold text-slate-900 dark:text-slate-100"><%= wo.getProductName() != null ? wo.getProductName() : "Sản phẩm #" + wo.getProduct_item_id() %></p>
                                <div class="mt-3 rounded-xl <%= over ? "bg-red-100" : "bg-amber-50 dark:bg-amber-900/20" %> p-2">
                                    <p class="text-[11px] font-bold <%= over ? "text-red-700" : "text-amber-700 dark:text-amber-300" %>">⏰ Hạn chót: <%= formatTime(wo.getDue_date()) %></p>
                                </div>
                                <div class="mt-3 flex items-center justify-between gap-3">
                                    <span class="rounded-xl bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:bg-slate-700 dark:text-slate-200">SL: <%= wo.getOrder_quantity() %></span>
                                    <button type="button" onclick="event.stopPropagation(); openKanbanDetail(this)"
                                            data-wo-id="<%= wo.getWo_id() %>"
                                            data-product="<%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %>"
                                            data-routing="<%= wo.getRoutingName() != null ? wo.getRoutingName() : "-" %>"
                                            data-quantity="<%= wo.getOrder_quantity() %>"
                                            data-status="InProgress"
                                            data-start="<%= wo.getStart_date() != null ? wo.getStart_date().substring(0, Math.min(10, wo.getStart_date().length())) : "Chưa xác định" %>"
                                            data-due="<%= wo.getDue_date() != null ? wo.getDue_date().substring(0, Math.min(10, wo.getDue_date().length())) : "Chưa xác định" %>"
                                            data-notes="<%= wo.getNotes() != null ? wo.getNotes() : "" %>"
                                            class="text-xs font-semibold text-teal-600 transition-colors hover:text-teal-700 dark:text-teal-400 dark:hover:text-teal-300">Chi tiết</button>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <div class="section-card kanban-col rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                        <div class="mb-4 flex items-center justify-between rounded-2xl bg-emerald-50 px-4 py-3 dark:bg-emerald-500/10">
                            <div class="flex items-center gap-3">
                                <span class="h-3 w-3 rounded-full bg-emerald-500"></span>
                                <div>
                                    <h3 class="font-semibold text-slate-900 dark:text-slate-100">Hoàn thành</h3>
                                </div>
                            </div>
                            <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-emerald-700 shadow-sm dark:bg-slate-800 dark:text-emerald-300"><%= doneList.size() %></span>
                        </div>
                        <div id="col-done" class="drop-zone space-y-3 rounded-2xl border border-dashed border-slate-200 bg-slate-50/80 p-2 dark:border-slate-700 dark:bg-slate-800/40"
                             ondrop="handleDrop(event, 'Done')" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)">
                            <% for (WorkOrderDTO wo : doneList) { %>
                            <div class="wo-card rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
                                 draggable="true"
                                 data-id="<%= wo.getWo_id() %>"
                                 data-status="Done"
                                 ondragstart="handleDragStart(event)"
                                 ondragend="handleDragEnd(event)">
                                <div class="mb-3 flex items-start justify-between gap-3">
                                    <span class="inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300">#WO-<%= wo.getWo_id() %></span>
                                    <span class="rounded-full bg-emerald-100 px-2.5 py-1 text-[10px] font-bold text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300 uppercase">Hoàn tất</span>
                                </div>
                                <p class="text-sm font-bold text-slate-900 dark:text-slate-100"><%= wo.getProductName() != null ? wo.getProductName() : "Sản phẩm #" + wo.getProduct_item_id() %></p>
                                <div class="mt-3 flex items-center gap-2 text-emerald-600 dark:text-emerald-400">
                                    <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>
                                    <span class="text-[11px] font-bold">Xong lúc: <%= formatTime(wo.getCompleted_date()) %></span>
                                </div>
                                <div class="mt-3 flex items-center justify-between gap-3">
                                    <span class="rounded-xl bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:bg-slate-700 dark:text-slate-200">SL: <%= wo.getOrder_quantity() %></span>
                                    <button type="button" onclick="event.stopPropagation(); openKanbanDetail(this)"
                                            data-wo-id="<%= wo.getWo_id() %>"
                                            data-product="<%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %>"
                                            data-routing="<%= wo.getRoutingName() != null ? wo.getRoutingName() : "-" %>"
                                            data-quantity="<%= wo.getOrder_quantity() %>"
                                            data-status="Done"
                                            data-start="<%= wo.getStart_date() != null ? wo.getStart_date().substring(0, Math.min(10, wo.getStart_date().length())) : "Chưa xác định" %>"
                                            data-due="<%= wo.getDue_date() != null ? wo.getDue_date().substring(0, Math.min(10, wo.getDue_date().length())) : "Chưa xác định" %>"
                                            data-completed="<%= wo.getCompleted_date() != null ? wo.getCompleted_date().substring(0, Math.min(10, wo.getCompleted_date().length())) : "" %>"
                                            data-notes="<%= wo.getNotes() != null ? wo.getNotes() : "" %>"
                                            class="text-xs font-semibold text-teal-600 transition-colors hover:text-teal-700 dark:text-teal-400 dark:hover:text-teal-300">Chi tiết</button>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>

                    <div class="section-card kanban-col rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                        <div class="mb-4 flex items-center justify-between rounded-2xl bg-slate-100 px-4 py-3 dark:bg-slate-800">
                            <div class="flex items-center gap-3">
                                <span class="h-3 w-3 rounded-full bg-slate-400"></span>
                                <div>
                                    <h3 class="font-semibold text-slate-900 dark:text-slate-100">Đã Hủy</h3>
                                </div>
                            </div>
                            <span class="rounded-full bg-white px-3 py-1 text-xs font-semibold text-slate-700 shadow-sm dark:bg-slate-700 dark:text-slate-300"><%= cancelledList.size() %></span>
                        </div>
                        <div id="col-cancelled" class="drop-zone space-y-3 rounded-2xl border border-dashed border-slate-200 bg-slate-50/80 p-2 dark:border-slate-700 dark:bg-slate-800/40"
                             ondrop="handleDrop(event, 'Cancelled')" ondragover="handleDragOver(event)" ondragleave="handleDragLeave(event)">
                            <% for (WorkOrderDTO wo : cancelledList) { %>
                            <div class="wo-card opacity-75 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-800"
                                 draggable="true"
                                 data-id="<%= wo.getWo_id() %>"
                                 data-status="Cancelled"
                                 ondragstart="handleDragStart(event)"
                                 ondragend="handleDragEnd(event)">
                                <div class="mb-3 flex items-start justify-between gap-3">
                                    <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600 dark:bg-slate-700 dark:text-slate-300">#WO-<%= wo.getWo_id() %></span>
                                </div>
                                <h4 class="text-sm font-semibold text-slate-500 dark:text-slate-400 line-through"><%= wo.getProductName() != null ? wo.getProductName() : "Sản phẩm #" + wo.getProduct_item_id() %></h4>
                                <div class="mt-3 flex flex-col gap-1">
                                    <p class="text-[11px] text-slate-400">Tạo: <%= formatTime(wo.getCreated_date()) %></p>
                                    <p class="text-[11px] font-bold text-red-500">Đã bị hủy bỏ</p>
                                </div>
                                <div class="mt-3 flex items-center justify-end">
                                    <button type="button" onclick="event.stopPropagation(); openKanbanDetail(this)"
                                            data-wo-id="<%= wo.getWo_id() %>"
                                            data-product="<%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %>"
                                            data-routing="<%= wo.getRoutingName() != null ? wo.getRoutingName() : "-" %>"
                                            data-quantity="<%= wo.getOrder_quantity() %>"
                                            data-status="Cancelled"
                                            data-start="<%= wo.getStart_date() != null ? wo.getStart_date().substring(0, Math.min(10, wo.getStart_date().length())) : "Chưa xác định" %>"
                                            data-due="<%= wo.getDue_date() != null ? wo.getDue_date().substring(0, Math.min(10, wo.getDue_date().length())) : "Chưa xác định" %>"
                                            data-notes="<%= wo.getNotes() != null ? wo.getNotes() : "" %>"
                                            class="text-xs font-semibold text-teal-600 transition-colors hover:text-teal-700 dark:text-teal-400 dark:hover:text-teal-300">Chi tiết</button>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <script>
        let draggedElement = null;
        let draggedId = null;
        let draggedStatus = null;

        function handleDragStart(event) {
            draggedElement = event.currentTarget;
            draggedId = event.currentTarget.dataset.id;
            draggedStatus = event.currentTarget.dataset.status;
            event.currentTarget.classList.add('dragging');
            event.dataTransfer.effectAllowed = 'move';
        }

        function handleDragEnd(event) {
            event.currentTarget.classList.remove('dragging');
            document.querySelectorAll('.drop-zone').forEach(function (el) {
                el.classList.remove('drag-over');
            });
        }

        function handleDragOver(event) {
            event.preventDefault();
            event.dataTransfer.dropEffect = 'move';
            event.currentTarget.classList.add('drag-over');
        }

        function handleDragLeave(event) {
            event.currentTarget.classList.remove('drag-over');
        }

        function handleDrop(event, newStatus) {
            event.preventDefault();
            event.currentTarget.classList.remove('drag-over');

            if (!draggedId || !newStatus) return;
            if (draggedStatus === newStatus) return;

            var xhr = new XMLHttpRequest();
            xhr.open('POST', 'KanbanController', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    if (xhr.status === 200 && xhr.responseText.trim() === 'OK') {
                        location.reload();
                    } else {
                        alert('Lỗi cập nhật trạng thái: ' + xhr.responseText);
                    }
                }
            };
            xhr.send('action=updateStatus&id=' + draggedId + '&status=' + encodeURIComponent(newStatus));
        }
        function openKanbanDetail(btn) {
            if (!btn) return;
            document.getElementById('kbDetailWoId').textContent = '#WO-' + btn.getAttribute('data-wo-id');
            document.getElementById('kbDetailProductName').textContent = btn.getAttribute('data-product') || '-';
            document.getElementById('kbDetailQuantity').textContent = btn.getAttribute('data-quantity') || '0';
            document.getElementById('kbDetailStartDate').textContent = btn.getAttribute('data-start') || 'Chưa xác định';
            document.getElementById('kbDetailDueDate').textContent = btn.getAttribute('data-due') || 'Chưa xác định';

            // Status
            var status = btn.getAttribute('data-status') || 'New';
            var statusText = status;
            if (status === 'New') statusText = 'New';
            else if (status === 'Ready') statusText = 'Chờ SX';
            else if (status === 'InProgress') statusText = 'Đang SX';
            else if (status === 'Done') statusText = 'Hoàn Thành';
            else if (status === 'Cancelled') statusText = 'Đã Hủy';
            document.getElementById('kbDetailStatus').textContent = statusText;

            // Notes
            var notes = btn.getAttribute('data-notes');
            var notesSection = document.getElementById('kbDetailNotesSection');
            if (notes && notes.trim() !== '') {
                notesSection.style.display = '';
                document.getElementById('kbDetailNotes').textContent = notes;
            } else {
                notesSection.style.display = 'none';
            }

            document.getElementById('kanbanDetailModal').classList.remove('hidden');
            document.getElementById('kanbanDetailModal').classList.add('flex');
        }

        function closeKanbanDetail() {
            document.getElementById('kanbanDetailModal').classList.add('hidden');
            document.getElementById('kanbanDetailModal').classList.remove('flex');
        }
    </script>

    <!-- Modal Chi tiết lệnh sản xuất -->
    <div id="kanbanDetailModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm" onclick="if(event.target===this)closeKanbanDetail()">
        <div class="section-card max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-3xl border border-slate-200 shadow-2xl dark:border-slate-700">
            <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Chi tiết lệnh sản xuất</h3>
                <button type="button" onclick="closeKanbanDetail()" class="rounded-xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
            <div class="grid gap-5 p-6 sm:grid-cols-2">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Mã lệnh</p>
                    <p id="kbDetailWoId" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Trạng thái</p>
                    <p id="kbDetailStatus" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Sản phẩm</p>
                    <p id="kbDetailProductName" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Số lượng</p>
                    <p id="kbDetailQuantity" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Ngày bắt đầu</p>
                    <p id="kbDetailStartDate" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Hạn chót</p>
                    <p id="kbDetailDueDate" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div class="sm:col-span-2" id="kbDetailNotesSection" style="display:none">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Ghi chú</p>
                    <p id="kbDetailNotes" class="mt-2 text-sm text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-800 rounded-xl px-4 py-3"></p>
                </div>
            </div>
            <div class="flex justify-end border-t border-slate-200 px-6 py-5 dark:border-slate-700">
                <button type="button" onclick="closeKanbanDetail()" class="rounded-2xl border border-slate-200 px-6 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Đóng</button>
            </div>
        </div>
    </div>
</body>
</html>