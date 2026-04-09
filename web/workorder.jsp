<%--
  ===== workorder.jsp – Quản lý Lệnh Sản Xuất =====
  Mục đích    : Trang CRUD đầy đủ cho Work Order (lệnh sản xuất).
                Tích hợp bộ lọc, bảng danh sách, 4 modal: Add / Edit / Detail / Delete.
  Request attributes nhận từ WorkOrderController:
    - "workOrders"  (List<WorkOrderDTO>) : Danh sách lệnh sản xuất (đã lọc)
    - "WORKORDER"   (WorkOrderDTO)       : Lệnh được chọn xem/sửa (không dùng ở đây, dùng trong modal qua data-*)
    - "items"       (List<ItemDTO>)      : Dropdown chọn sản phẩm (lọc item_type=SanPham)
    - "routings"    (List<RoutingDTO>)   : Dropdown chọn quy trình sản xuất
    - "msg"         (String)             : Flash thông báo thành công (đọc từ request hoặc param)
    - "error"       (String)             : Thông báo lỗi
  Session attributes đọc:
    - session["user"]     (UserDTO) : Thông tin người dùng (role để ẩn/hiện nút admin)
    - session["darkMode"] (Boolean) : Bật/tắt dark mode
  Filter params (GET):
    - keyword   : Tìm kiếm tự do theo mã, tên sản phẩm
    - product_id: Lọc theo sản phẩm
    - status    : Lọc theo trạng thái (New/WaitMaterial/Ready/InProgress/Done/Cancelled)
  JSP helpers (<%! ... %>):
    - getProductName()   : Ưu tiên WorkOrderDTO.productName; fallback lookup trong List<ItemDTO>
    - getRoutingName()   : Tương tự cho routing
    - getStatusClass()   : Trả về CSS class Tailwind tương ứng với từng trạng thái
    - getStatusLabel()   : Dịch status code sang tiếng Việt
    - isOverdue()        : Kiểm tra trễ hạn (due_date < now và chưa Done/Cancelled)
    - getDeadlineText()  : Hiển thị "QUÁ HẠN" ⚠️ hoặc "Còn X ngày Y giờ" ⏳
    - formatForInput()   : Chuyển datetime DB sang "yyyy-MM-ddTHH:mm" cho input[type=datetime-local]
    - formatDisplayDate(): Cắt chuỗi ngày giờ DB để hiển thị
  Luồng trạng thái Work Order:
    New → [checkMaterials → WaitMaterial/Ready] → [startProduction → InProgress] → [completeOrder → Done]
    Admin: có thể Edit/Delete khi status là New/WaitMaterial/Ready
    Employee: chỉ có nút "Bắt đầu làm" (Ready→InProgress) và "Báo cáo Xong" (InProgress→Done)
  Modal JavaScript:
    - openAddModal()                   : Mở modal thêm, tự điền ngày bắt đầu = now, due = tomorrow
    - openEditModalFromButton(btn)     : Đọc data-* từ nút Edit để điền vào form sửa
    - openDetailModalFromButton(btn)   : Đọc data-* để hiển thị popup chi tiết (read-only)
    - openDeleteWorkOrderModal(btn)    : Xác nhận xóa, truyền wo_id vào hidden field
    - validateDates(form)              : Client-side: kiểm tra due_date >= start_date
  Action form (POST → WorkOrderController):
    - insert         : Thêm lệnh mới
    - update         : Cập nhật lệnh
    - delete         : Xóa lệnh (chỉ khi status New/WaitMaterial/Ready)
    - checkMaterials : Kiểm tra kho → chuyển sang WaitMaterial (thiếu) hoặc Ready (đủ)
    - startProduction: Công nhân nhận lệnh → InProgress
    - completeOrder  : Báo cáo hoàn thành → Done, tự động cập nhật tồn kho
  Phân quyền  : Admin toàn quyền; Employee chỉ có nút trạng thái (Bắt đầu/Xong).
