<%--
  ===== item-list.jsp – Quản lý Vật Tư / Sản Phẩm =====
  Mục đích    : Danh sách toàn bộ vật tư/sản phẩm trong kho, CRUD qua modal inline.
                Hàng đỏ + badge "Tồn kho thấp" khi item.isLowStock() = true.
  Request attributes nhận từ ItemController:
    - "items"        (ArrayList<ItemDTO>) : Danh sách vật tư/sản phẩm (đã lọc)
    - "msg"          (String)             : Flash thông báo thành công
    - "error"        (String)             : Thông báo lỗi
    - "lowStockOnly" (Boolean)            : true → đang xem chỉ vật tư tồn kho thấp
  Request params (GET – bộ lọc):
    - keyword : Tìm kiếm theo mã hoặc tên
    - type    : Lọc loại (SanPham / VatTu)
  JSP helpers (<%! ... %>):
    - getStockStatusClass(item) : CSS badge xanh (đủ) / đỏ (tồn kho thấp)
    - getStockStatusText(item)  : Text "Bình thường" / "Tồn kho thấp"
  KPI stats: totalItems, productCount, materialCount, lowStockCount
  Modal Add    : POST → ItemController?action=saveAddItem
  Modal Edit   : openEditItemModalFromButton(btn) → POST → ItemController?action=saveUpdateItem
  Modal Delete : href=ItemController?action=deleteItem&id=... (GET redirect xóa)
  Phân quyền  : Tất cả người dùng đăng nhập.
--%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="java.util.ArrayList"%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    String getStockStatusClass(ItemDTO currentItem) {
        if (currentItem != null && currentItem.isLowStock()) {
            return "bg-red-100 text-red-700 dark:bg-red-500/10 dark:text-red-300";
        }
        return "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-300";
    }

    String getStockStatusText(ItemDTO currentItem) {
        if (currentItem != null && currentItem.isLowStock()) {
            return "Tồn kho thấp";
        }
        return "Bình thường";
    }
