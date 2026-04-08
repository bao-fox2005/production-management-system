package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.BillDAO;
import pms.model.BillDTO;
import pms.model.CustomerDAO;
import pms.model.CustomerDTO;
import pms.model.PaymentDAO;
import pms.model.PaymentDTO;
import pms.model.WorkOrderDAO;
import pms.model.WorkOrderDTO;

/**
 * BillController – Servlet quản lý Hóa Đơn (Bill).
 *
 * Mỗi hóa đơn liên kết với một Work Order và một Khách hàng.
 * Trạng thái thanh toán của hóa đơn được tính từ Payment record mới nhất:
 *   - Không có Payment / Payment chưa thanh toán → "pending"
 *   - Payment đã thanh toán (PAID)               → "paid"
 *   - Payment hết hạn (expiresAt < now)          → "expired"
 *
 * Chức năng:
 *   - listBill   : Xem toàn bộ hóa đơn, hỗ trợ lọc theo trạng thái và từ khóa
 *   - addBill    : Tạo hóa đơn mới
 *   - deleteBill : Xóa hóa đơn
 *   - updateBill : Cập nhật hóa đơn
 *   - searchBill : Tìm kiếm theo từ khóa
 */
public class BillController extends HttpServlet {

    /**
     * CẢNH BÁO: url là instance field – không thread-safe (giống ItemController).
     * Giữ nguyên để không phá vỡ logic hiện tại.
     */
    String url = "";

    /**
     * Điểm xử lý chung cho cả GET và POST.
     * Sau khi mỗi method xử lý xong (đặt url), forward đến trang bill.jsp.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 để hỗ trợ tiếng Việt
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "listBill"
        String action = request.getParameter("action");
        if (action == null) {
            action = "listBill";
        }

        // Phân luồng theo action
        switch (action) {
            case "listBill":
                ListBill(request);   // Tải toàn bộ hóa đơn
                break;
            case "addBill":
                AddBill(request);    // Tạo hóa đơn mới
                break;
            case "deleteBill":
                DeleteBill(request); // Xóa hóa đơn theo bill_id
                break;
            case "updateBill":
                UpdateBill(request); // Cập nhật hóa đơn
                break;
            case "searchBill":
                SearchBill(request); // Tìm kiếm hóa đơn theo từ khóa
                break;
        }

        // Tất cả action đều forward về bill.jsp (url được set bởi populateBillPageData)
        request.getRequestDispatcher(url).forward(request, response);
    }

    /**
     * Tải toàn bộ danh sách hóa đơn từ DB, áp dụng bộ lọc (nếu có) và đưa vào request.
     *
     * @param request Chứa tham số "filter" (trạng thái) và "keyword" (từ khóa tùy chọn)
     */
    private void ListBill(HttpServletRequest request) {
        BillDAO dao = new BillDAO();
        ArrayList<BillDTO> list = dao.getAllBill(); // Lấy tất cả hóa đơn từ DB

        // Áp dụng bộ lọc theo filter (trạng thái) và keyword (từ khóa)
        list = getFilteredBills(list, request.getParameter("filter"), request.getParameter("keyword"));

        // Nạp dữ liệu tham chiếu (WorkOrder, Customer, Payment) vào request
        populateBillPageData(request, list);
    }