--%>
<%@page import="java.util.ArrayList, java.util.List, java.text.SimpleDateFormat, java.util.Date"%>
<%@page import="pms.model.WorkOrderDTO"%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="pms.model.RoutingDTO"%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");
    
    WorkOrderDTO wo = (WorkOrderDTO) request.getAttribute("WORKORDER");
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("workOrders");
    List<ItemDTO> items = (List<ItemDTO>) request.getAttribute("items");
    List<RoutingDTO> routings = (List<RoutingDTO>) request.getAttribute("routings");
    UserDTO user = (UserDTO) session.getAttribute("user");
    List<pms.utils.NotificationService.Notification> notifications = (List<pms.utils.NotificationService.Notification>) session.getAttribute("notifications");
    
    String msg = request.getAttribute("msg") != null ? (String) request.getAttribute("msg") : request.getParameter("msg");
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    String searchKeyword = request.getParameter("keyword");
    String filterStatus = request.getParameter("status");
    String filterProduct = request.getParameter("product_id");
    
    if (workOrders == null) workOrders = new ArrayList<>();
    if (items == null) items = new ArrayList<>();
    if (routings == null) routings = new ArrayList<>();
    if (notifications == null) notifications = new ArrayList<>();
    
    String activePage = "workorder";
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    
    // BIẾN QUAN TRỌNG: Kiểm tra xem ai đang đăng nhập
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    
    int totalWO = workOrders.size();
    int newCount = 0, readyCount = 0, inProgressCount = 0, completedCount = 0, cancelledCount = 0;
    for (WorkOrderDTO w : workOrders) {
        if (w.getStatus() != null) {
            if (w.getStatus().equalsIgnoreCase("New")) newCount++;
            else if (w.getStatus().equalsIgnoreCase("Ready")) readyCount++;
            else if (w.getStatus().equalsIgnoreCase("In Progress") || w.getStatus().equalsIgnoreCase("InProgress")) inProgressCount++;
            else if (w.getStatus().equalsIgnoreCase("Completed") || w.getStatus().equalsIgnoreCase("Done")) completedCount++;
            else if (w.getStatus().equalsIgnoreCase("Cancelled")) cancelledCount++;
        }
    }
