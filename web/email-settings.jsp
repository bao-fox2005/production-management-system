<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.Properties, pms.model.UserDTO"%>
<%
    UserDTO user = (UserDTO) session.getAttribute("user");
    Properties smtpConfig = (Properties) request.getAttribute("smtpConfig");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");

    if (smtpConfig == null) smtpConfig = new Properties();

    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = request.getAttribute("activePage") != null ? (String) request.getAttribute("activePage") : "smtp";
    String pageTitle = request.getAttribute("pageTitle") != null ? (String) request.getAttribute("pageTitle") : "Cấu hình SMTP";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cấu hình SMTP - PMS</title>
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
        .section-card { background: rgba(255,255,255,0.95); backdrop-filter: blur(12px); }
        .dark .section-card { background: rgba(15,23,42,0.92); }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-teal-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-teal-950/20">
                    <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                        <div>
                            <div class="inline-flex items-center gap-2 rounded-full border border-teal-200 bg-teal-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-teal-700 dark:border-teal-500/30 dark:bg-teal-500/10 dark:text-teal-300">System Email</div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100">Cấu hình Email SMTP</h1>
                            <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Đồng bộ cấu hình email gửi tự động cho thông báo hóa đơn, thanh toán và vận hành.</p>
                        </div>
                        <a href="AdminController" class="inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">
                            Tải lại cấu hình
                        </a>
                    </div>
                </div>

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

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-5 text-white">
                        <h2 class="text-lg font-semibold">Thông tin máy chủ SMTP</h2>
                        <p class="text-teal-100 text-sm mt-1">Nhập thông tin kết nối email để hệ thống gửi thông báo tự động</p>
                    </div>

                    <form action="AdminController" method="post" class="p-6 space-y-5">
                        <input type="hidden" name="action" value="saveSmtpConfig"/>

                        <input type="hidden" name="smtp_host" value="<%= smtpConfig.getProperty("smtp.host", "") %>">
                        <input type="hidden" name="smtp_port" value="<%= smtpConfig.getProperty("smtp.port", "587") %>">


                        <div class="grid gap-5 sm:grid-cols-2">
                            <div>
                                <label class="block text-sm font-semibold text-slate-700 mb-2 dark:text-slate-300">Email gửi *</label>
                                <input type="email" name="smtp_user" value="<%= smtpConfig.getProperty("smtp.user", "") %>" placeholder="your-email@gmail.com"
                                       autocomplete="off"
                                       class="w-full px-4 py-3 rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 dark:text-white focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                            </div>
                            <div>
                                <label class="block text-sm font-semibold text-slate-700 mb-2 dark:text-slate-300">Mật khẩu *</label>
                                <input type="password" name="smtp_password" value="<%= smtpConfig.getProperty("smtp.password", "") %>" placeholder="App Password"
                                       autocomplete="new-password"
                                       class="w-full px-4 py-3 rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 dark:text-white focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-all">
                                <p class="text-xs text-slate-400 mt-1">Sử dụng App Password cho Gmail</p>
                            </div>
                        </div>

                        <!-- Tạm ẩn cấu hình admin_email khỏi giao diện theo yêu cầu. -->

                        <div class="pt-4 border-t border-slate-100 dark:border-slate-700">
                            <button type="submit" class="w-full sm:w-auto px-6 py-3 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all">
                                Lưu cấu hình
                            </button>
                            <button id="testEmailBtn" type="button" onclick="testEmail()" class="mt-3 sm:mt-0 sm:ml-3 w-full sm:w-auto px-6 py-3 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-semibold hover:bg-slate-50 dark:hover:bg-slate-800 transition-all disabled:opacity-60 disabled:cursor-not-allowed disabled:bg-slate-100 dark:disabled:bg-slate-800">
                                <span id="testEmailBtnText">Gửi email thử</span>
                            </button>
                            <p id="testEmailStatus" class="mt-3 text-sm text-slate-500 hidden">Đang gửi email thử, vui lòng chờ...</p>
                        </div>
                    </form>

                    <div class="bg-blue-50 dark:bg-blue-500/10 border-t border-blue-100 dark:border-blue-500/20 p-5">
                        <div class="flex gap-3">
                            <svg class="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                            </svg>
                            <div>
                                <h4 class="font-semibold text-blue-800 dark:text-blue-300">Hướng dẫn cấu hình Gmail</h4>
                                <ol class="mt-2 text-sm text-blue-700 dark:text-blue-200 space-y-1 list-decimal list-inside">
                                    <li>Bật xác minh 2 bước (2-Step Verification) trong Tài khoản Google</li>
                                    <li>Đi đến App Passwords: https://myaccount.google.com/apppasswords</li>
                                    <li>Tạo App Password mới cho “Mail”</li>
                                    <li>Sao chép App Password vào ô “Mật khẩu”</li>
                                </ol>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
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
                showToast('Vui lòng nhập đầy đủ SMTP Host, Port, Email gửi và App Password trước khi gửi thử.', 'error');
                return;
            }
            if (!smtpUser.includes('@')) {
                showToast('Email gửi không hợp lệ!', 'error');
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
                        showToast(xhr.responseText || 'Email thử đã được gửi! Kiểm tra hộp thư của bạn.', 'success');
                    } else {
                        showToast(normalizeErrorMessage(xhr.responseText, xhr.status), 'error');
                    }
                }
            };
            xhr.onerror = function() {
                testEmailSubmitting = false;
                setTestEmailLoading(false);
                showToast('Không thể kết nối tới máy chủ để gửi email thử.', 'error');
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

        function showToast(message, type) {
            if (!type) {
                type = 'info';
            }

            var toast = document.createElement('div');
            var icon = type === 'success' ? '✅' : '⚠️';
            var title = type === 'success' ? 'Thành công' : 'Lỗi';
            toast.className = 'notice-toast open';
            if (type === 'success') {
                toast.style.borderColor = '#86efac';
                toast.style.background = '#f0fdf4';
                toast.style.color = '#166534';
            } else if (type === 'error') {
                toast.style.borderColor = '#fecaca';
                toast.style.background = '#fff1f2';
                toast.style.color = '#9f1239';
            }

            toast.innerHTML = ''
                + '<div style="display:flex;align-items:start;gap:12px">'
                + '  <span style="font-size:18px;line-height:1">' + icon + '</span>'
                + '  <div style="flex:1">'
                + '      <div style="font-weight:600;margin-bottom:2px">' + title + '</div>'
                + '      <div style="font-size:13px;opacity:0.9">' + message + '</div>'
                + '  </div>'
                + '  <button onclick="this.parentElement.parentElement.remove()" style="background:none;border:none;font-size:18px;cursor:pointer;padding:0 4px;color:inherit;opacity:0.6">×</button>'
                + '</div>';

            document.body.appendChild(toast);

            setTimeout(function () {
                toast.style.transition = 'all 0.3s ease';
                toast.style.opacity = '0';
                toast.style.transform = 'translateY(10px)';
                setTimeout(function () {
                    toast.remove();
                }, 300);
            }, 5000);
        }
    </script>
</body>
</html>
