package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.BOMDAO;
import pms.model.BOMDTO;
import pms.model.BOMDetailDTO;
import pms.model.ItemDAO;
import pms.model.ItemDTO;

/**
 * BOMController – Servlet điều phối toàn bộ các hành động liên quan đến BOM
 * (Bill of Materials – Danh sách nguyên vật liệu).
 *
 * BOM mô tả một sản phẩm được tạo ra từ những nguyên liệu nào, với số lượng bao nhiêu.
 * Ví dụ: BOM cho "Xe đạp" = { Khung xe x1, Bánh xe x2, Xích x1, ... }
 *
 * Các action được hỗ trợ:
 *   - listBOM / list       : Xem danh sách tất cả BOM
 *   - searchBOM / search   : Lọc BOM theo tên sản phẩm và/hoặc trạng thái
 *   - addBOM               : Hiển thị form tạo BOM mới
 *   - saveAddBOM           : Lưu BOM mới (với danh sách nguyên liệu)
 *   - editBOM              : Hiển thị form sửa BOM đã có
 *   - saveUpdateBOM        : Lưu thay đổi BOM (xóa chi tiết cũ, insert lại mới)
 *   - viewBOM              : Xem chi tiết BOM
 *   - cloneBOM             : Sao chép BOM sang phiên bản mới
 *   - deleteBOM            : Xóa BOM
 *   - activateBOM          : Chuyển trạng thái về "active"
 *   - deactivateBOM        : Chuyển trạng thái về "inactive"
 *   - addDetail            : Thêm một dòng nguyên liệu vào BOM (inline từ trang chi tiết)
 *   - updateDetail         : Sửa một dòng nguyên liệu
 *   - deleteDetail         : Xóa một dòng nguyên liệu
 *
 * Thread-safety: Servlet là singleton. Không dùng instance field để lưu
 * trạng thái request. Mọi biến URL đều là biến cục bộ trong method.
 *
 * Flash message: Dùng session attribute "flashMsg"/"flashError" thay vì
 * request attribute để message vượt qua redirect (PRG Pattern).
 */
public class BOMController extends HttpServlet {

    // ---------------------------------------------------------------------------
    // Hằng số dùng chung – tránh magic string phân tán trong code
    // ---------------------------------------------------------------------------

    /** Tên attribute lưu thông báo thành công trong session/request */
    private static final String ATTR_MSG   = "msg";

    /** Tên attribute lưu thông báo lỗi trong session/request */
    private static final String ATTR_ERROR = "error";

    /** Tên attribute lưu đối tượng BOM chính trong request */
    private static final String ATTR_BOM   = "bom";

    /** URL redirect về danh sách BOM qua MainController */
    private static final String REDIRECT_LIST = "redirect:MainController?action=listBOM";

    // ---------------------------------------------------------------------------
    // Điểm vào chính – phân luồng theo tham số "action"
    // ---------------------------------------------------------------------------

    /**
     * Điểm vào chung cho cả GET và POST.
     * Đọc tham số "action" rồi gọi method xử lý tương ứng.
     * Mỗi method trả về chuỗi URL (biến cục bộ, không phải field).
     * Nếu URL bắt đầu bằng "redirect:" → sendRedirect, ngược lại → forward JSP.
     *
     * @param request  HttpServletRequest chứa toàn bộ tham số từ trình duyệt
     * @param response HttpServletResponse dùng để forward hoặc redirect
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8 cho cả request lẫn response để hỗ trợ tiếng Việt
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action từ query string; mặc định là "listBOM" nếu không có
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "listBOM";
        }

        // Biến cục bộ URL – an toàn với đa luồng (thread-safe)
        String url;

        // Phân luồng theo action
        switch (action) {
            case "list":
            case "listBOM":
                url = listBOMs(request);       // Hiển thị danh sách tất cả BOM
                break;
            case "search":
            case "searchBOM":
                url = searchBOMs(request);     // Tìm kiếm BOM theo từ khóa + trạng thái
                break;
            case "addBOM":
                url = showAddForm(request);    // Hiển thị form tạo BOM mới
                break;
            case "saveAddBOM":
                url = addBOM(request);         // Lưu BOM mới vào DB
                break;
            case "editBOM":
                url = showEditForm(request);   // Hiển thị form sửa BOM
                break;
            case "saveUpdateBOM":
                url = updateBOM(request);      // Lưu thay đổi BOM vào DB
                break;
            case "viewBOM":
                url = viewBOM(request);        // Xem chi tiết BOM và danh sách nguyên liệu
                break;
            case "cloneBOM":
                url = cloneBOM(request);       // Sao chép BOM sang phiên bản mới
                break;
            case "deleteBOM":
                url = deleteBOM(request);      // Xóa BOM khỏi hệ thống
                break;
            case "activateBOM":
                url = activateBOM(request);    // Đặt trạng thái "active"
                break;
            case "deactivateBOM":
                url = deactivateBOM(request);  // Đặt trạng thái "inactive"
                break;
            case "addDetail":
                url = addDetail(request);      // Thêm một dòng nguyên liệu vào BOM
                break;
            case "updateDetail":
                url = updateDetail(request);   // Sửa một dòng nguyên liệu
                break;
            case "deleteDetail":
                url = deleteDetail(request);   // Xóa một dòng nguyên liệu
                break;
            default:
                url = REDIRECT_LIST;           // Action không xác định → về danh sách
                break;
        }

        // Quyết định forward hay redirect dựa vào tiền tố "redirect:"
        if (url != null && url.startsWith("redirect:")) {
            response.sendRedirect(url.substring(9)); // HTTP 302, browser tự GET lại
        } else {
            request.getRequestDispatcher(url).forward(request, response); // Giữ nguyên request
        }
    }

    // ---------------------------------------------------------------------------
    // Danh sách BOM
    // ---------------------------------------------------------------------------

    /**
     * Tải toàn bộ danh sách BOM rồi forward tới bom-list.jsp.
     * Gọi loadBomListData() để nạp cả dữ liệu tham chiếu (products, materials) vào request.
     *
     * @return URL trang danh sách BOM
     */
    private String listBOMs(HttpServletRequest request) {
        loadBomListData(request); // Nạp danh sách BOM + dropdown tham chiếu vào request
        return "bom-list.jsp";
    }

