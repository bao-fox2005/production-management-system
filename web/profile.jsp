<%@page contentType="text/html" pageEncoding="UTF-8" import="pms.model.UserDTO, java.text.SimpleDateFormat, java.util.Date"%>
<%
    UserDTO user = (UserDTO) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trang Ca Nhan - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .avatar-circle {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
            font-weight: 700;
            background: linear-gradient(135deg, #0d9488 0%, #14b8a6 100%);
            color: white;
            box-shadow: 0 8px 32px rgba(20, 184, 166, 0.3);
        }
        .avatar-sm {
            width: 48px;
            height: 48px;
            font-size: 20px;
        }
        .avatar-xs {
            width: 32px;
            height: 32px;
            font-size: 14px;
        }
        .stat-mini {
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 16px;
            text-align: center;
        }
        .stat-mini-value {
            font-size: 24px;
            font-weight: 700;
            color: #0f172a;
        }
        .stat-mini-label {
            font-size: 12px;
            color: #64748b;
            margin-top: 4px;
        }
        .tab-btn {
            padding: 12px 24px;
            font-weight: 600;
            color: #64748b;
            border-bottom: 2px solid transparent;
            transition: all 0.2s;
        }
        .tab-btn:hover {
            color: #0f172a;
        }
        .tab-btn.active {
            color: #0d9488;
            border-bottom-color: #0d9488;
        }
        .form-input:focus {
            border-color: #0d9488;
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1);
        }
        .btn-primary {
            background: linear-gradient(135deg, #0d9488 0%, #14b8a6 100%);
            color: white;
            transition: all 0.2s;
        }
        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(20, 184, 166, 0.3);
        }
    </style>
