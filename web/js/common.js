// PMS Common JavaScript Utilities
// ===============================

// ============ Mobile Bottom Navigation ============
function initMobileNavigation() {
    const currentPath = window.location.pathname;
    const navItems = document.querySelectorAll('.mobile-nav-item');
    
    navItems.forEach(item => {
        const itemPath = item.getAttribute('data-page');
        if (currentPath.includes(itemPath)) {
            item.classList.add('active');
        }
    });
}

// ============ Sidebar Mobile Toggle ============
let sidebarOpen = window.innerWidth >= 1024; // Desktop: mặc định mở

function applySidebarState() {
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebarOverlay');
    const mainWrapper = document.getElementById('mainWrapper');
    const isDesktop = window.innerWidth >= 1024;

    if (!sidebar) return;

    if (sidebarOpen) {
        sidebar.classList.remove('-translate-x-full');
        sidebar.classList.add('translate-x-0');

        if (overlay) {
            overlay.classList.add('hidden');
        }

        if (mainWrapper) {
            mainWrapper.classList.add('sidebar-open');
            mainWrapper.classList.remove('sidebar-closed');
            mainWrapper.style.marginLeft = isDesktop ? '280px' : '0';
        }
    } else {
        sidebar.classList.add('-translate-x-full');
        sidebar.classList.remove('translate-x-0');

        if (overlay) {
            overlay.classList.toggle('hidden', isDesktop);
        }

        if (mainWrapper) {
            mainWrapper.classList.remove('sidebar-open');
            mainWrapper.classList.add('sidebar-closed');
            mainWrapper.style.marginLeft = '0';
        }
    }
}

function toggleSidebar() {
    sidebarOpen = !sidebarOpen;
    applySidebarState();

    // Lưu trạng thái
    localStorage.setItem('sidebar_open', sidebarOpen ? '1' : '0');
}

// Close sidebar when clicking overlay
document.addEventListener('DOMContentLoaded', function() {
    const overlay = document.getElementById('sidebarOverlay');
    if (overlay) {
        overlay.addEventListener('click', toggleSidebar);
    }

    const savedState = localStorage.getItem('sidebar_open');
    if (savedState !== null) {
        sidebarOpen = savedState === '1';
    }

    applySidebarState();

    window.addEventListener('resize', function() {
        applySidebarState();
    });
});

// ============ Notifications ============
function toggleNotificationPanel() {
    const panel = document.getElementById('notifPanel');
    const userDropdown = document.getElementById('userDropdown');
    
    if (userDropdown) userDropdown.classList.add('hidden');
    if (panel) panel.classList.toggle('hidden');
}

async function postNotificationAction(params) {
    const response = await fetch('NotificationServlet', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
        },
        body: new URLSearchParams(params).toString()
    });
    return response.json();
}

function updateNotificationBadge(count) {
    const badge = document.getElementById('notifBadge');
    if (!badge) return;

    const unread = Number(count) || 0;
    if (unread > 0) {
        badge.textContent = unread > 9 ? '9+' : String(unread);
        badge.classList.remove('hidden');
        badge.classList.add('flex');
    } else {
        badge.textContent = '0';
        badge.classList.add('hidden');
        badge.classList.remove('flex');
    }
}

function ensureNotificationEmptyState() {
    const list = document.getElementById('notifList');
    if (!list) return;

    const hasNotification = list.querySelector('a[data-notification-item]');
    let emptyState = document.getElementById('notifEmptyState');

    if (hasNotification) {
        if (emptyState) emptyState.remove();
        return;
    }

    if (!emptyState) {
        emptyState = document.createElement('div');
        emptyState.id = 'notifEmptyState';
        emptyState.className = 'p-8 text-center text-slate-400 dark:text-slate-500';
        emptyState.innerHTML = `
            <svg class="w-12 h-12 mx-auto mb-2 opacity-50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
            </svg>
            <p>Chưa có thông báo nào</p>
        `;
        list.appendChild(emptyState);
    }
}

