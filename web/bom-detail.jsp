<%--
  ===== bom-detail.jsp – Trang xem chi tiết một BOM =====
  Mục đích    : Hiển thị toàn bộ thông tin của một BOM: header (mã, phiên bản, trạng thái)
                và bảng danh sách nguyên liệu (BOM_Detail).
  Request attributes nhận từ BomController:
    - "bom"  (BOMDTO) : Đối tượng BOM cần xem; nếu null thì hiển thị trang lỗi "Không tìm thấy"
      → bom.getDetails()     : List<BOMDetailDTO> – danh sách nguyên liệu cấu thành
      → bom.getProductName() : Tên sản phẩm (từ JOIN với bảng Item)
  Session attributes đọc:
    - session["darkMode"] (Boolean) : Bật/tắt dark mode
    - session["lang"]     (String)  : Ngôn ngữ, mặc định "vi"
  Logic trạng thái (status):
    - "active"   → badge xanh  "Đang dùng"
    - "inactive" → badge xám   "Ngưng dùng"
    - khác       → badge vàng  "Chờ duyệt" (mặc định)
  KPI cards    : Hiển thị 4 chỉ số: Mã BOM, Phiên bản, Trạng thái, Số nguyên liệu.
  Nút hành động:
    - Sửa BOM : GET → BOMController?action=editBOM&id=...
    - Xem quy trình sản xuất: GET → MainController?action=listRouting&productItemId=...
  Phân quyền  : Tất cả người dùng đăng nhập.