    // ---------------------------------------------------------------------------
    // Tìm kiếm BOM
    // ---------------------------------------------------------------------------

    /**
     * Tìm kiếm BOM theo từ khóa (tên sản phẩm) và/hoặc trạng thái.
     * Lọc client-side: load toàn bộ DB rồi dùng removeIf() trong Java.
     * Giữ lại keyword và status để JSP hiển thị lại bộ lọc đã chọn.
     *
     * @return URL trang danh sách BOM sau khi lọc
     */
    private String searchBOMs(HttpServletRequest request) {
        BOMDAO dao = new BOMDAO();

        String keyword = request.getParameter("keyword"); // Từ khóa tìm theo tên sản phẩm
        String status  = request.getParameter("status");  // Lọc theo trạng thái (active/inactive/all)

        List<BOMDTO> boms = dao.getAllBOMS(); // Load toàn bộ BOM làm điểm xuất phát

        // Lọc theo keyword (không phân biệt hoa/thường)
        if (keyword != null && !keyword.trim().isEmpty()) {
            final String kw = keyword.trim().toLowerCase();
            boms.removeIf(b -> b.getProductName() == null
                    || !b.getProductName().toLowerCase().contains(kw));
        }

        // Lọc theo trạng thái nếu không phải "all" hoặc rỗng
        if (status != null && !status.trim().isEmpty() && !status.equalsIgnoreCase("all")) {
            final String st = status.trim();
            boms.removeIf(b -> b.getStatus() == null || !b.getStatus().equalsIgnoreCase(st));
        }

        loadBomReferenceData(request);              // Nạp dropdown cho bộ lọc
        request.setAttribute("boms",    boms);     // Kết quả sau lọc
        request.setAttribute("keyword", keyword);  // Giữ keyword để JSP hiển thị lại form
        request.setAttribute("status",  status);   // Giữ trạng thái đã chọn
        return "bom-list.jsp";
    }

    // ---------------------------------------------------------------------------
    // Xem chi tiết BOM
    // ---------------------------------------------------------------------------

    /**
     * Lấy thông tin chi tiết của một BOM theo ID và forward tới bom-detail.jsp.
     * Nếu ID không hợp lệ hoặc BOM không tồn tại → redirect về danh sách với thông báo lỗi.
     *
     * @return URL trang chi tiết BOM hoặc redirect về danh sách nếu lỗi
     */
    private String viewBOM(HttpServletRequest request) {
        String s_id = request.getParameter("id"); // ID dạng chuỗi từ URL

        int id;
        try {
            id = Integer.parseInt(s_id); // Parse sang int; ném NumberFormatException nếu sai
        } catch (NumberFormatException e) {
            request.setAttribute(ATTR_ERROR, "ID BOM không hợp lệ: " + s_id);
            return REDIRECT_LIST;
        }

        BOMDAO dao = new BOMDAO();
        BOMDTO bom = dao.getBOMById(id); // Truy vấn DB lấy BOM kèm danh sách chi tiết

        if (bom == null) {
            // BOM không tồn tại hoặc đã bị xóa
            request.setAttribute(ATTR_ERROR, "Không tìm thấy BOM với ID = " + id);
            return REDIRECT_LIST;
        }

        request.setAttribute(ATTR_BOM, bom); // Truyền BOM vào request để JSP hiển thị
        return "bom-detail.jsp";
    }

