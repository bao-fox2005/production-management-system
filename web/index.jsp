<%--
  ===== index.jsp – Trang menu chính (giao diện cũ) =====
  Mục đích    : Hiển thị lưới các module với sidebar tích hợp.
                Đây là giao diện cũ; trang chính hiện tại đã chuyển sang Dashboard.jsp
                được phục vụ bởi DashboardController.
  Session data đọc:
    - session["user"] (UserDTO): thông tin người dùng đang đăng nhập
      → username      : Hiển thị trên header và sidebar
      → userInitial   : Chữ cái đầu username, dùng làm avatar
      → role          : Phân quyền (admin/employee)
  Sidebar      : Tự render inline (không dùng shared-sidebar.jsp).
  JavaScript   : Toggle sidebar trên mobile (menuToggle + overlay).
  Phân quyền  : Bắt buộc đăng nhập (AuthenticationFilter).
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Lấy thông tin user từ session để hiển thị trên avatar và sidebar
    pms.model.UserDTO user = (pms.model.UserDTO) session.getAttribute("user");
    String userName = user != null ? user.getUsername() : "";
    String userRole = user != null ? user.getRole() : "";
    // Chữ đầu của username để hiển thị dạng avatar (vd: "admin" → "A")
    String userInitial = userName.length() > 0 ? userName.substring(0, 1).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>He Thong Quan Ly San Xuat - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
        .module-card { transition: all 0.2s; }
        .module-card:hover { transform: translateY(-4px); box-shadow: 0 12px 24px rgba(0,0,0,0.1); }
    </style>
