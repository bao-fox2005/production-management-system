package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.WorkOrderDAO;
import pms.model.ProductionLogDAO;
import pms.model.ItemDAO;
import pms.model.BillDAO;
import pms.model.BOMDAO;
import pms.model.DashboardDAO;
import pms.model.DashboardDTO;
import pms.model.WorkOrderDTO;
import pms.model.ProductionLogDTO;
import pms.model.ItemDTO;
import pms.model.BillDTO;
import pms.model.BOMDTO;
import pms.model.BOMDetailDTO;
import pms.utils.ExportService;

/**
 * ExportController – Servlet xuất dữ liệu ra file (CSV / HTML report).
 *
 * Đây là controller dùng chung cho tất cả nghiệp vụ export.
 * Mỗi action tương ứng với một loại dữ liệu khác nhau.
 * Dữ liệu được ghi trực tiếp vào HttpServletResponse
 * (không forward đến JSP) nên browser sẽ tải xuống file.
 *
 * Các loại export (tham số "type"):
 *   - workorders     : Xuất CSV danh sách Work Order
 *   - productionlogs : Xuất CSV nhật ký sản xuất
 *   - items          : Xuất CSV danh mục vật tư
 *   - bills          : Xuất CSV hóa đơn
 *   - bom            : Xuất CSV chi tiết một BOM cụ thể (cần bomId)
 *   - dashboard      : Xuất báo cáo dashboard dạng HTML
 */
public class ExportController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chung. Phân luồng theo tham số "type".
     * Mọi lỗi sẽ forward đến dashboard.jsp với thông báo lỗi.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy loại export, mặc định là "workorders"
        String type = request.getParameter("type");
        if (type == null) type = "workorders";

        try {
            switch (type) {
                case "workorders":
                    exportWorkOrders(request, response);      // Xuất CSV lệnh sản xuất
                    break;
                case "productionlogs":
                    exportProductionLogs(request, response);  // Xuất CSV nhật ký sản xuất
                    break;
                case "items":
                    exportItems(request, response);            // Xuất CSV danh mục vật tư
                    break;
                case "bills":
                    exportBills(request, response);            // Xuất CSV hóa đơn
                    break;
                case "bom":
                    exportBom(request, response);              // Xuất CSV một BOM cụ thể
                    break;
                case "dashboard":
                    exportDashboard(request, response);        // Xuất báo cáo dashboard HTML
                    break;
                default:
                    response.sendRedirect("DashboardController"); // Loại không xác định
                    break;
            }
        } catch (Exception e) {
            // Lỗi xuất file → thông báo và forward về dashboard
            e.printStackTrace();
            request.setAttribute("error", "Loi xuat file: " + e.getMessage());
            request.getRequestDispatcher("dashboard.jsp").forward(request, response);
        }
    }

    /**
     * Xuất tất cả Work Order ra file CSV.
     * ExportService sẽ set Content-Disposition header để browser tải file.
     */
    private void exportWorkOrders(HttpServletRequest request, HttpServletResponse response) throws IOException {
        WorkOrderDAO dao = new WorkOrderDAO();
        List<WorkOrderDTO> list = dao.getAllWorkOrders(); // Lấy tất cả WO
        ExportService.exportWorkOrdersToCsv(list, response); // Ghi CSV vào response
    }

    /**
     * Xuất tất cả nhật ký sản xuất ra file CSV.
     * Bao gồm toàn bộ log của mọi công nhân (không phân quyền tại đây).
     */
    private void exportProductionLogs(HttpServletRequest request, HttpServletResponse response) throws IOException {
        ProductionLogDAO dao = new ProductionLogDAO();
        List<ProductionLogDTO> list = dao.getAllLogs(); // Lấy tất cả nhật ký
        ExportService.exportProductionLogsToCsv(list, response);
    }

    /**
     * Xuất danh mục vật tư (Items) ra file CSV.
     */
    private void exportItems(HttpServletRequest request, HttpServletResponse response) throws IOException {
        ItemDAO dao = new ItemDAO();
        List<ItemDTO> list = dao.getAllItems(); // Lấy tất cả vật tư
        ExportService.exportItemsToCsv(list, response);
    }

    /**
     * Xuất danh sách hóa đơn ra file CSV.
     */
    private void exportBills(HttpServletRequest request, HttpServletResponse response) throws IOException {
        BillDAO dao = new BillDAO();
        List<BillDTO> list = dao.getAllBill(); // Lấy tất cả hóa đơn
        ExportService.exportBillsToCsv(list, response);
    }

    /**
     * Xuất chi tiết một BOM cụ thể ra file CSV.
     * Nếu không có bomId hoặc BOM không tồn tại → redirect về danh sách BOM.
     *
     * @param request Chứa tham số "bomId"
     */
    private void exportBom(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String sBomId = request.getParameter("bomId"); // ID BOM cần xuất

        if (sBomId == null || sBomId.trim().isEmpty()) {
            response.sendRedirect("MainController?action=listBOM"); // Không có ID → về danh sách
            return;
        }

        int bomId = Integer.parseInt(sBomId);
        BOMDAO dao = new BOMDAO();
        BOMDTO bom = dao.getBOMById(bomId); // Lấy BOM với danh sách chi tiết

        if (bom == null) {
            response.sendRedirect("MainController?action=listBOM"); // BOM không tồn tại
            return;
        }

        List<BOMDetailDTO> details = bom.getDetails(); // Danh sách nguyên vật liệu của BOM
        ExportService.exportBomToCsv(bom, details, response);
    }

    /**
     * Xuất báo cáo Dashboard tổng hợp dạng file HTML.
     * Bao gồm: số WO, doanh thu, tồn kho thấp, nhật ký sản xuất…
     */
    private void exportDashboard(HttpServletRequest request, HttpServletResponse response) throws IOException {
        DashboardDAO dao    = new DashboardDAO();
        DashboardDTO data   = dao.loadDashboardStats();           // Tải số liệu dashboard
        String html         = ExportService.generateDashboardHtml(data); // Tạo HTML report
        ExportService.exportDashboardReport(new StringBuilder(html), response); // Ghi file HTML vào response
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
        return "Export Controller";
    }
}
