<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="pms.model.BOMDTO"%>
<%@page import="pms.model.BOMDetailDTO"%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="java.util.List"%>
<%@page import="pms.model.UserDTO"%>
<%!
    // Trạng thái màu sắc
    String getStatusClass(String status) {
        if ("inactive".equalsIgnoreCase(status)) {
            return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400";
        }
        return "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
    }

    String getStatusText(String status) {
        if ("inactive".equalsIgnoreCase(status)) {
            return "Ngừng sử dụng";
        }
        return "Đang dùng";
    }
%>
<%
    List<BOMDTO> boms = (List<BOMDTO>) request.getAttribute("boms");
    List<ItemDTO> products = (List<ItemDTO>) request.getAttribute("products");
    List<ItemDTO> materials = (List<ItemDTO>) request.getAttribute("materials");
    UserDTO user = (UserDTO) session.getAttribute("user");

    // Flash message từ session (sau redirect)
    String flashMsg = (String) session.getAttribute("flashMsg");
    String flashError = (String) session.getAttribute("flashError");
    if (flashMsg != null) {
        request.setAttribute("msg", flashMsg);
        session.removeAttribute("flashMsg");
    }
    if (flashError != null) {
        request.setAttribute("error", flashError);
        session.removeAttribute("flashError");
    }

    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");

    // Lấy lại tham số tìm kiếm và bộ lọc
    String keyword = request.getParameter("keyword");
    String filterStatus = request.getParameter("status");

    if (boms == null) {
        boms = new java.util.ArrayList<>();
    }
    if (products == null) {
        products = new java.util.ArrayList<>();
    }
    if (materials == null) {
        materials = new java.util.ArrayList<>();
    }

    String userRole = user != null ? user.getRole() : "user";
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    // Thống kê KPI
    int totalBOM = boms.size();
    int activeCount = 0, inactiveCount = 0;
    for (BOMDTO b : boms) {
        if ("inactive".equalsIgnoreCase(b.getStatus())) {
            inactiveCount++;
        } else {
            activeCount++;
        }
    }
