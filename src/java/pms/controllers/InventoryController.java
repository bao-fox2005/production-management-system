package pms.controllers;

import java.io.IOException;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.BOMDAO;
import pms.model.InventoryLogDAO;
import pms.model.InventoryLogDTO;
import pms.model.ItemDAO;
import pms.model.ItemDTO;
import pms.model.UserDTO;
import pms.utils.NotificationService;

/**
 * InventoryController – Servlet quản lý Tồn Kho và Lịch Sử Nhập/Xuất Kho.
 *
 * Chức năng:
 *   - list         : Xem 200 bản ghi nhật ký kho mới nhất
 *   - byItem       : Xem nhật ký kho của một vật tư cụ thể
 *   - adjust       : Điều chỉnh thủ công số lượng tồn kho (tăng hoặc giảm)
 *   - replenish    : Nhập kho thủ công (chỉ tăng)
 *   - checkLowStock: Kiểm tra vật tư có tồn kho dưới mức tối thiểu
 *
 * Mọi thao tác thay đổi tồn kho đều ghi vào bảng InventoryLog để truy vết.
 * Yêu cầu người dùng đã đăng nhập (kiểm tra session).
 */
public class InventoryController extends HttpServlet {

    /** serialVersionUID cho Serializable */
    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chung. Phân luồng theo action.
     * Sau mỗi thao tác adjust/replenish → redirect về danh sách.
     * Các action hiển thị → forward trực tiếp.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "list"
        String action = request.getParameter("action");
        if (action == null) action = "list";

        String url = ""; // URL đích (JSP hoặc "redirect:...")

        switch (action) {
            case "list":
                listLogs(request);                         // Tải 200 bản ghi nhật ký gần nhất
                url = "inventory-log.jsp";
                break;
            case "byItem":
                logsByItem(request);                       // Tải nhật ký của một vật tư cụ thể
                url = "inventory-log.jsp";
                break;
            case "adjust":
                adjustStock(request);                      // Điều chỉnh tồn kho thủ công
                url = "redirect:InventoryController?action=list";
                return; // Return ngay để tránh fall-through xuống forward bên dưới
            case "replenish":
                replenishStock(request);                   // Nhập kho thủ công
                url = "redirect:InventoryController?action=list";
                return;
            case "checkLowStock":
                listLogs(request);                         // Tải nhật ký, JSP sẽ lọc low stock
                url = "inventory-log.jsp";
                break;
            default:
                listLogs(request);
                url = "inventory-log.jsp";
                break;
        }

