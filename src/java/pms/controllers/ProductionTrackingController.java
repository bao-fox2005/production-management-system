package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import pms.model.ProductionLogDAO;
import pms.model.ProductionLogDTO;
import pms.model.QcInspectionDAO;
import pms.model.QcInspectionDTO;
import pms.model.DefectDAO;
import pms.model.RoutingStepDAO;
import pms.model.WorkOrderDAO;
import pms.model.UserDTO;
import pms.utils.NotificationService;

/**
 * ProductionTrackingController - Unified Controller for Production Logs and Quality Control
 */
public class ProductionTrackingController extends HttpServlet {

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        try {
            switch (action) {
                case "list":
                    listTracking(request, response);
                    return;
                case "addLog":
                    addProductionLog(request, response);
                    return;
                case "addQc":
                    addQcInspection(request, response);
                    return;
                case "deleteLog":
                    deleteLog(request, response);
                    return;
                case "deleteQc":
                    deleteQc(request, response);
                    return;
                default:
                    listTracking(request, response);
                    return;
            }
        } catch (Exception e) {
            throw new ServletException("Error in ProductionTrackingController", e);
        }
    }

    private void listTracking(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        UserDTO user = session != null ? (UserDTO) session.getAttribute("user") : null;
        
        String userRole = user != null ? user.getRole() : "";
        int currentUserId = user != null ? user.getId() : 0;
        
        boolean isAdmin = "admin".equalsIgnoreCase(userRole);
        boolean isWorker = "employee".equalsIgnoreCase(userRole)
                || "worker".equalsIgnoreCase(userRole)
                || "user".equalsIgnoreCase(userRole);
                
        // Fetch Production Logs
        ProductionLogDAO logDao = new ProductionLogDAO();
        if (isAdmin) {
            request.setAttribute("listLogs", logDao.getAllLogs());
        } else if (isWorker) {
            java.util.List<ProductionLogDTO> allLogs = logDao.getAllLogs();
            java.util.List<ProductionLogDTO> workerLogs = new java.util.ArrayList<>();
            for (ProductionLogDTO log : allLogs) {
                if (log.getWorkerUserId() == currentUserId) {
                    workerLogs.add(log);
                }
            }
            request.setAttribute("listLogs", workerLogs);
        } else {
            request.setAttribute("listLogs", new java.util.ArrayList<>());
        }

        // Fetch QC Inspections
        QcInspectionDAO qcDao = new QcInspectionDAO();
        String filter = request.getParameter("filter");
        if ("failed".equalsIgnoreCase(filter)) {
            request.setAttribute("inspections", qcDao.getInspectionsByResult("FAIL"));
        } else if ("passed".equalsIgnoreCase(filter)) {
            request.setAttribute("inspections", qcDao.getInspectionsByResult("PASS"));
        } else {
            request.setAttribute("inspections", qcDao.getAllInspections());
        }
        
        request.setAttribute("totalInspected", qcDao.getTotalInspected());
        request.setAttribute("totalFailed", qcDao.getTotalFailed());
        request.setAttribute("passRate", qcDao.getOverallPassRate());
        
        // Fetch Common Dropdowns
        request.setAttribute("listWO", new WorkOrderDAO().getAllWorkOrders());
        request.setAttribute("listSteps", new RoutingStepDAO().getAllRoutingStep());
        request.setAttribute("listDefects", new DefectDAO().getAllDefects());
        request.setAttribute("isAdmin", isAdmin);
        request.setAttribute("isWorker", isWorker);

        request.getRequestDispatcher("production-tracking.jsp").forward(request, response);
    }

    private void addProductionLog(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        HttpSession session = request.getSession(false);
        UserDTO user = session != null ? (UserDTO) session.getAttribute("user") : null;
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=log&error="
                    + java.net.URLEncoder.encode("Session expired", "UTF-8"));
            return;
        }

        try {
            int woId = Integer.parseInt(request.getParameter("workOrderId"));
            int stepId = Integer.parseInt(request.getParameter("stepId"));
            int quantityDone = Integer.parseInt(request.getParameter("quantityDone"));
            int quantityDefective = Integer.parseInt(request.getParameter("quantityDefective"));
            int defectId = Integer.parseInt(request.getParameter("defectId"));

            ProductionLogDTO log = new ProductionLogDTO();
            log.setWoId(woId);
            log.setStepId(stepId);
            log.setWorkerUserId(user.getId());
            log.setQuantityDone(quantityDone);
            log.setQuantityDefective(quantityDefective);
            log.setDefectId(defectId > 0 ? defectId : null);
            log.setLogDate(new java.sql.Date(System.currentTimeMillis()));

            new ProductionLogDAO().insertLog(log);
            
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=log&msg="
                    + java.net.URLEncoder.encode("Đã thêm báo cáo sản xuất", "UTF-8"));
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=log&error="
                    + java.net.URLEncoder.encode("Lỗi lưu báo cáo: " + e.getMessage(), "UTF-8"));
        }
    }

    private void addQcInspection(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        HttpSession session = request.getSession(false);
        UserDTO user = session != null ? (UserDTO) session.getAttribute("user") : null;
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&error="
                    + java.net.URLEncoder.encode("Session expired", "UTF-8"));
            return;
        }

        try {
            int woId = Integer.parseInt(request.getParameter("woId"));
            int stepId = Integer.parseInt(request.getParameter("stepId"));
            String result = request.getParameter("inspectionResult");
            int inspected = Integer.parseInt(request.getParameter("quantityInspected"));
            int passed = Integer.parseInt(request.getParameter("quantityPassed"));
            int failed = Math.max(0, inspected - passed);
            String notes = request.getParameter("notes");
            String defectIdRaw = request.getParameter("defectId");

            if (inspected <= 0 || passed < 0 || passed > inspected || result == null) {
                response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&error="
                        + java.net.URLEncoder.encode("Dữ liệu nhập không hợp lệ", "UTF-8"));
                return;
            }

            if ("FAIL".equalsIgnoreCase(result) && defectIdRaw != null && !defectIdRaw.trim().isEmpty() && !"0".equals(defectIdRaw.trim())) {
                try {
                    int defectId = Integer.parseInt(defectIdRaw.trim());
                    pms.model.DefectDTO defect = new DefectDAO().getDefectById(defectId);
                    if (defect != null && defect.getReasonName() != null) {
                        String defectNote = "Lý do lỗi: " + defect.getReasonName().trim();
                        notes = (notes == null || notes.trim().isEmpty()) ? defectNote : defectNote + " | " + notes.trim();
                    }
                } catch (NumberFormatException ignore) {}
            }

            QcInspectionDTO qc = new QcInspectionDTO();
            qc.setWoId(woId);
            qc.setStepId(stepId);
            qc.setInspectorUserId(user.getId());
            qc.setInspectionResult(result);
            qc.setQuantityInspected(inspected);
            qc.setQuantityPassed(passed);
            qc.setQuantityFailed(failed);
            qc.setNotes(notes);

            boolean success = new QcInspectionDAO().insertInspection(qc);
            if (success) {
                if ("FAIL".equalsIgnoreCase(result)) {
                    NotificationService.notifyDefectDetected(String.valueOf(woId), "QC không đạt - " + failed + " sản phẩm lỗi");
                }
                response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&msg="
                        + java.net.URLEncoder.encode("Đã tạo phiếu kiểm tra chất lượng", "UTF-8"));
            } else {
                response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&error="
                        + java.net.URLEncoder.encode("Không thể lưu kết quả kiểm tra", "UTF-8"));
            }
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&error="
                    + java.net.URLEncoder.encode("Lỗi xử lý QC: " + e.getMessage(), "UTF-8"));
        }
    }

    private void deleteLog(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            int id = Integer.parseInt(request.getParameter("logId"));
            new ProductionLogDAO().deleteLog(id);
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=log&msg="
                    + java.net.URLEncoder.encode("Đã xóa nhật ký", "UTF-8"));
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=log&error="
                    + java.net.URLEncoder.encode("Lỗi xóa: " + e.getMessage(), "UTF-8"));
        }
    }

    private void deleteQc(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            new QcInspectionDAO().deleteInspection(id);
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&msg="
                    + java.net.URLEncoder.encode("Đã xóa phiếu QC", "UTF-8"));
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/ProductionTrackingController?action=list&tab=qc&error="
                    + java.net.URLEncoder.encode("Lỗi xóa QC: " + e.getMessage(), "UTF-8"));
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}