async function markNotificationRead(notificationId) {
    if (!notificationId) return true;
    try {
        const item = document.querySelector(`[data-notification-id="${notificationId}"]`);
        const wasUnread = item ? !item.classList.contains('opacity-60') : false;

        await postNotificationAction({ action: 'markRead', id: notificationId });

        if (item) {
            item.classList.add('opacity-60');
            const title = item.querySelector('[data-notification-title]');
            if (title) {
                title.classList.remove('text-teal-600', 'dark:text-teal-400');
            }
        }

        if (wasUnread) {
            const currentCount = Number((document.getElementById('notifBadge') || {}).textContent) || 0;
            updateNotificationBadge(Math.max(0, currentCount - 1));
        }
    } catch (error) {
        console.error('Mark notification read failed:', error);
    }
    return true;
}

async function handleNotificationClick(event, notificationId, link) {
    if (event) {
        event.preventDefault();
    }

    await markNotificationRead(notificationId);

    if (link) {
        window.location.href = link;
    }

    return false;
}

async function markAllNotificationsRead() {
    try {
        await postNotificationAction({ action: 'markAllRead' });
        document.querySelectorAll('[data-notification-item]').forEach(item => {
            item.classList.add('opacity-60');
        });
        document.querySelectorAll('[data-notification-title]').forEach(title => {
            title.classList.remove('text-teal-600', 'dark:text-teal-400');
        });
        updateNotificationBadge(0);
    } catch (error) {
        console.error('Mark all notifications read failed:', error);
    }
}

// Close notification panel when clicking outside
document.addEventListener('click', function(e) {
    const btn = document.getElementById('notifBtn');
    const panel = document.getElementById('notifPanel');
    
    if (panel && !panel.contains(e.target) && btn && !btn.contains(e.target)) {
        panel.classList.add('hidden');
    }
});

// ============ Dark Mode ============
function toggleDarkMode() {
    const html = document.documentElement;
    const isDark = !html.classList.contains('dark');

    applyDarkModeState(isDark);

    localStorage.setItem('pms_dark_mode', isDark ? '1' : '0');

    fetch('UserController?action=toggleDarkMode&dark=' + (isDark ? '1' : '0'), {
        method: 'POST'
    }).catch(() => {});
}

function applyDarkModeState(isDark) {
    const html = document.documentElement;
    const body = document.body;
    const moonIcon = document.getElementById('moonIcon');
    const sunIcon = document.getElementById('sunIcon');

    html.classList.toggle('dark', isDark);

    if (body) {
        body.classList.toggle('dark-mode-init', isDark);
        body.classList.remove('dark');
    }

    if (moonIcon) moonIcon.classList.toggle('hidden', isDark);
    if (sunIcon) sunIcon.classList.toggle('hidden', !isDark);
}

// Giữ lại để tương thích nếu trang cũ còn gọi hàm này trực tiếp
function updateDarkModeColors(isDark) {
    applyDarkModeState(isDark);
}

// Initialize dark mode from saved preference hoặc trạng thái server render
window.addEventListener('DOMContentLoaded', function() {
    const html = document.documentElement;
    const body = document.body;
    const savedDark = localStorage.getItem('pms_dark_mode');
    const serverDark = html.classList.contains('dark') || (body && body.classList.contains('dark-mode-init'));
    const isDark = savedDark === null ? serverDark : savedDark === '1';

    applyDarkModeState(isDark);
    localStorage.setItem('pms_dark_mode', isDark ? '1' : '0');
});

// ============ User Dropdown ============
function toggleUserDropdown() {
    const dropdown = document.getElementById('userDropdown');
    const notifPanel = document.getElementById('notifPanel');
    
    if (notifPanel) notifPanel.classList.add('hidden');
    if (dropdown) dropdown.classList.toggle('hidden');
}

