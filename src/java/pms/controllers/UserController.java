package pms.controllers;

import java.io.IOException;
import java.util.ArrayList;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import pms.model.UserDAO;
import pms.model.UserDTO;

/**
 * UserController – Servlet quản lý Người Dùng và Xác Thực (Authentication).
 *
 * Đây là controller lớn nhất, xử lý mọi tác vụ liên quan đến người dùng:
 *
 * XÁC THỰC:
 *   - loginUser  : Đăng nhập; kiểm tra tài khoản bị khóa; điều hướng theo vai trò
 *   - logout     : Hủy session và redirect về trang đăng nhập
 *
 * QUẢN LÝ NGƯỜI DÙNG (chỉ admin):
 *   - list        : Danh sách người dùng, hỗ trợ lọc theo vai trò
 *   - search      : Tìm kiếm theo username, họ tên, email, số điện thoại
 *   - add / saveAddUser   : Form và lưu người dùng mới
 *   - edit / saveUpdateUser: Form và cập nhật người dùng
 *   - removeUser  : Xóa người dùng
 *   - lockUser    : Khóa tài khoản (is_active = false)
 *   - unlockUser  : Mở khóa tài khoản
 *   - resetPassword     : Reset mật khẩu về "123456" (admin)
 *   - changePassword    : Admin đổi mật khẩu cho user khác
 *
 * HỒ SƠ CÁ NHÂN (mọi người dùng):
 *   - viewProfile       : Xem hồ sơ, làm mới dữ liệu từ DB
 *   - updateProfile     : Cập nhật họ tên, email, điện thoại (không đổi được role)
 *   - changeOwnPassword : Đổi mật khẩu của chính mình (cần nhập mật khẩu cũ)
 *   - changePasswordForm: Đổi mật khẩu với validate đầy đủ (cần xác minh currentPassword)
 *
 * CẢNH BÁO: url là instance field – không thread-safe. Giữ nguyên để tương thích.
 */
public class UserController extends HttpServlet {

    /**
     * CẢNH BÁO: instance field, không thread-safe (như BillController).
     * Giữ nguyên để không phá vỡ luồng hiện tại.
     */
    String url = "";