    // ---------------------------------------------------------------------------
    // Form thêm BOM mới
    // ---------------------------------------------------------------------------

    /**
     * Chuẩn bị dữ liệu và hiển thị form tạo BOM mới.
     * Nạp danh sách sản phẩm và nguyên liệu vào các dropdown của form.
     *
     * @return URL trang form BOM ở chế độ thêm mới
     */
    private String showAddForm(HttpServletRequest request) {
        loadBomReferenceData(request);       // Nạp products + materials cho dropdown
        request.setAttribute("mode", "add"); // Báo JSP đang ở chế độ thêm mới
        return "bom-form.jsp";
    }

    // ---------------------------------------------------------------------------
    // Form sửa BOM
    // ---------------------------------------------------------------------------

    /**
     * Tải thông tin BOM cần sửa và hiển thị form edit.
     * Nếu BOM không tồn tại → redirect về danh sách với thông báo lỗi.
     *
     * @return URL trang form BOM ở chế độ cập nhật
     */
    private String showEditForm(HttpServletRequest request) {
        String s_id = request.getParameter("id");

        int id;
        try {
            id = Integer.parseInt(s_id);
        } catch (NumberFormatException e) {
            request.setAttribute(ATTR_ERROR, "ID BOM không hợp lệ: " + s_id);
            return REDIRECT_LIST;
        }

        BOMDAO dao = new BOMDAO();
        BOMDTO bom = dao.getBOMById(id); // Lấy BOM cần edit từ DB

        if (bom == null) {
            request.setAttribute(ATTR_ERROR, "Không tìm thấy BOM với ID = " + id);
            return REDIRECT_LIST;
        }

        loadBomReferenceData(request);            // Nạp dropdown products/materials
        request.setAttribute(ATTR_BOM, bom);     // Truyền BOM đang edit vào form
        request.setAttribute("mode", "update");  // Báo JSP đang ở chế độ cập nhật
        return "bom-form.jsp";
    }

    // ---------------------------------------------------------------------------
    // Lưu BOM mới vào DB
    // ---------------------------------------------------------------------------

    /**
     * Đọc dữ liệu từ form thêm BOM, validate, rồi lưu header và chi tiết nguyên liệu vào DB.
     *
     * Quy trình:
     *   1. Parse productItemId và notes từ request.
     *   2. extractDetails() để lấy danh sách chi tiết nguyên liệu từ mảng input.
     *   3. Validate: ít nhất một nguyên liệu.
     *   4. INSERT BOM header → lấy bomId mới → INSERT từng BOMDetail.
     *   5. Thành công: redirect về danh sách (PRG Pattern).
     *   6. Thất bại: quay lại form với dữ liệu đã nhập và thông báo lỗi.
     *
     * @return URL redirect (thành công) hoặc URL forward về form (thất bại)
     */
    private String addBOM(HttpServletRequest request) {
        String error = "";
        BOMDTO bom = new BOMDTO(); // DTO tạm để giữ lại dữ liệu nếu có lỗi, tránh mất form

        try {
            // Parse các trường bắt buộc; ném NumberFormatException nếu sai định dạng
            int productItemId = Integer.parseInt(request.getParameter("productItemId"));
            String notes      = request.getParameter("notes");

            // Trích xuất danh sách nguyên liệu từ mảng input của form
            List<BOMDetailDTO> details = extractDetails(request);

            // Validate: phải có ít nhất 1 nguyên liệu trong BOM
            if (details.isEmpty()) {
                throw new IllegalArgumentException("Vui lòng thêm ít nhất một nguyên liệu cho BOM");
            }

            // Thiết lập BOM header
            bom.setProductItemId(productItemId);
            bom.setBomVersion(generateDefaultVersion(productItemId)); // Tự tạo version tiếp theo (v1.0, v2.0...)
            bom.setStatus("active"); // BOM mới luôn bắt đầu ở trạng thái active
            bom.setNotes(notes);
            bom.setDetails(details);

            BOMDAO dao = new BOMDAO();

            // INSERT BOM header vào DB; DAO phải gán bomId mới vào đối tượng bom sau khi insert
            if (dao.insertBOM(bom)) {
                // INSERT từng dòng chi tiết nguyên liệu
                for (BOMDetailDTO detail : details) {
                    detail.setBomId(bom.getBomId()); // Gán bomId vừa sinh cho mỗi detail
                    if (!dao.addBOMDetail(detail)) {
                        throw new IllegalStateException("Không thể lưu nguyên liệu cho BOM");
                    }
                }
                return REDIRECT_LIST; // Thành công → redirect để tránh submit lại khi F5
            } else {
                error = "Không thể tạo BOM mới – vui lòng thử lại";
            }

        } catch (Exception e) {
            error = "Lỗi: " + e.getMessage();

            // Cố khôi phục dữ liệu form để người dùng không phải nhập lại
            try {
                bom.setProductItemId(Integer.parseInt(request.getParameter("productItemId")));
            } catch (NumberFormatException ignore) {
                // productItemId không hợp lệ; giữ giá trị mặc định 0
            }
            bom.setNotes(request.getParameter("notes"));
            try {
                bom.setDetails(extractDetails(request)); // Cố giữ lại dữ liệu chi tiết người dùng đã nhập
            } catch (Exception ignore) {
                bom.setDetails(new ArrayList<>()); // Parse lỗi → để rỗng
            }
        }

        // Thất bại → trả về form với dữ liệu cũ và thông báo lỗi
        loadBomReferenceData(request);
        request.setAttribute(ATTR_BOM, bom);
        request.setAttribute(ATTR_ERROR, error);
        request.setAttribute("mode", "add");
        return "bom-form.jsp";
    }

