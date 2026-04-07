<%@page import="pms.model.RoutingStepDTO"%>
<%@page import="pms.model.RoutingDTO"%>
<%@page import="java.util.List"%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<RoutingDTO> list = (List<RoutingDTO>) request.getAttribute("listRouting");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    String keyword = request.getAttribute("keyword") != null ? (String) request.getAttribute("keyword") : request.getParameter("keyword");

    if (list == null && request.getAttribute("ROUTING_REDIRECT") == null) {
        request.setAttribute("ROUTING_REDIRECT", Boolean.TRUE);
        response.sendRedirect("RoutingController?action=listRouting");
        return;
    }
    if (list == null) list = new java.util.ArrayList<>();
    if (keyword == null) keyword = "";
    
    RoutingDTO routingDetail = (RoutingDTO) request.getAttribute("routingDetail");
    List<RoutingStepDTO> routingSteps = (List<RoutingStepDTO>) request.getAttribute("routingSteps");
    if (routingSteps == null) routingSteps = new java.util.ArrayList<>();

    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "routing"; // Trang hiện tại cho sidebar
    String pageTitle = "Quản lý quy trình sản xuất"; // Tiêu đề cho header
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    int totalRouting = list.size();
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý quy trình sản xuất - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif']
                    }
                }
            }
        };
    </script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
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
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <!-- Main Content -->
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto bg-slate-100 p-4 dark:bg-slate-900 sm:p-6 lg:p-8">
                <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div class="max-w-3xl">
                        <h1 class="text-2xl font-semibold tracking-tight text-slate-900 dark:text-slate-100 sm:text-3xl">Quản lý quy trình sản xuất</h1>
                        <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-300">
                            Danh sách này luôn lấy dữ liệu mới từ controller để đồng bộ với các thao tác thêm, sửa và xóa ở những trang khác.
                        </p>
                    </div>
                    <button type="button" onclick="openRoutingModal()" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:-translate-y-0.5 hover:bg-teal-700">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Thêm quy trình mới
                    </button>
                </div>

                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-red-200 bg-red-50 px-4 py-4 text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="flex flex-col gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700 lg:flex-row lg:items-center lg:justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách quy trình</h2>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tìm kiếm theo tên quy trình và theo dõi danh mục đang được sử dụng.</p>
                        </div>
                        <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
                            <form action="RoutingController" method="get" class="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center">
                                <input type="hidden" name="action" value="listRouting">
                                <div class="relative min-w-[260px]">
                                    <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-slate-400 dark:text-slate-500">
                                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m21 21-4.35-4.35M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15z"/>
                                        </svg>
                                    </span>
                                    <input type="text" name="keyword" value="<%= keyword %>" placeholder="Tìm theo tên quy trình" class="w-full rounded-2xl border border-slate-200 bg-white py-3 pl-11 pr-4 text-sm text-slate-700 outline-none transition focus:border-teal-400 focus:ring-2 focus:ring-teal-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                                </div>
                                <div class="flex gap-2">
                                    <button type="submit" class="rounded-2xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-slate-100 dark:text-slate-900 dark:hover:bg-white">Tìm kiếm</button>
                                    <% if (keyword != null && !keyword.trim().isEmpty()) { %>
                                    <a href="RoutingController?action=listRouting" class="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Xóa lọc</a>
                                    <% } %>
                                </div>
                            </form>
                            <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                                Hiển thị: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= list.size() %></span>
                            </div>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mã QT</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tên quy trình</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <% if (list.isEmpty()) { %>
                                <tr>
                                    <td colspan="3" class="px-6 py-14 text-center text-slate-500 dark:text-slate-400">
                                        <div class="flex flex-col items-center gap-3">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                <svg class="h-9 w-9" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="font-medium text-slate-700 dark:text-slate-200"><%= keyword != null && !keyword.trim().isEmpty() ? "Không tìm thấy kết quả phù hợp" : "Chưa có quy trình nào" %></p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= keyword != null && !keyword.trim().isEmpty() ? "Thử đổi từ khóa tìm kiếm hoặc xóa bộ lọc để xem toàn bộ danh sách." : "Tạo quy trình mới để bắt đầu tổ chức luồng sản xuất" %></p>
                                                <div class="mt-4">
                                                    <% if (keyword != null && !keyword.trim().isEmpty()) { %>
                                                    <a href="RoutingController?action=listRouting" class="inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Xóa bộ lọc</a>
                                                    <% } else { %>
                                                    <button type="button" onclick="openRoutingModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                                                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                        </svg>
                                                        Thêm quy trình đầu tiên
                                                    </button>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (RoutingDTO r : list) { %>
                                    <tr class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-teal-50 px-3 py-1 text-sm font-semibold text-teal-700 dark:bg-teal-500/10 dark:text-teal-300">#QT-<%= r.getRoutingId() %></span>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <div class="flex items-center gap-3">
                                                <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 text-sm font-bold text-white shadow-sm shadow-indigo-500/30">
                                                    <%= r.getRoutingName() != null ? r.getRoutingName().substring(0, 1).toUpperCase() : "?" %>
                                                </div>
                                                <div>
                                                    <p class="font-semibold text-slate-700 dark:text-slate-100"><%= r.getRoutingName() != null ? r.getRoutingName() : "-" %></p>
                                                    <p class="text-sm text-slate-500 dark:text-slate-400">Quy trình sản xuất</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex items-center justify-center gap-2">
                                                <a href="RoutingController?action=viewRoutingDetail&routingId=<%= r.getRoutingId() %><%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
                                                   class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-blue-100 hover:text-blue-600 dark:text-slate-400 dark:hover:bg-blue-500/10 dark:hover:text-blue-300" title="Xem chi tiết quy trình">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                                    </svg>
                                                </a>
                                                <a href="RoutingController?action=loadUpdateRouting&routingId=<%= r.getRoutingId() %>"
                                                   class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-amber-100 hover:text-amber-600 dark:text-slate-400 dark:hover:bg-amber-500/10 dark:hover:text-amber-300" title="Chỉnh sửa">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                                    </svg>
                                                </a>
                                                <button type="button"
                                                        data-routing-id="<%= r.getRoutingId() %>"
                                                        data-routing-name="<%= r.getRoutingName() != null ? r.getRoutingName() : "Quy trình #" + r.getRoutingId() %>"
                                                        onclick="openDeleteRoutingModal(this)"
                                                        class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-red-100 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-500/10 dark:hover:text-red-300" title="Xóa">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
                    <% if (!list.isEmpty()) { %>
                    <div class="border-t border-slate-200 bg-slate-50 px-6 py-4 text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800/80 dark:text-slate-400">
                        <%= keyword != null && !keyword.trim().isEmpty() ? "Kết quả tìm được:" : "Tổng cộng:" %> <span class="font-semibold text-slate-700 dark:text-slate-200"><%= list.size() %></span> quy trình
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <div id="routingModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-teal-600 dark:text-teal-300">Tạo mới</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Thêm quy trình sản xuất</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Nhập tên quy trình để tạo mới ngay trên trang danh sách.</p>
                </div>
                <button type="button" onclick="closeRoutingModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="RoutingController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="addRouting">
                <div class="space-y-2">
                    <label for="routingName" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Tên quy trình</label>
                    <input
                        id="routingName"
                        name="routingName"
                        type="text"
                        maxlength="100"
                        required
                        class="form-input"
                        placeholder="Ví dụ: Quy trình lắp ráp tiêu chuẩn"
                    >
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeRoutingModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Hủy
                    </button>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition hover:bg-teal-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Lưu quy trình
                    </button>
                </div>
            </form>
        </div>
    </div>

    <div id="editRoutingModal" class="fixed inset-0 z-50 <%= request.getAttribute("routingEdit") != null ? "flex" : "hidden" %> items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-600 dark:text-amber-300">Cập nhật</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Sửa quy trình sản xuất</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"></p>
                </div>
                <a href="RoutingController?action=listRouting<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </a>
            </div>
            <% RoutingDTO routingEdit = (RoutingDTO) request.getAttribute("routingEdit"); %>
            <% if (routingEdit != null) { %>
            <form action="RoutingController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="saveUpdateRouting">
                <input type="hidden" name="routingId" value="<%= routingEdit.getRoutingId() %>">
                <div class="grid gap-4 sm:grid-cols-2">
                    <div class="space-y-2">
                        <label for="routingIdDisplay" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Mã quy trình</label>
                        <input id="routingIdDisplay" type="text" value="#QT-<%= routingEdit.getRoutingId() %>" readonly class="form-input bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-300">
                    </div>
                    <div class="space-y-2">
                        <label for="editRoutingName" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Tên quy trình</label>
                        <input id="editRoutingName" name="routingName" type="text" maxlength="100" required value="<%= routingEdit.getRoutingName() %>" class="form-input" placeholder="Ví dụ: Quy trình lắp ráp tiêu chuẩn">
                    </div>
                </div>
                <div class="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-800/70 dark:text-slate-300">
                    Mẹo: dùng nút <span class="font-semibold">Xem chi tiết</span> để mở nhanh danh sách công đoạn ngay trên trang hiện tại.
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <a href="RoutingController?action=listRouting<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Hủy
                    </a>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-amber-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition hover:bg-amber-600">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                        </svg>
                        Lưu cập nhật
                    </button>
                </div>
            </form>
            <% } %>
        </div>
    </div>

    <div id="deleteRoutingModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa quy trình sản xuất?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteRoutingName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button type="button" onclick="closeDeleteRoutingModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <a id="confirmDeleteRoutingBtn" href="#" class="inline-flex items-center justify-center rounded-2xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa quy trình</a>
            </div>
        </div>
    </div>

    <div id="viewRoutingDetailModal" class="fixed inset-0 z-50 <%= routingDetail != null ? "flex" : "hidden" %> items-start justify-center overflow-y-auto bg-slate-950/60 p-4 backdrop-blur-sm sm:p-6">
        <div class="my-6 flex w-full max-w-4xl max-h-[calc(100vh-3rem)] flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40 sm:my-8 sm:max-h-[calc(100vh-4rem)]">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-blue-600 dark:text-blue-300">Chi tiết</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Chi tiết quy trình sản xuất</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Xem danh sách công đoạn của quy trình.</p>
                </div>
                <a href="RoutingController?action=listRouting<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </a>
            </div>
            <% if (routingDetail != null) { %>
            <div class="space-y-6 overflow-y-auto px-6 py-6">
                <div class="grid gap-4 lg:grid-cols-3">
                    <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800/70">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mã quy trình</p>
                        <p class="mt-2 text-lg font-semibold text-slate-900 dark:text-slate-100">#QT-<%= routingDetail.getRoutingId() %></p>
                    </div>
                    <div class="rounded-2xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800/70 lg:col-span-2">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tên quy trình</p>
                        <p class="mt-2 text-lg font-semibold text-slate-900 dark:text-slate-100"><%= routingDetail.getRoutingName() != null ? routingDetail.getRoutingName() : "-" %></p>
                    </div>
                </div>

                <div class="rounded-3xl border border-slate-200 dark:border-slate-700">
                    <div class="flex flex-col gap-3 border-b border-slate-200 px-5 py-4 dark:border-slate-700 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <h4 class="text-base font-semibold text-slate-900 dark:text-slate-100">Danh sách công đoạn</h4>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Theo dõi các công đoạn thuộc quy trình này mà không cần chuyển trang.</p>
                        </div>
                        <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                            Tổng công đoạn: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= routingSteps.size() %></span>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                    <th class="px-5 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mã CĐ</th>
                                    <th class="px-5 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tên công đoạn</th>
                                    <th class="px-5 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Thời gian</th>
                                    <th class="px-5 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Kiểm tra</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <% if (routingSteps.isEmpty()) { %>
                                <tr>
                                    <td colspan="4" class="px-5 py-10 text-center text-slate-500 dark:text-slate-400">
                                        <div class="mx-auto max-w-md">
                                            <p class="font-medium text-slate-700 dark:text-slate-200">Quy trình này chưa có công đoạn nào</p>
                                            <p class="mt-2 text-sm">Bạn có thể thêm công đoạn ở trang quản lý công đoạn khi cần mở rộng quy trình.</p>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (RoutingStepDTO step : routingSteps) { %>
                                    <tr class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
                                        <td class="px-5 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-sm font-semibold text-blue-700 dark:bg-blue-500/10 dark:text-blue-300">#CD-<%= step.getStepId() %></span>
                                        </td>
                                        <td class="px-5 py-4 align-middle">
                                            <div>
                                                <p class="font-semibold text-slate-700 dark:text-slate-100"><%= step.getStepName() != null ? step.getStepName() : "-" %></p>
                                                <p class="text-sm text-slate-500 dark:text-slate-400">Thuộc quy trình #QT-<%= step.getRoutingId() %></p>
                                            </div>
                                        </td>
                                        <td class="px-5 py-4 align-middle text-sm text-slate-600 dark:text-slate-300"><%= step.getEstimatedTime() %> phút</td>
                                        <td class="px-5 py-4 align-middle">
                                            <% if (step.isIsInspected()) { %>
                                            <span class="inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-sm font-semibold text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300">Có kiểm tra</span>
                                            <% } else { %>
                                            <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-sm font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300">Không kiểm tra</span>
                                            <% } %>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <a href="RoutingController?action=listRouting<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Đóng
                    </a>
                    <a href="MainController?action=listRoutingStep&searchRoutingId=<%= routingDetail.getRoutingId() %>" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-blue-500/30 transition hover:bg-blue-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h6m0 0v6m0-6L10 16l-5-5"/>
                        </svg>
                        Mở trang công đoạn đầy đủ
                    </a>
                </div>
            </div>
            <% } %>
        </div>
    </div>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>

    <script>
        const routingModal = document.getElementById('routingModal');
        const editRoutingModal = document.getElementById('editRoutingModal');
        const deleteRoutingModal = document.getElementById('deleteRoutingModal');
        const viewRoutingDetailModal = document.getElementById('viewRoutingDetailModal');
        const routingNameInput = document.getElementById('routingName');
        const editRoutingNameInput = document.getElementById('editRoutingName');
        const deleteRoutingName = document.getElementById('deleteRoutingName');
        const confirmDeleteRoutingBtn = document.getElementById('confirmDeleteRoutingBtn');

        function openRoutingModal() {
            if (!routingModal) return;
            routingModal.classList.remove('hidden');
            routingModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
            if (routingNameInput) {
                setTimeout(() => routingNameInput.focus(), 50);
            }
        }

        function closeRoutingModal() {
            if (!routingModal) return;
            routingModal.classList.add('hidden');
            routingModal.classList.remove('flex');
            if ((!editRoutingModal || editRoutingModal.classList.contains('hidden'))
                    && (!viewRoutingDetailModal || viewRoutingDetailModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function closeEditRoutingModal() {
            if (!editRoutingModal) return;
            editRoutingModal.classList.add('hidden');
            editRoutingModal.classList.remove('flex');
            if ((!routingModal || routingModal.classList.contains('hidden'))
                    && (!deleteRoutingModal || deleteRoutingModal.classList.contains('hidden'))
                    && (!viewRoutingDetailModal || viewRoutingDetailModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function openDeleteRoutingModal(button) {
            if (!deleteRoutingModal || !deleteRoutingName || !confirmDeleteRoutingBtn || !button) return;
            const routingId = button.getAttribute('data-routing-id');
            const routingName = button.getAttribute('data-routing-name');
            deleteRoutingName.textContent = routingName || ('Quy trình #' + routingId);
            confirmDeleteRoutingBtn.href = 'RoutingController?action=deleteRouting&routingId=' + routingId;
            deleteRoutingModal.classList.remove('hidden');
            deleteRoutingModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteRoutingModal() {
            if (!deleteRoutingModal) return;
            deleteRoutingModal.classList.add('hidden');
            deleteRoutingModal.classList.remove('flex');
            if ((!routingModal || routingModal.classList.contains('hidden'))
                    && (!editRoutingModal || editRoutingModal.classList.contains('hidden'))
                    && (!viewRoutingDetailModal || viewRoutingDetailModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        if (routingModal) {
            routingModal.addEventListener('click', function (event) {
                if (event.target === routingModal) {
                    closeRoutingModal();
                }
            });
        }

        if (editRoutingModal) {
            editRoutingModal.addEventListener('click', function (event) {
                if (event.target === editRoutingModal) {
                    closeEditRoutingModal();
                }
            });
        }

        if (deleteRoutingModal) {
            deleteRoutingModal.addEventListener('click', function (event) {
                if (event.target === deleteRoutingModal) {
                    closeDeleteRoutingModal();
                }
            });
        }

        if (viewRoutingDetailModal) {
            viewRoutingDetailModal.addEventListener('click', function (event) {
                if (event.target === viewRoutingDetailModal) {
                    window.location.href = 'RoutingController?action=listRouting<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>';
                }
            });
        }

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                if (routingModal && routingModal.classList.contains('flex')) {
                    closeRoutingModal();
                }
                if (editRoutingModal && editRoutingModal.classList.contains('flex')) {
                    closeEditRoutingModal();
                }
                if (deleteRoutingModal && deleteRoutingModal.classList.contains('flex')) {
                    closeDeleteRoutingModal();
                }
                if (viewRoutingDetailModal && viewRoutingDetailModal.classList.contains('flex')) {
                    window.location.href = 'RoutingController?action=listRouting<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>';
                }
            }
        });

        if ((editRoutingModal && editRoutingModal.classList.contains('flex'))
                || (deleteRoutingModal && deleteRoutingModal.classList.contains('flex'))
                || (viewRoutingDetailModal && viewRoutingDetailModal.classList.contains('flex'))) {
            document.body.classList.add('overflow-hidden');
        }

        if (editRoutingModal && editRoutingModal.classList.contains('flex') && editRoutingNameInput) {
            setTimeout(() => editRoutingNameInput.focus(), 50);
        }
    </script>
</body>
</html>
