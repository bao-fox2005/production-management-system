<%@page import="pms.model.DefectReasonDTO"%>
<%@page import="java.util.List"%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    List<DefectReasonDTO> listD = (List<DefectReasonDTO>) request.getAttribute("listD");
    if (listD == null) {
        listD = (List<DefectReasonDTO>) request.getAttribute("listDefect");
    }
    DefectReasonDTO defectEdit = (DefectReasonDTO) request.getAttribute("defectEdit");
    UserDTO user = (UserDTO) session.getAttribute("user");
    boolean isEditMode = (defectEdit != null);
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    String keyword = request.getAttribute("keyword") != null ? (String) request.getAttribute("keyword") : request.getParameter("keyword");

    if (listD == null && request.getAttribute("DEFECT_REASON_REDIRECT") == null) {
        request.setAttribute("DEFECT_REASON_REDIRECT", Boolean.TRUE);
        response.sendRedirect("DefectController?action=listDefectReason");
        return;
    }
    if (listD == null) listD = new java.util.ArrayList<>();
    if (keyword == null) keyword = "";
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "defect"; // Trang hiện tại cho sidebar
    String pageTitle = "Danh mục nguyên nhân lỗi"; // Tiêu đề cho header
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    int totalDefects = listD.size();
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Danh mục nguyên nhân lỗi - PMS</title>
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
                        <h1 class="text-2xl font-semibold tracking-tight text-slate-900 dark:text-slate-100 sm:text-3xl">Danh mục nguyên nhân lỗi</h1>
                        <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-300">
                            Danh sách này luôn lấy dữ liệu mới từ controller để đồng bộ với các thao tác thêm, sửa và xóa ở những trang khác.
                        </p>
                    </div>
                    <button type="button" onclick="openDefectReasonModal()" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-rose-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition-all hover:-translate-y-0.5 hover:bg-rose-700">
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Thêm nguyên nhân lỗi
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
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách nguyên nhân lỗi</h2>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tìm kiếm theo tên nguyên nhân và theo dõi danh mục đang được sử dụng.</p>
                        </div>
                        <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
                            <form action="DefectController" method="get" class="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center">
                                <input type="hidden" name="action" value="listDefectReason">
                                <div class="relative min-w-[260px]">
                                    <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-slate-400 dark:text-slate-500">
                                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m21 21-4.35-4.35M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15z"/>
                                        </svg>
                                    </span>
                                    <input type="text" name="keyword" value="<%= keyword %>" placeholder="Tìm theo tên nguyên nhân lỗi" class="w-full rounded-2xl border border-slate-200 bg-white py-3 pl-11 pr-4 text-sm text-slate-700 outline-none transition focus:border-rose-400 focus:ring-2 focus:ring-rose-500/15 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-rose-400">
                                </div>
                                <div class="flex gap-2">
                                    <button type="submit" class="rounded-2xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-slate-100 dark:text-slate-900 dark:hover:bg-white">Tìm kiếm</button>
                                    <% if (keyword != null && !keyword.trim().isEmpty()) { %>
                                    <a href="DefectController?action=listDefectReason" class="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Xóa lọc</a>
                                    <% } %>
                                </div>
                            </form>
                            <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                                Hiển thị: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= listD.size() %></span>
                            </div>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mã lỗi</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tên nguyên nhân lỗi</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <% if (listD.isEmpty()) { %>
                                <tr>
                                    <td colspan="3" class="px-6 py-14 text-center text-slate-500 dark:text-slate-400">
                                        <div class="flex flex-col items-center gap-3">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                <svg class="h-9 w-9" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="font-medium text-slate-700 dark:text-slate-200"><%= keyword != null && !keyword.trim().isEmpty() ? "Không tìm thấy kết quả phù hợp" : "Chưa có nguyên nhân lỗi nào" %></p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= keyword != null && !keyword.trim().isEmpty() ? "Thử đổi từ khóa tìm kiếm hoặc xóa bộ lọc để xem toàn bộ danh sách." : "Bắt đầu tạo danh mục để chuẩn hóa việc ghi nhận và phân tích lỗi" %></p>
                                                <div class="mt-4 flex items-center justify-center gap-2">
                                                    <% if (keyword != null && !keyword.trim().isEmpty()) { %>
                                                    <a href="DefectController?action=listDefectReason" class="inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Xóa bộ lọc</a>
                                                    <% } else { %>
                                                    <button type="button" onclick="openDefectReasonModal()" class="inline-flex items-center gap-2 rounded-2xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition-all hover:bg-rose-700">
                                                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                        </svg>
                                                        Thêm nguyên nhân lỗi đầu tiên
                                                    </button>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (DefectReasonDTO d : listD) { %>
                                    <tr class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-red-50 px-3 py-1 text-sm font-semibold text-red-700 dark:bg-red-500/10 dark:text-red-300">#LOI-<%= d.getDefectId() %></span>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-amber-100 px-3 py-1.5 text-sm font-semibold text-amber-700 dark:bg-amber-500/10 dark:text-amber-300">
                                                <svg class="mr-1 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                                                </svg>
                                                <%= d.getReasonName() %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex items-center justify-center gap-2">
                                                <a href="DefectController?action=loadUpdateDefectReason&defectId=<%= d.getDefectId() %>"
                                                   class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-amber-100 hover:text-amber-600 dark:text-slate-400 dark:hover:bg-amber-500/10 dark:hover:text-amber-300" title="Chỉnh sửa">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                                    </svg>
                                                </a>
                                                <button type="button"
                                                        data-defect-id="<%= d.getDefectId() %>"
                                                        data-defect-name="<%= d.getReasonName() != null ? d.getReasonName() : "Nguyên nhân lỗi #" + d.getDefectId() %>"
                                                        onclick="openDeleteDefectReasonModal(this)"
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
                    <% if (!listD.isEmpty()) { %>
                    <div class="border-t border-slate-200 bg-slate-50 px-6 py-4 text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800/80 dark:text-slate-400">
                        <%= keyword != null && !keyword.trim().isEmpty() ? "Kết quả tìm được:" : "Tổng cộng:" %>
                        <span class="font-semibold text-slate-700 dark:text-slate-200"><%= listD.size() %></span>
                        nguyên nhân lỗi
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <div id="defectReasonModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-rose-600 dark:text-rose-300">Tạo mới</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Thêm nguyên nhân lỗi</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo danh mục nguyên nhân lỗi ngay trên trang danh sách.</p>
                </div>
                <button type="button" onclick="closeDefectReasonModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="DefectController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="addDefectReason">
                <div class="space-y-2">
                    <label for="reasonName" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Tên nguyên nhân lỗi</label>
                    <input
                        id="reasonName"
                        name="reasonName"
                        type="text"
                        maxlength="100"
                        required
                        class="form-input"
                        placeholder="Ví dụ: Sai thông số máy, lỗi vật tư đầu vào"
                    >
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeDefectReasonModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Hủy
                    </button>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Lưu nguyên nhân lỗi
                    </button>
                </div>
            </form>
        </div>
    </div>

    <div id="editDefectReasonModal" class="fixed inset-0 z-50 <%= isEditMode ? "flex" : "hidden" %> items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-lg overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-600 dark:text-amber-300">Chỉnh sửa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Cập nhật nguyên nhân lỗi</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"></p>
                </div>
                <a href="DefectController?action=listDefectReason<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </a>
            </div>
            <% if (defectEdit != null) { %>
            <form action="DefectController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="saveUpdateDefectReason">
                <input type="hidden" name="defectId" value="<%= defectEdit.getDefectId() %>">
                <div class="space-y-2">
                    <label for="editReasonName" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Tên nguyên nhân lỗi</label>
                    <input
                        id="editReasonName"
                        name="reasonName"
                        type="text"
                        maxlength="100"
                        required
                        value="<%= defectEdit.getReasonName() %>"
                        class="form-input"
                        placeholder="Ví dụ: Sai thông số máy, lỗi vật tư đầu vào"
                    >
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <a href="DefectController?action=listDefectReason<%= keyword != null && !keyword.trim().isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
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

    <div id="deleteDefectReasonModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa nguyên nhân lỗi?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteDefectReasonName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button type="button" onclick="closeDeleteDefectReasonModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <a id="confirmDeleteDefectReasonBtn" href="#" class="inline-flex items-center justify-center rounded-2xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa nguyên nhân lỗi</a>
            </div>
        </div>
    </div>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>

    <script>
        const defectReasonModal = document.getElementById('defectReasonModal');
        const editDefectReasonModal = document.getElementById('editDefectReasonModal');
        const deleteDefectReasonModal = document.getElementById('deleteDefectReasonModal');
        const reasonNameInput = document.getElementById('reasonName');
        const editReasonNameInput = document.getElementById('editReasonName');
        const deleteDefectReasonName = document.getElementById('deleteDefectReasonName');
        const confirmDeleteDefectReasonBtn = document.getElementById('confirmDeleteDefectReasonBtn');

        function openDefectReasonModal() {
            if (!defectReasonModal) return;
            defectReasonModal.classList.remove('hidden');
            defectReasonModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
            if (reasonNameInput) {
                setTimeout(() => reasonNameInput.focus(), 50);
            }
        }

        function closeDefectReasonModal() {
            if (!defectReasonModal) return;
            defectReasonModal.classList.add('hidden');
            defectReasonModal.classList.remove('flex');
            if (!editDefectReasonModal || editDefectReasonModal.classList.contains('hidden')) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function closeEditDefectReasonModal() {
            if (!editDefectReasonModal) return;
            editDefectReasonModal.classList.add('hidden');
            editDefectReasonModal.classList.remove('flex');
            if ((!defectReasonModal || defectReasonModal.classList.contains('hidden'))
                    && (!deleteDefectReasonModal || deleteDefectReasonModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function openDeleteDefectReasonModal(button) {
            if (!deleteDefectReasonModal || !deleteDefectReasonName || !confirmDeleteDefectReasonBtn || !button) return;
            const defectId = button.getAttribute('data-defect-id');
            const defectName = button.getAttribute('data-defect-name');
            deleteDefectReasonName.textContent = defectName || ('Nguyên nhân lỗi #' + defectId);
            confirmDeleteDefectReasonBtn.href = 'DefectController?action=deleteDefectReason&defectId=' + defectId;
            deleteDefectReasonModal.classList.remove('hidden');
            deleteDefectReasonModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteDefectReasonModal() {
            if (!deleteDefectReasonModal) return;
            deleteDefectReasonModal.classList.add('hidden');
            deleteDefectReasonModal.classList.remove('flex');
            if ((!defectReasonModal || defectReasonModal.classList.contains('hidden'))
                    && (!editDefectReasonModal || editDefectReasonModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        if (defectReasonModal) {
            defectReasonModal.addEventListener('click', function (event) {
                if (event.target === defectReasonModal) {
                    closeDefectReasonModal();
                }
            });
        }

        if (editDefectReasonModal) {
            editDefectReasonModal.addEventListener('click', function (event) {
                if (event.target === editDefectReasonModal) {
                    closeEditDefectReasonModal();
                }
            });
        }

        if (deleteDefectReasonModal) {
            deleteDefectReasonModal.addEventListener('click', function (event) {
                if (event.target === deleteDefectReasonModal) {
                    closeDeleteDefectReasonModal();
                }
            });
        }

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                if (defectReasonModal && defectReasonModal.classList.contains('flex')) {
                    closeDefectReasonModal();
                }
                if (editDefectReasonModal && editDefectReasonModal.classList.contains('flex')) {
                    closeEditDefectReasonModal();
                }
                if (deleteDefectReasonModal && deleteDefectReasonModal.classList.contains('flex')) {
                    closeDeleteDefectReasonModal();
                }
            }
        });

        if ((editDefectReasonModal && editDefectReasonModal.classList.contains('flex'))
                || (deleteDefectReasonModal && deleteDefectReasonModal.classList.contains('flex'))) {
            document.body.classList.add('overflow-hidden');
        }

        if (editDefectReasonModal && editDefectReasonModal.classList.contains('flex')) {
            if (editReasonNameInput) {
                setTimeout(() => editReasonNameInput.focus(), 50);
            }
        }
    </script>
</body>
</html>
