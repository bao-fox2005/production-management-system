<%-- 
  Shared Header Component for PMS System
  Include this file at the top of all JSP pages that need the header
  
  Usage:
    String pageTitle = "Dashboard";  // Set before including
    String pageSubtitle = "Welcome";   // Optional
    boolean isAdmin = "admin".equalsIgnoreCase(userRole); // Set before including
    UserDTO user = (UserDTO) session.getAttribute("user");
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    int unreadCount = 0; // Set notification count before including
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
--%>

<!-- Header Cố Định -->
<header class="main-header sticky top-0 z-20 flex h-16 items-center justify-between gap-4 border-b border-slate-200 bg-white/90 px-4 backdrop-blur sm:px-6 lg:px-8">
    <!-- Left: Menu Toggle & Page Title -->
    <div class="flex items-center gap-3">
        <button id="menuToggle" onclick="toggleSidebar()" class="flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-100 transition-colors lg:hidden">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
        </button>
        <div>
            <h1 class="text-lg font-semibold text-slate-900"><%= pageTitle %></h1>
            <% if (pageSubtitle != null && !pageSubtitle.isEmpty()) { %>
            <p class="text-xs text-slate-500"><%= pageSubtitle %></p>
            <% } %>
        </div>
    </div>

    <!-- Center: Search Box -->
    <div class="hidden md:flex flex-1 items-center justify-center px-4 lg:px-8">
        <div class="relative w-full max-w-md">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
                type="text"
                id="globalSearch"
                placeholder="Tìm kiếm..."
                class="w-full rounded-full border border-slate-200 bg-slate-50 py-2 pl-10 pr-4 text-sm text-slate-700 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 transition-all"
                onkeyup="handleGlobalSearch(event)"
            />
        </div>
    </div>

    <!-- Right: Actions -->
    <div class="flex items-center gap-2">
        <!-- Language Toggle - Kích thước đồng đều với các nút khác -->
        <div class="flex items-center border border-slate-200 rounded-lg overflow-hidden h-10">
            <a href="?lang=vi" class="px-3 py-1.5 text-xs font-medium flex items-center <%= "vi".equals(lang) ? "bg-teal-500 text-white" : "bg-white text-slate-600 hover:bg-slate-50" %>">VI</a>
            <a href="?lang=en" class="px-3 py-1.5 text-xs font-medium flex items-center <%= "en".equals(lang) ? "bg-teal-500 text-white" : "bg-white text-slate-600 hover:bg-slate-50" %>">EN</a>
        </div>

        <!-- Dark Mode Toggle -->
        <button onclick="toggleDarkMode()" class="flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-100 transition-colors" title="Chế độ tối">
            <svg id="moonIcon" class="h-5 w-5 <%= isDarkMode ? "hidden" : "" %>" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
            </svg>
            <svg id="sunIcon" class="h-5 w-5 <%= isDarkMode ? "" : "hidden" %>" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
            </svg>
        </button>

        <!-- Notification Bell -->
        <button onclick="toggleNotificationPanel()" id="notifBtn" class="relative flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-100 transition-colors">
            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
            </svg>
            <% if (unreadCount > 0) { %>
            <span class="notif-badge absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] text-white font-medium">
                <%= unreadCount > 9 ? "9+" : unreadCount %>
            </span>
            <% } %>
        </button>

        <!-- User Avatar with Dropdown -->
        <div class="relative">
            <button onclick="toggleUserDropdown()" id="userDropdownBtn" class="flex items-center gap-2 px-3 py-1.5 rounded-xl border border-slate-200 hover:bg-slate-50 transition-colors">
                <div class="h-8 w-8 rounded-full bg-teal-500 text-white flex items-center justify-center text-sm font-bold">
                    <%= userName.substring(0,1).toUpperCase() %>
                </div>
                <span class="hidden sm:block text-sm font-medium text-slate-700"><%= userName %></span>
                <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                </svg>
            </button>

            <!-- User Dropdown -->
            <div id="userDropdown" class="absolute right-0 top-full mt-2 w-56 bg-white rounded-xl shadow-xl border border-slate-200 hidden z-50 overflow-hidden">
                <div class="p-4 border-b border-slate-100 bg-gradient-to-r from-teal-500 to-teal-600">
                    <p class="font-semibold text-white"><%= userName %></p>
                    <p class="text-xs text-teal-100"><%= userRole %></p>
                </div>
                <div class="py-2">
                    <a href="profile.jsp" class="flex items-center gap-3 px-4 py-2.5 hover:bg-slate-50 transition-colors">
                        <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                        </svg>
                        <span class="text-sm font-medium text-slate-700">Hồ Sơ Cá Nhân</span>
                    </a>
                    <a href="UserController?action=logout" class="flex items-center gap-3 px-4 py-2.5 hover:bg-red-50 transition-colors">
                        <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                        </svg>
                        <span class="text-sm font-medium text-red-600">Đăng Xuất</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</header>

<!-- Notification Panel (Hidden by default) -->
<div id="notifPanel" class="absolute right-4 top-16 w-80 bg-white rounded-xl shadow-xl border border-slate-200 hidden z-50 overflow-hidden">
    <div class="p-4 border-b border-slate-100 flex items-center justify-between">
        <h3 class="font-semibold text-slate-900">Thông Báo</h3>
        <% if (unreadCount > 0) { %>
        <a href="NotificationServlet?action=markAllRead" class="text-xs text-teal-600 hover:text-teal-700">Đánh dấu đã đọc</a>
        <% } %>
    </div>
    <div class="max-h-80 overflow-y-auto">
        <div class="p-8 text-center text-slate-400">
            <svg class="w-12 h-12 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/>
            </svg>
            <p>Chưa có thông báo nào</p>
        </div>
    </div>
</div>

<script>
// Global Search Handler
function handleGlobalSearch(event) {
    if (event.key === 'Enter') {
        const query = event.target.value.trim();
        if (query) {
            window.location.href = 'AutoCompleteSearch?action=search&q=' + encodeURIComponent(query);
        }
    }
}
</script>
