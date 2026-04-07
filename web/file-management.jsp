<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.ArrayList, pms.model.UserDTO, pms.controllers.FileController.FileRecordWrapper"%>
<%
    ArrayList<FileRecordWrapper> fileList = (ArrayList<FileRecordWrapper>) request.getAttribute("fileList");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    UserDTO user = (UserDTO) session.getAttribute("user");
    String downloadError = (String) request.getAttribute("downloadError");
    String downloadSuccess = (String) request.getAttribute("downloadSuccess");

    if (fileList == null) fileList = new ArrayList<>();
    String selectedTable = request.getParameter("table");
    if (selectedTable == null) selectedTable = "";
    
    String userName = user != null ? user.getUsername() : "User";
    String userRole = user != null ? user.getRole() : "user";
    boolean isAdmin = "admin".equalsIgnoreCase(userRole);
    String pageTitle = "Quản lý file mã hóa";
    String pageSubtitle = "Upload, mã hóa và tải xuống tài liệu";
    request.setAttribute("activePage", "file");
    request.setAttribute("pageTitle", pageTitle);
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    int unreadCount = 0;
%>
<!DOCTYPE html>
<html lang="<%= lang %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản Lý File - PMS</title>
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
        
        .upload-zone {
            border: 2px dashed #cbd5e1;
            transition: all 0.2s;
        }
        .upload-zone.dragover {
            border-color: #14b8a6;
            background: #f0fdfa;
        }
        
        .file-card {
            transition: all 0.2s ease;
        }
        .file-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
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
                    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                        <div>
                            <h1 class="text-2xl font-bold text-slate-800 dark:text-slate-100">Quản lý file mã hóa</h1>
                            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">Upload, mã hóa và tải xuống tài liệu an toàn</p>
                        </div>
                        <div class="flex gap-2">
                            <select id="filterTable" onchange="filterByTable()" class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm">
                                <option value="">Tất cả bảng</option>
                                <option value="Bill">Bill</option>
                                <option value="Work_Order">Work_Order</option>
                                <option value="Purchase_Order">Purchase_Order</option>
                                <option value="Customer">Customer</option>
                                <option value="Item">Item</option>
                            </select>
                        </div>
                    </div>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 dark:bg-emerald-900/30 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 dark:bg-red-900/30 dark:border-red-800 text-red-700 dark:text-red-300 flex items-center gap-3">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <%= error %>
                </div>
                <% } %>

                <!-- Upload Zone -->
                <% if (isAdmin) { %>
                <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm overflow-hidden mb-6">
                    <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-4 text-white">
                        <h3 class="text-lg font-semibold">Upload file mã hóa</h3>
                        <p class="text-teal-100 text-sm mt-1">Kéo thả hoặc chọn file để upload</p>
                    </div>
                    <div class="upload-zone rounded-xl p-8 m-4 dark:border-slate-600" id="uploadZone">
                        <form action="FileController" method="post" enctype="multipart/form-data" id="uploadForm">
                            <input type="hidden" name="action" value="upload"/>
                            <input type="hidden" name="uploader_id" value="<%= user != null ? user.getId() : 0 %>"/>
                            <div class="text-center">
                                <input type="file" id="fileInput" name="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.txt,.jpg,.jpeg,.png,.zip,.rar" class="hidden"/>
                                <label for="fileInput" class="cursor-pointer inline-flex items-center gap-2 px-6 py-3 bg-teal-600 text-white rounded-xl font-semibold hover:bg-teal-700 transition-all shadow-lg shadow-teal-600/30">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"/>
                                    </svg>
                                    Chọn file
                                </label>
                                <p class="mt-4 text-sm text-slate-500 dark:text-slate-400">PDF, DOC, DOCX, XLS, XLSX, TXT, JPG, PNG, ZIP, RAR (tối đa 10MB)</p>
                            </div>
                            <div id="filePreview" style="display:none;" class="mt-6 max-w-md mx-auto">
                                <div class="bg-slate-50 dark:bg-slate-900/50 rounded-xl p-4 border border-slate-200 dark:border-slate-700">
                                    <div id="previewName" class="font-semibold text-slate-700 dark:text-slate-200 mb-4 text-center"></div>
                                    <div class="space-y-3">
                                        <div>
                                            <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1">Mật khẩu mã hóa *</label>
                                            <input type="password" id="encryptPassword" name="password" placeholder="Nhập mật khẩu" required
                                                   class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 dark:text-slate-200 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800 transition-all">
                                        </div>
                                        <div class="grid grid-cols-2 gap-3">
                                            <div>
                                                <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1">Liên quan bảng</label>
                                                <select name="related_table" id="relatedTable" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 dark:text-slate-200">
                                                    <option value="">-- Chọn bảng --</option>
                                                    <option value="Bill">Bill (Hóa đơn)</option>
                                                    <option value="Work_Order">Work_Order</option>
                                                    <option value="Purchase_Order">Purchase_Order</option>
                                                    <option value="Customer">Customer</option>
                                                    <option value="Item">Item</option>
                                                </select>
                                            </div>
                                            <div>
                                                <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1">ID liên quan</label>
                                                <input type="number" name="related_id" id="relatedId" placeholder="ID"
                                                       class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 dark:text-slate-200">
                                            </div>
                                        </div>
                                        <div>
                                            <label class="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1">Mô tả</label>
                                            <textarea name="description" placeholder="Mô tả file..." rows="2"
                                                      class="w-full px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 dark:text-slate-200"></textarea>
                                        </div>
                                        <button type="submit" class="w-full py-3 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all shadow-lg shadow-teal-600/30">
                                            Tải lên và mã hóa
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                <% } %>

                <!-- File List -->
                <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-sm overflow-hidden">
                    <div class="p-4 border-b border-slate-100 dark:border-slate-700 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                        <div>
                            <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">Danh sách file</h3>
                            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1"><%= fileList.size() %> file</p>
                        </div>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">File</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Định Dạng</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Kích Thước</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Liên Quan</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Upload Bởi</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành Động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (fileList.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="px-4 py-12 text-center text-slate-400 dark:text-slate-500">
                                        <div class="flex flex-col items-center gap-2">
                                            <svg class="w-12 h-12 text-slate-300 dark:text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                                            </svg>
                                            <p>Chưa có file nào</p>
                                        </div>
                                    </td>
                                </tr>
                                <% } else { %>
                                    <% for (FileRecordWrapper f : fileList) { %>
                                    <tr class="border-b border-slate-50 dark:border-slate-800 last:border-0 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                                        <td class="px-4 py-3">
                                            <div class="flex items-center gap-3">
                                                <div class="w-10 h-10 rounded-lg bg-teal-50 dark:bg-teal-900/30 flex items-center justify-center text-xl">
                                                    <% if ("pdf".equals(f.fileExtension)) { %>📄
                                                    <% } else if ("doc".equals(f.fileExtension) || "docx".equals(f.fileExtension)) { %>📝
                                                    <% } else if ("xls".equals(f.fileExtension) || "xlsx".equals(f.fileExtension)) { %>📊
                                                    <% } else if ("jpg".equals(f.fileExtension) || "jpeg".equals(f.fileExtension) || "png".equals(f.fileExtension)) { %>🖼️
                                                    <% } else if ("zip".equals(f.fileExtension) || "rar".equals(f.fileExtension)) { %>📦
                                                    <% } else { %>📄<% } %>
                                                </div>
                                                <div>
                                                    <p class="font-semibold text-slate-700 dark:text-slate-200"><%= f.originalName %></p>
                                                    <% if (f.description != null && !f.description.isEmpty()) { %>
                                                    <p class="text-xs text-slate-500 dark:text-slate-400"><%= f.description %></p>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-4 py-3">
                                            <span class="px-2 py-1 rounded bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 text-xs font-bold uppercase"><%= f.fileExtension %></span>
                                        </td>
                                        <td class="px-4 py-3 text-slate-600 dark:text-slate-400"><%= f.fileSize %></td>
                                        <td class="px-4 py-3">
                                            <% if (f.relatedTable != null && !f.relatedTable.isEmpty()) { %>
                                            <span class="px-2 py-1 rounded bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-xs font-bold">#<%= f.relatedTable %>-<%= f.relatedId %></span>
                                            <% } else { %>
                                            <span class="text-slate-400 dark:text-slate-500">-</span>
                                            <% } %>
                                        </td>
                                        <td class="px-4 py-3 text-slate-600 dark:text-slate-400"><%= f.uploaderName != null ? f.uploaderName : "-" %></td>
                                        <td class="px-4 py-3 text-center">
                                            <div class="flex items-center justify-center gap-2">
                                                <button type="button"
                                                        data-file-id="<%= f.fileId %>"
                                                        data-file-name="<%= f.originalName %>"
                                                        onclick="openDownloadModalFromButton(this)"
                                                        class="px-3 py-1.5 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 transition-colors">
                                                    Tải xuống
                                                </button>
                                                <% if (isAdmin) { %>
                                                <form action="FileController" method="post" style="display:inline;">
                                                    <input type="hidden" name="action" value="delete"/>
                                                    <input type="hidden" name="file_id" value="<%= f.fileId %>"/>
                                                    <button type="submit" onclick="return confirm('Xóa file này?');"
                                                            class="px-3 py-1.5 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700 transition-colors">
                                                        Xóa
                                                    </button>
                                                </form>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>

    <!-- Download Password Modal -->
    <div id="downloadModal" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 hidden">
        <div class="bg-white dark:bg-slate-800 rounded-2xl p-6 max-w-md w-full shadow-2xl">
            <h3 id="modalTitle" class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">Tải Xuống File</h3>
            <input type="password" id="downloadPassword" placeholder="Nhập mật khẩu giải mã"
                   class="w-full px-4 py-3 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 dark:text-slate-200 mb-3 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 dark:focus:ring-teal-800">
            <div id="modalError" class="text-red-600 dark:text-red-400 text-sm mb-3 hidden"></div>
            <div class="flex gap-3 justify-end">
                <button onclick="closeDownloadModal()" class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 font-medium hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">Hủy</button>
                <button onclick="confirmDownload()" class="px-4 py-2 rounded-xl bg-teal-600 text-white font-medium hover:bg-teal-700 transition-colors">Tải Xuống</button>
            </div>
        </div>
    </div>

    <script>
        var currentDownloadId = null;

        var fileInput = document.getElementById('fileInput');
        var previewName = document.getElementById('previewName');
        var filePreview = document.getElementById('filePreview');
        var uploadZone = document.getElementById('uploadZone');

        if (fileInput && previewName && filePreview) {
            fileInput.addEventListener('change', function(e) {
                var file = e.target.files[0];
                if (file) {
                    previewName.textContent = file.name + ' (' + formatSize(file.size) + ')';
                    filePreview.style.display = 'block';
                }
            });
        }

        if (uploadZone && fileInput && previewName && filePreview) {
            uploadZone.addEventListener('dragover', function(e) {
                e.preventDefault();
                uploadZone.classList.add('dragover');
            });
            uploadZone.addEventListener('dragleave', function(e) {
                uploadZone.classList.remove('dragover');
            });
            uploadZone.addEventListener('drop', function(e) {
                e.preventDefault();
                uploadZone.classList.remove('dragover');
                var file = e.dataTransfer.files[0];
                if (file) {
                    fileInput.files = e.dataTransfer.files;
                    previewName.textContent = file.name + ' (' + formatSize(file.size) + ')';
                    filePreview.style.display = 'block';
                }
            });
        }

        function formatSize(bytes) {
            if (bytes < 1024) return bytes + ' B';
            if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
            return (bytes / 1048576).toFixed(1) + ' MB';
        }

        function openDownloadModal(fileId, fileName) {
            currentDownloadId = fileId;
            document.getElementById('modalTitle').textContent = 'Tải xuống: ' + fileName;
            document.getElementById('downloadPassword').value = '';
            document.getElementById('modalError').classList.add('hidden');
            document.getElementById('downloadModal').classList.remove('hidden');
            setTimeout(function() { document.getElementById('downloadPassword').focus(); }, 100);
        }

        function openDownloadModalFromButton(button) {
            if (!button) return;
            openDownloadModal(button.getAttribute('data-file-id'), button.getAttribute('data-file-name'));
        }

        function closeDownloadModal() {
            document.getElementById('downloadModal').classList.add('hidden');
            currentDownloadId = null;
        }

        function confirmDownload() {
            var password = document.getElementById('downloadPassword').value;
            var errorDiv = document.getElementById('modalError');
            if (!password) {
                errorDiv.textContent = 'Vui lòng nhập mật khẩu!';
                errorDiv.classList.remove('hidden');
                return;
            }
            if (!currentDownloadId) return;

            var form = document.createElement('form');
            form.method = 'POST';
            form.action = 'FileController';
            form.innerHTML = '<input type="hidden" name="action" value="download"/>' +
                '<input type="hidden" name="file_id" value="' + currentDownloadId + '"/>' +
                '<input type="hidden" name="password" value="' + password + '"/>';
            document.body.appendChild(form);
            form.submit();
            document.body.removeChild(form);
            closeDownloadModal();
        }

        var downloadPasswordInput = document.getElementById('downloadPassword');
        if (downloadPasswordInput) {
            downloadPasswordInput.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    confirmDownload();
                }
            });
        }

        function filterByTable() {
            var table = document.getElementById('filterTable').value;
            window.location.href = 'FileController?action=list' + (table ? '&table=' + table : '');
        }

        var selectedTable = '<%= selectedTable %>';
        if (selectedTable) {
            document.getElementById('filterTable').value = selectedTable;
        }
    </script>
</body>
</html>
