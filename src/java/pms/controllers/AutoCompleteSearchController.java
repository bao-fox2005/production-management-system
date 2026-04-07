package pms.controllers;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.ItemDAO;
import pms.model.CustomerDAO;
import pms.model.SupplierDAO;
import pms.model.WorkOrderDAO;
import pms.model.BOMDAO;
import pms.model.ItemDTO;
import pms.model.CustomerDTO;
import pms.model.SupplierDTO;
import pms.model.WorkOrderDTO;
import pms.model.BOMDTO;

/**
 * AutoCompleteSearchController – Controller xử lý tìm kiếm gợi ý (autocomplete) toàn hệ thống.
 *
 * Đây là API AJAX thuần, không forward/redirect JSP.
 * Browser gửi GET với tham số "q" (từ khóa) và tuy chọn "type" (loại dữ liệu).
 * Server trả về JSON array chứa các gợi ý khớp.
 *
 * Format JSON mỗi gợi ý:
 * <pre>
 * {
 *   "type":     "item" | "customer" | "supplier" | "workorder" | "bom",
 *   "id":       1,
 *   "label":    "Tên hiển thị chính",
 *   "sublabel": "Thông tin phụ (số điện thoại, tồn kho, trạng thái...)",
 *   "url":      "MainController?action=...&id=1"
 * }
 * </pre>
 *
 * Các loại dữ liệu được tìm kiếm (tham số "type"):
 *   - item      : Vật tư – tìm theo tên (ItemDAO.FilterByName)
 *   - customer  : Khách hàng – tìm theo tên hoặc số điện thoại
 *   - supplier  : Nhà cung cấp – tìm theo tên hoặc số điện thoại
 *   - workorder : Lệnh sản xuất – tìm theo ID hoặc tên sản phẩm
 *   - bom       : BOM – tìm theo tên sản phẩm hoặc version
 *
 * Nếu không có "type" → tìm kiếm tất cả 5 loại cùng lúc (cho thanh tìm kiếm global).
 *
 * Lưu ý hiệu năng: tất cả lọc thực hiện phía Java (load toàn bộ bảng rồi lọc).
 * Với dữ liệu lớn nên chuyển filter xuống tầng DAO (SQL LIKE).
 */
