<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.ArrayList, java.util.Map, java.util.HashMap, pms.model.BillDTO, pms.model.CustomerDTO, pms.model.ItemDTO, pms.model.PaymentDTO, pms.model.UserDTO, java.text.DecimalFormat, java.text.SimpleDateFormat, pms.utils.SystemConfigService"%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");
    
    ArrayList<BillDTO> billList = (ArrayList<BillDTO>) request.getAttribute("billList");
    ArrayList<CustomerDTO> customers = (ArrayList<CustomerDTO>) request.getAttribute("customers");
    ArrayList<ItemDTO> items = (ArrayList<ItemDTO>) request.getAttribute("items");
    Map<Integer, CustomerDTO> customerMap = (Map<Integer, CustomerDTO>) request.getAttribute("customerMap");
    Map<Integer, PaymentDTO> latestPaymentMap = (Map<Integer, PaymentDTO>) request.getAttribute("latestPaymentMap");
    UserDTO user = (UserDTO) session.getAttribute("user");
    
    String msg = request.getAttribute("msg") != null ? (String) request.getAttribute("msg") : request.getParameter("msg");
    String error = request.getAttribute("error") != null ? (String) request.getAttribute("error") : request.getParameter("error");
    String billPopupTitle = request.getAttribute("billPopupTitle") != null ? (String) request.getAttribute("billPopupTitle") : "Thông báo";
    String billPopupMessage = request.getAttribute("billPopupMessage") != null ? (String) request.getAttribute("billPopupMessage") : "";
    String billPopupActionUrl = request.getAttribute("billPopupActionUrl") != null ? (String) request.getAttribute("billPopupActionUrl") : "";
    String billPopupActionLabel = request.getAttribute("billPopupActionLabel") != null ? (String) request.getAttribute("billPopupActionLabel") : "";
    boolean billPopupReopenModal = Boolean.TRUE.equals(request.getAttribute("billPopupReopenModal"));
    String filterStatus = request.getParameter("filter");
    String searchKeyword = request.getParameter("keyword");
    
    if (billList == null) billList = new ArrayList<>();
    if (customers == null) customers = new ArrayList<>();
    if (items == null) items = new ArrayList<>();
    if (customerMap == null) customerMap = new HashMap<>();
    if (latestPaymentMap == null) latestPaymentMap = new HashMap<>();
    if (filterStatus == null) filterStatus = "all";
    
    DecimalFormat df = new DecimalFormat("#,###");
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

    StringBuilder itemTypeOptions = new StringBuilder();
    itemTypeOptions.append("<option value=\"\" disabled selected hidden>-- Chọn sản phẩm --</option>");
    for (ItemDTO item : items) {
        if (item == null) continue;
        String rawType = item.getItemType() != null ? item.getItemType().trim() : "";
        String normalizedType = rawType.toLowerCase().replaceAll("\\s+", "");
        boolean isProductType = "sanpham".equals(normalizedType)
                || "sảnphẩm".equals(normalizedType)
                || "product".equals(normalizedType);
        if (!isProductType) continue;

        String itemType = rawType.isEmpty() ? "SanPham" : rawType;
        String itemName = item.getItemName() != null ? item.getItemName().trim() : "Item #" + item.getItemID();
        String itemLabel = itemName + " (" + itemType + ")";
        itemTypeOptions.append("<option value=\"")
                .append(item.getItemID())
                .append("\">")
                .append(itemLabel.replace("<", "&lt;").replace(">", "&gt;"))
                .append("</option>");
    }
    String quoteItemOptionsHtml = itemTypeOptions.toString()
            .replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\r", "")
            .replace("\n", "");
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "bill";
    String pageTitle = "Quản lý hóa đơn";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    int unreadCount = session.getAttribute("unreadCount") != null ? (Integer) session.getAttribute("unreadCount") : 0;
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
    
    SystemConfigService configService = new SystemConfigService();
    String receiverBankBin = configService.getBankBin();
    String receiverBankAccount = configService.getBankAccount();
    String receiverBankAccountName = configService.getBankAccountName();
    if (receiverBankBin == null || receiverBankBin.trim().isEmpty()) receiverBankBin = "970406";
    if (receiverBankAccount == null || receiverBankAccount.trim().isEmpty()) receiverBankAccount = "1234567890";
    if (receiverBankAccountName == null || receiverBankAccountName.trim().isEmpty()) receiverBankAccountName = "CONG TY TNHH PMS";

    String bankAccountsData = configService.getConfig("BANK_RECEIVER_ACCOUNTS", "");
    String bankActiveAccountId = configService.getConfig("BANK_ACTIVE_ACCOUNT_ID", "");
    if (bankAccountsData == null || bankAccountsData.trim().isEmpty()) {
        bankAccountsData = "A1||" + receiverBankBin + "||" + receiverBankAccount + "||" + receiverBankAccountName;
    }
    if (bankActiveAccountId == null) {
        bankActiveAccountId = "";
    }

    ArrayList<String[]> receiverAccountList = new ArrayList<>();
    if (bankAccountsData != null && !bankAccountsData.trim().isEmpty()) {
        String[] accountRows = bankAccountsData.split(";;");
        for (String row : accountRows) {
            if (row == null || row.trim().isEmpty()) continue;
            String[] parts = row.split("\\|\\|", -1);
            if (parts.length < 4) continue;
            String id = parts[0] != null ? parts[0].trim() : "";
            String bin = parts[1] != null ? parts[1].trim() : "";
            String account = parts[2] != null ? parts[2].trim() : "";
            String name = parts[3] != null ? parts[3].trim() : "";
            if (id.isEmpty() || bin.isEmpty() || account.isEmpty() || name.isEmpty()) continue;
            receiverAccountList.add(new String[]{id, bin, account, name});
        }
    }
    if (receiverAccountList.isEmpty()) {
        receiverAccountList.add(new String[]{"A1", receiverBankBin, receiverBankAccount, receiverBankAccountName});
    }

    boolean hasActiveReceiver = false;
    for (String[] acc : receiverAccountList) {
        if (acc[0].equals(bankActiveAccountId)) {
            hasActiveReceiver = true;
            break;
        }
    }
    if (!hasActiveReceiver) {
        bankActiveAccountId = receiverAccountList.get(0)[0];
    }

    String bankAccountsDataJs = bankAccountsData.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
    String bankActiveAccountIdJs = bankActiveAccountId.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
    String billPopupTitleJs = billPopupTitle.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
    String billPopupMessageJs = billPopupMessage.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
    String billPopupActionUrlJs = billPopupActionUrl.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
    String billPopupActionLabelJs = billPopupActionLabel.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");

    double totalAmount = 0;
    int countPaid = 0;
    int countPending = 0;
    
    for (BillDTO b : billList) {
        PaymentDTO latestPayment = latestPaymentMap.get(b.getBill_id());
        boolean paymentExpired = latestPayment != null
                && latestPayment.getExpiresAt() != null
                && !"PAID".equalsIgnoreCase(latestPayment.getStatus())
                && latestPayment.getExpiresAt().before(new java.util.Date());
        if (latestPayment != null && "PAID".equalsIgnoreCase(latestPayment.getStatus())) {
            countPaid++;
            if (b.getTotal_amount() > 0) {
                totalAmount += b.getTotal_amount();
            }
        } else if (latestPayment == null || "PENDING".equalsIgnoreCase(latestPayment.getStatus()) || paymentExpired || "EXPIRED".equalsIgnoreCase(latestPayment.getStatus())) {
            countPending++;
        }
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản Lý Hóa Đơn - PMS</title>
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
        };
    </script>
    <style>
        * { font-family: 'Inter', 'Segoe UI', Arial, sans-serif; }
        body { overflow-x: hidden; }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .sidebar-header { position: sticky; top: 0; background: #0f172a; z-index: 10; }
        .sidebar-nav { flex: 1; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
        .sidebar-footer { position: sticky; bottom: 0; background: #0f172a; z-index: 10; }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        .kpi-card { transition: all 0.2s ease; }
        .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(0,0,0,0.1); }
        .dark .kpi-card { background: #1e293b; border-color: #334155; }
        .status-paid { background: #d1fae5; color: #047857; }
        .status-pending { background: #fef3c7; color: #b45309; }
        .status-cancelled { background: #fee2e2; color: #b91c1c; }
        .filter-btn { transition: all 0.2s; }
        .filter-btn:hover { transform: translateY(-1px); }
        .dark body, .dark .main-header, .dark .bg-white { background-color: #1e293b !important; }
        .dark .text-slate-900, .dark .text-slate-800, .dark .text-slate-700 { color: #e2e8f0 !important; }
        .dark .border-slate-200 { border-color: #334155 !important; }
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
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý hóa đơn</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Theo dõi hóa đơn, trạng thái thanh toán và tổng doanh thu từ đơn sản xuất.</p>
                    </div>
                    <div class="flex flex-wrap items-center gap-3">
                        <a href="MainController?action=listBill&filter=all" class="inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">
                            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                            </svg>
                            Làm mới
                        </a>
                        <button type="button" onclick="openAddModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                            </svg>
                            Tạo hóa đơn mới
                        </button>
                    </div>
                </div>

                <!-- Receiver Info (Compact) -->
                <div class="mb-6 rounded-2xl border border-teal-200 bg-white/95 p-4 shadow-sm dark:border-teal-500/20 dark:bg-slate-800/70">
                    <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                        <div>
                            <p class="text-[11px] font-semibold uppercase tracking-[0.12em] text-teal-600 dark:text-teal-300">Thông tin nhận tiền</p>
                            <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">
                                <span class="font-semibold text-slate-800 dark:text-slate-100"><%= receiverBankAccountName %></span>
                                · STK <span class="font-semibold text-slate-800 dark:text-slate-100"><%= receiverBankAccount %></span>
                            </p>
                        </div>
                        <div class="flex w-full flex-col gap-2 sm:w-auto sm:flex-row sm:items-center sm:justify-end">
                            <form action="PaymentController" method="post" class="w-full sm:w-auto">
                                <input type="hidden" name="action" value="switchActiveAccountQuick" />
                                <input type="hidden" name="redirect" value="MainController?action=listBill" />
                                <select name="active_account_id" onchange="this.form.submit()" class="min-w-[230px] rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:focus:ring-teal-500/30">
                                    <% for (String[] acc : receiverAccountList) { %>
                                    <option value="<%= acc[0] %>" <%= acc[0].equals(bankActiveAccountId) ? "selected" : "" %>><%= acc[3] %> · <%= acc[2] %></option>
                                    <% } %>
                                </select>
                            </form>
                            <a href="PaymentController?action=list" class="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700 transition-colors hover:bg-slate-100 dark:border-slate-700 dark:bg-slate-700/70 dark:text-slate-200 dark:hover:bg-slate-700">
                                Xem chi tiết thanh toán
                            </a>
                        </div>
                    </div>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center gap-3 dark:bg-emerald-900/30 dark:border-emerald-700 dark:text-emerald-300">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3 dark:bg-red-900/30 dark:border-red-700 dark:text-red-300">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <!-- Stats Cards -->
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                    <div class="kpi-card bg-white rounded-2xl p-5 shadow-sm border-t-4 border-blue-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500">Tổng Số Hóa Đơn</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800"><%= billList.size() %></p>
                                <p class="mt-1 text-xs text-slate-400">Tất cả hóa đơn</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white rounded-2xl p-5 shadow-sm border-t-4 border-emerald-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500">Đã Thanh Toán</p>
                                <p class="mt-2 text-3xl font-bold text-emerald-600"><%= countPaid %></p>
                                <p class="mt-1 text-xs text-slate-400">Hóa đơn đã thanh toán</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white rounded-2xl p-5 shadow-sm border-t-4 border-amber-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500">Chờ Thanh Toán</p>
                                <p class="mt-2 text-3xl font-bold text-amber-600"><%= countPending %></p>
                                <p class="mt-1 text-xs text-slate-400">Hóa đơn chưa thanh toán</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-50 text-amber-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white rounded-2xl p-5 shadow-sm border-t-4 border-teal-500">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500">Tổng Tiền</p>
                                <p class="mt-2 text-2xl font-bold text-teal-600"><%= df.format(totalAmount) %></p>
                                <p class="mt-1 text-xs text-slate-400">VND</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 text-teal-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Actions Row -->
                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                    <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                        <div class="flex flex-wrap gap-2">
                            <a href="MainController?action=listBill&filter=all" class="filter-btn rounded-2xl border px-4 py-2 text-sm font-medium <%= "all".equals(filterStatus) ? "border-teal-600 bg-teal-600 text-white" : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700" %>">
                                Tất cả
                            </a>
                            <a href="MainController?action=listBill&filter=paid" class="filter-btn rounded-2xl border px-4 py-2 text-sm font-medium <%= "paid".equals(filterStatus) ? "border-emerald-600 bg-emerald-600 text-white" : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700" %>">
                                Đã thanh toán
                            </a>
                            <a href="MainController?action=listBill&filter=pending" class="filter-btn rounded-2xl border px-4 py-2 text-sm font-medium <%= "pending".equals(filterStatus) ? "border-amber-500 bg-amber-500 text-white" : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700" %>">
                                Chờ thanh toán
                            </a>
                        </div>
                        <form action="MainController" method="get" class="flex w-full flex-col gap-2 sm:w-auto sm:flex-row">
                            <input type="hidden" name="action" value="listBill"/>
                            <input type="hidden" name="filter" value="<%= filterStatus %>"/>
                            <input type="text" name="keyword" value="<%= searchKeyword != null ? searchKeyword : "" %>"
                                   placeholder="Tìm mã hóa đơn hoặc khách hàng..."
                                   class="min-w-[260px] rounded-2xl border border-slate-200 px-4 py-2.5 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white">
                            <button type="submit" class="rounded-2xl bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600">
                                Tìm kiếm
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Bills Table -->
                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 bg-slate-50 dark:bg-slate-700/50 dark:border-slate-700">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã HD</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Khách hàng</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng tiền</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Thanh toán</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Ngày lập</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (billList.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-6 py-16 text-center text-slate-400">
                                        <div class="mx-auto flex max-w-md flex-col items-center gap-3">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-700/60 dark:text-slate-500">
                                                <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="text-base font-semibold text-slate-700 dark:text-slate-200">Chưa có hóa đơn nào</p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo hóa đơn đầu tiên để theo dõi thanh toán và doanh thu ngay trên bảng điều khiển này.</p>
                                            </div>
                                            <button type="button" onclick="openAddModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                </svg>
                                                Tạo hóa đơn mới
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } else {
                                    for (BillDTO b : billList) {
                                        CustomerDTO customer = customerMap.get(b.getCustomer_id());
                                        PaymentDTO payment = latestPaymentMap.get(b.getBill_id());
                                        boolean paymentExpired = payment != null
                                                && payment.getExpiresAt() != null
                                                && !"PAID".equalsIgnoreCase(payment.getStatus())
                                                && payment.getExpiresAt().before(new java.util.Date());
                                        String statusClass = payment != null && "PAID".equalsIgnoreCase(payment.getStatus())
                                                ? "status-paid"
                                                : paymentExpired || (payment != null && "EXPIRED".equalsIgnoreCase(payment.getStatus()))
                                                        ? "status-cancelled"
                                                        : payment != null
                                                                ? "status-pending"
                                                                : ("pending".equalsIgnoreCase(b.getStatus()) ? "status-pending"
                                                                : "paid".equalsIgnoreCase(b.getStatus()) ? "status-paid" : "status-cancelled");
                                        String statusLabel = payment != null && "PAID".equalsIgnoreCase(payment.getStatus()) ? "Đã thanh toán"
                                                            : paymentExpired || (payment != null && "EXPIRED".equalsIgnoreCase(payment.getStatus())) ? "Hết hạn QR"
                                                            : payment != null ? "Chờ thanh toán"
                                                            : "pending".equalsIgnoreCase(b.getStatus()) ? "Chờ thanh toán"
                                                            : "paid".equalsIgnoreCase(b.getStatus()) ? "Đã thanh toán" : "Đã hủy";
                                        String paymentClass = payment == null ? "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"
                                                : "PAID".equalsIgnoreCase(payment.getStatus()) ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300"
                                                : paymentExpired ? "bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-300"
                                                : "PENDING".equalsIgnoreCase(payment.getStatus()) ? "bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300"
                                                : "bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-300";
                                        String paymentLabel = payment == null ? "Chưa tạo QR"
                                                : "PAID".equalsIgnoreCase(payment.getStatus()) ? "Đã thanh toán"
                                                : paymentExpired ? "Đã hết hạn"
                                                : "PENDING".equalsIgnoreCase(payment.getStatus()) ? "Chờ thanh toán"
                                                : "Đã hết hạn";
                                        String customerName = customer != null ? customer.getCustomer_name() : (b.getCustomer_id() > 0 ? "KH-" + b.getCustomer_id() : "Khách lẻ");
                                        String customerEmail = customer != null && customer.getEmail() != null ? customer.getEmail() : "";
                                        boolean isPaidPayment = payment != null && "PAID".equalsIgnoreCase(payment.getStatus());
                                        String qrDataValue = payment != null && payment.getQrCodeData() != null ? payment.getQrCodeData() : "";
                                        String qrImageBase64Value = qrDataValue;
                                        if (qrDataValue.contains("|QR_URL|")) {
                                            String[] qrParts = qrDataValue.split("\\|QR_URL\\|", 2);
                                            qrImageBase64Value = qrParts.length > 0 ? qrParts[0] : "";
                                        }
                                        String qrImageBase64Attr = qrImageBase64Value;
                                        String bankBinAttr = payment != null && payment.getBankBin() != null ? payment.getBankBin() : "";
                                        String bankAccountAttr = payment != null && payment.getBankAccount() != null ? payment.getBankAccount() : "";
                                        String bankAccountNameAttr = payment != null && payment.getBankAccountName() != null ? payment.getBankAccountName() : "";
                                        String expiresAtAttr = payment != null && payment.getExpiresAt() != null ? payment.getExpiresAt().toString() : "";
                                %>
                                <tr id="bill-row-<%= b.getBill_id() %>" class="border-b border-slate-50 last:border-0 hover:bg-slate-50 transition-colors dark:border-slate-700 dark:hover:bg-slate-700/50">
                                    <td class="px-4 py-3 align-top text-sm font-semibold text-slate-700 dark:text-slate-300">#<%= b.getBill_id() %></td>
                                    <td class="px-4 py-3 align-top text-sm text-slate-600 dark:text-slate-400">
                                        <div class="font-medium text-slate-700 dark:text-slate-200"><%= customerName %></div>
                                        <div class="mt-1 text-xs text-slate-400 dark:text-slate-500"><%= customerEmail != null && !customerEmail.isEmpty() ? customerEmail : "Chưa có email" %></div>
                                    </td>
                                    <td class="px-4 py-3 align-top text-sm text-right font-semibold text-teal-600 dark:text-teal-400"><%= df.format(b.getTotal_amount()) %> VND</td>
                                    <td class="px-4 py-3 align-top">
                                        <div class="flex flex-col gap-2">
                                            <div class="flex flex-wrap items-center gap-2">
                                                <span id="bill-status-<%= b.getBill_id() %>" class="inline-flex w-fit items-center px-2.5 py-1 rounded-full text-xs font-bold <%= statusClass %>">
                                                    <%= statusLabel %>
                                                </span>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-4 py-3 align-top text-sm text-slate-500 dark:text-slate-400">
                                        <%= b.getBill_date() != null ? sdf.format(b.getBill_date()) : "-" %>
                                    </td>
                                    <td class="px-4 py-3 align-top text-center">
                                        <div class="inline-grid grid-cols-3 gap-1.5">
                                            <% if (payment != null && !"PAID".equalsIgnoreCase(payment.getStatus())) { %>
                                            <form action="PaymentController" method="post" style="display:inline;" class="js-confirm-payment-form justify-self-center" data-bill-id="<%= b.getBill_id() %>" data-payment-id="<%= payment.getPaymentId() %>" onsubmit="confirmPaymentInline(event, this); return false;">
                                                <input type="hidden" name="action" value="confirmPayment"/>
                                                <input type="hidden" name="payment_id" value="<%= payment.getPaymentId() %>"/>
                                                <input type="hidden" name="source" value="bill"/>
                                                <input type="hidden" name="ajax" value="1"/>
                                                <button type="submit"
                                                        id="confirm-payment-btn-<%= b.getBill_id() %>"
                                                        class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-600 text-white transition-colors hover:bg-emerald-700 shadow-sm shadow-emerald-500/30"
                                                        title="Xác nhận thanh toán"
                                                        aria-label="Xác nhận thanh toán">
                                                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                                    </svg>
                                                </button>
                                            </form>
                                            <% } else { %>
                                            <span class="h-10 w-10 rounded-2xl opacity-0 pointer-events-none select-none" aria-hidden="true"></span>
                                            <% } %>
                                            <button type="button"
                                                    id="view-qr-btn-<%= b.getBill_id() %>"
                                                    data-mode="invoice"
                                                    data-bill-id="<%= b.getBill_id() %>"
                                                    data-amount="<%= payment != null ? payment.getAmount() : b.getTotal_amount() %>"
                                                    data-customer-name="<%= customerName %>"
                                                    data-customer-email="<%= customerEmail %>"
                                                    data-payment-id="<%= payment != null ? payment.getPaymentId() : "" %>"
                                                    data-bank-bin="<%= bankBinAttr %>"
                                                    data-bank-account="<%= bankAccountAttr %>"
                                                    data-bank-account-name="<%= bankAccountNameAttr %>"
                                                    data-expires-at="<%= expiresAtAttr %>"
                                                    data-paid-at="<%= payment != null && payment.getPaidAt() != null ? payment.getPaidAt().toString() : "" %>"
                                                    data-payment-status="<%= payment != null ? payment.getStatus() : "" %>"
                                                    data-qr-image-base64="<%= (!paymentExpired && payment != null) ? qrImageBase64Attr : "" %>"
                                                    onclick="openPaymentDetail(this)"
                                                    class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-indigo-600 text-white transition-colors hover:bg-indigo-700 shadow-sm shadow-indigo-500/30"
                                                    title="Xem hóa đơn"
                                                    aria-label="Xem hóa đơn">
                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                                </svg>
                                            </button>
                                            <button type="button"
                                                    data-bill-id="<%= b.getBill_id() %>"
                                                    data-bill-name="Hóa đơn #<%= b.getBill_id() %>"
                                                    data-customer-name="<%= customerName %>"
                                                    onclick="openDeleteBillModal(this)"
                                                    class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-rose-600 text-white transition-colors hover:bg-rose-700 shadow-sm shadow-rose-500/30"
                                                    title="Xóa hóa đơn"
                                                    aria-label="Xóa hóa đơn">
                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                                </svg>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% }} %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Add Bill Modal -->
    <div id="addModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-4xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-center justify-between border-b border-slate-100 p-6 dark:border-slate-800">
                <div>
                    <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tạo hóa đơn mới</h3>
                </div>
                <button onclick="closeAddModal()" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="BillController" method="post" class="p-6 space-y-4">
                <input type="hidden" name="action" value="addBill"/>
                
                <div>
                    <div class="mb-2 flex items-center justify-between gap-3">
                        <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300">Khách Hàng</label>
                        <button type="button" onclick="openQuickCustomerModal()" class="inline-flex items-center gap-1 rounded-xl border border-cyan-500 px-3 py-1.5 text-xs font-semibold text-cyan-600 hover:bg-cyan-50 dark:text-cyan-300 dark:hover:bg-cyan-900/20">
                            + Thêm khách hàng
                        </button>
                    </div>
                    <select id="billCustomerSelect" name="customer_id" required class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white">
                        <option value="" disabled selected hidden>-- Chọn khách hàng có sẵn --</option>
                        <% for (CustomerDTO c : customers) { %>
                        <option value="<%= c.getCustomer_id() %>"><%= c.getCustomer_name() %></option>
                        <% } %>
                    </select>
                </div>

                <div class="rounded-2xl border border-slate-200 p-4 dark:border-slate-700">
                    <div class="mb-3 flex items-center justify-between">
                        <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300">Chi tiết báo giá</label>
                        <button type="button" id="addQuoteLineBtn" class="inline-flex items-center gap-1 rounded-xl border border-teal-500 px-3 py-1.5 text-xs font-semibold text-teal-600 hover:bg-teal-50 dark:text-teal-300 dark:hover:bg-teal-900/20">
                            + Thêm dòng
                        </button>
                    </div>
                    <div id="quoteLinesContainer" class="space-y-2"></div>
                </div>
                
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2 dark:text-slate-300">Tổng Tiền (VND)</label>
                    <input id="billTotalAmount" type="number" name="total_amount" required min="1000" step="1000" placeholder="Hệ thống tự tính"
                           readonly
                           class="w-full cursor-not-allowed rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-slate-700 focus:border-slate-200 focus:outline-none focus:ring-0 dark:bg-slate-800 dark:border-slate-700 dark:text-white">
                </div>
                
                <div class="flex gap-3 pt-4">
                    <button type="submit" class="flex-1 py-3 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700">
                        Tạo Hóa Đơn
                    </button>
                    <button type="button" onclick="closeAddModal()" class="px-6 py-3 rounded-xl border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700">
                        Hủy
                    </button>
                </div>
            </form>
        </div>
    </div>

    <div id="quickCustomerModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-center justify-between border-b border-slate-100 p-6 dark:border-slate-800">
                <div>
                    <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Thêm khách hàng nhanh</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo mới khách hàng ngay trong luồng tạo hóa đơn.</p>
                </div>
                <button type="button" onclick="closeQuickCustomerModal()" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-300">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form id="quickCustomerForm" class="p-6 space-y-4">
                <div>
                    <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">Tên khách hàng <span class="text-red-500">*</span></label>
                    <input type="text" name="customer_name" required maxlength="100" placeholder="VD: Nguyễn Văn A"
                           class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white" />
                </div>
                <div class="grid gap-3 sm:grid-cols-2">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">Số điện thoại <span class="text-red-500">*</span></label>
                        <input type="text" name="phone" required maxlength="15" placeholder="VD: 0901234567"
                               class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white" />
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">Email <span class="text-red-500">*</span></label>
                        <input type="email" name="email" required maxlength="50" placeholder="VD: khachhang@email.com"
                               class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-cyan-500 focus:outline-none focus:ring-2 focus:ring-cyan-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white" />
                    </div>
                </div>
                <div id="quickCustomerStatus" class="hidden rounded-xl border px-3 py-2 text-sm"></div>
                <div class="flex gap-3 pt-2">
                    <button type="submit" class="flex-1 rounded-xl bg-cyan-600 py-3 font-semibold text-white hover:bg-cyan-700">Lưu khách hàng</button>
                    <button type="button" onclick="closeQuickCustomerModal()" class="px-6 py-3 rounded-xl border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700">Đóng</button>
                </div>
            </form>
        </div>
    </div>

    <div id="deleteBillModal" class="fixed inset-0 z-[60] hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa hóa đơn?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">Bạn sắp xóa <span id="deleteBillName" class="font-semibold text-slate-700 dark:text-slate-200"></span> của <span id="deleteBillCustomer" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.</p>
                </div>
            </div>
            <form action="BillController" method="post" class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <input type="hidden" name="action" value="deleteBill"/>
                <input type="hidden" id="deleteBillId" name="bill_id" value=""/>
                <button type="button" onclick="closeDeleteBillModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-5 py-2.5 font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Hủy</button>
                <button type="submit" class="inline-flex items-center justify-center rounded-2xl bg-rose-600 px-5 py-2.5 font-semibold text-white shadow-sm shadow-rose-500/30 transition-all hover:bg-rose-700">Xóa hóa đơn</button>
            </form>
        </div>
    </div>

    <div id="qrModal" class="fixed inset-0 z-50 hidden items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
        <div class="flex max-h-[calc(100vh-2rem)] w-full max-w-2xl flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start justify-between border-b border-slate-100 px-6 py-5 dark:border-slate-800">
                <div>
                    <h3 id="qrModalTitle" class="text-lg font-semibold text-slate-900 dark:text-slate-100">Tạo mã QR thanh toán</h3>
                    <p id="qrModalDescription" class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo giao dịch QR trực tiếp ngay trong quản lý hóa đơn.</p>
                </div>
                <button type="button" onclick="closeQrModal()" class="rounded-2xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form id="qrCreateForm" action="PaymentController" method="post" class="flex-1 space-y-5 overflow-y-auto px-6 py-6">
                <input type="hidden" name="action" value="createQr"/>
                <input type="hidden" name="source" value="bill"/>
                <input type="hidden" name="ajax" value="1"/>
                <input id="qrPaymentId" type="hidden" name="payment_id" value=""/>
                <div id="qrFormFields" class="grid gap-5 md:grid-cols-2">
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Mã hóa đơn *</label>
                        <input id="qrBillId" type="number" name="bill_id" required readonly class="w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800 dark:text-white"/>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Số tiền (VND) *</label>
                        <input id="qrAmount" type="number" name="amount" step="1000" min="1000" required class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white"/>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Thời gian hiệu lực</label>
                        <select name="expire_minutes" class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white">
                            <option value="5">5 phút</option>
                            <option value="10">10 phút</option>
                            <option value="15">15 phút</option>
                            <option value="30">30 phút</option>
                            <option value="60">60 phút</option>
                            <option value="1440" selected>24 giờ</option>
                        </select>
                    </div>
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Tài khoản nhận tiền *</label>
                        <select id="qrReceiverAccount" class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white"></select>
                        <p id="qrReceiverAccountMeta" class="mt-2 text-xs text-slate-500 dark:text-slate-400">--</p>
                        <input id="qrBankBin" type="hidden" name="bank_bin"/>
                        <input id="qrBankAccount" type="hidden" name="bank_account"/>
                        <input id="qrBankAccountName" type="hidden" name="bank_account_name"/>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Tên khách hàng</label>
                        <input id="qrCustomerName" type="text" name="customer_name" class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white"/>
                    </div>
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-200">Email khách hàng</label>
                        <input id="qrCustomerEmail" type="email" name="customer_email" class="w-full rounded-2xl border border-slate-200 px-4 py-3 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white"/>
                    </div>
                </div>
                <div id="qrResult" class="hidden space-y-4 rounded-2xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800/70">
                    <div class="bg-white p-2 text-center dark:bg-slate-900">
                        <div id="qrImageWrap" class="flex min-h-[200px] items-center justify-center"></div>
                    </div>
                    <div class="grid gap-3 md:grid-cols-2">
                        <div class="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-900">
                            <div class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Ngân hàng</div>
                            <div id="qrResultBankName" class="mt-2 text-base font-semibold text-slate-900 dark:text-white">--</div>
                        </div>
                        <div class="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-900">
                            <div class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Số tài khoản</div>
                            <div id="qrResultBankAccount" class="mt-2 text-base font-semibold text-slate-900 dark:text-white">--</div>
                        </div>
                        <div class="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-900">
                            <div class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Chủ tài khoản</div>
                            <div id="qrResultBankAccountName" class="mt-2 text-base font-semibold text-slate-900 dark:text-white">PMS Company</div>
                        </div>
                        <div class="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-900">
                            <div id="qrTimeLabel" class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hết hạn</div>
                            <div id="qrResultExpiresAt" class="mt-2 text-base font-semibold text-amber-600 dark:text-amber-300">--</div>
                            <div id="qrCountdown" class="mt-2 text-sm font-medium text-slate-500 dark:text-slate-400">--</div>
                        </div>
                    </div>
                    <div id="qrInvoiceActions" class="hidden border-t border-slate-200 pt-4 dark:border-slate-700">
                        <div class="flex flex-col gap-2 sm:flex-row sm:justify-end">
                            <button id="qrRecreateButton" type="button" class="hidden inline-flex items-center justify-center gap-2 rounded-2xl bg-orange-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-orange-500/30 transition-colors hover:bg-orange-600">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 12a8 8 0 0113.66-5.66L20 8M20 4v4h-4M20 12a8 8 0 01-13.66 5.66L4 16M4 20v-4h4"/>
                                </svg>
                                Tạo lại mã QR
                            </button>
                            <a id="qrViewInvoiceLink" href="#" class="inline-flex items-center justify-center gap-2 rounded-2xl border border-slate-300 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.477 0 8.268 2.943 9.542 7-1.274 4.057-5.065 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                </svg>
                                Xem hóa đơn
                            </a>
                            <a id="qrDownloadInvoiceLink" href="#" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-cyan-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-cyan-500/30 transition-colors hover:bg-cyan-700">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v2a2 2 0 002 2h12a2 2 0 002-2v-2"/>
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 10l5 5 5-5"/>
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15V3"/>
                                </svg>
                                Tải hóa đơn
                            </a>
                        </div>
                    </div>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-100 pt-5 dark:border-slate-800 sm:flex-row sm:justify-end">
                    <button type="button" onclick="closeQrModal()" class="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-5 py-2.5 font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Đóng</button>
                    <button id="qrSubmitButton" type="submit" class="inline-flex items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                        <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                        </svg>
                        <span id="qrSubmitLabel">Tạo mã QR</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <div id="invoiceModal" class="fixed inset-0 z-[70] hidden items-center justify-center bg-slate-950/70 p-4 backdrop-blur-sm">
        <div class="flex h-[92vh] w-full max-w-[1120px] flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-center justify-between border-b border-slate-100 px-5 py-4 dark:border-slate-800">
                <div>
                    <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Xem hóa đơn</h3>
                </div>
                <div class="flex items-center gap-2">
                    <a id="invoiceModalDownload" href="#" target="_blank" rel="noopener" class="inline-flex items-center justify-center rounded-xl bg-slate-900 px-3 py-2 text-xs font-semibold text-white hover:bg-slate-700" title="Tải hóa đơn" aria-label="Tải hóa đơn">
                        Tải hóa đơn
                    </a>
                    <a id="invoiceModalDownloadPdf" href="#" target="_blank" rel="noopener" class="inline-flex items-center justify-center rounded-xl border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800">
                        Tải PDF
                    </a>
                    <button id="invoiceModalPrint" type="button" class="inline-flex items-center justify-center rounded-xl border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800">
                        In hóa đơn
                    </button>
                    <button type="button" onclick="closeInvoiceModal()" class="rounded-2xl p-2 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                    </button>
                </div>
            </div>
            <div class="flex-1 bg-slate-100 dark:bg-slate-800">
                <iframe id="invoiceModalFrame" src="about:blank" class="h-full w-full border-0" title="Invoice Preview"></iframe>
            </div>
        </div>
    </div>
 
    <script>
        const quoteItemOptionsHtml = '<%= quoteItemOptionsHtml %>';
        const billCustomerSelect = document.getElementById('billCustomerSelect');
        const billTotalAmount = document.getElementById('billTotalAmount');
        const addBillForm = document.querySelector('#addModal form');
        const addModal = document.getElementById('addModal');
        const quickCustomerModal = document.getElementById('quickCustomerModal');
        const quickCustomerForm = document.getElementById('quickCustomerForm');
        const quickCustomerStatus = document.getElementById('quickCustomerStatus');
        const deleteBillModal = document.getElementById('deleteBillModal');
        const qrModal = document.getElementById('qrModal');
        const qrCreateForm = document.getElementById('qrCreateForm');
        const qrModalTitle = document.getElementById('qrModalTitle');
        const qrModalDescription = document.getElementById('qrModalDescription');
        const qrFormFields = document.getElementById('qrFormFields');
        const qrSubmitButton = document.getElementById('qrSubmitButton');
        const qrSubmitLabel = document.getElementById('qrSubmitLabel');
        const qrResult = document.getElementById('qrResult');
        const qrImageWrap = document.getElementById('qrImageWrap');
        const qrResultBankName = document.getElementById('qrResultBankName');
        const qrResultBankAccount = document.getElementById('qrResultBankAccount');
        const qrResultBankAccountName = document.getElementById('qrResultBankAccountName');
        const qrResultExpiresAt = document.getElementById('qrResultExpiresAt');
        const qrCountdown = document.getElementById('qrCountdown');
        const qrTimeLabel = document.getElementById('qrTimeLabel');
        const qrReceiverAccount = document.getElementById('qrReceiverAccount');
        const qrReceiverAccountMeta = document.getElementById('qrReceiverAccountMeta');
        const qrBankBinInput = document.getElementById('qrBankBin');
        const qrBankAccountInput = document.getElementById('qrBankAccount');
        const qrBankAccountNameInput = document.getElementById('qrBankAccountName');
        const receiverAccountsRaw = '<%= bankAccountsDataJs %>';
        const receiverActiveIdRaw = '<%= bankActiveAccountIdJs %>';
        const receiverAccounts = [];
        const qrInvoiceActions = document.getElementById('qrInvoiceActions');
        const qrViewInvoiceLink = document.getElementById('qrViewInvoiceLink');
        const qrDownloadInvoiceLink = document.getElementById('qrDownloadInvoiceLink');
        const qrRecreateButton = document.getElementById('qrRecreateButton');
        const invoiceModal = document.getElementById('invoiceModal');
        const invoiceModalFrame = document.getElementById('invoiceModalFrame');
        const invoiceModalDownload = document.getElementById('invoiceModalDownload');
        const invoiceModalDownloadPdf = document.getElementById('invoiceModalDownloadPdf');
        const invoiceModalPrint = document.getElementById('invoiceModalPrint');
        let qrCountdownTimer = null;
        let errorPopupTimer = null;

        function parseReceiverAccounts(serialized) {
            if (!serialized || !serialized.trim()) return [];
            return serialized.split(';;').map(function (row) {
                const p = row.split('||');
                return p.length >= 4 ? { id: p[0], bin: p[1], account: p[2], name: p[3] } : null;
            }).filter(Boolean);
        }

        function findReceiverAccount(id) {
            return receiverAccounts.find(function (a) { return a.id === id; }) || null;
        }

        function syncQrReceiverAccountFields() {
            if (!qrReceiverAccount) return;
            const picked = findReceiverAccount(qrReceiverAccount.value) || receiverAccounts[0] || null;
            if (!picked) return;
            if (qrBankBinInput) qrBankBinInput.value = picked.bin || '';
            if (qrBankAccountInput) qrBankAccountInput.value = picked.account || '';
            if (qrBankAccountNameInput) qrBankAccountNameInput.value = picked.name || '';
            if (qrReceiverAccountMeta) {
                qrReceiverAccountMeta.textContent = 'STK: ' + (picked.account || '-') + ' · Chủ TK: ' + (picked.name || '-');
            }
        }

        function initReceiverAccounts() {
            const parsed = parseReceiverAccounts(receiverAccountsRaw);
            parsed.forEach(function (a) { receiverAccounts.push(a); });
            if (!receiverAccounts.length) {
                receiverAccounts.push({
                    id: 'A1',
                    bin: '<%= receiverBankBin %>',
                    account: '<%= receiverBankAccount %>',
                    name: '<%= receiverBankAccountName %>'
                });
            }

            if (!qrReceiverAccount) return;
            qrReceiverAccount.innerHTML = receiverAccounts.map(function (a) {
                return '<option value="' + a.id + '">' + (a.name || 'Tài khoản nhận tiền') + '</option>';
            }).join('');

            const active = findReceiverAccount(receiverActiveIdRaw) || receiverAccounts[0];
            qrReceiverAccount.value = active.id;
            syncQrReceiverAccountFields();
            qrReceiverAccount.addEventListener('change', syncQrReceiverAccountFields);
        }

        function createQuoteLineRow() {
            const row = document.createElement('div');
            row.className = 'quote-line grid gap-2 md:grid-cols-12';
            row.innerHTML = ''
                + '<select name="line_item_type" required class="md:col-span-4 rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white">'
                + quoteItemOptionsHtml
                + '</select>'
                + '<input type="number" name="line_quantity" required min="1" step="1" placeholder="SL" class="md:col-span-2 rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white" />'
                + '<input type="number" name="line_unit_price" required min="1000" step="1000" placeholder="Đơn giá" class="md:col-span-2 rounded-xl border border-slate-200 px-3 py-2 text-sm focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:bg-slate-800 dark:border-slate-700 dark:text-white" />'
                + '<div class="md:col-span-4 flex items-center gap-2">'
                + '  <input type="text" name="line_total_view" readonly placeholder="Thành tiền" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600 dark:bg-slate-800 dark:border-slate-700 dark:text-slate-300" />'
                + '  <button type="button" class="remove-quote-line inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-rose-600 text-white hover:bg-rose-700" title="Xóa dòng">×</button>'
                + '</div>';
            return row;
        }

        function recalcLineRow(row) {
            if (!row) return 0;
            const qtyInput = row.querySelector('input[name="line_quantity"]');
            const priceInput = row.querySelector('input[name="line_unit_price"]');
            const totalViewInput = row.querySelector('input[name="line_total_view"]');
            const qty = Number(qtyInput ? qtyInput.value : 0);
            const unit = Number(priceInput ? priceInput.value : 0);
            const lineTotal = qty > 0 && unit > 0 ? qty * unit : 0;
            if (totalViewInput) {
                totalViewInput.value = lineTotal > 0
                    ? new Intl.NumberFormat('vi-VN').format(lineTotal)
                    : '';
            }
            return lineTotal;
        }

        function recalcBillTotalFromLines() {
            const rows = document.querySelectorAll('#quoteLinesContainer .quote-line');
            let sum = 0;
            rows.forEach(function(row) {
                sum += recalcLineRow(row);
            });
            if (billTotalAmount) {
                billTotalAmount.value = sum > 0 ? String(Math.round(sum)) : '';
            }
        }

        function addQuoteLine() {
            const container = document.getElementById('quoteLinesContainer');
            if (!container) return;
            const row = createQuoteLineRow();
            container.appendChild(row);

            const qtyInput = row.querySelector('input[name="line_quantity"]');
            const unitInput = row.querySelector('input[name="line_unit_price"]');
            const removeBtn = row.querySelector('.remove-quote-line');
            if (qtyInput) qtyInput.addEventListener('input', recalcBillTotalFromLines);
            if (unitInput) unitInput.addEventListener('input', recalcBillTotalFromLines);
            if (removeBtn) {
                removeBtn.addEventListener('click', function() {
                    row.remove();
                    recalcBillTotalFromLines();
                });
            }
        }

        function resetQuoteLines() {
            const container = document.getElementById('quoteLinesContainer');
            if (!container) return;
            container.innerHTML = '';
            addQuoteLine();
        }

        function ensureBillCustomerSelected() {
            if (!billCustomerSelect) return;
            billCustomerSelect.selectedIndex = 0;
        }

        function ensureErrorPopup() {
            let popup = document.getElementById('billErrorPopup');
            if (popup) return popup;

            popup = document.createElement('div');
            popup.id = 'billErrorPopup';
            popup.className = 'pointer-events-none fixed inset-x-0 top-6 z-[120] mx-auto hidden w-full max-w-lg px-4';
            popup.innerHTML = ''
                + '<div class="pointer-events-auto rounded-2xl border border-rose-200 bg-white/95 p-4 shadow-2xl backdrop-blur dark:border-rose-900/60 dark:bg-slate-900/95">'
                + '  <div class="flex items-start gap-3">'
                + '    <div class="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-rose-100 text-rose-600 dark:bg-rose-500/20 dark:text-rose-300">!<\/div>'
                + '    <div class="min-w-0 flex-1">'
                + '      <div id="billErrorPopupTitle" class="text-sm font-bold text-rose-700 dark:text-rose-300">Lỗi dữ liệu<\/div>'
                + '      <div id="billErrorPopupMessage" class="mt-1 text-sm leading-5 text-slate-700 dark:text-slate-200"><\/div>'
                + '      <div id="billErrorPopupActions" class="mt-4 hidden flex flex-wrap gap-2">'
                + '        <a id="billErrorPopupActionLink" href="#" class="inline-flex items-center rounded-xl bg-rose-600 px-3 py-2 text-xs font-semibold text-white transition hover:bg-rose-700">Xem cấu hình<\/a>'
                + '        <button type="button" id="billErrorPopupCloseBtn" class="inline-flex items-center rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800">Đóng<\/button>'
                + '      <\/div>'
                + '    <\/div>'
                + '  <\/div>'
                + '<\/div>';
            document.body.appendChild(popup);

            const closeBtn = document.getElementById('billErrorPopupCloseBtn');
            if (closeBtn) {
                closeBtn.addEventListener('click', function() {
                    popup.classList.add('hidden');
                });
            }
            return popup;
        }

        function showErrorPopup(message, options) {
            const popup = ensureErrorPopup();
            const titleNode = document.getElementById('billErrorPopupTitle');
            const messageNode = document.getElementById('billErrorPopupMessage');
            const actionWrap = document.getElementById('billErrorPopupActions');
            const actionLink = document.getElementById('billErrorPopupActionLink');
            const title = options && options.title ? options.title : 'Lỗi dữ liệu';
            const actionUrl = options && options.actionUrl ? options.actionUrl : '';
            const actionLabel = options && options.actionLabel ? options.actionLabel : 'Xem cấu hình';
            const persistent = !!(options && options.persist);

            if (titleNode) {
                titleNode.textContent = title;
            }
            if (messageNode) {
                messageNode.textContent = message || 'Vui lòng kiểm tra lại dữ liệu nhập.';
            }
            if (actionWrap && actionLink) {
                if (actionUrl) {
                    actionLink.href = actionUrl;
                    actionLink.textContent = actionLabel;
                    actionWrap.classList.remove('hidden');
                    actionWrap.classList.add('flex');
                } else {
                    actionWrap.classList.add('hidden');
                    actionWrap.classList.remove('flex');
                    actionLink.setAttribute('href', '#');
                }
            }

            popup.classList.remove('hidden');

            if (errorPopupTimer) {
                clearTimeout(errorPopupTimer);
                errorPopupTimer = null;
            }
            if (!persistent) {
                errorPopupTimer = setTimeout(function() {
                    popup.classList.add('hidden');
                }, 3200);
            }
        }

        function getFieldLabel(input) {
            if (!input) return 'trường dữ liệu';
            const row = input.closest('.quote-line');
            if (row && input.name === 'line_item_type') return 'sản phẩm';
            if (row && input.name === 'line_quantity') return 'số lượng';
            if (row && input.name === 'line_unit_price') return 'đơn giá';
            if (input.name === 'customer_id') return 'khách hàng';
            if (input.name === 'total_amount') return 'tổng tiền';
            return 'trường dữ liệu';
        }

        function buildValidationMessage(input) {
            if (!input || !input.validity) return 'Dữ liệu chưa hợp lệ. Vui lòng kiểm tra lại.';
            const label = getFieldLabel(input);
            if (input.validity.valueMissing) return 'Vui lòng nhập ' + label + '.';
            if (input.validity.typeMismatch) return 'Định dạng ' + label + ' chưa đúng.';
            if (input.validity.rangeUnderflow) {
                if (input.name === 'line_quantity') return 'Số lượng phải lớn hơn hoặc bằng 1.';
                if (input.name === 'line_unit_price') return 'Đơn giá phải lớn hơn hoặc bằng 0.';
                return 'Giá trị ' + label + ' nhỏ hơn mức cho phép.';
            }
            if (input.validity.stepMismatch) {
                if (input.name === 'line_unit_price') return 'Đơn giá phải là bội số của 1.000 VND.';
                if (input.name === 'line_quantity') return 'Số lượng phải là số nguyên hợp lệ.';
                return 'Giá trị ' + label + ' không đúng bước nhập cho phép.';
            }
            if (input.validity.badInput) return 'Giá trị ' + label + ' không hợp lệ.';
            return 'Dữ liệu chưa hợp lệ. Vui lòng kiểm tra lại.';
        }

        function setQuickCustomerStatus(message, isError) {
            if (!quickCustomerStatus) return;
            quickCustomerStatus.classList.remove('hidden', 'border-red-200', 'text-red-700', 'bg-red-50', 'border-emerald-200', 'text-emerald-700', 'bg-emerald-50');
            quickCustomerStatus.classList.add(isError ? 'border-red-200' : 'border-emerald-200');
            quickCustomerStatus.classList.add(isError ? 'text-red-700' : 'text-emerald-700');
            quickCustomerStatus.classList.add(isError ? 'bg-red-50' : 'bg-emerald-50');
            quickCustomerStatus.textContent = message || '';
        }

        function openQuickCustomerModal() {
            if (!quickCustomerModal) return;
            quickCustomerModal.classList.remove('hidden');
            quickCustomerModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
            if (quickCustomerForm) {
                quickCustomerForm.reset();
            }
            if (quickCustomerStatus) {
                quickCustomerStatus.classList.add('hidden');
                quickCustomerStatus.textContent = '';
            }
            const firstInput = quickCustomerForm ? quickCustomerForm.querySelector('input[name="customer_name"]') : null;
            if (firstInput) firstInput.focus();
        }

        function closeQuickCustomerModal() {
            if (!quickCustomerModal) return;
            quickCustomerModal.classList.add('hidden');
            quickCustomerModal.classList.remove('flex');
            if ((!addModal || addModal.classList.contains('hidden')) && (!deleteBillModal || deleteBillModal.classList.contains('hidden')) && (!qrModal || qrModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function openAddModal() {
            if (!addModal) return;
            addModal.classList.remove('hidden');
            addModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
            ensureBillCustomerSelected();
            resetQuoteLines();
            if (billCustomerSelect) billCustomerSelect.focus();
        }

        function closeAddModal() {
            if (!addModal) return;
            addModal.classList.add('hidden');
            addModal.classList.remove('flex');
            if (!deleteBillModal || deleteBillModal.classList.contains('hidden')) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function openDeleteBillModal(button) {
            if (!deleteBillModal || !button) return;
            document.getElementById('deleteBillId').value = button.getAttribute('data-bill-id') || '';
            document.getElementById('deleteBillName').textContent = button.getAttribute('data-bill-name') || 'hóa đơn này';
            document.getElementById('deleteBillCustomer').textContent = button.getAttribute('data-customer-name') || 'khách hàng liên quan';
            deleteBillModal.classList.remove('hidden');
            deleteBillModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteBillModal() {
            if (!deleteBillModal) return;
            deleteBillModal.classList.add('hidden');
            deleteBillModal.classList.remove('flex');
            if ((!addModal || addModal.classList.contains('hidden')) && (!qrModal || qrModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function stopQrCountdown() {
            if (qrCountdownTimer) {
                clearInterval(qrCountdownTimer);
                qrCountdownTimer = null;
            }
        }

        function formatCountdown(totalSeconds) {
            const safeSeconds = Math.max(0, totalSeconds);
            const hours = Math.floor(safeSeconds / 3600);
            const minutes = Math.floor((safeSeconds % 3600) / 60);
            const seconds = safeSeconds % 60;
            if (hours > 0) {
                return String(hours).padStart(2, '0') + ':'
                    + String(minutes).padStart(2, '0') + ':'
                    + String(seconds).padStart(2, '0');
            }
            return String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
        }

        function parseExpiresAt(value) {
            if (!value) return null;
            const normalized = value.replace(' ', 'T');
            const date = new Date(normalized);
            return Number.isNaN(date.getTime()) ? null : date;
        }

        function startQrCountdown(expiresAtValue) {
            stopQrCountdown();
            if (!qrCountdown) return;

            const expiresAtDate = parseExpiresAt(expiresAtValue);
            if (!expiresAtDate) {
                qrCountdown.textContent = '--';
                return;
            }

            const renderCountdown = function() {
                const remainingMs = expiresAtDate.getTime() - Date.now();
                if (remainingMs <= 0) {
                    qrCountdown.textContent = 'Đã hết hạn';
                    qrCountdown.classList.add('text-red-500', 'dark:text-red-400');
                    qrCountdown.classList.remove('text-slate-500', 'dark:text-slate-400');
                    markQrAsExpiredOnUi();
                    stopQrCountdown();
                    return;
                }
                const remainingSeconds = Math.floor(remainingMs / 1000);
                qrCountdown.textContent = 'Còn lại ' + formatCountdown(remainingSeconds);
                qrCountdown.classList.remove('text-red-500', 'dark:text-red-400');
                qrCountdown.classList.add('text-slate-500', 'dark:text-slate-400');
            };

            renderCountdown();
            qrCountdownTimer = setInterval(renderCountdown, 1000);
        }

        function resetQrResult() {
            stopQrCountdown();
            if (!qrResult) return;
            qrResult.classList.add('hidden');
            if (qrImageWrap) {
                qrImageWrap.innerHTML = '<div class="flex h-[200px] w-[200px] items-center justify-center rounded-xl bg-slate-200 text-center text-sm text-slate-500 dark:bg-slate-700 dark:text-slate-300">Chưa có dữ liệu QR</div>';
            }
            if (qrResultBankName) qrResultBankName.textContent = '--';
            if (qrResultBankAccount) qrResultBankAccount.textContent = '--';
            if (qrResultBankAccountName) qrResultBankAccountName.textContent = 'PMS Company';
            if (qrTimeLabel) qrTimeLabel.textContent = 'Hết hạn';
            if (qrResultExpiresAt) {
                qrResultExpiresAt.textContent = '--';
                qrResultExpiresAt.classList.remove('text-emerald-600', 'dark:text-emerald-300');
                qrResultExpiresAt.classList.add('text-amber-600', 'dark:text-amber-300');
            }
            if (qrCountdown) {
                qrCountdown.textContent = '--';
                qrCountdown.classList.remove('text-red-500', 'dark:text-red-400', 'text-emerald-600', 'dark:text-emerald-300');
                qrCountdown.classList.add('text-slate-500', 'dark:text-slate-400');
            }
        }

        function buildInvoiceViewUrl(billId) {
            return '<%= request.getContextPath() %>/BillController?action=viewBillDetail&bill_id=' + encodeURIComponent(String(billId || ''));
        }

        function buildInvoiceDownloadUrl(billId) {
            return '<%= request.getContextPath() %>/BillController?action=downloadBill&bill_id=' + encodeURIComponent(String(billId || ''));
        }

        function openInvoiceModalByBillId(billId) {
            if (!billId || !invoiceModal || !invoiceModalFrame) return;
            invoiceModalFrame.src = buildInvoiceViewUrl(billId);
            if (invoiceModalDownload) {
                invoiceModalDownload.href = buildInvoiceDownloadUrl(billId);
            }
            if (invoiceModalDownloadPdf) {
                invoiceModalDownloadPdf.href = buildInvoiceDownloadUrl(billId);
            }
            if (invoiceModalPrint) {
                invoiceModalPrint.onclick = function () {
                    try {
                        if (invoiceModalFrame && invoiceModalFrame.contentWindow) {
                            invoiceModalFrame.contentWindow.focus();
                            invoiceModalFrame.contentWindow.print();
                        }
                    } catch (e) {
                        window.print();
                    }
                };
            }
            invoiceModal.classList.remove('hidden');
            invoiceModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeInvoiceModal() {
            if (!invoiceModal || !invoiceModalFrame) return;
            invoiceModal.classList.add('hidden');
            invoiceModal.classList.remove('flex');
            invoiceModalFrame.src = 'about:blank';
            if (invoiceModalDownload) {
                invoiceModalDownload.href = '#';
            }
            if (invoiceModalDownloadPdf) {
                invoiceModalDownloadPdf.href = '#';
            }
            if (invoiceModalPrint) {
                invoiceModalPrint.onclick = null;
            }
            if ((!addModal || addModal.classList.contains('hidden'))
                    && (!deleteBillModal || deleteBillModal.classList.contains('hidden'))
                    && (!qrModal || qrModal.classList.contains('hidden'))
                    && (!quickCustomerModal || quickCustomerModal.classList.contains('hidden'))) {
                document.body.classList.remove('overflow-hidden');
            }
        }

        function updateQrInvoiceActions(billId, paymentStatus) {
            if (!qrInvoiceActions) return;
            const safeBillId = billId ? String(billId) : '';
            const hasBillId = !!safeBillId;
            const normalizedStatus = String(paymentStatus || '').toUpperCase();
            qrInvoiceActions.classList.toggle('hidden', !hasBillId);
            if (qrDownloadInvoiceLink) {
                qrDownloadInvoiceLink.href = hasBillId ? buildInvoiceDownloadUrl(safeBillId) : '#';
            }
            if (qrViewInvoiceLink) {
                qrViewInvoiceLink.href = hasBillId ? buildInvoiceViewUrl(safeBillId) : '#';
                qrViewInvoiceLink.onclick = null;
            }
            if (qrRecreateButton) {
                qrRecreateButton.classList.add('hidden');
                qrRecreateButton.dataset.billId = safeBillId;
                qrRecreateButton.dataset.paymentStatus = normalizedStatus;
            }
        }

        function markQrAsExpiredOnUi() {
            const qrBillIdInput = document.getElementById('qrBillId');
            const currentBillId = qrBillIdInput ? qrBillIdInput.value : '';
            if (qrImageWrap) {
                qrImageWrap.innerHTML = '<div class="flex h-[200px] w-[200px] items-center justify-center rounded-xl bg-slate-200 text-center text-sm text-slate-500 dark:bg-slate-700 dark:text-slate-300">Mã QR đã hết hạn</div>';
            }
            if (currentBillId) {
                updateBillRowPaymentState({
                    billId: currentBillId,
                    paymentId: document.getElementById('qrPaymentId') ? document.getElementById('qrPaymentId').value : '',
                    amount: document.getElementById('qrAmount') ? document.getElementById('qrAmount').value : '',
                    bankBin: qrBankBinInput ? qrBankBinInput.value : '',
                    bankAccount: qrBankAccountInput ? qrBankAccountInput.value : '',
                    bankAccountName: qrBankAccountNameInput ? qrBankAccountNameInput.value : '',
                    expiresAt: qrResultExpiresAt ? qrResultExpiresAt.textContent : '',
                    paidAt: '',
                    status: 'EXPIRED',
                    qrImageBase64: ''
                });
                updateQrInvoiceActions(currentBillId, 'EXPIRED');
            }
        }

        function openPaymentDetail(trigger) {
            if (!trigger) return;
            const billId = trigger.getAttribute('data-bill-id') || '';
            if (billId) {
                window.location.href = buildInvoiceViewUrl(billId);
            }
        }
 
        function getBankDisplayName(bankBin) {
            const code = String(bankBin || '').trim();
            if (!code) return '--';
            const bankMap = {
                '970403': 'Sacombank',
                '970405': 'Agribank',
                '970407': 'Techcombank',
                '970412': 'PVcomBank',
                '970414': 'OceanBank (MBV)',
                '970415': 'VietinBank',
                '970416': 'ACB',
                '970418': 'BIDV',
                '970419': 'NCB',
                '970422': 'MBBank',
                '970423': 'TPBank',
                '970424': 'Shinhan Bank Vietnam',
                '970425': 'ABBank',
                '970427': 'VietABank',
                '970428': 'Nam A Bank',
                '970429': 'Saigonbank',
                '970430': 'PGBank',
                '970431': 'Eximbank',
                '970432': 'VPBank',
                '970433': 'VietBank',
                '970434': 'Indovina Bank',
                '970436': 'Vietcombank',
                '970437': 'HDBank',
                '970438': 'BaoViet Bank',
                '970439': 'Public Bank Vietnam',
                '970440': 'SeABank',
                '970441': 'VIB',
                '970442': 'Hong Leong Bank Vietnam',
                '970443': 'SHB',
                '970444': 'CBBank (VNCB)',
                '970446': 'Co-opBank',
                '970448': 'OCB',
                '970449': 'LienVietPostBank (LPBank)',
                '970452': 'KienlongBank',
                '970454': 'VietCapitalBank (BVB)',
                '970457': 'Woori Bank Vietnam',
                '970458': 'United Overseas Bank Vietnam (UOB)'
            };
            return bankMap[code] || code;
        }

        function renderQrResult(result) {
            if (!qrResult) return;
            const bankName = getBankDisplayName(result.bankBin);
            const bankAccount = result.bankAccount || '--';
            const bankAccountName = result.bankAccountName || 'PMS Company';
            const expiresAt = result.expiresAt || '--';
            const paidAt = result.paidAt || '';
            const paymentStatus = (result.status || '').toUpperCase();
            const qrImageBase64 = result.qrImageBase64 || '';
            const hasQrImage = paymentStatus !== 'EXPIRED' && !!qrImageBase64;
 
            if (qrImageWrap) {
                qrImageWrap.innerHTML = hasQrImage
                    ? '<img src="data:image/png;base64,' + qrImageBase64 + '" alt="QR Code" class="mx-auto h-[200px] w-[200px] rounded-xl border border-slate-200 bg-white p-1" />'
                    : '<div class="flex h-[200px] w-[200px] items-center justify-center rounded-xl bg-slate-200 text-center text-sm text-slate-500 dark:bg-slate-700 dark:text-slate-300">' + (paymentStatus === 'EXPIRED' ? 'Mã QR đã hết hạn' : 'Không có dữ liệu QR') + '</div>';
            }
 
            if (qrResultBankName) qrResultBankName.textContent = bankName;
            if (qrResultBankAccount) qrResultBankAccount.textContent = bankAccount;
            if (qrResultBankAccountName) qrResultBankAccountName.textContent = bankAccountName;
 
            if (paymentStatus === 'PAID') {
                stopQrCountdown();
                if (qrTimeLabel) qrTimeLabel.textContent = 'Thời gian thanh toán';
                if (qrResultExpiresAt) {
                    qrResultExpiresAt.textContent = paidAt || '--';
                    qrResultExpiresAt.classList.remove('text-amber-600', 'dark:text-amber-300');
                    qrResultExpiresAt.classList.add('text-emerald-600', 'dark:text-emerald-300');
                }
                if (qrCountdown) {
                    qrCountdown.textContent = 'Đã thanh toán';
                    qrCountdown.classList.remove('text-slate-500', 'dark:text-slate-400', 'text-red-500', 'dark:text-red-400');
                    qrCountdown.classList.add('text-emerald-600', 'dark:text-emerald-300');
                }
            } else if (paymentStatus === 'EXPIRED') {
                stopQrCountdown();
                if (qrTimeLabel) qrTimeLabel.textContent = 'Trạng thái';
                if (qrResultExpiresAt) {
                    qrResultExpiresAt.textContent = 'QR đã hết hạn';
                    qrResultExpiresAt.classList.remove('text-emerald-600', 'dark:text-emerald-300');
                    qrResultExpiresAt.classList.add('text-amber-600', 'dark:text-amber-300');
                }
                if (qrCountdown) {
                    qrCountdown.textContent = 'Vui lòng tạo lại mã QR';
                    qrCountdown.classList.remove('text-slate-500', 'dark:text-slate-400', 'text-emerald-600', 'dark:text-emerald-300');
                    qrCountdown.classList.add('text-red-500', 'dark:text-red-400');
                }
            } else {
                if (qrTimeLabel) qrTimeLabel.textContent = 'Hết hạn';
                if (qrResultExpiresAt) {
                    qrResultExpiresAt.textContent = expiresAt;
                    qrResultExpiresAt.classList.remove('text-emerald-600', 'dark:text-emerald-300');
                    qrResultExpiresAt.classList.add('text-amber-600', 'dark:text-amber-300');
                }
                startQrCountdown(expiresAt);
            }
 
            qrResult.classList.remove('hidden');
            const qrBillIdValue = document.getElementById('qrBillId') ? document.getElementById('qrBillId').value : '';
            updateQrInvoiceActions(qrBillIdValue, paymentStatus);
        }

        function applyStatusBadge(element, type) {
            if (!element) return;
            element.className = type === 'paid'
                ? 'inline-flex w-fit items-center px-2.5 py-1 rounded-full text-xs font-bold status-paid'
                : type === 'expired'
                    ? 'inline-flex w-fit items-center px-2.5 py-1 rounded-full text-xs font-bold status-cancelled'
                    : 'inline-flex w-fit items-center px-2.5 py-1 rounded-full text-xs font-bold status-pending';
        }

        function applyPaymentBadge(element, type) {
            if (!element) return;
            element.className = type === 'paid'
                ? 'inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-bold bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300'
                : type === 'expired'
                    ? 'inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-bold bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-300'
                    : type === 'pending'
                        ? 'inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-bold bg-amber-100 text-amber-700 dark:bg-amber-500/10 dark:text-amber-300'
                        : 'inline-flex w-fit items-center rounded-full px-3 py-1 text-xs font-bold bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300';
        }

        function updateBillRowPaymentState(result) {
            if (!result || !result.billId) return;
            const billId = result.billId;
            const status = (result.status || '').toUpperCase();
            const statusBadge = document.getElementById('bill-status-' + billId);
            const viewButton = document.getElementById('view-qr-btn-' + billId);
            const confirmButton = document.getElementById('confirm-payment-btn-' + billId);
            const confirmForm = confirmButton ? confirmButton.closest('form') : null;
            const paymentType = status === 'PAID' ? 'paid' : status === 'EXPIRED' ? 'expired' : 'pending';

            if (statusBadge) {
                applyStatusBadge(statusBadge, paymentType);
                statusBadge.textContent = status === 'PAID' ? 'Đã thanh toán' : status === 'EXPIRED' ? 'Hết hạn QR' : 'Chờ thanh toán';
                statusBadge.classList.toggle('hidden', status === 'PAID');
            }
            if (viewButton) {
                const isPaid = status === 'PAID';
                const isExpired = status === 'EXPIRED';
                const mode = isPaid ? 'view' : (isExpired ? 'recreate' : 'view');
                viewButton.dataset.mode = mode;
                viewButton.dataset.paymentId = result.paymentId || viewButton.dataset.paymentId || '';
                viewButton.dataset.amount = result.amount || viewButton.dataset.amount || '';
                viewButton.dataset.bankBin = result.bankBin || '';
                viewButton.dataset.bankAccount = result.bankAccount || '';
                viewButton.dataset.bankAccountName = result.bankAccountName || '';
                viewButton.dataset.expiresAt = result.expiresAt || '';
                viewButton.dataset.paidAt = result.paidAt || '';
                viewButton.dataset.paymentStatus = status;
                viewButton.dataset.qrImageBase64 = isExpired ? '' : (result.qrImageBase64 || '');
                viewButton.classList.remove('bg-blue-600', 'hover:bg-blue-700', 'shadow-blue-500/30', 'bg-indigo-600', 'hover:bg-indigo-700', 'shadow-indigo-500/30', 'bg-orange-500', 'hover:bg-orange-600', 'shadow-orange-500/30');
                if (isPaid) {
                    viewButton.classList.add('bg-indigo-600', 'hover:bg-indigo-700', 'shadow-indigo-500/30');
                } else if (isExpired) {
                    viewButton.classList.add('bg-orange-500', 'hover:bg-orange-600', 'shadow-orange-500/30');
                } else {
                    viewButton.classList.add('bg-blue-600', 'hover:bg-blue-700', 'shadow-blue-500/30');
                }
                viewButton.title = isPaid ? 'Xem hóa đơn' : (isExpired ? 'Tạo lại QR' : 'Xem mã QR thanh toán');
                viewButton.setAttribute('aria-label', viewButton.title);
                viewButton.innerHTML = isPaid
                    ? '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>'
                    : (isExpired
                    ? '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 12a8 8 0 0113.66-5.66L20 8M20 4v4h-4M20 12a8 8 0 01-13.66 5.66L4 16M4 20v-4h4"></path></svg>'
                    : '<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h3v3H7V7zm7 0h3v3h-3V7zM7 14h3v3H7v-3zm7 0h3m-3 3h3m-3-6h3m-10 3h3m1 4H6a2 2 0 01-2-2V6a2 2 0 012-2h12a2 2 0 012 2v5"></path></svg>');
            }
            if (confirmForm) {
                confirmForm.classList.toggle('hidden', status === 'PAID' || status === 'EXPIRED');
                confirmForm.dataset.paymentId = result.paymentId || confirmForm.dataset.paymentId || '';
                const paymentIdInput = confirmForm.querySelector('input[name="payment_id"]');
                if (paymentIdInput) {
                    paymentIdInput.value = result.paymentId || paymentIdInput.value;
                }
            }
        }

        function setQrModalMode(mode) {
            const isViewMode = mode === 'view';
            if (qrModalTitle) qrModalTitle.textContent = isViewMode ? 'Xem mã QR thanh toán' : (mode === 'recreate' ? 'Tạo lại mã QR thanh toán' : 'Tạo mã QR thanh toán');
            if (qrModalDescription) {
                qrModalDescription.textContent = isViewMode
                    ? ''
                    : 'Tạo hoặc tạo lại giao dịch QR trực tiếp ngay trong quản lý hóa đơn.';
            }
            if (qrFormFields) qrFormFields.classList.toggle('hidden', isViewMode);
            if (qrSubmitButton) qrSubmitButton.classList.toggle('hidden', isViewMode);
            if (qrSubmitLabel) qrSubmitLabel.textContent = mode === 'recreate' ? 'Tạo lại mã QR' : 'Tạo mã QR';
            if (qrInvoiceActions) qrInvoiceActions.classList.toggle('hidden', !isViewMode);
        }

        function openQrModal(trigger) {
            if (!qrModal) return;
            const mode = trigger ? (trigger.getAttribute('data-mode') || 'create') : 'create';
            const billId = trigger ? trigger.getAttribute('data-bill-id') : '';
            const amount = trigger ? trigger.getAttribute('data-amount') : '';
            const customerName = trigger ? trigger.getAttribute('data-customer-name') : '';
            const customerEmail = trigger ? trigger.getAttribute('data-customer-email') : '';
            document.getElementById('qrBillId').value = billId || '';
            document.getElementById('qrAmount').value = mode === 'view' ? (amount || '') : '';
            document.getElementById('qrCustomerName').value = customerName || '';
            document.getElementById('qrCustomerEmail').value = customerEmail || '';
            const qrPaymentIdInput = document.getElementById('qrPaymentId');
            if (qrPaymentIdInput) {
                qrPaymentIdInput.value = trigger ? (trigger.getAttribute('data-payment-id') || '') : '';
            }
            if (qrCreateForm) {
                qrCreateForm.dataset.mode = mode;
            }
            if (mode === 'view' && qrBankBinInput && qrBankAccountInput && qrBankAccountNameInput) {
                qrBankBinInput.value = trigger.getAttribute('data-bank-bin') || '';
                qrBankAccountInput.value = trigger.getAttribute('data-bank-account') || '';
                qrBankAccountNameInput.value = trigger.getAttribute('data-bank-account-name') || '';
            } else {
                syncQrReceiverAccountFields();
            }
            resetQrResult();
            setQrModalMode(mode);
            updateQrInvoiceActions(billId, trigger ? (trigger.getAttribute('data-payment-status') || '') : '');

            if (mode === 'view') {
                renderQrResult({
                    bankBin: trigger.getAttribute('data-bank-bin') || '',
                    bankAccount: trigger.getAttribute('data-bank-account') || '',
                    bankAccountName: trigger.getAttribute('data-bank-account-name') || '',
                    expiresAt: trigger.getAttribute('data-expires-at') || '',
                    paidAt: trigger.getAttribute('data-paid-at') || '',
                    status: trigger.getAttribute('data-payment-status') || '',
                    qrImageBase64: trigger.getAttribute('data-qr-image-base64') || ''
                });
            }

            qrModal.classList.remove('hidden');
            qrModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');

            if (mode !== 'view') {
                setTimeout(function() {
                    const qrAmountInput = document.getElementById('qrAmount');
                    if (qrAmountInput) {
                        qrAmountInput.focus();
                        qrAmountInput.select();
                    }
                }, 0);
            }
        }
 
        function closeQrModal() {
            if (!qrModal) return;
            stopQrCountdown();
            qrModal.classList.add('hidden');
            qrModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
            resetQrResult();
        }

        async function handleCreateOrRecreateQr(trigger) {
            if (!trigger) return;
            const mode = trigger.getAttribute('data-mode') || 'create';
            if (mode !== 'recreate') {
                openQrModal(trigger);
                return;
            }

            const paymentId = trigger.getAttribute('data-payment-id') || '';
            if (!paymentId) {
                openQrModal(trigger);
                return;
            }

            const originalHtml = trigger.innerHTML;
            const billId = trigger.getAttribute('data-bill-id') || '';
            try {
                trigger.disabled = true;
                trigger.classList.add('opacity-60', 'cursor-not-allowed');
                trigger.innerHTML = '<svg class="h-5 w-5 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v3a5 5 0 00-5 5H4z"></path></svg>';

                const payload = new URLSearchParams();
                payload.set('action', 'refreshQr');
                payload.set('source', 'bill');
                payload.set('ajax', '1');
                payload.set('payment_id', paymentId);
                payload.set('expire_minutes', '1440');

                const response = await fetch('<%= request.getContextPath() %>/PaymentController', {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json',
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                    },
                    body: payload.toString()
                });

                const responseText = await response.text();
                const result = responseText ? JSON.parse(responseText) : null;
                if (!response.ok || !result || !result.success) {
                    showBillToast((result && result.message) || 'Không thể tạo lại mã QR.', 'error');
                    return;
                }

                updateBillRowPaymentState(result);
                const viewButton = document.getElementById('view-qr-btn-' + (result.billId || billId));
                if (viewButton) {
                    openQrModal(viewButton);
                }
                showBillToast(result.message || 'Đã tạo lại mã QR thành công.', 'success');
            } catch (error) {
                showBillToast(error.message || 'Không thể tạo lại mã QR ngay trên trang.', 'error');
            } finally {
                trigger.disabled = false;
                trigger.classList.remove('opacity-60', 'cursor-not-allowed');
                trigger.innerHTML = originalHtml;
            }
        }

        if (qrRecreateButton) {
            qrRecreateButton.addEventListener('click', function() {
                const billId = this.dataset.billId || '';
                if (!billId) {
                    showBillToast('Không xác định được hóa đơn để tạo lại mã QR.', 'error');
                    return;
                }
                const viewButton = document.getElementById('view-qr-btn-' + billId);
                if (!viewButton) {
                    showBillToast('Không tìm thấy dữ liệu hóa đơn để tạo lại mã QR.', 'error');
                    return;
                }
                viewButton.dataset.mode = 'recreate';
                handleCreateOrRecreateQr(viewButton);
            });
        }

        if (addModal) {
            addModal.addEventListener('click', function(e) {
                if (e.target === this) closeAddModal();
            });
        }

        if (quickCustomerModal) {
            quickCustomerModal.addEventListener('click', function(e) {
                if (e.target === this) closeQuickCustomerModal();
            });
        }

        if (quickCustomerForm) {
            quickCustomerForm.addEventListener('submit', async function(event) {
                event.preventDefault();
                const submitBtn = quickCustomerForm.querySelector('button[type="submit"]');
                const nameInput = quickCustomerForm.querySelector('input[name="customer_name"]');
                const phoneInput = quickCustomerForm.querySelector('input[name="phone"]');
                const emailInput = quickCustomerForm.querySelector('input[name="email"]');
                const customerName = nameInput ? nameInput.value.trim() : '';
                const phone = phoneInput ? phoneInput.value.trim() : '';
                const email = emailInput ? emailInput.value.trim() : '';

                if (!customerName) {
                    setQuickCustomerStatus('Vui lòng nhập tên khách hàng.', true);
                    if (nameInput) nameInput.focus();
                    return;
                }
                if (customerName.length > 100) {
                    setQuickCustomerStatus('Tên khách hàng không được vượt quá 100 ký tự.', true);
                    if (nameInput) nameInput.focus();
                    return;
                }
                if (!phone) {
                    setQuickCustomerStatus('Vui lòng nhập số điện thoại khách hàng.', true);
                    if (phoneInput) phoneInput.focus();
                    return;
                }
                if (phone.length > 15) {
                    setQuickCustomerStatus('Số điện thoại không được vượt quá 15 ký tự.', true);
                    if (phoneInput) phoneInput.focus();
                    return;
                }
                if (!/^[0-9+\-\s().]{8,15}$/.test(phone)) {
                    setQuickCustomerStatus('Số điện thoại không hợp lệ.', true);
                    if (phoneInput) phoneInput.focus();
                    return;
                }
                if (!email) {
                    setQuickCustomerStatus('Vui lòng nhập email khách hàng.', true);
                    if (emailInput) emailInput.focus();
                    return;
                }
                if (email.length > 50) {
                    setQuickCustomerStatus('Email khách hàng không được vượt quá 50 ký tự.', true);
                    if (emailInput) emailInput.focus();
                    return;
                }

                if (submitBtn) {
                    submitBtn.disabled = true;
                    submitBtn.classList.add('opacity-60', 'cursor-not-allowed');
                }

                try {
                    const payload = new URLSearchParams();
                    payload.set('action', 'addCustomerForBill');
                    payload.set('customer_name', customerName);
                    payload.set('phone', phone);
                    payload.set('email', email);

                    const response = await fetch('<%= request.getContextPath() %>/BillController', {
                        method: 'POST',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': 'application/json',
                            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                        },
                        body: payload.toString()
                    });

                    const raw = await response.text();
                    let result = null;
                    try {
                        result = raw ? JSON.parse(raw) : null;
                    } catch (e) {
                        throw new Error('Phản hồi thêm khách hàng không hợp lệ.');
                    }

                    if (!response.ok || !result || !result.success) {
                        setQuickCustomerStatus((result && result.message) || 'Không thể tạo khách hàng mới.', true);
                        return;
                    }

                    if (billCustomerSelect) {
                        let option = billCustomerSelect.querySelector('option[value="' + result.customerId + '"]');
                        if (!option) {
                            option = document.createElement('option');
                            option.value = String(result.customerId);
                            option.textContent = result.customerName || ('KH #' + result.customerId);
                            billCustomerSelect.appendChild(option);
                        }
                        billCustomerSelect.value = String(result.customerId);
                    }

                    setQuickCustomerStatus(result.message || 'Đã tạo khách hàng và chọn vào danh sách.', false);
                    setTimeout(function() {
                        closeQuickCustomerModal();
                    }, 450);
                } catch (error) {
                    setQuickCustomerStatus(error.message || 'Không thể tạo khách hàng mới.', true);
                } finally {
                    if (submitBtn) {
                        submitBtn.disabled = false;
                        submitBtn.classList.remove('opacity-60', 'cursor-not-allowed');
                    }
                }
            });
        }

        if (deleteBillModal) {
            deleteBillModal.addEventListener('click', function(e) {
                if (e.target === this) closeDeleteBillModal();
            });
        }

        if (qrModal) {
            qrModal.addEventListener('click', function(e) {
                if (e.target === this) closeQrModal();
            });
        }

        if (invoiceModal) {
            invoiceModal.addEventListener('click', function(e) {
                if (e.target === this) closeInvoiceModal();
            });
        }
 
        if (qrCreateForm) {
            qrCreateForm.addEventListener('submit', async function(event) {
                event.preventDefault();
 
                const submitButton = qrSubmitButton || qrCreateForm.querySelector('button[type="submit"]');
                const originalButtonHtml = submitButton ? submitButton.innerHTML : '';
 
                try {
                    if (submitButton) {
                        submitButton.disabled = true;
                        submitButton.classList.add('opacity-60', 'cursor-not-allowed');
                        submitButton.innerHTML = 'Đang tạo QR...';
                    }
 
                    const payload = new URLSearchParams();
                    const currentMode = qrCreateForm ? (qrCreateForm.dataset.mode || 'create') : 'create';
                    const currentPaymentId = document.getElementById('qrPaymentId') ? document.getElementById('qrPaymentId').value : '';
                    const recreateMode = currentMode === 'recreate' && !!currentPaymentId;
                    payload.set('action', recreateMode ? 'refreshQr' : 'createQr');
                    payload.set('source', 'bill');
                    payload.set('ajax', '1');
                    payload.set('bill_id', document.getElementById('qrBillId').value || '');
                    if (recreateMode) {
                        payload.set('payment_id', currentPaymentId);
                    }
                    payload.set('amount', document.getElementById('qrAmount').value || '');
                    payload.set('customer_name', document.getElementById('qrCustomerName').value || '');
                    payload.set('customer_email', document.getElementById('qrCustomerEmail').value || '');
                    payload.set('expire_minutes', qrCreateForm.querySelector('select[name="expire_minutes"]') ? qrCreateForm.querySelector('select[name="expire_minutes"]').value : '1440');
                    payload.set('bank_bin', qrBankBinInput ? qrBankBinInput.value : '');
                    payload.set('bank_account', qrBankAccountInput ? qrBankAccountInput.value : '');
                    payload.set('bank_account_name', qrBankAccountNameInput ? qrBankAccountNameInput.value : '');

                    const response = await fetch('<%= request.getContextPath() %>/PaymentController', {
                        method: 'POST',
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Accept': 'application/json',
                            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                        },
                        body: payload.toString()
                    });

                    const responseText = await response.text();
                    let result;
                    try {
                        result = responseText ? JSON.parse(responseText) : null;
                    } catch (parseError) {
                        throw new Error(responseText && responseText.trim()
                            ? 'Phản hồi tạo QR không hợp lệ: ' + responseText.substring(0, 180)
                            : 'Phản hồi tạo QR không hợp lệ.');
                    }
 
                    if (!response.ok || !result.success) {
                        alert((result && result.message) || 'Không thể tạo mã QR.');
                        return;
                    }

                    updateBillRowPaymentState(result);
                    setQrModalMode('view');
                    renderQrResult(result);
                } catch (error) {
                    alert(error.message || 'Không thể tạo mã QR ngay trên trang.');
                } finally {
                    if (submitButton) {
                        submitButton.disabled = false;
                        submitButton.classList.remove('opacity-60', 'cursor-not-allowed');
                        submitButton.innerHTML = originalButtonHtml;
                    }
                }
            });
        }

        function showBillToast(message, type) {
            const toast = document.createElement('div');
            const isSuccess = type === 'success';
            toast.style.position = 'fixed';
            toast.style.right = '24px';
            toast.style.top = '24px';
            toast.style.zIndex = '9999';
            toast.style.minWidth = '320px';
            toast.style.maxWidth = '420px';
            toast.style.padding = '14px 16px';
            toast.style.borderRadius = '16px';
            toast.style.border = isSuccess ? '1px solid #86efac' : '1px solid #fecaca';
            toast.style.background = isSuccess ? '#f0fdf4' : '#fff1f2';
            toast.style.color = isSuccess ? '#166534' : '#9f1239';
            toast.style.boxShadow = '0 16px 40px rgba(15, 23, 42, 0.18)';
            toast.style.transform = 'translateY(-8px)';
            toast.style.opacity = '0';
            toast.style.transition = 'all 0.25s ease';
            toast.innerHTML = ''
                + '<div style="display:flex;align-items:flex-start;gap:12px">'
                + '  <div style="font-size:18px;line-height:1">' + (isSuccess ? '✅' : '⚠️') + '</div>'
                + '  <div style="flex:1">'
                + '      <div style="font-size:14px;font-weight:700;margin-bottom:2px">' + (isSuccess ? 'Thành công' : 'Thông báo') + '</div>'
                + '      <div style="font-size:13px;line-height:1.5">' + String(message || '') + '</div>'
                + '  </div>'
                + '</div>';
            document.body.appendChild(toast);
            requestAnimationFrame(function() {
                toast.style.opacity = '1';
                toast.style.transform = 'translateY(0)';
            });
            setTimeout(function() {
                toast.style.opacity = '0';
                toast.style.transform = 'translateY(-8px)';
                setTimeout(function() {
                    if (toast.parentNode) {
                        toast.parentNode.removeChild(toast);
                    }
                }, 250);
            }, 2600);
        }

        let activeConfirmPaymentOverlay = null;

        function removeConfirmPaymentOverlay() {
            if (activeConfirmPaymentOverlay && activeConfirmPaymentOverlay.parentNode) {
                activeConfirmPaymentOverlay.parentNode.removeChild(activeConfirmPaymentOverlay);
            }
            activeConfirmPaymentOverlay = null;
        }

        function askConfirmPayment(message) {
            return new Promise(function(resolve) {
                removeConfirmPaymentOverlay();

                const overlay = document.createElement('div');
                activeConfirmPaymentOverlay = overlay;
                overlay.style.position = 'fixed';
                overlay.style.inset = '0';
                overlay.style.background = 'rgba(15, 23, 42, 0.45)';
                overlay.style.backdropFilter = 'blur(4px)';
                overlay.style.zIndex = '9998';
                overlay.style.display = 'flex';
                overlay.style.alignItems = 'center';
                overlay.style.justifyContent = 'center';
                overlay.style.padding = '16px';

                const dialog = document.createElement('div');
                dialog.style.width = '100%';
                dialog.style.maxWidth = '420px';
                dialog.style.borderRadius = '24px';
                dialog.style.background = '#ffffff';
                dialog.style.padding = '24px';
                dialog.style.boxShadow = '0 24px 60px rgba(15, 23, 42, 0.25)';
                dialog.innerHTML = ''
                    + '<div style="display:flex;align-items:flex-start;gap:14px">'
                    + '  <div style="display:flex;height:44px;width:44px;align-items:center;justify-content:center;border-radius:999px;background:#ecfdf5;color:#059669;font-size:20px">✓</div>'
                    + '  <div style="flex:1">'
                    + '      <div style="font-size:18px;font-weight:700;color:#0f172a">Xác nhận thanh toán</div>'
                    + '      <div style="margin-top:8px;font-size:14px;line-height:1.6;color:#475569">' + String(message || '') + '</div>'
                    + '  </div>'
                    + '</div>'
                    + '<div style="margin-top:22px;display:flex;justify-content:flex-end;gap:10px">'
                    + '  <button type="button" data-action="cancel" style="border:none;border-radius:14px;background:#e2e8f0;color:#334155;padding:10px 16px;font-weight:600;cursor:pointer">Huỷ</button>'
                    + '  <button type="button" data-action="confirm" style="border:none;border-radius:14px;background:#059669;color:#ffffff;padding:10px 16px;font-weight:700;cursor:pointer">Xác nhận</button>'
                    + '</div>';

                overlay.appendChild(dialog);
                document.body.appendChild(overlay);

                function close(result) {
                    removeConfirmPaymentOverlay();
                    resolve(result);
                }

                function handleKeydown(event) {
                    if (event.key === 'Escape') {
                        document.removeEventListener('keydown', handleKeydown);
                        close(false);
                    }
                }

                document.addEventListener('keydown', handleKeydown);
                overlay.addEventListener('click', function(event) {
                    if (event.target === overlay) {
                        document.removeEventListener('keydown', handleKeydown);
                        close(false);
                    }
                });
                dialog.querySelector('[data-action="cancel"]').addEventListener('click', function() {
                    document.removeEventListener('keydown', handleKeydown);
                    close(false);
                });
                dialog.querySelector('[data-action="confirm"]').addEventListener('click', function() {
                    document.removeEventListener('keydown', handleKeydown);
                    close(true);
                });
            });
        }

        async function confirmPaymentInline(event, form) {
            if (event) {
                event.preventDefault();
            }
            if (!form) {
                return false;
            }

            const accepted = await askConfirmPayment('Xác nhận khách hàng đã thanh toán cho hóa đơn này?');
            if (!accepted) {
                removeConfirmPaymentOverlay();
                return false;
            }

            const submitButton = form.querySelector('button[type="submit"]');
            const originalButtonHtml = submitButton ? submitButton.innerHTML : '';
            try {
                removeConfirmPaymentOverlay();
                if (submitButton) {
                    submitButton.disabled = true;
                    submitButton.classList.add('opacity-60', 'cursor-not-allowed');
                }

                const payload = new URLSearchParams();
                payload.set('action', 'confirmPayment');
                payload.set('source', 'bill');
                payload.set('ajax', '1');
                payload.set('payment_id', form.querySelector('input[name="payment_id"]').value || '');

                const response = await fetch('<%= request.getContextPath() %>/PaymentController', {
                    method: 'POST',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json',
                        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                    },
                    body: payload.toString()
                });

                const responseText = await response.text();
                let result = null;
                try {
                    result = responseText ? JSON.parse(responseText) : null;
                } catch (parseError) {
                    throw new Error(responseText && responseText.trim()
                        ? 'Phản hồi xác nhận thanh toán không hợp lệ: ' + responseText.substring(0, 180)
                        : 'Phản hồi xác nhận thanh toán không hợp lệ.');
                }

                if (!response.ok || !result || !result.success) {
                    showBillToast((result && result.message) || 'Không thể xác nhận thanh toán.', 'error');
                    return false;
                }

                updateBillRowPaymentState(result);
                if (qrModal && !qrModal.classList.contains('hidden')) {
                    setQrModalMode('view');
                    renderQrResult(result);
                }
                window.setTimeout(function() {
                    window.location.href = '<%= request.getContextPath() %>/MainController?action=listBill';
                }, 180);
                showBillToast(result.message || 'Đã xác nhận thanh toán thành công.', 'success');
            } catch (error) {
                showBillToast(error.message || 'Không thể xác nhận thanh toán.', 'error');
            } finally {
                removeConfirmPaymentOverlay();
                if (submitButton) {
                    submitButton.disabled = false;
                    submitButton.classList.remove('opacity-60', 'cursor-not-allowed');
                    submitButton.innerHTML = originalButtonHtml;
                }
            }
            return false;
        }
 
        if (billTotalAmount) {
            billTotalAmount.addEventListener('blur', function() {
                const numericValue = Number(this.value || 0);
                if (numericValue > 0 && numericValue < 1000) {
                    this.value = 1000;
                }
            });
        }

        if (addBillForm) {
            addBillForm.setAttribute('novalidate', 'novalidate');
            addBillForm.addEventListener('submit', function(event) {
                const hasSelectedCustomer = billCustomerSelect && billCustomerSelect.value;
                if (!hasSelectedCustomer) {
                    event.preventDefault();
                    showErrorPopup('Vui lòng chọn khách hàng trước khi tạo hóa đơn.');
                    if (billCustomerSelect) billCustomerSelect.focus();
                    return;
                }

                const quoteRows = addBillForm.querySelectorAll('#quoteLinesContainer .quote-line');
                if (!quoteRows.length) {
                    event.preventDefault();
                    showErrorPopup('Chi tiết báo giá phải có ít nhất 1 sản phẩm.', { title: 'Thiếu sản phẩm báo giá' });
                    return;
                }

                recalcBillTotalFromLines();

                const firstInvalid = addBillForm.querySelector(':invalid');
                if (firstInvalid) {
                    event.preventDefault();
                    showErrorPopup(buildValidationMessage(firstInvalid));
                    firstInvalid.focus();
                    return;
                }

                if (!billTotalAmount || Number(billTotalAmount.value || 0) <= 0) {
                    event.preventDefault();
                    showErrorPopup('Vui lòng nhập tổng tiền lớn hơn 0.');
                    if (billTotalAmount) billTotalAmount.focus();
                }
            });
        }

        const serverBillPopup = {
            title: '<%= billPopupTitleJs %>',
            message: '<%= billPopupMessageJs %>',
            actionUrl: '<%= request.getContextPath() %>/<%= billPopupActionUrlJs %>',
            actionLabel: '<%= billPopupActionLabelJs %>',
            reopenModal: '<%= String.valueOf(billPopupReopenModal) %>' === 'true'
        };

        if (serverBillPopup.message) {
            if (serverBillPopup.reopenModal) {
                openAddModal();
            }
            showErrorPopup(serverBillPopup.message, {
                title: serverBillPopup.title || 'Thông báo',
                actionUrl: serverBillPopup.actionUrl,
                actionLabel: serverBillPopup.actionLabel || 'Xem cấu hình',
                persist: true
            });
        }

        const addQuoteLineBtn = document.getElementById('addQuoteLineBtn');
        if (addQuoteLineBtn) {
            addQuoteLineBtn.addEventListener('click', addQuoteLine);
        }
        resetQuoteLines();
        initReceiverAccounts();

        function removeLegacyDownloadButtonsInActionColumn() {
            const legacyLinks = document.querySelectorAll('td a[href*="BillController?action=downloadBill&bill_id="]');
            legacyLinks.forEach(function(link) {
                const parentCell = link.closest('td');
                const row = link.closest('tr');
                if (!parentCell || !row) return;
                const actionCell = row.querySelector('td:last-child');
                if (actionCell === parentCell) {
                    link.remove();
                }
            });
        }

        removeLegacyDownloadButtonsInActionColumn();
 
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                if (qrModal && !qrModal.classList.contains('hidden')) {
                    closeQrModal();
                }
                if (deleteBillModal && !deleteBillModal.classList.contains('hidden')) {
                    closeDeleteBillModal();
                }
                if (quickCustomerModal && !quickCustomerModal.classList.contains('hidden')) {
                    closeQuickCustomerModal();
                }
                if (addModal && !addModal.classList.contains('hidden')) {
                    closeAddModal();
                }
                if (invoiceModal && !invoiceModal.classList.contains('hidden')) {
                    closeInvoiceModal();
                }
            }
        });
    </script>
</body>
</html>
