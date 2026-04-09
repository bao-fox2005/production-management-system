package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.DefectDAO;
import pms.model.QcInspectionDAO;
import pms.model.QcInspectionDTO;
import pms.model.RoutingStepDAO;
import pms.model.UserDTO;
import pms.model.WorkOrderDAO;
import pms.utils.NotificationService;

/**
 * QcController – Servlet quản lý Phiếu Kiểm Tra Chất Lượng (QC Inspection).
 *
 * QC Inspection ghi lại kết quả kiểm tra sản phẩm tại từng bước sản xuất:
 *   - Số lượng kiểm tra (quantityInspected)
 *   - Số lượng đạt    (quantityPassed)
 *   - Số lượng lỗi    (quantityFailed = inspected - passed)
 *   - Kết quả: PASS hoặc FAIL
 *   - Nguyên nhân lỗi (ghi vào notes nếu kết quả FAIL)
 *
 * Chức năng:
 *   - list      : Xem toàn bộ danh sách phiếu QC kèm thống kê (tổng, tỷ lệ pass)
 *   - add       : Hiển thị form tạo phiếu QC mới
 *   - saveAdd   : Lưu phiếu QC mới; nếu FAIL → gửi thông báo lỗi
 *   - byWo      : Lọc phiếu QC theo Work Order cụ thể
 *   - failed    : Hiển thị chỉ các phiếu QC không đạt (FAIL)
 *   - delete    : Xóa phiếu QC
 *
 * Tất cả saveAdd và delete đều dùng redirect (PRG Pattern) để tránh submit lại.
 * Mọi thông báo truyền qua URL parameter (msg, error) đã UTF-8 encode.
 */
