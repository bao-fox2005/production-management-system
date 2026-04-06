<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%-- 
  Shared Header Component for PMS System
  Dùng chung cho tất cả các trang JSP
  
  Tự động lấy biến từ session/request.
 --%>
<%@page import="java.util.List"%>
<%@page import="pms.utils.NotificationService"%>
<%@page import="pms.utils.NotificationService.Notification"%>
<%
    // Lấy user từ session
    pms.model.UserDTO headerUser = (pms.model.UserDTO) session.getAttribute("user");
    String pageTitle = request.getAttribute("pageTitle") != null ? (String) request.getAttribute("pageTitle") : "Bảng điều khiển";
    
    String notificationUsername = headerUser != null ? headerUser.getUsername() : null;
    List<Notification> headerNotifications = NotificationService.getNotifications(notificationUsername);
    int unreadCount = NotificationService.getUnreadCount(notificationUsername);
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    String userName = headerUser != null ? headerUser.getUsername() : "User";
    String userRole = headerUser != null ? headerUser.getRole() : "";
%>

<style>
    @media (min-width: 1024px) {
        #mainWrapper.sidebar-open {
            margin-left: 280px !important;
        }

        #mainWrapper.sidebar-closed {
            margin-left: 0 !important;
        }
    }
</style>

<!-- Header Cố Định - Shared Component -->
<header class="main-header sticky top-0 z-20 h-16 bg-white/95 dark:bg-slate-800/95 border-b border-slate-200 dark:border-slate-700 backdrop-blur pl-2 pr-4 lg:pl-2 lg:pr-6 flex items-center justify-between shadow-sm relative">
    <!-- Left: Menu + Title -->
    <div class="flex items-center gap-2 min-w-0">
        <button id="menuToggle" onclick="toggleSidebar()" class="w-10 h-10 flex items-center justify-center rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors shrink-0" title="Mở/đóng menu trái">
            <svg class="w-5 h-5 text-slate-600 dark:text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
            </svg>
        </button>
        <div>
            <h1 class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= pageTitle %></h1>
        </div>
    </div>

    <!-- Center: Search Box -->
    <div class="hidden md:flex flex-1 max-w-xl mx-4">
        <div class="search-box relative flex items-center w-full rounded-full px-4 py-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm">
            <svg class="w-4 h-4 text-slate-400 dark:text-slate-500 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
            <input
                type="text"
                id="globalSearch"
                placeholder="Tìm kiếm..."
                class="flex-1 bg-transparent outline-none text-sm text-slate-700 dark:text-slate-200 placeholder:text-slate-400 dark:placeholder:text-slate-500"
                onkeyup="handleGlobalSearch(event)"
            />
        </div>
    </div>

    <!-- Right: Language + Dark Mode + Notifications + User -->
    <div class="flex items-center gap-2">
        <!-- Language Toggle -->
        <div class="flex items-center rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700 h-10 bg-white dark:bg-slate-800">
            <a href="?lang=vi" class="px-3 py-1.5 text-xs font-medium flex items-center <%= "vi".equals(lang) ? "bg-teal-500 text-white" : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700" %>">VI</a>
            <a href="?lang=en" class="px-3 py-1.5 text-xs font-medium flex items-center <%= "en".equals(lang) ? "bg-teal-500 text-white" : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700" %>">EN</a>
        </div>
        
        <!-- Dark Mode Toggle -->
        <button onclick="toggleDarkMode()" class="w-10 h-10 flex items-center justify-center rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors" title="Chế độ tối">
            <svg id="moonIcon" class="w-5 h-5 text-slate-600 dark:text-slate-300 <%= isDarkMode ? "hidden" : "" %>" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
            </svg>
            <svg id="sunIcon" class="w-5 h-5 text-slate-600 dark:text-slate-300 <%= isDarkMode ? "" : "hidden" %>" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
            </svg>
        </button>
        
        <!-- Notification Bell -->
        <button id="notifBtn" onclick="toggleNotificationPanel()" class="relative w-10 h-10 flex items-center justify-center rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors">
            <svg class="w-5 h-5 text-slate-600 dark:text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (unreadCount > 0) { %>
            <span id="notifBadge" class="notif-badge absolute -top-1 -right-1 min-w-[20px] h-5 px-1 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                <%= unreadCount > 9 ? "9+" : unreadCount %>
            </span>
            <% } else { %>
            <span id="notifBadge" class="notif-badge absolute -top-1 -right-1 min-w-[20px] h-5 px-1 bg-red-500 text-white text-[10px] font-bold rounded-full hidden items-center justify-center">0</span>
            <% } %>
        </button>
        
        <!-- User: text chào mừng + dropdown -->
        <button id="userDropdownBtn" onclick="toggleUserDropdown()" class="flex items-center gap-2 px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
            <span class="hidden sm:block text-sm font-medium text-slate-700 dark:text-slate-200">Xin chào, <%= userName %></span>
            <svg class="w-4 h-4 text-slate-400 dark:text-slate-500 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
            </svg>
        </button>
    </div>