</head>
<body class="bg-slate-50 min-h-screen">
    <div id="layoutShell" class="h-screen overflow-hidden lg:grid lg:grid-cols-[280px_1fr]">
        <!-- Sidebar -->
        <aside id="sidebar" data-collapsed="false" class="sidebar fixed inset-y-0 left-0 z-30 flex h-screen w-72 -translate-x-full flex-col bg-slate-900 text-white transition-transform duration-300 lg:static lg:translate-x-0">
            <div class="flex h-16 shrink-0 items-center gap-3 border-b border-slate-800 px-6">
                <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-teal-500/10 text-lg text-teal-200 font-bold">&#9881;</div>
                <div class="sidebar-brand-text">
                    <p class="text-sm font-semibold tracking-wide">PMS System</p>
                    <p class="text-xs text-slate-400">Production Management</p>
                </div>
            </div>
            <nav class="flex-1 overflow-y-auto space-y-6 px-4 py-6">
                <section class="space-y-3">
                    <p class="nav-group-label px-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Tong quan</p>
                    <div class="space-y-1">
                        <a href="DashboardController" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-teal-500/20 text-sm">&#128200;</span>
                            <span class="nav-label">Dashboard</span>
                        </a>
                        <a href="BangDieuKien.jsp" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium bg-teal-500/20 text-white shadow-sm">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-teal-500/20 text-sm">&#9881;</span>
                            <span class="nav-label">Man hinh chinh</span>
                        </a>
                    </div>
                </section>
                <section class="space-y-3">
                    <p class="nav-group-label px-2 text-xs font-semibold uppercase tracking-wider text-slate-400">San xuat</p>
                    <div class="space-y-1">
                        <a href="MainController?action=listWorkOrder" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#128203;</span>
                            <span class="nav-label">Lenh San Xuat</span>
                        </a>
                        <a href="MainController?action=listProduction" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#128221;</span>
                            <span class="nav-label">Nhat ky San Xuat</span>
                        </a>
                        <a href="QcController?action=list" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#10004;</span>
                            <span class="nav-label">Kiem Tra Chat Luong</span>
                        </a>
                    </div>
                </section>
                <section class="space-y-3">
                    <p class="nav-group-label px-2 text-xs font-semibold uppercase tracking-wider text-slate-400">Danh muc</p>
                    <div class="space-y-1">
                        <a href="MainController?action=listBOM" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#129513;</span>
                            <span class="nav-label">BOM</span>
                        </a>
                        <a href="MainController?action=listRouting" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#128260;</span>
                            <span class="nav-label">Quy Trinh</span>
                        </a>
                        <a href="MainController?action=listRoutingStep" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#9878;</span>
                            <span class="nav-label">Cong Doan</span>
                        </a>
                        <a href="MainController?action=listDefectReason" class="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-sm font-medium text-slate-200 hover:bg-slate-800">
                            <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-800 text-sm">&#9888;</span>
                            <span class="nav-label">Nguyen Nhan Loi</span>
                        </a>
                    </div>
                </section>
            </nav>
            <div class="shrink-0 border-t border-slate-800 px-6 py-4">
                <div class="flex items-center gap-3">
                    <div class="h-10 w-10 rounded-full bg-teal-500/20 text-center text-sm leading-10 text-teal-200 font-bold"><%= userInitial %></div>
                    <div class="sidebar-user-text">
                        <p class="text-sm font-semibold"><%= userName %></p>
                        <p class="text-xs text-slate-400"><%= userRole %></p>
                    </div>
                </div>
            </div>
        </aside>

        <!-- Main Content -->
        <div class="flex min-h-screen flex-col overflow-hidden">
            <header class="sticky top-0 z-20 flex h-16 items-center justify-between gap-4 border-b border-slate-200 bg-white/90 px-4 backdrop-blur sm:px-6">
                <div class="flex items-center gap-3">
                    <button id="menuToggle" class="flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-100" type="button">&#9776;</button>
                    <h1 class="text-lg font-semibold text-slate-800">Bang Dieu Kien</h1>
                </div>
                <div class="flex items-center gap-3">
                    <a href="UserController?action=viewProfile" class="flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 transition-colors">
                        <div class="w-8 h-8 rounded-full bg-teal-500/20 text-teal-600 flex items-center justify-center text-sm font-bold"><%= userInitial %></div>
                        <span class="text-sm font-medium text-slate-700 hidden sm:block"><%= userName %></span>
                    </a>
                    <a href="MainController?action=logoutUser" class="rounded-xl border border-rose-200 px-4 py-2 text-sm font-semibold text-rose-600 hover:bg-rose-50">Dang Xuat</a>
                </div>
            </header>

            <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
                <div class="mb-8">
                    <h2 class="text-2xl font-bold text-slate-900">Xin chao, <%= userName %>!</h2>
                    <p class="text-slate-500 mt-1">Chon mot chuc nang de bat dau lam viec</p>
                </div>

                <!-- Module Grid -->
                <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                    <!-- BOM -->
                    <a href="MainController?action=listBOM" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-blue-100 flex items-center justify-center text-2xl mb-4">&#129513;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Quan ly BOM</h3>
                        <p class="text-sm text-slate-500 mt-1">Bill of Materials - Don de san pham</p>
                    </a>

                    <!-- Defect Reasons -->
                    <a href="MainController?action=listDefectReason" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-red-100 flex items-center justify-center text-2xl mb-4">&#9888;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Danh Muc Loi</h3>
                        <p class="text-sm text-slate-500 mt-1">Cac loai loi thuong gap</p>
                    </a>

                    <!-- Routing -->
                    <a href="MainController?action=listRouting" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-orange-100 flex items-center justify-center text-2xl mb-4">&#128260;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Quy Trinh</h3>
                        <p class="text-sm text-slate-500 mt-1">Cac quy trinh san xuat</p>
                    </a>

                    <!-- Routing Steps -->
                    <a href="MainController?action=listRoutingStep" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-purple-100 flex items-center justify-center text-2xl mb-4">&#9878;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Cong Doan</h3>
                        <p class="text-sm text-slate-500 mt-1">Chi tiet cac buoc san xuat</p>
                    </a>

                    <!-- Work Orders -->
                    <a href="MainController?action=listWorkOrder" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-teal-100 flex items-center justify-center text-2xl mb-4">&#128203;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Lenh San Xuat</h3>
                        <p class="text-sm text-slate-500 mt-1">Tao va quan ly lenh san xuat</p>
                    </a>

                    <!-- Production Log -->
                    <a href="MainController?action=listProduction" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-yellow-100 flex items-center justify-center text-2xl mb-4">&#128221;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Nhat ky San Xuat</h3>
                        <p class="text-sm text-slate-500 mt-1">Bao cao san luong hang ngay</p>
                    </a>

                    <!-- QC -->
                    <a href="QcController?action=list" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-emerald-100 flex items-center justify-center text-2xl mb-4">&#10004;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Kiem Tra Chat Luong</h3>
                        <p class="text-sm text-slate-500 mt-1">QC inspection records</p>
                    </a>

                    <!-- Kanban -->
                    <a href="KanbanController" class="module-card bg-white rounded-2xl p-6 shadow-sm border border-slate-100 block">
                        <div class="w-14 h-14 rounded-2xl bg-indigo-100 flex items-center justify-center text-2xl mb-4">&#128200;</div>
                        <h3 class="text-lg font-semibold text-slate-900">Kanban Board</h3>
                        <p class="text-sm text-slate-500 mt-1">Quan ly trang thai Lenh SX</p>
                    </a>
                </div>
            </main>
        </div>
    </div>

    <div id="sidebarOverlay" class="sidebar-overlay hidden lg:hidden"></div>

    <script>
        const menuToggle = document.getElementById('menuToggle');
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebarOverlay');

        menuToggle.addEventListener('click', function() {
            if (window.innerWidth >= 1024) {
                const collapsed = sidebar.dataset.collapsed === 'true';
                sidebar.dataset.collapsed = (!collapsed).toString();
            } else {
                sidebar.classList.toggle('-translate-x-full');
                overlay.classList.toggle('hidden');
            }
        });

        overlay.addEventListener('click', function() {
            sidebar.classList.add('-translate-x-full');
            overlay.classList.add('hidden');
        });
    </script>
</body>
</html>
