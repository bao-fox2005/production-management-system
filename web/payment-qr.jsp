<%@page contentType="text/html" pageEncoding="UTF-8" import="java.lang.String, pms.model.PaymentDTO, java.text.DecimalFormat, java.text.SimpleDateFormat, java.util.Date, java.sql.Timestamp, pms.model.UserDTO"%>
<%
    PaymentDTO payment = (PaymentDTO) request.getAttribute("payment");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    String action = request.getParameter("action");
    if (action == null && payment == null) action = "create";
    else if (action == null) action = "view";

    DecimalFormat df = new DecimalFormat("#,###");
    SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss dd/MM/yyyy");
    SimpleDateFormat isoSdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");

    String qrImageBase64 = "";
    String qrVietQrUrl = "";
    String expiresAtIso = "";
    if (payment != null && payment.getQrCodeData() != null) {
        String[] parts = payment.getQrCodeData().split("\\|QR_URL\\|");
        qrImageBase64 = parts[0];
        if (parts.length > 1) qrVietQrUrl = parts[1];
    }
    if (payment != null && payment.getExpiresAt() != null) {
        expiresAtIso = isoSdf.format(payment.getExpiresAt());
    }
    
    String userName = user != null ? user.getUsername() : "";
    String userInitial = userName.length() > 0 ? userName.substring(0, 1).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thanh Toan QR - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
    </style>
