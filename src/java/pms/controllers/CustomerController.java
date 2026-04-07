package pms.controllers;

import java.io.IOException;
import java.net.URLEncoder;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.CustomerDAO;
import pms.model.CustomerDTO;

/**
 * CustomerController – Servlet quản lý toàn bộ nghiệp vụ Khách hàng.
 *
 * Các chức năng:
 *   - Hiển thị danh sách khách hàng (listCustomer)
 *   - Tìm kiếm khách hàng theo từ khóa (searchCustomer)
 *   - Thêm khách hàng mới (addCustomer / saveAddCustomer)
 *   - Cập nhật thông tin khách hàng (updateCustomer / saveUpdateCustomer)
 *   - Xóa khách hàng (removeCustomer)
 *
 * Thông báo thành công/lỗi được truyền qua URL parameter (redirect-then-read)
 * thay vì request attribute, tránh mất message sau redirect.
 */
public class CustomerController extends HttpServlet {

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Đọc action, phân luồng đến method xử lý, rồi quyết định redirect hay forward.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 để hỗ trợ tiếng Việt
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Biến url chứa đích đến: "redirect:..." hoặc tên file JSP
        String url = "";

        // Lấy action; mặc định là "listCustomer" nếu không có
        String action = request.getParameter("action");
        if (action == null || action.isEmpty()) {
            action = "listCustomer";
        }

        // Phân luồng theo action; mỗi method trả về URL đích
        switch (action) {
            case "addCustomer":
            case "saveAddCustomer":
                url = addCustomer(request);   // Hiển thị form thêm hoặc lưu khách hàng mới
                break;
            case "removeCustomer":
                url = removeCustomer(request); // Xóa khách hàng theo ID
                break;
            case "updateCustomer":
            case "saveUpdateCustomer":
                url = updateCustomer(request); // Hiển thị form sửa hoặc lưu thay đổi
                break;
            case "searchCustomer":
            case "listCustomer":
                url = searchCustomer(request); // Tìm kiếm hoặc hiển thị toàn bộ danh sách
                break;
            default:
                // Action không xác định → về danh sách khách hàng
                url = "redirect:CustomerController?action=listCustomer";
                break;
        }

