<%@page import="pms.model.RoutingStepDTO"%>
<%@page import="java.util.List"%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<RoutingStepDTO> listStep = (List<RoutingStepDTO>) request.getAttribute("listStep");
    RoutingStepDTO stepEdit = (RoutingStepDTO) request.getAttribute("stepEdit");
    UserDTO user = (UserDTO) session.getAttribute("user");
    boolean isEditMode = (stepEdit != null);
    String msg = request.getAttribute("msg") != null ? (String) request.getAttribute("msg") : request.getParameter("msg");
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    String keyword = request.getAttribute("keyword") != null ? (String) request.getAttribute("keyword") : "";
    String searchRoutingId = request.getAttribute("searchRoutingId") != null ? (String) request.getAttribute("searchRoutingId") : "";
    
    if (listStep == null) listStep = new java.util.ArrayList<>();
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.length() > 0 ? userName.substring(0, 1).toUpperCase() : "U";
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    int totalSteps = listStep.size();
    int qcCount = 0;
    for (RoutingStepDTO s : listStep) {
        if (s.isIsInspected()) qcCount++;
    }

    String activePage = "routingstep";
    String pageTitle = "Quản lý công đoạn chi tiết";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý công đoạn chi tiết - PMS</title>
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
        .modal-backdrop {
            background: rgba(15, 23, 42, 0.72);
            backdrop-filter: blur(6px);
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-teal-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-teal-950/30">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-teal-200 bg-teal-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-teal-700 dark:border-teal-500/30 dark:bg-teal-500/10 dark:text-teal-300">
                                Quy trình sản xuất
                            </div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý công đoạn chi tiết</h1>
                            <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-400">Quản lý các bước thực hiện trong quy trình, thời gian dự kiến và trạng thái kiểm tra QC trên cùng một màn hình.</p>
                        </div>
                        <button type="button" onclick="openAddStepModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:-translate-y-0.5 hover:bg-teal-700">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                            </svg>
                            Thêm công đoạn
                        </button>
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
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 mb-6">
                    <div class="kpi-card rounded-2xl border border-blue-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-blue-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng công đoạn</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalSteps %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-300 text-2xl">&#9878;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-emerald-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-emerald-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Có kiểm tra QC</p>
                                <p class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= qcCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-300 text-2xl">&#10004;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-amber-200 border-t-4 border-t-amber-500 bg-white p-5 shadow-sm dark:border-amber-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Không kiểm tra</p>
                                <p class="mt-2 text-3xl font-bold text-amber-600 dark:text-amber-300"><%= totalSteps - qcCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-300 text-2xl">&#10006;</div>
                        </div>
                    </div>
                </div>

                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                    <div class="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <h2 class="text-base font-semibold text-slate-900 dark:text-slate-100">Tìm kiếm công đoạn</h2>
                            <p class="text-sm text-slate-500 dark:text-slate-400">Lọc nhanh theo tên công đoạn hoặc theo quy trình.</p>
                        </div>
                    </div>
                    <form action="RoutingStepController" method="get" class="flex flex-col gap-4 xl:flex-row">
                        <input type="hidden" name="action" value="searchRoutingStep">
                        <div class="flex-1 relative">
                            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>"
                                   placeholder="Tìm theo tên công đoạn..."
                                   class="w-full pl-10 pr-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                            <svg class="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                            </svg>
                        </div>
                        <div class="xl:w-64">
                            <select name="searchRoutingId" class="w-full px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                                <option value="">Tất cả quy trình</option>
                                <%
                                    java.util.List<pms.model.RoutingDTO> routingListFilter = (java.util.List<pms.model.RoutingDTO>) request.getAttribute("listRouting");
                                    if (routingListFilter != null) {
                                        for (pms.model.RoutingDTO routing : routingListFilter) {
                                %>
                                <option value="<%= routing.getRoutingId() %>" <%= String.valueOf(routing.getRoutingId()).equals(searchRoutingId) ? "selected" : "" %>><%= routing.getRoutingName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>
                        <button type="submit" class="px-6 py-3 rounded-2xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all shadow-sm shadow-teal-500/30">
                            Tìm kiếm
                        </button>
                        <a href="RoutingStepController?action=listRoutingStep" class="px-6 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-semibold hover:bg-slate-50 dark:hover:bg-slate-800 transition-all text-center">
                            Đặt lại
                        </a>
                    </form>
                </div>

                <!-- Routing Steps Table -->
                <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã CD</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tên công đoạn</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Thời gian (phút)</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Kiểm tra QC</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (listStep.isEmpty()) { %>
                                <tr>
                                    <td colspan="5" class="px-4 py-12 text-center text-slate-400 dark:text-slate-500">
                                        <div class="flex flex-col items-center gap-2">
                                            <svg class="w-12 h-12 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                                            </svg>
                                            <p>Chưa có công đoạn nào</p>
                                            <p class="text-sm">Tạo công đoạn mới để bắt đầu</p>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (RoutingStepDTO s : listStep) { %>
                                    <tr class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors">
                                        <td class="px-4 py-3">
                                            <span class="font-bold text-teal-600 dark:text-teal-300">#CD-<%= s.getStepId() %></span>
                                        </td>
                                        <td class="px-4 py-3">
                                            <div class="flex items-center gap-3">
                                                <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-teal-400 to-teal-600 flex items-center justify-center text-white font-bold text-sm">
                                                    <%= s.getStepName() != null ? s.getStepName().substring(0, 1).toUpperCase() : "?" %>
                                                </div>
                                                <span class="font-medium text-slate-700 dark:text-slate-200"><%= s.getStepName() != null ? s.getStepName() : "-" %></span>
                                            </div>
                                        </td>
                                        <td class="px-4 py-3 text-right font-semibold text-slate-700 dark:text-slate-200"><%= s.getEstimatedTime() %> phút</td>
                                        <td class="px-4 py-3 text-center">
                                            <% if (s.isIsInspected()) { %>
                                            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300">
                                                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                                </svg>
                                                Có QC
                                            </span>
                                            <% } else { %>
                                            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300">
                                                Không
                                            </span>
                                            <% } %>
                                        </td>
                                        <td class="px-4 py-3 text-center">
                                            <div class="flex items-center justify-center gap-2">
                                                <button type="button"
                                                        class="p-2 rounded-xl text-slate-500 dark:text-slate-400 hover:bg-amber-100 dark:hover:bg-amber-500/10 hover:text-amber-600 dark:hover:text-amber-300 transition-colors"
                                                        title="Chỉnh sửa"
                                                        data-step-id="<%= s.getStepId() %>"
                                                        data-routing-id="<%= s.getRoutingId() %>"
                                                        data-step-name="<%= s.getStepName() != null ? s.getStepName() : "" %>"
                                                        data-estimated-time="<%= s.getEstimatedTime() %>"
                                                        data-is-inspected="<%= s.isIsInspected() %>"
                                                        onclick="openEditStepModalFromButton(this)">
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                                    </svg>
                                                </button>
                                                <button type="button"
                                                        class="p-2 rounded-xl text-slate-500 dark:text-slate-400 hover:bg-red-100 dark:hover:bg-red-500/10 hover:text-red-600 dark:hover:text-red-300 transition-colors"
                                                        title="Xóa"
                                                        data-step-id="<%= s.getStepId() %>"
                                                        data-step-name="<%= s.getStepName() != null ? s.getStepName() : "Công đoạn #" + s.getStepId() %>"
                                                        onclick="openDeleteStepModal(this)">
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                                    </svg>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% if (!listStep.isEmpty()) { %>
                    <div class="px-4 py-3 border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-sm text-slate-500 dark:text-slate-400">
                        Tổng cộng: <span class="font-semibold"><%= listStep.size() %></span> công đoạn
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <script>
        // Modal thêm công đoạn
        function openAddStepModal() {
            const modal = document.getElementById('addStepModal');
            if (modal) {
                modal.classList.remove('hidden');
                modal.classList.add('flex');
                document.body.classList.add('overflow-hidden');
            }
        }

        function closeAddStepModal() {
            const modal = document.getElementById('addStepModal');
            if (modal) {
                modal.classList.add('hidden');
                modal.classList.remove('flex');
                document.body.classList.remove('overflow-hidden');
            }
        }

        function openEditStepModal(stepId, routingId, stepName, estimatedTime, isInspected) {
            const modal = document.getElementById('editStepModal');
            if (!modal) return;
            document.getElementById('edit_step_id').value = stepId || '';
            document.getElementById('edit_routing_id').value = routingId || '';
            document.getElementById('edit_step_name').value = stepName || '';
            document.getElementById('edit_estimated_time').value = estimatedTime || '';
            document.getElementById('edit_is_inspected').checked = String(isInspected).toLowerCase() === 'true';
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function openEditStepModalFromButton(button) {
            if (!button) return;
            openEditStepModal(
                button.getAttribute('data-step-id'),
                button.getAttribute('data-routing-id'),
                button.getAttribute('data-step-name'),
                button.getAttribute('data-estimated-time'),
                button.getAttribute('data-is-inspected')
            );
        }

        function closeEditStepModal() {
            const modal = document.getElementById('editStepModal');
            if (modal) {
                modal.classList.add('hidden');
                modal.classList.remove('flex');
                if (!document.getElementById('addStepModal')?.classList.contains('flex')
                        && !document.getElementById('deleteStepModal')?.classList.contains('flex')) {
                    document.body.classList.remove('overflow-hidden');
                }
            }
        }

        function openDeleteStepModal(button) {
            const modal = document.getElementById('deleteStepModal');
            const stepIdInput = document.getElementById('delete_step_id');
            const stepName = document.getElementById('deleteStepName');
            if (!modal || !stepIdInput || !stepName || !button) return;
            stepIdInput.value = button.getAttribute('data-step-id') || '';
            stepName.textContent = button.getAttribute('data-step-name') || 'công đoạn này';
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteStepModal() {
            const modal = document.getElementById('deleteStepModal');
            if (modal) {
                modal.classList.add('hidden');
                modal.classList.remove('flex');
                if (!document.getElementById('addStepModal')?.classList.contains('flex')
                        && !document.getElementById('editStepModal')?.classList.contains('flex')) {
                    document.body.classList.remove('overflow-hidden');
                }
            }
        }

        // Đóng modal khi click bên ngoài
        document.getElementById('addStepModal').addEventListener('click', function(event) {
            if (event.target === this) {
                closeAddStepModal();
            }
        });
        document.getElementById('editStepModal').addEventListener('click', function(event) {
            if (event.target === this) {
                closeEditStepModal();
            }
        });
        document.getElementById('deleteStepModal').addEventListener('click', function(event) {
            if (event.target === this) {
                closeDeleteStepModal();
            }
        });

        // Đóng modal khi nhấn Escape
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeAddStepModal();
                closeEditStepModal();
                closeDeleteStepModal();
            }
        });

        (function autoOpenEditStepModal() {
            const modal = document.getElementById('editStepModal');
            if (!modal || modal.getAttribute('data-auto-open') !== 'true') {
                return;
            }
            openEditStepModal(
                modal.getAttribute('data-step-id'),
                modal.getAttribute('data-routing-id'),
                modal.getAttribute('data-step-name'),
                modal.getAttribute('data-estimated-time'),
                modal.getAttribute('data-is-inspected')
            );
        })();
    </script>

    <!-- Modal thêm công đoạn -->
    <div id="addStepModal" class="modal-backdrop fixed inset-0 z-50 hidden items-center justify-center p-4">
        <div class="w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-teal-600 dark:text-teal-300">Tạo mới</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Thêm công đoạn sản xuất</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Nhập thông tin công đoạn để thêm mới ngay trên trang danh sách.</p>
                </div>
                <button type="button" onclick="closeAddStepModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="MainController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="addRoutingStep">
                <div class="space-y-2">
                    <label for="routingId" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Quy trình</label>
                    <select id="routingId" name="routingId" class="w-full rounded-2xl border border-slate-200 bg-white py-3 px-4 text-sm text-slate-700 outline-none transition focus:border-teal-400 focus:ring-2 focus:ring-teal-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                        <option value="">-- Chọn quy trình --</option>
                        <%
                            java.util.List<pms.model.RoutingDTO> routingList = (java.util.List<pms.model.RoutingDTO>) request.getAttribute("listRouting");
                            if (routingList != null) {
                                for (pms.model.RoutingDTO r : routingList) {
                        %>
                        <option value="<%= r.getRoutingId() %>"><%= r.getRoutingName() %></option>
                        <%
                                }
                            }
                        %>
                    </select>
                </div>
                <div class="space-y-2">
                    <label for="stepName" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Tên công đoạn <span class="text-red-500">*</span></label>
                    <input
                        id="stepName"
                        name="stepName"
                        type="text"
                        maxlength="100"
                        required
                        class="w-full rounded-2xl border border-slate-200 bg-white py-3 px-4 text-sm text-slate-700 outline-none transition focus:border-teal-400 focus:ring-2 focus:ring-teal-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400"
                        placeholder="Ví dụ: Gọt gỗ, Cắt gỗ thành hình"
                    >
                </div>
                <div class="space-y-2">
                    <label for="estimatedTime" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Thời gian (phút) <span class="text-red-500">*</span></label>
                    <input
                        id="estimatedTime"
                        name="estimatedTime"
                        type="number"
                        min="1"
                        required
                        class="w-full rounded-2xl border border-slate-200 bg-white py-3 px-4 text-sm text-slate-700 outline-none transition focus:border-teal-400 focus:ring-2 focus:ring-teal-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400"
                        placeholder="Ví dụ: 5, 10, 20"
                    >
                </div>
                <div class="flex items-center gap-3">
                    <input type="checkbox" id="isInspected" name="isInspected" class="w-5 h-5 rounded border-slate-300 text-teal-600 focus:ring-teal-500 dark:border-slate-600 dark:bg-slate-700">
                    <label for="isInspected" class="text-sm font-medium text-slate-700 dark:text-slate-200">Có kiểm tra QC ở bước này</label>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeAddStepModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Hủy
                    </button>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition hover:bg-teal-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Lưu công đoạn
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal sửa công đoạn -->
    <div id="editStepModal"
         class="modal-backdrop fixed inset-0 z-50 hidden items-center justify-center p-4"
         data-auto-open="<%= isEditMode ? "true" : "false" %>"
         data-step-id="<%= stepEdit != null ? stepEdit.getStepId() : "" %>"
         data-routing-id="<%= stepEdit != null ? stepEdit.getRoutingId() : "" %>"
         data-step-name="<%= stepEdit != null && stepEdit.getStepName() != null ? stepEdit.getStepName() : "" %>"
         data-estimated-time="<%= stepEdit != null ? stepEdit.getEstimatedTime() : "" %>"
         data-is-inspected="<%= stepEdit != null ? stepEdit.isIsInspected() : false %>">
        <div class="w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-600 dark:text-amber-300">Cập nhật</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Sửa công đoạn sản xuất</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"></p>
                </div>
                <button type="button" onclick="closeEditStepModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="MainController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="saveUpdateRoutingStep">
                <input type="hidden" id="edit_step_id" name="stepId" value="<%= stepEdit != null ? stepEdit.getStepId() : "" %>">
                <div class="space-y-2">
                    <label for="edit_routing_id" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Quy trình</label>
                    <select id="edit_routing_id" name="routingId" class="w-full rounded-2xl border border-slate-200 bg-white py-3 px-4 text-sm text-slate-700 outline-none transition focus:border-amber-400 focus:ring-2 focus:ring-amber-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-amber-400">
                        <option value="">-- Chọn quy trình --</option>
                        <%
                            java.util.List<pms.model.RoutingDTO> editRoutingList = (java.util.List<pms.model.RoutingDTO>) request.getAttribute("listRouting");
                            if (editRoutingList != null) {
                                for (pms.model.RoutingDTO r : editRoutingList) {
                        %>
                        <option value="<%= r.getRoutingId() %>" <%= stepEdit != null && r.getRoutingId() == stepEdit.getRoutingId() ? "selected" : "" %>><%= r.getRoutingName() %></option>
                        <%
                                }
                            }
                        %>
                    </select>
                </div>
                <div class="space-y-2">
                    <label for="edit_step_name" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Tên công đoạn <span class="text-red-500">*</span></label>
                    <input id="edit_step_name" name="stepName" type="text" maxlength="100" required value="<%= stepEdit != null && stepEdit.getStepName() != null ? stepEdit.getStepName() : "" %>" class="w-full rounded-2xl border border-slate-200 bg-white py-3 px-4 text-sm text-slate-700 outline-none transition focus:border-amber-400 focus:ring-2 focus:ring-amber-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-amber-400" placeholder="Ví dụ: Gọt gỗ, Cắt gỗ thành hình">
                </div>
                <div class="space-y-2">
                    <label for="edit_estimated_time" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Thời gian (phút) <span class="text-red-500">*</span></label>
                    <input id="edit_estimated_time" name="estimatedTime" type="number" min="1" required value="<%= stepEdit != null ? stepEdit.getEstimatedTime() : "" %>" class="w-full rounded-2xl border border-slate-200 bg-white py-3 px-4 text-sm text-slate-700 outline-none transition focus:border-amber-400 focus:ring-2 focus:ring-amber-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-amber-400" placeholder="Ví dụ: 5, 10, 20">
                </div>
                <div class="flex items-center gap-3">
                    <input type="checkbox" id="edit_is_inspected" name="isInspected" class="w-5 h-5 rounded border-slate-300 text-amber-600 focus:ring-amber-500 dark:border-slate-600 dark:bg-slate-700" <%= stepEdit != null && stepEdit.isIsInspected() ? "checked" : "" %>>
                    <label for="edit_is_inspected" class="text-sm font-medium text-slate-700 dark:text-slate-200">Có kiểm tra QC ở bước này</label>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeEditStepModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Hủy
                    </button>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition hover:bg-amber-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                        </svg>
                        Lưu cập nhật
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal xóa công đoạn -->
    <div id="deleteStepModal" class="modal-backdrop fixed inset-0 z-[60] hidden items-center justify-center p-4">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa công đoạn?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteStepName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <form action="MainController" method="post" class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <input type="hidden" name="action" value="deleteRoutingStep">
                <input type="hidden" id="delete_step_id" name="stepId" value="">
                <button type="button" onclick="closeDeleteStepModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <button type="submit" class="inline-flex items-center justify-center rounded-2xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa công đoạn</button>
            </form>
        </div>
    </div>
</body>
</html>
