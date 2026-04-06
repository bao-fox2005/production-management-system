package pms.utils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import javax.servlet.http.HttpServletResponse;
import pms.model.WorkOrderDTO;
import pms.model.ProductionLogDTO;
import pms.model.ItemDTO;
import pms.model.BillDTO;
import pms.model.BOMDTO;
import pms.model.BOMDetailDTO;

public class ExportService {

    private static final String CSV_SEPARATOR = ",";
    private static final SimpleDateFormat DATE_FMT = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    private static final SimpleDateFormat FILE_DATE_FMT = new SimpleDateFormat("yyyyMMdd_HHmmss");

    public static void exportWorkOrdersToCsv(List<WorkOrderDTO> list, HttpServletResponse response) throws IOException {
        String filename = "workorders_" + FILE_DATE_FMT.format(new Date()) + ".csv";
        String csv = buildWorkOrderCsv(list);
        writeResponse(response, csv, filename, "text/csv;charset=UTF-8");
    }

    public static void exportProductionLogsToCsv(List<ProductionLogDTO> list, HttpServletResponse response) throws IOException {
        String filename = "productionlogs_" + FILE_DATE_FMT.format(new Date()) + ".csv";
        String csv = buildProductionLogCsv(list);
        writeResponse(response, csv, filename, "text/csv;charset=UTF-8");
    }

    public static void exportItemsToCsv(List<ItemDTO> list, HttpServletResponse response) throws IOException {
        String filename = "items_" + FILE_DATE_FMT.format(new Date()) + ".csv";
        String csv = buildItemCsv(list);
        writeResponse(response, csv, filename, "text/csv;charset=UTF-8");
    }

    public static void exportBillsToCsv(List<BillDTO> list, HttpServletResponse response) throws IOException {
        String filename = "bills_" + FILE_DATE_FMT.format(new Date()) + ".csv";
        String csv = buildBillCsv(list);
        writeResponse(response, csv, filename, "text/csv;charset=UTF-8");
    }

    public static void exportBomToCsv(BOMDTO bom, List<BOMDetailDTO> details, HttpServletResponse response) throws IOException {
        String filename = "bom_" + bom.getBomId() + "_" + FILE_DATE_FMT.format(new Date()) + ".csv";
        String csv = buildBomCsv(bom, details);
        writeResponse(response, csv, filename, "text/csv;charset=UTF-8");
    }

    public static void exportDashboardReport(StringBuilder htmlContent, HttpServletResponse response) throws IOException {
        String filename = "dashboard_report_" + FILE_DATE_FMT.format(new Date()) + ".html";
        writeResponse(response, htmlContent.toString(), filename, "text/html;charset=UTF-8");
    }

    private static String buildWorkOrderCsv(List<WorkOrderDTO> list) {
        StringBuilder sb = new StringBuilder();
        sb.append("\uFEFF");
        sb.append("WO_ID,San Pham,Routing,So Luong,Trang Thai,Ngay Bat Dau,Ngay Ket Thuc,Ghi Chu\n");
        for (WorkOrderDTO wo : list) {
            sb.append(wo.getWo_id()).append(CSV_SEPARATOR);
            sb.append(escCsv(wo.getProductName())).append(CSV_SEPARATOR);
            sb.append(escCsv(wo.getRoutingName())).append(CSV_SEPARATOR);
            sb.append(wo.getOrder_quantity()).append(CSV_SEPARATOR);
            sb.append(escCsv(wo.getStatus())).append(CSV_SEPARATOR);
            sb.append(escCsv(wo.getStart_date())).append(CSV_SEPARATOR);
            sb.append(escCsv(wo.getDue_date())).append(CSV_SEPARATOR);
            sb.append(escCsv(wo.getNotes())).append("\n");
        }
        return sb.toString();
    }

    private static String buildProductionLogCsv(List<ProductionLogDTO> list) {
        StringBuilder sb = new StringBuilder();
        sb.append("\uFEFF");
        sb.append("Log_ID,WO_ID,Cong Doan,Nguoi Thuc Hien,So Luong,So Luong Loi,Lo,Ngay\n");
        for (ProductionLogDTO log : list) {
            sb.append(log.getLogId()).append(CSV_SEPARATOR);
            sb.append(log.getWoId()).append(CSV_SEPARATOR);
            sb.append(escCsv(log.getStepName())).append(CSV_SEPARATOR);
            sb.append(escCsv(log.getWorkerName())).append(CSV_SEPARATOR);
            sb.append(log.getQuantityDone()).append(CSV_SEPARATOR);
            sb.append(log.getQuantityDefective()).append(CSV_SEPARATOR);
            sb.append(escCsv(log.getDefectName())).append(CSV_SEPARATOR);
            String dateStr = log.getLogDate() != null ? DATE_FMT.format(log.getLogDate()) : "";
            sb.append(dateStr).append("\n");
        }
        return sb.toString();
    }