    /**
     * Tạo hóa đơn mới từ dữ liệu form.
     * Validate: wo_id > 0 và total_amount > 0 trước khi INSERT.
     * Sau khi xử lý (thành công hay thất bại) → tải lại danh sách hóa đơn.
     *
     * @param request Chứa wo_id, customer_id, total_amount
     */
    private void AddBill(HttpServletRequest request) {
        try {
            int wo_id          = Integer.parseInt(request.getParameter("wo_id"));       // ID lệnh sản xuất liên kết
            int customer_id    = Integer.parseInt(request.getParameter("customer_id")); // ID khách hàng
            double total_amount = Double.parseDouble(request.getParameter("total_amount")); // Tổng tiền

            // Validate: phải chọn work order hợp lệ
            if (wo_id <= 0) {
                request.setAttribute("error", "Vui lòng chọn lệnh sản xuất hợp lệ.");
                ListBill(request);
                return;
            }

            // Validate: tổng tiền phải dương
            if (total_amount <= 0) {
                request.setAttribute("error", "Tổng tiền phải lớn hơn 0.");
                ListBill(request);
                return;
            }

            BillDAO dao = new BillDAO();
            // Tạo BillDTO: id=0 (DB tự sinh), ngày tạo = ngày hiện tại
            BillDTO bill = new BillDTO(0, wo_id, customer_id, total_amount,
                    new java.sql.Date(System.currentTimeMillis()));

            boolean result = dao.InsertBill(bill); // Lưu vào DB
            if (result) {
                request.setAttribute("msg", "Tạo hóa đơn thành công.");
            } else {
                request.setAttribute("error", "Tạo hóa đơn thất bại.");
            }

        } catch (Exception e) {
            // Lỗi parse số hoặc lỗi DB
            request.setAttribute("error", "Không thể tạo hóa đơn: " + e.getMessage());
        }

        // Luôn tải lại danh sách sau khi xử lý
        ListBill(request);
    }

    /**
     * Xóa hóa đơn theo bill_id.
     * Sau khi xóa → tải lại danh sách hóa đơn.
     *
     * @param request Chứa tham số "bill_id"
     */
    private void DeleteBill(HttpServletRequest request) {
        int bill_id = Integer.parseInt(request.getParameter("bill_id")); // ID hóa đơn cần xóa
        BillDAO dao = new BillDAO();
        boolean result = dao.deleteBill(bill_id); // Xóa khỏi DB

        if (result) {
            request.setAttribute("msg", "Xóa hóa đơn thành công");
        } else {
            request.setAttribute("msg", "Xóa hóa đơn thất bại");
        }

        ListBill(request); // Tải lại danh sách
    }

    /**
     * Cập nhật thông tin hóa đơn (WorkOrder, Khách hàng, Tổng tiền).
     * Giữ nguyên ngày tạo và trạng thái từ DB.
     * Sau khi cập nhật → tải lại danh sách.
     *
     * @param request Chứa bill_id, wo_id, customer_id, total_amount
     */
    private void UpdateBill(HttpServletRequest request) {
        try {
            int bill_id        = Integer.parseInt(request.getParameter("bill_id"));
            int wo_id          = Integer.parseInt(request.getParameter("wo_id"));
            int customer_id    = Integer.parseInt(request.getParameter("customer_id"));
            double total_amount = Double.parseDouble(request.getParameter("total_amount"));

            BillDAO dao = new BillDAO();
            // Lấy hóa đơn hiện tại để giữ nguyên ngày tạo và trạng thái
            BillDTO currentBill = dao.SearchByBillID(String.valueOf(bill_id));

            if (currentBill == null) {
                // Hóa đơn không tồn tại → báo lỗi và tải lại danh sách
                request.setAttribute("error", "Không tìm thấy hóa đơn cần cập nhật.");
                ListBill(request);
                return;
            }

            // Tạo DTO với dữ liệu mới, giữ nguyên bill_date và status từ DB
            BillDTO bill = new BillDTO(
                    bill_id,
                    wo_id,
                    customer_id,
                    total_amount,
                    currentBill.getBill_date() != null  // Giữ ngày tạo gốc; nếu null thì dùng ngày hiện tại
                            ? currentBill.getBill_date()
                            : new java.sql.Date(System.currentTimeMillis()),
                    currentBill.getStatus() // Giữ nguyên trạng thái (không đổi khi edit thông tin)
            );

            boolean result = dao.UpdateBill(bill);
            if (result) {
                request.setAttribute("msg", "Cập nhật hóa đơn thành công.");
            } else {
                request.setAttribute("error", "Cập nhật hóa đơn thất bại.");
            }

        } catch (Exception e) {
            request.setAttribute("error", "Không thể cập nhật hóa đơn: " + e.getMessage());
        }

        ListBill(request);
    }

