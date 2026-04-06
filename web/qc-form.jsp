<%@page contentType="text/html" pageEncoding="UTF-8" import="java.util.List, pms.model.WorkOrderDTO, pms.model.RoutingStepDTO, pms.model.DefectDTO, pms.model.UserDTO"%>
<%
    List<WorkOrderDTO> workOrders = (List<WorkOrderDTO>) request.getAttribute("workOrders");
    List<RoutingStepDTO> steps = (List<RoutingStepDTO>) request.getAttribute("steps");
    List<DefectDTO> defects = (List<DefectDTO>) request.getAttribute("defects");
    UserDTO user = (UserDTO) session.getAttribute("user");
    
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");
    
    if (workOrders == null) workOrders = new java.util.ArrayList<>();
    if (steps == null) steps = new java.util.ArrayList<>();
    if (defects == null) defects = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Them Kiem Tra Chat Luong - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
    <style>
        body { font-family: Inter, "Segoe UI", Arial, sans-serif; }
        .form-input:focus {
            border-color: #0d9488;
            box-shadow: 0 0 0 3px rgba(20, 184, 166, 0.1);
        }
    </style>
</head>
<body class="bg-slate-50 min-h-screen">
    <div class="max-w-3xl mx-auto px-4 py-8">
        <!-- Header -->
        <div class="flex items-center gap-4 mb-8">
            <a href="QcController?action=list" class="flex items-center gap-2 text-slate-600 hover:text-slate-900 transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
                </svg>
                Quay lai
            </a>
            <span class="text-slate-300">|</span>
            <h1 class="text-xl font-semibold text-slate-900">Them Kiem Tra Chat Luong</h1>
        </div>

        <!-- Alerts -->
        <% if (msg != null && !msg.isEmpty()) { %>
        <div class="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center gap-3">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= msg %>
        </div>
        <% } %>
        <% if (error != null && !error.isEmpty()) { %>
        <div class="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-center gap-3">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <%= error %>
        </div>
        <% } %>

        <!-- Form Card -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
            <div class="bg-gradient-to-r from-teal-500 to-teal-600 p-6 text-white">
                <h2 class="text-lg font-semibold">Thong Tin Kiem Tra Chat Luong</h2>
                <p class="text-teal-100 text-sm mt-1">Nhap thong tin kiem tra chat luong san pham</p>
            </div>

            <form action="QcController" method="post" class="p-6 space-y-6">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="inspectorId" value="<%= user != null ? user.getId() : 0 %>">

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <!-- Work Order -->
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">
                            Lenh San Xuat (WO) <span class="text-red-500">*</span>
                        </label>
                        <select name="woId" id="woId" required
                                class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all bg-white"
                                onchange="updateQuantity()">
                            <option value="">-- Chon lenh san xuat --</option>
                            <% for (WorkOrderDTO wo : workOrders) { 
                                if (!"Completed".equalsIgnoreCase(wo.getStatus()) && !"Cancelled".equalsIgnoreCase(wo.getStatus())) {
                            %>
                            <option value="<%= wo.getWo_id() %>" data-quantity="<%= wo.getOrder_quantity() %>">
                                WO-<%= wo.getWo_id() %> | <%= wo.getProductName() != null ? wo.getProductName() : "SP#" + wo.getProduct_item_id() %> | SL: <%= wo.getOrder_quantity() %>
                            </option>
                            <% }} %>
                        </select>
                    </div>

                    <!-- Routing Step -->
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">
                            Cong Doan <span class="text-red-500">*</span>
                        </label>
                        <select name="stepId" id="stepId" required
                                class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all bg-white">
                            <option value="">-- Chon cong doan --</option>
                            <% for (RoutingStepDTO s : steps) { %>
                            <option value="<%= s.getStepId() %>"><%= s.getStepName() %> (<%= s.getEstimatedTime() %> phut)</option>
                            <% } %>
                        </select>
                    </div>
                </div>

                <!-- Quantity Row -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <!-- Total Inspected -->
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">
                            Tong So Luong Kiem Tra <span class="text-red-500">*</span>
                        </label>
                        <input type="number" name="quantityInspected" id="quantityInspected" value="0" min="1" required
                               placeholder="VD: 100"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all"
                               oninput="calculateResults()">
                    </div>

                    <!-- Passed -->
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">
                            So Luong Dat (PASS) <span class="text-red-500">*</span>
                        </label>
                        <input type="number" name="quantityPassed" id="quantityPassed" value="0" min="0" required
                               placeholder="VD: 95"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all"
                               oninput="calculateResults()">
                        <p id="passRate" class="text-xs text-emerald-600 mt-1 font-medium"></p>
                    </div>

                    <!-- Failed -->
                    <div>
                        <label class="block text-sm font-semibold text-slate-700 mb-2">
                            So Luong Loi (FAIL)
                        </label>
                        <input type="number" name="quantityFailed" id="quantityFailed" value="0" min="0" readonly
                               placeholder="Tu dong tinh"
                               class="w-full px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 text-slate-500">
                        <p id="failRate" class="text-xs text-red-600 mt-1 font-medium"></p>
                    </div>
                </div>

                <!-- Inspection Result -->
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">
                        Ket Qua Kiem Tra <span class="text-red-500">*</span>
                    </label>
                    <div class="flex gap-4">
                        <label class="flex items-center gap-3 px-6 py-3 rounded-xl border-2 cursor-pointer transition-all <%= "PASS".equals(request.getParameter("result")) ? "border-emerald-500 bg-emerald-50" : "border-slate-200 hover:border-emerald-300" %>" id="passLabel">
                            <input type="radio" name="inspectionResult" value="PASS" required
                                   class="w-5 h-5 text-emerald-600" onchange="toggleResult()">
                            <span class="flex items-center gap-2">
                                <svg class="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                                </svg>
                                <span class="font-semibold text-emerald-700">Dat (PASS)</span>
                            </span>
                        </label>
                        <label class="flex items-center gap-3 px-6 py-3 rounded-xl border-2 cursor-pointer transition-all <%= "FAIL".equals(request.getParameter("result")) ? "border-red-500 bg-red-50" : "border-slate-200 hover:border-red-300" %>" id="failLabel">
                            <input type="radio" name="inspectionResult" value="FAIL"
                                   class="w-5 h-5 text-red-600" onchange="toggleResult()">
                            <span class="flex items-center gap-2">
                                <svg class="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                                </svg>
                                <span class="font-semibold text-red-700">Loi (FAIL)</span>
                            </span>
                        </label>
                    </div>
                </div>

                <!-- Defect Reason (show when FAIL) -->
                <div id="defectSection" class="hidden">
                    <label class="block text-sm font-semibold text-slate-700 mb-2">
                        Ly Do Loi
                    </label>
                    <select name="defectId" id="defectId"
                            class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all bg-white">
                        <option value="0">-- Khong co loi cu the --</option>
                        <% for (DefectDTO d : defects) { %>
                        <option value="<%= d.getDefectId() %>"><%= d.getReasonName() %></option>
                        <% } %>
                    </select>
                </div>

                <!-- Notes -->
                <div>
                    <label class="block text-sm font-semibold text-slate-700 mb-2">
                        Ghi Chu
                    </label>
                    <textarea name="notes" id="notes" rows="3"
                              placeholder="Nhap ghi chu neu co..."
                              class="w-full px-4 py-3 rounded-xl border border-slate-200 form-input transition-all resize-none"></textarea>
                </div>

                <!-- Actions -->
                <div class="flex items-center gap-4 pt-4 border-t border-slate-100">
                    <button type="submit" class="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-teal-600 text-white font-semibold hover:bg-teal-700 transition-all shadow-sm">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                        </svg>
                        Luu Ket Qua
                    </button>
                    <a href="QcController?action=list" class="px-6 py-3 rounded-xl border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition-all">
                        Huy Bo
                    </a>
                </div>
            </form>
        </div>
    </div>

    <script>
        function calculateResults() {
            const total = parseInt(document.getElementById('quantityInspected').value) || 0;
            const passed = parseInt(document.getElementById('quantityPassed').value) || 0;
            const failed = Math.max(0, total - passed);
            
            document.getElementById('quantityFailed').value = failed;
            
            // Calculate rates
            const passRate = total > 0 ? ((passed / total) * 100).toFixed(1) : 0;
            const failRate = total > 0 ? ((failed / total) * 100).toFixed(1) : 0;
            
            document.getElementById('passRate').textContent = passRate + '% dat';
            document.getElementById('failRate').textContent = failRate + '% loi';
        }

        function toggleResult() {
            const passRadio = document.querySelector('input[name="inspectionResult"][value="PASS"]');
            const failRadio = document.querySelector('input[name="inspectionResult"][value="FAIL"]');
            const passLabel = document.getElementById('passLabel');
            const failLabel = document.getElementById('failLabel');
            const defectSection = document.getElementById('defectSection');
            
            if (passRadio.checked) {
                passLabel.classList.add('border-emerald-500', 'bg-emerald-50');
                passLabel.classList.remove('border-slate-200');
                failLabel.classList.remove('border-red-500', 'bg-red-50');
                failLabel.classList.add('border-slate-200');
                defectSection.classList.add('hidden');
            } else if (failRadio.checked) {
                failLabel.classList.add('border-red-500', 'bg-red-50');
                failLabel.classList.remove('border-slate-200');
                passLabel.classList.remove('border-emerald-500', 'bg-emerald-50');
                passLabel.classList.add('border-slate-200');
                defectSection.classList.remove('hidden');
            }
        }

        function updateQuantity() {
            const woSelect = document.getElementById('woId');
            const selectedOption = woSelect.options[woSelect.selectedIndex];
            const quantity = selectedOption.getAttribute('data-quantity');
            if (quantity) {
                document.getElementById('quantityInspected').value = quantity;
                calculateResults();
            }
        }
    </script>
</body>
</html>