    /**
     * Điểm xử lý chung. Phân luồng theo action.
     * changePasswordForm tự ghi response (return sớm), các action còn lại forward hoặc redirect.
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Đặt encoding UTF-8
        response.setContentType("text/html;charset=UTF-8");
        request.setCharacterEncoding("UTF-8");
        response.setCharacterEncoding("UTF-8");

        // Lấy action, mặc định là "list"
        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        // Phân luồng theo action
        switch (action) {
            case "loginUser":
                DoLogin(request);                                // Xử lý đăng nhập
                break;
            case "logoutUser":
            case "logout":
                DoLogout(request);                               // Đăng xuất, hủy session
                break;
            case "list":
                listUsers(request);                              // Danh sách users (lọc theo role)
                break;
            case "search":
                searchUsers(request);                            // Tìm kiếm users
                break;
            case "add":
                request.setAttribute("mode", "add");             // Hiển thị form thêm mới
                url = "user-form.jsp";
                break;
            case "addUser":
            case "saveAddUser":
                AddUser(request);                                // Lưu người dùng mới
                break;
            case "removeUser":
                RemoveUser(request);                             // Xóa người dùng
                break;
            case "edit":
            case "updateUser":
            case "saveUpdateUser":
                UpdateUser(request);                             // Cập nhật người dùng
                break;
            case "view":
            case "viewUser":
                viewUser(request);                               // Xem chi tiết người dùng
                break;
            case "lockUser":
                lockUser(request);                               // Khóa tài khoản
                break;
            case "unlockUser":
                unlockUser(request);                             // Mở khóa tài khoản
                break;
            case "resetPassword":
                resetPassword(request);                          // Reset mật khẩu về "123456"
                break;
            case "changePassword":
                changePassword(request);                         // Admin đổi mật khẩu cho user khác
                break;
            case "changeOwnPassword":
                changeOwnPassword(request);                      // Tự đổi mật khẩu của mình
                break;
            case "updateProfile":
                updateProfile(request);                          // Cập nhật họ tên, email, phone
                break;
            case "viewProfile":
                viewProfile(request);                            // Xem hồ sơ cá nhân
                break;
            case "changePasswordForm":
                doChangePassword(request, response);             // Đổi mật khẩu với validate đầy đủ
                return; // Đã tự ghi response
        }

        // Redirect hoặc forward
        if (url != null && url.startsWith("redirect:")) {
            response.sendRedirect(url.substring(9)); // Bỏ tiền tố "redirect:"
        } else {
            request.getRequestDispatcher(url).forward(request, response);
        }
    }

    /**
     * Xử lý đăng nhập.
     * Nếu đã có user trong session → không check lại.
     * Nếu chưa có → lấy username/password từ form và xác thực qua DAO.
     * Kết quả:
     *   - Đăng nhập thành công + bị khoá → Banned.jsp
     *   - Đăng nhập thành công + active  → DashboardController (admin thì load thêm eList)
     *   - Đăng nhập thất bại             → redirect về login.jsp với thông báo
     *
     * @param request Chứa "txtUsername" và "txtPassword"
     */
    private void DoLogin(HttpServletRequest request) {
        HttpSession session = request.getSession();
        UserDTO user = (UserDTO) session.getAttribute("user"); // Kiểm tra đã đăng nhập chưa

        UserDAO udao = new UserDAO();

        if (user == null) {
            // Chưa đăng nhập → xác thực từ form
            String username = request.getParameter("txtUsername"); // Username từ form
            String password = request.getParameter("txtPassword"); // Password từ form
            user = udao.Login(username, password);                 // Hash password và so sánh DB

            if (user != null) {
                session.setAttribute("user", user); // Lưu user vào session nếu đúng
            } else {
                // Sai credentials → thông báo lỗi; giữ username để form fill lại
                session.setAttribute("loginMessage", "Incorrect User ID or Password");
                session.setAttribute("loginUsername", username);
            }
        }

        if (user != null) {
            if (!user.isActive()) {
                url = "Banned.jsp"; // Tài khoản bị khoá
            } else {
                url = "DashboardController"; // Đăng nhập thành công → Dashboard

                // Admin: nạp thêm danh sách nhân viên vào session để các trang khác dùng
                if (user.getRole().equals("admin")) {
                    ArrayList<UserDTO> eList = udao.getUsersByRole("employee");
                    session.setAttribute("eList", eList); // Cache danh sách nhân viên
                }
            }
        } else {
            url = "redirect:login.jsp"; // Thất bại → quay về trang login
        }
    }

    /**
     * Đăng xuất: hủy toàn bộ session và redirect về trang đăng nhập.
     * Chỉ invalidate nếu session hiện có user (tránh lỗi với session rỗng).
     */
    private void DoLogout(HttpServletRequest request) {
        HttpSession session = request.getSession();
        if (session.getAttribute("user") != null) {
            session.invalidate(); // Xóa toàn bộ dữ liệu session
        }
        url = "redirect:login.jsp"; // Redirect về trang đăng nhập
    }

    /**
     * Tải danh sách người dùng, có thể lọc theo vai trò (role).
     * Nếu role = null, rỗng hoặc "all" → lấy tất cả user.
     * Nếu role = "admin", "employee"… → lấy theo role đó.
     *
     * @param request Chứa tùy chọn "role" để lọc
     */
    private void listUsers(HttpServletRequest request) {
        UserDAO udao = new UserDAO();
        String roleFilter = request.getParameter("role"); // Lọc theo vai trò

        ArrayList<UserDTO> users;
        if (roleFilter != null && !roleFilter.isEmpty() && !"all".equals(roleFilter)) {
            users = udao.getUsersByRole(roleFilter); // Chỉ lấy theo vai trò cụ thể
            request.setAttribute("role", roleFilter); // Giữ lại để JSP highlight tab
        } else {
            users = udao.getAllUsers(); // Lấy tất cả user
        }

        request.setAttribute("users", users);
        url = "user-list.jsp";
    }

