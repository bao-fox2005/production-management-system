<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List,java.text.DecimalFormat,java.text.SimpleDateFormat,pms.model.BillDTO,pms.model.BillLineDTO,pms.model.CustomerDTO,pms.model.PaymentDTO,pms.model.UserDTO"%>
<%
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    BillDTO bill = (BillDTO) request.getAttribute("detailBill");
    CustomerDTO customer = (CustomerDTO) request.getAttribute("detailCustomer");
    PaymentDTO payment = (PaymentDTO) request.getAttribute("detailPayment");
    List<BillLineDTO> lines = (List<BillLineDTO>) request.getAttribute("detailLines");

    Boolean publicViewAttr = (Boolean) request.getAttribute("isPublicInvoiceView");
    boolean isPublicView = publicViewAttr != null && publicViewAttr;
    boolean isEmbedView = "1".equals(request.getParameter("embed"))
            || "true".equalsIgnoreCase(request.getParameter("embed"));

    UserDTO user = (UserDTO) session.getAttribute("user");
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;

    if (bill == null) {
        response.sendError(404, "Không tìm thấy hóa đơn");
        return;
    }

    if (lines == null) {
        lines = new java.util.ArrayList<>();
    }

    DecimalFormat money = new DecimalFormat("#,###");
    SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");
    SimpleDateFormat sdfDateTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    String customerName = customer != null && customer.getCustomer_name() != null
            ? customer.getCustomer_name()
            : "Khách lẻ";
    String customerEmail = customer != null && customer.getEmail() != null ? customer.getEmail() : "";
    String customerPhone = customer != null && customer.getPhone() != null ? customer.getPhone() : "";

    String paymentStatusCode = payment != null && payment.getStatus() != null ? payment.getStatus().toUpperCase() : "PENDING";
    String paymentStatusLabel = "Chờ thanh toán";
    if ("PAID".equals(paymentStatusCode)) {
        paymentStatusLabel = "Đã thanh toán";
    } else if ("EXPIRED".equals(paymentStatusCode)) {
        paymentStatusLabel = "Hết hạn";
    }

    String qrBase64 = "";
    if (payment != null && payment.getQrCodeData() != null) {
        String qrRaw = payment.getQrCodeData();
        if (qrRaw.contains("|QR_URL|")) {
            String[] parts = qrRaw.split("\\|QR_URL\\|", 2);
            qrBase64 = parts.length > 0 ? parts[0] : "";
        } else {
            qrBase64 = qrRaw;
        }
    }

    String invoiceNo = String.format("%06d", bill.getBill_id());
    java.util.Date invoiceIssuedAt = bill.getBill_created_at() != null
            ? new java.util.Date(bill.getBill_created_at().getTime())
            : bill.getBill_date();
    String paidAt = (payment != null && payment.getPaidAt() != null) ? sdfDateTime.format(payment.getPaidAt()) : "-";
    long qrExpiresAtMillis = (payment != null && payment.getExpiresAt() != null) ? payment.getExpiresAt().getTime() : -1L;
    String paymentCode = (payment != null && payment.getPaymentId() > 0) ? String.format("PAY-%04d", payment.getPaymentId()) : "-";

    boolean showInvoiceQr = "PENDING".equals(paymentStatusCode) && qrBase64 != null && !qrBase64.isEmpty();
    boolean canManageQr = !isPublicView && !isEmbedView;
    boolean hasPaymentRecord = payment != null && payment.getPaymentId() > 0;
    boolean canRefreshQr = canManageQr && payment != null && ("PENDING".equals(paymentStatusCode) || "EXPIRED".equals(paymentStatusCode));
    boolean canCreateQr = canManageQr && payment == null;
    String qrAction = hasPaymentRecord ? "refreshQr" : "createQr";

    String downloadUrl = "BillController?action=" + (isPublicView ? "downloadPublicBill" : "downloadBill") + "&bill_id=" + bill.getBill_id();
    String backUrl = "MainController?action=listBill";

    request.setAttribute("activePage", "bill");
    request.setAttribute("pageTitle", "Chi tiết hóa đơn");