%>
<%!
    String getProductName(WorkOrderDTO w, List<ItemDTO> items) {
        if (w.getProductName() != null && !w.getProductName().isEmpty()) return w.getProductName();
        for (ItemDTO item : items) {
            if (item.getItemID() == w.getProduct_item_id()) return item.getItemName() != null ? item.getItemName() : "SP#" + item.getItemID();
        }
        return "SP#" + w.getProduct_item_id();
    }

    String getRoutingName(WorkOrderDTO w, List<RoutingDTO> routings) {
        if (w.getRoutingName() != null && !w.getRoutingName().isEmpty()) return w.getRoutingName();
        for (RoutingDTO r : routings) {
            if (r.getRoutingId() == w.getRouting_id()) return r.getRoutingName() != null ? r.getRoutingName() : "Routing#" + r.getRoutingId();
        }
        return "Routing#" + w.getRouting_id();
    }

    String getStatusClass(String status) {
        if (status == null) return "bg-slate-100 text-slate-600 dark:bg-slate-700/70 dark:text-slate-300";
        if (status.equalsIgnoreCase("New")) return "bg-blue-100 text-blue-700 dark:bg-blue-500/10 dark:text-blue-300";
        if (status.equalsIgnoreCase("Ready")) return "bg-sky-100 text-sky-700 dark:bg-sky-500/10 dark:text-sky-300";
        if (status.equalsIgnoreCase("In Progress") || status.equalsIgnoreCase("InProgress")) return "bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300";
        if (status.equalsIgnoreCase("Completed") || status.equalsIgnoreCase("Done")) return "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
        if (status.equalsIgnoreCase("Cancelled")) return "bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-300";
        return "bg-slate-100 text-slate-600 dark:bg-slate-700/70 dark:text-slate-300";
    }

    String getStatusLabel(String status) {
        if (status == null) return "N/A";
        if (status.equalsIgnoreCase("New")) return "Mới";
        if (status.equalsIgnoreCase("Ready")) return "Chờ SX";
        if (status.equalsIgnoreCase("In Progress") || status.equalsIgnoreCase("InProgress")) return "Đang SX";
        if (status.equalsIgnoreCase("Completed") || status.equalsIgnoreCase("Done")) return "Hoàn Thành";
        if (status.equalsIgnoreCase("Cancelled")) return "Đã Hủy";
        return status;
    }

    boolean isOverdue(String dueStr, String status) {
        if (dueStr == null || dueStr.isEmpty() || "Done".equalsIgnoreCase(status) || "Cancelled".equalsIgnoreCase(status)) return false;
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            Date due = sdf.parse(dueStr.endsWith(".0") ? dueStr.substring(0, 19) : dueStr);
            return due.getTime() < new Date().getTime();
        } catch (Exception e) { return false; }
    }

    String getDeadlineText(String dueStr, String status) {
        if (dueStr == null || dueStr.isEmpty() || "Done".equalsIgnoreCase(status) || "Cancelled".equalsIgnoreCase(status)) return "";
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            Date due = sdf.parse(dueStr.endsWith(".0") ? dueStr.substring(0, 19) : dueStr);
            long diff = due.getTime() - new Date().getTime();
            
            if (diff < 0) {
                return "<span class='mt-1.5 block text-[11px] font-bold text-red-600 bg-red-100/80 px-2 py-0.5 rounded-md'>⚠️ QUÁ HẠN</span>";
            } else {
                long days = diff / (1000 * 60 * 60 * 24);
                long hours = (diff / (1000 * 60 * 60)) % 24;
                String timeTxt = days > 0 ? (days + " ngày " + hours + " giờ") : (hours + " giờ");
                return "<span class='mt-1 block text-[11px] font-medium text-amber-600 dark:text-amber-400'>⏳ Còn " + timeTxt + "</span>";
            }
        } catch (Exception e) { return ""; }
    }
    
    String formatForInput(String dbDate) {
        if (dbDate == null || dbDate.isEmpty()) return "";
        try { return dbDate.replace(" ", "T").substring(0, 16); } catch (Exception e) { return ""; }
    }
    
    String formatDisplayDate(String dbDate) {
        if (dbDate == null || dbDate.isEmpty()) return "-";
        try { return dbDate.endsWith(".0") ? dbDate.substring(0, 16) : dbDate.substring(0, 16); } catch (Exception e) { return dbDate; }
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản Lý Lệnh Sản Xuất - PMS</title>
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
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        .form-input { width: 100%; border-radius: 1rem; border: 1px solid rgb(226 232 240); background: rgb(255 255 255 / 0.92); padding: 0.75rem 1rem; color: rgb(15 23 42); transition: all 0.2s ease; }
        .dark .form-input { border-color: rgb(51 65 85); background: rgb(15 23 42 / 0.75); color: rgb(241 245 249); }
        .form-input:focus { border-color: #0d9488; box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1); outline: none; }
        .kpi-card { position: relative; overflow: hidden; }
        .section-card { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(14px); }
        .dark .section-card { background: rgba(15, 23, 42, 0.88); }
        .table-row:hover td { background: rgba(248, 250, 252, 0.85); }
        .dark .table-row:hover td { background: rgba(30, 41, 59, 0.72); }
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
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Lệnh sản xuất</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo, tìm kiếm và theo dõi toàn bộ lệnh sản xuất trên cùng một màn hình</p>
                    </div>
                    <% if (isAdmin) { %>
                    <button onclick="openAddModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                        Thêm lệnh mới
                    </button>
                    <% } %>
                </div>

                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-red-200 bg-red-50 px-4 py-4 text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <%= error %>
                </div>
                <% } %>

                <div class="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
                    <!-- Tổng lệnh -->
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-indigo-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">Tổng lệnh</p>
                                <p class="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= totalWO %></p>
                            </div>
                            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 dark:bg-indigo-500/10 dark:text-indigo-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                            </div>
                        </div>
                    </div>
                    <!-- Mới -->
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">Mới</p>
                                <p class="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= newCount %></p>
                            </div>
                            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
                            </div>
                        </div>
                    </div>
                    <!-- Chờ SX -->
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-sky-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">Chờ SX</p>
                                <p class="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= readyCount %></p>
                            </div>
                            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-50 text-sky-600 dark:bg-sky-500/10 dark:text-sky-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/></svg>
                            </div>
                        </div>
                    </div>
                    <!-- Đang SX -->
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-amber-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">Đang SX</p>
                                <p class="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= inProgressCount %></p>
                            </div>
                            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    <!-- Hoàn thành -->
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">Hoàn thành</p>
                                <p class="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= completedCount %></p>
                            </div>
                            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    <!-- Đã hủy -->
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-red-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-3">
                            <div>
                                <p class="text-[11px] font-semibold uppercase tracking-[0.15em] text-slate-500 dark:text-slate-400">Đã hủy</p>
                                <p class="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= cancelledCount %></p>
                            </div>
                            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-red-50 text-red-600 dark:bg-red-500/10 dark:text-red-300">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-5 shadow-sm dark:border-slate-700">
                    <form action="MainController" method="get" class="grid gap-4 md:grid-cols-2 lg:grid-cols-[1fr_200px_200px_auto] lg:items-center">
                        <input type="hidden" name="action" value="listWorkOrder">
                        
                        <div class="relative">
                            <input type="text" name="keyword" value="<%= searchKeyword != null ? searchKeyword : "" %>" placeholder="Tìm kiếm mã lệnh, quy trình..." class="form-input pl-11">
                            <svg class="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                            </svg>
                        </div>
                        
                        <select name="product_id" class="form-input">
                            <option value="">Tất cả sản phẩm</option>
                            <% for (ItemDTO item : items) { 
                                if (item.isProduct() || "SanPham".equalsIgnoreCase(item.getItemType())) {
                            %>
                            <option value="<%= item.getItemID() %>" <%= String.valueOf(item.getItemID()).equals(filterProduct) ? "selected" : "" %>><%= item.getItemName() %></option>
                            <% } } %>
                        </select>

                        <select name="status" class="form-input">
                            <option value="">Tất cả trạng thái</option>
                            <option value="New" <%= "New".equals(filterStatus) ? "selected" : "" %>>Mới</option>
                            <option value="Ready" <%= "Ready".equals(filterStatus) ? "selected" : "" %>>Chờ SX</option>
                            <option value="In Progress" <%= "In Progress".equals(filterStatus) ? "selected" : "" %>>Đang sản xuất</option>
                            <option value="Done" <%= "Done".equals(filterStatus) ? "selected" : "" %>>Hoàn thành</option>
                            <option value="Cancelled" <%= "Cancelled".equals(filterStatus) ? "selected" : "" %>>Đã hủy</option>
                        </select>
                        <button type="submit" class="rounded-2xl bg-teal-600 px-6 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">Lọc dữ liệu</button>
                    </form>
                </div>

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="flex flex-col gap-3 border-b border-slate-200 px-6 py-5 dark:border-slate-700 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách lệnh sản xuất</h2>
                        </div>
                        <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                            Tổng cộng: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= workOrders.size() %></span>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Mã LSX / Ngày tạo</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Sản phẩm</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Hạn chót</th>
                                    <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Số lượng</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Trạng thái</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Hành động</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <% if (workOrders.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-6 py-14 text-center text-slate-500 dark:text-slate-400">Chưa có lệnh sản xuất nào</td>
                                </tr>
                                <% } else { %>
                                    <% for (WorkOrderDTO w : workOrders) { 
                                        boolean overdue = isOverdue(w.getDue_date(), w.getStatus());
                                    %>
                                    <tr class="table-row transition-colors <%= overdue ? "bg-rose-50/40 dark:bg-rose-900/10" : "" %>">
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-700 dark:bg-teal-500/10 dark:text-teal-300">#WO-<%= w.getWo_id() %></span>
                                            <p class="mt-1 text-[11px] text-slate-400"><%= formatDisplayDate(w.getCreated_date()) %></p>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <div class="flex items-center gap-3">
                                                <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-teal-50 text-sm font-bold text-teal-600 dark:bg-teal-500/10 dark:text-teal-300">
                                                    <%= getProductName(w, items).substring(0, Math.min(2, getProductName(w, items).length())).toUpperCase() %>
                                                </div>
                                                <div>
                                                    <p class="font-semibold text-slate-800 dark:text-slate-100"><%= getProductName(w, items) %></p>
                                                    <p class="text-sm text-slate-500"><%= getRoutingName(w, routings) %></p>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <div class="text-sm text-slate-600 dark:text-slate-300">
                                                <%= formatDisplayDate(w.getDue_date()) %>
                                            </div>
                                            <%= getDeadlineText(w.getDue_date(), w.getStatus()) %>
                                        </td>
                                        <td class="px-6 py-4 text-right align-middle font-semibold text-slate-800 dark:text-slate-100"><%= w.getOrder_quantity() %></td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex flex-col items-center gap-1.5">
                                                <span class="inline-flex items-center rounded-full px-3 py-1 text-xs font-bold <%= getStatusClass(w.getStatus()) %>">
                                                    <%= getStatusLabel(w.getStatus()) %>
                                                </span>
                                                <% if ("New".equalsIgnoreCase(w.getStatus()) && w.getNotes() != null && w.getNotes().startsWith("Thiếu")) { %>
                                                    <span class="text-[11px] font-medium text-rose-600 dark:text-rose-400 max-w-[150px] leading-tight text-center">
                                                        <%= w.getNotes() %>
                                                    </span>
                                                <% } %>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex items-center justify-center gap-2">
                                                
                                                <% if (isAdmin) { %>
                                                    <% if ("New".equalsIgnoreCase(w.getStatus())) { %>
                                                        <form action="WorkOrderController" method="post" class="inline-block m-0 p-0" style="margin-right: 4px;">
                                                            <input type="hidden" name="action" value="checkMaterials">
                                                            <input type="hidden" name="wo_id" value="<%= w.getWo_id() %>">
                                                            <button type="submit" 
                                                                    class="rounded-xl p-2.5 text-sky-500 transition-colors hover:bg-sky-100 hover:text-sky-700 dark:hover:bg-sky-500/10 dark:text-sky-400"
                                                                    title="Kiểm tra kho vật tư">
                                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                                                                </svg>
                                                            </button>
                                                        </form>
                                                    <% } %>

                                                    <%-- Icon giỏ hàng: hiện khi status=New và notes có thông tin thiếu vật tư --%>
                                                    <% if ("New".equalsIgnoreCase(w.getStatus()) && w.getNotes() != null && w.getNotes().startsWith("Thiếu")) { %>
                                                        <a href="MainController?action=listPurchaseOrder&from_wo_id=<%= w.getWo_id() %>" 
                                                           class="flex items-center gap-1.5 rounded-xl bg-rose-50 px-3 py-2 text-xs font-semibold text-rose-600 transition-colors hover:bg-rose-100 hover:text-rose-700 dark:bg-rose-500/10 dark:text-rose-400"
                                                           title="Tạo đơn nhập vật tư thiếu" style="margin-right: 4px;">
                                                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                                                        </a>
                                                    <% } %>
                                                    
                                                    <%
                                                        String st = w.getStatus() != null ? w.getStatus() : "";
                                                        boolean canEditOrDelete = "New".equalsIgnoreCase(st) || "Ready".equalsIgnoreCase(st);
                                                        if (canEditOrDelete) {
                                                    %>
                                                    <button type="button"
                                                            class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-amber-100 hover:text-amber-600 dark:text-slate-400 dark:hover:bg-amber-500/10 dark:hover:text-amber-300"
                                                            title="Chỉnh sửa"
                                                            data-wo-id="<%= w.getWo_id() %>"
                                                            data-product-id="<%= w.getProduct_item_id() %>"
                                                            data-routing-id="<%= w.getRouting_id() %>"
                                                            data-quantity="<%= w.getOrder_quantity() %>"
                                                            data-status="<%= w.getStatus() != null ? w.getStatus() : "New" %>"
                                                            data-start-date="<%= formatForInput(w.getStart_date()) %>"
                                                            data-due-date="<%= formatForInput(w.getDue_date()) %>"
                                                            onclick="openEditModalFromButton(this)">
                                                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                                                    </button>
                                                    <button type="button"
                                                            data-wo-id="<%= w.getWo_id() %>"
                                                            data-wo-name="Lệnh sản xuất #<%= w.getWo_id() %>"
                                                            onclick="openDeleteWorkOrderModal(this)"
                                                            class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-red-100 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-500/10 dark:hover:text-red-300" title="Xóa">
                                                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                                    </button>
                                                    <% } %>

                                                <% } else { %>
                                                    <% if ("Ready".equalsIgnoreCase(w.getStatus())) { %>
                                                        <form action="WorkOrderController" method="post" class="inline-block m-0 p-0" style="margin-right: 4px;">
                                                            <input type="hidden" name="action" value="startProduction">
                                                            <input type="hidden" name="wo_id" value="<%= w.getWo_id() %>">
                                                            <button type="submit" 
                                                                    class="flex items-center gap-1.5 rounded-xl bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-600 transition-colors hover:bg-emerald-100 hover:text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400"
                                                                    title="Nhận lệnh và Bắt đầu làm">
                                                                <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                                                                <span>Bắt đầu làm</span>
                                                            </button>
                                                        </form>
                                                    <% } %>

                                                    <% if ("In Progress".equalsIgnoreCase(w.getStatus()) || "InProgress".equalsIgnoreCase(w.getStatus())) { %>
                                                        <form action="WorkOrderController" method="post" class="inline-block m-0 p-0" style="margin-right: 4px;">
                                                            <input type="hidden" name="action" value="completeOrder">
                                                            <input type="hidden" name="wo_id" value="<%= w.getWo_id() %>">
                                                            <button type="submit" 
                                                                    class="flex items-center gap-1.5 rounded-xl bg-purple-50 px-3 py-2 text-xs font-semibold text-purple-600 transition-colors hover:bg-purple-100 hover:text-purple-700 dark:bg-purple-500/10 dark:text-purple-400"
                                                                    title="Báo cáo hoàn thành lệnh"
                                                                    onclick="return confirm('Xác nhận đã sản xuất xong toàn bộ số lượng?');">
                                                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                                                                <span>Báo cáo Xong</span>
                                                            </button>
                                                        </form>
                                                    <% } %>
                                                <% } %>

                                                <button type="button"
                                                        class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-blue-100 hover:text-blue-600 dark:text-slate-400 dark:hover:bg-blue-500/10 dark:hover:text-blue-300"
                                                        title="Xem chi tiết"
                                                        data-detail-wo-id="<%= w.getWo_id() %>"
                                                        data-detail-product-name="<%= getProductName(w, items) %>"
                                                        data-detail-product-id="<%= w.getProduct_item_id() %>"
                                                        data-detail-routing-name="<%= getRoutingName(w, routings) %>"
                                                        data-detail-routing-id="<%= w.getRouting_id() %>"
                                                        data-detail-quantity="<%= w.getOrder_quantity() %>"
                                                        data-detail-status="<%= w.getStatus() != null ? w.getStatus() : "New" %>"
                                                        data-detail-start-date="<%= formatDisplayDate(w.getStart_date()) %>"
                                                        data-detail-due-date="<%= formatDisplayDate(w.getDue_date()) %>"
                                                        onclick="openDetailModalFromButton(this)">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                                </button>

                                            </div>
                                        </td>
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

    <jsp:include page="mobile-nav.jsp" />

    <div id="addModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-3xl border border-slate-200 shadow-2xl dark:border-slate-700">
            <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Thêm lệnh sản xuất mới</h3>
                </div>
                <button onclick="closeAddModal()" class="rounded-xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
            
            <form action="WorkOrderController" method="post" class="space-y-5 p-6" onsubmit="return validateDates(this);">
                <input type="hidden" name="action" value="insert">
                
                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Sản phẩm</label>
                    <select name="product_item_id" required class="form-input">
                        <option value="">-- Chọn sản phẩm --</option>
                        <% for (ItemDTO item : items) { 
                            if (item.isProduct() || "SanPham".equalsIgnoreCase(item.getItemType())) {
                        %>
                        <option value="<%= item.getItemID() %>"><%= item.getItemName() %> (ID: <%= item.getItemID() %>)</option>
                        <%  } 
                           } %>
                    </select>
                </div>

                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Quy trình sản xuất</label>
                    <select name="routing_id" required class="form-input">
                        <option value="">-- Chọn quy trình --</option>
                        <% for (RoutingDTO r : routings) { %>
                        <option value="<%= r.getRoutingId() %>"><%= r.getRoutingName() %> (ID: <%= r.getRoutingId() %>)</option>
                        <% } %>
                    </select>
                </div>

                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng</label>
                    <input type="number" name="order_quantity" required min="1" class="form-input">
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Ngày bắt đầu</label>
                        <input type="datetime-local" name="start_date" required class="form-input">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Hạn chót</label>
                        <input type="datetime-local" name="due_date" required class="form-input">
                    </div>
                </div>

                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Trạng thái</label>
                    <input type="hidden" name="status" value="New">
                    <input type="text" value="Mới (Mặc định)" disabled class="form-input bg-slate-100 text-slate-500 cursor-not-allowed dark:bg-slate-800 dark:text-slate-400">
                </div>

                <div class="flex gap-3 pt-2">
                    <button type="submit" class="flex-1 rounded-2xl bg-teal-600 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">Tạo lệnh</button>
                    <button type="button" onclick="closeAddModal()" class="rounded-2xl border border-slate-200 px-6 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                </div>
            </form>
        </div>
    </div>

    <div id="editModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-3xl border border-slate-200 shadow-2xl dark:border-slate-700">
            <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div><h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Cập nhật lệnh sản xuất</h3></div>
                <button type="button" onclick="closeEditModal()" class="rounded-xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
            <form action="WorkOrderController" method="post" class="space-y-5 p-6" onsubmit="return validateDates(this);">
                <input type="hidden" name="action" value="update">
                <input type="hidden" id="edit_wo_id" name="wo_id" value="">
                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Sản phẩm</label>
                    <select id="edit_product_item_id" name="product_item_id" required class="form-input">
                        <option value="">-- Chọn sản phẩm --</option>
                        <% for (ItemDTO item : items) { 
                            if (item.isProduct() || "SanPham".equalsIgnoreCase(item.getItemType())) {
                        %>
                        <option value="<%= item.getItemID() %>"><%= item.getItemName() %> (ID: <%= item.getItemID() %>)</option>
                        <% } } %>
                    </select>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Quy trình sản xuất</label>
                    <select id="edit_routing_id" name="routing_id" required class="form-input">
                        <option value="">-- Chọn quy trình --</option>
                        <% for (RoutingDTO r : routings) { %>
                        <option value="<%= r.getRoutingId() %>"><%= r.getRoutingName() %> (ID: <%= r.getRoutingId() %>)</option>
                        <% } %>
                    </select>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng</label>
                    <input id="edit_order_quantity" type="number" name="order_quantity" required min="1" class="form-input">
                </div>
                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Ngày bắt đầu</label>
                        <input type="datetime-local" id="edit_start_date" name="start_date" required class="form-input">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Hạn chót</label>
                        <input type="datetime-local" id="edit_due_date" name="due_date" required class="form-input">
                    </div>
                </div>

                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Trạng thái</label>
                    <input type="hidden" id="edit_status_hidden" name="status" value="">
                    <input type="text" id="edit_status_display" value="" disabled 
                           class="form-input bg-slate-100 text-slate-500 cursor-not-allowed dark:bg-slate-800 dark:text-slate-400" 
                           title="Trạng thái được quản lý tự động bởi hệ thống">
                </div>
                
                <div class="flex gap-3 pt-2">
                    <button type="submit" class="flex-1 rounded-2xl bg-amber-600 py-3 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition-all hover:bg-amber-700">Lưu cập nhật</button>
                    <button type="button" onclick="closeEditModal()" class="rounded-2xl border border-slate-200 px-6 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                </div>
            </form>
        </div>
    </div>

    <div id="detailModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-3xl border border-slate-200 shadow-2xl dark:border-slate-700">
            <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div><h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Chi tiết lệnh sản xuất</h3></div>
                <button type="button" onclick="closeDetailModal()" class="rounded-xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
            <div class="grid gap-5 p-6 sm:grid-cols-2">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Mã lệnh</p>
                    <p id="detailWoId" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Trạng thái</p>
                    <p id="detailStatus" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Sản phẩm</p>
                    <p id="detailProductName" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Số lượng</p>
                    <p id="detailQuantity" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Ngày bắt đầu</p>
                    <p id="detailStartDate" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">Hạn chót</p>
                    <p id="detailDueDate" class="mt-2 text-base font-semibold text-slate-900 dark:text-slate-100"></p>
                </div>
            </div>
            <div class="flex justify-end border-t border-slate-200 px-6 py-5 dark:border-slate-700">
                <button type="button" onclick="closeDetailModal()" class="rounded-2xl border border-slate-200 px-6 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Đóng</button>
            </div>
        </div>
    </div>

    <div id="deleteWorkOrderModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start gap-4">
                <div class="flex-1">
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa lệnh sản xuất?</h3>
                </div>
            </div>
            <form action="WorkOrderController" method="post" class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" id="delete_wo_id" name="wo_id" value="">
                <button type="button" onclick="closeDeleteWorkOrderModal()" class="rounded-2xl border border-slate-200 px-6 py-3 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <button type="submit" class="rounded-2xl bg-rose-600 px-6 py-3 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition-all hover:bg-rose-700">Xóa lệnh</button>
            </form>
        </div>
    </div>
 
    <script>
        function validateDates(form) {
            const startDate = form.querySelector('[name="start_date"]').value;
            const dueDate = form.querySelector('[name="due_date"]').value;
            
            if (startDate && dueDate) {
                if (new Date(dueDate) < new Date(startDate)) {
                    alert("LỖI: Hạn chót (Due Date) không thể diễn ra trước Ngày bắt đầu (Start Date)!");
                    return false; 
                }
            }
            return true; 
        }

        function openAddModal() {
            document.getElementById('addModal').classList.remove('hidden');
            document.getElementById('addModal').classList.add('flex');

            let now = new Date();
            now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
            document.querySelector('#addModal input[name="start_date"]').value = now.toISOString().slice(0,16);
            
            let tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(0, 0, 0, 0); 
            tomorrow.setMinutes(tomorrow.getMinutes() - tomorrow.getTimezoneOffset());
            document.querySelector('#addModal input[name="due_date"]').value = tomorrow.toISOString().slice(0,16);
        }
        function closeAddModal() {
            document.getElementById('addModal').classList.add('hidden');
            document.getElementById('addModal').classList.remove('flex');
        }

        function openEditModal(woId, productId, routingId, quantity, status, startDate, dueDate) {
            document.getElementById('edit_wo_id').value = woId || '';
            document.getElementById('edit_product_item_id').value = productId || '';
            document.getElementById('edit_routing_id').value = routingId || '';
            document.getElementById('edit_order_quantity').value = quantity || '';
            
            // XỬ LÝ KHÓA TRẠNG THÁI HIỂN THỊ
            document.getElementById('edit_status_hidden').value = status || 'New';
            let statusText = 'Mới';
            if (status === 'WaitMaterial') statusText = 'Chờ vật tư';
            else if (status === 'Ready') statusText = 'Chờ SX';
            else if (status === 'In Progress' || status === 'InProgress') statusText = 'Đang sản xuất';
            else if (status === 'Done' || status === 'Completed') statusText = 'Hoàn thành';
            else if (status === 'Cancelled') statusText = 'Đã hủy';
            document.getElementById('edit_status_display').value = statusText + " (Hệ thống tự động)";
            // -----------------------------

            document.getElementById('edit_start_date').value = startDate || '';
            document.getElementById('edit_due_date').value = dueDate || '';
            
            document.getElementById('editModal').classList.remove('hidden');
            document.getElementById('editModal').classList.add('flex');
        }
        
        function openEditModalFromButton(button) {
            if (!button) return;
            openEditModal(
                button.getAttribute('data-wo-id'),
                button.getAttribute('data-product-id'),
                button.getAttribute('data-routing-id'),
                button.getAttribute('data-quantity'),
                button.getAttribute('data-status'),
                button.getAttribute('data-start-date'),
                button.getAttribute('data-due-date')
            );
        }
        function closeEditModal() {
            document.getElementById('editModal').classList.add('hidden');
            document.getElementById('editModal').classList.remove('flex');
        }

        function openDetailModalFromButton(button) {
            if (!button) return;
            document.getElementById('detailWoId').textContent = button.getAttribute('data-detail-wo-id') ? '#WO-' + button.getAttribute('data-detail-wo-id') : '-';
            document.getElementById('detailProductName').textContent = button.getAttribute('data-detail-product-name') || '-';
            document.getElementById('detailQuantity').textContent = button.getAttribute('data-detail-quantity') || '0';
            document.getElementById('detailStatus').textContent = button.getAttribute('data-detail-status') || 'New';
            document.getElementById('detailStartDate').textContent = button.getAttribute('data-detail-start-date') || 'Chưa xác định';
            document.getElementById('detailDueDate').textContent = button.getAttribute('data-detail-due-date') || 'Chưa xác định';
            
            document.getElementById('detailModal').classList.remove('hidden');
            document.getElementById('detailModal').classList.add('flex');
        }
        function closeDetailModal() {
            document.getElementById('detailModal').classList.add('hidden');
            document.getElementById('detailModal').classList.remove('flex');
        }

        function openDeleteWorkOrderModal(button) {
            if (!button) return;
            document.getElementById('delete_wo_id').value = button.getAttribute('data-wo-id') || '';
            const modal = document.getElementById('deleteWorkOrderModal');
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        }
        function closeDeleteWorkOrderModal() {
            const modal = document.getElementById('deleteWorkOrderModal');
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }
    </script>
</body>
</html>