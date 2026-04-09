<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.ProductionLogDTO, pms.model.QcInspectionDTO, pms.model.WorkOrderDTO, pms.model.RoutingStepDTO, pms.model.DefectDTO, pms.model.UserDTO, java.text.SimpleDateFormat"%>
<%
    List<ProductionLogDTO> listLogs = (List<ProductionLogDTO>) request.getAttribute("listLogs");
    List<QcInspectionDTO> inspections = (List<QcInspectionDTO>) request.getAttribute("inspections");
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("listWO");
    List<RoutingStepDTO> listSteps = (List<RoutingStepDTO>) request.getAttribute("listSteps");
    List<DefectDTO> listDefects = (List<DefectDTO>) request.getAttribute("listDefects");
    
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    String activeTab = request.getParameter("tab");
    if (activeTab == null) activeTab = "log"; // default to production log

    if (listLogs == null) listLogs = new java.util.ArrayList<>();
    if (inspections == null) inspections = new java.util.ArrayList<>();
    if (workOrders == null) workOrders = new java.util.ArrayList<>();
    if (listSteps == null) listSteps = new java.util.ArrayList<>();
    if (listDefects == null) listDefects = new java.util.ArrayList<>();

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    
    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";
    
    request.setAttribute("activePage", "tracking");
    request.setAttribute("pageTitle", "Theo dõi Sản xuất & QC");

    // Production KPIs
    int totalLogs = listLogs.size();
    int totalOK = 0, totalNG = 0;
    for (ProductionLogDTO log : listLogs) {
        totalOK += log.getQuantityDone();
        totalNG += log.getQuantityDefective();
    }
    
    // QC KPIs
    Integer totalInspectedAttr = (Integer) request.getAttribute("totalInspected");
    Integer totalFailedAttr = (Integer) request.getAttribute("totalFailed");
    Double passRateAttr = (Double) request.getAttribute("passRate");
    int totalInspected = totalInspectedAttr != null ? totalInspectedAttr : 0;
    int totalFailed = totalFailedAttr != null ? totalFailedAttr : 0;
    int totalPassed = totalInspected - totalFailed;
    double passRate = passRateAttr != null ? passRateAttr : 0;
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Theo dõi Sản xuất & QC - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: { fontFamily: { sans: ['Inter', 'sans-serif'], } }
            }
        }
    </script>
    <style>
        body { font-family: Inter, sans-serif; }
        .sidebar { box-shadow: 24px 0 48px rgba(15, 23, 42, 0.16); }
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .form-input { transition: all 0.2s ease; }
        .form-input:focus { box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1); }
        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }
        .kpi-card { transition: all 0.2s ease; }
        .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08); }
        .section-card { background: rgba(255,255,255,0.95); backdrop-filter: blur(12px); }
        .dark .section-card { background: rgba(15,23,42,0.92); }
        .status-pass { background: #d1fae5; color: #047857; }
        .status-fail { background: #fee2e2; color: #b91c1c; }
        .dark .status-pass { background: rgba(16, 185, 129, 0.14); color: #6ee7b7; }
        .dark .status-fail { background: rgba(239, 68, 68, 0.14); color: #fca5a5; }
        
        /* Tabs styling */
        .tab-btn { transition: all 0.2s ease; border-bottom: 2px solid transparent; }
        .tab-btn.active { border-bottom-color: #0d9488; color: #0d9488; font-weight: 600; }
        .dark .tab-btn.active { border-bottom-color: #2dd4bf; color: #2dd4bf; }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased dark:bg-slate-900 dark:text-slate-100 <%= isDarkMode ? "dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />
        
        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />
            
            <main class="flex-1 overflow-y-auto p-4 lg:p-6 bg-slate-100 dark:bg-slate-900">
                <!-- Page Header -->
                <div class="mb-4">
                    <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Theo dõi Sản xuất & Kiểm định</h1>
                    <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Ghi nhận sản lượng hoàn thành và kiểm tra chất lượng kết quả</p>
                </div>

                <!-- Alerts -->
                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-4 p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-700 dark:bg-emerald-500/10 dark:border-emerald-500/20 dark:text-emerald-300 flex items-center gap-3">
                    <%= java.net.URLDecoder.decode(msg, "UTF-8") %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-4 p-4 rounded-2xl bg-red-50 border border-red-200 text-red-700 dark:bg-red-500/10 dark:border-red-500/20 dark:text-red-300 flex items-center gap-3">
                    <%= java.net.URLDecoder.decode(error, "UTF-8") %>
                </div>
                <% } %>

                <!-- Tabs Navigation -->
                <div class="border-b border-slate-200 dark:border-slate-700 mb-6 flex gap-6">
                    <button class="tab-btn px-2 py-3 text-sm text-slate-600 dark:text-slate-400 <%= "log".equals(activeTab) ? "active" : "" %>" onclick="switchTab('log')">
                        Nhật ký Sản Lượng
                    </button>
                    <button class="tab-btn px-2 py-3 text-sm text-slate-600 dark:text-slate-400 <%= "qc".equals(activeTab) ? "active" : "" %>" onclick="switchTab('qc')">
                        Phiếu Kiểm Tra QC
                    </button>
                </div>

                <!-- TAB CONTENT: LOG -->
                <div id="tab-log" class="<%= "log".equals(activeTab) ? "block" : "hidden" %> animate-fade-in">
                    <!-- Actions -->
                    <div class="mb-6 flex justify-end">
                        <button onclick="openModal('logModal')" class="inline-flex items-center gap-2 rounded-2xl bg-amber-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-amber-500/30 transition-all hover:bg-amber-600">
                            + Tạo báo cáo sản lượng
                        </button>
                    </div>

                    <!-- Production KPIs -->
                    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 mb-6">
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">Tổng báo cáo</p>
                            <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalLogs %></p>
                        </div>
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">SP Đạt</p>
                            <p class="mt-2 text-3xl font-bold text-emerald-600"><%= totalOK %></p>
                        </div>
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">SP Lỗi</p>
                            <p class="mt-2 text-3xl font-bold text-red-600"><%= totalNG %></p>
                        </div>
                    </div>

                    <!-- Production Logs Table -->
                    <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                        <table class="w-full">
                            <thead>
                                <tr class="bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Mã Lệnh</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Đạt</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Lỗi</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Ngày giờ</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Lý do</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (listLogs.isEmpty()) { %>
                                    <tr><td colspan="5" class="p-6 text-center text-slate-500">Chưa có báo cáo sản lượng.</td></tr>
                                <% } else { for (ProductionLogDTO l : listLogs) { %>
                                    <tr class="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td class="px-4 py-3 text-sm">WO-<%= l.getWoId() %></td>
                                        <td class="px-4 py-3 text-sm text-emerald-600 font-semibold"><%= l.getQuantityDone() %></td>
                                        <td class="px-4 py-3 text-sm <%= l.getQuantityDefective() > 0 ? "text-red-600 font-semibold" : "text-slate-400" %>"><%= l.getQuantityDefective() %></td>
                                        <td class="px-4 py-3 text-sm text-slate-500"><%= l.getLogDate() != null ? sdf.format(l.getLogDate()) : "-" %></td>
                                        <td class="px-4 py-3 text-sm text-slate-500"><%= l.getDefectName() != null ? l.getDefectName() : "-" %></td>
                                    </tr>
                                <% } } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB CONTENT: QC -->
                <div id="tab-qc" class="<%= "qc".equals(activeTab) ? "block" : "hidden" %> animate-fade-in">
                    <!-- Actions -->
                    <div class="mb-6 flex justify-end">
                        <button onclick="openModal('qcModal')" class="inline-flex items-center gap-2 rounded-2xl bg-teal-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                            + Tạo phiếu kiểm tra
                        </button>
                    </div>

                    <!-- QC KPIs -->
                    <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">Tổng kiểm tra (SP)</p>
                            <p class="mt-2 text-3xl font-bold text-slate-800 dark:text-slate-100"><%= totalInspected %></p>
                        </div>
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">Đạt</p>
                            <p class="mt-2 text-3xl font-bold text-emerald-600"><%= totalPassed %></p>
                        </div>
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">Lỗi</p>
                            <p class="mt-2 text-3xl font-bold text-rose-600"><%= totalFailed %></p>
                        </div>
                        <div class="kpi-card rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
                            <p class="text-xs font-semibold text-slate-500 uppercase">Tỷ lệ Đạt</p>
                            <p class="mt-2 text-3xl font-bold text-teal-600"><%= String.format("%.1f", passRate) %>%</p>
                        </div>
                    </div>

                    <!-- QC Logs Table -->
                    <div class="section-card rounded-3xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
                        <table class="w-full">
                            <thead>
                                <tr class="bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Mã Lệnh</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Kết quả</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Tổng KT</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Đạt</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase text-slate-500">Ghi chú</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% if (inspections.isEmpty()) { %>
                                    <tr><td colspan="5" class="p-6 text-center text-slate-500">Chưa có phiếu kiểm tra.</td></tr>
                                <% } else { for (QcInspectionDTO q : inspections) { 
                                    boolean passed = "PASS".equals(q.getInspectionResult());
                                %>
                                    <tr class="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td class="px-4 py-3 text-sm">WO-<%= q.getWoId() %></td>
                                        <td class="px-4 py-3">
                                            <span class="px-2.5 py-1 rounded-full text-xs font-bold <%= passed ? "status-pass" : "status-fail" %>">
                                                <%= passed ? "Đạt" : "Lỗi" %>
                                            </span>
                                        </td>
                                        <td class="px-4 py-3 text-sm"><%= q.getQuantityInspected() %></td>
                                        <td class="px-4 py-3 text-sm text-emerald-600 font-semibold"><%= q.getQuantityPassed() %></td>
                                        <td class="px-4 py-3 text-sm text-slate-500"><%= q.getNotes() != null ? q.getNotes() : "-" %></td>
                                    </tr>
                                <% } } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    </div>
    
    <div id="sidebarOverlay" class="fixed inset-0 bg-black/50 z-20 lg:hidden hidden" onclick="toggleSidebar()"></div>
    <jsp:include page="mobile-nav.jsp" />

    <!-- MODAL: ADD LOG -->
    <div id="logModal" class="hidden fixed inset-0 z-50 items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card w-full max-w-lg rounded-3xl p-6">
            <h3 class="text-lg font-bold mb-4 dark:text-white">Báo cáo sản lượng</h3>
            <form action="ProductionTrackingController" method="post" class="space-y-4">
                <input type="hidden" name="action" value="addLog">
                <select name="workOrderId" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="">-- Chọn lệnh --</option>
                    <% for (WorkOrderDTO w : workOrders) { if (!"Completed".equalsIgnoreCase(w.getStatus())) { %>
                    <option value="<%= w.getWo_id() %>">WO-<%= w.getWo_id() %> (<%= w.getOrder_quantity() %> sp)</option>
                    <% } } %>
                </select>
                <select name="stepId" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="">-- Chọn công đoạn --</option>
                    <% for (RoutingStepDTO s : listSteps) { %>
                    <option value="<%= s.getStepId() %>"><%= s.getStepName() %></option>
                    <% } %>
                </select>
                <div class="flex gap-4">
                    <input type="number" name="quantityDone" min="0" value="0" placeholder="Số lượng đạt" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <input type="number" name="quantityDefective" min="0" value="0" placeholder="Số lượng lỗi" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                </div>
                <select name="defectId" class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="0">-- Nguyên nhân lỗi --</option>
                    <% for (DefectDTO d : listDefects) { %>
                    <option value="<%= d.getDefectId() %>"><%= d.getReasonName() %></option>
                    <% } %>
                </select>
                <div class="flex justify-end gap-2 mt-4">
                    <button type="button" onclick="closeModal('logModal')" class="px-4 py-2 rounded-xl border dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800">Hủy</button>
                    <button type="submit" class="px-4 py-2 rounded-xl bg-amber-500 text-white font-semibold">Lưu</button>
                </div>
            </form>
        </div>
    </div>

    <!-- MODAL: ADD QC -->
    <div id="qcModal" class="hidden fixed inset-0 z-50 items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">
        <div class="section-card w-full max-w-lg rounded-3xl p-6">
            <h3 class="text-lg font-bold mb-4 dark:text-white">Kiểm tra chất lượng</h3>
            <form action="ProductionTrackingController" method="post" class="space-y-4">
                <input type="hidden" name="action" value="addQc">
                <select name="woId" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="">-- Chọn lệnh --</option>
                    <% for (WorkOrderDTO w : workOrders) { if (!"Completed".equalsIgnoreCase(w.getStatus())) { %>
                    <option value="<%= w.getWo_id() %>">WO-<%= w.getWo_id() %> (<%= w.getOrder_quantity() %> sp)</option>
                    <% } } %>
                </select>
                <select name="stepId" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="">-- Chọn công đoạn --</option>
                    <% for (RoutingStepDTO s : listSteps) { %>
                    <option value="<%= s.getStepId() %>"><%= s.getStepName() %></option>
                    <% } %>
                </select>
                <div class="flex gap-4">
                    <input type="number" name="quantityInspected" min="1" placeholder="Tổng kiểm" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <input type="number" name="quantityPassed" min="0" placeholder="Số đạt" required class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                </div>
                <div class="flex gap-4 justify-around mt-2">
                    <label class="flex items-center gap-2"><input type="radio" name="inspectionResult" value="PASS" required> PASS</label>
                    <label class="flex items-center gap-2 text-red-500"><input type="radio" name="inspectionResult" value="FAIL"> FAIL</label>
                </div>
                <select name="defectId" class="w-full form-input p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600">
                    <option value="0">-- Lỗi kỹ thuật --</option>
                    <% for (DefectDTO d : listDefects) { %>
                    <option value="<%= d.getDefectId() %>"><%= d.getReasonName() %></option>
                    <% } %>
                </select>
                <textarea name="notes" placeholder="Ghi chú thêm..." class="w-full p-3 rounded-xl border border-slate-300 dark:bg-slate-800 dark:border-slate-600"></textarea>
                <div class="flex justify-end gap-2 mt-4">
                    <button type="button" onclick="closeModal('qcModal')" class="px-4 py-2 rounded-xl border dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800">Hủy</button>
                    <button type="submit" class="px-4 py-2 rounded-xl bg-teal-600 text-white font-semibold">Lưu QC</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function switchTab(tab) {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.getElementById('tab-log').classList.add('hidden');
            document.getElementById('tab-qc').classList.add('hidden');
            
            event.target.classList.add('active');
            document.getElementById('tab-' + tab).classList.remove('hidden');
            
            // update URL params to avoid re-loading tab reset if we want to save state
            const url = new URL(window.location);
            url.searchParams.set('tab', tab);
            window.history.pushState({}, '', url);
        }

        function openModal(id) { document.getElementById(id).classList.remove('hidden'); document.getElementById(id).classList.add('flex'); }
        function closeModal(id) { document.getElementById(id).classList.add('hidden'); document.getElementById(id).classList.remove('flex');}
    </script>
</body>
</html>