    private static String buildItemCsv(List<ItemDTO> list) {
        StringBuilder sb = new StringBuilder();
        sb.append("\uFEFF");
        sb.append("ID,Ten,Loai,So Luong Ton,Don Vi,Toi Thieu,Muc Toi Thieu,Mo Ta\n");
        for (ItemDTO item : list) {
            sb.append(item.getItemID()).append(CSV_SEPARATOR);
            sb.append(escCsv(item.getItemName())).append(CSV_SEPARATOR);
            sb.append(escCsv(item.getItemType())).append(CSV_SEPARATOR);
            sb.append(item.getStockQuantity()).append(CSV_SEPARATOR);
            sb.append(escCsv(item.getUnit())).append(CSV_SEPARATOR);
            sb.append(item.getMinStockLevel()).append(CSV_SEPARATOR);
            sb.append(escCsv(item.getDescription())).append("\n");
        }
        return sb.toString();
    }

    private static String buildBillCsv(List<BillDTO> list) {
        StringBuilder sb = new StringBuilder();
        sb.append("\uFEFF");
        sb.append("Bill_ID,WO_ID,Customer_ID,Tong Tien,Ngay Lap\n");
        for (BillDTO bill : list) {
            sb.append(bill.getBill_id()).append(CSV_SEPARATOR);
            sb.append(bill.getWo_id()).append(CSV_SEPARATOR);
            sb.append(bill.getCustomer_id()).append(CSV_SEPARATOR);
            sb.append(String.format("%.2f", bill.getTotal_amount())).append(CSV_SEPARATOR);
            String billDateStr = bill.getBill_date() != null ? DATE_FMT.format(bill.getBill_date()) : "";
            sb.append(billDateStr).append("\n");
        }
        return sb.toString();
    }

    private static String buildBomCsv(BOMDTO bom, List<BOMDetailDTO> details) {
        StringBuilder sb = new StringBuilder();
        sb.append("\uFEFF");
        sb.append("=== BOM Report ===\n");
        sb.append("BOM_ID,San Pham,Phien Ban,Trang Thai,Ngay Tao,Ghi Chu\n");
        sb.append(bom.getBomId()).append(CSV_SEPARATOR);
        sb.append(escCsv(bom.getProductName())).append(CSV_SEPARATOR);
        sb.append(escCsv(bom.getBomVersion())).append(CSV_SEPARATOR);
        sb.append(escCsv(bom.getStatus())).append(CSV_SEPARATOR);
        String bomDateStr = bom.getCreatedDate() != null ? DATE_FMT.format(bom.getCreatedDate()) : "";
        sb.append(bomDateStr).append(CSV_SEPARATOR);
        sb.append(escCsv(bom.getNotes())).append("\n\n");
        sb.append("=== Chi Tiet Nguyen Lieu ===\n");
        sb.append("STT,Nguyen Lieu,So Luong,Don Vi,Huy Choi (%),Ghi Chu\n");
        if (details != null) {
            int idx = 1;
            for (BOMDetailDTO d : details) {
                sb.append(idx++).append(CSV_SEPARATOR);
                sb.append(escCsv(d.getMaterialName())).append(CSV_SEPARATOR);
                sb.append(d.getQuantityRequired()).append(CSV_SEPARATOR);
                sb.append(escCsv(d.getUnit())).append(CSV_SEPARATOR);
                sb.append(d.getWastePercent()).append(CSV_SEPARATOR);
                sb.append(escCsv(d.getNotes())).append("\n");
            }
        }
        return sb.toString();
    }

