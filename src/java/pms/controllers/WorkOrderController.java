package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.ItemDAO;
import pms.model.ItemDTO;
import pms.model.RoutingDAO;
import pms.model.RoutingDTO;
import pms.model.WorkOrderDAO;
import pms.model.WorkOrderDTO;
import pms.model.BOMDAO;
import pms.model.BOMDTO;
import pms.model.BOMDetailDTO;
import pms.model.PurchaseOrderDAO;
import pms.model.PurchaseOrderDTO;

/**
 * WorkOrderController – Servlet quản lý Lệnh Sản Xuất (Work Order).
 *
 * Luồng nghiệp vụ chính của một Work Order:
 *   New → (checkMaterials) → WaitMaterial / Ready → (startProduction) → In Progress → (completeOrder) → Done
 *   Bất kỳ trạng thái nào → (delete) → Cancelled
 *
 * Các action hỗ trợ:
 *   - insert          : Tạo lệnh sản xuất mới
 *   - update          : Cập nhật lệnh sản xuất
 *   - delete          : Hủy lệnh (chuyển trạng thái → Cancelled, không xóa cứng)
 *   - checkMaterials  : Kiểm tra đủ vật tư chưa; nếu thiếu → tạo PO tự động
 *   - startProduction : Bắt đầu sản xuất; trừ tồn kho nguyên liệu
 *   - completeOrder   : Hoàn thành; cộng tồn kho thành phẩm
 *   - search          : Tìm kiếm lệnh theo ID
 *   - listWorkOrder   : Hiển thị danh sách, hỗ trợ lọc theo từ khóa/trạng thái/sản phẩm
 *   - calendar/gantt  : Hiển thị theo dạng lịch hoặc biểu đồ Gantt
 */
public class WorkOrderController extends HttpServlet {