%>
<%
    ArrayList<ItemDTO> items = (ArrayList<ItemDTO>) request.getAttribute("items");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");
    if (msg == null || msg.trim().isEmpty()) {
        msg = request.getParameter("msg");
    }
    String error = (String) request.getAttribute("error");
    if (error == null || error.trim().isEmpty()) {
        error = request.getParameter("error");
    }
    String keyword = request.getParameter("keyword");
    String typeFilter = request.getParameter("type");
    Boolean lowStockOnly = (Boolean) request.getAttribute("lowStockOnly");

    if (items == null) items = new ArrayList<>();

    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;

    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    String activePage = "item";
    String pageTitle = "Quản lý vật tư / sản phẩm";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);

    int totalItems = items.size();
    int productCount = 0, materialCount = 0, lowStockCount = 0;
    for (ItemDTO item : items) {
        if ("SanPham".equals(item.getItemType())) productCount++;
        else if ("VatTu".equals(item.getItemType())) materialCount++;
        if (item.isLowStock()) lowStockCount++;
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý vật tư - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.48); z-index: 20; }
        .form-input {
            background: #ffffff;
            border-color: #e2e8f0;
            color: #0f172a;
            transition: all 0.2s ease;
        }
        .form-input:focus {
            border-color: #0d9488;
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1);
        }
        .dark .form-input {
            background: #0f172a;
            border-color: #334155;
            color: #e2e8f0;
        }
        .dark .form-input::placeholder {
            color: #64748b;
        }
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
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
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
            .main-wrapper { margin-left: 280px; }
        }
        .kpi-card { transition: all 0.2s ease; }
        .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08); }
        .dark .kpi-card:hover { box-shadow: 0 20px 45px rgba(2, 6, 23, 0.45); }
        .section-card {
            background: rgba(255,255,255,0.95);
            backdrop-filter: blur(12px);
        }
        .dark .section-card {
            background: rgba(15,23,42,0.92);
        }
        .modal-backdrop {
            background: rgba(15, 23, 42, 0.72);
            backdrop-filter: blur(6px);
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <!-- Main Content -->
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-teal-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-teal-950/30">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-teal-200 bg-teal-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-teal-700 dark:border-teal-500/30 dark:bg-teal-500/10 dark:text-teal-300">
                                Danh mục kho
                            </div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý vật tư / sản phẩm</h1>
                            <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-400">Theo dõi danh mục vật tư, sản phẩm và cảnh báo tồn kho ngay trên một màn hình. Bạn có thể thêm nhanh vật tư mới mà không cần rời khỏi trang danh sách.</p>
                        </div>
                        <div class="flex flex-wrap gap-3">
                            <button type="button" onclick="openAddItemModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:-translate-y-0.5 hover:bg-teal-700">
                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                </svg>
                                Thêm vật tư
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Alerts -->
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

                <!-- Stats Cards -->
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
                    <div class="kpi-card rounded-2xl border border-blue-200 border-t-4 border-t-blue-500 bg-white p-5 shadow-sm dark:border-blue-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tổng vật tư</p>
                                <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalItems %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-500/10 text-blue-600 dark:text-blue-300 text-2xl">&#128230;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-violet-200 border-t-4 border-t-violet-500 bg-white p-5 shadow-sm dark:border-violet-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Sản phẩm</p>
                                <p class="mt-2 text-3xl font-bold text-violet-600 dark:text-violet-300"><%= productCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-violet-50 text-2xl text-violet-600 dark:bg-violet-500/10 dark:text-violet-300">&#128722;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-teal-200 border-t-4 border-t-teal-500 bg-white p-5 shadow-sm dark:border-teal-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Vật tư</p>
                                <p class="mt-2 text-3xl font-bold text-teal-600 dark:text-teal-300"><%= materialCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 dark:bg-teal-500/10 text-teal-600 dark:text-teal-300 text-2xl">&#9881;</div>
                        </div>
                    </div>
                    <div class="kpi-card rounded-2xl border border-red-200 border-t-4 border-t-red-500 bg-white p-5 shadow-sm dark:border-red-500/30 dark:bg-slate-800">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tồn kho thấp</p>
                                <p class="mt-2 text-3xl font-bold text-red-600 dark:text-red-300"><%= lowStockCount %></p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-300 text-2xl">&#9888;</div>
                        </div>
                    </div>
                </div>

                <!-- Search & Filter -->
                <div class="section-card mb-6 rounded-3xl border border-slate-200 p-4 shadow-sm dark:border-slate-700">
                    <div class="mb-4 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                            <h2 class="text-base font-semibold text-slate-900 dark:text-slate-100">Bộ lọc danh sách</h2>
                            <p class="text-sm text-slate-500 dark:text-slate-400">Tìm nhanh theo tên vật tư và loại sản phẩm trong kho.</p>
                        </div>
                        <% if (Boolean.TRUE.equals(lowStockOnly)) { %>
                        <span class="inline-flex items-center rounded-full bg-red-100 px-3 py-1 text-xs font-semibold text-red-700 dark:bg-red-500/10 dark:text-red-300">Đang xem danh sách tồn kho thấp</span>
                        <% } %>
                    </div>
                    <form method="get" action="ItemController" class="flex flex-col gap-4 xl:flex-row">
                        <input type="hidden" name="action" value="search">
                        <div class="flex-1 relative">
                            <input type="text" name="keyword" value="<%= keyword != null ? keyword : "" %>"
                                   placeholder="Tìm kiếm theo mã hoặc tên..."
                                   class="w-full pl-10 pr-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                            <svg class="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                            </svg>
                        </div>
                        <select name="type" class="px-4 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 form-input transition-all">
                            <option value="">Tất cả loại</option>
                            <option value="SanPham" <%= "SanPham".equals(typeFilter) ? "selected" : "" %>>Sản phẩm</option>
                            <option value="VatTu" <%= "VatTu".equals(typeFilter) ? "selected" : "" %>>Vật tư</option>
                        </select>
                        <button type="submit" class="px-6 py-3 rounded-2xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all shadow-sm shadow-teal-500/30">
                            Tìm kiếm
                        </button>
                        <a href="ItemController?action=list" class="px-6 py-3 rounded-2xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-semibold hover:bg-slate-50 dark:hover:bg-slate-800 transition-all">
                            Đặt lại
                        </a>
                    </form>
                </div>

                <!-- Items Table -->
                <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Mã VT</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tên vật tư</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Loại</th>
                                    <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tồn kho</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (items.isEmpty()) { %>
                                <tr>
                                    <td colspan="5" class="px-4 py-14 text-center text-slate-400 dark:text-slate-500">
                                        <div class="mx-auto flex max-w-md flex-col items-center gap-3">
                                            <div class="flex h-16 w-16 items-center justify-center rounded-3xl bg-slate-100 text-slate-400 dark:bg-slate-800 dark:text-slate-500">
                                                <svg class="h-8 w-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"/>
                                                </svg>
                                            </div>
                                            <div>
                                                <p class="text-base font-semibold text-slate-700 dark:text-slate-200">Chưa có vật tư nào</p>
                                                <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Bắt đầu bằng cách thêm vật tư hoặc sản phẩm mới trực tiếp trên trang này.</p>
                                            </div>
                                            <button type="button" onclick="openAddItemModal()" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                                                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                                                </svg>
                                                Thêm vật tư đầu tiên
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (ItemDTO item : items) { %>
                                    <tr class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors <%= item.isLowStock() ? "bg-red-50/50 dark:bg-red-500/5" : "" %>">
                                        <td class="px-4 py-3">
                                            <span class="font-bold text-slate-700 dark:text-slate-200">#<%= item.getItemID() %></span>
                                        </td>
                                        <td class="px-4 py-3">
                                            <div class="flex items-center gap-3">
                                                <div class="w-10 h-10 rounded-2xl bg-slate-100 dark:bg-slate-700 flex items-center justify-center text-slate-600 dark:text-slate-200 font-bold text-sm">
                                                    <%= item.getItemName() != null ? item.getItemName().substring(0, 1).toUpperCase() : "?" %>
                                                </div>
                                                <span class="font-medium text-slate-700 dark:text-slate-200"><%= item.getItemName() != null ? item.getItemName() : "-" %></span>
                                            </div>
                                        </td>
                                        <td class="px-4 py-3 text-center">
                                            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold <%= "SanPham".equals(item.getItemType()) ? "bg-violet-100 text-violet-700 dark:bg-violet-500/10 dark:text-violet-300" : "bg-teal-100 text-teal-700 dark:bg-teal-500/10 dark:text-teal-300" %>">
                                                <%= "SanPham".equals(item.getItemType()) ? "Sản phẩm" : "Vật tư" %>
                                            </span>
                                        </td>
                                        <td class="px-4 py-3 text-right">
                                            <span class="font-bold <%= item.isLowStock() ? "text-red-600 dark:text-red-300" : "text-slate-700 dark:text-slate-200" %>"><%= item.getStockQuantity() %></span>
                                        </td>
                                        <td class="px-4 py-3 text-center">
                                            <div class="flex items-center justify-center gap-2">
                                                <button type="button"
                                                        class="p-2 rounded-xl text-slate-500 dark:text-slate-400 hover:bg-amber-100 dark:hover:bg-amber-500/10 hover:text-amber-600 dark:hover:text-amber-300 transition-colors"
                                                        title="Chỉnh sửa"
                                                        data-item-id="<%= item.getItemID() %>"
                                                        data-item-name="<%= item.getItemName() != null ? item.getItemName() : "" %>"
                                                        data-item-type="<%= item.getItemType() != null ? item.getItemType() : "" %>"
                                                        data-stock-quantity="<%= item.getStockQuantity() %>"
                                                        data-description="<%= item.getDescription() != null ? item.getDescription() : "" %>"
                                                        data-unit="<%= item.getUnit() != null ? item.getUnit() : "" %>"
                                                        data-min-stock="<%= item.getMinStockLevel() %>"
                                                        onclick="openEditItemModalFromButton(this)">
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                                    </svg>
                                                </button>
                                                <button type="button"
                                                        data-item-id="<%= item.getItemID() %>"
                                                        data-item-name="<%= item.getItemName() != null ? item.getItemName() : "Vật tư / sản phẩm #" + item.getItemID() %>"
                                                        onclick="openDeleteItemModal(this)"
                                                        class="p-2 rounded-xl text-slate-500 dark:text-slate-400 hover:bg-red-100 dark:hover:bg-red-500/10 hover:text-red-600 dark:hover:text-red-300 transition-colors" title="Xóa">
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                                    </svg>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% if (!items.isEmpty()) { %>
                    <div class="px-4 py-3 border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/80 text-sm text-slate-500 dark:text-slate-400">
                        Tổng cộng: <span class="font-semibold"><%= items.size() %></span> vật tư
                    </div>
                    <% } %>
                </div>
            </main>
        </div>
    </div>

    <div id="addItemModal" class="modal-backdrop fixed inset-0 z-50 hidden items-center justify-center p-4">
        <div class="w-full max-w-3xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-teal-600 dark:text-teal-300">Thao tác nhanh</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Thêm vật tư mới</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo vật tư hoặc sản phẩm mới trực tiếp từ danh sách kho.</p>
                </div>
                <button type="button" onclick="closeAddItemModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="ItemController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="saveAddItem">
                <div class="grid gap-5 md:grid-cols-2">
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Tên vật tư <span class="text-red-500">*</span></label>
                        <input type="text" name="itemName" required class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Nhập tên vật tư hoặc sản phẩm">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Loại <span class="text-red-500">*</span></label>
                        <select name="itemType" required class="form-input w-full rounded-2xl border px-4 py-3">
                            <option value="">Chọn loại</option>
                            <option value="SanPham">Sản phẩm</option>
                            <option value="VatTu">Vật tư</option>
                        </select>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Số lượng tồn kho</label>
                        <input type="number" name="stockQuantity" min="0" value="0" class="form-input w-full rounded-2xl border px-4 py-3">
                    </div>
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Mô tả</label>
                        <textarea name="description" rows="4" class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Mô tả ngắn về vật tư hoặc sản phẩm"></textarea>
                    </div>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end dark:border-slate-700">
                    <button type="button" onclick="closeAddItemModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                    <button type="submit" class="rounded-2xl bg-teal-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition hover:bg-teal-700">Lưu vật tư</button>
                </div>
            </form>
        </div>
    </div>

    <div id="editItemModal" class="modal-backdrop fixed inset-0 z-50 hidden items-center justify-center p-4" data-auto-open="false">
        <div class="w-full max-w-3xl overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start justify-between border-b border-slate-200 px-6 py-5 dark:border-slate-700">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-amber-600 dark:text-amber-300">Cập nhật</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Sửa vật tư / sản phẩm</h3>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"></p>
                </div>
                <button type="button" onclick="closeEditItemModal()" class="rounded-2xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-800 dark:hover:text-slate-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <form action="ItemController" method="post" class="space-y-5 px-6 py-6">
                <input type="hidden" name="action" value="saveUpdateItem">
                <input type="hidden" id="edit_item_id" name="id" value="">
                <div class="grid gap-5 md:grid-cols-2">
                    <div class="md:col-span-2">
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Tên vật tư <span class="text-red-500">*</span></label>
                        <input id="edit_item_name" type="text" name="itemName" required class="form-input w-full rounded-2xl border px-4 py-3" placeholder="Nhập tên vật tư hoặc sản phẩm">
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Loại <span class="text-red-500">*</span></label>
                        <select id="edit_item_type" name="itemType" required class="form-input w-full rounded-2xl border px-4 py-3">
                            <option value="">Chọn loại</option>
                            <option value="SanPham">Sản phẩm</option>
                            <option value="VatTu">Vật tư</option>
                        </select>
                    </div>
                    <div>
                        <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">Số lượng tồn kho</label>
                        <input id="edit_stock_quantity" type="number" name="stockQuantity" min="0" value="0" class="form-input w-full rounded-2xl border px-4 py-3">
                    </div>
                    <div class="md:col-span-2 hidden">
                        <input id="edit_unit" type="text" name="unit" value="">
                        <input id="edit_min_stock" type="number" name="minStockLevel" min="0" value="0">
                    </div>
                    <div class="md:col-span-2 hidden">
                        <textarea id="edit_description" name="description" rows="4"></textarea>
                    </div>
                </div>
                <div class="flex flex-col-reverse gap-3 border-t border-slate-200 pt-5 sm:flex-row sm:justify-end dark:border-slate-700">
                    <button type="button" onclick="closeEditItemModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                    <button type="submit" class="rounded-2xl bg-amber-600 px-5 py-3 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition hover:bg-amber-700">Lưu cập nhật</button>
                </div>
            </form>
        </div>
    </div>

    <div id="deleteItemModal" class="modal-backdrop fixed inset-0 z-[60] hidden items-center justify-center p-4">
        <div class="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
            <div class="flex items-start gap-4">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-100 text-rose-600 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M5.07 19h13.86c1.54 0 2.5-1.67 1.73-3L13.73 4c-.77-1.33-2.69-1.33-3.46 0L3.34 16c-.77 1.33.19 3 1.73 3z"/>
                    </svg>
                </div>
                <div class="flex-1">
                    <p class="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 dark:text-rose-300">Xác nhận xóa</p>
                    <h3 class="mt-2 text-xl font-semibold text-slate-900 dark:text-slate-100">Xóa vật tư / sản phẩm?</h3>
                    <p class="mt-2 text-sm leading-6 text-slate-500 dark:text-slate-400">
                        Bạn sắp xóa <span id="deleteItemName" class="font-semibold text-slate-700 dark:text-slate-200"></span>. Thao tác này không thể hoàn tác.
                    </p>
                </div>
            </div>
            <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
                <button type="button" onclick="closeDeleteItemModal()" class="rounded-2xl border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">Hủy</button>
                <a id="confirmDeleteItemBtn" href="#" class="rounded-2xl bg-rose-600 px-5 py-3 text-center text-sm font-semibold text-white shadow-sm shadow-rose-500/30 transition hover:bg-rose-700">Xóa</a>
            </div>
        </div>
    </div>

    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>
    <script src="js/common.js"></script>
    <script>
        const addItemModal = document.getElementById('addItemModal');
        const editItemModal = document.getElementById('editItemModal');
        const deleteItemModal = document.getElementById('deleteItemModal');
        const deleteItemName = document.getElementById('deleteItemName');
        const confirmDeleteItemBtn = document.getElementById('confirmDeleteItemBtn');

        function openAddItemModal() {
            if (!addItemModal) return;
            addItemModal.classList.remove('hidden');
            addItemModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeAddItemModal() {
            if (!addItemModal) return;
            addItemModal.classList.add('hidden');
            addItemModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
        }

        function openEditItemModal(itemId, itemName, itemType, stockQuantity, description, unit, minStockLevel) {
            if (!editItemModal) return;
            document.getElementById('edit_item_id').value = itemId || '';
            document.getElementById('edit_item_name').value = itemName || '';
            document.getElementById('edit_item_type').value = itemType || '';
            document.getElementById('edit_stock_quantity').value = stockQuantity || 0;
            document.getElementById('edit_description').value = description || '';
            document.getElementById('edit_unit').value = unit || '';
            document.getElementById('edit_min_stock').value = minStockLevel || 0;
            editItemModal.classList.remove('hidden');
            editItemModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function openEditItemModalFromButton(button) {
            if (!button) return;
            openEditItemModal(
                button.getAttribute('data-item-id'),
                button.getAttribute('data-item-name'),
                button.getAttribute('data-item-type'),
                button.getAttribute('data-stock-quantity'),
                button.getAttribute('data-description'),
                button.getAttribute('data-unit'),
                button.getAttribute('data-min-stock')
            );
        }

        function closeEditItemModal() {
            if (!editItemModal) return;
            editItemModal.classList.add('hidden');
            editItemModal.classList.remove('flex');
            document.body.classList.remove('overflow-hidden');
        }

        function openDeleteItemModal(button) {
            if (!deleteItemModal || !deleteItemName || !confirmDeleteItemBtn || !button) return;
            const itemId = button.getAttribute('data-item-id');
            const itemName = button.getAttribute('data-item-name');
            deleteItemName.textContent = itemName || ('Vật tư / sản phẩm #' + itemId);
            confirmDeleteItemBtn.href = 'ItemController?action=deleteItem&id=' + itemId;
            deleteItemModal.classList.remove('hidden');
            deleteItemModal.classList.add('flex');
            document.body.classList.add('overflow-hidden');
        }

        function closeDeleteItemModal() {
            if (!deleteItemModal) return;
            deleteItemModal.classList.add('hidden');
            deleteItemModal.classList.remove('flex');
            if (!addItemModal || addItemModal.classList.contains('hidden')) {
                if (!editItemModal || editItemModal.classList.contains('hidden')) {
                    document.body.classList.remove('overflow-hidden');
                }
            }
        }

        if (addItemModal) {
            addItemModal.addEventListener('click', function (event) {
                if (event.target === addItemModal) {
                    closeAddItemModal();
                }
            });
        }

        if (editItemModal) {
            editItemModal.addEventListener('click', function (event) {
                if (event.target === editItemModal) {
                    closeEditItemModal();
                }
            });
        }

        if (deleteItemModal) {
            deleteItemModal.addEventListener('click', function (event) {
                if (event.target === deleteItemModal) {
                    closeDeleteItemModal();
                }
            });
        }

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape') {
                closeDeleteItemModal();
                closeAddItemModal();
                closeEditItemModal();
            }
        });
    </script>
</body>
</html>