    /**
     * Tìm kiếm người dùng theo keyword (username, họ tên, email, điện thoại).
     * Có thể kết hợp với lọc theo role.
     * Lọc client-side: lấy tất cả rồi dùng removeIf().
     *
     * @param request Chứa "keyword" và tùy chọn "role"
     */
    private void searchUsers(HttpServletRequest request) {
        UserDAO udao = new UserDAO();
        String keyword = request.getParameter("keyword");
        String role    = request.getParameter("role");

        // Bước 1: Lấy danh sách theo role (hoặc tất cả)
        ArrayList<UserDTO> users;
        if (role != null && !role.isEmpty() && !role.equals("all")) {
            users = udao.getUsersByRole(role);
        } else {
            users = udao.getAllUsers();
        }

        // Bước 2: Lọc theo keyword trong Java (không qua SQL)
        if (keyword != null && !keyword.trim().isEmpty()) {
            final String kw = keyword.toLowerCase();
            users.removeIf(u -> {
                // Khớp nếu bất kỳ trường nào chứa keyword
                boolean matchUsername = u.getUsername() != null && u.getUsername().toLowerCase().contains(kw);
                boolean matchFullName = u.getFullName() != null && u.getFullName().toLowerCase().contains(kw);
                boolean matchEmail    = u.getEmail()    != null && u.getEmail().toLowerCase().contains(kw);
                boolean matchPhone    = u.getPhone()    != null && u.getPhone().toLowerCase().contains(kw);
                return !matchUsername && !matchFullName && !matchEmail && !matchPhone; // Loại nếu không khớp gì
            });
        }

        request.setAttribute("users",   users);
        request.setAttribute("keyword", keyword); // Giữ keyword trên form
        request.setAttribute("role",    role);     // Giữ role filter
        url = "user-list.jsp";
    }

    /**
     * Xem chi tiết thông tin một người dùng theo ID.
     * Nếu ID không hợp lệ → redirect về danh sách với thông báo lỗi.
     *
     * @param request Chứa "id" (user ID)
     */
    private void viewUser(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        int id = 0;
        try {
            id = Integer.parseInt(s_id);
        } catch (Exception e) {
            request.setAttribute("error", "Invalid user ID");
            url = "redirect:UserController?action=list";
            return;
        }

        UserDAO udao = new UserDAO();
        UserDTO user = udao.SearchByID(id); // Lấy thông tin user từ DB
        request.setAttribute("user", user);
        url = "user-detail.jsp"; // Trang chi tiết người dùng
    }

    /**
     * Xóa người dùng khỏi hệ thống theo ID.
     * Sau khi xóa → redirect về danh sách.
     *
     * @param request Chứa "id" (user ID cần xóa)
     */
    private void RemoveUser(HttpServletRequest request) {
        String id = request.getParameter("id");
        UserDAO udao = new UserDAO();

        if (id != null && !id.isEmpty()) {
            boolean check = udao.Delete(Integer.parseInt(id)); // Xóa khỏi DB
            if (check) {
                request.setAttribute("msg", "Deleted!");
            } else {
                request.setAttribute("error", "Cannot delete user: " + id);
            }
        }
        url = "redirect:UserController?action=list";
    }

