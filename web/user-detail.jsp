<%-- user-detail.jsp - Chi tiết người dùng --%>
<%@page import="pms.model.UserDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    UserDTO user = (UserDTO) request.getAttribute("user");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chi tiết người dùng</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background-color: #f5f6fa; }
        .sidebar { min-height: 100vh; background: #2c3e50; color: white; }
        .sidebar a { color: white; text-decoration: none; padding: 12px 20px; display: block; }
        .sidebar a:hover { background: #34495e; }
        .detail-card { background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="row">
            <div class="col-md-2 sidebar p-0">
                <div class="text-center py-3 border-bottom">
                    <h5>PMS</h5>
                </div>
                <a href="BangDieuKien.jsp"><i class="fas fa-home me-2"></i> Trang chủ</a>
                <a href="UserController?action=list" class="active"><i class="fas fa-users me-2"></i> Người dùng</a>
                <a href="ItemController?action=list"><i class="fas fa-box me-2"></i> Vật phẩm</a>
                <a href="BOMController?action=list"><i class="fas fa-clipboard-list me-2"></i> BOM</a>
                <a href="RoutingController?action=list"><i class="fas fa-route me-2"></i> Quy trình</a>
                <a href="WorkOrderController?action=list"><i class="fas fa-industry me-2"></i> Lệnh sản xuất</a>
                <a href="SupplierController?action=list"><i class="fas fa-truck me-2"></i> Nhà cung cấp</a>
                <a href="CustomerController?action=list"><i class="fas fa-user-tie me-2"></i> Khách hàng</a>
            </div>

            <div class="col-md-10 p-4">
                <div class="mb-3">
                    <a href="UserController?action=list" class="btn btn-secondary">
                        <i class="fas fa-arrow-left me-2"></i>Quay lại
                    </a>
                </div>

                <div class="detail-card">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h2><i class="fas fa-user me-2"></i>Chi tiết người dùng</h2>
                        <div>
                            <a href="UserController?action=updateUser&id=<%= user.getId() %>" class="btn btn-warning">
                                <i class="fas fa-edit me-2"></i>Sửa
                            </a>
                            <% if ("active".equals(user.getStatus())) { %>
                                <a href="UserController?action=lockUser&id=<%= user.getId() %>" 
                                   class="btn btn-secondary" onclick="return confirm('Khóa tài khoản này?')">
                                    <i class="fas fa-lock me-2"></i>Khóa
                                </a>
                            <% } else { %>
                                <a href="UserController?action=unlockUser&id=<%= user.getId() %>" class="btn btn-success">
                                    <i class="fas fa-unlock me-2"></i>Mở khóa
                                </a>
                            <% } %>
                            <a href="UserController?action=resetPassword&id=<%= user.getId() %>" 
                               class="btn btn-dark" onclick="return confirm('Reset mật khẩu về 123456?')">
                                <i class="fas fa-key me-2"></i>Reset mật khẩu
                            </a>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <table class="table table-borderless">
                                <tr>
                                    <th width="40%">Mã người dùng:</th>
                                    <td><strong><%= user.getId() %></strong></td>
                                </tr>
                                <tr>
                                    <th>Username:</th>
                                    <td><%= user.getUsername() %></td>
                                </tr>
                                <tr>
                                    <th>Họ tên:</th>
                                    <td><%= user.getFullName() != null ? user.getFullName() : "Chưa cập nhật" %></td>
                                </tr>
                                <tr>
                                    <th>Email:</th>
                                    <td><%= user.getEmail() != null ? user.getEmail() : "Chưa cập nhật" %></td>
                                </tr>
                                <tr>
                                    <th>Điện thoại:</th>
                                    <td><%= user.getPhone() != null ? user.getPhone() : "Chưa cập nhật" %></td>
                                </tr>
                            </table>
                        </div>
                        <div class="col-md-6">
                            <table class="table table-borderless">
                                <tr>
                                    <th width="40%">Vai trò:</th>
                                    <td>
                                        <% if ("admin".equals(user.getRole())) { %>
                                            <span class="badge bg-danger">Admin</span>
                                        <% } else { %>
                                            <span class="badge bg-primary">Công nhân</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <tr>
                                    <th>Trạng thái:</th>
                                    <td>
                                        <% if ("active".equals(user.getStatus())) { %>
                                            <span class="badge bg-success"><i class="fas fa-check-circle me-1"></i> Hoạt động</span>
                                        <% } else { %>
                                            <span class="badge bg-secondary"><i class="fas fa-lock me-1"></i> Khóa</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <tr>
                                    <th>Ngày tạo:</th>
                                    <td><%= user.getCreatedDate() != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(user.getCreatedDate()) : "Chưa có" %></td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