    // ---------------------------------------------------------------------------
    // Trích xuất chi tiết nguyên liệu từ form
    // ---------------------------------------------------------------------------

    /**
     * Đọc các mảng input từ form HTML (materialItemId[], quantityRequired[], v.v.)
     * và chuyển thành List&lt;BOMDetailDTO&gt;.
     *
     * Dòng được bỏ qua nếu cả materialId lẫn quantity đều rỗng (dòng trống chưa điền).
     * Nếu materialId hoặc quantity không phải số hợp lệ → ném IllegalArgumentException
     * kèm chỉ số dòng để người dùng biết dòng nào sai.
     *
     * @return Danh sách BOMDetailDTO đã parse; rỗng nếu không có dữ liệu
     * @throws IllegalArgumentException nếu dữ liệu nhập vào không hợp lệ
     */
    private List<BOMDetailDTO> extractDetails(HttpServletRequest request) {
        // Lấy các mảng tham số từ form; trả về null nếu input không tồn tại
        String[] materialIds   = request.getParameterValues("materialItemId[]");
        String[] quantities    = request.getParameterValues("quantityRequired[]");
        String[] units         = request.getParameterValues("unit[]");
        String[] wastePercents = request.getParameterValues("wastePercent[]");
        String[] notes         = request.getParameterValues("detailNotes[]");

        List<BOMDetailDTO> details = new ArrayList<>();

        // Bảo vệ null: nếu không có dòng nào thì trả về list rỗng
        if (materialIds == null || quantities == null) {
            return details;
        }

        for (int i = 0; i < materialIds.length; i++) {
            String materialIdValue = materialIds[i] != null ? materialIds[i].trim() : "";
            String quantityValue   = (i < quantities.length && quantities[i] != null)
                                     ? quantities[i].trim() : "";

            // Bỏ qua dòng hoàn toàn rỗng (người dùng chưa điền vào)
            if (materialIdValue.isEmpty() && quantityValue.isEmpty()) {
                continue;
            }

            // Parse materialId; thêm chỉ số dòng vào message lỗi để dễ debug
            int materialId;
            double quantity;
            try {
                materialId = Integer.parseInt(materialIdValue);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(
                        "Mã nguyên liệu không hợp lệ ở dòng " + (i + 1) + ": \"" + materialIdValue + "\"");
            }
            try {
                quantity = Double.parseDouble(quantityValue);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException(
                        "Số lượng không hợp lệ ở dòng " + (i + 1) + ": \"" + quantityValue + "\"");
            }

            // Tạo và điền dữ liệu cho đối tượng chi tiết
            BOMDetailDTO detail = new BOMDetailDTO();
            detail.setMaterialItemId(materialId);
            detail.setQuantityRequired(quantity);
            detail.setUnit(getArrayValue(units, i));                           // Đơn vị (kg, cái, m...)
            detail.setWastePercent(parseDoubleOrDefault(wastePercents, i, 0.0)); // Tỷ lệ hao hụt; mặc định 0
            detail.setNotes(getArrayValue(notes, i));                          // Ghi chú cho dòng này
            details.add(detail);
        }

        return details;
    }

    // ---------------------------------------------------------------------------
    // Tiện ích: đọc phần tử mảng an toàn
    // ---------------------------------------------------------------------------

    /**
     * Lấy phần tử tại vị trí index của mảng chuỗi một cách an toàn (null-safe, bounds-safe).
     * Trả về chuỗi rỗng nếu mảng null, index vượt giới hạn, hoặc phần tử null.
     *
     * @param values Mảng chuỗi nguồn (có thể null)
     * @param index  Chỉ số cần lấy
     * @return Giá trị đã trim, hoặc "" nếu không hợp lệ
     */
    private String getArrayValue(String[] values, int index) {
        if (values == null || index >= values.length || values[index] == null) {
            return ""; // Trả về rỗng thay vì ném exception
        }
        return values[index].trim();
    }

