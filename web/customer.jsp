<%--
  ===== customer.jsp – Quản lý Khách Hàng =====
  Mục đích    : CRUD khách hàng: danh sách, tìm kiếm, thêm (modal), sửa (modal pre-fill), xóa (confirm).
  Request attributes nhận từ CustomerController:
    - "customerList" (List<CustomerDTO>) : Danh sách khách (đã lọc nếu có keyword)
    - "customer"     (CustomerDTO)       : Đối tượng khách cần sửa (khi mode="update")
    - "mode"         (String)            : "add" (mặc định) hoặc "update" → điều khiển action form
    - "msg"          (String)            : Flash thông báo thành công
    - "error"        (String)            : Thông báo lỗi
    - "keyword"      (String)            : Từ khóa tìm kiếm để giữ giá trị trong input
  Session: session["darkMode"] (Boolean) | session["lang"] (String)
  Modal (customerModal):
    - mode="add"    : POST → CustomerController?action=saveAddCustomer
    - mode="update" : POST → CustomerController?action=saveUpdateCustomer + hidden id
    - Tự mở khi mode=update hoặc có error (JavaScript)
    - Đóng khi mode=update: redirect về CustomerController?action=listCustomer
  Modal xóa (deleteCustomerModal):
    - Đọc data-customer-id/name từ nút Xóa → POST CustomerController?action=removeCustomer
  Tìm kiếm    : GET → CustomerController?action=searchCustomer&keyword=...
  Phân quyền  : Admin toàn quyền; Employee xem danh sách, không có nút Thêm/Xóa.
