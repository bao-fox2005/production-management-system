package pms.controllers;

import java.io.IOException;
import java.sql.Timestamp;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.ItemDAO;
import pms.model.ItemDTO;
import pms.model.PurchaseOrderDAO;
import pms.model.PurchaseOrderDTO;
import pms.model.UserDTO;
import pms.utils.NotificationService;

/**
 * PurchaseOrderController – Servlet quản lý Đơn Đặt Mua Vật Tư (Purchase Order).
 *
 * Đơn PO có thể được tạo thủ công hoặc tự động khi WorkOrderController phát hiện thiếu NVL.
 * Quyền hạn:
 *   - Admin + Worker: Được tạo PO mới
 *   - Admin only    : Cập nhật trạng thái và xóa PO
 *
 * URL mapping: /PurchaseOrderController
 */
@WebServlet(name = "PurchaseOrderController", urlPatterns = {"/PurchaseOrderController"})
public class PurchaseOrderController extends HttpServlet {

    /**
     * Điểm xử lý chung. Xác định quyền người dùng ngay từ đầu để phân quyền ở từng nhánh.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");

        // Lấy action; mặc định là "listPurchaseOrder"
        String action = request.getParameter("action");
        if (action == null) action = "listPurchaseOrder";

        // Tạo DAO dùng chung
        PurchaseOrderDAO dao = new PurchaseOrderDAO();
        ItemDAO itemDao      = new ItemDAO();

        // Lấy thông tin user từ session để kiểm tra quyền
        UserDTO user = (UserDTO) request.getSession().getAttribute("user");
        String role  = user != null ? user.getRole() : "user"; // Mặc định là user nếu chưa đăng nhập

        // Xác định quyền: admin có toàn quyền, worker/employee chỉ tạo được PO
        boolean isAdmin  = "admin".equalsIgnoreCase(role);
        boolean isWorker = "employee".equalsIgnoreCase(role)
                || "worker".equalsIgnoreCase(role)
                || "user".equalsIgnoreCase(role);

        try {
            switch (action) {

                case "listPurchaseOrder":
                case "searchPurchaseOrder":
                    // Hiển thị toàn bộ danh sách PO cùng dropdown vật tư
                    request.setAttribute("listPO",    dao.getAllPurchaseOrders()); // Danh sách tất cả PO
                    request.setAttribute("listItems", itemDao.ItemList());         // Dropdown chọn vật tư
                    request.setAttribute("isAdmin",   isAdmin);                   // JSP dùng để ẩn/hiện nút
                    request.setAttribute("isWorker",  isWorker);
                    request.getRequestDispatcher("SearchPurchaseOrder.jsp").forward(request, response);
                    return;

                case "addPurchaseOrder":
                    // Kiểm tra quyền: chỉ admin hoặc worker mới được tạo PO
                    if (!isAdmin && !isWorker) {
                        response.sendRedirect("MainController?action=listPurchaseOrder");
                        return;
                    }

                    int itemId = Integer.parseInt(request.getParameter("itemId")); // ID vật tư cần mua
                    int qty    = Integer.parseInt(request.getParameter("quantity")); // Số lượng cần mua

                    // Lấy timestamp hiện tại làm ngày đặt hàng (bao gồm cả giờ phút giây)
                    String date = new Timestamp(System.currentTimeMillis()).toString();

                    // Tạo PO với trạng thái Pending (chờ admin duyệt)
                    boolean inserted = dao.insertPurchaseOrder(new PurchaseOrderDTO(0, itemId, qty, "Pending", date));

                    if (inserted) {
                        // Lấy PO vừa tạo để lấy poId (PO mới nhất ở đầu danh sách)
                        List<PurchaseOrderDTO> latestOrders = dao.getAllPurchaseOrders();
                        PurchaseOrderDTO createdPo = (latestOrders != null && !latestOrders.isEmpty())
                                ? latestOrders.get(0) : null;

                        // Lấy thông tin vật tư để hiển thị trong thông báo
                        ItemDTO item     = itemDao.SearchByID(itemId);
                        String itemName  = (item != null && item.getItemName() != null) ? item.getItemName() : "Vật tư";
                        String requester = resolveRequesterName(user); // Tên người tạo PO
                        int poId         = createdPo != null ? createdPo.getPoId() : 0;

                        // Gửi thông báo cho admin về PO mới (email hoặc in-app)
                        NotificationService.notifyPurchaseOrderRequested(poId, itemName, qty, requester);

                        response.sendRedirect("MainController?action=listPurchaseOrder&msg="
                                + java.net.URLEncoder.encode("Đã tạo đơn nhập vật tư thành công.", "UTF-8"));
                    } else {
                        response.sendRedirect("MainController?action=listPurchaseOrder&error="
                                + java.net.URLEncoder.encode("Không thể tạo đơn nhập vật tư.", "UTF-8"));
                    }
                    return;

                case "updateStatusPurchaseOrder":
                    // Chỉ admin mới được cập nhật trạng thái PO (Pending → Approved → Received…)
                    if (!isAdmin) {
                        response.sendRedirect("MainController?action=listPurchaseOrder&error="
                                + java.net.URLEncoder.encode("Chỉ quản lý mới được cập nhật trạng thái đơn nhập.", "UTF-8"));
                        return;
                    }
                    int poId      = Integer.parseInt(request.getParameter("poId")); // ID PO cần cập nhật
                    String newStatus = request.getParameter("status");               // Trạng thái mới
                    dao.updateStatus(poId, newStatus); // Gọi DAO cập nhật status trong DB
                    response.sendRedirect("MainController?action=listPurchaseOrder&msg="
                            + java.net.URLEncoder.encode("Đã cập nhật trạng thái đơn nhập vật tư.", "UTF-8"));
                    return;

                case "deletePurchaseOrder":
                    // Chỉ admin mới được xóa PO
                    if (!isAdmin) {
                        response.sendRedirect("MainController?action=listPurchaseOrder&error="
                                + java.net.URLEncoder.encode("Chỉ quản lý mới được xóa đơn nhập.", "UTF-8"));
                        return;
                    }
                    int idDel = Integer.parseInt(request.getParameter("poId")); // ID PO cần xóa
                    dao.deletePurchaseOrder(idDel); // Xóa PO khỏi DB (hard delete)
                    response.sendRedirect("MainController?action=listPurchaseOrder&msg="
                            + java.net.URLEncoder.encode("Đã xóa đơn nhập vật tư.", "UTF-8"));
                    return;

                default:
                    // Action không xác định → về danh sách
                    response.sendRedirect("MainController?action=listPurchaseOrder");
                    return;
            }

        } catch (Exception e) {
            // Bất kỳ lỗi nào (parse ID, lỗi DB…) → redirect với thông báo lỗi chung
            e.printStackTrace();
            response.sendRedirect("MainController?action=listPurchaseOrder&error="
                    + java.net.URLEncoder.encode("Có lỗi xảy ra khi xử lý đơn nhập vật tư.", "UTF-8"));
        }
    }

    /**
     * Lấy tên hiển thị của người yêu cầu tạo PO.
     * Ưu tiên: fullName → username → "Người dùng hệ thống"
     *
     * @param user Đối tượng UserDTO từ session (có thể null)
     * @return Tên người dùng để hiển thị trong thông báo
     */
    private String resolveRequesterName(UserDTO user) {
        if (user == null) return "Người dùng hệ thống"; // Không đăng nhập

        // Ưu tiên fullName (tên đầy đủ) hơn username
        if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
            return user.getFullName().trim();
        }
        // Fallback sang username nếu không có fullName
        if (user.getUsername() != null && !user.getUsername().trim().isEmpty()) {
            return user.getUsername().trim();
        }
        return "Người dùng hệ thống"; // Fallback cuối cùng
    }

    /** Xử lý HTTP GET – xem danh sách PO */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – tạo, cập nhật, xóa PO */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}