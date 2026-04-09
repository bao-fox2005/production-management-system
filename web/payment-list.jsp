<%@page contentType="text/html" pageEncoding="UTF-8" import="pms.model.UserDTO, pms.utils.SystemConfigService"%>
<%
    UserDTO user = (UserDTO) session.getAttribute("user");
    String msg = (String) request.getAttribute("msg");
    String error = (String) request.getAttribute("error");

    Boolean sessionDark = (Boolean) session.getAttribute("darkMode");
    boolean isDarkMode = sessionDark != null ? sessionDark : false;
    String lang = session.getAttribute("lang") != null ? (String) session.getAttribute("lang") : "vi";

    String activePage = request.getAttribute("activePage") != null ? (String) request.getAttribute("activePage") : "payment-config";
    String pageTitle = request.getAttribute("pageTitle") != null ? (String) request.getAttribute("pageTitle") : "Quản lý thanh toán";
    request.setAttribute("activePage", activePage);
    request.setAttribute("pageTitle", pageTitle);

    String bankAccountsData = request.getAttribute("bankAccountsData") != null ? (String) request.getAttribute("bankAccountsData") : null;
    String bankActiveAccountId = request.getAttribute("bankActiveAccountId") != null ? (String) request.getAttribute("bankActiveAccountId") : null;

    if (bankAccountsData == null) {
        SystemConfigService configService = new SystemConfigService();
        bankAccountsData = configService.getConfig("BANK_RECEIVER_ACCOUNTS", "");
        bankActiveAccountId = configService.getConfig("BANK_ACTIVE_ACCOUNT_ID", "");
    }

    if (bankAccountsData == null) bankAccountsData = "";
    if (bankActiveAccountId == null) bankActiveAccountId = "";

    String bankAccountsDataJs = bankAccountsData.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
    String bankActiveAccountIdJs = bankActiveAccountId.replace("\\", "\\\\").replace("'", "\\'").replace("\r", "").replace("\n", "\\n");
