<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.Properties, pms.model.UserDTO, java.text.SimpleDateFormat"%>
<%
    UserDTO user = (UserDTO) session.getAttribute("user");
    Properties smtpConfig = (Properties) application.getAttribute("smtpConfig");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    
    if (smtpConfig == null) smtpConfig = new Properties();
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    String userInitial = userName.substring(0, 1).toUpperCase();
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cấu hình Email - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
    </style>
</head>
<body class="bg-slate-100 min-h-screen">
    <div class="max-w-2xl mx-auto px-4 py-8">
        <!-- Header -->
        <div class="flex items-center justify-between mb-8">
            <div>
                <h1 class="text-2xl font-bold text-slate-900">Cấu hình Email SMTP</h1>
                <p class="text-sm text-slate-500 mt-1">Cấu hình SMTP để gửi email thông báo</p>
            </div>
            <a href="DashboardController" class="px-4 py-2 rounded-xl bg-white border border-slate-200 text-slate-600 text-sm font-medium hover:bg-slate-50">
                Quay về Dashboard
            </a>
        </div>

        <!-- Alerts -->
        <% if (msg != null && !msg.trim().isEmpty()) { %>
        <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= msg %>
        </div>
        <% } %>
        <% if (error != null && !error.trim().isEmpty()) { %>
        <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= error %>
        </div>
        <% } %>

        <!-- Config Form -->
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">
            <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-5 text-white">
                <h2 class="text-lg font-semibold">Thông tin máy chủ SMTP</h2>
                <p class="text-teal-100 text-sm mt-1">Nhập thông tin cấu hình email của bạn</p>
            </div>
            
            <form action="AdminController" method="post" class="p-6 space-y-5">
                <input type="hidden" name="action" value="saveSmtpConfig"/>
                
                <div class="grid gap-5 sm:grid-cols-2">
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">SMTP Host *</label>
                        <input type="text" name="smtp_host" value="<%= smtpConfig.getProperty("smtp.host", "") %>" placeholder="smtp.gmail.com"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                        <p class="text-xs text-slate-400 mt-1">Ví dụ: smtp.gmail.com, smtp.mail.yahoo.com</p>
                    </div>
                    
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">SMTP Port *</label>
                        <input type="text" name="smtp_port" value="<%= smtpConfig.getProperty("smtp.port", "587") %>" placeholder="587"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                        <p class="text-xs text-slate-400 mt-1">587 (TLS) hoặc 465 (SSL)</p>
                    </div>
                </div>
                
                <div class="grid gap-5 sm:grid-cols-2">
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">Email gửi *</label>
                        <input type="email" name="smtp_user" value="<%= smtpConfig.getProperty("smtp.user", "") %>" placeholder="your-email@gmail.com"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                    </div>
                    
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">Mật khẩu *</label>
                        <input type="password" name="smtp_password" value="<%= smtpConfig.getProperty("smtp.password", "") %>" placeholder="App Password"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                        <p class="text-xs text-slate-400 mt-1">Sử dụng App Password cho Gmail</p>
                    </div>
                </div>
                
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">Email nhận thông báo (Quản trị)</label>
                    <input type="email" name="admin_email" value="<%= smtpConfig.getProperty("admin.email", "") %>" placeholder="admin@company.com"
                           class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                    <p class="text-xs text-slate-400 mt-1">Email nhận các thông báo từ hệ thống</p>
                </div>

                <div class="pt-4 border-t border-slate-100">
                    <button type="submit" class="w-full sm:w-auto px-6 py-3 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all">
                        Lưu cấu hình
                    </button>
                    <button id="testEmailBtn" type="button" onclick="testEmail()" class="ml-3 w-full sm:w-auto px-6 py-3 rounded-xl border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition-all disabled:opacity-60 disabled:cursor-not-allowed disabled:bg-slate-100">
                        <span id="testEmailBtnText">Gửi email thử</span>
                    </button>
                    <p id="testEmailStatus" class="mt-3 text-sm text-slate-500 hidden">Đang gửi email thử, vui lòng chờ...</p>
                </div>
            </form>
            
            <!-- Info Box -->
            <div class="bg-blue-50 border-t border-blue-100 p-5">
                <div class="flex gap-3">
                    <svg class="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <div>
                        <h4 class="font-semibold text-blue-800">Hướng dẫn cấu hình Gmail</h4>
                        <ol class="mt-2 text-sm text-blue-700 space-y-1 list-decimal list-inside">
                            <li>Bật xác minh 2 bước (2-Step Verification) trong Tài khoản Google</li>
                            <li>Đi đến App Passwords https://myaccount.google.com/apppasswords</li>
                            <li>Tạo App Password mới cho "Mail"</li>
                            <li>Sao chép App Password vào ô "Mật khẩu"</li>
                        </ol>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        var testEmailSubmitting = false;

        function setTestEmailLoading(isLoading) {
            var btn = document.getElementById('testEmailBtn');
            var btnText = document.getElementById('testEmailBtnText');
            var status = document.getElementById('testEmailStatus');

            if (!btn || !btnText || !status) {
                return;
            }

            btn.disabled = isLoading;
            btnText.textContent = isLoading ? 'Đang gửi...' : 'Gửi email thử';
            status.classList.toggle('hidden', !isLoading);
        }

        function testEmail() {
            if (testEmailSubmitting) {
                return;
            }

            var smtpHost = document.querySelector('input[name="smtp_host"]').value.trim();
            var smtpPort = document.querySelector('input[name="smtp_port"]').value.trim();
            var smtpUser = document.querySelector('input[name="smtp_user"]').value.trim();
            var smtpPassword = document.querySelector('input[name="smtp_password"]').value;

            if (!smtpHost || !smtpPort || !smtpUser || !smtpPassword) {
                alert('Vui lòng nhập đầy đủ SMTP Host, Port, Email gửi và App Password trước khi gửi thử.');
                return;
            }
            if (!smtpUser.includes('@')) {
                alert('Email gửi không hợp lệ!');
                return;
            }

            function normalizeErrorMessage(responseText, status) {
                var text = (responseText || '').trim();
                var lower = text.toLowerCase();

                if (!text) {
                    return 'Gửi email thử thất bại. Mã lỗi HTTP: ' + status;
                }

                if (lower.indexOf('<!doctype html') !== -1 || lower.indexOf('<html') !== -1 || lower.indexOf('http status 500') !== -1) {
                    return 'Máy chủ đang báo lỗi khi gửi email thử. Kiểm tra lại SMTP Host, Port, Email gửi và App Password Gmail rồi thử lại.';
                }

                return text;
            }

            testEmailSubmitting = true;
            setTestEmailLoading(true);

            var xhr = new XMLHttpRequest();
            xhr.open('POST', 'AdminController', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    testEmailSubmitting = false;
                    setTestEmailLoading(false);

                    if (xhr.status === 200) {
                        alert(xhr.responseText || 'Email thử đã được gửi! Kiểm tra hộp thư của bạn.');
                    } else {
                        alert(normalizeErrorMessage(xhr.responseText, xhr.status));
                    }
                }
            };
            xhr.onerror = function() {
                testEmailSubmitting = false;
                setTestEmailLoading(false);
                alert('Không thể kết nối tới máy chủ để gửi email thử.');
            };
            xhr.send(
                'action=sendTestEmail'
                + '&test_email=' + encodeURIComponent(smtpUser)
                + '&smtp_host=' + encodeURIComponent(smtpHost)
                + '&smtp_port=' + encodeURIComponent(smtpPort)
                + '&smtp_user=' + encodeURIComponent(smtpUser)
                + '&smtp_password=' + encodeURIComponent(smtpPassword)
            );
        }
    </script>
</body>
</html>