--%>
<%@page import="pms.model.BOMDTO"%>
<%@page import="pms.model.BOMDetailDTO"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    BOMDTO bom = (BOMDTO) request.getAttribute("bom");
    List<BOMDetailDTO> details = bom != null ? bom.getDetails() : null;

    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "bom";
    String pageTitle = bom != null ? "Chi tiết BOM #" + bom.getBomId() : "Chi tiết BOM";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);

    int totalDetails = details != null ? details.size() : 0;
    String status = bom != null && bom.getStatus() != null ? bom.getStatus() : "pending";
    String statusLabel = "Chờ duyệt";
    String statusBadgeClass = "bg-amber-100 text-amber-700 ring-amber-200 dark:bg-amber-500/10 dark:text-amber-300 dark:ring-amber-400/30";

    if ("active".equalsIgnoreCase(status)) {
        statusLabel = "Đang dùng";
        statusBadgeClass = "bg-emerald-100 text-emerald-700 ring-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-300 dark:ring-emerald-400/30";
    } else if ("inactive".equalsIgnoreCase(status)) {
        statusLabel = "Ngưng dùng";
        statusBadgeClass = "bg-slate-100 text-slate-700 ring-slate-200 dark:bg-slate-500/10 dark:text-slate-300 dark:ring-slate-400/30";
    }
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= pageTitle %> - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class'
        };
    </script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
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

        .dark .sidebar-fixed,
        .dark .sidebar-header,
        .dark .sidebar-footer {
            background: #0f172a;
        }

        .section-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(14px);
        }
        .dark .section-card {
            background: rgba(15, 23, 42, 0.88);
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto bg-slate-100 p-4 dark:bg-slate-900 sm:p-6 lg:p-8">
                <% if (bom == null) { %>
                <div class="section-card rounded-3xl border border-slate-200/70 px-6 py-14 text-center shadow-sm dark:border-slate-700/60">
                    <h1 class="text-xl font-semibold text-slate-900 dark:text-slate-100">Không tìm thấy BOM</h1>
                    <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">Bản ghi bạn đang truy cập không tồn tại hoặc đã bị xóa.</p>
                    <div class="mt-6">
                        <a href="BOMController?action=list" class="rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-teal-700">Quay lại danh sách</a>
                    </div>
                </div>
                <% } else { %>
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-teal-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-teal-950/30">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-teal-200 bg-teal-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-teal-700 dark:border-teal-500/30 dark:bg-teal-500/10 dark:text-teal-300">
                                Chi tiết định mức
                            </div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100">Chi tiết BOM</h1>
                            <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-400">Theo dõi nhanh thông tin định mức, trạng thái áp dụng và danh sách nguyên liệu của sản phẩm trên giao diện đồng bộ.</p>
                        </div>
                        <div class="flex flex-wrap gap-3">
                            <a href="BOMController?action=list" class="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">← Danh sách BOM</a>
                            <a href="MainController?action=listRouting&productItemId=<%= bom.getProductItemId() %>" class="rounded-2xl bg-indigo-600 px-4 py-3 text-sm font-medium text-white shadow-sm shadow-indigo-500/30 transition-colors hover:bg-indigo-700">Xem quy trình sản xuất</a>
                            <a href="BOMController?action=editBOM&id=<%= bom.getBomId() %>" class="rounded-2xl bg-teal-600 px-4 py-3 text-sm font-medium text-white shadow-sm shadow-teal-500/30 transition-colors hover:bg-teal-700">Sửa BOM</a>
                        </div>
                    </div>
                </div>

                <div class="mb-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                    <div class="section-card rounded-3xl border border-slate-200/70 p-5 shadow-sm dark:border-slate-700/60">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Mã BOM</p>
                        <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100">#<%= bom.getBomId() %></p>
                    </div>
                    <div class="section-card rounded-3xl border border-slate-200/70 p-5 shadow-sm dark:border-slate-700/60">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Phiên bản</p>
                        <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= bom.getBomVersion() != null ? bom.getBomVersion() : "v1.0" %></p>
                    </div>
                    <div class="section-card rounded-3xl border border-slate-200/70 p-5 shadow-sm dark:border-slate-700/60">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Trạng thái</p>
                        <div class="mt-3">
                            <span class="inline-flex items-center rounded-full px-3 py-1 text-sm font-semibold ring-1 <%= statusBadgeClass %>"><%= statusLabel %></span>
                        </div>
                    </div>
                    <div class="section-card rounded-3xl border border-slate-200/70 p-5 shadow-sm dark:border-slate-700/60">
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Số nguyên liệu</p>
                        <p class="mt-3 text-3xl font-bold text-slate-900 dark:text-slate-100"><%= totalDetails %></p>
                    </div>
                </div>

                <div class="grid gap-6 xl:grid-cols-[1fr_1.6fr]">
                    <section class="section-card rounded-3xl border border-slate-200/70 p-6 shadow-sm dark:border-slate-700/60">
                        <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Thông tin BOM</h2>
                        <dl class="mt-4 space-y-4 text-sm">
                            <div class="rounded-2xl bg-slate-50 px-4 py-3 dark:bg-slate-800/70">
                                <dt class="text-slate-500 dark:text-slate-400">Sản phẩm áp dụng</dt>
                                <dd class="mt-1 font-semibold text-slate-900 dark:text-slate-100"><%= bom.getProductName() != null ? bom.getProductName() : "ID: " + bom.getProductItemId() %></dd>
                            </div>
                            <div class="rounded-2xl bg-slate-50 px-4 py-3 dark:bg-slate-800/70">
                                <dt class="text-slate-500 dark:text-slate-400">Mã sản phẩm</dt>
                                <dd class="mt-1 font-semibold text-slate-900 dark:text-slate-100"><%= bom.getProductItemId() %></dd>
                            </div>
                            <div class="rounded-2xl bg-slate-50 px-4 py-3 dark:bg-slate-800/70">
                                <dt class="text-slate-500 dark:text-slate-400">Ngày tạo</dt>
                                <dd class="mt-1 font-semibold text-slate-900 dark:text-slate-100"><%= bom.getCreatedDate() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(bom.getCreatedDate()) : "Chưa có" %></dd>
                            </div>
                            <div class="rounded-2xl bg-slate-50 px-4 py-3 dark:bg-slate-800/70">
                                <dt class="text-slate-500 dark:text-slate-400">Ghi chú</dt>
                                <dd class="mt-1 leading-6 text-slate-700 dark:text-slate-300"><%= bom.getNotes() != null && !bom.getNotes().trim().isEmpty() ? bom.getNotes() : "Không có ghi chú." %></dd>
                            </div>
                        </dl>
                    </section>

                    <section class="section-card overflow-hidden rounded-3xl border border-slate-200/70 shadow-sm dark:border-slate-700/60">
                        <div class="border-b border-slate-200/70 px-6 py-5 dark:border-slate-700/60">
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách nguyên liệu</h2>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Danh sách vật tư cấu thành đang áp dụng cho BOM hiện tại.</p>
                        </div>

                        <% if (details != null && !details.isEmpty()) { %>
                        <div class="overflow-x-auto">
                            <table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700">
                                <thead class="bg-slate-50 dark:bg-slate-800/80">
                                    <tr>
                                        <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">#</th>
                                        <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Nguyên liệu</th>
                                        <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Số lượng</th>
                                        <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Đơn vị</th>
                                        <th class="px-6 py-4 text-left text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">Ghi chú</th>
                                    </tr>
                                </thead>
                                <tbody class="divide-y divide-slate-100 bg-white dark:divide-slate-800 dark:bg-transparent">
                                    <%
                                        int stt = 1;
                                        for (BOMDetailDTO detail : details) {
                                    %>
                                    <tr class="transition-colors hover:bg-slate-50/80 dark:hover:bg-slate-800/50">
                                        <td class="px-6 py-4 text-sm font-medium text-slate-500 dark:text-slate-400"><%= stt++ %></td>
                                        <td class="px-6 py-4">
                                            <div class="font-semibold text-slate-900 dark:text-slate-100"><%= detail.getMaterialName() != null ? detail.getMaterialName() : "ID: " + detail.getMaterialItemId() %></div>
                                            <div class="mt-1 text-xs text-slate-500 dark:text-slate-400">Mã vật tư: <%= detail.getMaterialItemId() %></div>
                                        </td>
                                        <td class="px-6 py-4 text-sm font-semibold text-slate-900 dark:text-slate-100"><%= detail.getQuantityRequired() %></td>
                                        <td class="px-6 py-4 text-sm text-slate-600 dark:text-slate-300"><%= detail.getUnit() != null && !detail.getUnit().trim().isEmpty() ? detail.getUnit() : "-" %></td>
                                        <td class="px-6 py-4 text-sm text-slate-600 dark:text-slate-300"><%= detail.getNotes() != null && !detail.getNotes().trim().isEmpty() ? detail.getNotes() : "-" %></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                        <% } else { %>
                        <div class="px-6 py-14 text-center">
                            <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Chưa có nguyên liệu nào</h3>
                            <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">BOM này hiện chưa có dòng nguyên liệu.</p>
                        </div>
                        <% } %>
                    </section>
                </div>
                <% } %>
            </main>
        </div>
    </div>
</body>
</html>
