<%@page import="pms.model.BOMDTO"%>
<%@page import="pms.model.BOMDetailDTO"%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="java.util.List"%>
<%@page import="pms.model.UserDTO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    // Trạng thái màu sắc
    String getStatusClass(String status) {
        if ("inactive".equalsIgnoreCase(status)) return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400";
        return "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
    }

    String getStatusText(String status) {
        if ("inactive".equalsIgnoreCase(status)) return "Ngừng sử dụng";
        return "Đang dùng";
    }
%>
<%
    List<BOMDTO> boms = (List<BOMDTO>) request.getAttribute("boms");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    
    // Lấy lại tham số tìm kiếm và bộ lọc
    String keyword = request.getParameter("keyword");
    String filterStatus = request.getParameter("status");
    
    if (boms == null) boms = new java.util.ArrayList<>();
    
    String userRole = user != null ? user.getRole() : "user";
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    
    // Thống kê KPI
    int totalBOM = boms.size();
    int activeCount = 0;
    int inactiveCount = 0;
    for (BOMDTO b : boms) {
        if ("inactive".equalsIgnoreCase(b.getStatus())) {
            inactiveCount++;
        } else {
            activeCount++; 
        }
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Công thức sản xuất (BOM) - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config = { darkMode: 'class' };</script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
        .form-input {
            width: 100%; border-radius: 1rem; border: 1px solid rgb(226 232 240);
            background: rgb(255 255 255 / 0.92); padding: 0.75rem 1rem; color: rgb(15 23 42); transition: all 0.2s ease;
        }
        .dark .form-input { border-color: rgb(51 65 85); background: rgb(15 23 42 / 0.75); color: rgb(241 245 249); }
        .form-input:focus { border-color: #0d9488; box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1); outline: none; }
        .kpi-card { position: relative; overflow: hidden; }
        .section-card { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(14px); }
        .dark .section-card { background: rgba(15, 23, 42, 0.88); }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .sidebar-header { position: sticky; top: 0; background: #0f172a; z-index: 10; }
        .sidebar-nav { flex: 1; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
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
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Định mức vật tư (BOM)</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Quản lý công thức sản xuất và cấu trúc nguyên liệu</p>
                    </div>
                    <% if (isAdmin) { %>
                    <a href="MainController?action=addBOM" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                        Thêm BOM mới
                    </a>
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

                <div class="mb-6 grid gap-4 sm:grid-cols-3">
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tổng công thức</p>
                                <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= totalBOM %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-300">
                                <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đang sử dụng</p>
                                <p class="mt-3 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= activeCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-300">
                                <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-slate-400 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Ngừng sử dụng</p>
                                <p class="mt-3 text-3xl font-bold text-slate-600 dark:text-slate-400"><%= inactiveCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400">
                                <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-5 shadow-sm dark:border-slate-700">
                    <form action="MainController" method="get" class="grid gap-4 md:grid-cols-[1fr_200px_auto] lg:items-center">
                        <input type="hidden" name="action" value="searchBOM"> <div class="relative">
                            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>" placeholder="Nhập tên sản phẩm hoặc mã BOM..." class="form-input pl-11">
                            <svg class="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                            </svg>
                        </div>
                        
                        <select name="status" class="form-input">
                            <option value="">Tất cả trạng thái</option>
                            <option value="active" <%= "active".equals(filterStatus) ? "selected" : "" %>>Đang dùng</option>
                            <option value="inactive" <%= "inactive".equals(filterStatus) ? "selected" : "" %>>Ngừng sử dụng</option>
                        </select>

                        <button type="submit" class="rounded-2xl bg-teal-600 px-6 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">Tìm kiếm</button>
                    </form>
                </div>

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                        <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách Công thức</h2>
                        <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                            Tổng: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= boms.size() %></span>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Mã BOM</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Sản phẩm</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Trạng thái</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Hành động</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <% if (boms.isEmpty()) { %>
                                <tr>
                                    <td colspan="4" class="px-6 py-14 text-center text-slate-500 dark:text-slate-400">Không tìm thấy công thức BOM nào.</td>
                                </tr>
                                <% } else { %>
                                    <% for (BOMDTO b : boms) { %>
                                    <tr class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-700 dark:bg-teal-500/10 dark:text-teal-300">#BOM-<%= b.getBomId() %></span>
                                            <% if(b.getBomVersion() != null && !b.getBomVersion().isEmpty()) { %>
                                                <p class="mt-1 text-[11px] text-slate-400">Ver: <%= b.getBomVersion() %></p>
                                            <% } %>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <p class="font-semibold text-slate-800 dark:text-slate-100"><%= b.getProductName() != null ? b.getProductName() : "Sản phẩm #" + b.getProductItemId() %></p>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <span class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold <%= getStatusClass(b.getStatus()) %>">
                                                <% if ("inactive".equalsIgnoreCase(b.getStatus())) { %>
                                                    <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
                                                <% } else { %>
                                                    <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                                <% } %>
                                                <%= getStatusText(b.getStatus()) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex items-center justify-center gap-2">
                                                <a href="MainController?action=viewBOM&id=<%= b.getBomId() %>" class="rounded-xl p-2 text-slate-500 hover:bg-blue-100 hover:text-blue-600 transition-colors" title="Chi tiết">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                                </a>
                                                <% if (isAdmin) { %>
                                                <a href="MainController?action=editBOM&id=<%= b.getBomId() %>" class="rounded-xl p-2 text-slate-500 hover:bg-amber-100 hover:text-amber-600 transition-colors" title="Sửa">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                                                </a>
                                                <a href="MainController?action=deleteBOM&id=<%= b.getBomId() %>" onclick="return confirm('Bạn có chắc chắn muốn xóa BOM này? Thao tác không thể phục hồi.');" class="rounded-xl p-2 text-slate-500 hover:bg-red-100 hover:text-red-600 transition-colors" title="Xóa">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                                </a>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <%-- <jsp:include page="components/bom-modals.jsp" /> (hoặc các form tương tự) --%>
            </main>
        </div>
    </div>
</body>
</html>