    /**
     * Điểm xử lý chung cho mọi request.
     * Tất cả logic được bọc trong try-catch để ngăn crash server.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 cho cả request và response
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action, trim(), mặc định là "listWorkOrder"
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "listWorkOrder";
        }
        action = action.trim(); // Loại khoảng trắng thừa đầu/cuối

        WorkOrderDAO dao = new WorkOrderDAO(); // DAO dùng chung cho toàn request

        try {
            if ("insert".equals(action)) {
                // ---------------------------------------------------------------
                // Tạo lệnh sản xuất mới
                // ---------------------------------------------------------------
                int product  = Integer.parseInt(request.getParameter("product_item_id")); // ID sản phẩm cần sản xuất
                int routing  = Integer.parseInt(request.getParameter("routing_id"));       // ID quy trình sản xuất
                int quantity = Integer.parseInt(request.getParameter("order_quantity"));   // Số lượng cần sản xuất
                String status = request.getParameter("status");

                // Chuyển datetime-local ("2024-01-15T08:30") sang SQL datetime ("2024-01-15 08:30:00")
                String startDate = request.getParameter("start_date");
                if (startDate != null && startDate.contains("T")) startDate = startDate.replace("T", " ") + ":00";

                String dueDate = request.getParameter("due_date");
                if (dueDate != null && dueDate.contains("T")) dueDate = dueDate.replace("T", " ") + ":00";

                // Tạo DTO và gán dữ liệu
                WorkOrderDTO wo = new WorkOrderDTO();
                wo.setProduct_item_id(product);
                wo.setRouting_id(routing);
                wo.setOrder_quantity(quantity);
                wo.setStatus(status);
                wo.setStart_date(startDate);
                wo.setDue_date(dueDate);

                // Lưu vào DB và redirect với thông báo kết quả
                boolean inserted = dao.insertWorkOrder(wo);
                String insertNotice = inserted
                        ? java.net.URLEncoder.encode("Tạo lệnh sản xuất thành công", "UTF-8")
                        : java.net.URLEncoder.encode("Tạo lệnh sản xuất thất bại", "UTF-8");
                response.sendRedirect(request.getContextPath() + "/MainController?action=listWorkOrder"
                        + (inserted ? "&msg=" : "&error=") + insertNotice);
                return;

            } else if ("update".equals(action)) {
                // ---------------------------------------------------------------
                // Cập nhật lệnh sản xuất
                // ---------------------------------------------------------------
                int id       = Integer.parseInt(request.getParameter("wo_id"));
                int product  = Integer.parseInt(request.getParameter("product_item_id"));
                int routing  = Integer.parseInt(request.getParameter("routing_id"));
                int quantity = Integer.parseInt(request.getParameter("order_quantity"));
                String status = request.getParameter("status");

                // Xử lý format ngày giờ tương tự như insert
                String startDate = request.getParameter("start_date");
                if (startDate != null && startDate.contains("T")) startDate = startDate.replace("T", " ") + ":00";

                String dueDate = request.getParameter("due_date");
                if (dueDate != null && dueDate.contains("T")) dueDate = dueDate.replace("T", " ") + ":00";

                WorkOrderDTO wo = new WorkOrderDTO();
                wo.setWo_id(id);
                wo.setProduct_item_id(product);
                wo.setRouting_id(routing);
                wo.setOrder_quantity(quantity);
                wo.setStatus(status);
                wo.setStart_date(startDate);
                wo.setDue_date(dueDate);

                boolean updated = dao.updateWorkOrder(wo);
                String updateNotice = updated
                        ? java.net.URLEncoder.encode("Cập nhật lệnh sản xuất thành công", "UTF-8")
                        : java.net.URLEncoder.encode("Cập nhật lệnh sản xuất thất bại", "UTF-8");
                response.sendRedirect(request.getContextPath() + "/MainController?action=listWorkOrder"
                        + (updated ? "&msg=" : "&error=") + updateNotice);
                return;

            } else if ("delete".equals(action)) {
                // ---------------------------------------------------------------
                // Hủy lệnh sản xuất (soft delete: đổi trạng thái → Cancelled)
                // Không xóa cứng để giữ lịch sử
                // ---------------------------------------------------------------
                int id = Integer.parseInt(request.getParameter("wo_id"));
                boolean deleted = dao.updateWorkOrderStatusOnly(id, "Cancelled"); // Chỉ đổi status
                String deleteNotice = deleted
                        ? java.net.URLEncoder.encode("Đã chuyển lệnh sản xuất vào danh sách ĐÃ HỦY", "UTF-8")
                        : java.net.URLEncoder.encode("Không thể hủy lệnh sản xuất này", "UTF-8");
                response.sendRedirect(request.getContextPath() + "/MainController?action=listWorkOrder"
                        + (deleted ? "&msg=" : "&error=") + deleteNotice);
                return;

            } else if ("checkMaterials".equals(action)) {
                // ---------------------------------------------------------------
                // Kiểm tra tồn kho nguyên liệu so với BOM
                // Nếu thiếu: đổi status → WaitMaterial và tạo PO tự động
                // Nếu đủ:    đổi status → Ready
                // ---------------------------------------------------------------
                int woId = Integer.parseInt(request.getParameter("wo_id"));
                WorkOrderDTO wo = dao.searchById(woId); // Lấy thông tin Work Order

                // Chỉ cho phép kiểm tra khi WO ở trạng thái New hoặc WaitMaterial
                if (wo != null && ("New".equalsIgnoreCase(wo.getStatus())
                        || "WaitMaterial".equalsIgnoreCase(wo.getStatus()))) {

                    BOMDAO bomDao        = new BOMDAO();
                    ItemDAO itemDao      = new ItemDAO();
                    PurchaseOrderDAO poDao = new PurchaseOrderDAO();

                    // Lấy danh sách BOM của sản phẩm (lấy BOM đầu tiên = mới nhất/active)
                    List<BOMDTO> boms = bomDao.getBOMSByProduct(wo.getProduct_item_id());
                    if (boms == null || boms.isEmpty()) {
                        response.sendRedirect(request.getContextPath()
                            + "/MainController?action=listWorkOrder&error="
                            + java.net.URLEncoder.encode("Sản phẩm chưa có công thức BOM, không thể tính toán!", "UTF-8"));
                        return;
                    }

                    BOMDTO activeBom = boms.get(0); // Lấy BOM đầu tiên (active)
                    List<BOMDetailDTO> materials = bomDao.getBOMDetails(activeBom.getBomId()); // Chi tiết nguyên liệu

                    boolean isMissingMaterial = false;
                    StringBuilder missingNotes = new StringBuilder("Thiếu: ");

                    // Nếu đang kiểm tra lại (WaitMaterial) thì không tạo PO mới nữa
                    boolean isRechecking = "WaitMaterial".equalsIgnoreCase(wo.getStatus());

                    // Duyệt từng nguyên liệu trong BOM
                    for (BOMDetailDTO mat : materials) {
                        // Tính tổng lượng cần = số lượng/đơn vị × số lượng lệnh
                        double totalNeeded = mat.getQuantityRequired() * wo.getOrder_quantity();
                        ItemDTO item = itemDao.SearchByID(mat.getMaterialItemId()); // Lấy tồn kho hiện tại

                        if (item.getStockQuantity() < totalNeeded) {
                            isMissingMaterial = true;
                            int missingAmount = (int) Math.ceil(totalNeeded - item.getStockQuantity()); // Lượng thiếu
                            missingNotes.append(missingAmount).append(" ").append(item.getItemName()).append(", ");

                            if (!isRechecking) {
                                // Lần đầu kiểm tra → tạo Purchase Order để đặt mua số lượng thiếu
                                PurchaseOrderDTO po = new PurchaseOrderDTO();
                                po.setItemId(item.getItemID());
                                po.setQuantityRequested(missingAmount);
                                po.setStatus("Pending"); // Đang chờ duyệt
                                po.setOrderDate(new java.sql.Timestamp(System.currentTimeMillis()).toString());
                                poDao.insertPurchaseOrder(po); // Tạo đơn mua tự động
                            }
                        }
                    }

                    if (isMissingMaterial) {
                        // Có nguyên liệu thiếu → lưu ghi chú và đổi sang WaitMaterial
                        String notesToSave = missingNotes.substring(0, missingNotes.length() - 2); // Bỏ ", " cuối
                        dao.updateStatusAndNotes(woId, "WaitMaterial", notesToSave);
                        String msg = isRechecking
                                ? "Vẫn còn thiếu vật tư, chưa thể sản xuất!"
                                : "Thiếu vật tư! Đã tạo phiếu Nhập vật tư.";
                        response.sendRedirect(request.getContextPath()
                            + "/MainController?action=listWorkOrder&msg="
                            + java.net.URLEncoder.encode(msg, "UTF-8"));
                    } else {
                        // Đủ nguyên liệu → đổi sang Ready (sẵn sàng sản xuất)
                        dao.updateStatusAndNotes(woId, "Ready", "");
                        response.sendRedirect(request.getContextPath()
                            + "/MainController?action=listWorkOrder&msg="
                            + java.net.URLEncoder.encode("Kho đã đủ vật tư! Lệnh đã Sẵn sàng.", "UTF-8"));
                    }
                    return;
                }

            } else if ("startProduction".equals(action)) {
                // ---------------------------------------------------------------
                // Bắt đầu sản xuất: xuất kho nguyên liệu và đổi status → In Progress
                // Chỉ cho phép khi WO đang ở trạng thái Ready
                // ---------------------------------------------------------------
                int woId = Integer.parseInt(request.getParameter("wo_id"));
                WorkOrderDTO wo = dao.searchById(woId);

                if (wo != null && "Ready".equalsIgnoreCase(wo.getStatus())) {
                    BOMDAO bomDao   = new BOMDAO();
                    ItemDAO itemDao = new ItemDAO();

                    // Lấy BOM của sản phẩm để biết cần xuất kho nguyên liệu nào
                    List<BOMDTO> boms = bomDao.getBOMSByProduct(wo.getProduct_item_id());
                    if (boms != null && !boms.isEmpty()) {
                        BOMDTO activeBom = boms.get(0);
                        List<BOMDetailDTO> materials = bomDao.getBOMDetails(activeBom.getBomId());

                        for (BOMDetailDTO mat : materials) {
                            // Tính tổng cần xuất (làm tròn lên để đủ)
                            int totalNeeded = (int) Math.ceil(mat.getQuantityRequired() * wo.getOrder_quantity());
                            // Giảm tồn kho nguyên liệu trong DB
                            itemDao.decreaseStock(mat.getMaterialItemId(), totalNeeded);
                        }
                    }

                    // Đổi trạng thái WO sang In Progress
                    dao.updateStatusAndNotes(woId, "In Progress", "");
                    response.sendRedirect(request.getContextPath()
                        + "/MainController?action=listWorkOrder&msg="
                        + java.net.URLEncoder.encode("Đã xuất kho vật tư! Lệnh đang được tiến hành sản xuất.", "UTF-8"));
                    return;
                }

            } else if ("completeOrder".equals(action)) {
                // ---------------------------------------------------------------
                // Hoàn thành lệnh sản xuất:
                //   - Cộng số lượng thành phẩm vào kho
                //   - Đổi status → Done
                // ---------------------------------------------------------------
                int woId = Integer.parseInt(request.getParameter("wo_id"));
                WorkOrderDTO wo = dao.searchById(woId);

                // Chỉ cho phép hoàn thành khi WO đang In Progress
                if (wo != null && ("In Progress".equalsIgnoreCase(wo.getStatus())
                        || "InProgress".equalsIgnoreCase(wo.getStatus()))) {

                    ItemDAO itemDao = new ItemDAO();
                    // Cộng số lượng thành phẩm hoàn thành vào tồn kho sản phẩm
                    itemDao.increaseStock(wo.getProduct_item_id(), wo.getOrder_quantity());

                    // Đổi trạng thái WO → Done
                    dao.updateWorkOrderStatusOnly(woId, "Done");
                    response.sendRedirect(request.getContextPath()
                        + "/MainController?action=listWorkOrder&msg="
                        + java.net.URLEncoder.encode(
                            "Hoàn thành lệnh! Đã cộng " + wo.getOrder_quantity()
                            + " " + wo.getProductName() + " vào kho.", "UTF-8"));
                    return;
                }

            } else if ("search".equals(action)) {
                // ---------------------------------------------------------------
                // Tìm kiếm Work Order theo ID cụ thể
                // ---------------------------------------------------------------
                int id = Integer.parseInt(request.getParameter("wo_id"));
                WorkOrderDTO wo = dao.searchById(id); // Lấy WO theo ID
                request.setAttribute("WORKORDER", wo);  // Đưa kết quả vào request
                loadWorkOrderPageData(request, dao);     // Nạp thêm dữ liệu tham chiếu
                request.getRequestDispatcher("workorder.jsp").forward(request, response);
                return;

            } else if ("listWorkOrder".equals(action) || "list".equals(action)
                    || "loadUpdate".equals(action) || "calendar".equals(action)
                    || "gantt".equals(action)) {
                // ---------------------------------------------------------------
                // Hiển thị danh sách Work Order với bộ lọc tùy chọn
                // Hỗ trợ cả view dạng bảng, lịch (calendar) và biểu đồ Gantt
                // ---------------------------------------------------------------
                String searchKeyword  = request.getParameter("keyword");  // Từ khóa tìm kiếm
                String filterStatus   = request.getParameter("status");   // Lọc theo trạng thái
                String filterProduct  = request.getParameter("product_id"); // Lọc theo sản phẩm
                String searchId       = request.getParameter("search");   // Tìm theo ID cụ thể
                String msg            = request.getParameter("msg");      // Thông báo thành công từ redirect
                String error          = request.getParameter("error");    // Thông báo lỗi từ redirect

                // Nếu có search ID trong URL parameter thì tìm WO theo ID đó
                if (searchId != null && !searchId.trim().isEmpty()) {
                    try {
                        request.setAttribute("WORKORDER", dao.searchById(Integer.parseInt(searchId.trim())));
                    } catch (NumberFormatException e) {
                        request.setAttribute("error", "Mã lệnh không hợp lệ");
                    }
                }

                // Chuyển msg/error từ URL parameter vào request attribute để JSP đọc
                if (msg != null && !msg.trim().isEmpty()) request.setAttribute("msg", msg);
                if (error != null && !error.trim().isEmpty()) request.setAttribute("error", error);

                // Nạp toàn bộ dữ liệu trang (work orders + items + routings)
                loadWorkOrderPageData(request, dao);

                // Áp dụng bộ lọc lên danh sách (Java-side filtering)
                List<WorkOrderDTO> allWos = (List<WorkOrderDTO>) request.getAttribute("workOrders");
                request.setAttribute("workOrders", filterWorkOrders(allWos, searchKeyword, filterStatus, filterProduct));

                // Chọn view phù hợp: bảng, lịch, hay gantt
                request.getRequestDispatcher(resolveView(action)).forward(request, response);
                return;
            }

            // Nhánh mặc định: tải dữ liệu và hiển thị theo action
            loadWorkOrderPageData(request, dao);
            request.getRequestDispatcher(resolveView(action)).forward(request, response);

        } catch (Exception e) {
            // Bắt mọi lỗi không mong muốn, tránh crash server
            e.printStackTrace();
            request.setAttribute("error", e.getMessage());
            loadWorkOrderPageData(request, dao);
            request.getRequestDispatcher(resolveView(action)).forward(request, response);
        }
    }

    /**
     * Xác định file JSP cần hiển thị dựa vào action.
     *
     * @param action Tên action hiện tại
     * @return Đường dẫn JSP tương ứng
     */
    private String resolveView(String action) {
        if ("calendar".equals(action)) return "production-calendar.jsp"; // Xem dạng lịch tháng
        if ("gantt".equals(action))    return "production-gantt.jsp";    // Biểu đồ Gantt tiến độ
        return "workorder.jsp";                                           // Danh sách dạng bảng mặc định
    }

