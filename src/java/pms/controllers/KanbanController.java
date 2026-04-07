package pms.controllers;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.WorkOrderDAO;
import pms.model.WorkOrderDTO;
import pms.model.BOMDAO;
import pms.model.InventoryLogDAO;
import pms.utils.NotificationService;

/**
 * KanbanController – Servlet hiển thị bảng Kanban theo trạng thái Work Order.
 *
 * Bảng Kanban chia Work Order thành 4 cột theo trạng thái:
 *   - New      : Bao gồm New, WaitMaterial, Ready
 *   - InProgress: Đang sản xuất
 *   - Done     : Hoàn thành (Done, Completed)
 *   - Cancelled: Đã hủy
 *
 * Chức năng:
 *   - view        : Hiển thị kanban với bộ lọc keyword và khoảng ngày
 *   - updateStatus: Cập nhật trạng thái WO bằng kéo thả (AJAX, trả plain text OK/FAIL)
 *
 * Khi WO chuyển sang "Done":
 *   - Tự động trừ kho nguyên vật liệu theo BOM (autoDeductForWorkOrder)
 *   - Gửi thông báo hoàn thành (NotificationService)
 *
 * Lọc ngày thông minh:
 *   - WO chưa hoàn thành → lọc theo ngày tạo (created_date)
 *   - WO đã hoàn thành   → ưu tiên lọc theo ngày hoàn thành (completed_date)
 */
