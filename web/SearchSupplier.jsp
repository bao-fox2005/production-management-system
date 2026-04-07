<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.ArrayList"%>
<%@page import="pms.model.SupplierDTO"%>
<%@page import="pms.model.UserDTO"%>
<%
    ArrayList<SupplierDTO> supplierList = (ArrayList<SupplierDTO>) request.getAttribute("supplierList");
    SupplierDTO supplierEdit = (SupplierDTO) request.getAttribute("supplierEdit");
    UserDTO user = (UserDTO) session.getAttribute("user");
    boolean isEditMode = (supplierEdit != null);
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    String keyword = request.getParameter("keyword");
    
    if (supplierList == null) supplierList = new ArrayList<>();
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "supplier";
    String pageTitle = "Quản lý nhà cung cấp";
    String totalSuppliers = String.valueOf(supplierList.size());
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
%>
<!DOCTYPE html>
<html lang="vi" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý nhà cung cấp - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
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
            border-color: #ea580c;
            box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.12);
        }
        .dark .form-input {
            background: #0f172a;
            border-color: #334155;
            color: #e2e8f0;
        }
        .dark .form-input::placeholder { color: #64748b; }
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
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-orange-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-orange-950/30">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-orange-200 bg-orange-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-orange-700 dark:border-orange-500/30 dark:bg-orange-500/10 dark:text-orange-300">
                                Nguồn cung ứng
                            </div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý nhà cung cấp</h1>
                            <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-400">Theo dõi đối tác cung ứng, cập nhật thông tin liên hệ và thêm mới nhà cung cấp ngay trên cùng một màn hình.</p>
                        </div>
                        <div class="flex flex-wrap items-center gap-3">
                            <% if (!isEditMode) { %>
                            <button type="button" onclick="openSupplierModal()" class="inline-flex items-center gap-2 rounded-2xl bg-orange-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-orange-500/30 transition-all hover:-translate-y-0.5 hover:bg-orange-700">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                </svg>
                                Thêm nhà cung cấp
                            </button>
                            <% } %>
                        </div>
                    </div>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 mb-6">
                    <div class="kpi-card rounded-2xl border border-orange-200 border-t-4 border-t-orange-500 bg-white p-5 shadow-sm dark:border-orange-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng nhà cung cấp</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalSuppliers %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-orange-50 text-2xl text-orange-600 dark:bg-orange-500/10 dark:text-orange-300">&#128667;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-amber-200 border-t-4 border-t-amber-500 bg-white p-5 shadow-sm dark:border-amber-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Đang hiển thị</p>
                                <p class="mt-2 text-3xl font-bold text-amber-600 dark:text-amber-300"><%= supplierList.size() %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-50 text-2xl text-amber-600 dark:bg-amber-500/10 dark:text-amber-300">&#128196;</div>
                        </div>
                    </div>
                </div>

                <div class="grid gap-6 grid-cols-1">
                    <div class="w-full">
                        <!-- Search Bar -->
                        <div class="section-card mb-6 rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                            <div class="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                                <div>
                                    <h2 class="text-base font-semibold text-slate-900 dark:text-slate-100">Tìm kiếm nhà cung cấp</h2>
                                    <p class="text-sm text-slate-500 dark:text-slate-400">Tìm nhanh theo tên nhà cung cấp hoặc số điện thoại liên hệ.</p>
                                </div>
                            </div>
                            <form action="SupplierController" method="get" class="flex flex-col gap-3 sm:flex-row">
                                <input type="hidden" name="action" value="searchSupplier">
                                <div class="flex-1 relative">
                                    <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>"
                                           placeholder="Tìm kiếm theo tên hoặc số điện thoại..."
                                           class="form-input w-full rounded-2xl border border-slate-200 py-3 pl-10 pr-4 transition-all dark:border-slate-700">
                                    <svg class="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                                    </svg>
                                </div>
                                <button type="submit" class="rounded-2xl bg-orange-600 px-6 py-3 font-semibold text-white transition-all hover:bg-orange-700">
                                    Tìm kiếm
                                </button>
                                <a href="SupplierController?action=listSupplier" class="rounded-2xl border border-slate-200 px-6 py-3 font-semibold text-slate-600 transition-all hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                                    Tất cả
                                </a>
                            </form>
                        </div>

                        <!-- Supplier Table -->
                        <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                            <div class="overflow-x-auto">
                                <table class="w-full">
                                    <thead>
                                        <tr class="border-b border-slate-100 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã NPP</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tên nhà cung cấp</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Số điện thoại</th>
                                            <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% if (supplierList.isEmpty()) { %>
                                        <tr>
                                            <td colspan="4" class="px-4 py-14 text-center text-slate-400 dark:text-slate-500">
                                                <div class="mx-auto flex max-w-md flex-col items-center gap-3">
                                                    <div class="flex h-16 w-16 items-center justify-center rounded-3xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                        <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
                                                        </svg>
                                                    </div>
                                                    <div>
                                                        <p class="text-base font-semibold text-slate-700 dark:text-slate-200">Chưa có nhà cung cấp nào</p>
                                                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Bắt đầu bằng cách thêm nhà cung cấp mới trực tiếp ngay trên trang này.</p>
                                                    </div>
                                                    <% if (!isEditMode) { %>
                                                    <button type="button" onclick="openSupplierModal()" class="inline-flex items-center gap-2 rounded-2xl bg-orange-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-orange-500/30 transition-all hover:bg-orange-700">
                                                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                        </svg>
                                                        Thêm nhà cung cấp đầu tiên
                                                    </button>
                                                    <% } %>
                                                </div>
                                            </td>
                                        </tr>
                                        <% } else { %>
                                            <% for (SupplierDTO s : supplierList) { %>
                                            <tr class="border-b border-slate-50 last:border-0 hover:bg-slate-50 transition-colors dark:border-slate-800 dark:hover:bg-slate-800/60">
                                                <td class="px-4 py-3">
                                                    <span class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-orange-100 text-sm font-bold text-orange-600 dark:bg-orange-500/10 dark:text-orange-300">
                                                        <%= s.getSupplierId() %>
                                                    </span>
                                                </td>
                                                <td class="px-4 py-3">
                                                    <div class="flex items-center gap-3">
                                                        <div class="flex h-10 w-10 items-center justify-center rounded-2xl bg-gradient-to-br from-orange-400 to-orange-600 text-sm font-bold text-white shadow-sm shadow-orange-500/30">
                                                            <%= s.getSupplierName() != null ? s.getSupplierName().substring(0, 1).toUpperCase() : "?" %>
                                                        </div>
                                                        <span class="font-medium text-slate-700 dark:text-slate-200"><%= s.getSupplierName() != null ? s.getSupplierName() : "-" %></span>
                                                    </div>
                                                </td>
                                                <td class="px-4 py-3 text-slate-600 dark:text-slate-300"><%= s.getContactPhone() != null ? s.getContactPhone() : "-" %></td>
                                                <td class="px-4 py-3 text-center">
                                                    <div class="flex items-center justify-center gap-2">
                                                        <a href="SupplierController?action=loadUpdateSupplier&id=<%= s.getSupplierId() %>"
                                                           class="rounded-xl p-2 text-slate-500 transition-colors hover:bg-blue-100 hover:text-blue-600 dark:text-slate-400 dark:hover:bg-blue-500/10 dark:hover:text-blue-300" title="Chỉnh sửa">
                                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                                            </svg>
                                                        </a>
                                                        <button type="button"
                                                                data-supplier-id="<%= s.getSupplierId() %>"
                                                                data-supplier-name="<%= s.getSupplierName() != null ? s.getSupplierName() : "Nhà cung cấp #" + s.getSupplierId() %>"
                                                                onclick="openDeleteSupplierModal(this)"
                                                                class="rounded-xl p-2 text-slate-500 transition-colors hover:bg-red-100 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-500/10 dark:hover:text-red-300" title="Xóa">
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
                            <% if (!supplierList.isEmpty()) { %>
                            <div class="border-t border-slate-100 bg-slate-50 px-4 py-3 text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800/80 dark:text-slate-400">
                                Tổng cộng: <span class="font-semibold"><%= supplierList.size() %></span> nhà cung cấp
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <div id="supplierModal" data-edit-mode="<%= isEditMode ? "true" : "false" %>" class="modal-backdrop fixed inset-0 z-50 hidden items-center justify-center p-4">
        <div class="w-full max-w-2xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-orange-600 dark:text-orange-300"><%= isEditMode ? "Chế độ chỉnh sửa" : "Thao tác nhanh" %></p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100"><%= isEditMode ? "Cập nhật nhà cung cấp" : "Thêm nhà cung cấp mới" %></h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= isEditMode ? "" : "Tạo nhà cung cấp trực tiếp ngay trên trang danh sách." %></p>
                </div>
                <button type="button" onclick="closeSupplierModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="SupplierController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="<%= isEditMode ? "saveUpdateSupplier" : "addSupplier" %>">
                <% if (isEditMode) { %>
                <input type="hidden" name="id" value="<%= supplierEdit.getSupplierId() %>">
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Mã nhà cung cấp</label>
                    <input type="text" value="<%= supplierEdit.getSupplierId() %>" readonly class="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-slate-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
                </div>
                <% } %>
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Tên nhà cung cấp <span class="text-red-500">*</span></label>
                    <input type="text" name="supplierName" required class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Nhập tên nhà cung cấp" value="<%= isEditMode && supplierEdit.getSupplierName() != null ? supplierEdit.getSupplierName() : "" %>">
                </div>
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Số điện thoại liên hệ <span class="text-red-500">*</span></label>
                    <input type="text" name="contactPhone" required class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Ví dụ: 0909 123 456" value="<%= isEditMode && supplierEdit.getContactPhone() != null ? supplierEdit.getContactPhone() : "" %>">
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end dark:border-slate-700">
                    <button type="button" onclick="closeSupplierModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                    <button type="submit" class="rounded-2xl bg-orange-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-orange-500/30 transition hover:bg-orange-700"><%= isEditMode ? "Lưu cập nhật" : "Lưu nhà cung cấp" %></button>
                </div>
            </form>
        </div>
    </div>

    <div id="deleteSupplierModal" class="modal-backdrop fixed inset-0 z-[60] hidden items-center justify-center p-4">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa nhà cung cấp?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteSupplierName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button type="button" onclick="closeDeleteSupplierModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <a id="confirmDeleteSupplierBtn" href="#" class="rounded-2xl bg-rose-600 px-5 py-3 text-center text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa nhà cung cấp</a>
            </div>
        </div>
    </div>
 
    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>
    <script src="js/common.js"></script>
    <script>
        const supplierModal = document.getElementById('supplierModal');
        const deleteSupplierModal = document.getElementById('deleteSupplierModal');
        const deleteSupplierName = document.getElementById('deleteSupplierName');
        const confirmDeleteSupplierBtn = document.getElementById('confirmDeleteSupplierBtn');
        const supplierEditMode = supplierModal && supplierModal.dataset.editMode === 'true';
        const supplierListUrl = 'SupplierController?action=listSupplier';

        function openSupplierModal() {
            if (!supplierModal) return;
            supplierModal.classList.remove('hidden');
            supplierModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeSupplierModal() {
            if (!supplierModal) return;
            supplierModal.classList.add('hidden');
            supplierModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
            if (supplierEditMode) {
                window.location.href = supplierListUrl;
            }
        }

        function openDeleteSupplierModal(button) {
            if (!deleteSupplierModal || !deleteSupplierName || !confirmDeleteSupplierBtn || !button) return;
            const supplierId = button.getAttribute('data-supplier-id');
            const supplierName = button.getAttribute('data-supplier-name');
            deleteSupplierName.textContent = supplierName || ('Nhà cung cấp #' + supplierId);
            confirmDeleteSupplierBtn.href = 'SupplierController?action=deleteSupplier&id=' + supplierId;
            deleteSupplierModal.classList.remove('hidden');
            deleteSupplierModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteSupplierModal() {
            if (!deleteSupplierModal) return;
            deleteSupplierModal.classList.add('hidden');
            deleteSupplierModal.classList.remove('flex');
            if (!supplierModal || supplierModal.classList.contains('hidden')) {
                document.body.classList.remove('overflow-hidden');
            }
        }
 
        if (supplierModal) {
            supplierModal.addEventListener('click', function(event) {
                if (event.target === supplierModal) {
                    closeSupplierModal();
                }
            });
        }

        if (deleteSupplierModal) {
            deleteSupplierModal.addEventListener('click', function(event) {
                if (event.target === deleteSupplierModal) {
                    closeDeleteSupplierModal();
                }
            });
        }
 
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeDeleteSupplierModal();
                closeSupplierModal();
            }
        });

        if (supplierEditMode) {
            openSupplierModal();
        }
    </script>
</body>
</html>