public class AutoCompleteSearchController extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /**
     * Điểm xử lý chính cho tất cả autocomplete request.
     * Content-Type luôn là application/json để browser biết đây là JSON.
     *
     * @param request  Chứa "q" (từ khóa) và tùy chọn "type"
     * @param response HttpServletResponse để ghi JSON
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt Content-Type JSON (bắt buộc cho AJAX response)
        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        request.setCharacterEncoding("UTF-8");

        String query = request.getParameter("q");    // Từ khóa tìm kiếm
        String type  = request.getParameter("type"); // Loại dữ liệu cần tìm (null = tất cả)

        // Nếu không có từ khóa → trả về mảng rỗng để tránh load toàn bộ dữ liệu
        if (query == null || query.trim().isEmpty()) {
            writeResponse(response, "[]");
            return;
        }

        query = query.trim(); // Loại bỏ khoảng trắng ở đầu/cuối

        // Bắt đầu xây dựng JSON array
        StringBuilder json = new StringBuilder();
        json.append("[");

        try {
            boolean first = true; // Cờ để biết cần thêm dấu "," trước phần tử tiếp theo không

            // ---- Tìm kiếm Vật tư (Item) ----
            if (type == null || type.isEmpty() || "item".equals(type)) {
                for (ItemDTO item : searchItems(query)) {
                    if (!first) json.append(",");
                    // JSON object: type, id, label (tên vật tư), sublabel (loại | số lượng đơn vị), url
                    json.append("{\"type\":\"item\",\"id\":").append(item.getItemID())
                        .append(",\"label\":\"").append(esc(item.getItemName())).append("\"")
                        .append(",\"sublabel\":\"").append(esc(item.getItemType()))
                            .append(" | ").append(item.getStockQuantity()).append(" ").append(esc(item.getUnit())).append("\"")
                        .append(",\"url\":\"MainController?action=updateItem&id=").append(item.getItemID())
                        .append("\"}");
                    first = false;
                }
            }

            // ---- Tìm kiếm Khách hàng (Customer) ----
            if (type == null || type.isEmpty() || "customer".equals(type)) {
                for (CustomerDTO c : searchCustomers(query)) {
                    if (!first) json.append(",");
                    String phone = c.getPhone() != null ? c.getPhone() : "";
                    String email = c.getEmail() != null ? c.getEmail() : "";
                    // sublabel: số điện thoại + email (nếu có)
                    json.append("{\"type\":\"customer\",\"id\":").append(c.getCustomer_id())
                        .append(",\"label\":\"").append(esc(c.getCustomer_name())).append("\"")
                        .append(",\"sublabel\":\"").append(esc(phone))
                            .append(email.isEmpty() ? "" : " | " + esc(email)).append("\"")
                        .append(",\"url\":\"MainController?action=updateCustomer&id=")
                            .append(c.getCustomer_id()).append("\"")
                        .append("}");
                    first = false;
                }
            }

            // ---- Tìm kiếm Nhà cung cấp (Supplier) ----
            if (type == null || type.isEmpty() || "supplier".equals(type)) {
                for (SupplierDTO s : searchSuppliers(query)) {
                    if (!first) json.append(",");
                    // city = địa chỉ thành phố; fallback về email nếu không có city
                    String city = s.getCity() != null ? s.getCity()
                                : (s.getEmail() != null ? s.getEmail() : "");
                    json.append("{\"type\":\"supplier\",\"id\":").append(s.getSupplierId())
                        .append(",\"label\":\"").append(esc(s.getSupplierName())).append("\"")
                        .append(",\"sublabel\":\"").append(esc(city)).append("\"")
                        .append(",\"url\":\"MainController?action=updateSupplier&id=")
                            .append(s.getSupplierId()).append("\"")
                        .append("}");
                    first = false;
                }
            }

            // ---- Tìm kiếm Lệnh sản xuất (WorkOrder) ----
            if (type == null || type.isEmpty() || "workorder".equals(type)) {
                for (WorkOrderDTO wo : searchWorkOrders(query)) {
                    if (!first) json.append(",");
                    // label: "#ID - Tên sản phẩm"
                    String label = "#" + wo.getWo_id()
                            + (wo.getProductName() != null ? " - " + wo.getProductName() : "");
                    json.append("{\"type\":\"workorder\",\"id\":").append(wo.getWo_id())
                        .append(",\"label\":\"").append(esc(label)).append("\"")
                        .append(",\"sublabel\":\"SL: ").append(wo.getOrder_quantity())
                            .append(" | Status: ")
                            .append(wo.getStatus() != null ? wo.getStatus() : "N/A").append("\"")
                        .append(",\"url\":\"MainController?action=updateWorkOrder&id=")
                            .append(wo.getWo_id()).append("\"")
                        .append("}");
                    first = false;
                }
            }

            // ---- Tìm kiếm BOM (Bill of Materials) ----
            if (type == null || type.isEmpty() || "bom".equals(type)) {
                for (BOMDTO bom : searchBoms(query)) {
                    if (!first) json.append(",");
                    // label: "Tên sản phẩm (version)"
                    String name = (bom.getProductName() != null ? bom.getProductName() : "")
                            + " (" + (bom.getBomVersion() != null ? bom.getBomVersion() : "") + ")";
                    json.append("{\"type\":\"bom\",\"id\":").append(bom.getBomId())
                        .append(",\"label\":\"").append(esc(name)).append("\"")
                        .append(",\"sublabel\":\"Status: ")
                            .append(bom.getStatus() != null ? bom.getStatus() : "N/A").append("\"")
                        .append(",\"url\":\"MainController?action=viewBOM&id=")
                            .append(bom.getBomId()).append("\"")
                        .append("}");
                    first = false;
                }
            }

        } catch (Exception e) {
            // Lỗi trong quá trình tìm kiếm → trả JSON error thay vì crash server
            json.append("{\"error\":\"").append(esc(e.getMessage())).append("\"}]");
            writeResponse(response, json.toString());
            return;
        }

        json.append("]"); // Đóng mảng JSON
        writeResponse(response, json.toString());
    }

    /**
     * Tìm vật tư theo tên.
     * Dùng DAO.FilterByName() để lấy sơ bộ, sau đó lọc thêm bằng matches() phía Java.
     *
     * @param query Từ khóa tìm kiếm
     * @return Danh sách ItemDTO khớp từ khóa
     */
    private List<ItemDTO> searchItems(String query) {
        List<ItemDTO> result = new ArrayList<>();
        ItemDAO dao = new ItemDAO();
        ArrayList<ItemDTO> items = dao.FilterByName(query); // Lọc sơ bộ tại DB

        if (items != null) {
            for (ItemDTO item : items) {
                if (matches(item.getItemName(), query)) { // Lọc chặt hơn phía Java
                    result.add(item);
                }
            }
        }
        return result;
    }

    /**
     * Tìm khách hàng theo tên hoặc số điện thoại.
     * Load toàn bộ danh sách khách hàng rồi lọc phía Java.
     *
     * @param query Từ khóa tìm kiếm
     * @return Danh sách CustomerDTO khớp từ khóa
     */
    private List<CustomerDTO> searchCustomers(String query) {
        List<CustomerDTO> result = new ArrayList<>();
        try {
            CustomerDAO dao = new CustomerDAO();
            List<CustomerDTO> list = dao.getAllCustomers(); // Load toàn bộ

            if (list != null) {
                for (CustomerDTO c : list) {
                    String name  = c.getCustomer_name() != null ? c.getCustomer_name() : "";
                    String phone = c.getPhone() != null ? c.getPhone() : "";
                    // Khớp nếu tên chứa query (case-insensitive) hoặc số điện thoại chứa query
                    if (matches(name, query) || phone.contains(query)) {
                        result.add(c);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace(); // Log lỗi, trả về rỗng
        }
        return result;
    }

    /**
     * Tìm nhà cung cấp theo tên hoặc số điện thoại liên hệ.
     *
     * @param query Từ khóa tìm kiếm
     * @return Danh sách SupplierDTO khớp từ khóa
     */
    private List<SupplierDTO> searchSuppliers(String query) {
        List<SupplierDTO> result = new ArrayList<>();
        try {
            SupplierDAO dao = new SupplierDAO();
            ArrayList<SupplierDTO> list = dao.getAllSupplier();

            if (list != null) {
                for (SupplierDTO s : list) {
                    String name  = s.getSupplierName() != null ? s.getSupplierName() : "";
                    String phone = s.getContactPhone() != null ? s.getContactPhone() : "";
                    if (matches(name, query) || phone.contains(query)) {
                        result.add(s);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return result;
    }

    /**
     * Tìm lệnh sản xuất theo ID hoặc tên sản phẩm.
     *
     * @param query Từ khóa tìm kiếm (ID dạng số hoặc tên sản phẩm)
     * @return Danh sách WorkOrderDTO khớp từ khóa
     */
    private List<WorkOrderDTO> searchWorkOrders(String query) {
        List<WorkOrderDTO> result = new ArrayList<>();
        try {
            WorkOrderDAO dao = new WorkOrderDAO();
            List<WorkOrderDTO> list = dao.getAllWorkOrders();

            if (list != null) {
                for (WorkOrderDTO wo : list) {
                    // Tạo chuỗi tìm kiếm: "#5 Tên sản phẩm"
                    String label = "#" + wo.getWo_id()
                            + (wo.getProductName() != null ? " " + wo.getProductName() : "");
                    // Khớp khi label chứa query hoặc ID chứa query (ví dụ: gõ "5" → khớp WO#5, WO#15…)
                    if (matches(label, query) || String.valueOf(wo.getWo_id()).contains(query)) {
                        result.add(wo);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return result;
    }

    /**
     * Tìm BOM theo tên sản phẩm hoặc version.
     *
     * @param query Từ khóa tìm kiếm
     * @return Danh sách BOMDTO khớp từ khóa
     */
    private List<BOMDTO> searchBoms(String query) {
        List<BOMDTO> result = new ArrayList<>();
        try {
            BOMDAO dao = new BOMDAO();
            List<BOMDTO> list = dao.getAllBOMS();

            if (list != null) {
                for (BOMDTO bom : list) {
                    String name = bom.getProductName() != null ? bom.getProductName() : "";
                    String ver  = bom.getBomVersion() != null ? bom.getBomVersion() : "";
                    // Khớp nếu tên sản phẩm hoặc phiên bản chứa query
                    if (matches(name, query) || matches(ver, query)) {
                        result.add(bom);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return result;
    }

    /**
     * Kiểm tra chuỗi field có chứa query không (case-insensitive, null-safe).
     *
     * @param field Chuỗi cần kiểm tra (có thể null)
     * @param query Từ khóa tìm kiếm
     * @return true nếu field chứa query (không phân biệt hoa/thường)
     */
    private boolean matches(String field, String query) {
        return field != null && field.toLowerCase().contains(query.toLowerCase());
    }

    /**
     * Escape các ký tự đặc biệt trong chuỗi trước khi đưa vào JSON string.
     * Tránh JSON injection: dấu nháy kép, backslash, ký tự xuống dòng.
     *
     * @param s Chuỗi cần escape (có thể null)
     * @return Chuỗi đã escape, hoặc "" nếu null
     */
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")   // Escape backslash trước
                 .replace("\"", "\\\"")  // Escape double quote
                 .replace("\n", "\\n")   // Escape newline
                 .replace("\r", "\\r")   // Escape carriage return
                 .replace("\t", "\\t");  // Escape tab
    }

    /**
     * Ghi JSON response với các header chống cache phù hợp cho AJAX.
     * Access-Control-Allow-Origin: * cho phép gọi từ bất kỳ domain.
     *
     * @param response HttpServletResponse cần ghi vào
     * @param json     Chuỗi JSON đã build sẵn
     */
    private void writeResponse(HttpServletResponse response, String json) throws IOException {
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // Không cache
        response.setHeader("Pragma",        "no-cache");
        response.setHeader("Expires",       "0");
        response.setHeader("Access-Control-Allow-Origin", "*"); // Cho phép CORS
        response.getWriter().write(json);
    }

    /** Xử lý HTTP GET – tìm kiếm gợi ý */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST (cùng logic GET, hỗ trợ form submit nếu cần) */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }
}
