package pms.controllers;

import java.io.IOException;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import pms.model.UserDAO;
import pms.model.UserDTO;
import pms.utils.FileEncryptor;
import pms.utils.FileService;
import pms.utils.FileService.FileRecord;
import java.util.ArrayList;

/**
 * FileController – Servlet quản lý File Tài Liệu Mã Hóa.
 *
 * Tất cả file được upload đều được mã hóa bằng mật khẩu (AES hoặc tương đương)
 * trước khi lưu vào server. Khi tải xuống, file được giải mã bằng đúng mật khẩu đó.
 *
 * @MultipartConfig: cho phép nhận file upload (multipart/form-data), tối đa 10MB.
 *
 * Phân quyền: chỉ admin mới được upload, xóa và đổi mật khẩu file.
 * Mọi người dùng đã đăng nhập đều có thể download (nếu biết mật khẩu của file đó).
 *
 * Chức năng:
 *   - list           : Xem danh sách file (lọc theo bảng liên kết)
 *   - upload         : Upload và mã hóa file mới (chỉ admin)
 *   - download       : Giải mã và tải xuống file (cần mật khẩu)
 *   - delete         : Xóa file (chỉ admin)
 *   - verifyPassword : Kiểm tra mật khẩu file qua AJAX (trả JSON)
 *   - changePassword : Đổi mật khẩu mã hóa file (chỉ admin)
 */
@MultipartConfig(maxFileSize = 10 * 1024 * 1024) // Giới hạn 10MB mỗi file
public class FileController extends HttpServlet {

    /** URL redirect về danh sách file */
    private static final String LIST_REDIRECT = "FileController?action=list";

    /**
     * FileService: xử lý logic upload, download, mã hóa, quản lý file trên disk và DB.
     * Khởi tạo một lần trong init().
     */
    private FileService fileService;

    /**
     * FileEncryptor: thư viện mã hóa/giải mã file.
     * Khởi tạo một lần trong init().
     */
    private FileEncryptor encryptor;

    /**
     * Khởi tạo FileService và FileEncryptor khi servlet được deploy.
     * Gọi fileService.init(servletContext) để service biết đường dẫn lưu file.
     */
    @Override
    public void init() throws ServletException {
        this.fileService = new FileService();
        this.fileService.init(getServletContext()); // Truyền context để lấy đường dẫn upload
        this.encryptor   = new FileEncryptor();
    }

    /**
     * Điểm xử lý chung.
     * download và verifyPassword tự ghi response => return trực tiếp.
     * Các action khác: nếu có "redirect" attribute trong request → sendRedirect,
     * nếu không → forward đến file-management.jsp.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "list";
        }

        switch (action) {
            case "list":
                listFiles(request);                  // Tải danh sách file
                break;
            case "upload":
                uploadFile(request);                 // Upload và mã hóa file
                break;
            case "download":
                downloadFile(request, response);     // Giải mã và tải xuống
                return; // Đã tự ghi response
            case "delete":
                deleteFile(request);                 // Xóa file (chỉ admin)
                break;
            case "verifyPassword":
                verifyPassword(request, response);   // Kiểm tra mật khẩu (AJAX → JSON)
                return; // Đã tự ghi response
            case "changePassword":
                changePassword(request);             // Đổi mật khẩu file
                break;
        }

        // Sau khi xử lý: redirect hoặc forward
        if (request.getAttribute("redirect") != null) {
            response.sendRedirect(request.getContextPath() + "/" + (String) request.getAttribute("redirect"));
        } else {
            request.getRequestDispatcher("file-management.jsp").forward(request, response);
        }
    }

    /**
     * Tải danh sách file kèm thông tin người upload.
     * Nếu có tham số "table" → lọc file theo bảng liên kết (ví dụ: WorkOrder, BOM).
     * Chuyển đổi FileRecord → FileRecordWrapper để JSP dễ hiển thị (tên người upload, định dạng kích thước).
     *
     * @param request Chứa tùy chọn "table" (tên bảng liên kết) và "id" (ID của record)
     */
    private void listFiles(HttpServletRequest request) {
        String table = request.getParameter("table"); // "WorkOrder", "BOM"... hoặc null = xem tất cả
        ArrayList<FileRecord> records;

        if (table != null && !table.isEmpty()) {
            try {
                int relatedId = 0;
                String idStr = request.getParameter("id");

                // Parse ID liên kết (ví dụ: WorkOrder ID)
                if (idStr != null && !idStr.isEmpty()) {
                    relatedId = Integer.parseInt(idStr);
                }

                records = fileService.getFilesByRelated(table, relatedId); // Lọc theo bảng + ID
            } catch (Exception e) {
                records = fileService.getAllFiles(); // Fallback về tất cả nếu lỗi
            }
        } else {
            records = fileService.getAllFiles(); // Không có filter → lấy tất cả
        }

        // Chuyển FileRecord → FileRecordWrapper (để JSP hiển thị tên người upload và format size)
        ArrayList<FileRecordWrapper> wrappers = new ArrayList<>();
        UserDAO udao = new UserDAO();

        for (FileRecord r : records) {
            String uploaderName = null;
            if (r.uploaderId > 0) {
                UserDTO u = udao.SearchByID(r.uploaderId); // Tra cứu tên người upload
                if (u != null) uploaderName = u.getFullName();
            }

            // Định dạng ngày giờ upload theo dd/MM/yyyy HH:mm
            String uploadedAt = r.uploadedAt != null
                    ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(r.uploadedAt) : "-";

            wrappers.add(new FileRecordWrapper(
                    r.fileId, r.originalName, r.fileExtension,
                    r.getFormattedSize(),   // Ví dụ: "2.5 MB" thay vì số bytes thô
                    uploaderName, r.description,
                    uploadedAt, r.relatedTable, r.relatedId, r.getContentType()
            ));
        }

        request.setAttribute("fileList", wrappers); // Danh sách file để JSP hiển thị
    }

