package pms.controllers;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import pms.model.BillDAO;
import pms.model.BillDTO;
import pms.model.BillLineDAO;
import pms.model.BillLineDTO;
import pms.model.CustomerDAO;
import pms.model.CustomerDTO;
import pms.model.ItemDAO;
import pms.model.ItemDTO;
import pms.model.PaymentDAO;
import pms.model.PaymentDTO;
import pms.model.WorkOrderDAO;
import pms.model.WorkOrderDTO;
import pms.utils.EmailService;
import pms.utils.PaymentService;
import pms.utils.PdfInvoiceExporter;
import pms.utils.SystemConfigService;

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
            case "viewBillDetail":
                viewBillDetail(request, response, false);
                return;
            case "downloadBill":
                downloadBill(request, response, false);
                return;
            case "viewPublicBill":
                viewBillDetail(request, response, true);
                return;
            case "downloadPublicBill":
                downloadBill(request, response, true);
                return;
            case "addCustomerForBill":
                addCustomerForBill(request, response);
                return;
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
            int wo_id = parseIntOrDefault(request.getParameter("wo_id"), 0);
            double total_amount = parseDoubleOrDefault(request.getParameter("total_amount"), 0D);

            if (total_amount <= 0) {
                request.setAttribute("error", "Tổng tiền phải lớn hơn 0.");
                ListBill(request);
                return;
            }

            int customer_id = parseIntOrDefault(request.getParameter("customer_id"), 0);
            if (customer_id <= 0) {
                request.setAttribute("error", "Vui lòng chọn khách hàng hợp lệ.");
                ListBill(request);
                return;
            }

            List<BillLineDTO> quoteLines = parseQuoteLines(request);

            BillDAO dao = new BillDAO();
            BillDTO bill = new BillDTO(0, wo_id, customer_id, total_amount,
                    new java.sql.Date(System.currentTimeMillis()),
                    "pending",
                    new Timestamp(System.currentTimeMillis()),
                    null,
                    null,
                    quoteLines);

            int newBillId = dao.insertBillWithLines(bill, quoteLines);
            if (newBillId > 0) {
                PaymentService paymentService = new PaymentService();
                PaymentDTO payment = paymentService.createQrPayment(
                        newBillId,
                        total_amount,
                        1440,
                        null,
                        null
                );

                sendInvoiceEmailPhase1(newBillId, total_amount, customer_id, request, quoteLines, payment);

                String detailLink = "BillController?action=viewBillDetail&bill_id=" + newBillId;
                String downloadLink = "BillController?action=downloadBill&bill_id=" + newBillId;
                request.setAttribute("msg",
                        "Tạo hóa đơn thành công. "
                        + "<a class='font-semibold underline' href='" + detailLink + "'>Xem chi tiết</a>"
                        + " · "
                        + "<a class='font-semibold underline' href='" + downloadLink + "'>Tải hóa đơn</a>"
                        + (payment != null && payment.getPaymentId() > 0 ? " · QR đã sẵn sàng." : " · Chưa tạo được QR."));
            } else {
                request.setAttribute("error", "Tạo hóa đơn thất bại.");
            }

        } catch (Exception e) {
            request.setAttribute("error", "Không thể tạo hóa đơn: " + e.getMessage());
        }

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
        PaymentService paymentService = new PaymentService();

        // Tải danh sách WO, Customer và Item để điền dropdown
        List<WorkOrderDTO> workOrders = workOrderDAO.getAllWorkOrders();
        List<CustomerDTO> customers   = customerDAO.getAllCustomers();
        List<ItemDTO> items           = new ItemDAO().getAllItems();

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

            // Nếu bill chưa có payment thì tự tạo QR để màn hình luôn có Xem QR / Xác nhận / Tạo lại
            if (latestPayment == null && !"paid".equalsIgnoreCase(bill.getStatus())) {
                try {
                    latestPayment = paymentService.createQrPayment(
                            bill.getBill_id(),
                            bill.getTotal_amount(),
                            1440,
                            null,
                            null
                    );
                } catch (Exception ignored) {
                    latestPayment = paymentDAO.getLatestPaymentByBillId(bill.getBill_id());
                }
            }

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
        request.setAttribute("items",            new ArrayList<>(items));
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

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");

    private void addCustomerForBill(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        String customerName = trimToNull(request.getParameter("customer_name"));
        String customerPhone = trimToNull(request.getParameter("phone"));
        String customerEmail = trimToNull(request.getParameter("email"));

        if (customerName == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("{\"success\":false,\"message\":\"Vui lòng nhập tên khách hàng.\"}");
            return;
        }
        if (customerEmail != null && !EMAIL_PATTERN.matcher(customerEmail).matches()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("{\"success\":false,\"message\":\"Email không hợp lệ.\"}");
            return;
        }

        CustomerDAO customerDAO = new CustomerDAO();
        if (customerEmail != null) {
            CustomerDTO existed = customerDAO.SearchByCustomerEmail(customerEmail);
            if (existed != null && existed.getCustomer_id() > 0) {
                response.getWriter().write("{\"success\":true,\"customerId\":" + existed.getCustomer_id()
                        + ",\"customerName\":\"" + escapeJson(existed.getCustomer_name())
                        + "\",\"message\":\"Email đã tồn tại, đã chọn khách hàng hiện có.\"}");
                return;
            }
        }

        boolean inserted = customerDAO.insertCustomer(new CustomerDTO(0, customerName, customerPhone, customerEmail));
        if (!inserted) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"success\":false,\"message\":\"Không thể tạo khách hàng mới.\"}");
            return;
        }

        CustomerDTO created = customerEmail != null
                ? customerDAO.SearchByCustomerEmail(customerEmail)
                : customerDAO.searchCustomers(customerName).stream().findFirst().orElse(null);

        if (created == null || created.getCustomer_id() <= 0) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"success\":false,\"message\":\"Tạo khách hàng thành công nhưng không đọc được dữ liệu trả về.\"}");
            return;
        }

        response.getWriter().write("{\"success\":true,\"customerId\":" + created.getCustomer_id()
                + ",\"customerName\":\"" + escapeJson(created.getCustomer_name()) + "\"}");
    }

    private List<BillLineDTO> parseQuoteLines(HttpServletRequest request) {
        List<BillLineDTO> lines = new ArrayList<>();

        String[] itemTypes = request.getParameterValues("line_item_type");
        String[] quantities = request.getParameterValues("line_quantity");
        String[] unitPrices = request.getParameterValues("line_unit_price");

        if (itemTypes == null || quantities == null || unitPrices == null) {
            return lines;
        }

        int max = Math.min(itemTypes.length, Math.min(quantities.length, unitPrices.length));
        for (int i = 0; i < max; i++) {
            String itemType = trimToNull(itemTypes[i]);
            int qty = parseIntOrDefault(quantities[i], 0);
            double unitPrice = parseDoubleOrDefault(unitPrices[i], 0D);
            if (itemType == null || qty <= 0 || unitPrice <= 0) {
                continue;
            }
            double lineTotal = BigDecimal.valueOf(unitPrice)
                    .multiply(BigDecimal.valueOf(qty))
                    .doubleValue();
            lines.add(new BillLineDTO(0, 0, itemType, qty, unitPrice, lineTotal, null));
        }

        return lines;
    }

    private void sendInvoiceEmailPhase1(int billId, double totalAmount, int customerId,
            HttpServletRequest request, List<BillLineDTO> quoteLines, PaymentDTO payment) {
        try {
            CustomerDAO customerDAO = new CustomerDAO();
            CustomerDTO customer = customerDAO.SearchByCustomerID(String.valueOf(customerId));
            if (customer == null || trimToNull(customer.getEmail()) == null) {
                return;
            }

            SystemConfigService config = new SystemConfigService();
            EmailService emailService = config.createEmailService();
            if (!emailService.isConfigured()) {
                return;
            }

            String baseUrl = buildBaseUrl(request);
            String billCode = String.valueOf(billId);
            String customerName = customer.getCustomer_name() != null ? customer.getCustomer_name() : "Quý khách";
            String viewLink = baseUrl + "/BillController?action=viewPublicBill&bill_id=" + billId;
            String downloadLink = baseUrl + "/BillController?action=downloadPublicBill&bill_id=" + billId;
            BillDAO billDAO = new BillDAO();
            BillDTO bill = billDAO.SearchByBillID(String.valueOf(billId));
            java.util.Date invoiceIssuedAt = bill != null && bill.getBill_created_at() != null
                    ? new java.util.Date(bill.getBill_created_at().getTime())
                    : (bill != null ? bill.getBill_date() : null);
            String invoiceIssuedAtText = invoiceIssuedAt != null
                    ? new SimpleDateFormat("dd/MM/yyyy HH:mm").format(invoiceIssuedAt)
                    : "-";
            String paymentStatus = payment != null && payment.getStatus() != null ? payment.getStatus().toUpperCase() : "PENDING";
            String paymentStatusLabel = "Chờ thanh toán";
            if ("PAID".equals(paymentStatus)) {
                paymentStatusLabel = "Đã thanh toán";
            } else if ("EXPIRED".equals(paymentStatus)) {
                paymentStatusLabel = "Hết hạn";
            }


            StringBuilder linesHtml = new StringBuilder();
            if (quoteLines != null && !quoteLines.isEmpty()) {
                linesHtml.append("<table style='width:100%;border-collapse:collapse;margin-top:12px'>")
                        .append("<thead><tr>")
                        .append("<th style='text-align:left;border:1px solid #dbeafe;padding:8px'>Sản phẩm</th>")
                        .append("<th style='text-align:right;border:1px solid #dbeafe;padding:8px'>SL</th>")
                        .append("<th style='text-align:right;border:1px solid #dbeafe;padding:8px'>Đơn giá</th>")
                        .append("<th style='text-align:right;border:1px solid #dbeafe;padding:8px'>Thành tiền</th>")
                        .append("</tr></thead><tbody>");
                for (BillLineDTO line : quoteLines) {
                    linesHtml.append("<tr>")
                            .append("<td style='border:1px solid #e5e7eb;padding:8px'>").append(escapeHtml(line.getItemType())).append("</td>")
                            .append("<td style='border:1px solid #e5e7eb;padding:8px;text-align:right'>").append(line.getQuantity()).append("</td>")
                            .append("<td style='border:1px solid #e5e7eb;padding:8px;text-align:right'>").append(String.format("%,.0f", line.getUnitPrice())).append(" VND</td>")
                            .append("<td style='border:1px solid #e5e7eb;padding:8px;text-align:right'>").append(String.format("%,.0f", line.getLineTotal())).append(" VND</td>")
                            .append("</tr>");
                }
                linesHtml.append("</tbody></table>");
            }

            StringBuilder body = new StringBuilder();
            body.append("<!DOCTYPE html><html><head><meta charset='UTF-8'></head><body style='font-family:Segoe UI,Arial,sans-serif;background:#f8fafc;padding:20px'>")
                    .append("<div style='max-width:760px;margin:0 auto;background:#fff;border:1px solid #dbeafe;border-radius:14px;overflow:hidden'>")
                    .append("<div style='background:linear-gradient(120deg,#047857,#0ea5e9);padding:18px 22px;color:#fff'>")
                    .append("<div style='font-size:12px;opacity:.9;letter-spacing:.1em'>PMS INVOICE</div>")
                    .append("<h2 style='margin:6px 0 0'>Hóa đơn #").append(billCode).append("</h2>")
                    .append("</div>")
                    .append("<div style='padding:20px'>")
                    .append("<p>Xin chào <strong>").append(escapeHtml(customerName)).append("</strong>, hóa đơn của bạn đã được tạo thành công.</p>")
                    .append("<p><strong>Ngày lập:</strong> ").append(invoiceIssuedAtText).append("</p>")
                    .append("<p><strong>Trạng thái:</strong> ").append(paymentStatusLabel).append("</p>")
                    .append("<p><strong>Tổng tiền:</strong> ").append(String.format("%,.0f", totalAmount)).append(" VND</p>")
                    .append(linesHtml)
                    .append("<div style='margin-top:16px'>")
                    .append("<a href='").append(viewLink).append("' style='display:inline-block;margin-right:8px;background:#0f766e;color:#fff;padding:10px 14px;border-radius:8px;text-decoration:none'>Xem hóa đơn</a>")
                    .append("<a href='").append(downloadLink).append("' style='display:inline-block;margin-right:8px;background:#1d4ed8;color:#fff;padding:10px 14px;border-radius:8px;text-decoration:none'>Tải hóa đơn</a>")
                    .append("</div>");

            body.append("<p style='margin-top:18px;color:#64748b;font-size:12px'>Bạn có thể mở lại liên kết xem/tải hóa đơn bất kỳ lúc nào, kể cả sau khi thanh toán.</p>")
                    .append("</div></div></body></html>");

            boolean sent = emailService.sendEmail(
                    customer.getEmail(),
                    "[PMS] Hóa đơn #" + billCode + " - Thông tin thanh toán",
                    body.toString()
            );

            if (!sent) {
                request.setAttribute("msg", "Tạo hóa đơn thành công nhưng chưa gửi được email yêu cầu thanh toán.");
            }
        } catch (Exception ignored) {
            // Không chặn luồng tạo Bill nếu email lỗi
        }
    }

    private void viewBillDetail(HttpServletRequest request, HttpServletResponse response, boolean publicView)
            throws ServletException, IOException {
        int billId = parseIntOrDefault(request.getParameter("bill_id"), 0);
        if (billId <= 0) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thiếu bill_id hợp lệ");
            return;
        }

        BillDAO billDAO = new BillDAO();
        BillDTO bill = billDAO.SearchByBillID(String.valueOf(billId));
        if (bill == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy hóa đơn");
            return;
        }

        CustomerDTO customer = null;
        if (bill.getCustomer_id() > 0) {
            customer = new CustomerDAO().SearchByCustomerID(String.valueOf(bill.getCustomer_id()));
        }

        PaymentDTO payment = new PaymentDAO().getLatestPaymentByBillId(billId);
        List<BillLineDTO> lines = new BillLineDAO().getByBillId(billId);

        request.setAttribute("detailBill", bill);
        request.setAttribute("detailCustomer", customer);
        request.setAttribute("detailPayment", payment);
        request.setAttribute("detailLines", lines);
        request.setAttribute("isPublicInvoiceView", publicView);
        request.getRequestDispatcher("bill-detail.jsp").forward(request, response);
    }

    private void downloadBill(HttpServletRequest request, HttpServletResponse response, boolean publicDownload)
            throws IOException {
        int billId = parseIntOrDefault(request.getParameter("bill_id"), 0);
        if (billId <= 0) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thiếu bill_id hợp lệ");
            return;
        }

        BillDAO billDAO = new BillDAO();
        BillDTO bill = billDAO.SearchByBillID(String.valueOf(billId));
        if (bill == null) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "Không tìm thấy hóa đơn");
            return;
        }

        CustomerDTO customer = bill.getCustomer_id() > 0
                ? new CustomerDAO().SearchByCustomerID(String.valueOf(bill.getCustomer_id()))
                : null;
        PaymentDTO payment = new PaymentDAO().getLatestPaymentByBillId(billId);
        List<BillLineDTO> lines = new BillLineDAO().getByBillId(billId);

        DecimalFormat money = new DecimalFormat("#,###");
        SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");

        String status = "Chờ thanh toán";
        if (payment != null) {
            if ("PAID".equalsIgnoreCase(payment.getStatus())) {
                status = "Đã thanh toán";
            } else if ("EXPIRED".equalsIgnoreCase(payment.getStatus())) {
                status = "Hết hạn";
            }
        }

        SystemConfigService configService = new SystemConfigService();
        String companyName = trimToNull(configService.getCompanyName()) != null ? configService.getCompanyName() : "PMS MANUFACTURING";
        String companyAddress = trimToNull(configService.getCompanyAddress()) != null ? configService.getCompanyAddress() : "Địa chỉ chưa cập nhật";
        String companyPhone = trimToNull(configService.getCompanyPhone()) != null ? configService.getCompanyPhone() : "Chưa cập nhật";
        String companyEmail = trimToNull(configService.getAdminEmail()) != null ? configService.getAdminEmail() : trimToNull(configService.getSmtpUser());
        if (companyEmail == null) {
            companyEmail = "Chưa cập nhật";
        }

        String paymentCode = (payment != null && payment.getPaymentId() > 0)
                ? String.format("PAY-%04d", payment.getPaymentId())
                : "-";
        String paidAt = (payment != null && payment.getPaidAt() != null)
                ? sdf.format(payment.getPaidAt())
                : "-";
        String bankName = resolveBankName(payment != null ? payment.getBankBin() : null);
        String bankAccount = payment != null && trimToNull(payment.getBankAccount()) != null ? payment.getBankAccount() : "-";
        String bankAccountName = payment != null && trimToNull(payment.getBankAccountName()) != null ? payment.getBankAccountName() : "-";

        byte[] pdfBytes = PdfInvoiceExporter.exportInvoice(
                bill,
                customer,
                payment,
                lines,
                companyName,
                companyAddress,
                companyPhone,
                companyEmail
        );

        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=hoa-don-" + billId + ".pdf");
        response.setContentLength(pdfBytes.length);
        response.getOutputStream().write(pdfBytes);
        response.getOutputStream().flush();
    }

    private String buildBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String host = request.getServerName();
        int port = request.getServerPort();
        boolean defaultPort = ("http".equalsIgnoreCase(scheme) && port == 80)
                || ("https".equalsIgnoreCase(scheme) && port == 443);
        return scheme + "://" + host + (defaultPort ? "" : ":" + port) + request.getContextPath();
    }

    private int parseIntOrDefault(String raw, int defaultValue) {
        try {
            return Integer.parseInt(raw != null ? raw.trim() : "");
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private double parseDoubleOrDefault(String raw, double defaultValue) {
        try {
            return Double.parseDouble(raw != null ? raw.trim() : "");
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private String trimToNull(String value) {
        if (value == null) return null;
        String s = value.trim();
        return s.isEmpty() ? null : s;
    }

    private String resolveBankName(String bankBin) {
        String code = trimToNull(bankBin);
        if (code == null) return "-";
        switch (code) {
            case "970403": return "Sacombank";
            case "970405": return "Agribank";
            case "970407": return "Techcombank";
            case "970415": return "VietinBank";
            case "970416": return "ACB";
            case "970418": return "BIDV";
            case "970422": return "MB Bank";
            case "970423": return "TPBank";
            case "970432": return "VPBank";
            case "970436": return "Vietcombank";
            case "970437": return "HDBank";
            case "970441": return "VIB";
            case "970443": return "SHB";
            case "970448": return "OCB";
            default: return "Ngân hàng khác";
        }
    }

    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
    }

    private String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "\\n");
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
