<%--
  ===== bom-form.jsp – Form tạo/sửa BOM =====
  Mục đích    : Form dùng cho 2 chế độ: thêm BOM mới (mode="add") và sửa BOM (mode="edit").
                Hỗ trợ thêm/xóa động dòng nguyên liệu qua JavaScript (addMaterialRow / removeMaterialRow).
  Request attributes nhận từ BomController:
    - "mode"      (String)        : "add" hoặc "edit" – xác định tiêu đề, action form, nút submit
    - "bom"       (BOMDTO)        : Đối tượng BOM cần sửa (null khi mode=add)
    - "products"  (List<ItemDTO>) : Danh sách sản phẩm (item_type=SanPham) cho dropdown chọn sản phẩm chính
    - "materials" (List<ItemDTO>) : Danh sách nguyên vật liệu (item_type=VatTu) cho dropdown nguyên liệu
    - "msg"       (String)        : Flash thông báo thành công (nếu có)
    - "error"     (String)        : Thông báo lỗi (nếu có, vd: sản phẩm đã có BOM active)
  Session attributes đọc:
    - session["darkMode"] (Boolean) : Bật/tắt dark mode
    - session["lang"]     (String)  : Ngôn ngữ (vi/en), mặc định "vi"
  Form submit:
    - Thêm mới: POST → BOMController?action=saveAddBOM
    - Cập nhật: POST → BOMController?action=saveUpdateBOM + hidden field id
  Nguyên liệu  : Gửi dưới dạng mảng: materialItemId[], quantityRequired[], detailNotes[]
                 BomController.saveAddBOM() và saveUpdateBOM() xử lý mảng này bằng vòng lặp.
  JavaScript   :
    - addMaterialRow()        : Clone từ <template> – thêm 1 dòng nguyên liệu mới
    - removeMaterialRow(btn)  : Xóa dòng nguyên liệu (giữ lại tối thiểu 1 dòng, xóa trắng thay vì xóa)
    - updateMaterialRowTitles(): Đánh lại số thứ tự "Nguyên liệu #1", "#2"...
  Phân quyền  : Chỉ admin mới có nút "Thêm BOM mới" từ bom-list.jsp; nhưng URL trực tiếp thì bất kỳ ai đăng nhập cũng vào được.