    /**
     * Upload và mã hóa file mới (chỉ admin được làm).
     * Validate:
     *   - Phải là admin
     *   - Mật khẩu mã hóa không được rỗng
     *   - relatedId phải là số hợp lệ (nếu có)
     *   - Phải có file đính kèm
     *
     * @param request Chứa "password", "description", "related_table", "related_id", và file Part
     */
    private void uploadFile(HttpServletRequest request) {
        UserDTO currentUser = (UserDTO) request.getSession().getAttribute("user");
        if (currentUser == null || !"admin".equalsIgnoreCase(currentUser.getRole())) {
            request.setAttribute("error", "Bạn không có quyền upload file.");
            listFiles(request);
            return;
        }

        try {
            String password = request.getParameter("password"); // Mật khẩu để mã hóa file
            if (password == null || password.trim().isEmpty()) {
                request.setAttribute("error", "Mật khẩu mã hóa không được để trống!");
                listFiles(request);
                return;
            }

            String description  = request.getParameter("description");   // Mô tả file (tùy chọn)
            String relatedTable = request.getParameter("related_table");  // Bảng liên kết (tùy chọn)
            String relatedIdStr = request.getParameter("related_id");     // ID record liên kết
            int relatedId = 0;

            // Parse relatedId nếu có (ví dụ: liên kết với WorkOrder #5)
            if (relatedIdStr != null && !relatedIdStr.trim().isEmpty()) {
                try {
                    relatedId = Integer.parseInt(relatedIdStr.trim());
                } catch (NumberFormatException e) {
                    request.setAttribute("error", "ID liên quan không hợp lệ!");
                    listFiles(request);
                    return;
                }
            }

            Part filePart = request.getPart("file"); // Lấy file từ multipart form
            if (filePart == null || filePart.getSize() <= 0) {
                request.setAttribute("error", "Chưa chọn file để upload!");
                listFiles(request);
                return;
            }

            // Gọi FileService để mã hóa và lưu file
            boolean success = fileService.uploadEncryptedFile(
                    filePart,              // File đính kèm
                    password.trim(),       // Mật khẩu mã hóa
                    currentUser.getId(),   // ID người upload (từ session)
                    description,           // Mô tả
                    relatedTable,          // Bảng liên kết
                    relatedId             // ID liên kết
            );

            if (success) {
                request.setAttribute("msg", "Upload và mã hóa file thành công!");
            } else {
                request.setAttribute("error", "Upload file thất bại! Kiểm tra định dạng, kích thước hoặc dữ liệu liên quan.");
            }

        } catch (Exception e) {
            request.setAttribute("error", "Lỗi upload: " + e.getMessage());
            e.printStackTrace();
        }

        listFiles(request); // Tải lại danh sách sau khi xử lý
    }