</head>
<body class="bg-slate-100 min-h-screen">
    <!-- Header -->
    <header class="bg-white border-b border-slate-200 shadow-sm sticky top-0 z-30">
        <div class="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl bg-teal-500/10 flex items-center justify-center text-teal-600 font-bold">&#9881;</div>
                <div>
                    <p class="text-sm font-semibold text-slate-800">PMS System</p>
                    <p class="text-xs text-slate-500">Thanh Toan QR</p>
                </div>
            </div>
            <div class="flex items-center gap-3">
                <% if (user != null) { %>
                <a href="UserController?action=viewProfile" class="flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 transition-colors">
                    <div class="w-8 h-8 rounded-full bg-teal-500/20 text-teal-600 flex items-center justify-center text-sm font-bold"><%= userInitial %></div>
                    <span class="text-sm font-medium text-slate-700 hidden sm:block"><%= userName %></span>
                </a>
                <% } %>
                <a href="PaymentController?action=list" class="px-4 py-2 rounded-xl border border-slate-200 text-sm font-medium text-slate-600 hover:bg-slate-50">Danh Sach</a>
                <a href="BangDieuKien.jsp" class="px-4 py-2 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700">Trang Chu</a>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <div class="max-w-2xl mx-auto px-4 py-6">
        <% if (msg != null) { %>
        <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= msg %>
        </div>
        <% } %>
        <% if (error != null) { %>
        <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= error %>
        </div>
        <% } %>

        <% if (payment == null) { %>
        <!-- FORM TAO QR -->
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">
            <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-5 text-white">
                <h2 class="text-xl font-bold">Tao Ma QR Thanh Toan</h2>
                <p class="text-teal-100 text-sm mt-1">Nhap thong tin de tao ma thanh toan moi</p>
            </div>
            <form action="PaymentController" method="post" class="p-6 space-y-5">
                <input type="hidden" name="action" value="createQr"/>
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">Ma Hoa Don *</label>
                    <input type="number" name="bill_id" placeholder="Nhap ma hoa don" required
                           class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                </div>
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">So Tien (VND) *</label>
                    <input type="number" name="amount" placeholder="Nhap so tien" step="1000" min="1000" required
                           class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                </div>
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">Thoi Gian Hieu Luc</label>
                    <select name="expire_minutes" class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                        <option value="5">5 phut</option>
                        <option value="10">10 phut</option>
                        <option value="15" selected>15 phut</option>
                        <option value="30">30 phut</option>
                        <option value="60">60 phut</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">Ten Khach Hang</label>
                    <input type="text" name="customer_name" placeholder="Nhap ten khach hang"
                           class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                </div>
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">Email Khach Hang</label>
                    <input type="email" name="customer_email" placeholder="Nhap email"
                           class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                </div>
                <button type="submit" class="w-full py-3 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all">
                    Tao QR Thanh Toan
                </button>
            </form>
        </div>

        <% } else { %>
        <!-- HIEN THI QR -->
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">
            <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-5 text-white">
                <h2 class="text-xl font-bold">Thong Tin Thanh Toan</h2>
                <p class="text-teal-100 text-sm mt-1">Ma QR thanh toan cho hoa don</p>
            </div>
            
            <!-- Info Grid -->
            <div class="p-6">
                <div class="grid grid-cols-2 gap-4 mb-6">
                    <div class="bg-slate-50 rounded-xl p-4 border border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-500">Ma Thanh Toan</p>
                        <p class="text-lg font-bold text-teal-600 mt-1">#<%= payment.getPaymentId() %></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-4 border border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-500">Ma Hoa Don</p>
                        <p class="text-lg font-bold text-slate-800 mt-1">HD<%= String.format("%06d", payment.getBillId()) %></p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-4 border border-slate-100 col-span-2">
                        <p class="text-xs font-semibold uppercase text-slate-500">Tong So Tien</p>
                        <p class="text-2xl font-bold text-teal-600 mt-1"><%= df.format(payment.getAmount()) %> VND</p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-4 border border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-500">Trang Thai</p>
                        <p class="text-lg font-bold mt-1 <%= "PAID".equals(payment.getStatus()) ? "text-emerald-600" : "text-amber-600" %>">
                            <%= payment.getStatus() %>
                        </p>
                    </div>
                    <div class="bg-slate-50 rounded-xl p-4 border border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-500">Ngan Hang</p>
                        <p class="text-lg font-semibold text-slate-800 mt-1"><%= payment.getBankAccountName() != null ? payment.getBankAccountName() : "PMS Company" %></p>
                    </div>
                </div>

                <% if (!"PAID".equals(payment.getStatus()) && !"CANCELLED".equals(payment.getStatus())) { %>
                <!-- TIMER -->
                <div id="timerBox" class="<%= payment.isExpired() ? "bg-red-50 border-2 border-red-500" : "bg-amber-50 border-2 border-amber-500" %> rounded-2xl p-5 text-center mb-6">
                    <p class="text-sm font-semibold <%= payment.isExpired() ? "text-red-600" : "text-amber-600" %>" id="timerLabel">
                        <%= payment.isExpired() ? "DA HET HAN" : "Thoi Gian Con Lai" %>
                    </p>
                    <p class="text-4xl font-bold <%= payment.isExpired() ? "text-red-600" : "text-amber-600" %> mt-2 font-mono" id="timerValue">--:--</p>
                </div>
                <% } %>

                <% if (!payment.isExpired() && !"PAID".equals(payment.getStatus()) && !"CANCELLED".equals(payment.getStatus())) { %>
                <!-- QR CODE -->
                <div class="bg-slate-50 rounded-2xl p-6 text-center mb-6">
                    <% if (qrImageBase64 != null && !qrImageBase64.isEmpty()) { %>
                    <img src="data:image/png;base64,<%= qrImageBase64 %>" alt="QR Code" class="max-w-[280px] mx-auto rounded-xl border-2 border-slate-200">
                    <% } else { %>
                    <div class="w-[280px] h-[280px] mx-auto bg-slate-200 rounded-xl flex items-center justify-center text-slate-400">
                        QR Code se hien thi o day
                    </div>
                    <% } %>
                    <p class="text-sm text-slate-500 mt-4">Quet ma QR de thanh toan</p>
                </div>

                <div class="bg-amber-50 border border-amber-200 rounded-xl p-4 text-center text-amber-700 mb-6">
                    Vui long thanh toan truoc khi het han. Ma QR se tu dong vo hieu luc sau <strong id="expireMinutesDisplay">15</strong> phut.
                </div>

                <!-- Actions -->
                <div class="space-y-3">
                    <form action="PaymentController" method="post">
                        <input type="hidden" name="action" value="refreshQr"/>
                        <input type="hidden" name="payment_id" value="<%= payment.getPaymentId() %>"/>
                        <div class="mb-3">
                            <label class="block text-sm font-semibold text-slate-700 mb-2">Tai tao QR (chon thoi gian)</label>
                            <select name="expire_minutes" class="w-full px-4 py-2 rounded-xl border border-slate-200">
                                <option value="5">5 phut</option>
                                <option value="10">10 phut</option>
                                <option value="15" selected>15 phut</option>
                                <option value="30">30 phut</option>
                                <option value="60">60 phut</option>
                            </select>
                        </div>
                        <button type="submit" class="w-full py-2.5 rounded-xl border border-slate-200 text-slate-600 font-medium hover:bg-slate-50 transition-all">
                            Tai Tao Ma QR Moi
                        </button>
                    </form>

                    <form action="PaymentController" method="post" class="pt-2 border-t border-slate-100">
                        <input type="hidden" name="action" value="confirmPayment"/>
                        <input type="hidden" name="payment_id" value="<%= payment.getPaymentId() %>"/>
                        <div class="mb-3">
                            <label class="block text-sm font-semibold text-slate-700 mb-2">Ma Giao Dich (neu da thanh toan)</label>
                            <input type="text" name="transaction_id" placeholder="Nhap ma giao dich"
                                   class="w-full px-4 py-2 rounded-xl border border-slate-200">
                        </div>
                        <button type="submit" class="w-full py-3 rounded-xl bg-emerald-600 text-white font-semibold hover:bg-emerald-700 transition-all">
                            Xac Nhan Thanh Toan
                        </button>
                    </form>
                </div>
                <% } else if ("PAID".equals(payment.getStatus())) { %>
                <div class="bg-emerald-50 border border-emerald-200 rounded-xl p-6 text-center text-emerald-700 mb-6">
                    <div class="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4 text-3xl">&#10004;</div>
                    <p class="text-xl font-bold">Da Thanh Toan Thanh Cong!</p>
                    <p class="text-sm mt-2 opacity-75">Thoi gian: <%= payment.getPaidAt() != null ? sdf.format(payment.getPaidAt()) : "" %></p>
                    <p class="text-sm opacity-75">Ma giao dich: <%= payment.getTransactionId() != null ? payment.getTransactionId() : "-" %></p>
                </div>
                <% } else { %>
                <div class="bg-red-50 border border-red-200 rounded-xl p-6 text-center text-red-700 mb-6">
                    <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4 text-3xl">&#10006;</div>
                    <p class="text-xl font-bold">Ma QR Da Het Han</p>
                    <p class="text-sm mt-2 opacity-75">Vui long tai tao moi.</p>
                </div>
                <% } %>
            </div>
        </div>
        <% } %>
    </div>

    <script>
        (function() {
            var paymentId = <%= payment != null ? payment.getPaymentId() : "null" %>;
            var status = "<%= payment != null ? payment.getStatus() : "" %>";
            var expiresAt = <%= expiresAtIso.isEmpty() ? "null" : "new Date('" + expiresAtIso + "')" %>;

            if (paymentId && status === 'PENDING' && expiresAt && expiresAt.getFullYear() > 2000) {
                startCountdown(expiresAt, paymentId);
            }
        })();

        function startCountdown(expiresAt, paymentId) {
            var timerValue = document.getElementById('timerValue');
            var timerLabel = document.getElementById('timerLabel');
            var expireDisplay = document.getElementById('expireMinutesDisplay');
            var timerBox = document.getElementById('timerBox');

            if (expireDisplay) {
                expireDisplay.textContent = Math.round((expiresAt - new Date()) / 60000) || 15;
            }

            function update() {
                var now = new Date();
                var remaining = expiresAt - now;

                if (remaining <= 0) {
                    if (timerValue) timerValue.textContent = "00:00";
                    if (timerLabel) timerLabel.textContent = "DA HET HAN";
                    if (timerBox) {
                        timerBox.classList.remove('bg-amber-50', 'border-amber-500');
                        timerBox.classList.add('bg-red-50', 'border-red-500');
                    }
                    clearInterval(interval);
                    checkStatus(paymentId);
                    return;
                }

                var minutes = Math.floor(remaining / 60000);
                var seconds = Math.floor((remaining % 60000) / 1000);
                if (timerValue) {
                    timerValue.textContent = String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
                }

                if (remaining < 120000 && timerBox) {
                    timerBox.classList.remove('bg-amber-50', 'border-amber-500');
                    timerBox.classList.add('bg-red-50', 'border-red-500');
                }
            }

            update();
            var interval = setInterval(update, 1000);
        }

        function checkStatus(paymentId) {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', 'PaymentController?action=checkStatus&payment_id=' + paymentId, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    try {
                        var json = JSON.parse(xhr.responseText);
                        if (json.status === 'PAID' || json.status === 'EXPIRED') {
                            location.reload();
                        }
                    } catch(e) {}
                }
            };
            xhr.send();
        }
    </script>
</body>
</html>