    /**
     * Nạp toàn bộ dữ liệu cần thiết cho trang Work Order vào request:
     *   - workOrders : Toàn bộ danh sách WO từ DB
     *   - items      : Danh sách sản phẩm (để dropdown chọn)
     *   - routings   : Danh sách quy trình sản xuất (để dropdown chọn)
     */
    private void loadWorkOrderPageData(HttpServletRequest request, WorkOrderDAO dao) {
        ItemDAO itemDao       = new ItemDAO();
        RoutingDAO routingDao = new RoutingDAO();
        request.setAttribute("workOrders", dao.getAllWorkOrders());      // Tất cả WO
        request.setAttribute("items",      itemDao.getAllItems());         // Dropdown sản phẩm
        request.setAttribute("routings",   routingDao.getAllRouting());   // Dropdown quy trình
    }

    /**
     * Lọc danh sách Work Order theo từ khóa, trạng thái và sản phẩm.
     * Tất cả điều kiện lọc là tùy chọn; nếu null/rỗng thì bỏ qua điều kiện đó.
     *
     * @param source       Danh sách gốc cần lọc
     * @param keyword      Từ khóa tìm trong ID, tên sản phẩm, tên routing
     * @param status       Trạng thái cần lọc (New, Ready, In Progress, Done, Cancelled…)
     * @param productIdStr ID sản phẩm dạng chuỗi (null nếu không lọc theo sản phẩm)
     * @return Danh sách WO đã lọc
     */
    private List<WorkOrderDTO> filterWorkOrders(List<WorkOrderDTO> source,
            String keyword, String status, String productIdStr) {

        if (source == null) return new ArrayList<>(); // Tránh NullPointerException

        List<WorkOrderDTO> filtered = new ArrayList<>();

        // Chuẩn hóa điều kiện lọc: trim và lowercase để so sánh không phân biệt hoa thường
        String normalizedKeyword = keyword != null ? keyword.trim().toLowerCase() : null;
        String normalizedStatus  = status  != null ? status.trim() : null;

        // Parse product ID nếu có
        Integer filterProductId = null;
        if (productIdStr != null && !productIdStr.isEmpty()) {
            try { filterProductId = Integer.parseInt(productIdStr); } catch (Exception e) { /* Bỏ qua */ }
        }

        for (WorkOrderDTO wo : source) {
            boolean matches = true; // Giả sử WO phù hợp cho đến khi có điều kiện vi phạm

            // Kiểm tra điều kiện từ khóa: khớp ID, tên sản phẩm, hoặc tên routing
            if (normalizedKeyword != null && !normalizedKeyword.isEmpty()) {
                String idText       = String.valueOf(wo.getWo_id()).toLowerCase();
                String productName  = wo.getProductName() != null  ? wo.getProductName().toLowerCase()  : "";
                String routingName  = wo.getRoutingName() != null  ? wo.getRoutingName().toLowerCase()  : "";
                if (!idText.contains(normalizedKeyword)
                        && !productName.contains(normalizedKeyword)
                        && !routingName.contains(normalizedKeyword)) {
                    matches = false; // Không khớp bất kỳ trường nào → loại bỏ
                }
            }

            // Kiểm tra điều kiện trạng thái
            if (matches && normalizedStatus != null && !normalizedStatus.isEmpty()) {
                String woStatus = wo.getStatus() != null ? wo.getStatus() : "";
                if (!woStatus.equalsIgnoreCase(normalizedStatus)) matches = false;
            }

            // Kiểm tra điều kiện sản phẩm
            if (matches && filterProductId != null) {
                if (wo.getProduct_item_id() != filterProductId) matches = false;
            }

            if (matches) filtered.add(wo); // Thêm vào kết quả nếu qua tất cả điều kiện
        }

        return filtered;
    }

    /** Xử lý HTTP GET – xem danh sách, calendar, gantt */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – tạo, cập nhật, hủy, bắt đầu, hoàn thành lệnh */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() { return "WorkOrder Controller"; }
}