    /**
     * Tìm kiếm hóa đơn theo từ khóa (ID hóa đơn, ID WorkOrder, ID khách hàng).
     * Sau đó áp dụng bộ lọc trạng thái nếu có.
     *
     * @param request Chứa "keyword" và tùy chọn "filter"
     */
    private void SearchBill(HttpServletRequest request) {
        String keyword = request.getParameter("keyword");
        BillDAO dao = new BillDAO();

        // Tìm kiếm trong DB trước (DAO có thể dùng LIKE query)
        ArrayList<BillDTO> list = dao.searchBill(keyword);

        // Sau đó áp dụng thêm bộ lọc client-side (trạng thái thanh toán)
        list = getFilteredBills(list, request.getParameter("filter"), keyword);

        populateBillPageData(request, list);
        request.setAttribute("keyword", keyword); // Giữ lại keyword cho ô tìm kiếm
    }

    /**
     * Nạp toàn bộ dữ liệu tham chiếu cần thiết cho trang bill.jsp:
     *   - billList        : Danh sách hóa đơn đã lọc
     *   - workOrders      : Danh sách WO để dropdown chọn khi tạo/sửa bill
     *   - customers       : Danh sách khách hàng cho dropdown
     *   - workOrderMap    : Map id→WO để JSP tra cứu nhanh tên sản phẩm
     *   - customerMap     : Map id→Customer để JSP tra cứu nhanh tên khách
     *   - latestPaymentMap: Map billId→Payment để hiển thị trạng thái thanh toán
     *
     * Ngoài ra, tự động cập nhật Payment sang EXPIRED nếu đã hết thời hạn.
     *
     * @param request  HttpServletRequest để set attribute
     * @param billList Danh sách hóa đơn đã lọc cần hiển thị
     */
    private void populateBillPageData(HttpServletRequest request, ArrayList<BillDTO> billList) {
        WorkOrderDAO workOrderDAO = new WorkOrderDAO();
        CustomerDAO customerDAO   = new CustomerDAO();
        PaymentDAO paymentDAO     = new PaymentDAO();

        // Tải danh sách WO và Customer để điền dropdown
        List<WorkOrderDTO> workOrders = workOrderDAO.getAllWorkOrders();
        List<CustomerDTO> customers   = customerDAO.getAllCustomers();

        // Tạo Map để JSP có thể tra cứu O(1) thay vì duyệt list O(n)
        Map<Integer, WorkOrderDTO> workOrderMap = new HashMap<>();
        Map<Integer, CustomerDTO> customerMap   = new HashMap<>();
        Map<Integer, PaymentDTO> latestPaymentMap = new HashMap<>();

        // Xây dựng map WorkOrder: key=wo_id, value=WorkOrderDTO
        for (WorkOrderDTO workOrder : workOrders) {
            workOrderMap.put(workOrder.getWo_id(), workOrder);
        }

        // Xây dựng map Customer: key=customer_id, value=CustomerDTO
        for (CustomerDTO customer : customers) {
            customerMap.put(customer.getCustomer_id(), customer);
        }

        // Với mỗi hóa đơn, lấy payment mới nhất và kiểm tra hết hạn
        for (BillDTO bill : billList) {
            PaymentDTO latestPayment = paymentDAO.getLatestPaymentByBillId(bill.getBill_id());

            // Kiểm tra nếu payment đã hết hạn nhưng chưa được cập nhật status → tự động cập nhật EXPIRED
            if (latestPayment != null
                    && latestPayment.getExpiresAt() != null         // Có thời hạn thanh toán
                    && !"PAID".equalsIgnoreCase(latestPayment.getStatus()) // Chưa thanh toán
                    && latestPayment.getExpiresAt().before(new java.util.Date())) { // Đã quá hạn

                paymentDAO.updatePaymentStatus(latestPayment.getPaymentId(), "EXPIRED", null);
                latestPayment.setStatus("EXPIRED"); // Cập nhật trong bộ nhớ để JSP đọc ngay
            }

            // Lưu payment mới nhất vào map để JSP tra cứu
            latestPaymentMap.put(bill.getBill_id(), latestPayment);
        }

        // Đưa tất cả dữ liệu vào request để JSP sử dụng
        request.setAttribute("billList",         billList);
        request.setAttribute("workOrders",       new ArrayList<>(workOrders));
        request.setAttribute("customers",        new ArrayList<>(customers));
        request.setAttribute("workOrderMap",     workOrderMap);
        request.setAttribute("customerMap",      customerMap);
        request.setAttribute("latestPaymentMap", latestPaymentMap);
        url = "bill.jsp"; // Trang JSP hiển thị danh sách hóa đơn
    }