--%>
<%@page import="pms.model.BOMDTO"%>
<%@page import="pms.model.BOMDetailDTO"%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String mode = (String) request.getAttribute("mode");
    BOMDTO bom = (BOMDTO) request.getAttribute("bom");
    List<ItemDTO> products = (List<ItemDTO>) request.getAttribute("products");
    List<ItemDTO> materials = (List<ItemDTO>) request.getAttribute("materials");
    boolean isAdd = "add".equals(mode);

    if (products == null) {
        products = new java.util.ArrayList<>();
    }
    if (materials == null) {
        materials = new java.util.ArrayList<>();
    }

    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");

    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String activePage = "bom";
    String pageTitle = isAdd ? "Thêm BOM" : "Sửa BOM";
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);

    String selectedStatus = bom != null && bom.getStatus() != null ? bom.getStatus() : "active";
    String versionValue = bom != null && bom.getBomVersion() != null ? bom.getBomVersion() : "v1.0";
    String notesValue = bom != null && bom.getNotes() != null ? bom.getNotes() : "";
    List<BOMDetailDTO> detailRows = bom != null && bom.getDetails() != null && !bom.getDetails().isEmpty()
            ? bom.getDetails() : new ArrayList<BOMDetailDTO>();
    if (detailRows.isEmpty()) {
        detailRows.add(new BOMDetailDTO());
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
        .material-row + .material-row {
            border-top: 1px dashed rgba(148, 163, 184, 0.35);
            padding-top: 1rem;
            margin-top: 1rem;
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
                <div class="mb-6 rounded-3xl border border-slate-200 bg-gradient-to-br from-white via-slate-50 to-teal-50/70 p-6 shadow-sm dark:border-slate-700 dark:from-slate-900 dark:via-slate-900 dark:to-teal-950/30">
                    <div class="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                        <div class="max-w-3xl">
                            <div class="inline-flex items-center gap-2 rounded-full border border-teal-200 bg-teal-50 px-3 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-teal-700 dark:border-teal-500/30 dark:bg-teal-500/10 dark:text-teal-300">
                                <%= isAdd ? "Tạo định mức" : "Cập nhật định mức" %>
                            </div>
                            <h1 class="mt-3 text-2xl font-semibold text-slate-900 dark:text-slate-100"><%= isAdd ? "Tạo BOM mới" : "Sửa BOM" %></h1>
                            <p class="mt-2 text-sm leading-6 text-slate-600 dark:text-slate-400"><%= isAdd ? "Thiết lập nhanh định mức vật tư cho sản phẩm trên giao diện đồng bộ với danh sách và trang chi tiết." : "Cập nhật thông tin và danh sách vật tư của BOM trên giao diện chỉnh sửa đồng bộ." %></p>
                        </div>
                        <div class="flex flex-wrap gap-3">
                            <a href="BOMController?action=list" class="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">← Danh sách BOM</a>
                            <% if (!isAdd && bom != null) { %>
                            <a href="BOMController?action=viewBOM&id=<%= bom.getBomId() %>" class="rounded-2xl border border-teal-200 bg-teal-50 px-4 py-3 text-sm font-medium text-teal-700 transition-colors hover:bg-teal-100 dark:border-teal-500/30 dark:bg-teal-500/10 dark:text-teal-300 dark:hover:bg-teal-500/20">Xem chi tiết</a>
                            <% } %>
                        </div>
                    </div>
                </div>

                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-emerald-700 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span><%= msg %></span>
                </div>
                <% } %>

                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 flex items-center gap-3 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-4 text-rose-700 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300">
                    <svg class="h-5 w-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span><%= error %></span>
                </div>
                <% } %>

                <section class="section-card rounded-3xl border border-slate-200/70 p-6 shadow-sm dark:border-slate-700/60">
                    <div class="mb-6 flex items-start justify-between gap-4">
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-100"><%= isAdd ? "Thông tin BOM mới" : "Thông tin BOM cần chỉnh sửa" %></h2>
                            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= isAdd ? "Chọn sản phẩm và khai báo định mức cần thiết." : "Cập nhật sản phẩm áp dụng, ghi chú và danh sách nguyên liệu của BOM." %></p>
                        </div>
                        <% if (!isAdd && bom != null) { %>
                        <span class="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700 ring-1 ring-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:ring-slate-700">BOM #<%= bom.getBomId() %></span>
                        <% } %>
                    </div>

                    <form method="post" action="BOMController" class="space-y-6">
                        <input type="hidden" name="action" value="<%= isAdd ? "saveAddBOM" : "saveUpdateBOM" %>">
                        <% if (!isAdd && bom != null) { %>
                        <input type="hidden" name="id" value="<%= bom.getBomId() %>">
                        <% } %>

                        <div class="grid gap-5 md:grid-cols-2">
                            <div class="md:col-span-2">
                                <label for="productItemId" class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Sản phẩm áp dụng</label>
                                <select id="productItemId" name="productItemId" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                                    <option value="">-- Chọn sản phẩm --</option>
                                    <% for (ItemDTO p : products) { %>
                                    <option value="<%= p.getItemID() %>" <%= bom != null && bom.getProductItemId() == p.getItemID() ? "selected" : "" %>><%= p.getItemName() %></option>
                                    <% } %>
                                </select>
                            </div>

                            <div class="md:col-span-2">
                                <label for="notes" class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Ghi chú</label>
                                <textarea id="notes" name="notes" rows="5" placeholder="Nhập ghi chú cho BOM" class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400"><%= notesValue %></textarea>
                            </div>
                        </div>

                        <section class="rounded-3xl border border-slate-200/80 bg-slate-50/70 p-5 dark:border-slate-700 dark:bg-slate-900/40">
                            <div class="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                                <div>
                                    <h3 class="text-base font-semibold text-slate-900 dark:text-slate-100">Nguyên liệu cấu thành</h3>
                                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400"><%= isAdd ? "Thêm các vật tư cấu thành cần thiết cho định mức sản xuất." : "Điều chỉnh danh sách vật tư cấu thành đang áp dụng cho BOM này." %></p>
                                </div>
                                <button type="button" onclick="addMaterialRow()" class="inline-flex items-center justify-center rounded-2xl border border-teal-200 bg-white px-4 py-2.5 text-sm font-medium text-teal-700 transition hover:bg-teal-50 dark:border-teal-500/30 dark:bg-slate-800 dark:text-teal-300 dark:hover:bg-slate-700">
                                    + Thêm nguyên liệu
                                </button>
                            </div>

                            <div id="materialRows" class="space-y-4">
                                <% for (int i = 0; i < detailRows.size(); i++) {
                                    BOMDetailDTO detail = detailRows.get(i);
                                %>
                                <div class="material-row rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800/70">
                                    <div class="mb-4 flex items-center justify-between gap-3">
                                        <div>
                                            <p class="text-sm font-semibold text-slate-900 dark:text-slate-100">Nguyên liệu #<%= i + 1 %></p>
                                            <p class="text-xs text-slate-500 dark:text-slate-400">Khai báo vật tư và số lượng.</p>
                                        </div>
                                        <button type="button" onclick="removeMaterialRow(this)" class="rounded-xl border border-rose-200 px-3 py-2 text-xs font-medium text-rose-600 hover:bg-rose-50 dark:border-rose-500/30 dark:text-rose-300 dark:hover:bg-rose-500/10">
                                            Xóa
                                        </button>
                                    </div>
                                    <div class="grid gap-4 md:grid-cols-2">
                                        <div>
                                            <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Nguyên liệu</label>
                                            <select name="materialItemId[]" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                                                <option value="">-- Chọn nguyên liệu --</option>
                                                <% for (ItemDTO m : materials) { %>
                                                <option value="<%= m.getItemID() %>" <%= detail.getMaterialItemId() == m.getItemID() ? "selected" : "" %>><%= m.getItemName() %></option>
                                                <% } %>
                                            </select>
                                        </div>
                                        <div>
                                            <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Số lượng</label>
                                            <input type="number" step="0.01" min="0.01" name="quantityRequired[]" value="<%= detail.getQuantityRequired() > 0 ? detail.getQuantityRequired() : "" %>" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                                        </div>
                                        <div class="md:col-span-2">
                                            <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Ghi chú dòng nguyên liệu</label>
                                            <input type="text" name="detailNotes[]" value="<%= detail.getNotes() != null ? detail.getNotes() : "" %>" placeholder="Ví dụ: cắt dư 2%, dùng loại A" class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                                        </div>
                                    </div>
                                </div>
                                <% } %>
                            </div>
                        </section>

                        <div class="flex flex-wrap items-center gap-3 border-t border-slate-200 pt-5 dark:border-slate-700">
                            <button type="submit" class="rounded-2xl bg-teal-600 px-5 py-3 text-sm font-medium text-white shadow-sm shadow-teal-500/30 transition-colors hover:bg-teal-700"><%= isAdd ? "Lưu BOM mới" : "Lưu thay đổi" %></button>
                            <% if (!isAdd && bom != null) { %>
                            <a href="BOMController?action=viewBOM&id=<%= bom.getBomId() %>" class="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Hủy</a>
                            <% } else { %>
                            <a href="BOMController?action=list" class="rounded-2xl border border-slate-200 bg-white px-5 py-3 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">Hủy</a>
                            <% } %>
                        </div>
                    </form>
                </section>
            </main>
        </div>
    </div>

    <template id="materialRowTemplate">
        <div class="material-row rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700 dark:bg-slate-800/70">
            <div class="mb-4 flex items-center justify-between gap-3">
                <div>
                    <p class="text-sm font-semibold text-slate-900 dark:text-slate-100">Nguyên liệu mới</p>
                    <p class="text-xs text-slate-500 dark:text-slate-400">Khai báo vật tư và số lượng.</p>
                </div>
                <button type="button" onclick="removeMaterialRow(this)" class="rounded-xl border border-rose-200 px-3 py-2 text-xs font-medium text-rose-600 hover:bg-rose-50 dark:border-rose-500/30 dark:text-rose-300 dark:hover:bg-rose-500/10">
                    Xóa
                </button>
            </div>
            <div class="grid gap-4 md:grid-cols-2">
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Nguyên liệu</label>
                    <select name="materialItemId[]" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                        <option value="">-- Chọn nguyên liệu --</option>
                        <% for (ItemDTO m : materials) { %>
                        <option value="<%= m.getItemID() %>"><%= m.getItemName() %></option>
                        <% } %>
                    </select>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Số lượng</label>
                    <input type="number" step="0.01" min="0.01" name="quantityRequired[]" required class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                </div>
                <div class="md:col-span-2">
                    <label class="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-200">Ghi chú dòng nguyên liệu</label>
                    <input type="text" name="detailNotes[]" placeholder="Ví dụ: cắt dư 2%, dùng loại A" class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:border-teal-400">
                </div>
            </div>
        </div>
    </template>
    <script>
        function updateMaterialRowTitles() {
            const rows = document.querySelectorAll('#materialRows .material-row');
            rows.forEach((row, index) => {
                const title = row.querySelector('p.font-semibold');
                if (title) {
                    title.textContent = 'Nguyên liệu #' + (index + 1);
                }
            });
        }

        function addMaterialRow() {
            const template = document.getElementById('materialRowTemplate');
            const container = document.getElementById('materialRows');
            if (!template || !container) {
                return;
            }
            container.insertAdjacentHTML('beforeend', template.innerHTML);
            updateMaterialRowTitles();
        }

        function removeMaterialRow(button) {
            const container = document.getElementById('materialRows');
            if (!container) {
                return;
            }
            const rows = container.querySelectorAll('.material-row');
            if (rows.length <= 1) {
                rows[0].querySelectorAll('input, select').forEach((field) => {
                    field.value = '';
                });
                return;
            }
            const row = button.closest('.material-row');
            if (row) {
                row.remove();
                updateMaterialRowTitles();
            }
        }

        document.addEventListener('DOMContentLoaded', updateMaterialRowTitles);
    </script>
</body>
</html>