</head>
<body class="bg-slate-50 min-h-screen">
    <div class="max-w-5xl mx-auto px-4 py-8">
        <!-- Header -->
        <div class="flex items-center gap-4 mb-8">
            <a href="BangDieuKien.jsp" class="flex items-center gap-2 text-slate-600 hover:text-slate-900 transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
                </svg>
                Quay lại
            </a>
            <span class="text-slate-300">|</span>
            <h1 class="text-xl font-semibold text-slate-900">Trang Ca Nhan</h1>
        </div>

        <!-- Alerts -->
        <% if (msg != null) { %>
        <div class="mb-6 p-4 rounded-xl bg-amber-50 border border-amber-200 text-amber-700 flex items-center gap-3">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
            </svg>
            <%= msg %>
        </div>
        <% } %>
        <% if (error != null) { %>
        <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= error %>
        </div>
        <% } %>
        <% if (success != null) { %>
        <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center gap-3">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= success %>
        </div>
        <% } %>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Left: Avatar & Quick Info -->
            <div class="lg:col-span-1">
                <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
                    <!-- Profile Header -->
                    <div class="bg-gradient-to-br from-teal-500 to-teal-600 p-6 text-center">
                        <div class="avatar-circle mx-auto mb-4">
                            <%= user.getUsername() != null ? user.getUsername().substring(0, 1).toUpperCase() : "U" %>
                        </div>
                        <h2 class="text-xl font-bold text-white"><%= user.getFullName() != null ? user.getFullName() : user.getUsername() %></h2>
                        <p class="text-teal-100 mt-1">
                            <% if ("admin".equals(user.getRole())) { %>
                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/20 text-white text-sm">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                                    </svg>
                                    Quản trị viên
                                </span>
                            <% } else { %>
                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/20 text-white text-sm">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                                    </svg>
                                    Công nhân
                                </span>
                            <% } %>
                        </p>
                    </div>

                    <!-- Quick Stats -->
                    <div class="p-4 border-t border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-400 tracking-wider mb-3">Thong tin nhanh</p>
                        <div class="grid grid-cols-2 gap-3">
                            <div class="stat-mini">
                                <div class="stat-mini-value">#<%= user.getId() %></div>
                                <div class="stat-mini-label">Ma User</div>
                            </div>
                            <div class="stat-mini">
                                <div class="stat-mini-value">
                                    <span class="inline-flex items-center justify-center w-6 h-6 rounded-full <%= "active".equals(user.getStatus()) ? "bg-emerald-100 text-emerald-600" : "bg-red-100 text-red-600" %>">
                                        <% if ("active".equals(user.getStatus())) { %>
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                        </svg>
                                        <% } else { %>
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                        </svg>
                                        <% } %>
                                    </span>
                                </div>
                                <div class="stat-mini-label">Trang Thai</div>
                            </div>
                        </div>
                    </div>

                    <!-- Contact Info -->
                    <div class="p-4 border-t border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-400 tracking-wider mb-3">Lien he</p>
                        <div class="space-y-3">
                            <div class="flex items-center gap-3">
                                <div class="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center text-slate-500">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                                    </svg>
                                </div>
                                <div class="flex-1 min-w-0">
                                    <p class="text-xs text-slate-400">Email</p>
                                    <p class="text-sm text-slate-700 truncate"><%= user.getEmail() != null ? user.getEmail() : "Chua co" %></p>
                                </div>
                            </div>
                            <div class="flex items-center gap-3">
                                <div class="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center text-slate-500">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                                    </svg>
                                </div>
                                <div class="flex-1 min-w-0">
                                    <p class="text-xs text-slate-400">Dien thoai</p>
                                    <p class="text-sm text-slate-700"><%= user.getPhone() != null ? user.getPhone() : "Chua co" %></p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Timestamps -->
                    <div class="p-4 border-t border-slate-100">
                        <p class="text-xs font-semibold uppercase text-slate-400 tracking-wider mb-3">Thoi gian</p>
                        <div class="space-y-2 text-sm">
                            <div class="flex justify-between">
                                <span class="text-slate-500">Tao tai khoan:</span>
                                <span class="text-slate-700 font-medium"><%= user.getCreatedDate() != null ? sdf.format(user.getCreatedDate()) : "Chua xac dinh" %></span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right: Tabs Content -->
            <div class="lg:col-span-2">
                <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
                    <!-- Tabs Header -->
                    <div class="border-b border-slate-100">
                        <div class="flex">
                            <button onclick="switchTab('profile')" id="tab-profile" class="tab-btn active">
                                <span class="flex items-center gap-2">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                                    </svg>
                                    Thong Tin Ca Nhan
                                </span>
                            </button>
                            <button onclick="switchTab('password')" id="tab-password" class="tab-btn">
                                <span class="flex items-center gap-2">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"/>
                                    </svg>
                                    Doi Mat Khau
                                </span>
                            </button>
                        </div>
                    </div>

                    <!-- Tab: Profile -->
                    <div id="content-profile" class="p-6">
                        <form action="UserController" method="post" class="space-y-6">
                            <input type="hidden" name="action" value="updateProfile">
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Username</label>
                                    <input type="text" value="<%= user.getUsername() %>" disabled
                                           class="w-full px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 text-slate-500">
                                    <p class="text-xs text-slate-400 mt-1">Username khong the thay doi</p>
                                </div>
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Ho Ten</label>
                                    <input type="text" name="fullName" value="<%= user.getFullName() != null ? user.getFullName() : "" %>"
                                           placeholder="Nhap ho ten day du"
                                           class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all">
                                </div>
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Email</label>
                                    <input type="email" name="email" value="<%= user.getEmail() != null ? user.getEmail() : "" %>"
                                           placeholder="Nhap dia chi email"
                                           class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all">
                                </div>
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">So Dien Thoai</label>
                                    <input type="text" name="phone" value="<%= user.getPhone() != null ? user.getPhone() : "" %>"
                                           placeholder="Nhap so dien thoai"
                                           class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all">
                                </div>
                            </div>

                            <div class="flex items-center gap-4 pt-4 border-t border-slate-100">
                                <button type="submit" class="btn-primary px-6 py-3 rounded-xl font-semibold flex items-center gap-2">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                    </svg>
                                    Luu Thay Doi
                                </button>
                                <a href="BangDieuKien.jsp" class="px-6 py-3 rounded-xl font-semibold text-slate-600 hover:text-slate-900 transition-colors">
                                    Huy Bo
                                </a>
                            </div>
                        </form>
                    </div>

                    <!-- Tab: Password -->
                    <div id="content-password" class="p-6 hidden">
                        <div class="max-w-md">
                            <div class="mb-6">
                                <h3 class="text-lg font-semibold text-slate-900">Doi Mat Khau</h3>
                                <p class="text-sm text-slate-500 mt-1">Mat khau phai it nhat 6 ky tu</p>
                            </div>

                        <form action="UserController" method="post" class="space-y-4">
                            <input type="hidden" name="action" value="changePasswordForm">
                                <input type="hidden" name="userId" value="<%= user.getId() %>">
                                
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Mat Khau Hien Tai</label>
                                    <div class="relative">
                                        <input type="password" name="currentPassword" id="currentPassword" required
                                               placeholder="Nhap mat khau hien tai"
                                               class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all pr-12">
                                        <button type="button" onclick="togglePassword('currentPassword')" 
                                                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                                            <svg id="eye-currentPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                            </svg>
                                        </button>
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Mat Khau Moi</label>
                                    <div class="relative">
                                        <input type="password" name="newPassword" id="newPassword" required minlength="6"
                                               placeholder="Nhap mat khau moi (it nhat 6 ky tu)"
                                               class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all pr-12">
                                        <button type="button" onclick="togglePassword('newPassword')"
                                                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                                            <svg id="eye-newPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                            </svg>
                                        </button>
                                    </div>
                                    <div class="mt-2">
                                        <div id="passwordStrength" class="h-1 rounded-full bg-slate-200 transition-all">
                                            <div id="passwordStrengthBar" class="h-full rounded-full transition-all" style="width: 0%"></div>
                                        </div>
                                        <p id="passwordStrengthText" class="text-xs text-slate-400 mt-1">Do manh mat khau</p>
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 mb-2">Xac Nhan Mat Khau Moi</label>
                                    <div class="relative">
                                        <input type="password" name="confirmPassword" id="confirmPassword" required minlength="6"
                                               placeholder="Nhap lai mat khau moi"
                                               class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all pr-12">
                                        <button type="button" onclick="togglePassword('confirmPassword')"
                                                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                                            <svg id="eye-confirmPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                            </svg>
                                        </button>
                                    </div>
                                    <p id="passwordMatch" class="text-xs mt-1 hidden"></p>
                                </div>

                                <div class="pt-4">
                                    <button type="submit" class="btn-primary w-full py-3 rounded-xl font-semibold flex items-center justify-center gap-2">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"/>
                                        </svg>
                                        Cap Nhat Mat Khau
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Tab switching
        function switchTab(tabName) {
            // Hide all content
            document.getElementById('content-profile').classList.add('hidden');
            document.getElementById('content-password').classList.add('hidden');
            
            // Remove active from all tabs
            document.getElementById('tab-profile').classList.remove('active');
            document.getElementById('tab-password').classList.remove('active');
            
            // Show selected content
            document.getElementById('content-' + tabName).classList.remove('hidden');
            document.getElementById('tab-' + tabName).classList.add('active');
        }

        // Toggle password visibility
        function togglePassword(inputId) {
            const input = document.getElementById(inputId);
            const eye = document.getElementById('eye-' + inputId);
            
            if (input.type === 'password') {
                input.type = 'text';
                eye.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/>';
            } else {
                input.type = 'password';
                eye.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>';
            }
        }

        // Password strength meter
        document.getElementById('newPassword').addEventListener('input', function(e) {
            const password = e.target.value;
            const strengthBar = document.getElementById('passwordStrengthBar');
            const strengthText = document.getElementById('passwordStrengthText');
            
            let strength = 0;
            let color = '#e2e8f0';
            let text = 'Do manh mat khau';
            
            if (password.length >= 6) strength += 25;
            if (password.length >= 8) strength += 25;
            if (/[A-Z]/.test(password) && /[a-z]/.test(password)) strength += 25;
            if (/[0-9]/.test(password) || /[^A-Za-z0-9]/.test(password)) strength += 25;
            
            if (strength >= 75) {
                color = '#10b981';
                text = 'Mat khau manh';
            } else if (strength >= 50) {
                color = '#f59e0b';
                text = 'Mat khau trung binh';
            } else if (strength >= 25) {
                color = '#f97316';
                text = 'Mat khau yeu';
            }
            
            strengthBar.style.width = strength + '%';
            strengthBar.style.backgroundColor = color;
            strengthText.textContent = text;
            strengthText.style.color = color;
        });

        // Confirm password matching
        document.getElementById('confirmPassword').addEventListener('input', function(e) {
            const newPass = document.getElementById('newPassword').value;
            const confirmPass = e.target.value;
            const matchText = document.getElementById('passwordMatch');
            
            if (confirmPass.length > 0) {
                matchText.classList.remove('hidden');
                if (newPass === confirmPass) {
                    matchText.textContent = 'Mat khau khop';
                    matchText.style.color = '#10b981';
                } else {
                    matchText.textContent = 'Mat khau khong khop';
                    matchText.style.color = '#ef4444';
                }
            } else {
                matchText.classList.add('hidden');
            }
        });
    </script>
</body>
</html>