    /**
     * Giải mã và tải xuống file cho người dùng.
     * Quy trình:
     *   1. Kiểm tra file_id và password có đủ không
     *   2. Lấy FileRecord từ DB trực tiếp (để biết tên và content type)
     *   3. Xác minh mật khẩu (verifyPassword)
     *   4. Giải mã file (downloadDecryptedFile)
     *   5. Ghi byte[] vào response với Content-Disposition attachment
     *
     * @param request  Chứa "file_id" và "password"
     * @param response HttpServletResponse để ghi binary file
     */
    private void downloadFile(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String fileIdStr = request.getParameter("file_id");
        String password  = request.getParameter("password"); // Mật khẩu giải mã

        // Kiểm tra có đủ thông tin không
        if (fileIdStr == null || password == null || password.trim().isEmpty()) {
            request.setAttribute("downloadError", "Thiếu thông tin tải xuống!");
            listFiles(request);
            request.getRequestDispatcher("file-management.jsp").forward(request, response);
            return;
        }

        try {
            int fileId = Integer.parseInt(fileIdStr);
            FileRecord record = getFileRecord(fileId); // Lấy metadata file từ DB

            if (record == null) {
                request.setAttribute("downloadError", "File không tồn tại!");
                listFiles(request);
                request.getRequestDispatcher("file-management.jsp").forward(request, response);
                return;
            }

            // Xác minh mật khẩu trước khi giải mã
            boolean valid = fileService.verifyPassword(fileId, password.trim());
            if (!valid) {
                request.setAttribute("downloadError", "Mật khẩu không đúng!");
                listFiles(request);
                request.getRequestDispatcher("file-management.jsp").forward(request, response);
                return;
            }

            // Giải mã file → byte array
            byte[] decryptedData = fileService.downloadDecryptedFile(fileId, password.trim());
            if (decryptedData == null) {
                request.setAttribute("downloadError", "Giải mã thất bại!");
                listFiles(request);
                request.getRequestDispatcher("file-management.jsp").forward(request, response);
                return;
            }

            // Ghi file vào response để browser tải xuống
            response.setContentType(record.getContentType()); // MIME type (ví dụ: application/pdf)
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"" + record.originalName + "\""); // Tên file khi save
            response.setContentLength(decryptedData.length);                // Kích thước file
            response.getOutputStream().write(decryptedData);                // Ghi binary
            response.getOutputStream().flush();                              // Đảm bảo gửi hết

        } catch (Exception e) {
            request.setAttribute("downloadError", "Lỗi tải file: " + e.getMessage());
            e.printStackTrace();
        }
        listFiles(request);
        request.getRequestDispatcher("file-management.jsp").forward(request, response);
    }

    /**
     * Xóa file theo file_id (chỉ admin).
     * FileService xóa cả bản ghi DB và file vật lý trên disk.
     *
     * @param request Chứa "file_id"
     */
    private void deleteFile(HttpServletRequest request) {
        UserDTO currentUser = (UserDTO) request.getSession().getAttribute("user");
        if (currentUser == null || !"admin".equalsIgnoreCase(currentUser.getRole())) {
            request.setAttribute("error", "Bạn không có quyền xóa file.");
            listFiles(request);
            return;
        }

        String fileIdStr = request.getParameter("file_id");
        if (fileIdStr != null && !fileIdStr.isEmpty()) {
            try {
                int fileId = Integer.parseInt(fileIdStr);
                boolean success = fileService.deleteFile(fileId); // Xóa DB + disk
                if (success) {
                    request.setAttribute("msg", "Xóa file thành công!");
                } else {
                    request.setAttribute("error", "Xóa file thất bại!");
                }
            } catch (Exception e) {
                request.setAttribute("error", "Lỗi: " + e.getMessage());
            }
        }
        listFiles(request);
    }

    /**
     * Kiểm tra mật khẩu của file qua AJAX, trả JSON {valid: true/false}.
     * Dùng cho modal tải xuống: JavaScript hỏi trước khi gửi form download.
     *
     * @param request  Chứa "file_id" và "password"
     * @param response HttpServletResponse để ghi JSON
     */
    private void verifyPassword(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String fileIdStr = request.getParameter("file_id");
        String password  = request.getParameter("password");

        response.setContentType("application/json;charset=UTF-8"); // JSON response

        try {
            if (fileIdStr == null || password == null) {
                response.getWriter().write("{\"valid\":false,\"error\":\"Thieu thong tin\"}");
                return;
            }
            int fileId     = Integer.parseInt(fileIdStr);
            boolean valid  = fileService.verifyPassword(fileId, password); // So sánh hash mật khẩu
            response.getWriter().write("{\"valid\":" + valid + "}"); // Chỉ trả true/false

        } catch (Exception e) {
            response.getWriter().write("{\"valid\":false,\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    /**
     * Đổi mật khẩu mã hóa của file (chỉ admin).
     * FileService sẽ giải mã bằng oldPassword rồi mã hóa lại bằng newPassword.
     *
     * @param request Chứa "file_id", "oldPassword", "newPassword"
     */
    private void changePassword(HttpServletRequest request) {
        UserDTO currentUser = (UserDTO) request.getSession().getAttribute("user");
        if (currentUser == null || !"admin".equalsIgnoreCase(currentUser.getRole())) {
            request.setAttribute("error", "Bạn không có quyền đổi mật khẩu file.");
            listFiles(request);
            return;
        }

        String fileIdStr   = request.getParameter("file_id");
        String oldPassword = request.getParameter("oldPassword"); // Mật khẩu hiện tại
        String newPassword = request.getParameter("newPassword"); // Mật khẩu mới

        // Kiểm tra có đủ thông tin không
        if (fileIdStr == null || oldPassword == null || newPassword == null) {
            request.setAttribute("error", "Thiếu thông tin!");
            listFiles(request);
            return;
        }

        try {
            int fileId    = Integer.parseInt(fileIdStr);
            // Giải mã với oldPW → mã hóa lại với newPW
            boolean success = fileService.changePassword(fileId, oldPassword, newPassword);
            if (success) {
                request.setAttribute("msg", "Đổi mật khẩu file thành công!");
            } else {
                request.setAttribute("error", "Đổi mật khẩu thất bại! Mật khẩu cũ không đúng.");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Lỗi: " + e.getMessage());
        }

        listFiles(request);
    }

    /**
     * Lấy metadata của file từ bảng EncryptedFile trong DB theo file_id.
     * Sử dụng JDBC trực tiếp (không qua DAO) để lấy đủ các trường cần thiết.
     *
     * @param fileId ID file cần tra cứu
     * @return FileRecord với thông tin metadata, hoặc null nếu không tìm thấy
     */
    private FileRecord getFileRecord(int fileId) {
        java.sql.Connection con = null;
        try {
            con = pms.utils.DBUtils.getConnection(); // Lấy connection từ pool

            java.sql.PreparedStatement ps = con.prepareStatement(
                    "SELECT * FROM EncryptedFile WHERE file_id = ?");
            ps.setInt(1, fileId);
            java.sql.ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                FileRecord r = new FileRecord();
                r.fileId        = rs.getInt("file_id");
                r.originalName  = rs.getString("original_name");   // Tên file gốc khi upload
                r.storedFileName = rs.getString("stored_name");    // Tên file mã hóa trên disk
                r.fileExtension = rs.getString("file_extension");  // Phần mở rộng (.pdf, .xlsx…)
                r.fileSize      = rs.getLong("file_size");         // Kích thước byte
                r.passwordHash  = rs.getString("password_hash");   // Hash mật khẩu để verify
                r.uploaderId    = rs.getInt("uploader_id");        // ID người upload
                r.description   = rs.getString("file_description"); // Mô tả
                r.relatedTable  = rs.getString("related_table");    // Bảng liên kết
                r.relatedId     = rs.getInt("related_id");         // ID liên kết
                r.uploadedAt    = rs.getTimestamp("uploaded_at");  // Thời điểm upload
                return r;
            }

        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (con != null) con.close(); } catch (Exception e) {}
        }
        return null; // Không tìm thấy file
    }

    /**
     * FileRecordWrapper – DTO phục vụ JSP, thân thiện hơn FileRecord.
     *
     * Khác FileRecord (lưu raw data từ DB):
     *   - fileSize : String đã định dạng ("2.5 MB" thay vì số bytes)
     *   - uploaderName : Tên người upload thay vì uploaderId
     *   - uploadedAt  : Chuỗi ngày giờ đã format (dd/MM/yyyy HH:mm)
     */
    public static class FileRecordWrapper {
        public int    fileId;        // ID file
        public String originalName;  // Tên file gốc
        public String fileExtension; // Phần mở rộng
        public String fileSize;      // Kích thước đã format ("2.5 MB")
        public String uploaderName;  // Tên đầy đủ người upload
        public String description;   // Mô tả file
        public String uploadedAt;    // Ngày giờ upload (dd/MM/yyyy HH:mm)
        public String relatedTable;  // Bảng liên kết
        public int    relatedId;     // ID liên kết
        public String contentType;   // MIME type (ví dụ: "application/pdf")

        /** Constructor đầy đủ để tạo wrapper từ FileRecord và thông tin bổ sung */
        public FileRecordWrapper(int fileId, String originalName, String fileExtension,
                String fileSize, String uploaderName, String description,
                String uploadedAt, String relatedTable, int relatedId, String contentType) {
            this.fileId       = fileId;
            this.originalName = originalName;
            this.fileExtension = fileExtension;
            this.fileSize     = fileSize;
            this.uploaderName = uploaderName;
            this.description  = description;
            this.uploadedAt   = uploadedAt;
            this.relatedTable = relatedTable;
            this.relatedId    = relatedId;
            this.contentType  = contentType;
        }
    }

    /** Xử lý HTTP GET – xem danh sách file */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – upload, download, xóa, đổi mật khẩu */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "File Controller – Quản lý file tài liệu mã hóa";
    }
}