    // ---------------------------------------------------------------------------
    // Tiện ích: parse double với giá trị mặc định
    // ---------------------------------------------------------------------------

    /**
     * Parse phần tử mảng thành double; trả về defaultValue nếu không thể parse.
     * Dùng cho wastePercent – không bắt buộc nhập, mặc định 0.
     *
     * @param values       Mảng chuỗi nguồn
     * @param index        Chỉ số cần parse
     * @param defaultValue Giá trị trả về nếu parse thất bại
     * @return Giá trị double, hoặc defaultValue
     */
    private double parseDoubleOrDefault(String[] values, int index, double defaultValue) {
        if (values == null || index >= values.length
                || values[index] == null || values[index].trim().isEmpty()) {
            return defaultValue; // Rỗng hoặc null → trả về mặc định
        }
        try {
            return Double.parseDouble(values[index].trim());
        } catch (NumberFormatException e) {
            return defaultValue; // Không parse được → trả về mặc định, không crash
        }
    }

    // ---------------------------------------------------------------------------
    // Tự động tạo version BOM tiếp theo
    // ---------------------------------------------------------------------------

    /**
     * Tìm phiên bản BOM lớn nhất hiện tại của sản phẩm và trả về phiên bản kế tiếp.
     *
     * Cách hoạt động:
     *   - Lấy tất cả BOM của sản phẩm đó, tìm version lớn nhất dạng "vN.M".
     *   - Trả về "v(N+1).0". Ví dụ: đã có v1.0, v2.0 → trả về "v3.0".
     *   - Nếu chưa có BOM nào → trả về "v1.0".
     *
     * @param productItemId ID sản phẩm cần tạo BOM
     * @return Chuỗi version dạng "vN.0"
     */
    private String generateDefaultVersion(int productItemId) {
        BOMDAO dao = new BOMDAO();
        int nextVersion = 1; // Bắt đầu từ v1.0 nếu chưa có BOM nào

        for (BOMDTO existing : dao.getBOMSByProduct(productItemId)) {
            String version = existing.getBomVersion();
            if (version == null || !version.startsWith("v")) {
                continue; // Bỏ qua version không đúng format "vN.M"
            }
            try {
                // Cắt "v" → lấy phần trước dấu "." → parse thành số nguyên
                String normalized = version.substring(1);         // Bỏ tiền tố "v"
                int current = Integer.parseInt(normalized.split("\\.")[0]); // Lấy số chính
                if (current >= nextVersion) {
                    nextVersion = current + 1; // Tiếp theo = lớn nhất hiện tại + 1
                }
            } catch (Exception ignore) {
                // Version không parse được thì bỏ qua, giữ nextVersion cũ
            }
        }
        return "v" + nextVersion + ".0"; // Trả về version tiếp theo
    }

    // ---------------------------------------------------------------------------
    // Cập nhật BOM đã tồn tại
    // ---------------------------------------------------------------------------