%>
<!DOCTYPE html>
<html lang="<%= lang %>" class="<%= isDarkMode ? "dark" : "" %>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý thanh toán - PMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    fontFamily: { sans: ['Inter', 'Segoe UI', 'Arial', 'sans-serif'] }
                }
            }
        };
    </script>
    <style>
        * { font-family: 'Inter', 'Segoe UI', Arial, sans-serif; }
        body { overflow-x: hidden; }

        /* Đồng bộ layout với các trang shared-sidebar khác */
        .sidebar-fixed { position: fixed; top: 0; left: 0; height: 100vh; z-index: 40; }
        .sidebar-header { position: sticky; top: 0; background: #0f172a; z-index: 10; }
        .sidebar-nav { flex: 1; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #475569 #1e293b; }
        .sidebar-nav::-webkit-scrollbar { width: 4px; }
        .sidebar-nav::-webkit-scrollbar-track { background: #1e293b; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: #475569; border-radius: 2px; }
        .sidebar-footer { position: sticky; bottom: 0; background: #0f172a; z-index: 10; }

        .main-wrapper { margin-left: 0; transition: margin-left 0.3s ease; }
        @media (min-width: 1024px) { .main-wrapper { margin-left: 280px; } }

        .section-card {
            background: #ffffff;
            border: 1px solid #e2e8f0;
            box-shadow: 0 2px 8px rgba(15, 23, 42, 0.06);
        }
        .dark .section-card {
            background: #1e293b;
            border-color: #334155;
            box-shadow: none;
        }

        .action-btn {
            border-radius: 14px;
            font-weight: 700;
            letter-spacing: 0.01em;
            transition: all .2s ease;
        }
        .action-btn:hover { transform: translateY(-1px); }

        .modal-backdrop { display: none; }
        .modal-backdrop.open { display: flex; }

        .notice-toast {
            position: fixed;
            right: 20px;
            bottom: 20px;
            z-index: 80;
            max-width: 360px;
            border-radius: 14px;
            border: 1px solid #fecaca;
            background: #fff1f2;
            color: #9f1239;
            padding: 12px 14px;
            box-shadow: 0 14px 30px -18px rgba(190, 24, 93, 0.45);
            display: none;
        }
        .notice-toast.open { display: block; }
        .dark .notice-toast {
            border-color: rgba(244, 114, 182, 0.32);
            background: rgba(136, 19, 55, 0.28);
            color: #fecdd3;
        }
    </style>
    <script src="js/common.js"></script>
</head>
<body class="bg-slate-100 text-slate-900 min-h-screen antialiased <%= isDarkMode ? "dark dark-mode-init" : "" %>">
    <div class="min-h-screen flex">
        <jsp:include page="components/shared-sidebar.jsp" />

        <div id="mainWrapper" class="main-wrapper flex-1 flex flex-col min-h-screen min-w-0">
            <jsp:include page="components/shared-header.jsp" />

            <main class="flex-1 overflow-y-auto bg-slate-100 p-4 lg:p-6 dark:bg-slate-900">
                <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                        <h1 class="text-2xl font-semibold text-slate-900 dark:text-slate-100">Quản lý thanh toán</h1>
                        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Quản lý danh sách tài khoản nhận tiền dùng cho QR thanh toán.</p>
                    </div>
                    <div class="flex flex-wrap items-center gap-3">
                        <button type="button" onclick="openAccountModal('create')" class="inline-flex h-11 items-center justify-center gap-2 rounded-2xl bg-teal-600 px-5 text-sm font-semibold text-white shadow-sm shadow-teal-500/30 transition-all hover:bg-teal-700">
                            Tạo tài khoản nhận tiền
                        </button>
                    </div>
                </div>

                <% if (msg != null && !msg.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 text-emerald-700 dark:text-emerald-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <%= msg %>
                </div>
                <% } %>
                <% if (error != null && !error.trim().isEmpty()) { %>
                <div class="mb-6 p-4 rounded-2xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 text-red-700 dark:text-red-300 flex items-center gap-3 shadow-sm">
                    <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    <%= error %>
                </div>
                <% } %>

                <div class="grid grid-cols-1 gap-4 mb-6 lg:grid-cols-2">
                    <div class="kpi-card bg-white rounded-2xl p-5 shadow-sm border-t-4 border-emerald-500 dark:bg-slate-800 dark:border-slate-700">
                        <div class="flex items-center justify-between gap-3">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">Số tài khoản hoạt động</p>
                                <p id="activeAccountTitle" class="mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-400">0</p>
                                <p id="activeAccountSub" class="mt-1 text-xs text-slate-400 dark:text-slate-500">Đang bật để tạo QR</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-500/10 dark:text-emerald-300">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            </div>
                        </div>
                    </div>
                    <div class="kpi-card bg-white rounded-2xl p-5 shadow-sm border-t-4 border-blue-500 dark:bg-slate-800 dark:border-slate-700">
                        <div class="flex items-center justify-between gap-3">
                            <div>
                                <p class="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">Số tài khoản</p>
                                <p id="accountCount" class="mt-2 text-3xl font-bold text-blue-600 dark:text-blue-400">0</p>
                                <p class="mt-1 text-xs text-slate-400 dark:text-slate-500">Tổng tài khoản đã cấu hình</p>
                            </div>
                            <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-300">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a5 5 0 00-10 0v2M5 9h14l-1 11H6L5 9z"/></svg>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="section-card mb-4 rounded-2xl border border-slate-200/80 p-4 dark:border-slate-700">
                    <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                        <div class="relative w-full md:max-w-md">
                            <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-slate-400 dark:text-slate-500">
                                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35M10.5 18a7.5 7.5 0 100-15 7.5 7.5 0 000 15z"/></svg>
                            </span>
                            <input id="accountSearchInput" type="text" oninput="handleSearchInput(this.value)" placeholder="Tìm theo tên tài khoản, ngân hàng hoặc số tài khoản..."
                                   class="w-full rounded-2xl border border-slate-200 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-700 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-200 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:focus:ring-teal-500/30">
                        </div>
                        <button type="button" onclick="clearSearch()" class="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-600 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700">
                            Xóa lọc
                        </button>
                    </div>
                </div>

                <div class="section-card overflow-hidden rounded-3xl border border-slate-200 shadow-sm dark:border-slate-700">
                    <div class="overflow-x-auto">
                        <table class="w-full">
                            <thead>
                                <tr class="border-b border-slate-100 bg-slate-50 dark:border-slate-700 dark:bg-slate-700/50">
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tên tài khoản</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Ngân hàng</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Số tài khoản</th>
                                    <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Trạng thái</th>
                                    <th class="px-4 py-3 text-center text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Hành động</th>
                                </tr>
                            </thead>
                            <tbody id="accountTableBody"></tbody>
                        </table>
                    </div>
                </div>

                <form id="accountsSubmitForm" action="PaymentController" method="post" class="hidden">
                    <input type="hidden" name="action" value="saveBankAccounts" />
                    <input type="hidden" name="accounts_data" id="accounts_data_submit" />
                    <input type="hidden" name="active_account_id" id="active_account_id_submit" />
                </form>
            </main>
            </div>
            </div>

    <div id="accountModal" class="modal-backdrop fixed inset-0 bg-slate-900/50 items-center justify-center p-4 z-50">
        <div class="w-full max-w-2xl rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 shadow-xl">
            <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
                <h3 id="accountModalTitle" class="text-lg font-semibold">Tạo tài khoản nhận tiền</h3>
                <button type="button" onclick="closePopup('accountModal')" class="text-slate-500 hover:text-slate-900 dark:hover:text-slate-100">✕</button>
            </div>
            <form class="p-6 space-y-4" onsubmit="saveAccount(event)">
                <input type="hidden" id="modalAccountId" value="" />
                <div>
                    <label class="block text-sm font-medium mb-1">Tên tài khoản *</label>
                    <input id="modalAccountName" type="text" class="w-full rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 px-3 py-2.5" placeholder="VD: ABC" required>
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1">Ngân hàng *</label>
                    <select id="modalBank" class="w-full rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 px-3 py-2.5" required></select>
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1">Số tài khoản *</label>
                    <input id="modalAccountNumber" type="text" class="w-full rounded-xl border border-slate-200 dark:border-slate-700 dark:bg-slate-800 px-3 py-2.5" required>
                </div>
                <div class="pt-2 flex justify-end gap-2">
                    <button type="button" onclick="closePopup('accountModal')" class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700">Đóng</button>
                    <button type="submit" class="px-4 py-2 rounded-xl bg-teal-600 text-white font-semibold">Lưu tài khoản</button>
                </div>
            </form>
        </div>
    </div>

    <div id="detailModal" class="modal-backdrop fixed inset-0 bg-slate-900/50 items-center justify-center p-4 z-50">
        <div class="w-full max-w-lg rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 shadow-xl">
            <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
                <h3 class="text-lg font-semibold">Chi tiết tài khoản nhận tiền</h3>
                <button type="button" onclick="closePopup('detailModal')" class="text-slate-500 hover:text-slate-900 dark:hover:text-slate-100">✕</button>
            </div>
            <div class="p-6 space-y-2 text-sm">
                <p><span class="font-semibold">Tên tài khoản:</span> <span id="detailName"></span></p>
                <p><span class="font-semibold">Ngân hàng:</span> <span id="detailBank"></span></p>
                <p><span class="font-semibold">Số tài khoản:</span> <span id="detailAccount"></span></p>
                <p><span class="font-semibold">Trạng thái:</span> <span id="detailStatus"></span></p>
            </div>
        </div>
    </div>

    <div id="deleteModal" class="modal-backdrop fixed inset-0 bg-slate-900/50 items-center justify-center p-4 z-50">
        <div class="w-full max-w-md rounded-3xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 shadow-xl">
            <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
                <h3 class="text-lg font-semibold">Xác nhận xoá tài khoản</h3>
                <button type="button" onclick="closePopup('deleteModal')" class="text-slate-500 hover:text-slate-900 dark:hover:text-slate-100">✕</button>
            </div>
            <div class="p-6 space-y-4 text-sm">
                <p class="text-slate-600 dark:text-slate-300">Bạn chắc chắn muốn xoá tài khoản <span id="deleteAccountName" class="font-semibold text-slate-900 dark:text-slate-100"></span>?</p>
                <div class="pt-2 flex justify-end gap-2">
                    <button type="button" onclick="closePopup('deleteModal')" class="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700">Huỷ</button>
                    <button type="button" onclick="confirmDeleteAccount()" class="px-4 py-2 rounded-xl bg-rose-600 text-white font-semibold hover:bg-rose-700">Xoá</button>
                </div>
            </div>
        </div>
    </div>

    <div id="noticeToast" class="notice-toast"></div>

    <script>
        const BANKS_VN = [
            { code: '970403', name: 'Sacombank' },
            { code: '970407', name: 'Techcombank' },
            { code: '970418', name: 'BIDV' },
            { code: '970405', name: 'Agribank' },
            { code: '970415', name: 'VietinBank' },
            { code: '970436', name: 'Vietcombank' },
            { code: '970422', name: 'MBBank' },
            { code: '970432', name: 'VPBank' },
            { code: '970423', name: 'TPBank' },
            { code: '970431', name: 'Eximbank' },
            { code: '970437', name: 'HDBank' },
            { code: '970416', name: 'ACB' },
            { code: '970454', name: 'VietCapitalBank (BVB)' },
            { code: '970428', name: 'Nam A Bank' },
            { code: '970439', name: 'Public Bank Vietnam' },
            { code: '970438', name: 'BaoViet Bank' },
            { code: '970429', name: 'Saigonbank' },
            { code: '970430', name: 'PGBank' },
            { code: '970424', name: 'Shinhan Bank Vietnam' },
            { code: '970425', name: 'ABBank' },
            { code: '970427', name: 'VietABank' },
            { code: '970434', name: 'Indovina Bank' },
            { code: '970441', name: 'VIB' },
            { code: '970433', name: 'VietBank' },
            { code: '970400', name: 'Saigon Commercial Bank (SCB)' },
            { code: '970452', name: 'KienlongBank' },
            { code: '970457', name: 'Woori Bank Vietnam' },
            { code: '970458', name: 'United Overseas Bank Vietnam (UOB)' },
            { code: '970448', name: 'OCB' },
            { code: '970449', name: 'LienVietPostBank (LPBank)' },
            { code: '970446', name: 'Co-opBank' },
            { code: '970412', name: 'PVcomBank' },
            { code: '970414', name: 'OceanBank (MBV)' },
            { code: '970419', name: 'NCB' },
            { code: '970440', name: 'SeABank' },
            { code: '970442', name: 'Hong Leong Bank Vietnam' },
            { code: '970443', name: 'SHB' },
            { code: '970444', name: 'CBBank (VNCB)' },
            { code: '970455', name: 'IBK Bank Hanoi Branch' },
            { code: '970456', name: 'Woori Bank Vietnam' },
            { code: '970462', name: 'Kookmin Bank Ho Chi Minh Branch' },
            { code: '970463', name: 'Kookmin Bank Hanoi Branch' },
            { code: '970467', name: 'Keb Hana Bank HCM Branch' },
            { code: '970468', name: 'Keb Hana Bank Hanoi Branch' },
            { code: '970499', name: 'Napas 247' },
            { code: '970406', name: 'DongA Bank' },
            { code: '970409', name: 'Bac A Bank' },
            { code: '970410', name: 'Standard Chartered Vietnam' },
            { code: '970411', name: 'PVcomBank' },
            { code: '970421', name: 'VRB' },
            { code: '970426', name: 'Maritime Bank (MSB)' },
            { code: '970435', name: 'Kookmin Bank' },
            { code: '970447', name: 'Sài Gòn - Hà Nội Bank (SHB)' },
            { code: '970453', name: 'VietBank' },
            { code: '970460', name: 'HSBC Vietnam' },
            { code: '970461', name: 'ANZ Vietnam' },
            { code: '970465', name: 'CIMB Vietnam' },
            { code: '970466', name: 'DBS Vietnam' },
            { code: '970470', name: 'Mizuho Bank HCM' },
            { code: '970471', name: 'Bank of China HCM Branch' }
        ];

        const state = {
            accounts: [],
            activeId: '',
            deleteId: '',
            searchKeyword: ''
        };

        function esc(text) {
            return (text || "").replace(/[&<>"']/g, function (ch) {
                if (ch === "&") return "&amp;";
                if (ch === "<") return "&lt;";
                if (ch === ">") return "&gt;";
                if (ch === '"') return "&quot;";
                return "&#39;";
            });
        }

        function openPopup(id) { document.getElementById(id).classList.add('open'); }
        function closePopup(id) { document.getElementById(id).classList.remove('open'); }

        let noticeTimer = null;
        function showNotice(message) {
            const toast = document.getElementById('noticeToast');
            if (!toast) return;
            toast.textContent = message || 'Có lỗi xảy ra.';
            toast.classList.add('open');
            if (noticeTimer) clearTimeout(noticeTimer);
            noticeTimer = setTimeout(function () {
                toast.classList.remove('open');
            }, 2600);
        }

        function isPlaceholderValue(value) {
            const v = (value || '').trim();
            return !v || v === '-' || v === '--' || v.toLowerCase() === 'null' || v.toLowerCase() === 'undefined';
        }

        function isValidAccount(a) {
            return !!(a
                && !isPlaceholderValue(String(a.id || ''))
                && !isPlaceholderValue(String(a.bin || ''))
                && !isPlaceholderValue(String(a.account || ''))
                && !isPlaceholderValue(String(a.name || '')));
        }

        function normalizeAccounts(accounts) {
            const cleaned = [];
            const usedIds = {};
            (accounts || []).forEach(function (a) {
                if (!isValidAccount(a)) return;
                const idRaw = String(a.id || '').trim();
                const id = usedIds[idRaw] ? ('A' + Date.now() + Math.floor(Math.random() * 1000)) : idRaw;
                usedIds[id] = true;
                cleaned.push({
                    id: id,
                    bin: String(a.bin || '').trim(),
                    account: String(a.account || '').trim(),
                    name: String(a.name || '').trim()
                });
            });
            return cleaned;
        }

        function parseAccounts(serialized) {
            if (!serialized || !serialized.trim()) return [];
            const parsed = serialized.split(';;').map(function (row) {
                const p = row.split('||');
                if (p.length < 4) return null;
                return {
                    id: (p[0] || '').trim(),
                    bin: (p[1] || '').trim(),
                    account: (p[2] || '').trim(),
                    name: (p[3] || '').trim()
                };
            }).filter(Boolean);
            return normalizeAccounts(parsed);
        }

        function serializeAccounts(accounts) {
            return (accounts || []).filter(isValidAccount).map(function (a) {
                return [a.id, a.bin, a.account, a.name]
                    .map(function (x) { return (x || '').replace(/\|\|/g, ' ').replace(/;;/g, ' ').trim(); })
                    .join('||');
            }).join(';;');
        }

        function accountById(id) {
            return state.accounts.find(function (a) { return a.id === id; }) || null;
        }

        function updateSummary() {
            document.getElementById('accountCount').textContent = state.accounts.length;
            const active = accountById(state.activeId);
            document.getElementById('activeAccountTitle').textContent = active ? '1' : '0';
            document.getElementById('activeAccountSub').textContent = active ? 'Đang bật để tạo QR' : 'Chưa có tài khoản hoạt động';
        }

        function normalizeText(value) {
            return (value || '')
                .toString()
                .toLowerCase()
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .trim();
        }

        function getFilteredAccounts() {
            const keyword = normalizeText(state.searchKeyword);
            if (!keyword) {
                return state.accounts.slice();
            }
            return state.accounts.filter(function (a) {
                const bank = bankNameByCode(a.bin);
                const status = a.id === state.activeId ? 'dang hoat dong' : 'du phong';
                return [a.name, bank, a.account, a.bin, status]
                    .some(function (field) { return normalizeText(field).includes(keyword); });
            });
        }

        function handleSearchInput(value) {
            state.searchKeyword = value || '';
            renderAccounts();
        }

        function clearSearch() {
            state.searchKeyword = '';
            const searchInput = document.getElementById('accountSearchInput');
            if (searchInput) {
                searchInput.value = '';
                searchInput.focus();
            }
            renderAccounts();
        }

        function renderAccounts() {
            const body = document.getElementById('accountTableBody');
            const filteredAccounts = getFilteredAccounts();

            if (!state.accounts.length) {
                body.innerHTML = '<tr><td colspan="5" class="px-6 py-14 text-center text-slate-400">'
                    + '<div class="mx-auto flex max-w-md flex-col items-center gap-3">'
                        + '<div class="flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 dark:bg-slate-700/60 dark:text-slate-500">'
                            + '<svg class="h-7 w-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a5 5 0 00-10 0v2M5 9h14l-1 11H6L5 9z"/></svg>'
                        + '</div>'
                        + '<div><p class="text-base font-semibold text-slate-700 dark:text-slate-200">Chưa có tài khoản nhận tiền</p><p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Tạo tài khoản đầu tiên để sử dụng khi sinh QR thanh toán.</p></div>'
                    + '</div>'
                + '</td></tr>';
                updateSummary();
                return;
            }

            if (!filteredAccounts.length) {
                body.innerHTML = '<tr><td colspan="5" class="px-6 py-12 text-center text-slate-500 dark:text-slate-400">Không tìm thấy tài khoản phù hợp với từ khóa "<span class="font-semibold">' + esc(state.searchKeyword) + '</span>".</td></tr>';
                updateSummary();
                return;
            }

            body.innerHTML = filteredAccounts.map(function (a) {
                const active = a.id === state.activeId;
                return '<tr class="border-b border-slate-50 transition-colors hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-700/50">'
                    + '<td class="px-4 py-3 align-top text-sm font-semibold text-slate-700 dark:text-slate-200">' + esc(a.name) + '</td>'
                    + '<td class="px-4 py-3 align-top text-sm text-slate-600 dark:text-slate-300">' + esc(bankNameByCode(a.bin)) + '</td>'
                    + '<td class="px-4 py-3 align-top text-sm text-slate-600 dark:text-slate-300">' + esc(a.account) + '</td>'
                    + '<td class="px-4 py-3 align-top">'
                        + (active
                            ? '<span class="px-2 py-1 rounded-lg text-xs bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">Đang hoạt động</span>'
                            : '<span class="px-2 py-1 rounded-lg text-xs bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300">Dự phòng</span>')
                    + '</td>'
                    + '<td class="px-4 py-3 align-top text-center">'
                        + '<div class="flex flex-wrap items-center justify-center gap-2">'
                            + '<button type="button" class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-blue-600 text-white transition-colors hover:bg-blue-700 shadow-sm shadow-blue-500/30" onclick="showDetail(\'' + esc(a.id) + '\')" title="Xem" aria-label="Xem chi tiết">'
                                + '<svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>'
                            + '</button>'
                            + '<button type="button" class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-amber-500 text-white transition-colors hover:bg-amber-600 shadow-sm shadow-amber-500/30" onclick="openAccountModal(\'edit\',\'' + esc(a.id) + '\')" title="Sửa" aria-label="Sửa tài khoản">'
                                + '<svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>'
                            + '</button>'
                            + '<button type="button" class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-rose-600 text-white transition-colors hover:bg-rose-700 shadow-sm shadow-rose-500/30" onclick="openDeleteModal(\'' + esc(a.id) + '\')" title="Xoá" aria-label="Xoá tài khoản">'
                                + '<svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M9 7V4a1 1 0 011-1h4a1 1 0 011 1v3M4 7h16"/></svg>'
                            + '</button>'
                            + (!active ? '<button type="button" class="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-emerald-600 text-white transition-colors hover:bg-emerald-700 shadow-sm shadow-emerald-500/30" onclick="setActive(\'' + esc(a.id) + '\')" title="Đặt hoạt động" aria-label="Đặt hoạt động">'
                                + '<svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg></button>' : '')
                        + '</div>'
                    + '</td>'
                    + '</tr>';
            }).join('');

            updateSummary();
        }

        function showDetail(id) {
            const a = accountById(id);
            if (!a) return;
            document.getElementById('detailName').textContent = a.name;
            document.getElementById('detailBank').textContent = bankNameByCode(a.bin);
            document.getElementById('detailAccount').textContent = a.account;
            document.getElementById('detailStatus').textContent = a.id === state.activeId ? 'Đang hoạt động' : 'Dự phòng';
            openPopup('detailModal');
        }

        function openAccountModal(mode, id) {
            const edit = mode === 'edit';
            const a = edit ? accountById(id) : null;
            document.getElementById('accountModalTitle').textContent = edit ? 'Sửa tài khoản nhận tiền' : 'Tạo tài khoản nhận tiền';
            document.getElementById('modalAccountId').value = edit ? a.id : '';
            document.getElementById('modalAccountName').value = edit ? a.name : '';
            ensureBankOptions();
            document.getElementById('modalBank').value = edit ? a.bin : (BANKS_VN.length ? BANKS_VN[0].code : '');
            document.getElementById('modalAccountNumber').value = edit ? a.account : '';
            openPopup('accountModal');
        }

        function saveAccount(e) {
            e.preventDefault();
            const id = document.getElementById('modalAccountId').value;
            const name = document.getElementById('modalAccountName').value.trim();
            const bin = document.getElementById('modalBank').value.trim();
            const account = document.getElementById('modalAccountNumber').value.trim();
            if (!name || !bin || !account) {
                showNotice('Vui lòng nhập đầy đủ thông tin tài khoản và chọn ngân hàng.');
                return;
            }

            if (id) {
                const target = accountById(id);
                if (!target) return;
                target.name = name;
                target.bin = bin;
                target.account = account;
            } else {
                state.accounts.push({ id: 'A' + Date.now(), name: name, bin: bin, account: account });
            }

            if (!state.activeId) {
                state.activeId = id || state.accounts[state.accounts.length - 1].id;
            }

            closePopup('accountModal');
            submitAccounts();
        }

        function openDeleteModal(id) {
            const a = accountById(id);
            if (!a) return;
            state.deleteId = id;
            document.getElementById('deleteAccountName').textContent = a.name || 'tài khoản này';
            openPopup('deleteModal');
        }

        function confirmDeleteAccount() {
            const id = state.deleteId;
            if (!id) return;
            if (state.accounts.length <= 1) {
                state.deleteId = '';
                closePopup('deleteModal');
                showNotice('Cần giữ ít nhất 1 tài khoản nhận tiền để tạo QR hoá đơn.');
                return;
            }
            state.accounts = state.accounts.filter(function (a) { return a.id !== id; });
            if (state.activeId === id) {
                state.activeId = state.accounts.length ? state.accounts[0].id : '';
            }
            state.deleteId = '';
            closePopup('deleteModal');
            submitAccounts();
        }

        function setActive(id) {
            if (!accountById(id)) return;
            state.activeId = id;
            submitAccounts();
        }

        function submitAccounts() {
            state.accounts = normalizeAccounts(state.accounts || []);
            if (!state.accounts.length) {
                showNotice('Phải có ít nhất một tài khoản nhận tiền hợp lệ.');
                renderAccounts();
                return;
            }
            if (!accountById(state.activeId)) {
                state.activeId = state.accounts[0].id;
            }
            document.getElementById('accounts_data_submit').value = serializeAccounts(state.accounts);
            document.getElementById('active_account_id_submit').value = state.activeId;
            document.getElementById('accountsSubmitForm').submit();
        }

        function bankNameByCode(code) {
            const b = BANKS_VN.find(function (x) { return x.code === code; });
            return b ? b.name : (code ? 'Ngân hàng khác' : '-');
        }

        function ensureBankOptions() {
            const select = document.getElementById('modalBank');
            if (!select || select.options.length > 0) {
                return;
            }
            BANKS_VN.forEach(function (b) {
                const opt = document.createElement('option');
                opt.value = b.code;
                opt.textContent = b.name;
                select.appendChild(opt);
            });
        }

        (function init() {
            ensureBankOptions();
            state.accounts = normalizeAccounts(parseAccounts('<%= bankAccountsDataJs %>'));
            state.activeId = '<%= bankActiveAccountIdJs %>';
            if (!state.accounts.length) {
                state.accounts = [{ id: 'A' + Date.now(), name: 'Tài khoản mặc định', bin: '970406', account: '1234567890' }];
            }
            if (!accountById(state.activeId)) {
                state.activeId = state.accounts.length ? state.accounts[0].id : '';
            }
            renderAccounts();
        })();
    </script>
</body>
</html>