--%>
<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.CustomerDTO, pms.model.UserDTO, java.text.SimpleDateFormat"%>
<%
    List<CustomerDTO> customerList = (List<CustomerDTO>) request.getAttribute("customerList");
    CustomerDTO customer = (CustomerDTO) request.getAttribute("customer");
    UserDTO user = (UserDTO) session.getAttribute("user");
    
    String msg = request.getAttribute("msg") != null ? (String) request.getAttribute("msg") : request.getParameter("msg");
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    String keyword = request.getAttribute("keyword") != null ? (String) request.getAttribute("keyword") : request.getParameter("keyword");
    String mode = (String) request.getAttribute("mode");
    
    if (customerList == null) customerList = new java.util.ArrayList<>();
    if (mode == null) mode = "add";
    
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "customer";
    String pageTitle = "Quản lý khách";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
    <head>
        <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý khách - PMS</title>
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
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
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
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 antialiased dark:bg-slate-900 dark:text-slate-100">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <!-- Main Content -->
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-cyan-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-cyan-950/30">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-cyan-200 bg-cyan-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-cyan-700 dark:border-cyan-500/30 dark:bg-cyan-500/10 dark:text-cyan-300">
                                Dữ liệu khách hàng
                            </div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý khách</h1>
                            <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-400">Quản lý thông tin liên hệ, cập nhật dữ liệu nhanh và theo dõi danh sách khách trên cùng một màn hình.</p>
                        </div>
                        <div class="flex flex-wrap items-center gap-3">
                            <% if (!"update".equals(mode)) { %>
                            <button type="button" onclick="openCustomerModal()" class="inline-flex items-center gap-2 rounded-2xl bg-cyan-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition-all hover:-translate-y-0.5 hover:bg-cyan-700">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                </svg>
                                Thêm khách
                            </button>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 mb-6">
                    <div class="kpi-card rounded-2xl border border-cyan-200 border-t-4 border-t-cyan-500 bg-white p-5 shadow-sm dark:border-cyan-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng khách hàng</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= customerList.size() %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-cyan-50 text-2xl text-cyan-600 dark:bg-cyan-500/10 dark:text-cyan-300">&#128101;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-blue-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-blue-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Đang hiển thị</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= customerList.size() %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-300 text-2xl">&#128196;</div>
                        </div>
                    </div>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 text-emerald-700 dark:text-emerald-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-700 dark:text-red-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <div class="grid gap-6 grid-cols-1">
                    <div class="w-full">
                        <!-- Search Bar -->
                        <div class="section-card mb-6 rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                            <div class="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                                <div>
                                    <h2 class="text-base font-semibold text-slate-900 dark:text-slate-100">Tìm kiếm khách</h2>
                                    <p class="text-sm text-slate-500 dark:text-slate-400">Tìm nhanh theo mã khách, tên khách, số điện thoại hoặc email.</p>
                                </div>
                            </div>
                            <form action="CustomerController" method="get" class="flex flex-col gap-3 sm:flex-row">
                                <input type="hidden" name="action" value="searchCustomer">
                                <div class="flex-1 relative">
                                    <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>"
                                           placeholder="Tìm theo mã khách, tên, số điện thoại hoặc email..."
                                           class="w-full pl-10 pr-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                                    <svg class="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                                    </svg>
                                </div>
                                <button type="submit" class="px-6 py-3 rounded-2xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all shadow-sm shadow-teal-500/30">
                                    Tìm kiếm
                                </button>
                                <a href="CustomerController?action=searchCustomer" class="px-6 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-semibold hover:bg-slate-50 dark:hover:bg-slate-800 transition-all">
                                    Tất cả
                                </a>
                            </form>
                        </div>

                        <!-- Customer Table -->
                        <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                            <div class="overflow-x-auto">
                                <table class="w-full">
                                    <thead>
                                        <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã KH</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tên khách</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Số điện thoại</th>
                                            <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Email</th>
                                            <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% if (customerList.isEmpty()) { %>
                                        <tr>
                                            <td colspan="5" class="px-4 py-14 text-center text-slate-400 dark:text-slate-500">
                                                <div class="mx-auto flex max-w-md flex-col items-center gap-3">
                                                    <div class="flex h-16 w-16 items-center justify-center rounded-3xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                        <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                                                        </svg>
                                                    </div>
                                                    <div>
                                                        <p class="text-base font-semibold text-slate-700 dark:text-slate-200">Chưa có khách nào</p>
                                                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Bắt đầu bằng cách tạo khách mới trực tiếp ngay trên trang này.</p>
                                                    </div>
                                                    <% if (!"update".equals(mode)) { %>
                                                    <button type="button" onclick="openCustomerModal()" class="inline-flex items-center gap-2 rounded-2xl bg-cyan-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition-all hover:bg-cyan-700">
                                                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                        </svg>
                                                        Thêm khách đầu tiên
                                                    </button>
                                                    <% } %>
                                                </div>
                                            </td>
                                        </tr>
                                        <% } else { %>
                                            <% for (CustomerDTO c : customerList) { %>
                                            <tr class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors">
                                                <td class="px-4 py-3">
                                                    <span class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-teal-100 dark:bg-teal-500/10 text-teal-600 dark:text-teal-300 text-sm font-bold">
                                                        <%= c.getCustomer_id() %>
                                                    </span>
                                                </td>
                                                <td class="px-4 py-3">
                                                    <div class="flex items-center gap-3">
                                                        <div class="w-10 h-10 rounded-2xl bg-gradient-to-br from-teal-400 to-cyan-500 flex items-center justify-center text-white font-bold text-sm shadow-sm shadow-teal-500/30">
                                                            <%= c.getCustomer_name() != null ? c.getCustomer_name().substring(0, 1).toUpperCase() : "?" %>
                                                        </div>
                                                        <span class="font-medium text-slate-700 dark:text-slate-200"><%= c.getCustomer_name() != null ? c.getCustomer_name() : "-" %></span>
                                                    </div>
                                                </td>
                                                <td class="px-4 py-3 text-slate-600 dark:text-slate-300"><%= c.getPhone() != null ? c.getPhone() : "-" %></td>
                                                <td class="px-4 py-3 text-slate-600 dark:text-slate-300"><%= c.getEmail() != null ? c.getEmail() : "-" %></td>
                                                <td class="px-4 py-3 text-center">
                                                    <div class="flex items-center justify-center gap-2">
                                                        <a href="CustomerController?action=updateCustomer&id=<%= c.getCustomer_id() %>"
                                                           class="inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-blue-100 hover:text-blue-600 dark:text-slate-300 dark:hover:bg-blue-500/10 dark:hover:text-blue-300"
                                                           title="Chỉnh sửa khách">
                                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                                            </svg>
                                                            <span class="hidden sm:inline">Sửa</span>
                                                        </a>
                                                        <button type="button"
                                                                data-customer-id="<%= c.getCustomer_id() %>"
                                                                data-customer-name="<%= c.getCustomer_name() != null ? c.getCustomer_name() : "Khách #" + c.getCustomer_id() %>"
                                                                onclick="openDeleteCustomerModal(this)"
                                                                class="inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-red-100 hover:text-red-600 dark:text-slate-300 dark:hover:bg-red-500/10 dark:hover:text-red-300"
                                                                title="Xóa khách">
                                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                                            </svg>
                                                            <span class="hidden sm:inline">Xóa</span>
                                                        </button>
                                                    </div>
                </td>
            </tr>
                                            <% } %>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                            <% if (!customerList.isEmpty()) { %>
                            <div class="px-4 py-3 border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-sm text-slate-500 dark:text-slate-400">
                                Tổng cộng: <span class="font-semibold"><%= customerList.size() %></span> khách
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <div id="customerModal" data-edit-mode="<%= "update".equals(mode) ? "true" : "false" %>" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-2xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-600 dark:text-cyan-300"><%= "update".equals(mode) ? "Chế độ chỉnh sửa" : "Thao tác nhanh" %></p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100"><%= "update".equals(mode) ? "Cập nhật khách hàng" : "Thêm khách mới" %></h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= "update".equals(mode) ? "" : "Tạo khách trực tiếp ngay trên trang danh sách." %></p>
                </div>
                <button type="button" onclick="closeCustomerModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="CustomerController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="<%= "update".equals(mode) ? "saveUpdateCustomer" : "saveAddCustomer" %>">
                <% if ("update".equals(mode) && customer != null) { %>
                <input type="hidden" name="id" value="<%= customer.getCustomer_id() %>">
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Mã khách hàng</label>
                    <input type="text" value="<%= customer.getCustomer_id() %>" readonly class="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-slate-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-400">
                </div>
                <% } %>
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Tên khách <span class="text-red-500">*</span></label>
                    <input type="text" name="customer_name" required class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Nhập tên khách hoặc doanh nghiệp" value="<%= customer != null && customer.getCustomer_name() != null ? customer.getCustomer_name() : "" %>">
                </div>
                <div class="grid gap-5 sm:grid-cols-2">
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Số điện thoại</label>
                        <input type="text" name="phone" class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Ví dụ: 0912345678" value="<%= customer != null && customer.getPhone() != null ? customer.getPhone() : "" %>">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Email</label>
                        <input type="email" name="email" class="form-input w-full rounded-2xl border px-4 py-3" placeholder="email@example.com" value="<%= customer != null && customer.getEmail() != null ? customer.getEmail() : "" %>">
                    </div>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end dark:border-slate-700">
                    <button type="button" onclick="closeCustomerModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                    <button type="submit" class="rounded-2xl bg-cyan-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition hover:bg-cyan-700"><%= "update".equals(mode) ? "Lưu cập nhật" : "Lưu khách" %></button>
                </div>
            </form>
        </div>
    </div>

    <div id="deleteCustomerModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa khách hàng?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteCustomerName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <form action="CustomerController" method="post" class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <input type="hidden" name="action" value="removeCustomer">
                <input type="hidden" id="deleteCustomerId" name="id" value="">
                <button type="button" onclick="closeDeleteCustomerModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <button type="submit" class="rounded-2xl bg-rose-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa khách</button>
            </form>
        </div>
    </div>
 
    <script src="js/common.js"></script>
    <script>
        const customerModal = document.getElementById('customerModal');
        const deleteCustomerModal = document.getElementById('deleteCustomerModal');
        const customerEditMode = customerModal && customerModal.dataset.editMode === 'true';
        const shouldReopenCustomerModal = Boolean('<%= (error != null && !error.isEmpty() && !"update".equals(mode)) ? "true" : "" %>');
        const customerListUrl = 'CustomerController?action=listCustomer';

        function openCustomerModal() {
            if (!customerModal) return;
            customerModal.classList.remove('hidden');
            customerModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeCustomerModal() {
            if (!customerModal) return;
            customerModal.classList.add('hidden');
            customerModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
            if (customerEditMode) {
                window.location.href = customerListUrl;
            }
        }

        function openDeleteCustomerModal(button) {
            if (!deleteCustomerModal || !button) return;
            document.getElementById('deleteCustomerId').value = button.getAttribute('data-customer-id') || '';
            document.getElementById('deleteCustomerName').textContent = button.getAttribute('data-customer-name') || 'khách hàng này';
            deleteCustomerModal.classList.remove('hidden');
            deleteCustomerModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteCustomerModal() {
            if (!deleteCustomerModal) return;
            deleteCustomerModal.classList.add('hidden');
            deleteCustomerModal.classList.remove('flex');
            if (!customerModal || customerModal.classList.contains('hidden')) {
                document.body.classList.remove('overflow-hidden');
            }
        }
 
        if (customerModal) {
            customerModal.addEventListener('click', function(event) {
                if (event.target === customerModal) {
                    closeCustomerModal();
                }
            });
        }

        if (deleteCustomerModal) {
            deleteCustomerModal.addEventListener('click', function(event) {
                if (event.target === deleteCustomerModal) {
                    closeDeleteCustomerModal();
                }
            });
        }
 
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeDeleteCustomerModal();
                closeCustomerModal();
            }
        });

        if (customerEditMode || shouldReopenCustomerModal) {
            openCustomerModal();
        }
    </script>
</body>
</html>
