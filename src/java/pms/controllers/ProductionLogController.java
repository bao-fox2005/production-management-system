package pms.controllers;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.ProductionLogDAO;
import pms.model.ProductionLogDTO;
import pms.model.WorkOrderDAO;
import pms.model.RoutingStepDAO;
import pms.model.DefectDAO;

/**
 * ProductionLogController – Servlet quản lý Nhật Ký Sản Xuất (Production Log).
 *
 * Nhật ký sản xuất ghi lại kết quả từng bước sản xuất của công nhân:
 *   - Số lượng hoàn thành (quantityDone)
 *   - Số lượng lỗi (quantityDefective)
 *   - Nguyên nhân lỗi (defectId)
 *
 * Phân quyền:
 *   - Admin  : Xem toàn bộ nhật ký của tất cả công nhân
 *   - Worker : Chỉ xem nhật ký của chính mình, được phép thêm nhật ký mới
 *   - Khác   : Không xem được (danh sách rỗng)
 *
 * Hỗ trợ hai luồng action:
 *   1. Luồng mới (qua MainController): listLog, addLog
 *   2. Luồng cũ (gọi trực tiếp): insert, update, delete – giữ để backward-compat
 */
public class ProductionLogController extends HttpServlet {

    /**
     * Điểm xử lý chung. Phân quyền ngay từ đầu, sau đó phân luồng theo action.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định "listLog"
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "listLog";
        }

        // Lấy thông tin user từ session để phân quyền
        pms.model.UserDTO currentUser = (pms.model.UserDTO) request.getSession().getAttribute("user");
        String userRole    = currentUser != null ? currentUser.getRole() : "";
        int currentUserId  = currentUser != null ? currentUser.getId() : 0; // ID người đang đăng nhập

        // Xác định quyền hạn
        boolean isAdmin  = "admin".equalsIgnoreCase(userRole);
        boolean isWorker = "employee".equalsIgnoreCase(userRole)
                || "worker".equalsIgnoreCase(userRole)
                || "user".equalsIgnoreCase(userRole);

        // Tạo các DAO cần thiết
        ProductionLogDAO dao   = new ProductionLogDAO();
        WorkOrderDAO woDao     = new WorkOrderDAO();
        RoutingStepDAO stepDao = new RoutingStepDAO();
        DefectDAO defectDao    = new DefectDAO();

        try {
            // ---------------------------------------------------------------
            // LUỒNG MỚI: listLog / addLog
            // ---------------------------------------------------------------

            if ("listLog".equals(action) || "list".equals(action)) {
                // Hiển thị nhật ký sản xuất theo phân quyền
                if (isAdmin) {
                    // Admin xem tất cả nhật ký của mọi công nhân
                    request.setAttribute("listLogs", dao.getAllLogs());

                } else if (isWorker) {
                    // Worker chỉ xem nhật ký của chính mình
                    // Lấy tất cả rồi lọc theo workerUserId trong Java
                    java.util.List<ProductionLogDTO> allLogs = dao.getAllLogs();
                    java.util.List<ProductionLogDTO> workerLogs = new java.util.ArrayList<>();
                    for (ProductionLogDTO log : allLogs) {
                        if (log.getWorkerUserId() == currentUserId) { // Chỉ lấy log của mình
                            workerLogs.add(log);
                        }
                    }
                    request.setAttribute("listLogs", workerLogs); // Danh sách đã lọc

                } else {
                    // Vai trò không xác định → danh sách rỗng
                    request.setAttribute("listLogs", new java.util.ArrayList<>());
                }

                // Nạp dữ liệu tham chiếu cho form và dropdown
                request.setAttribute("listWO",      woDao.getAllWorkOrders());     // Dropdown WO
                request.setAttribute("listSteps",   stepDao.getAllRoutingStep());  // Dropdown bước SX
                request.setAttribute("listDefects", defectDao.getAllDefects());    // Dropdown lỗi
                request.setAttribute("isAdmin",     isAdmin);   // JSP dùng để hiện/ẩn nút quản lý
                request.setAttribute("isWorker",    isWorker);  // JSP dùng để hiện nút thêm log

                request.getRequestDispatcher("productionlog.jsp").forward(request, response);
                return;
            }

            if ("addLog".equals(action)) {
                // Chỉ worker mới được thêm nhật ký sản xuất
                if (!isWorker) {
                    response.sendRedirect("MainController?action=listLog");
                    return;
                }

                // Parse dữ liệu từ form báo cáo sản xuất
                int woId              = Integer.parseInt(request.getParameter("workOrderId")); // ID lệnh SX
                int stepId            = Integer.parseInt(request.getParameter("stepId"));      // ID bước thực hiện
                int quantityDone      = Integer.parseInt(request.getParameter("quantityDone")); // SL hoàn thành
                int quantityDefective = Integer.parseInt(request.getParameter("quantityDefective")); // SL lỗi
                int defectId          = Integer.parseInt(request.getParameter("defectId")); // Nguyên nhân lỗi

                // Tạo DTO và điền dữ liệu
                ProductionLogDTO log = new ProductionLogDTO();
                log.setWoId(woId);
                log.setStepId(stepId);
                log.setWorkerUserId(currentUserId); // Lấy ID từ session (bảo mật hơn lấy từ form)
                log.setQuantityDone(quantityDone);
                log.setQuantityDefective(quantityDefective);

                // defectId = 0 nghĩa là không có lỗi → set null thay vì 0
                if (defectId > 0) {
                    log.setDefectId(defectId);
                } else {
                    log.setDefectId(null); // Không có lỗi
                }

                log.setLogDate(new java.sql.Date(System.currentTimeMillis())); // Ngày báo cáo = hôm nay
                dao.insertLog(log); // Lưu vào DB

                response.sendRedirect("MainController?action=listLog"); // Redirect về danh sách
                return;
            }

            // ---------------------------------------------------------------
            // LUỒNG CŨ: insert, update, delete (backward compatibility)
            // Giữ lại để không phá vỡ các link cũ đang tồn tại
            // ---------------------------------------------------------------

            if ("insert".equals(action)) {
                // Luồng cũ: điền số liệu trực tiếp không qua MainController
                int woId         = Integer.parseInt(request.getParameter("woId"));
                int stepId       = Integer.parseInt(request.getParameter("stepId"));
                int workerUserId = Integer.parseInt(request.getParameter("workerUserId")); // Lấy từ form (luồng cũ)
                int quantity     = Integer.parseInt(request.getParameter("producedQuantity"));

                String defectStr = request.getParameter("defectId");
                Integer defectId = null;
                if (defectStr != null && !defectStr.isEmpty()) {
                    defectId = Integer.parseInt(defectStr); // Parse defectId nếu có
                }

                ProductionLogDTO log = new ProductionLogDTO();
                log.setWoId(woId);
                log.setStepId(stepId);
                log.setWorkerUserId(workerUserId); // Luồng cũ: lấy từ form parameter
                log.setProducedQuantity(quantity);
                log.setDefectId(defectId);
                dao.insertLog(log);

                response.sendRedirect("ProductionLogController?action=listLog");
                return;
            }

            if ("update".equals(action)) {
                // Cập nhật log theo logId (luồng cũ)
                int logId    = Integer.parseInt(request.getParameter("logId"));
                int quantity = Integer.parseInt(request.getParameter("producedQuantity"));

                String defectStr = request.getParameter("defectId");
                Integer defectId = null;
                if (defectStr != null && !defectStr.isEmpty()) {
                    defectId = Integer.parseInt(defectStr);
                }

                ProductionLogDTO log = new ProductionLogDTO();
                log.setLogId(logId);
                log.setProducedQuantity(quantity);
                log.setDefectId(defectId);
                dao.updateLog(log); // Cập nhật số lượng và defectId

                response.sendRedirect("ProductionLogController?action=listLog");
                return;
            }

            if ("delete".equals(action)) {
                // Xóa log theo logId (chỉ admin nên dùng)
                int logId = Integer.parseInt(request.getParameter("logId"));
                dao.deleteLog(logId); // Xóa cứng khỏi DB

                response.sendRedirect("ProductionLogController?action=listLog");
                return;
            }

            // Không khớp action nào → redirect về danh sách
            response.sendRedirect("ProductionLogController?action=listLog");

        } catch (Exception e) {
            // Ném lại dưới dạng ServletException để container xử lý (hiển thị trang lỗi 500)
            throw new ServletException("Lỗi xử lý nhật ký sản xuất", e);
        }
    }

    /** Xử lý HTTP GET – xem danh sách */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – thêm, cập nhật, xóa nhật ký */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "ProductionLog Controller – Quản lý nhật ký sản xuất";
    }
}