    /**
     * Khoá tài khoản người dùng (đặt is_active = false).
     * User bị khoá sẽ bị redirect đến Banned.jsp khi cố đăng nhập.
     *
     * @param request Chứa "id" (user ID cần khoá)
     */
    private void lockUser(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        UserDAO udao = new UserDAO();

        try {
            int id = Integer.parseInt(s_id);
            boolean success = udao.lockUser(id); // Cập nhật is_active = false trong DB
            if (success) {
                request.setAttribute("msg", "User locked successfully!");
            } else {
                request.setAttribute("error", "Failed to lock user");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Invalid user ID");
        }
        url = "redirect:UserController?action=list";
    }

    /**
     * Mở khoá tài khoản người dùng (đặt is_active = true).
     *
     * @param request Chứa "id" (user ID cần mở khoá)
     */
    private void unlockUser(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        UserDAO udao = new UserDAO();

        try {
            int id = Integer.parseInt(s_id);
            boolean success = udao.unlockUser(id); // Cập nhật is_active = true trong DB
            if (success) {
                request.setAttribute("msg", "User unlocked successfully!");
            } else {
                request.setAttribute("error", "Failed to unlock user");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Invalid user ID");
        }
        url = "redirect:UserController?action=list";
    }

    /**
     * Reset mật khẩu người dùng về mật khẩu mặc định "123456".
     * Thông báo mật khẩu mới trong msg để admin biết và thông báo cho user.
     *
     * @param request Chứa "id" (user ID cần reset)
     */
    private void resetPassword(HttpServletRequest request) {
        String s_id = request.getParameter("id");
        UserDAO udao = new UserDAO();
        String defaultPassword = "123456"; // Mật khẩu mặc định sau khi reset

        try {
            int id = Integer.parseInt(s_id);
            boolean success = udao.resetPassword(id, defaultPassword); // Cập nhật DB
            if (success) {
                request.setAttribute("msg", "Password reset to: " + defaultPassword); // Thông báo password mới
            } else {
                request.setAttribute("error", "Failed to reset password");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Invalid user ID");
        }
        url = "redirect:UserController?action=list";
    }

    /**
     * Admin đổi mật khẩu cho người dùng khác (không cần nhập mật khẩu cũ).
     * Chỉ admin mới được dùng chức năng này.
     *
     * @param request Chứa "id" và "newPassword"
     */
    private void changePassword(HttpServletRequest request) {
        HttpSession session = request.getSession();
        UserDTO currentUser = (UserDTO) session.getAttribute("user");

        // Kiểm tra quyền admin
        if (currentUser == null || !currentUser.getRole().equals("admin")) {
            request.setAttribute("error", "Unauthorized");
            url = "redirect:login.jsp";
            return;
        }

        String s_id       = request.getParameter("id");
        String newPassword = request.getParameter("newPassword"); // Mật khẩu mới do admin đặt

        UserDAO udao = new UserDAO();

        try {
            int id = Integer.parseInt(s_id);
            boolean success = udao.resetPassword(id, newPassword); // Dùng resetPassword để cập nhật DB
            if (success) {
                request.setAttribute("msg", "Password changed successfully!");
            } else {
                request.setAttribute("error", "Failed to change password");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Invalid user ID");
        }
        url = "redirect:UserController?action=list";
    }

    /**
     * Người dùng tự đổi mật khẩu của mình.
     * Validate: newPassword phải khớp confirmPassword.
     * DAO sẽ kiểm tra oldPassword trước khi cập nhật (bảo mật).
     *
     * @param request Chứa "oldPassword", "newPassword", "confirmPassword"
     */
    private void changeOwnPassword(HttpServletRequest request) {
        HttpSession session = request.getSession();
        UserDTO currentUser = (UserDTO) session.getAttribute("user");

        if (currentUser == null) {
            url = "redirect:login.jsp";
            return;
        }

        String oldPassword     = request.getParameter("oldPassword");
        String newPassword     = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // Validate: mật khẩu mới phải khớp xác nhận
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "New passwords do not match");
            url = "change-password.jsp";
            return;
        }

        UserDAO udao = new UserDAO();
        // DAO sẽ hash oldPassword và so sánh với DB trước khi cập nhật
        boolean success = udao.changePassword(currentUser.getId(), oldPassword, newPassword);

        if (success) {
            request.setAttribute("msg", "Password changed successfully!");
        } else {
            request.setAttribute("error", "Old password is incorrect"); // oldPassword sai
        }
        url = "change-password.jsp";
    }

    /**
     * Thêm người dùng mới (admin thêm thủ công).
     * Nếu action = "saveAddUser" → xử lý lưu DB, nếu không → hiển thị form.
     * Kiểm tra username đã tồn tại trước khi INSERT.
     * Nếu INSERT thất bại → ReseedSQL (reset auto-increment để tránh gap ID).
     *
     * @param request Chứa username, password, role, fullName, email, phone, status
     */
    private void AddUser(HttpServletRequest request) {
        String msg   = "";
        String error = "";

        UserDAO udao = new UserDAO();
        String action = request.getParameter("action");

        if (action.equals("saveAddUser")) {
            // Lấy dữ liệu từ form
            String username  = request.getParameter("username");
            String password  = request.getParameter("password");
            String role      = request.getParameter("role");
            String fullName  = request.getParameter("fullName");
            String email     = request.getParameter("email");
            String phone     = request.getParameter("phone");
            // Mặc định "active" nếu không có status
            String status = request.getParameter("status") != null ? request.getParameter("status") : "active";

            // Kiểm tra username đã tồn tại chưa (null = không loại trừ ID nào)
            if (udao.isUsernameExists(username, null)) {
                error = "Username already exists";
                request.setAttribute("users",     udao.getAllUsers());
                request.setAttribute("showModal", true);  // JSP mở lại modal thêm user
                request.setAttribute("error",     error);
                url = "user-list.jsp";
                return;

            } else {
                // Tạo DTO và INSERT vào DB
                UserDTO u = new UserDTO();
                u.setUsername(username);
                u.setPassword(password);
                u.setRole(role);
                u.setFullName(fullName);
                u.setEmail(email);
                u.setPhone(phone);
                u.setStatus(status);

                if (udao.Add(u)) {
                    msg = "Thêm người dùng thành công!";
                    url = "redirect:UserController?action=list"; // Redirect về danh sách
                    return;

                } else {
                    // INSERT thất bại → ReseedSQL để tránh gap trong auto-increment
                    error = "Failed to add user";
                    udao.ReseedSQL(); // Reset seed ID sau khi insert thất bại
                    request.setAttribute("users",     udao.getAllUsers());
                    request.setAttribute("showModal", true); // Mở lại modal
                    request.setAttribute("error",     error);
                    url = "user-list.jsp";
                    return;
                }
            }
        }

        // Không phải saveAddUser → hiển thị form thêm mới
        url = "user-form.jsp";
    }

    /**
     * Cập nhật thông tin người dùng (admin chỉnh sửa).
     * Nếu action = "saveUpdateUser" → xử lý lưu DB, nếu không → tải form sửa.
     * Kiểm tra username đã tồn tại ở user khác trước khi UPDATE.
     * Password: nếu form để rỗng → giữ nguyên mật khẩu cũ.
     *
     * @param request Chứa id, username, password, role, fullName, email, phone, status
     */
    private void UpdateUser(HttpServletRequest request) {
        String msg   = "";
        String error = "";

        UserDAO udao = new UserDAO();
        String action = request.getParameter("action");
        String s_id  = request.getParameter("id");
        int id = 0;

        try {
            if (s_id != null && !s_id.isEmpty()) {
                id = Integer.parseInt(s_id); // Parse ID user cần cập nhật
            }
        } catch (Exception e) {
            error += "ID must be a number";
        }

        UserDTO existingUser = udao.SearchByID(id); // Lấy dữ liệu cũ để giữ nguyên nếu cần

        if (action.equals("saveUpdateUser")) {
            String username  = request.getParameter("username");
            String password  = request.getParameter("password");
            String role      = request.getParameter("role");
            String fullName  = request.getParameter("fullName");
            String email     = request.getParameter("email");
            String phone     = request.getParameter("phone");
            String status    = request.getParameter("status");

            // Kiểm tra username đã bị dùng bởi user KHÁC chưa (loại trừ id hiện tại)
            if (udao.isUsernameExists(username, id)) {
                error = "Username already exists";
                request.setAttribute("users",         udao.getAllUsers());
                request.setAttribute("showEditModal", true);     // Mở lại modal edit
                request.setAttribute("editUser",      existingUser);
                request.setAttribute("error",         error);
                url = "user-list.jsp";
                return;

            } else {
                UserDTO u = new UserDTO();
                u.setId(id);
                u.setUsername(username);
                // Giữ nguyên mật khẩu cũ nếu form để rỗng (không bắt buộc đổi password khi edit)
                u.setPassword(password != null && !password.isEmpty()
                        ? password               // Mật khẩu mới
                        : existingUser.getPassword()); // Mật khẩu cũ
                u.setRole(role);
                u.setFullName(fullName);
                u.setEmail(email);
                u.setPhone(phone);
                u.setStatus(status);

                if (udao.Update(u)) {
                    msg = "Cập nhật người dùng thành công!";
                    url = "redirect:UserController?action=list";
                    return;

                } else {
                    error = "Failed to update user";
                    request.setAttribute("users",         udao.getAllUsers());
                    request.setAttribute("showEditModal", true);
                    request.setAttribute("editUser",      existingUser);
                    request.setAttribute("error",         error);
                    url = "user-list.jsp";
                    return;
                }
            }
        }

        // Không phải saveUpdateUser → tải form sửa với dữ liệu hiện tại
        request.setAttribute("editUser", existingUser);
        url = "user-form.jsp";
    }

    /** Xử lý HTTP GET – xem danh sách, form thêm/sửa */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Xử lý HTTP POST – đăng nhập, thêm, sửa, xóa, đổi mật khẩu */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /** Mô tả ngắn về servlet này */
    @Override
    public String getServletInfo() {
        return "User Controller";
    }

    // ============================= HỒ SƠ CÁ NHÂN =============================

    /**
     * Xem hồ sơ cá nhân của người dùng đang đăng nhập.
     * Làm mới dữ liệu user từ DB để đảm bảo thông tin luôn cập nhật nhất.
     * Nếu đã có thay đổi từ thiết bị khác → session sẽ được sync.
     */
    private void viewProfile(HttpServletRequest request) {
        HttpSession session = request.getSession();
        UserDTO user = (UserDTO) session.getAttribute("user");

        if (user == null) {
            url = "redirect:login.jsp"; // Chưa đăng nhập → về login
            return;
        }

        // Làm mới từ DB (đảm bảo thông tin mới nhất, không dùng session cũ)
        UserDAO udao = new UserDAO();
        UserDTO freshUser = udao.SearchByID(user.getId());
        if (freshUser != null) {
            session.setAttribute("user", freshUser); // Cập nhật session với data mới
        }

        url = "profile.jsp";
    }

    /**
     * Cập nhật hồ sơ cá nhân (họ tên, email, số điện thoại).
     * Giữ nguyên role, username, mật khẩu (người dùng không tự thay đổi được).
     * Sau khi cập nhật thành công → làm mới session với thông tin mới.
     *
     * @param request Chứa "fullName", "email", "phone"
     */
    private void updateProfile(HttpServletRequest request) {
        HttpSession session = request.getSession();
        UserDTO currentUser = (UserDTO) session.getAttribute("user");

        if (currentUser == null) {
            url = "redirect:login.jsp";
            return;
        }

        String fullName = request.getParameter("fullName"); // Họ tên mới
        String email    = request.getParameter("email");    // Email mới
        String phone    = request.getParameter("phone");    // Điện thoại mới

        UserDAO udao = new UserDAO();
        UserDTO u = new UserDTO();
        u.setId(currentUser.getId());
        u.setUsername(currentUser.getUsername());        // Giữ nguyên username
        u.setPassword(currentUser.getPassword());        // Giữ nguyên mật khẩu
        u.setRole(currentUser.getRole());                // Giữ nguyên vai trò
        u.setStatus(currentUser.getStatus());            // Giữ nguyên trạng thái
        u.setFullName(fullName);                         // Cập nhật họ tên
        u.setEmail(email);                               // Cập nhật email
        u.setPhone(phone);                               // Cập nhật điện thoại

        boolean success = udao.Update(u); // Cập nhật DB

        if (success) {
            // Làm mới session với thông tin mới nhất sau khi cập nhật
            UserDTO updatedUser = udao.SearchByID(currentUser.getId());
            if (updatedUser != null) {
                session.setAttribute("user", updatedUser); // Sync session
            }
            request.setAttribute("success", "Cap nhat thong tin thanh cong!");
        } else {
            request.setAttribute("error", "Loi khi cap nhat thong tin!");
        }

        url = "profile.jsp";
    }

    /**
     * Đổi mật khẩu cá nhân với validate đầy đủ (form từ profile.jsp).
     * Validate:
     *   - Tất cả trường không được rỗng
     *   - newPassword phải khớp confirmPassword
     *   - newPassword phải ít nhất 6 ký tự
     *   - currentPassword phải đúng (xác minh qua DAO.verifyPassword)
     * Nếu thành công → cập nhật DB qua resetPassword.
     *
     * @param request  Chứa "currentPassword", "newPassword", "confirmPassword"
     * @param response HttpServletResponse để forward kết quả
     */
    private void doChangePassword(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        UserDTO currentUser = (UserDTO) session.getAttribute("user");

        if (currentUser == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String currentPassword  = request.getParameter("currentPassword"); // Mật khẩu hiện tại
        String newPassword      = request.getParameter("newPassword");     // Mật khẩu mới
        String confirmPassword  = request.getParameter("confirmPassword"); // Xác nhận mật khẩu mới

        // Validate 1: Không được rỗng
        if (currentPassword == null || newPassword == null || confirmPassword == null
                || currentPassword.isEmpty() || newPassword.isEmpty()) {
            request.setAttribute("error", "Vui long nhap day du thong tin!");
            url = "profile.jsp";
            request.getRequestDispatcher(url).forward(request, response);
            return;
        }

        // Validate 2: Mật khẩu mới phải khớp xác nhận
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "Mat khau moi khong khop!");
            url = "profile.jsp";
            request.getRequestDispatcher(url).forward(request, response);
            return;
        }

        // Validate 3: Mật khẩu mới phải ít nhất 6 ký tự
        if (newPassword.length() < 6) {
            request.setAttribute("error", "Mat khau moi phai it nhat 6 ky tu!");
            url = "profile.jsp";
            request.getRequestDispatcher(url).forward(request, response);
            return;
        }

        // Validate 4: Xác minh mật khẩu hiện tại đúng không
        UserDAO udao = new UserDAO();
        if (!udao.verifyPassword(currentUser.getId(), currentPassword)) {
            request.setAttribute("error", "Mat khau hien tai khong dung!"); // Mật khẩu hiện tại sai
            url = "profile.jsp";
            request.getRequestDispatcher(url).forward(request, response);
            return;
        }

        // Cập nhật mật khẩu mới vào DB
        boolean success = udao.resetPassword(currentUser.getId(), newPassword);

        if (success) {
            request.setAttribute("success", "Doi mat khau thanh cong!");
        } else {
            request.setAttribute("error", "Loi khi doi mat khau!");
        }

        url = "profile.jsp";
        request.getRequestDispatcher(url).forward(request, response);
    }
}