// Close dropdown when clicking outside
document.addEventListener('click', function(e) {
    const btn = document.getElementById('userDropdownBtn');
    const dropdown = document.getElementById('userDropdown');
    
    if (dropdown && !dropdown.contains(e.target) && btn && !btn.contains(e.target)) {
        dropdown.classList.add('hidden');
    }
});

// ============ Generic Modal Functions ============
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }
}

// Close modal with Escape key
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        const modals = document.querySelectorAll('[id^="modal"]');
        modals.forEach(modal => {
            if (!modal.classList.contains('hidden')) {
                modal.classList.add('hidden');
                modal.classList.remove('flex');
            }
        });
    }
});

// ============ Form Validation Helpers ============
function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return false;
    
    const inputs = form.querySelectorAll('[required]');
    let isValid = true;
    
    inputs.forEach(input => {
        if (!input.value.trim()) {
            input.classList.add('border-red-500');
            isValid = false;
        } else {
            input.classList.remove('border-red-500');
        }
    });
    
    return isValid;
}

// ============ Toast Notifications ============
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `fixed bottom-20 left-1/2 transform -translate-x-1/2 px-6 py-3 rounded-xl shadow-lg z-50 animate-fade-in-up ${
        type === 'success' ? 'bg-emerald-500 text-white' : 
        type === 'error' ? 'bg-red-500 text-white' : 
        'bg-slate-700 text-white'
    }`;
    toast.textContent = message;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('animate-fade-out');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// ============ Confirm Delete ============
function confirmDelete(message) {
    return confirm(message || 'Bạn có chắc chắn muốn xóa?');
}

// ============ AJAX Helper ============
async function fetchData(url, options = {}) {
    try {
        const response = await fetch(url, {
            ...options,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                ...options.headers
            }
        });
        
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        
        return await response.text();
    } catch (error) {
        console.error('Fetch error:', error);
        throw error;
    }
}

// ============ Format Number ============
function formatNumber(num) {
    if (num === null || num === undefined) return '0';
    return new Intl.NumberFormat('vi-VN').format(num);
}

// ============ Format Currency ============
function formatCurrency(amount) {
    if (amount === null || amount === undefined) return '0 VND';
    return new Intl.NumberFormat('vi-VN', {
        style: 'currency',
        currency: 'VND',
        minimumFractionDigits: 0
    }).format(amount);
}

// ============ Debounce Function ============
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ============ Search with Debounce ============
function setupDebouncedSearch(inputId, searchUrl, callback) {
    const input = document.getElementById(inputId);
    if (!input) return;
    
    const debouncedSearch = debounce((value) => {
        fetch(`${searchUrl}?keyword=${encodeURIComponent(value)}`)
            .then(response => response.text())
            .then(callback)
            .catch(error => console.error('Search error:', error));
    }, 300);
    
    input.addEventListener('input', (e) => debouncedSearch(e.target.value));
}

// ============ Print Function ============
function printPage() {
    window.print();
}

// ============ Export to PDF ============
function exportToPDF() {
    showToast('Đang xử lý...', 'info');
}

// ============ Table Sort ============
function sortTable(tableId, columnIndex) {
    const table = document.getElementById(tableId);
    if (!table) return;
    
    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));
    
    rows.sort((a, b) => {
        const aText = a.cells[columnIndex].textContent.trim();
        const bText = b.cells[columnIndex].textContent.trim();
        
        // Try numeric comparison first
        const aNum = parseFloat(aText);
        const bNum = parseFloat(bText);
        
        if (!isNaN(aNum) && !isNaN(bNum)) {
            return aNum - bNum;
        }
        
        return aText.localeCompare(bText);
    });
    
    rows.forEach(row => tbody.appendChild(row));
}

// ============ Initialize on Page Load ============
document.addEventListener('DOMContentLoaded', function() {
    initMobileNavigation();
    ensureNotificationEmptyState();
});