        // Forward hoặc redirect tùy tiền tố
        if (url.startsWith("redirect:")) {
            response.sendRedirect(url.substring(9));
        } else {
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Tải 200 bản ghi nhật ký kho mới nhất và đưa vào request.
     * Giới hạn 200 bản ghi để tránh quá tải trang hiển thị.
     */
    private void listLogs(HttpServletRequest request) {
        InventoryLogDAO dao = new InventoryLogDAO();
        List<InventoryLogDTO> logs = dao.getRecentLogs(200); // Chỉ lấy 200 bản ghi mới nhất
        request.setAttribute("logs", logs);
        request.setAttribute("mode", "all"); // JSP dùng mode để chọn tiêu đề phù hợp
    }

    /**
     * Tải nhật ký kho của một vật tư cụ thể theo itemId.
     * Nếu không có itemId hoặc không hợp lệ → fallback về listLogs().
     *
     * @param request HttpServletRequest chứa tham số "itemId"
     */
    private void logsByItem(HttpServletRequest request) {
        String sItemId = request.getParameter("itemId"); // ID vật tư dạng chuỗi

        // Kiểm tra null/rỗng trước khi parse
        if (sItemId == null || sItemId.trim().isEmpty()) {
            listLogs(request); // Fallback: hiển thị tất cả nếu không có ID
            return;
        }

        try {
            int itemId = Integer.parseInt(sItemId);
            InventoryLogDAO dao = new InventoryLogDAO();

            // Lấy toàn bộ nhật ký của vật tư này
            List<InventoryLogDTO> logs = dao.getLogsByItem(itemId);
            request.setAttribute("logs",   logs);
            request.setAttribute("itemId", itemId);
            request.setAttribute("mode",   "byItem"); // JSP hiển thị filter theo item

            // Lấy thông tin vật tư để hiển thị tên và chi tiết
            ItemDAO itemDao = new ItemDAO();
            ItemDTO item = itemDao.SearchByID(itemId);
            request.setAttribute("item", item); // Tên vật tư, đơn vị, loại...

        } catch (Exception e) {
            // ID không phải số hoặc lỗi DB → báo lỗi và hiển thị tất cả
            request.setAttribute("error", "Invalid item ID");
            listLogs(request);
        }
    }

    /**
     * Điều chỉnh tồn kho thủ công (có thể tăng hoặc giảm).
     * quantityChange có thể là số âm (xuất kho) hoặc số dương (nhập kho).
     * Tồn kho không được xuống dưới 0 (tự động clamp về 0).
     * Sau khi điều chỉnh, ghi InventoryLog và kiểm tra ngưỡng low stock.
     *
     * Yêu cầu: người dùng phải đăng nhập (session user != null).
     *
     * @param request Chứa itemId, quantityChange, reason, referenceType
     */
    private void adjustStock(HttpServletRequest request) {
        // Chỉ cho phép người đã đăng nhập thực hiện
        HttpSession session = request.getSession(false); // false = không tạo session mới
        if (session == null) return;
        UserDTO user = (UserDTO) session.getAttribute("user");
        if (user == null) return;

        try {
            int itemId    = Integer.parseInt(request.getParameter("itemId"));
            int change    = Integer.parseInt(request.getParameter("quantityChange")); // Số lượng thay đổi (âm/dương)
            String reason  = request.getParameter("reason");     // Lý do điều chỉnh
            String refType = request.getParameter("referenceType"); // Loại tham chiếu: MANUAL, PRODUCTION...

            // Lấy tồn kho hiện tại
            ItemDAO itemDao = new ItemDAO();
            ItemDTO item = itemDao.SearchByID(itemId);
            if (item == null) return; // Vật tư không tồn tại → bỏ qua

            int before = item.getStockQuantity(); // Tồn kho trước điều chỉnh
            int after  = before + change;         // Tồn kho sau điều chỉnh
            if (after < 0) after = 0;            // Không cho phép tồn kho âm

            // Cập nhật tồn kho mới vào DB
            itemDao.updateStock(itemId, after);

            // Tạo bản ghi InventoryLog để lưu lịch sử
            InventoryLogDTO log = new InventoryLogDTO();
            log.setItemId(itemId);
            log.setChangeType("ADJUST");                           // Loại: điều chỉnh thủ công
            log.setQuantityBefore(before);                         // Số lượng trước
            log.setQuantityChange(change);                         // Lượng thay đổi (âm hoặc dương)
            log.setQuantityAfter(after);                           // Số lượng sau
            log.setReferenceType(refType != null ? refType : "MANUAL"); // Nguồn gốc điều chỉnh
            log.setReferenceId(0);                                 // Không có reference cụ thể khi thủ công
            log.setReason(reason != null ? reason : "Dieu chinh thu cong"); // Ghi chú lý do
            log.setPerformedBy(user.getId());                      // ID người thực hiện

            // Lưu log vào DB
            InventoryLogDAO invDao = new InventoryLogDAO();
            invDao.logChange(log);

            // Nếu tồn kho sau điều chỉnh ≤ mức tối thiểu → gửi thông báo cảnh báo
            if (after <= item.getMinStockLevel()) {
                NotificationService.notifyLowStock(item.getItemName(), after);
            }

            request.setAttribute("msg", "Da dieu chinh ton kho thanh cong!");

        } catch (Exception e) {
            request.setAttribute("error", "Loi dieu chinh: " + e.getMessage());
        }
    }

    /**
     * Nhập kho thủ công: chỉ tăng tồn kho (không cho phép âm).
     * Ghi InventoryLog với changeType = "IN" (nhập kho).
     * Hỗ trợ liên kết với một referenceId (ví dụ: ID PO hay phiếu nhập).
     *
     * @param request Chứa itemId, quantity, referenceType, referenceId
     */
    private void replenishStock(HttpServletRequest request) {
        // Yêu cầu đăng nhập
        HttpSession session = request.getSession(false);
        if (session == null) return;
        UserDTO user = (UserDTO) session.getAttribute("user");
        if (user == null) return;

        try {
            int itemId   = Integer.parseInt(request.getParameter("itemId"));
            int quantity = Integer.parseInt(request.getParameter("quantity")); // Số lượng nhập (luôn dương)
            String refType = request.getParameter("referenceType"); // Nguồn: PO, MANUAL...

            // Parse referenceId (ID phiếu nhập/PO liên quan); mặc định 0 nếu không có
            int refId = 0;
            try { refId = Integer.parseInt(request.getParameter("referenceId")); } catch (Exception e) { /* Giữ 0 */ }

            // Lấy tồn kho hiện tại
            ItemDAO itemDao = new ItemDAO();
            ItemDTO item = itemDao.SearchByID(itemId);
            if (item == null) return;

            int before = item.getStockQuantity(); // Tồn kho trước nhập
            int after  = before + quantity;        // Tồn kho sau nhập (chỉ tăng)

            // Cập nhật tồn kho mới
            itemDao.updateStock(itemId, after);

            // Tạo bản ghi InventoryLog loại IN (nhập kho)
            InventoryLogDTO log = new InventoryLogDTO();
            log.setItemId(itemId);
            log.setChangeType("IN");                               // Nhập kho
            log.setQuantityBefore(before);
            log.setQuantityChange(quantity);
            log.setQuantityAfter(after);
            log.setReferenceType(refType != null ? refType : "MANUAL");
            log.setReferenceId(refId);                             // Có thể là ID PO
            log.setReason("Nhap kho thu cong");
            log.setPerformedBy(user.getId());

            InventoryLogDAO invDao = new InventoryLogDAO();
            invDao.logChange(log); // Lưu log vào DB

            // Thông báo thành công kèm số lượng và đơn vị
            request.setAttribute("msg", "Da nhap kho " + quantity + " "
                    + (item.getUnit() != null ? item.getUnit() : "") + " thanh cong!");

        } catch (Exception e) {
            request.setAttribute("error", "Loi nhap kho: " + e.getMessage());
        }
    }

    /** Xử lý HTTP GET – xem danh sách nhật ký kho */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – điều chỉnh hoặc nhập kho */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}