public class QcController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chung. saveAdd và delete tự trả response nên return trực tiếp.
     * Các action còn lại forward đến qc-list.jsp hoặc qc-form.jsp.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        if (action == null) action = "list";

        String url = ""; // Đích forward

        switch (action) {
            case "list":
                listInspections(request);    // Tải toàn bộ phiếu QC + thống kê
                url = "qc-list.jsp";
                break;
            case "add":
                showAddForm(request);        // Hiển thị form tạo phiếu
                url = "qc-form.jsp";
                break;
            case "saveAdd":
                addInspection(request, response); // Lưu phiếu → redirect
                return; // Đã tự ghi response
            case "byWo":
                inspectionsByWo(request);    // Lọc theo WO cụ thể
                url = "qc-list.jsp";
                break;
            case "failed":
                failedInspections(request);  // Chỉ hiện phiếu FAIL
                url = "qc-list.jsp";
                break;
            case "delete":
                deleteInspection(request, response); // Xóa phiếu → redirect
                return;
            default:
                listInspections(request);
                url = "qc-list.jsp";
                break;
        }

        if (url.startsWith("redirect:")) {
            response.sendRedirect(request.getContextPath() + "/" + url.substring(9));
        } else {
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Tải toàn bộ phiếu QC kèm số liệu thống kê tổng hợp.
     * Cung cấp: inspections, totalInspected, totalFailed, passRate, workOrders, steps, defects.
     */
    private void listInspections(HttpServletRequest request) {
        QcInspectionDAO dao = new QcInspectionDAO();
        List<QcInspectionDTO> list = dao.getAllInspections(); // Tất cả phiếu QC

        int totalInspected = dao.getTotalInspected(); // Tổng số SP đã kiểm tra
        int totalFailed    = dao.getTotalFailed();    // Tổng số SP lỗi
        double passRate    = dao.getOverallPassRate(); // Tỷ lệ đạt (%) toàn bộ

        request.setAttribute("inspections",     list);
        request.setAttribute("totalInspected",  totalInspected);
        request.setAttribute("totalFailed",     totalFailed);
        request.setAttribute("passRate",        passRate);
        request.setAttribute("mode",            "all"); // JSP dùng mode để chọn tiêu đề
        loadFormOptions(request); // Nạp dropdown cho form tạo phiếu
    }

    /**
     * Nạp các danh sách dropdown cần thiết cho form tạo/sửa phiếu QC:
     *   - workOrders : Chọn Work Order
     *   - steps      : Chọn bước sản xuất
     *   - defects    : Chọn nguyên nhân lỗi
     */
    private void loadFormOptions(HttpServletRequest request) {
        request.setAttribute("workOrders", new WorkOrderDAO().getAllWorkOrders());
        request.setAttribute("steps",      new RoutingStepDAO().getAllRoutingStep());
        request.setAttribute("defects",    new DefectDAO().getAllDefects());
    }

    /**
     * Lọc và hiển thị phiếu QC của một Work Order cụ thể.
     * Nếu không có woId hợp lệ → fallback về list tất cả.
     *
     * @param request Chứa tham số "woId"
     */
    private void inspectionsByWo(HttpServletRequest request) {
        String sWoId = request.getParameter("woId");
        if (sWoId == null || sWoId.trim().isEmpty()) {
            listInspections(request); // Không có ID → hiện tất cả
            return;
        }
        try {
            int woId = Integer.parseInt(sWoId);
            QcInspectionDAO dao = new QcInspectionDAO();
            List<QcInspectionDTO> list = dao.getInspectionsByWo(woId); // Lấy phiếu của WO này
            request.setAttribute("inspections", list);
            request.setAttribute("woId",        woId);  // JSP hiện filter đang chọn
            request.setAttribute("mode",        "byWo");
            loadFormOptions(request);
        } catch (Exception e) {
            listInspections(request); // Parse lỗi → về danh sách tổng
        }
    }

    /**
     * Hiển thị tất cả phiếu QC có kết quả FAIL (không đạt chất lượng).
     */
    private void failedInspections(HttpServletRequest request) {
        QcInspectionDAO dao = new QcInspectionDAO();
        List<QcInspectionDTO> list = dao.getInspectionsByResult("FAIL"); // Chỉ lấy FAIL
        request.setAttribute("inspections", list);
        request.setAttribute("mode",        "failed");
        loadFormOptions(request);
    }

    /**
     * Tải form tạo phiếu QC mới (chỉ set mode và dropdown).
     */
    private void showAddForm(HttpServletRequest request) {
        request.setAttribute("mode", "add");
        loadFormOptions(request); // Nạp dropdown WO, steps, defects
    }

    /**
     * Tạo và lưu phiếu QC mới.
     * Yêu cầu: người dùng đã đăng nhập (kiểm tra session).
     * Validate trước khi INSERT:
     *   - quantityInspected > 0
     *   - 0 ≤ quantityPassed ≤ quantityInspected
     *   - inspectionResult không rỗng
     * Nếu kết quả FAIL và có defectId → ghi nguyên nhân vào notes.
     * Nếu lưu thành công và FAIL → gửi thông báo defect.
     *
     * @param request  Chứa woId, stepId, inspectionResult, quantityInspected, quantityPassed, notes, defectId
     * @param response HttpServletResponse để redirect
     */
    private void addInspection(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null) {
            // Phiên hết hạn → yêu cầu đăng nhập lại
            response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                    + java.net.URLEncoder.encode("Phiên đăng nhập đã hết hạn", "UTF-8"));
            return;
        }

        UserDTO user = (UserDTO) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                    + java.net.URLEncoder.encode("Bạn cần đăng nhập để tạo phiếu QC", "UTF-8"));
            return;
        }

        try {
            int woId    = Integer.parseInt(request.getParameter("woId"));      // ID lệnh SX
            int stepId  = Integer.parseInt(request.getParameter("stepId"));    // ID bước SX
            String result = request.getParameter("inspectionResult");          // PASS hoặc FAIL
            int inspected = Integer.parseInt(request.getParameter("quantityInspected")); // Số kiểm tra
            int passed    = Integer.parseInt(request.getParameter("quantityPassed"));    // Số đạt
            int failed    = Math.max(0, inspected - passed); // Số lỗi = inspected - passed (không âm)
            String notes  = request.getParameter("notes");   // Ghi chú
            String defectIdRaw = request.getParameter("defectId"); // Nguyên nhân lỗi (tùy chọn)

            // Validate: số lượng kiểm tra phải dương
            if (inspected <= 0) {
                response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                        + java.net.URLEncoder.encode("Số lượng kiểm tra phải lớn hơn 0", "UTF-8"));
                return;
            }

            // Validate: số đạt trong khoảng [0, inspected]
            if (passed < 0 || passed > inspected) {
                response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                        + java.net.URLEncoder.encode("Số lượng đạt không hợp lệ", "UTF-8"));
                return;
            }

            // Tự động xác định kết quả dựa trên số lượng lỗi
            if (result == null || result.trim().isEmpty()) {
                result = (failed > 0) ? "FAIL" : "PASS";
            }

            // Nếu FAIL và có defectId → thêm tên nguyên nhân vào notes
            if ("FAIL".equalsIgnoreCase(result) && defectIdRaw != null
                    && !defectIdRaw.trim().isEmpty() && !"0".equals(defectIdRaw.trim())) {
                try {
                    int defectId = Integer.parseInt(defectIdRaw.trim());
                    DefectDAO defectDAO = new DefectDAO();
                    pms.model.DefectDTO defect = defectDAO.getDefectById(defectId);
                    if (defect != null && defect.getReasonName() != null
                            && !defect.getReasonName().trim().isEmpty()) {
                        String defectNote = "Lý do lỗi: " + defect.getReasonName().trim();
                        // Ghép nguyên nhân vào đầu notes (nếu đã có notes thì thêm " | " phân cách)
                        notes = (notes == null || notes.trim().isEmpty())
                                ? defectNote
                                : defectNote + " | " + notes.trim();
                    }
                } catch (NumberFormatException ignore) {
                    // defectId không phải số → bỏ qua
                }
            }

            // Tạo DTO và lưu vào DB
            QcInspectionDTO qc = new QcInspectionDTO();
            qc.setWoId(woId);
            qc.setStepId(stepId);
            qc.setInspectorUserId(user.getId()); // ID người kiểm tra (từ session)
            qc.setInspectionResult(result);       // PASS hoặc FAIL
            qc.setQuantityInspected(inspected);
            qc.setQuantityPassed(passed);
            qc.setQuantityFailed(failed);
            qc.setNotes(notes);

            QcInspectionDAO dao = new QcInspectionDAO();
            boolean success = dao.insertInspection(qc); // Lưu vào DB

            if (success) {
                if ("FAIL".equalsIgnoreCase(result)) {
                    // Phiếu FAIL → gửi thông báo cảnh báo lỗi sản phẩm
                    NotificationService.notifyDefectDetected(String.valueOf(woId),
                            "QC không đạt - " + failed + " sản phẩm lỗi");
                }
                response.sendRedirect(request.getContextPath() + "/QcController?action=list&msg="
                        + java.net.URLEncoder.encode("Tạo phiếu kiểm tra chất lượng thành công", "UTF-8"));
            } else {
                response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                        + java.net.URLEncoder.encode("Lưu kết quả QC thất bại", "UTF-8"));
            }

        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                    + java.net.URLEncoder.encode("Lỗi khi tạo phiếu QC: " + e.getMessage(), "UTF-8"));
        }
    }

    /**
     * Xóa phiếu QC theo id (inspection ID).
     * Redirect về danh sách với msg hoặc error tùy kết quả.
     *
     * @param request  Chứa tham số "id" (ID phiếu QC)
     * @param response HttpServletResponse để redirect
     */
    private void deleteInspection(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String sId = request.getParameter("id");
        if (sId == null || sId.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                    + java.net.URLEncoder.encode("Thiếu mã phiếu QC cần xóa", "UTF-8"));
            return;
        }
        try {
            int id = Integer.parseInt(sId);
            QcInspectionDAO dao = new QcInspectionDAO();
            boolean deleted = dao.deleteInspection(id); // Xóa khỏi DB

            // Redirect về list với thông báo tương ứng
            response.sendRedirect(request.getContextPath() + "/QcController?action=list&"
                    + (deleted
                       ? "msg=" + java.net.URLEncoder.encode("Đã xóa kết quả QC", "UTF-8")
                       : "error=" + java.net.URLEncoder.encode("Không thể xóa kết quả QC", "UTF-8")));
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/QcController?action=list&error="
                    + java.net.URLEncoder.encode("Lỗi xóa QC: " + e.getMessage(), "UTF-8"));
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
}
