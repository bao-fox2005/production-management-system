<!-- Mobile Bottom Navigation Bar -->
<!-- This should be included at the bottom of all main pages -->
<style>
    .mobile-nav-item {
        transition: all 0.2s ease;
    }
    .mobile-nav-item.active {
        color: #14b8a6;
    }
    .mobile-nav-item.active svg {
        stroke: #14b8a6;
    }
    .mobile-nav-item.active span {
        color: #14b8a6;
    }
    .mobile-nav-item:active {
        transform: scale(0.95);
    }
</style>

<!-- Bottom Navigation - Only visible on mobile -->
<nav id="mobileBottomNav" class="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 shadow-lg lg:hidden z-50 hidden">
    <div class="flex items-center justify-around py-2 px-2">
        <!-- Dashboard -->
        <a href="DashboardController" 
           class="mobile-nav-item flex flex-col items-center py-1 px-3 min-w-[60px]"
           data-page="dashboard">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span class="text-[10px] mt-1 font-medium text-slate-600">Dashboard</span>
        </a>
        
        <!-- Work Orders -->
        <a href="WorkOrderController" 
           class="mobile-nav-item flex flex-col items-center py-1 px-3 min-w-[60px]"
           data-page="workorder">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
            </svg>
            <span class="text-[10px] mt-1 font-medium text-slate-600">Lenh SX</span>
        </a>
        
        <!-- Kanban -->
        <a href="KanbanController"
           class="mobile-nav-item flex flex-col items-center py-1 px-3 min-w-[60px]"
           data-page="kanban">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"/>
            </svg>
            <span class="text-[10px] mt-1 font-medium text-slate-600">Kanban</span>
        </a>
        
        <!-- Production Log -->
        <a href="ProductionLogController" 
           class="mobile-nav-item flex flex-col items-center py-1 px-3 min-w-[60px]"
           data-page="productionlog">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span class="text-[10px] mt-1 font-medium text-slate-600">Log SX</span>
        </a>
        
        <!-- More Menu -->
        <button onclick="toggleMobileMenu()" 
                class="mobile-nav-item flex flex-col items-center py-1 px-3 min-w-[60px]">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
            </svg>
            <span class="text-[10px] mt-1 font-medium text-slate-600">Khac</span>
        </button>
    </div>
</nav>

<!-- Mobile Menu Overlay -->
<div id="mobileMenuOverlay" class="fixed inset-0 bg-black/50 z-[60] hidden lg:hidden" onclick="toggleMobileMenu()"></div>

<!-- Mobile Menu Panel -->
<div id="mobileMenuPanel" class="fixed bottom-16 right-4 bg-white rounded-2xl shadow-xl z-[70] hidden lg:hidden overflow-hidden" style="width: 280px;">
    <div class="p-4 border-b border-slate-100 bg-gradient-to-r from-teal-500 to-teal-600">
        <h3 class="text-white font-semibold">Menu</h3>
    </div>
    <div class="py-2 max-h-[60vh] overflow-y-auto">
        <!-- Quick Links -->
        <a href="ItemController?action=list" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Quan ly Vat Tu</span>
        </a>
        
        <a href="CustomerController?action=listCustomer" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Khach Hang</span>
        </a>
        
        <a href="SupplierController?action=listSupplier" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Nha Cung Cap</span>
        </a>
        
        <a href="qc-list.jsp" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Kiem Chat Luong</span>
        </a>
        
        <a href="MainController?action=listBill" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Quan Ly Hoa Don</span>
        </a>
        
        <a href="SearchPurchaseOrder.jsp" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Don Dat Hang</span>
        </a>
        
        <div class="border-t border-slate-100 my-2"></div>
        
        <a href="profile.jsp" class="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
            <svg class="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>
            <span class="text-sm font-medium text-slate-700">Ho So Ca Nhan</span>
        </a>
        
        <a href="UserController?action=logout" class="flex items-center gap-3 px-4 py-3 hover:bg-red-50 transition-colors">
            <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
            </svg>
            <span class="text-sm font-medium text-red-600">Dang Xuat</span>
        </a>
    </div>
</div>

<script>
    // Show/hide bottom nav based on screen size
    function checkMobileView() {
        const bottomNav = document.getElementById('mobileBottomNav');
        if (window.innerWidth < 1024) {
            bottomNav.classList.remove('hidden');
        } else {
            bottomNav.classList.add('hidden');
        }
    }
    
    // Toggle mobile menu
    function toggleMobileMenu() {
        const overlay = document.getElementById('mobileMenuOverlay');
        const panel = document.getElementById('mobileMenuPanel');
        
        overlay.classList.toggle('hidden');
        panel.classList.toggle('hidden');
    }
    
    // Initialize
    window.addEventListener('resize', checkMobileView);
    window.addEventListener('load', checkMobileView);
    
    // Highlight active nav item
    document.addEventListener('DOMContentLoaded', function() {
        const currentPath = window.location.pathname;
        const navItems = document.querySelectorAll('.mobile-nav-item');
        
        navItems.forEach(item => {
            const itemPath = item.getAttribute('data-page');
            if (itemPath && currentPath.includes(itemPath.toLowerCase())) {
                item.classList.add('active');
            }
        });
    });
</script>