</header>

<!-- Notification Panel -->
<div id="notifPanel" class="absolute right-4 top-16 w-80 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 hidden z-50 overflow-hidden">
    <div class="p-4 border-b border-slate-100 dark:border-slate-700 flex items-center justify-between">
        <h3 class="font-semibold text-slate-900 dark:text-slate-100">Thông báo</h3>
        <% if (notificationUsername != null && unreadCount > 0) { %>
        <button type="button" onclick="markAllNotificationsRead()" class="text-xs text-teal-600 dark:text-teal-400 hover:text-teal-700 dark:hover:text-teal-300">Đánh dấu đã đọc</button>
        <% } %>
    </div>
    <div id="notifList" class="max-h-80 overflow-y-auto">
        <% if (headerNotifications.isEmpty()) { %>
        <div class="p-8 text-center text-slate-400 dark:text-slate-500" id="notifEmptyState">
            <svg class="w-12 h-12 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/>
            </svg>
            <p>Chưa có thông báo nào</p>
        </div>
        <% } else { %>
        <% for (Notification n : headerNotifications) { %>
        <a href="<%= n.getLink() %>" data-notification-item="true" data-notification-id="<%= n.getId() %>" class="block p-4 border-b border-slate-50 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700/60 transition-colors <%= n.isRead() ? "opacity-60" : "" %>" onclick="return handleNotificationClick(event, '<%= n.getId() %>', '<%= n.getLink() %>')">
            <p data-notification-title="true" class="text-sm font-semibold text-slate-900 dark:text-slate-100 <%= n.isRead() ? "" : "text-teal-600 dark:text-teal-400" %>"><%= n.getTitle() %></p>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5"><%= n.getMessage() %></p>
        </a>
        <% } %>
        <% } %>
    </div>
</div>

<!-- User Dropdown -->
<div id="userDropdown" class="absolute right-4 top-16 w-56 bg-white dark:bg-slate-800 rounded-xl shadow-xl border border-slate-200 dark:border-slate-700 hidden z-50">
    <div class="p-4 border-b border-slate-100 dark:border-slate-700">
        <p class="font-semibold text-slate-900 dark:text-slate-100"><%= userName %></p>
        <% if (userRole != null && !userRole.isEmpty()) { %>
        <p class="mt-1 text-xs text-slate-500 dark:text-slate-400 uppercase tracking-wide"><%= userRole %></p>
        <% } %>
    </div>
    <div class="p-2">
        <a href="profile.jsp" class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
            <span class="text-sm text-slate-700 dark:text-slate-200">Hồ sơ cá nhân</span>
        </a>
        <a href="UserController?action=logout" class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors">
            <span class="text-sm text-red-600 font-medium">Đăng xuất</span>
        </a>
    </div>
</div>