    public static String generateDashboardHtml(pms.model.DashboardDTO data) {
        StringBuilder sb = new StringBuilder();
        sb.append("<!DOCTYPE html>\n<html lang='vi'>\n<head>\n<meta charset='UTF-8'>\n");
        sb.append("<title>Bao Cao Dashboard - ").append(DATE_FMT.format(new Date())).append("</title>\n");
        sb.append("<style>\n");
        sb.append("body{font-family:Arial,sans-serif;margin:24px;}\n");
        sb.append("h1{color:#1e40af;border-bottom:2px solid #1e40af;padding-bottom:8px;}\n");
        sb.append("h2{color:#374151;margin-top:24px;}\n");
        sb.append(".kpi-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;margin:16px 0;}\n");
        sb.append(".kpi-card{background:#f8fafc;border:1px solid #e2e8f0;border-radius:12px;padding:16px;}\n");
        sb.append(".kpi-label{font-size:12px;color:#6b7280;text-transform:uppercase;}\n");
        sb.append(".kpi-value{font-size:28px;font-weight:bold;color:#1e293b;}\n");
        sb.append("table{width:100%;border-collapse:collapse;margin:16px 0;}\n");
        sb.append("th,td{border:1px solid #e5e7eb;padding:10px;text-align:left;}\n");
        sb.append("th{background:#1e40af;color:white;}\n");
        sb.append("tr:nth-child(even){background:#f9fafb;}\n");
        sb.append(".footer{text-align:center;color:#9ca3af;font-size:12px;margin-top:32px;}\n");
        sb.append("</style>\n</head>\n<body>\n");
        sb.append("<h1>Bao Cao Tong Quan He Thong PMS</h1>\n");
        sb.append("<p>Ngay tao: ").append(DATE_FMT.format(new Date())).append("</p>\n");
        sb.append("<h2>Tong Quan KPI</h2>\n<div class='kpi-grid'>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Tong Lenh San Xuat</div><div class='kpi-value'>").append(data.getTotalWorkOrders()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Dang San Xuat</div><div class='kpi-value'>").append(data.getWorkOrdersInProgress()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Hoan Thanh</div><div class='kpi-value'>").append(data.getWorkOrdersDone()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Ti Le Hoan Thanh</div><div class='kpi-value'>").append(data.getCompletionRate()).append("%</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Tong Thu (Thang)</div><div class='kpi-value'>").append(data.getFormattedRevenue()).append(" VND</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Hoa Don</div><div class='kpi-value'>").append(data.getTotalBills()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Vat Tu / San Pham</div><div class='kpi-value'>").append(data.getTotalItems()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Het Hang / Sac Thap</div><div class='kpi-value'>").append(data.getLowStockItems()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Nguoi Dung</div><div class='kpi-value'>").append(data.getTotalUsers()).append("</div></div>\n");
        sb.append("<div class='kpi-card'><div class='kpi-label'>Don Dat Hang</div><div class='kpi-value'>").append(data.getTotalPurchaseOrders()).append("</div></div>\n");
        sb.append("</div>\n");
        sb.append("<h2>Lenh San Xuat Gan Day</h2>\n<table>\n<tr><th>ID</th><th>San Pham</th><th>Routing</th><th>So Luong</th><th>Trang Thai</th></tr>\n");
        if (data.getRecentWorkOrders() != null) {
            for (WorkOrderDTO wo : data.getRecentWorkOrders()) {
                sb.append("<tr><td>#").append(wo.getWo_id()).append("</td><td>")
                    .append(escHtml(wo.getProductName() != null ? wo.getProductName() : "-"))
                    .append("</td><td>")
                    .append(escHtml(wo.getRoutingName() != null ? wo.getRoutingName() : "-"))
                    .append("</td><td>").append(wo.getOrder_quantity())
                    .append("</td><td>").append(escHtml(wo.getStatus() != null ? wo.getStatus() : "-"))
                    .append("</td></tr>\n");
            }
        }
        sb.append("</table>\n");
        sb.append("<h2>Nhat Ky San Xuat Gan Day</h2>\n<table>\n<tr><th>ID</th><th>WO</th><th>Cong Doan</th><th>Nguoi Thuc Hien</th><th>Ngay</th></tr>\n");
        if (data.getRecentLogs() != null) {
            for (ProductionLogDTO log : data.getRecentLogs()) {
                sb.append("<tr><td>#").append(log.getLogId()).append("</td><td>#")
                    .append(log.getWoId()).append("</td><td>")
                    .append(escHtml(log.getStepName() != null ? log.getStepName() : "-"))
                    .append("</td><td>")
                    .append(escHtml(log.getWorkerName() != null ? log.getWorkerName() : "-"))
                    .append("</td><td>");
                    String logDateStr = log.getLogDate() != null ? DATE_FMT.format(log.getLogDate()) : "-";
                    sb.append(logDateStr).append("</td></tr>\n");
            }
        }
        sb.append("</table>\n");
        sb.append("<div class='footer'>He thong quan ly san xuat PMS - Tu dong tao boi ExportService</div>\n");
        sb.append("</body>\n</html>");
        return sb.toString();
    }

    private static void writeResponse(HttpServletResponse response, String content, String filename, String contentType) throws IOException {
        response.setContentType(contentType);
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        response.setContentLength(content.getBytes("UTF-8").length);
        response.getWriter().write(content);
        response.getWriter().flush();
    }

    private static String escCsv(String s) {
        if (s == null) return "";
        if (s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }

    private static String escHtml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}