%>
<!DOCTYPE html>
<html lang="<%= lang%>" class="<%= isDarkMode ? "dark" : ""%>">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Công thức sản xuất (BOM) - PMS</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script>tailwind.config = {darkMode: 'class'};</script>
        <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
        <style>
            body {
                font-family: Inter, "Segoe UI", Arial, sans-serif;
            }
            .sidebar {
                box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16);
            }
            .sidebar-overlay {
                position: fixed;
                inset: 0;
                background: rgba(15, 23, 42, 0.48);
                z-index: 20;
            }
            .form-input {
                width: 100%;
                border-radius: 1rem;
                border: 1px solid rgb(226 232 240);
                background: rgb(255 255 255 / 0.92);
                padding: 0.75rem 1rem;
                color: rgb(15 23 42);
                transition: all 0.2s ease;
            }
            .dark .form-input {
                border-color: rgb(51 65 85);
                background: rgb(15 23 42 / 0.75);
                color: rgb(241 245 249);
            }
            .form-input:focus {
                border-color: #0d9488;
                box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1);
                outline: none;
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
            .main-wrapper {
                margin-left: 0;
                transition: margin-left 0.3s ease;
            }
            @media (min-width: 1024px) {
                .main-wrapper {
                    margin-left: 280px;
                }
            }
            /* Toggle switch */
            .toggle-switch {
                position: relative;
                display: inline-block;
                width: 48px;
                height: 26px;
            }
            .toggle-switch input {
                opacity: 0;
                width: 0;
                height: 0;
            }
            .toggle-slider {
                position: absolute;
                cursor: pointer;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background-color: #e2e8f0;
                border-radius: 26px;
                transition: .3s;
            }
            .toggle-slider:before {
                position: absolute;
                content: "";
                height: 18px;
                width: 18px;
                left: 4px;
                bottom: 4px;
                background-color: white;
                border-radius: 50%;
                transition: .3s;
                box-shadow: 0 1px 4px rgba(0,0,0,.2);
            }
            input:checked + .toggle-slider {
                background-color: #ef4444;
            }
            input:checked + .toggle-slider:before {
                transform: translateX(22px);
            }
            .dark .toggle-slider {
                background-color: #334155;
            }
            /* Material row separator */
            .bom-material-row + .bom-material-row {
                border-top: 1px dashed rgba(148,163,184,0.35);
                padding-top: 1rem;
                margin-top: 1rem;
            }
        </style>
        <script src="js/common.js"></script>
    </head>
    <body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark dark-mode-init" : ""%>">
        <div class="min-h-screen flex">
            <jsp:include page="components/shared-sidebar.jsp" />

            <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
                <jsp:include page="components/shared-header.jsp" />

                <main class="flex-1 overflow-y-auto bg-slate-100 p-4 dark:bg-slate-900 sm:p-6 lg:p-8">
                    <!-- Page Header -->
                    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                        <div>
                            <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Định mức vật tư (BOM)</h1>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Quản lý công thức sản xuất và cấu trúc nguyên liệu</p>
                        </div>
                        <% if (isAdmin) { %>
                        <button type="button" id="btnAddBOM" onclick="openBomModal('add')"
                                class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700 hover:-translate-y-0.5">
                            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                            Thêm BOM mới
                        </button>
                        <% } %>
                    </div>

                    <!-- Alerts -->
                    <% if (msg != null && !msg.trim().isEmpty()) {%>
                    <div id="alertSuccess" class="mb-6 flex items-center gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300">
                        <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                        <%= msg%>
                    </div>
                    <% } %>
                    <% if (error != null && !error.trim().isEmpty()) {%>
                    <div class="mb-6 flex items-center gap-3 rounded-2xl border border-red-200 bg-red-50 px-4 py-4 text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                        <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                        <%= error%>
                    </div>
                    <% }%>

                    <!-- KPI Cards -->
                    <div class="mb-6 grid gap-4 sm:grid-cols-3">
                        <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <div class="flex items-start justify-between gap-4">
                                <div>
                                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tổng công thức</p>
                                    <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= totalBOM%></p>
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
                                    <p class="mt-3 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= activeCount%></p>
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
                                    <p class="mt-3 text-3xl font-bold text-slate-600 dark:text-slate-400"><%= inactiveCount%></p>
                                </div>
                                <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400">
                                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Search / Filter -->
                    <div class="section-card mb-6 rounded-3xl border border-slate-200 p-5 shadow-sm dark:border-slate-700">
                        <form action="MainController" method="get" class="grid gap-4 md:grid-cols-[1fr_200px_auto] lg:items-center">
                            <input type="hidden" name="action" value="searchBOM">
                            <div class="relative">
                                <input type="text" name="keyword" value="<%= keyword != null ? keyword : ""%>" placeholder="Nhập tên sản phẩm hoặc mã BOM..." class="form-input pl-11">
                                <svg class="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                                </svg>
                            </div>
                            <select name="status" class="form-input">
                                <option value="">Tất cả trạng thái</option>
                                <option value="active" <%= "active".equals(filterStatus) ? "selected" : ""%>>Đang dùng</option>
                                <option value="inactive" <%= "inactive".equals(filterStatus) ? "selected" : ""%>>Ngừng sử dụng</option>
                            </select>
                            <button type="submit" class="rounded-2xl bg-teal-600 px-6 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">Tìm kiếm</button>
                        </form>
                    </div>

                    <!-- BOM Table -->
                    <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                        <div class="flex items-center justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách Công thức</h2>
                            <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                                Tổng: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= boms.size()%></span>
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
                                <% 
                                // DÒNG QUAN TRỌNG NHẤT HAY BỊ XÓA NHẦM:
                                for (BOMDTO b : boms) { 
                                    
                                    // Build JSON của details để truyền vào modal
                                    StringBuilder detailsJson = new StringBuilder("[");
                                    if (b.getDetails() != null && !b.getDetails().isEmpty()) {
                                        for (int di = 0; di < b.getDetails().size(); di++) {
                                            BOMDetailDTO d = b.getDetails().get(di);
                                            if (di > 0) detailsJson.append(",");
                                            
                                            // Format an toàn tuyệt đối cho JSON
                                            String safeNotes = "";
                                            if (d.getNotes() != null) {
                                                safeNotes = d.getNotes()
                                                    .replace("\\", "\\\\")   // Xử lý dấu gạch chéo ngược
                                                    .replace("\"", "\\\"")   // Xử lý nháy kép
                                                    .replace("\n", "\\n")    // Xử lý xuống dòng
                                                    .replace("\r", "");      // Xử lý carriage return
                                            }

                                            detailsJson.append("{")
                                                .append("\"materialItemId\":").append(d.getMaterialItemId()).append(",")
                                                .append("\"quantityRequired\":").append(d.getQuantityRequired()).append(",")
                                                .append("\"notes\":\"").append(safeNotes).append("\"")
                                                .append("}");
                                        }
                                    }
                                    detailsJson.append("]");
                                %>
                                <tr class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-700 dark:bg-teal-500/10 dark:text-teal-300">#BOM-<%= b.getBomId()%></span>
                                            <% if (b.getBomVersion() != null && !b.getBomVersion().isEmpty()) {%>
                                            <p class="mt-1 text-[11px] text-slate-400">Ver: <%= b.getBomVersion()%></p>
                                            <% }%>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <p class="font-semibold text-slate-800 dark:text-slate-100"><%= b.getProductName() != null ? b.getProductName() : "Sản phẩm #" + b.getProductItemId()%></p>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <span class="inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold <%= getStatusClass(b.getStatus())%>">
                                                <% if ("inactive".equalsIgnoreCase(b.getStatus())) { %>
                                                <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
                                                <% } else { %>
                                                <svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                                <% }%>
                                                <%= getStatusText(b.getStatus())%>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex items-center justify-center gap-2">
                                                <!-- Xem chi tiết -->
                                                <a href="MainController?action=viewBOM&id=<%= b.getBomId()%>"
                                                   class="rounded-xl p-2 text-slate-500 hover:bg-blue-100 hover:text-blue-600 transition-colors" title="Chi tiết">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                                </a>
                                                <% if (isAdmin) {%>
                                                <!-- Sửa BOM (mở Modal) -->
                                                <button type="button"
                                                        class="rounded-xl p-2 text-slate-500 hover:bg-amber-100 hover:text-amber-600 transition-colors"
                                                        title="Sửa"
                                                        data-bom-id="<%= b.getBomId()%>"
                                                        data-bom-product-id="<%= b.getProductItemId()%>"
                                                        data-bom-notes="<%= b.getNotes() != null ? b.getNotes().replace("\"", "&quot;").replace("'", "&#39;").replace("\n", " ").replace("\r", "") : ""%>"
                                                        data-bom-status="<%= b.getStatus() != null ? b.getStatus() : "active"%>"
                                                        data-bom-details='<%= detailsJson.toString().replace("'", "&#39;") %>'
                                                        onclick="openBomModal('edit', this)">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                                                </button>
                                                <!-- Xóa BOM -->
                                                <button type="button"
                                                        class="rounded-xl p-2 text-slate-500 hover:bg-red-100 hover:text-red-600 transition-colors"
                                                        title="Xóa"
                                                        data-bom-id="<%= b.getBomId()%>"
                                                        data-bom-name="BOM #<%= b.getBomId()%> – <%= b.getProductName() != null ? b.getProductName() : "SP #" + b.getProductItemId()%>"
                                                        onclick="openDeleteBomModal(this)">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                                </button>
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
                </main>
            </div>
        </div>

        <!-- =====================================================================
             MODAL: Thêm / Sửa BOM  (Task 1 + Task 2)
             ===================================================================== -->
        <div id="bomModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
            <div class="w-full max-w-2xl max-h-[95vh] flex flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">

                <!-- Header Modal -->
                <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                    <div>
                        <p id="bomModalBadge" class="text-xs font-semibold uppercase tracking-[0.24em] text-teal-600 dark:text-teal-300">Tạo mới</p>
                        <h3 id="bomModalTitle" class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Thêm BOM mới</h3>
                        <p id="bomModalSubtitle" class="mt-1 text-sm text-slate-500 dark:text-slate-400">Thiết lập định mức vật tư cho sản phẩm ngay trên trang danh sách.</p>
                    </div>
                    <button type="button" onclick="closeBomModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
                    </button>
                </div>

                <!-- Form Body -->
                <form id="bomForm" action="BOMController" method="post" class="flex-1 overflow-y-auto px-6 py-6 space-y-5">
                    <input type="hidden" id="bomFormAction" name="action" value="saveAddBOM">
                    <input type="hidden" id="bomFormId"     name="id"     value="">

                    <!-- Sản phẩm -->
                    <div>
                        <label for="bom_productItemId" class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">
                            Sản phẩm áp dụng <span class="text-red-500">*</span>
                        </label>
                        <select id="bom_productItemId" name="productItemId" required
                                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100">
                            <option value="">-- Chọn sản phẩm --</option>
                            <% for (ItemDTO p : products

                                
                                    ) {%>
                            <option value="<%= p.getItemID()%>"><%= p.getItemName()%></option>
                            <% } %>
                        </select>
                    </div>

                    <!-- Ghi chú -->
                    <div>
                        <label for="bom_notes" class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Ghi chú</label>
                        <textarea id="bom_notes" name="notes" rows="3" placeholder="Nhập ghi chú cho BOM (nếu có)"
                                  class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:focus:border-teal-400"></textarea>
                    </div>

                    <!-- ===== Task 2: Toggle Ngừng sử dụng ===== -->
                    <div class="flex items-center justify-between rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800/60">
                        <div>
                            <p class="text-sm font-semibold text-slate-700 dark:text-slate-200">Ngừng sử dụng</p>
                            <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">BOM sẽ bị ẩn khỏi màn hình tạo Lệnh Sản Xuất nhưng vẫn lưu trong hệ thống</p>
                        </div>
                        <label class="toggle-switch flex-shrink-0">
                            <input type="checkbox" id="bom_inactive_toggle" onchange="updateBomStatus(this)">
                            <span class="toggle-slider"></span>
                        </label>
                        <!-- Hidden field thực sự gửi status -->
                        <input type="hidden" id="bom_status" name="status" value="active">
                    </div>

                    <!-- Nguyên liệu cấu thành -->
                    <div class="rounded-3xl border border-slate-200/80 bg-slate-50/70 p-5 dark:border-slate-700 dark:bg-slate-900/40">
                        <div class="mb-4 flex items-center justify-between gap-3">
                            <div>
                                <h4 class="text-sm font-semibold text-slate-900 dark:text-slate-100">Nguyên liệu cấu thành</h4>
                                <p class="mt-1 text-xs text-slate-500 dark:text-slate-400">Khai báo vật tư và số lượng cần thiết.</p>
                            </div>
                            <button type="button" onclick="addBomMaterialRow()"
                                    class="inline-flex items-center gap-1.5 rounded-2xl border border-teal-200 bg-white px-3 py-2 text-xs font-semibold text-teal-700 transition hover:bg-teal-50 dark:border-teal-500/30 dark:bg-slate-800 dark:text-teal-300 dark:hover:bg-slate-700">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                                Thêm nguyên liệu
                            </button>
                        </div>
                        <div id="bomMaterialRows" class="space-y-3"></div>
                    </div>

                    <!-- Actions -->
                    <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                        <button type="button" onclick="closeBomModal()"
                                class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-5 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                            Hủy
                        </button>
                        <button type="submit" id="bomFormSubmitBtn"
                                class="inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition hover:bg-teal-700">
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            Lưu BOM
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Template ẩn: một dòng nguyên liệu (dùng JS clone) -->
        <template id="bomMaterialRowTpl">
            <div class="bom-material-row rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800/70">
                <div class="mb-3 flex items-center justify-between gap-3">
                    <p class="text-xs font-semibold text-slate-700 dark:text-slate-200">Nguyên liệu mới</p>
                    <button type="button" onclick="removeBomMaterialRow(this)"
                            class="rounded-xl border border-rose-200 px-3 py-1.5 text-xs font-semibold text-rose-600 hover:bg-rose-50 dark:border-rose-500/30 dark:text-rose-300 dark:hover:bg-rose-500/10">
                        Xóa
                    </button>
                </div>
                <div class="grid gap-3 md:grid-cols-2">
                    <div>
                        <label class="mb-1.5 block text-xs font-semibold text-slate-600 dark:text-slate-300">Nguyên liệu <span class="text-red-500">*</span></label>
                        <select name="materialItemId[]" required data-material-select="true"
                                class="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-teal-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100">
                            <option value="">-- Chọn nguyên liệu --</option>
                        </select>
                    </div>
                    <div>
                        <label class="mb-1.5 block text-xs font-semibold text-slate-600 dark:text-slate-300">Số lượng <span class="text-red-500">*</span></label>
                        <input type="number" step="1" min="1" name="quantityRequired[]" required placeholder="Ví dụ: 2"
                               class="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-teal-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100">
                    </div>
                    <div class="md:col-span-2">
                        <label class="mb-1.5 block text-xs font-semibold text-slate-600 dark:text-slate-300">Ghi chú dòng</label>
                        <input type="text" name="detailNotes[]" placeholder="Ví dụ: cắt dư 2%, dùng loại A"
                               class="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-teal-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100">
                    </div>
                </div>
            </div>
        </template>

        <!-- JSON dữ liệu materials từ server (tách khỏi script block để tránh lỗi lint JSP) -->
        <script id="materialsJson" type="application/json">
            [<% for (int mi = 0;

                mi< materials.size ();
                mi

                
                    ++) {
                    ItemDTO m = materials.get(mi);%>{"id":<%= m.getItemID()%>,"name":"<%= m.getItemName() != null ? m.getItemName().replace("\\", "\\\\").replace("\"", "\\\"") : ""%>"}<%= mi < materials.size() - 1 ? "," : ""%><% }%>]
        </script>

        <!-- =====================================================================
             MODAL: Xác nhận Xóa BOM
             ===================================================================== -->
        <div id="deleteBomModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
            <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
                <div class="flex items-start gap-4">
                    <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                        <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/></svg>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                        <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa BOM?</h3>
                        <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteBomName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác <strong>không thể hoàn tác</strong>.</p>
                    </div>
                </div>
                <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeDeleteBomModal()"
                            class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-5 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                    <a id="deleteBomConfirmBtn" href="#"
                       class="inline-flex items-center justify-center rounded-2xl bg-rose-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 hover:bg-rose-700">Xóa BOM</a>
                </div>
            </div>
        </div>

        <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>

        <!-- =====================================================================
             JavaScript: Modal Logic (Tasks 1 & 2)
             ===================================================================== -->
        <script>
            // #region agent log
            function agentLog(hypothesisId, location, message, data) {
                try {
                    fetch('http://127.0.0.1:7640/ingest/264e58ca-4f2d-4319-a4ac-e8276b74978c', {
                        method: 'POST',
                        headers: {'Content-Type': 'application/json', 'X-Debug-Session-Id': 'e3273a'},
                        body: JSON.stringify({
                            sessionId: 'e3273a',
                            runId: 'pre-fix',
                            hypothesisId: hypothesisId,
                            location: location,
                            message: message,
                            data: data || {},
                            timestamp: Date.now()
                        })
                    }).catch(function () {});
                } catch (e) {
                }
            }
            // #endregion

            // #region agent console log
            function agentConsole(label, payload) {
                try {
                    console.log('[BOM_ADMIN_DEBUG]', label, payload);
                } catch (e) {
                }
            }
            // #endregion

            // ---- Dữ liệu materials từ server ----
            const MATERIALS_DATA = JSON.parse(document.getElementById('materialsJson').textContent || '[]');

            // ---- Tạo option HTML cho dropdown nguyên liệu ----
            function buildMaterialOptions(selectedId) {
                return MATERIALS_DATA.map(function (m) {
                    var sel = (m.id === selectedId) ? ' selected' : '';
                    return '<option value="' + m.id + '"' + sel + '>' + m.name + '</option>';
                }).join('');
            }

            // ---- Thêm dòng nguyên liệu ----
            function addBomMaterialRow(materialId, quantity, notes) {
                const tpl = document.getElementById('bomMaterialRowTpl');
                const cont = document.getElementById('bomMaterialRows');
                const temp = document.createElement('div');
                temp.innerHTML = tpl.innerHTML;
                const row = temp.firstElementChild;
                // Populate select với danh sách materials
                const sel = row.querySelector('select[data-material-select]');
                if (sel) {
                    sel.innerHTML = '<option value="">-- Chọn nguyên liệu --</option>' + buildMaterialOptions(materialId || 0);
                }
                if (quantity !== undefined && quantity !== null)
                    row.querySelector('input[name="quantityRequired[]"]').value = Math.round(quantity);
                if (notes !== undefined && notes !== null)
                    row.querySelector('input[name="detailNotes[]"]').value = notes;
                cont.appendChild(row);
                updateBomMaterialTitles();
            }

            // ---- Xóa dòng nguyên liệu ----
            function removeBomMaterialRow(btn) {
                const cont = document.getElementById('bomMaterialRows');
                const rows = cont.querySelectorAll('.bom-material-row');
                if (rows.length <= 1) {
                    // Xóa trắng thay vì xóa hàng
                    rows[0].querySelectorAll('input, select').forEach(el => {
                        if (el.type !== 'submit')
                            el.value = '';
                    });
                } else {
                    btn.closest('.bom-material-row').remove();
                }
                updateBomMaterialTitles();
            }

            // ---- Cập nhật tiêu đề dòng nguyên liệu ----
            function updateBomMaterialTitles() {
                document.querySelectorAll('#bomMaterialRows .bom-material-row').forEach((row, idx) => {
                    const title = row.querySelector('p.font-semibold');
                    if (title)
                        title.textContent = 'Nguyên liệu #' + (idx + 1);
                });
            }

            // ---- Toggle Ngừng sử dụng (Task 2) ----
            function updateBomStatus(checkbox) {
                document.getElementById('bom_status').value = checkbox.checked ? 'inactive' : 'active';
            }

            // ---- Mở Modal Add / Edit ----
            function openBomModal(mode, btn) {
                const modal = document.getElementById('bomModal');
                const badge = document.getElementById('bomModalBadge');
                const title = document.getElementById('bomModalTitle');
                const subtitle = document.getElementById('bomModalSubtitle');
                const formAction = document.getElementById('bomFormAction');
                const formId = document.getElementById('bomFormId');
                const submitBtn = document.getElementById('bomFormSubmitBtn');
                const cont = document.getElementById('bomMaterialRows');

                // Reset form
                document.getElementById('bomForm').reset();
                cont.innerHTML = '';
                document.getElementById('bom_status').value = 'active';
                document.getElementById('bom_inactive_toggle').checked = false;

                if (mode === 'add') {
                    // #region agent log
                    agentLog('H1', 'bom-list.jsp:openBomModal:add', 'open add modal', {mode: mode});
                    // #endregion
                    badge.textContent = 'Tạo mới';
                    badge.className = 'text-xs font-semibold uppercase tracking-[0.24em] text-teal-600 dark:text-teal-300';
                    title.textContent = 'Thêm BOM mới';
                    subtitle.textContent = 'Thiết lập định mức vật tư cho sản phẩm ngay trên trang danh sách.';
                    formAction.value = 'saveAddBOM';
                    formId.value = '';
                    submitBtn.textContent = 'Lưu BOM mới';
                    submitBtn.className = 'inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition hover:bg-teal-700';
                    // Thêm 1 dòng trống
                    addBomMaterialRow();
                } else if (mode === 'edit' && btn) {
                    const bomId = btn.getAttribute('data-bom-id');
                    const productId = parseInt(btn.getAttribute('data-bom-product-id'));
                    const notes = btn.getAttribute('data-bom-notes');
                    const status = btn.getAttribute('data-bom-status');
                    let   details = [];
                    try {
                        details = JSON.parse(btn.getAttribute('data-bom-details') || '[]');
                    } catch (e) {
                    }

                    // #region agent log
                    agentLog('H2', 'bom-list.jsp:openBomModal:edit:dataset', 'open edit modal dataset', {
                        bomId: bomId,
                        productId: productId,
                        status: status,
                        notesLen: notes ? notes.length : 0,
                        detailsLen: details ? details.length : 0,
                        sampleQty: (details && details[0]) ? details[0].quantityRequired : null
                    });
                    // #endregion

                    // #region agent console log
                    agentConsole('openEdit.dataset', {
                        bomId: bomId,
                        productId: productId,
                        status: status,
                        notesLen: notes ? notes.length : 0,
                        detailsLen: details ? details.length : 0,
                        sample0: details && details[0] ? details[0] : null
                    });
                    // #endregion

                    badge.textContent = 'Cập nhật';
                    badge.className = 'text-xs font-semibold uppercase tracking-[0.24em] text-amber-600 dark:text-amber-300';
                    title.textContent = 'Sửa BOM #' + bomId;
                    subtitle.textContent = 'Chỉnh sửa thông tin và danh sách vật tư của BOM này.';
                    formAction.value = 'saveUpdateBOM';
                    formId.value = bomId;
                    submitBtn.innerHTML = '<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg> Lưu thay đổi';
                    submitBtn.className = 'inline-flex items-center justify-center gap-2 rounded-2xl bg-amber-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition hover:bg-amber-700';

                    // Điền dữ liệu BOM
                    document.getElementById('bom_productItemId').value = productId;
                    document.getElementById('bom_notes').value = notes || '';

                    // Task 2: Set trạng thái toggle
                    const isInactive = status === 'inactive';
                    document.getElementById('bom_inactive_toggle').checked = isInactive;
                    document.getElementById('bom_status').value = status || 'active';

                    // Điền nguyên liệu
                    if (details.length > 0) {
                        details.forEach(d => addBomMaterialRow(d.materialItemId, d.quantityRequired, d.notes));
                    } else {
                        addBomMaterialRow();
                    }

                    // #region agent log
                    try {
                        const qtyDom = Array.from(document.querySelectorAll('#bomMaterialRows input[name="quantityRequired[]"]')).map(i => i.value);
                        agentLog('H3', 'bom-list.jsp:openBomModal:edit:afterFill', 'after fill DOM', {
                            bomId: bomId,
                            qty0: qtyDom[0] || null,
                            qtyValues: qtyDom.slice(0, 10)
                        });
                    } catch (e2) {
                    }
                    // #endregion

                    // #region agent console log
                    try {
                        const qtyDom = Array.from(document.querySelectorAll('#bomMaterialRows input[name="quantityRequired[]"]')).map(i => i.value);
                        const matDom = Array.from(document.querySelectorAll('#bomMaterialRows select[name="materialItemId[]"]')).map(s => s.value);
                        agentConsole('openEdit.afterFill.dom', {bomId: bomId, mat0: matDom[0] || null, qty0: qtyDom[0] || null, qtyValues: qtyDom.slice(0, 10)});
                    } catch (e3) {
                    }
                    // #endregion
                }

                modal.classList.remove('hidden');
                modal.classList.add('flex');
                document.body.classList.add('overflow-hidden');
            }

            // ---- Đóng Modal BOM ----
            function closeBomModal() {
                const modal = document.getElementById('bomModal');
                modal.classList.add('hidden');
                modal.classList.remove('flex');
                const deleteBomModal = document.getElementById('deleteBomModal');
                if (!deleteBomModal || deleteBomModal.classList.contains('hidden')) {
                    document.body.classList.remove('overflow-hidden');
                }
            }

            // ---- Modal Xóa BOM ----
            function openDeleteBomModal(btn) {
                const modal = document.getElementById('deleteBomModal');
                const nameEl = document.getElementById('deleteBomName');
                const linkEl = document.getElementById('deleteBomConfirmBtn');
                const bomId = btn.getAttribute('data-bom-id');
                nameEl.textContent = btn.getAttribute('data-bom-name') || ('BOM #' + bomId);
                linkEl.href = 'BOMController?action=deleteBOM&id=' + bomId;
                modal.classList.remove('hidden');
                modal.classList.add('flex');
                document.body.classList.add('overflow-hidden');
            }

            function closeDeleteBomModal() {
                const modal = document.getElementById('deleteBomModal');
                modal.classList.add('hidden');
                modal.classList.remove('flex');
                document.body.classList.remove('overflow-hidden');
            }

            // ---- Đóng khi click backdrop ----
            document.getElementById('bomModal').addEventListener('click', function (e) {
                if (e.target === this)
                    closeBomModal();
            });
            document.getElementById('deleteBomModal').addEventListener('click', function (e) {
                if (e.target === this)
                    closeDeleteBomModal();
            });

            // ---- Đóng khi nhấn Escape ----
            document.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') {
                    const bomModal = document.getElementById('bomModal');
                    const delModal = document.getElementById('deleteBomModal');
                    if (bomModal && bomModal.classList.contains('flex'))
                        closeBomModal();
                    if (delModal && delModal.classList.contains('flex'))
                        closeDeleteBomModal();
                }
            });

            // ---- Validate: ít nhất 1 nguyên liệu ----
            document.getElementById('bomForm').addEventListener('submit', function (e) {
                const rows = document.querySelectorAll('#bomMaterialRows .bom-material-row');
                let valid = false;
                rows.forEach(row => {
                    const sel = row.querySelector('select[name="materialItemId[]"]');
                    const qty = row.querySelector('input[name="quantityRequired[]"]');
                    if (sel && sel.value && qty && qty.value)
                        valid = true;
                });
                if (!valid) {
                    e.preventDefault();
                    alert('Vui lòng thêm ít nhất một nguyên liệu với đầy đủ thông tin!');
                }

                // #region agent log
                try {
                    const action = document.getElementById('bomFormAction').value;
                    const bomId = document.getElementById('bomFormId').value;
                    const qtyValues = Array.from(document.querySelectorAll('#bomMaterialRows input[name="quantityRequired[]"]')).map(i => i.value);
                    agentLog('H4', 'bom-list.jsp:bomForm:submit', 'submit bom form DOM', {
                        action: action,
                        id: bomId,
                        qtyValues: qtyValues.slice(0, 10)
                    });
                } catch (err) {
                }
                // #endregion

                // #region agent console log
                try {
                    const action = document.getElementById('bomFormAction').value;
                    const bomId = document.getElementById('bomFormId').value;
                    const productId = document.getElementById('bom_productItemId').value;
                    const status = document.getElementById('bom_status').value;
                    const qtyValues = Array.from(document.querySelectorAll('#bomMaterialRows input[name="quantityRequired[]"]')).map(i => i.value);
                    const matValues = Array.from(document.querySelectorAll('#bomMaterialRows select[name="materialItemId[]"]')).map(s => s.value);
                    agentConsole('submit.dom', {action: action, id: bomId, productId: productId, status: status, mat0: matValues[0] || null, qty0: qtyValues[0] || null, qtyValues: qtyValues.slice(0, 10)});
                } catch (err2) {
                }
                // #endregion
            });

            // ---- Auto-dismiss alert sau 4 giây ----
            setTimeout(function () {
                const el = document.getElementById('alertSuccess');
                if (el)
                    el.style.transition = 'opacity 0.5s', el.style.opacity = '0', setTimeout(() => el.remove(), 500);
            }, 4000);
        </script>
    </body>
</html>