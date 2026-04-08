package pms.controllers;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.ItemDAO;
import pms.model.ItemDTO;

/**
 * ItemController – Servlet quản lý vật tư/nguyên liệu/sản phẩm (Items).
 *
 * Các chức năng:
 *   - list        : Danh sách toàn bộ items
 *   - search      : Tìm kiếm theo tên và loại
 *   - lowStock    : Danh sách items sắp hết hàng (dưới mức tồn kho tối thiểu)
 *   - addItem     : Hiển thị form thêm mới
 *   - saveAddItem : Lưu item mới vào DB
 *   - editItem    : Hiển thị form chỉnh sửa
 *   - saveUpdateItem: Lưu thay đổi vào DB
 *   - deleteItem  : Xóa item khỏi DB
 */
public class ItemController extends HttpServlet {

    /**
     * CẢNH BÁO: Biến url là instance field – không thread-safe khi có nhiều request đồng thời.
     * Đây là hạn chế có thể gây lỗi khi tải cao. Tuy nhiên giữ nguyên để không phá vỡ logic hiện tại.
     */
    String url = "";

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Đọc action, gọi method tương ứng (mỗi method gán giá trị cho url),
     * rồi redirect hoặc forward.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 để hỗ trợ tiếng Việt
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "list" nếu không có
        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        // Phân luồng theo action
        switch (action) {
            case "list":
                listItems(request);     // Tải toàn bộ items
                break;
            case "search":
                searchItems(request);   // Lọc items theo tên và loại
                break;
            case "addItem":
                showAddForm(request);   // Hiển thị form thêm item rỗng
                break;
            case "saveAddItem":
                addItem(request);       // Xử lý lưu item mới
                break;
            case "editItem":
                showEditForm(request);  // Tải item cần sửa lên form
                break;
            case "saveUpdateItem":
                updateItem(request);    // Xử lý lưu thay đổi item
                break;
            case "deleteItem":
                deleteItem(request);    // Xóa item theo ID
                break;
            case "lowStock":
                listLowStock(request);  // Chỉ hiển thị items sắp hết hàng
                break;
        }