        // Quyết định redirect hay forward dựa vào tiền tố "redirect:"
        if (url != null && url.startsWith("redirect:")) {
            // sendRedirect: trình duyệt sẽ tạo GET request mới đến địa chỉ này
            // Dùng getContextPath() để URL đúng kể cả khi deploy ở sub-path
            response.sendRedirect(request.getContextPath() + "/" + url.substring(9));
        } else if (url != null && !url.isEmpty()) {
            // forward: giữ nguyên request, server chuyển tiếp nội bộ đến JSP
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Xóa khách hàng theo ID.
     * Nếu xóa thành công → redirect về danh sách với thông báo thành công.
     * Nếu thất bại (có dữ liệu liên quan) → redirect với thông báo lỗi từ DAO.
     * Nếu không có ID → tải lại danh sách và forward.
     *
     * @param request HttpServletRequest chứa tham số "id" của khách hàng cần xóa
     * @return URL đích (redirect hoặc JSP)
     */
    private String removeCustomer(HttpServletRequest request) {
        String id = request.getParameter("id"); // ID dạng chuỗi từ URL
        CustomerDAO cdao = new CustomerDAO();

        if (id != null && !id.isEmpty()) {
            try {
                // Chuyển ID sang int và gọi DAO xóa trong DB
                boolean check = cdao.deleteCustomer(Integer.parseInt(id));

                if (check) {
                    // Thành công → redirect với message được encode an toàn vào URL
                    return "redirect:CustomerController?action=listCustomer&msg="
                            + URLEncoder.encode("Xóa khách hàng thành công!", "UTF-8");
                } else {
                    // Thất bại → lấy message lỗi cụ thể từ DAO (ví dụ: khóa ngoại)
                    String daoError = cdao.getLastError();
                    String errorMessage = (daoError != null && !daoError.trim().isEmpty())
                            ? daoError
                            : "Không thể xóa khách hàng " + id + " vì có dữ liệu liên quan.";
                    return "redirect:CustomerController?action=listCustomer&error="
                            + URLEncoder.encode(errorMessage, "UTF-8");
                }
            } catch (Exception e) {
                // NumberFormatException hoặc lỗi DB → encode message lỗi vào URL
                return "redirect:CustomerController?action=listCustomer&error="
                        + safeEncode("Lỗi: " + e.getMessage());
            }
        }

        // Không có ID → tải danh sách và hiển thị lại trang khách hàng
        request.setAttribute("customerList", cdao.getAllCustomers());
        return "customer.jsp";
    }

    /**
     * Xử lý thêm khách hàng mới.
     * - Nếu action là "addCustomer"    → hiển thị form rỗng (chế độ thêm mới)
     * - Nếu action là "saveAddCustomer" → validate và lưu vào DB
     *
     * Validate: tên khách hàng không được để trống.
     *
     * @param request HttpServletRequest chứa dữ liệu form
     * @return URL đích
     */
    private String addCustomer(HttpServletRequest request) {
        CustomerDAO cdao = new CustomerDAO();
        String action = request.getParameter("action");

        // Báo cho JSP biết đang ở chế độ thêm mới (hiển thị form trống)
        request.setAttribute("mode", "add");

        if ("saveAddCustomer".equals(action)) {
            // Lấy và làm sạch dữ liệu từ form; trimToNull trả về null nếu rỗng
            String name  = trimToNull(request.getParameter("customer_name"));
            String phone = trimToNull(request.getParameter("phone"));
            String email = trimToNull(request.getParameter("email"));

            // Tạo DTO với id=0 (DB tự sinh ID khi INSERT)
            CustomerDTO c = new CustomerDTO(0, name, phone, email);

            if (name == null) {
                // Validate: tên không được rỗng
                request.setAttribute("error", "Tên khách không được để trống");
                request.setAttribute("customer", c); // Giữ lại dữ liệu đã nhập

            } else if (cdao.insertCustomer(c)) {
                // INSERT thành công → redirect về danh sách với thông báo
                return "redirect:CustomerController?action=listCustomer&msg="
                        + safeEncode("Thêm khách hàng thành công!");
            } else {
                // INSERT thất bại → lấy lỗi từ DAO (ví dụ: trùng email)
                String daoError = cdao.getLastError();
                request.setAttribute("error", daoError != null && !daoError.trim().isEmpty()
                        ? daoError
                        : "Không thể thêm khách hàng");
                request.setAttribute("customer", c); // Giữ lại dữ liệu đã nhập
            }
        }

        // Nạp danh sách khách hàng để hiển thị bên cạnh form
        request.setAttribute("customerList", cdao.getAllCustomers());
        return "customer.jsp";
    }

    /**
     * Xử lý cập nhật thông tin khách hàng.
     * - Nếu action là "updateCustomer"     → tải thông tin khách hàng lên form
     * - Nếu action là "saveUpdateCustomer" → validate và lưu thay đổi vào DB
     *
     * @param request HttpServletRequest chứa "id" và dữ liệu form
     * @return URL đích
     */
    private String updateCustomer(HttpServletRequest request) {
        CustomerDAO cdao = new CustomerDAO();
        String action = request.getParameter("action");
        String sId = request.getParameter("id"); // ID dạng chuỗi

        // Lấy thông tin khách hàng hiện tại từ DB để điền sẵn vào form
        CustomerDTO c = cdao.SearchByCustomerID(sId);

        // Báo JSP đang ở chế độ cập nhật
        request.setAttribute("mode", "update");

        if ("saveUpdateCustomer".equals(action)) {
            // Lấy dữ liệu mới từ form
            String name  = trimToNull(request.getParameter("customer_name"));
            String phone = trimToNull(request.getParameter("phone"));
            String email = trimToNull(request.getParameter("email"));

            try {
                int id = Integer.parseInt(sId); // Parse ID để đảm bảo hợp lệ

                // Tạo DTO mới với dữ liệu đã chỉnh sửa
                c = new CustomerDTO(id, name, phone, email);

                if (name == null) {
                    // Validate: tên không được rỗng
                    request.setAttribute("error", "Tên khách không được để trống");

                } else if (cdao.updateCustomer(c)) {
                    // UPDATE thành công → redirect về danh sách
                    return "redirect:CustomerController?action=listCustomer&msg="
                            + safeEncode("Cập nhật khách hàng thành công!");
                } else {
                    // UPDATE thất bại → lấy lỗi từ DAO
                    String daoError = cdao.getLastError();
                    request.setAttribute("error", daoError != null && !daoError.trim().isEmpty()
                            ? daoError
                            : "Cập nhật thất bại");
                }
            } catch (Exception e) {
                // ID không phải số hoặc lỗi khác
                request.setAttribute("error", "Lỗi: " + e.getMessage());
            }
        }

        // Đưa thông tin khách hàng và danh sách vào request để JSP hiển thị
        request.setAttribute("customer", c);
        request.setAttribute("customerList", cdao.getAllCustomers());
        return "customer.jsp";
    }

    /**
     * Tìm kiếm khách hàng theo từ khóa và hiển thị danh sách kết quả.
     * Nếu không có từ khóa → hiển thị toàn bộ danh sách.
     * Cũng đọc msg/error từ URL parameter (sau redirect) để hiển thị thông báo.
     *
     * @param request HttpServletRequest chứa tham số "keyword" (tùy chọn)
     * @return URL của trang danh sách khách hàng
     */
    private String searchCustomer(HttpServletRequest request) {
        String keyword = request.getParameter("keyword");
        CustomerDAO cdao = new CustomerDAO();
        List<CustomerDTO> customerList;

        if (keyword != null && !keyword.trim().isEmpty()) {
            // Có từ khóa → gọi DAO tìm kiếm theo tên/số điện thoại/email
            customerList = cdao.searchCustomers(keyword.trim());
        } else {
            // Không có từ khóa → lấy toàn bộ danh sách
            customerList = cdao.getAllCustomers();
        }

        request.setAttribute("customerList", customerList);
        request.setAttribute("keyword", keyword); // Giữ lại keyword để hiển thị lại trên ô tìm kiếm

        // Đọc msg/error từ URL parameter (được truyền qua redirect) và đưa vào request
        if (request.getAttribute("msg") == null && request.getParameter("msg") != null) {
            request.setAttribute("msg", request.getParameter("msg"));
        }
        if (request.getAttribute("error") == null && request.getParameter("error") != null) {
            request.setAttribute("error", request.getParameter("error"));
        }

        return "customer.jsp";
    }

    /**
     * Trim chuỗi và trả về null nếu kết quả rỗng.
     * Dùng để chuẩn hóa dữ liệu form: phân biệt "chưa nhập" (null) với "nhập khoảng trắng" ("").
     *
     * @param value Chuỗi cần xử lý
     * @return Chuỗi đã trim, hoặc null nếu rỗng
     */
    private String trimToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed; // Trả null nếu chỉ có khoảng trắng
    }

    /**
     * Encode chuỗi sang UTF-8 URL-safe (dùng cho query string).
     * Nếu encode thất bại (không bao giờ xảy ra với UTF-8) thì trả về chuỗi fallback.
     *
     * @param value Chuỗi cần encode
     * @return Chuỗi đã encode, an toàn để nhúng vào URL
     */
    private String safeEncode(String value) {
        try {
            return URLEncoder.encode(value, "UTF-8"); // Encode ký tự đặc biệt (dấu, khoảng trắng…)
        } catch (Exception ex) {
            return "Loi-he-thong"; // Fallback nếu có lỗi không mong muốn
        }
    }

    /** Xử lý HTTP GET – hiển thị danh sách, tìm kiếm, form */
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
}
