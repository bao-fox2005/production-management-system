<%@page import="pms.model.PurchaseOrderDTO"%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="java.util.List"%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    private String getStatusClass(String status) {
        if ("Received".equals(status)) {
            return "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
        }
        if ("Ordered".equals(status)) {
            return "bg-blue-100 text-blue-700 dark:bg-blue-500/10 dark:text-blue-300";
        }
        return "bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300";
    }

    private String getStatusLabel(String status) {
        if ("Received".equals(status)) {
            return "Đã nhập kho";
        }
        if ("Ordered".equals(status)) {
            return "Đã duyệt";
        }
        return "Chờ duyệt";
    }
    
    // HÀM FORMAT HIỂN THỊ NGÀY GIỜ ĐẸP
    private String formatDisplayDate(String dbDate) {
        if (dbDate == null || dbDate.isEmpty()) return "-";
        try { 
            return dbDate.endsWith(".0") ? dbDate.substring(0, 16) : dbDate.substring(0, 16); 
        } catch (Exception e) { 
            return dbDate; 
        }
    }
%>
<%
    List<PurchaseOrderDTO> listPO = (List<PurchaseOrderDTO>) request.getAttribute("listPO");
    List<ItemDTO> listItems = (List<ItemDTO>) request.getAttribute("listItems");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = request.getAttribute("msg") != null ? (String) request.getAttribute("msg") : request.getParameter("msg");
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");

    if (listPO == null) {
        listPO = new java.util.ArrayList<>();
    }
    if (listItems == null) {
        listItems = new java.util.ArrayList<>();
    }

    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isWorker = "employee".equalsIgnoreCase(userRole)
            || "worker".equalsIgnoreCase(userRole)
            || "user".equalsIgnoreCase(userRole);
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "purchaseorder";
    String pageTitle = "Nhập vật tư";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);

    int totalPO = listPO.size();
    int pendingCount = 0;
    int orderedCount = 0;
    int receivedCount = 0;
    for (PurchaseOrderDTO po : listPO) {
        String status = po.getStatus();
        if ("Pending".equals(status)) {
            pendingCount++;
        } else if ("Ordered".equals(status)) {
            orderedCount++;
        } else if ("Received".equals(status)) {
            receivedCount++;
        }
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nhập vật tư - PMS</title>
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

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto bg-slate-100 p-4 dark:bg-slate-900 sm:p-6 lg:p-8">
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-cyan-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-cyan-950/40">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-cyan-200 bg-cyan-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.24em] text-cyan-700 dark:border-cyan-500/30 dark:bg-cyan-500/10 dark:text-cyan-300">
                                Mua hàng
                            </div>
                            <h1 class="mt-4 text-3xl font-semibold tracking-tight text-slate-900 dark:text-slate-100 sm:text-4xl">Nhập vật tư</h1>
                            <p class="mt-3 max-w-2xl text-sm leading-6 text-slate-600 dark:text-slate-300 sm:text-base">
                                Theo dõi nhu cầu mua vật tư, cập nhật trạng thái xử lý và tạo đơn nhập hàng trực tiếp.
                            </p>
                        </div>
                        <% if (isAdmin || isWorker) { %>
                        <button type="button" onclick="openPurchaseOrderModal()" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-cyan-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition-all hover:-translate-y-0.5 hover:bg-cyan-700">
                            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                            </svg>
                            Tạo đơn nhập mới
                        </button>
                        <% } %>
                    </div>
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

                <div class="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-slate-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Tổng đơn</p>
                                <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= totalPO %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Tổng số yêu cầu mua</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-2xl text-slate-600 dark:bg-slate-700/70 dark:text-slate-200">&#128221;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-amber-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Chờ duyệt</p>
                                <p class="mt-3 text-3xl font-bold text-amber-600 dark:text-amber-300"><%= pendingCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Các đơn đang chờ xử lý</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-amber-50 text-2xl text-amber-600 dark:bg-amber-500/10 dark:text-amber-300">&#9203;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đã duyệt</p>
                                <p class="mt-3 text-3xl font-bold text-blue-600 dark:text-blue-300"><%= orderedCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Đơn đã chuyển sang đặt hàng</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-50 text-2xl text-blue-600 dark:bg-blue-500/10 dark:text-blue-300">&#128230;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-slate-200 border-t-4 border-t-emerald-500 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                        <div class="flex items-start justify-between gap-4">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đã nhập kho</p>
                                <p class="mt-3 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= receivedCount %></p>
                                <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Vật tư đã hoàn tất tiếp nhận</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-50 text-2xl text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-300">&#10004;</div>
                        </div>
                    </div>
                </div>

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="flex flex-col gap-3 border-b border-slate-200 px-6 py-5 dark:border-slate-700 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách đơn nhập vật tư</h2>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Theo dõi vật tư cần mua, số lượng yêu cầu và trạng thái xử lý</p>
                        </div>
                        <div class="rounded-2xl bg-slate-100 px-4 py-2 text-sm font-medium text-slate-600 dark:bg-slate-700/70 dark:text-slate-300">
                            Tổng cộng: <span class="font-semibold text-slate-900 dark:text-slate-100"><%= listPO.size() %></span>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/80">
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mã đơn</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Vật tư</th>
                                    <th class="px-6 py-4 text-right text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Số lượng</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Trạng thái</th>
                                    <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Thời gian tạo</th>
                                    <th class="px-6 py-4 text-center text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                                <% if (listPO.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-6 py-14 text-center text-slate-500 dark:text-slate-400">
                                        <div class="flex flex-col items-center gap-3">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                <svg class="h-9 w-9" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="font-medium text-slate-700 dark:text-slate-200">Chưa có đơn nhập vật tư nào</p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo đơn đầu tiên để bắt đầu quy trình mua hàng</p>
                                                <div class="mt-4">
                                                    <button type="button" onclick="openPurchaseOrderModal()" class="inline-flex items-center gap-2 rounded-2xl bg-cyan-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition-all hover:bg-cyan-700">
                                                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                        </svg>
                                                        Tạo đơn đầu tiên
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (PurchaseOrderDTO po : listPO) { %>
                                    <tr class="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/60">
                                        <td class="px-6 py-4 align-middle">
                                            <span class="inline-flex items-center rounded-full bg-cyan-50 px-3 py-1 text-sm font-semibold text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-300">#PO-<%= po.getPoId() %></span>
                                        </td>
                                        <td class="px-6 py-4 align-middle">
                                            <div class="flex items-center gap-3">
                                                <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-cyan-500 to-blue-600 text-sm font-bold text-white shadow-sm shadow-cyan-500/30">
                                                    <%= po.getItemName() != null ? po.getItemName().substring(0, 1).toUpperCase() : "?" %>
                                                </div>
                                                <div>
                                                    <p class="font-semibold text-slate-700 dark:text-slate-100"><%= po.getItemName() != null ? po.getItemName() : "Vật tư #" + po.getItemId() %></p>
                                                    <p class="text-sm text-slate-500 dark:text-slate-400">Yêu cầu mua vật tư</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 text-right align-middle">
                                            <span class="font-bold text-rose-600 dark:text-rose-300"><%= po.getQuantityRequested() %></span>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <span class="inline-flex items-center rounded-full px-3 py-1 text-xs font-bold <%= getStatusClass(po.getStatus()) %>">
                                                <%= getStatusLabel(po.getStatus()) %>
                                            </span>
                                        </td>
                                        <td class="px-6 py-4 align-middle text-sm font-medium text-slate-600 dark:text-slate-400">
                                            <%= formatDisplayDate(po.getOrderDate()) %>
                                        </td>
                                        <td class="px-6 py-4 text-center align-middle">
                                            <div class="flex items-center justify-center gap-2">
                                                <% if (isAdmin) { %>
                                                <form action="MainController" method="post" class="inline">
                                                    <input type="hidden" name="action" value="updateStatusPurchaseOrder">
                                                    <input type="hidden" name="poId" value="<%= po.getPoId() %>">
                                                    <select name="status" onchange="if(confirm('Cập nhật trạng thái đơn này?')){this.form.submit();}else{location.reload();}"
                                                            class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-700 shadow-sm transition focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200">
                                                        <option value="Pending" <%= "Pending".equals(po.getStatus()) ? "selected" : "" %>>Chờ duyệt</option>
                                                        <option value="Ordered" <%= "Ordered".equals(po.getStatus()) ? "selected" : "" %>>Đang nhập</option>
                                                        <option value="Received" <%= "Received".equals(po.getStatus()) ? "selected" : "" %>>Đã nhập</option>
                                                    </select>
                                                </form>
                                                <button type="button"
                                                        data-po-id="<%= po.getPoId() %>"
                                                        data-po-name="Đơn nhập #<%= po.getPoId() %>"
                                                        onclick="openDeletePurchaseOrderModal(this)"
                                                        class="rounded-xl p-2.5 text-slate-500 transition-colors hover:bg-red-100 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-500/10 dark:hover:text-red-300" title="Xóa">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                                    </svg>
                                                </button>
                                                <% } else { %>
                                                <span class="text-sm font-medium text-slate-500 dark:text-slate-400">Chỉ quản lý được duyệt/xóa</span>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% if (!listPO.isEmpty()) { %>
                    <div class="border-t border-slate-200 bg-slate-50 px-6 py-4 text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800/80 dark:text-slate-400">
                        Tổng cộng: <span class="font-semibold text-slate-700 dark:text-slate-200"><%= listPO.size() %></span> đơn
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <% if (isAdmin || isWorker) { %>
    <div id="purchaseOrderModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-900/20 dark:border-slate-700 dark:bg-slate-900 dark:shadow-black/40">
            <div class="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-cyan-600 dark:text-cyan-300">Tạo mới</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Tạo đơn nhập vật tư</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Chọn vật tư và nhập số lượng cần mua từ nhà cung cấp.</p>
                </div>
                <button type="button" onclick="closePurchaseOrderModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-200" aria-label="Đóng">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="MainController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="addPurchaseOrder">
                <div class="space-y-2">
                    <label for="itemId" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Chọn vật tư</label>
                    <select id="itemId" name="itemId" required class="form-input">
                        <option value="">-- Chọn vật tư --</option>
                        <% for (ItemDTO i : listItems) {
                            String type = i.getItemType();
                            if (type == null || !type.trim().equalsIgnoreCase("SanPham")) { %>
                        <option value="<%= i.getItemID() %>"><%= i.getItemName() %> (<%= i.getStockQuantity() %> tồn kho)</option>
                        <%  }
                           } %>
                    </select>
                </div>
                <div class="space-y-2">
                    <label for="quantity" class="text-sm font-semibold text-slate-700 dark:text-slate-200">Số lượng cần nhập</label>
                    <input id="quantity" name="quantity" type="number" min="1" value="1" required class="form-input" placeholder="Nhập số lượng cần mua">
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 dark:border-slate-700 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closePurchaseOrderModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                        Hủy
                    </button>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-cyan-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition hover:bg-cyan-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Tạo đơn nhập
                    </button>
                </div>
            </form>
        </div>
    </div>
    <% } %>

    <div id="deletePurchaseOrderModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa đơn nhập vật tư?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deletePurchaseOrderName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button type="button" onclick="closeDeletePurchaseOrderModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <a id="confirmDeletePurchaseOrderBtn" href="#" class="inline-flex items-center justify-center rounded-2xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa đơn</a>
            </div>
        </div>
    </div>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>

    <script>
        const purchaseOrderModal = document.getElementById('purchaseOrderModal');
        const purchaseItemSelect = document.getElementById('itemId');
        const deletePurchaseOrderModal = document.getElementById('deletePurchaseOrderModal');
        const deletePurchaseOrderName = document.getElementById('deletePurchaseOrderName');
        const confirmDeletePurchaseOrderBtn = document.getElementById('confirmDeletePurchaseOrderBtn');

        function openPurchaseOrderModal() {
            if (!purchaseOrderModal) return;
            purchaseOrderModal.classList.remove('hidden');
            purchaseOrderModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
            if (purchaseItemSelect) {
                setTimeout(() => purchaseItemSelect.focus(), 50);
            }
        }

        function closePurchaseOrderModal() {
            if (!purchaseOrderModal) return;
            purchaseOrderModal.classList.add('hidden');
            purchaseOrderModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
        }

        function openDeletePurchaseOrderModal(button) {
            if (!deletePurchaseOrderModal || !deletePurchaseOrderName || !confirmDeletePurchaseOrderBtn || !button) return;
            const poId = button.getAttribute('data-po-id');
            const poName = button.getAttribute('data-po-name');
            deletePurchaseOrderName.textContent = poName || ('Đơn nhập #' + poId);
            confirmDeletePurchaseOrderBtn.href = 'MainController?action=deletePurchaseOrder&poId=' + poId;
            deletePurchaseOrderModal.classList.remove('hidden');
            deletePurchaseOrderModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeletePurchaseOrderModal() {
            if (!deletePurchaseOrderModal) return;
            deletePurchaseOrderModal.classList.add('hidden');
            deletePurchaseOrderModal.classList.remove('flex');
            if (!purchaseOrderModal || purchaseOrderModal.classList.contains('hidden')) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        if (purchaseOrderModal) {
            purchaseOrderModal.addEventListener('click', function (event) {
                if (event.target === purchaseOrderModal) {
                    closePurchaseOrderModal();
                }
            });
        }

        if (deletePurchaseOrderModal) {
            deletePurchaseOrderModal.addEventListener('click', function (event) {
                if (event.target === deletePurchaseOrderModal) {
                    closeDeletePurchaseOrderModal();
                }
            });
        }

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                closeDeletePurchaseOrderModal();
                if (purchaseOrderModal && purchaseOrderModal.classList.contains('flex')) {
                    closePurchaseOrderModal();
                }
            }
        });
    </script>
</body>
</html>