<%-- user-form.jsp - Thêm/Sửa người dùng --%>
<%@page import="pms.model.UserDTO, pms.utils.NotificationService.Notification"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String mode = (String) request.getAttribute("mode");
    UserDTO u = (UserDTO) request.getAttribute("u");
    UserDTO currentUser = (UserDTO) session.getAttribute("user");
    List<Notification> notifications = (List<Notification>) session.getAttribute("notifications");
    boolean isAdd = "add".equals(mode);
    
    if (notifications == null) notifications = new java.util.ArrayList<>();
    
    int unreadCount = 0;
    for (Notification n : notifications) {
        if (!n.isRead()) unreadCount++;
    }
    
    String userName = currentUser != null ? currentUser.getUsername() : "User";
    String userRole = currentUser != null ? currentUser.getRole() : "user";
    String pageTitle = isAdd ? "Thêm Người Dùng" : "Sửa Người Dùng";
    String pageSubtitle = isAdd ? "Tạo tài khoản mới" : "Cập nhật thông tin";
    request.setAttribute("activePage", "user");
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= pageTitle %> - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif'],
                    },
                }
            }
        }
    </script>
    <style>
        * { font-family: 'Inter', 'Segoe UI', Arial, sans-serif; }
        body { overflow-x: hidden; }
        
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
        .sidebar-nav::-webkit-scrollbar {
            width: 4px;
        }
        .sidebar-nav::-webkit-scrollbar-track {
            background: #1e293b;
        }
        .sidebar-nav::-webkit-scrollbar-thumb {
            background: #475569;
            border-radius: 2px;
        }
        
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
            .main-wrapper {
                margin-left: 280px;
            }
        }
        
        .notif-badge { animation: pulse 2s infinite; }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        
        .form-card {
            transition: all 0.2s ease;
        }
        .form-card:focus-within {
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.2);
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
                <div class="mb-6">
                    <div class="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400 mb-2">
                        <a href="UserController?action=list" class="hover:text-teal-600 dark:hover:text-teal-400 transition-colors">Người dùng</a>
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                        </svg>
                        <span class="text-slate-700 dark:text-slate-200"><%= pageTitle %></span>
                    </div>
                    <h1 class="text-2xl font-bold text-slate-800 dark:text-slate-100"><%= pageTitle %></h1>
                    <p class="text-sm text-slate-500 dark:text-slate-400 mt-1"><%= pageSubtitle %></p>
                </div>

                <!-- Alerts -->
                <% if (request.getAttribute("msg") != null) { %>
                <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 dark:bg-emerald-900/30 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= request.getAttribute("msg") %>
                </div>
                <% } %>
                <% if (request.getAttribute("error") != null) { %>
                <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 dark:bg-red-900/30 dark:border-red-800 text-red-700 dark:text-red-300 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= request.getAttribute("error") %>
                </div>
                <% } %>

                <!-- Form Card -->
                <div class="max-w-2xl">
                    <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm overflow-hidden">
                        <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-5 text-white">
                            <h2 class="text-lg font-semibold flex items-center gap-2">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M<%= isAdd ? "16 13v6m-3-3h6M6 10h2a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2zm10 0h2a2 2 0 002-2V6a2 2 0 00-2-2h-2a2 2 0 00-2 2v2a2 2 0 002 2zM6 20h2a2 2 0 002-2v-2a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2z" : "user-edit me-2"/>
                                </svg>
                                <%= isAdd ? "Tạo tài khoản mới" : "Cập nhật thông tin" %>
                            </h2>
                        </div>
                        
                        <form method="post" action="UserController" class="p-6 space-y-5">
                            <input type="hidden" name="action" value="<%= isAdd ? "saveAddUser" : "saveUpdateUser" %>">
                            <% if (!isAdd) { %>
                                <input type="hidden" name="id" value="<%= u.getId() %>">
                            <% } %>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                                <!-- Username -->
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                        Username <span class="text-red-500">*</span>
                                    </label>
                                    <input type="text" name="username" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all" required
                                           value="<%= u != null ? u.getUsername() : "" %>"
                                           <%= !isAdd ? "readonly" : "" %>>
                                    <% if (!isAdd) { %>
                                    <p class="text-xs text-slate-400 mt-1">Không thể thay đổi username</p>
                                    <% } %>
                                </div>
                                
                                <!-- Password -->
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                        Mật khẩu <%= isAdd ? "<span class='text-red-500'>*</span>" : "" %>
                                    </label>
                                    <input type="password" name="password" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all"
                                           <%= isAdd ? "required" : "" %> 
                                           placeholder="<%= isAdd ? "Nhập mật khẩu" : "Để trống nếu không đổi" %>">
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                                <!-- Full Name -->
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                        Họ tên
                                    </label>
                                    <input type="text" name="fullName" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all"
                                           value="<%= u != null ? (u.getFullName() != null ? u.getFullName() : "") : "" %>">
                                </div>
                                
                                <!-- Role -->
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                        Vai trò <span class="text-red-500">*</span>
                                    </label>
                                    <select name="role" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all" required>
                                        <option value="">-- Chọn vai trò --</option>
                                        <option value="admin" <%= u != null && "admin".equals(u.getRole()) ? "selected" : "" %>>Admin</option>
                                        <option value="employee" <%= u != null && "employee".equals(u.getRole()) ? "selected" : "" %>>Công nhân</option>
                                    </select>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                                <!-- Email -->
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                        Email
                                    </label>
                                    <input type="email" name="email" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all"
                                           value="<%= u != null ? (u.getEmail() != null ? u.getEmail() : "") : "" %>">
                                </div>
                                
                                <!-- Phone -->
                                <div>
                                    <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                        Điện thoại
                                    </label>
                                    <input type="text" name="phone" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all"
                                           value="<%= u != null ? (u.getPhone() != null ? u.getPhone() : "") : "" %>">
                                </div>
                            </div>

                            <% if (!isAdd) { %>
                            <div>
                                <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                                    Trạng thái <span class="text-red-500">*</span>
                                </label>
                                <select name="status" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all" required>
                                    <option value="active" <%= u != null && "active".equals(u.getStatus()) ? "selected" : "" %>>Hoạt động</option>
                                    <option value="inactive" <%= u != null && "inactive".equals(u.getStatus()) ? "selected" : "" %>>Khóa</option>
                                </select>
                            </div>
                            <% } %>

                            <div class="flex gap-3 pt-4 border-t border-slate-100 dark:border-slate-700">
                                <button type="submit" class="px-6 py-2.5 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-colors flex items-center gap-2 shadow-lg shadow-teal-600/30">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                    </svg>
                                    Lưu
                                </button>
                                <a href="UserController?action=list" class="px-6 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-medium hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">
                                    Hủy
                                </a>
                            </div>
                        </form>
                    </div>
                </div>
            </main>
        </div>
    </div>
</body>
</html>