    /**
     * Lọc danh sách hóa đơn theo trạng thái thanh toán (filter) và từ khóa (keyword).
     *
     * Trạng thái được tính từ Payment record mới nhất của mỗi hóa đơn:
     *   "paid"    : Payment.status = PAID
     *   "expired" : Payment chưa thanh toán và đã quá expiresAt
     *   "pending" : Không có Payment hoặc chưa thanh toán và chưa hết hạn
     *
     * Lọc "pending" bao gồm cả "expired" (tiện cho người dùng xem hóa đơn chưa xử lý).
     *
     * @param source   Danh sách hóa đơn gốc
     * @param filter   Giá trị lọc: "all", "paid", "pending", "expired" (null → "all")
     * @param keyword  Từ khóa tìm theo bill_id, wo_id, customer_id (null → không lọc)
     * @return Danh sách hóa đơn sau khi lọc
     */
    private ArrayList<BillDTO> getFilteredBills(ArrayList<BillDTO> source, String filter, String keyword) {
        ArrayList<BillDTO> filtered = new ArrayList<>();

        // Chuẩn hóa filter và keyword
        String normalizedFilter  = filter  == null ? "all" : filter.trim().toLowerCase();
        String normalizedKeyword = keyword == null ? ""    : keyword.trim().toLowerCase();

        PaymentDAO paymentDAO = new PaymentDAO();

        for (BillDTO bill : source) {
            // Lấy payment mới nhất để xác định trạng thái thanh toán của hóa đơn
            PaymentDTO latestPayment = paymentDAO.getLatestPaymentByBillId(bill.getBill_id());

            // Xác định trạng thái thanh toán thực tế
            boolean paymentExpired = latestPayment != null
                    && latestPayment.getExpiresAt() != null
                    && !"PAID".equalsIgnoreCase(latestPayment.getStatus())
                    && latestPayment.getExpiresAt().before(new java.util.Date()); // Đã quá hạn

            // Tính trạng thái dẫn xuất: paid > expired > pending
            String derivedStatus = "pending"; // Mặc định: chưa thanh toán
            if (latestPayment != null) {
                if ("PAID".equalsIgnoreCase(latestPayment.getStatus())) {
                    derivedStatus = "paid";    // Đã thanh toán
                } else if (paymentExpired || "EXPIRED".equalsIgnoreCase(latestPayment.getStatus())) {
                    derivedStatus = "expired"; // Quá hạn
                }
            }

            // Kiểm tra điều kiện lọc theo trạng thái
            boolean matchesFilter = "all".equals(normalizedFilter)             // Hiển thị tất cả
                    || normalizedFilter.equals(derivedStatus)                  // Khớp chính xác
                    || ("pending".equals(normalizedFilter)                     // pending bao gồm cả expired
                        && ("pending".equals(derivedStatus) || "expired".equals(derivedStatus)));

            // Kiểm tra điều kiện tìm kiếm theo từ khóa (so sánh ID)
            boolean matchesKeyword = normalizedKeyword.isEmpty()
                    || String.valueOf(bill.getBill_id()).contains(normalizedKeyword)  // Khớp bill_id
                    || String.valueOf(bill.getWo_id()).contains(normalizedKeyword)    // Khớp wo_id
                    || String.valueOf(bill.getCustomer_id()).contains(normalizedKeyword); // Khớp customer_id

            if (matchesFilter && matchesKeyword) {
                filtered.add(bill); // Thêm vào kết quả nếu qua tất cả điều kiện
            }
        }

        return filtered;
    }

    /** Xử lý HTTP GET – xem danh sách, tìm kiếm hóa đơn */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – tạo, cập nhật, xóa hóa đơn */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "Bill Controller – Quản lý hóa đơn bán hàng";
    }
}