        // Quyết định redirect hay forward
        if (url != null && url.startsWith("redirect:")) {
            response.sendRedirect(url.substring(9)); // Bỏ tiền tố "redirect:" lấy URL thực
        } else {
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Tải toàn bộ danh sách items từ DB và forward đến trang danh sách.
     */
    private void listItems(HttpServletRequest request) {
        ItemDAO dao = new ItemDAO();
        ArrayList<ItemDTO> items = dao.getAllItems(); // Lấy tất cả items từ DB
        request.setAttribute("items", items);        // Đưa vào request để JSP đọc
        url = "item-list.jsp";
    }

    /**
     * Tìm kiếm items theo từ khóa tên và/hoặc loại item.
     * Load toàn bộ rồi filter trong Java.
     */
    private void searchItems(HttpServletRequest request) {
        ItemDAO dao = new ItemDAO();
        String keyword = request.getParameter("keyword"); // Từ khóa tìm theo tên
        String type    = request.getParameter("type");    // Loại item: "product", "material"…

        // Load tất cả trước rồi lọc dần
        ArrayList<ItemDTO> items = dao.getAllItems();

        // Lọc theo tên (không phân biệt hoa thường)
        if (keyword != null && !keyword.trim().isEmpty()) {
            items.removeIf(i -> i.getItemName() == null
                    || !i.getItemName().toLowerCase().contains(keyword.toLowerCase()));
        }

        // Lọc theo loại item nếu không phải "all"
        if (type != null && !type.isEmpty() && !type.equals("all")) {
            items.removeIf(i -> !i.getItemType().equals(type));
        }

        request.setAttribute("items", items); // Kết quả sau lọc
        url = "item-list.jsp";
    }

    /**
     * Lấy danh sách items có tồn kho dưới mức tối thiểu (cần đặt mua thêm).
     */
    private void listLowStock(HttpServletRequest request) {
        ItemDAO dao = new ItemDAO();
        ArrayList<ItemDTO> items = dao.getLowStockItems(); // Query riêng chỉ lấy hàng sắp hết
        request.setAttribute("items", items);
        request.setAttribute("lowStockOnly", true); // Flag để JSP hiển thị banner cảnh báo
        url = "item-list.jsp";
    }

    /**
     * Hiển thị form thêm item mới (form rỗng).
     */
    private void showAddForm(HttpServletRequest request) {
        request.setAttribute("mode", "add"); // JSP dùng mode để chọn tiêu đề và action form
        url = "item-form.jsp";
    }

    /**
     * Tải thông tin item cần chỉnh sửa lên form.
     * Nếu ID không hợp lệ → redirect về danh sách với lỗi.
     */
    private void showEditForm(HttpServletRequest request) {
        String s_id = request.getParameter("id"); // ID item dạng chuỗi
        int id = 0;
        try {
            id = Integer.parseInt(s_id); // Chuyển sang int
        } catch (Exception e) {
            // ID không phải số → báo lỗi và về danh sách
            request.setAttribute("error", "Invalid item ID");
            url = "redirect:ItemController?action=list";
            return;
        }

        ItemDAO dao = new ItemDAO();
        ItemDTO item = dao.SearchByID(id);          // Lấy thông tin item từ DB
        request.setAttribute("item", item);          // Đưa item vào request để JSP điền form
        request.setAttribute("mode", "update");      // Chế độ chỉnh sửa
        url = "item-form.jsp";
    }

    /**
     * Đọc dữ liệu từ form và lưu item mới vào DB.
     * Nếu lưu thành công → redirect về danh sách.
     * Nếu thất bại → hiển thị lại form với thông báo lỗi.
     * stockQuantity và minStockLevel có xử lý lỗi riêng để không crash khi rỗng.
     */
    private void addItem(HttpServletRequest request) {
        String error = "";

        try {
            String itemName    = request.getParameter("itemName");    // Tên vật tư
            String itemType    = request.getParameter("itemType");    // Loại: material/product
            String unit        = request.getParameter("unit");        // Đơn vị: kg, cái, thùng…
            String description = request.getParameter("description"); // Mô tả

            // Parse số lượng tồn kho; mặc định 0 nếu rỗng hoặc không phải số
            int stockQuantity = 0;
            try {
                stockQuantity = Integer.parseInt(request.getParameter("stockQuantity"));
            } catch (Exception e) { /* Giữ nguyên 0 */ }

            // Parse mức tồn kho tối thiểu; mặc định 0 nếu rỗng
            int minStockLevel = 0;
            try {
                minStockLevel = Integer.parseInt(request.getParameter("minStockLevel"));
            } catch (Exception e) { /* Giữ nguyên 0 */ }

            // Tạo DTO và điền dữ liệu
            ItemDTO item = new ItemDTO();
            item.setItemName(itemName);
            item.setItemType(itemType);
            item.setStockQuantity(stockQuantity);
            item.setUnit(unit);
            item.setDescription(description);
            item.setMinStockLevel(minStockLevel);

            ItemDAO dao = new ItemDAO();
            if (dao.Add(item)) {
                // Thêm thành công → redirect với thông báo được encode vào URL
                url = "redirect:ItemController?action=list&msg="
                        + java.net.URLEncoder.encode("Thêm vật tư thành công", "UTF-8");
                return;
            } else {
                error = "Không thể thêm vật tư";
                dao.ReseedSQL(); // Reset sequence ID của SQL Server sau INSERT thất bại
            }

        } catch (Exception e) {
            error = "Lỗi: " + e.getMessage();
        }

        // Thất bại → hiển thị lại form với thông báo lỗi
        request.setAttribute("error", error);
        request.setAttribute("mode", "add");
        url = "item-form.jsp";
    }

    /**
     * Đọc dữ liệu form edit và cập nhật item trong DB.
     * Nếu thành công/thất bại đều redirect về danh sách với thông báo trong URL.
     *
     * @throws UnsupportedEncodingException khi URLEncoder không hỗ trợ UTF-8 (thực tế không xảy ra)
     */
    private void updateItem(HttpServletRequest request) throws UnsupportedEncodingException {
        try {
            int id             = Integer.parseInt(request.getParameter("id"));
            String itemName    = request.getParameter("itemName");
            String itemType    = request.getParameter("itemType");
            int stockQuantity  = Integer.parseInt(request.getParameter("stockQuantity"));
            String unit        = request.getParameter("unit");
            String description = request.getParameter("description");
            int minStockLevel  = Integer.parseInt(request.getParameter("minStockLevel"));

            // Xây dựng DTO với đầy đủ thông tin cần update
            ItemDTO item = new ItemDTO();
            item.setItemID(id);
            item.setItemName(itemName);
            item.setItemType(itemType);
            item.setStockQuantity(stockQuantity);
            item.setUnit(unit);
            item.setDescription(description);
            item.setMinStockLevel(minStockLevel);

            ItemDAO dao = new ItemDAO();
            if (dao.Update(item)) {
                // Cập nhật thành công → redirect với msg
                url = "redirect:ItemController?action=list&msg="
                        + java.net.URLEncoder.encode("Cập nhật vật tư thành công", "UTF-8");
            } else {
                // Cập nhật thất bại → redirect với error
                url = "redirect:ItemController?action=list&error="
                        + java.net.URLEncoder.encode("Không thể cập nhật vật tư", "UTF-8");
            }

        } catch (Exception e) {
            // Lỗi parse số hoặc lỗi DB → redirect với error message
            url = "redirect:ItemController?action=list&error="
                    + java.net.URLEncoder.encode("Lỗi: " + e.getMessage(), "UTF-8");
        }
    }

    /**
     * Xóa item theo ID.
     * Nếu xóa thành công/thất bại đều redirect về danh sách với thông báo.
     *
     * @throws UnsupportedEncodingException khi URLEncoder không hỗ trợ UTF-8
     */
    private void deleteItem(HttpServletRequest request) throws UnsupportedEncodingException {
        String s_id = request.getParameter("id");
        try {
            int id = Integer.parseInt(s_id); // Parse ID để đảm bảo hợp lệ
            ItemDAO dao = new ItemDAO();
            boolean success = dao.Delete(id); // Gọi DAO xóa item trong DB

            if (success) {
                url = "redirect:ItemController?action=list&msg="
                        + java.net.URLEncoder.encode("Xóa vật tư thành công", "UTF-8");
            } else {
                url = "redirect:ItemController?action=list&error="
                        + java.net.URLEncoder.encode("Không thể xóa vật tư", "UTF-8");
            }
        } catch (Exception e) {
            url = "redirect:ItemController?action=list&error="
                    + java.net.URLEncoder.encode("Lỗi: " + e.getMessage(), "UTF-8");
        }
    }

    /** Xử lý HTTP GET – tìm kiếm, xem danh sách, form */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – lưu thêm mới, cập nhật */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Item Controller";
    }
}