public class KanbanController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chung.
     * updateStatus xử lý trực tiếp (trả text/plain), view thì forward đến kanban.jsp.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        if (action == null) action = "view";

        // updateStatus được xử lý trước trong switch để return sớm
        if ("updateStatus".equals(action)) {
            updateStatus(request, response); // Xử lý AJAX kéo thả
            return;
        }

        switch (action) {
            case "view":
            default:
                viewKanban(request); // Tải dữ liệu cho bảng Kanban
                break;
        }

        request.getRequestDispatcher("kanban.jsp").forward(request, response);
    }

    /**
     * Tải và phân loại Work Order vào 4 cột Kanban, hỗ trợ lọc keyword và khoảng ngày.
     *
     * Lọc ngày thông minh (Smart Date Filter):
     *   - WO chưa xong → lọc theo ngày tạo
     *   - WO đã xong   → lọc theo ngày hoàn thành (fallback về ngày tạo nếu completed_date trống)
     *
     * Đếm overdueCount: số WO chưa xong nhưng đã quá due_date.
     *
     * @param request Chứa tham số "keyword", "fromDate", "toDate"
     */
    private void viewKanban(HttpServletRequest request) {
        WorkOrderDAO dao = new WorkOrderDAO();
        List<WorkOrderDTO> all = dao.getAllWorkOrders(); // Lấy tất cả WO

        // Đọc bộ lọc từ request
        String keyword  = request.getParameter("keyword");
        String fromDate = request.getParameter("fromDate");
        String toDate   = request.getParameter("toDate");

        // Khởi tạo 4 danh sách cho 4 cột Kanban
        List<WorkOrderDTO> newList        = new ArrayList<>();
        List<WorkOrderDTO> inProgressList = new ArrayList<>();
        List<WorkOrderDTO> doneList       = new ArrayList<>();
        List<WorkOrderDTO> cancelledList  = new ArrayList<>();

        int overdueCount = 0;                                       // Số WO đã quá hạn
        long now         = System.currentTimeMillis();              // Thời điểm hiện tại (ms)
        SimpleDateFormat sdfDb = new SimpleDateFormat("yyyy-MM-dd"); // Định dạng ngày trong DB

        for (WorkOrderDTO wo : all) {
            boolean match = true; // Giả sử WO này thỏa bộ lọc

            // ---- Bộ lọc 1: Keyword ----
            if (keyword != null && !keyword.trim().isEmpty()) {
                String kw   = keyword.toLowerCase();
                String name = wo.getProductName() != null ? wo.getProductName().toLowerCase() : "";
                // Khớp khi ID hoặc tên sản phẩm chứa keyword
                if (!String.valueOf(wo.getWo_id()).contains(kw) && !name.contains(kw)) {
                    match = false;
                }
            }

            // ---- Bộ lọc 2: Khoảng ngày (Smart Date Filter) ----
            if (match) {
                boolean hasFromDate = fromDate != null && !fromDate.trim().isEmpty();
                boolean hasToDate   = toDate   != null && !toDate.trim().isEmpty();

                if (hasFromDate || hasToDate) {
                    // Mặc định so sánh theo ngày tạo
                    String dateToCompare = wo.getCreated_date();

                    // WO đã hoàn thành → ưu tiên ngày hoàn thành
                    if ("Done".equalsIgnoreCase(wo.getStatus()) || "Completed".equalsIgnoreCase(wo.getStatus())) {
                        dateToCompare = wo.getCompleted_date();
                        // Fallback về ngày tạo nếu chưa có ngày hoàn thành
                        if (dateToCompare == null || dateToCompare.trim().isEmpty()) {
                            dateToCompare = wo.getCreated_date();
                        }
                    }

                    if (dateToCompare == null || dateToCompare.trim().isEmpty()) {
                        match = false; // Không có ngày → loại bỏ
                    } else {
                        try {
                            // Cắt chuỗi ngày về dạng yyyy-MM-dd (bỏ phần giờ)
                            String dateStr = dateToCompare.trim();
                            if (dateStr.length() >= 10) {
                                dateStr = dateStr.substring(0, 10);
                            }
                            Date targetDate = sdfDb.parse(dateStr);

                            // So sánh với fromDate (ngày bắt đầu)
                            if (hasFromDate) {
                                Date from = sdfDb.parse(fromDate);
                                if (targetDate.getTime() < from.getTime()) match = false;
                            }
                            // So sánh với toDate (ngày kết thúc – bao gồm cả ngày đó đến 23:59:59)
                            if (hasToDate) {
                                Date to = sdfDb.parse(toDate);
                                to.setHours(23); to.setMinutes(59); to.setSeconds(59); // Hết ngày
                                if (targetDate.getTime() > to.getTime()) match = false;
                            }
                        } catch (Exception e) {
                            match = false; // Không parse được ngày → loại bỏ
                        }
                    }
                }
            }

            if (!match) continue; // Bỏ qua WO không khớp bộ lọc

            // ---- Đếm WO quá hạn ----
            // Chỉ đếm WO chưa hoàn thành và chưa hủy
            if (wo.getDue_date() != null && !wo.getDue_date().isEmpty()
                    && !"Done".equalsIgnoreCase(wo.getStatus())
                    && !"Cancelled".equalsIgnoreCase(wo.getStatus())) {
                try {
                    SimpleDateFormat sdfFull = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                    // Chuẩn hóa chuỗi due_date (có thể có ".0" hoặc "T" dạng ISO)
                    Date dueFull = sdfFull.parse(wo.getDue_date().endsWith(".0")
                            ? wo.getDue_date().substring(0, 19)
                            : wo.getDue_date().replace("T", " "));
                    if (dueFull.getTime() < now) {
                        overdueCount++; // WO đã quá hạn
                    }
                } catch (Exception e) { /* Bỏ qua lỗi parse */ }
            }

            // ---- Phân loại vào cột Kanban ----
            String status = wo.getStatus();
            if ("New".equalsIgnoreCase(status) || "WaitMaterial".equalsIgnoreCase(status)
                    || "Ready".equalsIgnoreCase(status)) {
                newList.add(wo);          // Cột "Mới" – gồm cả chờ vật liệu và sẵn sàng
            } else if ("InProgress".equalsIgnoreCase(status) || "In Progress".equalsIgnoreCase(status)) {
                inProgressList.add(wo);  // Cột "Đang sản xuất"
            } else if ("Done".equalsIgnoreCase(status) || "Completed".equalsIgnoreCase(status)) {
                doneList.add(wo);         // Cột "Hoàn thành"
            } else if ("Cancelled".equalsIgnoreCase(status)) {
                cancelledList.add(wo);   // Cột "Đã hủy"
            }
        }

        // Đưa các danh sách và bộ lọc vào request để JSP hiển thị
        request.setAttribute("newList",        newList);
        request.setAttribute("inProgressList", inProgressList);
        request.setAttribute("doneList",       doneList);
        request.setAttribute("cancelledList",  cancelledList);
        request.setAttribute("overdueCount",   overdueCount);   // JSP hiện badge cảnh báo
        request.setAttribute("keyword",        keyword  != null ? keyword  : "");
        request.setAttribute("fromDate",       fromDate != null ? fromDate : "");
        request.setAttribute("toDate",         toDate   != null ? toDate   : "");
    }

    /**
     * Cập nhật trạng thái WO qua AJAX (kéo thả thẻ Kanban).
     * Phản hồi text/plain: "OK" hoặc "FAIL".
     *
     * Khi WO chuyển sang "Done":
     *   1. Tự động trừ kho nguyên vật liệu theo BOM (autoDeductForWorkOrder)
     *   2. Gửi thông báo hoàn thành tới NotificationService
     *
     * @param request  Chứa "id" (wo_id) và "status" (trạng thái mới)
     * @param response HttpServletResponse để ghi text/plain
     */
    private void updateStatus(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            int woId      = Integer.parseInt(request.getParameter("id")); // ID WO cần cập nhật
            String newStatus = request.getParameter("status");             // Trạng thái mới

            WorkOrderDAO woDao = new WorkOrderDAO();
            WorkOrderDTO wo   = woDao.searchById(woId);          // Lấy WO hiện tại

            // Cập nhật chỉ cột status (không đổi dữ liệu khác)
            boolean updated = woDao.updateWorkOrderStatusOnly(woId, newStatus);

            if (updated && "Done".equals(newStatus) && wo != null) {
                // WO vừa hoàn thành → tự động trừ kho nguyên vật liệu
                BOMDAO bomDao                = new BOMDAO();
                InventoryLogDAO invDao       = new InventoryLogDAO();
                invDao.autoDeductForWorkOrder(
                        woId,
                        wo.getProduct_item_id(), // ID sản phẩm đầu ra
                        wo.getOrder_quantity(),   // Số lượng sản xuất
                        1,                        // Hệ số multiplier (thường là 1)
                        bomDao
                );

                // Gửi thông báo hoàn thành WO
                NotificationService.notifyWorkOrderCompleted(
                        woId,
                        wo.getProductName() != null ? wo.getProductName() : "WO#" + woId
                );
            }

            // Phản hồi kết quả cho JavaScript
            response.setContentType("text/plain");
            response.getWriter().write(updated ? "OK" : "FAIL");

        } catch (Exception e) {
            // Lỗi → trả HTTP 500 với message lỗi
            response.setStatus(500);
            response.getWriter().write("ERROR: " + e.getMessage());
        }
    }

    /** Xử lý HTTP GET */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Kanban Controller";
    }
}