%>
<!DOCTYPE html>
<html lang="vi" class="<%= (isDarkMode && !isEmbedView && !isPublicView) ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hóa đơn #<%= bill.getBill_id() %> - PMS</title>
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
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Roboto:wght@500;700;900&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; }
        .invoice-title {
            font-family: 'Roboto', sans-serif;
            letter-spacing: 0.01em;
        }
        .paper {
            background:
                radial-gradient(circle at 100% 0%, rgba(15,23,42,.06), transparent 40%),
                linear-gradient(180deg, #ffffff 0%, #fcfcfd 100%);
        }
        .table-head {
            background: #f1f3f5;
        }
        .status-paid { background: #ecfdf3; color: #027a48; border-color: #abefc6; }
        .status-pending { background: #fffaeb; color: #b54708; border-color: #fedf89; }
        .status-expired { background: #fef3f2; color: #b42318; border-color: #fecdca; }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .sidebar-header { position: sticky; top: 0; background: #0f172a; z-index: 10; }
        .sidebar-nav { flex: 1; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
        .sidebar-footer { position: sticky; bottom: 0; background: #0f172a; z-index: 10; }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        @media print {
            .no-print { display: none !important; }
            body { background: #fff !important; }
            .paper { box-shadow: none !important; border: 0 !important; }
            .main-wrapper { margin-left: 0 !important; }
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="<%= (isEmbedView || isPublicView) ? "bg-slate-100" : ("bg-slate-100 text-slate-900 min-h-screen antialiased " + (isDarkMode ? "dark dark-mode-init" : "")) %>">
<% if (!isPublicView && !isEmbedView) { %>
<div class="min-h-screen flex">
    <jsp:include page="components/shared-sidebar.jsp" />
    <div id="mainWrapper" class="main-wrapper flex-1 min-w-0">
        <jsp:include page="components/shared-header.jsp" />
        <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
<% } else { %>
<div class="p-2 sm:p-4">
<% } %>
            <div class="paper mx-auto max-w-5xl rounded-3xl border border-slate-200 shadow-xl">
                <div class="border-b border-slate-200 px-8 py-8 sm:px-12">
                    <div class="flex flex-wrap items-start justify-between gap-8">
                        <div class="flex items-start gap-4">
                            <img src="<%= request.getContextPath() %>/img/logo.png" alt="PMS Logo" class="h-12 w-12 rounded-xl border border-slate-200 bg-white object-contain p-1" />
                            <div>
                                <p class="text-sm font-extrabold tracking-[0.16em] text-slate-800">PMS MANUFACTURING</p>
                                <p class="mt-1 text-xs text-slate-500">123 Anywhere St., Any City</p>
                                <p class="text-xs text-slate-500">Hotline: 1900 6868 · Email: contact@pms.local</p>
                            </div>
                        </div>
                        <div class="text-right">
                            <p class="text-xs font-semibold uppercase tracking-[0.12em] text-slate-500">Invoice No.</p>
                            <p class="text-2xl font-black tracking-wide text-slate-900"><%= invoiceNo %></p>
                            <p class="mt-1 text-xs text-slate-500">Ngày lập: <span class="font-semibold text-slate-700"><%= invoiceIssuedAt != null ? sdfDateTime.format(invoiceIssuedAt) : "-" %></span></p>
                        </div>
                    </div>
                    <h1 class="invoice-title mt-8 text-2xl font-semibold uppercase tracking-[0.06em] text-slate-900 sm:text-3xl">Invoice</h1>
                </div>

                <div class="grid gap-6 border-b border-slate-200 px-8 py-7 sm:grid-cols-2 sm:px-12">
                    <div class="rounded-2xl border border-slate-200 bg-white p-5">
                        <p class="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Billed to</p>
                        <p class="mt-2 text-lg font-semibold text-slate-900"><%= customerName %></p>
                        <p class="mt-1 text-sm text-slate-600"><%= customerPhone != null && !customerPhone.isEmpty() ? customerPhone : "Chưa có SĐT" %></p>
                        <p class="text-sm text-slate-600"><%= customerEmail != null && !customerEmail.isEmpty() ? customerEmail : "Chưa có email" %></p>
                    </div>
                    <div class="rounded-2xl border border-slate-200 bg-white p-5">
                        <p class="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Thông tin giao dịch</p>
                        <p class="mt-2 text-sm text-slate-700">Mã giao dịch: <span class="font-semibold"><%= paymentCode %></span></p>
                        <p class="mt-1 text-sm text-slate-700">Trạng thái: <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold <%= "PAID".equals(paymentStatusCode) ? "status-paid" : ("EXPIRED".equals(paymentStatusCode) ? "status-expired" : "status-pending") %>"><%= paymentStatusLabel %></span></p>
                        <% if ("PAID".equals(paymentStatusCode)) { %>
                        <p class="mt-1 text-sm text-slate-700">Đã thanh toán lúc: <span class="font-semibold"><%= paidAt %></span></p>
                        <% } %>
                    </div>
                </div>

                <div class="px-8 py-8 sm:px-12">
                    <div class="overflow-x-auto rounded-2xl border border-slate-200">
                        <table class="w-full min-w-[660px]">
                            <thead class="table-head">
                                <tr>
                                    <th class="px-4 py-3 text-left text-xs font-bold uppercase tracking-[0.08em] text-slate-700">Item</th>
                                    <th class="px-4 py-3 text-right text-xs font-bold uppercase tracking-[0.08em] text-slate-700">Quantity</th>
                                    <th class="px-4 py-3 text-right text-xs font-bold uppercase tracking-[0.08em] text-slate-700">Price</th>
                                    <th class="px-4 py-3 text-right text-xs font-bold uppercase tracking-[0.08em] text-slate-700">Amount</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 bg-white">
                            <% if (lines.isEmpty()) { %>
                                <tr>
                                    <td colspan="4" class="px-4 py-8 text-center text-sm text-slate-500">Không có dòng hàng</td>
                                </tr>
                            <% } else { for (BillLineDTO line : lines) { %>
                                <tr>
                                    <td class="px-4 py-3.5 text-sm font-medium text-slate-800"><%= line.getItemType() %></td>
                                    <td class="px-4 py-3.5 text-right text-sm text-slate-700"><%= line.getQuantity() %></td>
                                    <td class="px-4 py-3.5 text-right text-sm text-slate-700"><%= money.format(line.getUnitPrice()) %> VND</td>
                                    <td class="px-4 py-3.5 text-right text-sm font-semibold text-slate-900"><%= money.format(line.getLineTotal()) %> VND</td>
                                </tr>
                            <% }} %>
                            </tbody>
                            <tfoot>
                                <tr class="bg-slate-50">
                                    <td colspan="2"></td>
                                    <td class="px-4 py-4 text-right text-base font-bold text-slate-700">Total</td>
                                    <td class="px-4 py-4 text-right text-2xl font-black text-slate-900"><%= money.format(bill.getTotal_amount()) %> VND</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>

                    <div class="mt-8 rounded-2xl border border-slate-200 bg-white p-5">
                        <p class="text-sm text-slate-700"><span class="font-bold">Payment method:</span> Chuyển khoản / QR</p>
                        <p class="mt-2 text-sm text-slate-700"><span class="font-bold">Note:</span> Thank you for choosing us!</p>
                    </div>

                    <% if (showInvoiceQr) { %>
                    <div class="mt-8 rounded-2xl border border-slate-200 bg-white p-6 text-center shadow-sm">
                        <p class="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">QR thanh toán</p>
                        <img src="data:image/png;base64,<%= qrBase64 %>" alt="QR thanh toán" class="mx-auto mt-3 h-52 w-52 rounded-2xl border border-slate-200 bg-white p-2" />
                        <div class="mx-auto mt-5 max-w-xs rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-center">
                            <p class="text-[11px] font-semibold uppercase tracking-[0.16em] text-amber-700">Thời gian còn lại</p>
                            <p id="qrCountdown" data-expires-at="<%= qrExpiresAtMillis %>" data-status="<%= paymentStatusCode %>" class="mt-2 text-2xl font-black tracking-[0.08em] text-amber-600">--:--</p>
                        </div>
                    </div>
                    <% } %>

                    <div class="no-print mt-10 flex flex-wrap items-center justify-end gap-3 border-t border-slate-200 pt-6">
                        <% if (canRefreshQr || canCreateQr) { %>
                        <form action="PaymentController" method="post" class="inline-flex">
                            <input type="hidden" name="action" value="<%= qrAction %>" />
                            <input type="hidden" name="source" value="bill" />
                            <input type="hidden" name="bill_id" value="<%= bill.getBill_id() %>" />
                            <% if (hasPaymentRecord) { %>
                            <input type="hidden" name="payment_id" value="<%= payment.getPaymentId() %>" />
                            <% } else { %>
                            <input type="hidden" name="amount" value="<%= bill.getTotal_amount() %>" />
                            <input type="hidden" name="customer_name" value="<%= customerName %>" />
                            <input type="hidden" name="customer_email" value="<%= customerEmail %>" />
                            <% } %>
                            <input type="hidden" name="expire_minutes" value="1440" />
                            <button type="submit" class="rounded-xl bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600"><%= hasPaymentRecord ? "Tạo lại mã QR" : "Tạo mã QR" %></button>
                        </form>
                        <% } %>
                        <a href="<%= downloadUrl %>" class="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-700">Tải hóa đơn</a>
                        <% if (!isPublicView && !isEmbedView) { %>
                        <a href="<%= backUrl %>" class="rounded-xl border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100">Quay lại danh sách</a>
                        <% } %>
                    </div>
                </div>
            </div>
<% if (!isPublicView && !isEmbedView) { %>
        </main>
    </div>
</div>
<% } else { %>
</div>
<% } %>
<script>
    (function () {
        var countdownEl = document.getElementById('qrCountdown');
        var noteEl = document.getElementById('qrCountdownNote');
        if (!countdownEl) {
            return;
        }

        var expiresAt = parseInt(countdownEl.getAttribute('data-expires-at') || '-1', 10);
        var status = countdownEl.getAttribute('data-status') || '';

        function pad(value) {
            return value < 10 ? '0' + value : '' + value;
        }

        function renderExpired(message) {
            countdownEl.textContent = '00:00';
            countdownEl.classList.remove('text-amber-600');
            countdownEl.classList.add('text-rose-600');
            if (noteEl) {
                noteEl.textContent = message;
                noteEl.classList.remove('text-amber-700');
                noteEl.classList.add('text-rose-700');
            }
        }

        function renderPaid() {
            countdownEl.textContent = 'ĐÃ THANH TOÁN';
            countdownEl.classList.remove('text-amber-600');
            countdownEl.classList.add('text-emerald-600');
            if (noteEl) {
                noteEl.textContent = 'Giao dịch đã được xác nhận thành công';
                noteEl.classList.remove('text-amber-700');
                noteEl.classList.add('text-emerald-700');
            }
        }

        if (status === 'PAID') {
            renderPaid();
            return;
        }

        if (status === 'EXPIRED' || expiresAt <= 0) {
            renderExpired('Mã QR đã hết hạn');
            return;
        }

        function tick() {
            var remainingMs = expiresAt - Date.now();
            if (remainingMs <= 0) {
                renderExpired('Mã QR đã hết hạn');
                window.clearInterval(timerId);
                return;
            }

            var totalSeconds = Math.floor(remainingMs / 1000);
            var hours = Math.floor(totalSeconds / 3600);
            var minutes = Math.floor((totalSeconds % 3600) / 60);
            var seconds = totalSeconds % 60;

            countdownEl.textContent = hours > 0
                    ? pad(hours) + ':' + pad(minutes) + ':' + pad(seconds)
                    : pad(minutes) + ':' + pad(seconds);
        }

        tick();
        var timerId = window.setInterval(tick, 1000);
    })();
</script>
</body>
</html>