    /**
     * Đọc dữ liệu form edit, validate, rồi update BOM header và toàn bộ chi tiết nguyên liệu.
     *
     * Chiến lược cập nhật chi tiết (delete-insert pattern):
     *   Xóa toàn bộ chi tiết cũ rồi insert lại mới → đơn giản, đảm bảo chuẩn hóa.
     *
     * Nếu form không cung cấp version/status → giữ nguyên từ DB.
     * bomId được parse trước try-catch chính để tái sử dụng trong catch block.
     *
     * @return URL redirect (thành công) hoặc URL forward về form (thất bại)
     */
    private String updateBOM(HttpServletRequest request) {
        String error = "";

        // Parse bomId ngoài try-catch chính để có thể dùng lại trong recover
        int id;
        try {
            id = Integer.parseInt(request.getParameter("id"));
        } catch (NumberFormatException e) {
            request.setAttribute(ATTR_ERROR, "ID BOM không hợp lệ");
            return REDIRECT_LIST;
        }

        try {
            int productItemId = Integer.parseInt(request.getParameter("productItemId"));
            String notes      = request.getParameter("notes");
            List<BOMDetailDTO> details = extractDetails(request);

            // Validate: ít nhất 1 nguyên liệu
            if (details.isEmpty()) {
                throw new IllegalArgumentException("Vui lòng thêm ít nhất một nguyên liệu cho BOM");
            }

            BOMDAO dao = new BOMDAO();
            BOMDTO existingBom = dao.getBOMById(id); // Lấy BOM hiện tại để kế thừa version/status nếu form để rỗng

            // Giữ nguyên version/status từ DB nếu form không cung cấp
            String version = request.getParameter("version");
            String status  = request.getParameter("status");
            if ((version == null || version.trim().isEmpty()) && existingBom != null) {
                version = existingBom.getBomVersion();
            }
            if ((status == null || status.trim().isEmpty()) && existingBom != null) {
                status = existingBom.getStatus();
            }

            // Tạo DTO chứa dữ liệu sẽ được UPDATE
            BOMDTO bom = new BOMDTO();
            bom.setBomId(id);
            bom.setProductItemId(productItemId);
            bom.setBomVersion(version);
            bom.setStatus(status);
            bom.setNotes(notes);

            if (dao.updateBOM(bom)) {
                // Xóa toàn bộ chi tiết cũ trước khi insert mới (delete-insert pattern)
                if (!dao.deleteBOMDetailsByBomId(id)) {
                    throw new IllegalStateException("Không thể làm mới danh sách nguyên liệu của BOM");
                }
                for (BOMDetailDTO detail : details) {
                    detail.setBomId(id); // Gán lại bomId cho mỗi detail mới
                    if (!dao.addBOMDetail(detail)) {
                        throw new IllegalStateException("Không thể cập nhật nguyên liệu cho BOM");
                    }
                }
                return REDIRECT_LIST; // Thành công → redirect để ngăn F5 submit lại
            } else {
                error = "Không thể cập nhật BOM – vui lòng thử lại";
            }

        } catch (Exception e) {
            error = "Lỗi: " + e.getMessage();
        }

        // Lấy lại dữ liệu BOM từ DB để tái điền vào form khi có lỗi
        BOMDAO dao = new BOMDAO();
        BOMDTO bom = dao.getBOMById(id); // id đã parse an toàn ở trên
        if (bom != null) {
            try {
                bom.setProductItemId(Integer.parseInt(request.getParameter("productItemId")));
            } catch (NumberFormatException ignore) {}
            bom.setNotes(request.getParameter("notes"));
            try {
                bom.setDetails(extractDetails(request)); // Khôi phục chi tiết người dùng đã nhập
            } catch (Exception ignore) {
                bom.setDetails(new ArrayList<>()); // Parse lỗi → để rỗng
            }
        }

        loadBomReferenceData(request);
        request.setAttribute(ATTR_BOM, bom);
        request.setAttribute(ATTR_ERROR, error);
        request.setAttribute("mode", "update");
        return "bom-form.jsp";
    }

    // ---------------------------------------------------------------------------
    // Nạp dữ liệu cho trang danh sách BOM
    // ---------------------------------------------------------------------------

    /**
     * Nạp toàn bộ danh sách BOM và dữ liệu tham chiếu (products, materials) vào request.
     * Dùng bởi listBOMs() và bất kỳ nơi nào cần hiển thị danh sách đầy đủ.
     */
    private void loadBomListData(HttpServletRequest request) {
        BOMDAO dao = new BOMDAO();
        request.setAttribute("boms", dao.getAllBOMS()); // Tất cả BOM từ DB
        loadBomReferenceData(request);                  // Dropdown products/materials cho bộ lọc
    }

    // ---------------------------------------------------------------------------
    // Nạp dữ liệu tham chiếu (dropdown)
    // ---------------------------------------------------------------------------

    /**
     * Nạp danh sách sản phẩm (products) và nguyên liệu (materials) vào request.
     * Dùng bởi mọi trang cần dropdown để chọn sản phẩm/nguyên liệu.
     */
    private void loadBomReferenceData(HttpServletRequest request) {
        ItemDAO itemDao = new ItemDAO();
        request.setAttribute("products",  itemDao.getProducts());  // Thành phẩm/bán thành phẩm
        request.setAttribute("materials", itemDao.getMaterials()); // Nguyên vật liệu đầu vào
    }

    // ---------------------------------------------------------------------------
    // Sao chép BOM
    // ---------------------------------------------------------------------------

