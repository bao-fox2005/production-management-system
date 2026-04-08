<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.ArrayList, pms.model.PaymentDTO, pms.model.UserDTO, java.text.DecimalFormat, java.text.SimpleDateFormat"%>
<%!
    String getStatusClass(String status) {
        if ("PAID".equals(status)) return "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
        if ("EXPIRED".equals(status)) return "bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-300";
        return "bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300";
    }

    String getStatusText(String status) {
        if ("PAID".equals(status)) return "Đã thanh toán";
        if ("EXPIRED".equals(status)) return "Hết hạn";
        return "Chờ thanh toán";
    }
%>
<%
    ArrayList<PaymentDTO> paymentList = (ArrayList<PaymentDTO>) request.getAttribute("paymentList");
    String keyword = (String) request.getAttribute("keyword");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    UserDTO user = (UserDTO) session.getAttribute("user");

    if (paymentList == null) paymentList = new ArrayList<>();
    DecimalFormat df = new DecimalFormat("#,###");
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "payment"; // Trang hiện tại cho sidebar
    String pageTitle = "Quản lý thanh toán"; // Tiêu đề cho header
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    String currentAction = request.getParameter("action");
    if (currentAction == null || currentAction.trim().isEmpty()) currentAction = "list";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    // Stats
    int totalPayments = paymentList.size();
    int pendingCount = 0, paidCount = 0, expiredCount = 0;
    double totalAmount = 0;
    for (PaymentDTO p : paymentList) {
        totalAmount += p.getAmount();
        if ("PENDING".equals(p.getStatus())) pendingCount++;
        else if ("PAID".equals(p.getStatus())) paidCount++;
        else if ("EXPIRED".equals(p.getStatus())) expiredCount++;
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý thanh toán - PMS</title>
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
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <!-- Main Content -->
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý thanh toán</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Theo dõi thanh toán QR, trạng thái xử lý và giá trị giao dịch theo từng hóa đơn.</p>
                    </div>
                    <div class="flex flex-wrap items-center gap-3">
                        <a href="PaymentController?action=list" class="inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                            </svg>
                            Làm mới
                        </a>
                        <button type="button" onclick="openQrModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                            </svg>
                            Tạo QR mới
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
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
                    <div class="kpi-card bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-blue-200 dark:border-blue-500/30 border-t-4 border-t-blue-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng thanh toán</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalPayments %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-300 text-2xl">&#128179;</div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-emerald-200 dark:border-emerald-500/30 border-t-4 border-t-emerald-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Đã thanh toán</p>
                                <p class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-300"><%= paidCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-300 text-2xl">&#10004;</div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-amber-200 dark:border-amber-500/30 border-t-4 border-t-amber-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Chờ thanh toán</p>
                                <p class="mt-2 text-3xl font-bold text-amber-600 dark:text-amber-300"><%= pendingCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-300 text-2xl">&#9203;</div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white dark:bg-slate-800 rounded-2xl p-5 shadow-sm border border-teal-200 dark:border-teal-500/30 border-t-4 border-t-teal-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng tiền</p>
                                <p class="mt-2 text-2xl font-bold text-teal-600 dark:text-teal-300"><%= df.format(totalAmount) %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 dark:bg-teal-500/10 text-teal-600 dark:text-teal-300 text-2xl">&#128176;</div>
                        </div>
                    </div>
                </div>

                <!-- Filter & Search -->
                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                    <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                        <div class="flex flex-wrap gap-2">
                            <a href="PaymentController?action=list" class="rounded-2xl border px-4 py-2.5 text-sm font-medium <%= "list".equals(currentAction) ? "border-teal-600 bg-teal-600 text-white shadow-sm shadow-teal-500/30" : "border-slate-200 bg-white text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700" %>">Tất cả</a>
                            <a href="PaymentController?action=pending" class="rounded-2xl border px-4 py-2.5 text-sm font-medium <%= "pending".equals(currentAction) ? "border-amber-500 bg-amber-500 text-white shadow-sm shadow-amber-500/30" : "border-slate-200 bg-white text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700" %>">Chờ thanh toán</a>
                            <a href="PaymentController?action=paid" class="rounded-2xl border px-4 py-2.5 text-sm font-medium <%= "paid".equals(currentAction) ? "border-emerald-600 bg-emerald-600 text-white shadow-sm shadow-emerald-500/30" : "border-slate-200 bg-white text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700" %>">Đã thanh toán</a>
                        </div>
                        <form action="PaymentController" method="get" class="flex w-full flex-col gap-2 sm:w-auto sm:flex-row">
                            <input type="hidden" name="action" value="search"/>
                            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>"
                                   placeholder="Tìm mã thanh toán, hóa đơn hoặc khách hàng..."
                                   class="form-input min-w-[280px] rounded-2xl border border-slate-200 px-4 py-2.5 transition-all dark:border-slate-700">
                            <button type="submit" class="rounded-2xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600">
                                Tìm kiếm
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Payment Table -->
                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="overflow-x-auto">
                        <table class="min-w-full">
                            <thead>
                                <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã TT</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã hóa đơn</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Số tiền</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Phương thức</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Trạng thái</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Khách hàng</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tạo lúc</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (paymentList.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" class="px-6 py-16 text-center text-slate-400 dark:text-slate-500">
                                        <div class="mx-auto flex max-w-md flex-col items-center gap-3">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-700/60 dark:text-slate-500">
                                                <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="text-base font-semibold text-slate-700 dark:text-slate-200">Chưa có thanh toán nào</p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo mã QR thanh toán mới để bắt đầu theo dõi giao dịch của khách hàng.</p>
                                            </div>
                                            <button type="button" onclick="openQrModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                </svg>
                                                Tạo QR mới
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (PaymentDTO p : paymentList) { %>
                                    <tr class="border-b border-slate-50 transition-colors hover:bg-slate-50 dark:border-slate-800 dark:hover:bg-slate-800/60 last:border-0">
                                        <td class="px-4 py-4 align-top">
                                            <div class="font-semibold text-teal-600 dark:text-teal-300">#<%= p.getPaymentId() %></div>
                                            <div class="mt-1 text-xs text-slate-400 dark:text-slate-500">Thanh toán QR</div>
                                        </td>
                                        <td class="px-4 py-4 align-top text-slate-600 dark:text-slate-300">
                                            <div class="font-medium text-slate-700 dark:text-slate-200">HD<%= String.format("%06d", p.getBillId()) %></div>
                                            <div class="mt-1 text-xs text-slate-400 dark:text-slate-500">Liên kết hóa đơn</div>
                                        </td>
                                        <td class="px-4 py-4 align-top text-right">
                                            <div class="font-bold text-teal-600 dark:text-teal-300"><%= df.format(p.getAmount()) %> VND</div>
                                            <div class="mt-1 text-xs text-slate-400 dark:text-slate-500">Giá trị giao dịch</div>
                                        </td>
                                        <td class="px-4 py-4 align-top text-slate-600 dark:text-slate-300">
                                            <span class="inline-flex items-center rounded-xl bg-slate-100 px-3 py-1 text-sm font-medium text-slate-700 dark:bg-slate-800 dark:text-slate-300"><%= p.getPaymentMethod() != null ? p.getPaymentMethod() : "QR" %></span>
                                        </td>
                                        <td class="px-4 py-4 align-top text-center">
                                            <span class="inline-flex items-center rounded-full px-3 py-1 text-xs font-bold <%= getStatusClass(p.getStatus()) %>">
                                                <%= getStatusText(p.getStatus()) %>
                                            </span>
                                        </td>
                                        <td class="px-4 py-4 align-top text-slate-600 dark:text-slate-300">
                                            <div class="font-medium text-slate-700 dark:text-slate-200"><%= p.getCustomerName() != null ? p.getCustomerName() : "Khách lẻ" %></div>
                                            <div class="mt-1 text-xs text-slate-400 dark:text-slate-500">Người thanh toán</div>
                                        </td>
                                        <td class="px-4 py-4 align-top text-sm text-slate-500 dark:text-slate-400">
                                            <div><%= p.getCreatedAt() != null ? sdf.format(p.getCreatedAt()) : "-" %></div>
                                        </td>
                                        <td class="px-4 py-4 align-top text-center">
                                            <div class="flex items-center justify-center gap-2">
                                                <a href="payment-qr.jsp?payment_id=<%= p.getPaymentId() %>"
                                                   class="px-3 py-1.5 rounded-xl bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm shadow-blue-500/30">
                                                    Xem QR
                                                </a>
                                                <% if ("PENDING".equals(p.getStatus())) { %>
                                                <form action="PaymentController" method="post" style="display:inline;" onsubmit="return confirm('Xác nhận khách hàng đã thanh toán?')">
                                                    <input type="hidden" name="action" value="confirmPayment"/>
                                                    <input type="hidden" name="payment_id" value="<%= p.getPaymentId() %>"/>
                                                    <button type="submit" class="px-3 py-1.5 rounded-xl bg-emerald-600 text-white text-sm font-medium hover:bg-emerald-700 transition-colors shadow-sm shadow-emerald-500/30">
                                                        Xác nhận
                                                    </button>
                                                </form>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% if (!paymentList.isEmpty()) { %>
                    <div class="px-4 py-3 border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-sm text-slate-500 dark:text-slate-400">
                        Tổng cộng: <span class="font-semibold"><%= paymentList.size() %></span> thanh toán
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <div id="qrModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-2xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start justify-between border-b border-slate-100 px-6 py-5 dark:border-slate-800">
                <div>
                    <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tạo mã QR thanh toán</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo nhanh QR thanh toán ngay trên màn hình hiện tại.</p>
                </div>
                <button type="button" onclick="closeQrModal()" class="rounded-2xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="PaymentController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="createQr"/>
                <div class="grid gap-5 md:grid-cols-2">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Mã hóa đơn *</label>
                        <input type="number" name="bill_id" placeholder="Nhập mã hóa đơn" required class="form-input w-full rounded-2xl border border-slate-200 px-4 py-3 dark:border-slate-700"/>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số tiền (VND) *</label>
                        <input type="number" name="amount" placeholder="Nhập số tiền" step="1000" min="1000" required class="form-input w-full rounded-2xl border border-slate-200 px-4 py-3 dark:border-slate-700"/>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Thời gian hiệu lực</label>
                        <select name="expire_minutes" class="form-input w-full rounded-2xl border border-slate-200 px-4 py-3 dark:border-slate-700">
                            <option value="5">5 phút</option>
                            <option value="10">10 phút</option>
                            <option value="15" selected>15 phút</option>
                            <option value="30">30 phút</option>
                            <option value="60">60 phút</option>
                        </select>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Tên khách hàng</label>
                        <input type="text" name="customer_name" placeholder="Nhập tên khách hàng" class="form-input w-full rounded-2xl border border-slate-200 px-4 py-3 dark:border-slate-700"/>
                    </div>
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Email khách hàng</label>
                        <input type="email" name="customer_email" placeholder="Nhập email khách hàng" class="form-input w-full rounded-2xl border border-slate-200 px-4 py-3 dark:border-slate-700"/>
                    </div>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-100 pt-5 dark:border-slate-800 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeQrModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-5 py-2.5 font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Hủy</button>
                    <button type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        Tạo mã QR
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script>
        const qrModal = document.getElementById('qrModal');
        function openQrModal() {
            if (!qrModal) return;
            qrModal.classList.remove('hidden');
            qrModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }
        function closeQrModal() {
            if (!qrModal) return;
            qrModal.classList.add('hidden');
            qrModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
        }
        if (qrModal) {
            qrModal.addEventListener('click', function(event) {
                if (event.target === qrModal) {
                    closeQrModal();
                }
            });
        }
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeQrModal();
            }
        });
    </script>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>
</body>
</html>