    /**
     * Tạo bản sao BOM với phiên bản mới.
     * Nếu newVersion không được cung cấp → tự tăng từ version hiện tại của BOM nguồn.
     * Dùng session flash message để thông báo vượt qua redirect.
     *
     * @return URL redirect về danh sách BOM
     */
    private String cloneBOM(HttpServletRequest request) {
        String s_id      = request.getParameter("id");
        String newVersion = request.getParameter("newVersion"); // Version muốn đặt cho bản copy

        HttpSession session = request.getSession();

        try {
            int id = Integer.parseInt(s_id);
            BOMDAO dao = new BOMDAO();

            // Nếu không có newVersion → tự tính phiên bản tiếp theo
            if (newVersion == null || newVersion.trim().isEmpty()) {
                BOMDTO existing = dao.getBOMById(id);
                if (existing == null) {
                    throw new IllegalArgumentException("Không tìm thấy BOM với ID = " + id);
                }
                String currentVersion = existing.getBomVersion();
                if (currentVersion != null && currentVersion.startsWith("v")) {
                    try {
                        // Parse số version chính (phần trước dấu chấm)
                        int verNum = Integer.parseInt(currentVersion.substring(1).split("\\.")[0]);
                        newVersion = "v" + (verNum + 1) + ".0"; // Tăng lên 1
                    } catch (NumberFormatException ex) {
                        newVersion = "v2.0"; // Fallback nếu format lạ
                    }
                } else {
                    newVersion = "v2.0"; // Fallback khi không có version hợp lệ
                }
            }

            boolean success = dao.cloneBOM(id, newVersion); // DAO copy header + details

            // Dùng session flash để message tồn tại qua redirect
            if (success) {
                session.setAttribute("flashMsg", "BOM đã được sao chép thành công sang phiên bản " + newVersion);
            } else {
                session.setAttribute("flashError", "Không thể sao chép BOM");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi khi sao chép BOM: " + e.getMessage());
        }

        return REDIRECT_LIST;
    }

    // ---------------------------------------------------------------------------
    // Xóa BOM
    // ---------------------------------------------------------------------------

    /**
     * Xóa BOM theo ID.
     * Dùng session flash message để thông báo vượt qua redirect.
     *
     * @return URL redirect về danh sách BOM
     */
    private String deleteBOM(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        HttpSession session = request.getSession();

        try {
            int id = Integer.parseInt(s_id);
            BOMDAO dao = new BOMDAO();
            boolean success = dao.deleteBOM(id); // Xóa BOM và chi tiết liên quan khỏi DB
            if (success) {
                session.setAttribute("flashMsg", "Xóa BOM thành công!");
            } else {
                session.setAttribute("flashError", "Không thể xóa BOM");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi khi xóa BOM: " + e.getMessage());
        }
        return REDIRECT_LIST;
    }

    // ---------------------------------------------------------------------------
    // Kích hoạt BOM
    // ---------------------------------------------------------------------------

    /**
     * Đặt trạng thái BOM về "active" – BOM được dùng cho sản xuất.
     * Dùng session flash message để thông báo vượt qua redirect.
     *
     * @return URL redirect về danh sách BOM
     */
    private String activateBOM(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        HttpSession session = request.getSession();

        try {
            int id = Integer.parseInt(s_id);
            BOMDAO dao = new BOMDAO();
            boolean success = dao.activateBOM(id); // UPDATE status = 'active' trong DB
            if (success) {
                session.setAttribute("flashMsg", "Kích hoạt BOM thành công!");
            } else {
                session.setAttribute("flashError", "Không thể kích hoạt BOM");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi: " + e.getMessage());
        }
        return REDIRECT_LIST;
    }

    // ---------------------------------------------------------------------------
    // Vô hiệu hóa BOM
    // ---------------------------------------------------------------------------

    /**
     * Đặt trạng thái BOM về "inactive" – BOM không còn được dùng cho sản xuất mới.
     * Dùng session flash message để thông báo vượt qua redirect.
     *
     * @return URL redirect về danh sách BOM
     */
    private String deactivateBOM(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        HttpSession session = request.getSession();

        try {
            int id = Integer.parseInt(s_id);
            BOMDAO dao = new BOMDAO();
            boolean success = dao.deactivateBOM(id); // UPDATE status = 'inactive' trong DB
            if (success) {
                session.setAttribute("flashMsg", "Vô hiệu hóa BOM thành công!");
            } else {
                session.setAttribute("flashError", "Không thể vô hiệu hóa BOM");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi: " + e.getMessage());
        }
        return REDIRECT_LIST;
    }

    // ---------------------------------------------------------------------------
    // Thêm một dòng chi tiết nguyên liệu
    // ---------------------------------------------------------------------------

    /**
     * Thêm một BOMDetailDTO vào BOM đang xem (inline từ trang bom-detail.jsp).
     * Khác addBOM: chỉ thêm từng dòng một, không thêm hàng loạt.
     *
     * @return URL redirect về trang xem chi tiết BOM tương ứng
     */
    private String addDetail(HttpServletRequest request) {
        String s_bomId = request.getParameter("bomId"); // BOM cần thêm nguyên liệu vào
        HttpSession session = request.getSession();

        try {
            int bomId          = Integer.parseInt(s_bomId);
            int materialItemId = Integer.parseInt(request.getParameter("materialItemId")); // Nguyên liệu
            double quantity    = Double.parseDouble(request.getParameter("quantity"));     // Số lượng cần
            String unit        = request.getParameter("unit");     // Đơn vị (kg, cái, m...)
            String notes       = request.getParameter("notes");    // Ghi chú

            // Parse tỷ lệ hao hụt với fallback về 0 nếu rỗng hoặc không hợp lệ
            double wastePercent = 0;
            String swp = request.getParameter("wastePercent");
            if (swp != null && !swp.trim().isEmpty()) {
                try {
                    wastePercent = Double.parseDouble(swp);
                } catch (NumberFormatException e) {
                    // Giữ wastePercent = 0 nếu không parse được
                }
            }

            // Tạo và điền dữ liệu chi tiết
            BOMDetailDTO detail = new BOMDetailDTO();
            detail.setBomId(bomId);
            detail.setMaterialItemId(materialItemId);
            detail.setQuantityRequired(quantity);
            detail.setUnit(unit);
            detail.setWastePercent(wastePercent);
            detail.setNotes(notes);

            BOMDAO dao = new BOMDAO();
            boolean success = dao.addBOMDetail(detail); // INSERT chi tiết vào DB
            if (success) {
                session.setAttribute("flashMsg", "Thêm nguyên liệu thành công!");
            } else {
                session.setAttribute("flashError", "Không thể thêm nguyên liệu");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi: " + e.getMessage());
        }

        // Redirect về trang xem chi tiết BOM để thấy ngay nguyên liệu vừa thêm
        return "redirect:MainController?action=viewBOM&id=" + s_bomId;
    }

    // ---------------------------------------------------------------------------
    // Cập nhật một dòng chi tiết nguyên liệu
    // ---------------------------------------------------------------------------

    /**
     * Cập nhật thông tin một BOMDetailDTO theo detailId.
     *
     * @return URL redirect về trang xem chi tiết BOM tương ứng
     */
    private String updateDetail(HttpServletRequest request) {
        String s_bomId = request.getParameter("bomId");
        HttpSession session = request.getSession();

        try {
            int detailId       = Integer.parseInt(request.getParameter("detailId"));    // ID dòng chi tiết
            int materialItemId = Integer.parseInt(request.getParameter("materialItemId")); // Nguyên liệu mới
            double quantity    = Double.parseDouble(request.getParameter("quantity"));   // Số lượng mới
            String unit        = request.getParameter("unit");
            String notes       = request.getParameter("notes");

            // Parse wastePercent an toàn với fallback 0
            double wastePercent = 0;
            String swp = request.getParameter("wastePercent");
            if (swp != null && !swp.trim().isEmpty()) {
                try {
                    wastePercent = Double.parseDouble(swp);
                } catch (NumberFormatException e) {
                    // Giữ 0 nếu không hợp lệ
                }
            }

            BOMDetailDTO detail = new BOMDetailDTO();
            detail.setBomDetailId(detailId);       // ID của dòng chi tiết cần UPDATE
            detail.setMaterialItemId(materialItemId);
            detail.setQuantityRequired(quantity);
            detail.setUnit(unit);
            detail.setWastePercent(wastePercent);
            detail.setNotes(notes);

            BOMDAO dao = new BOMDAO();
            boolean success = dao.updateBOMDetail(detail); // Gửi câu UPDATE lên DB
            if (success) {
                session.setAttribute("flashMsg", "Cập nhật nguyên liệu thành công!");
            } else {
                session.setAttribute("flashError", "Không thể cập nhật nguyên liệu");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi: " + e.getMessage());
        }

        return "redirect:MainController?action=viewBOM&id=" + s_bomId;
    }

    // ---------------------------------------------------------------------------
    // Xóa một dòng chi tiết nguyên liệu
    // ---------------------------------------------------------------------------

    /**
     * Xóa một BOMDetailDTO theo detailId (ID dòng chi tiết, không phải bomId).
     *
     * @return URL redirect về trang xem chi tiết BOM tương ứng
     */
    private String deleteDetail(HttpServletRequest request) {
        String s_bomId = request.getParameter("bomId"); // Để redirect về đúng trang sau khi xóa
        String s_id    = request.getParameter("id");    // ID của dòng chi tiết cần xóa
        HttpSession session = request.getSession();

        try {
            int detailId = Integer.parseInt(s_id);
            BOMDAO dao = new BOMDAO();
            boolean success = dao.deleteBOMDetail(detailId); // DELETE dòng chi tiết khỏi DB
            if (success) {
                session.setAttribute("flashMsg", "Xóa nguyên liệu thành công!");
            } else {
                session.setAttribute("flashError", "Không thể xóa nguyên liệu");
            }
        } catch (Exception e) {
            session.setAttribute("flashError", "Lỗi: " + e.getMessage());
        }

        return "redirect:MainController?action=viewBOM&id=" + s_bomId;
    }

    // ---------------------------------------------------------------------------
    // doGet / doPost
    // ---------------------------------------------------------------------------

    /** Xử lý HTTP GET – chủ yếu: hiển thị danh sách, form, chi tiết */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – chủ yếu: thêm mới, cập nhật, xóa */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "BOM Controller – quản lý Bill of Materials (danh sách nguyên vật liệu)";
    }
}