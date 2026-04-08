<%-- item-form.jsp - Thêm/Sửa vật phẩm --%>
<%@page import="pms.model.ItemDTO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String mode = (String) request.getAttribute("mode");
    ItemDTO item = (ItemDTO) request.getAttribute("item");
    boolean isAdd = "add".equals(mode);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isAdd ? "Thêm" : "Sửa" %> vật phẩm</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background-color: #f5f6fa; }
        .sidebar { min-height: 100vh; background: #2c3e50; color: white; }
        .sidebar a { color: white; text-decoration: none; padding: 12px 20px; display: block; }
        .sidebar a:hover { background: #34495e; }
        .form-card { background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
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
                <a href="UserController?action=list"><i class="fas fa-users me-2"></i> Người dùng</a>
                <a href="ItemController?action=list" class="active"><i class="fas fa-box me-2"></i> Vật phẩm</a>
                <a href="BOMController?action=list"><i class="fas fa-clipboard-list me-2"></i> BOM</a>
                <a href="RoutingController?action=list"><i class="fas fa-route me-2"></i> Quy trình</a>
                <a href="WorkOrderController?action=list"><i class="fas fa-industry me-2"></i> Lệnh sản xuất</a>
                <a href="SupplierController?action=list"><i class="fas fa-truck me-2"></i> Nhà cung cấp</a>
                <a href="CustomerController?action=list"><i class="fas fa-user-tie me-2"></i> Khách hàng</a>
            </div>

            <div class="col-md-10 p-4">
                <div class="mb-3">
                    <a href="ItemController?action=list" class="btn btn-secondary">
                        <i class="fas fa-arrow-left me-2"></i>Quay lại
                    </a>
                </div>

                <div class="form-card" style="max-width: 700px; margin: 0 auto;">
                    <h2 class="mb-4">
                        <i class="fas fa-box<%= isAdd ? "-plus" : "-edit" %> me-2"></i>
                        <%= isAdd ? "Thêm" : "Sửa" %> vật phẩm
                    </h2>

                    <!-- Messages -->
                    <% if (request.getAttribute("msg") != null) { %>
                        <div class="alert alert-success alert-dismissible fade show">
                            <%= request.getAttribute("msg") %>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <% } %>
                    <% if (request.getAttribute("error") != null) { %>
                        <div class="alert alert-danger alert-dismissible fade show">
                            <%= request.getAttribute("error") %>
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    <% } %>

                    <form method="post" action="ItemController">
                        <input type="hidden" name="action" value="<%= isAdd ? "saveAddItem" : "saveUpdateItem" %>">
                        <% if (!isAdd) { %>
                            <input type="hidden" name="id" value="<%= item.getItemID() %>">
                        <% } %>

                        <div class="mb-3">
                            <label class="form-label">Tên vật phẩm <span class="text-danger">*</span></label>
                            <input type="text" name="itemName" class="form-control" required
                                   value="<%= item != null ? item.getItemName() : "" %>">
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Loại <span class="text-danger">*</span></label>
                                <select name="itemType" class="form-select" required>
                                    <option value="">-- Chọn loại --</option>
                                    <option value="SanPham" <%= item != null && "SanPham".equals(item.getItemType()) ? "selected" : "" %>>Sản phẩm</option>
                                    <option value="VatTu" <%= item != null && "VatTu".equals(item.getItemType()) ? "selected" : "" %>>Vật tư</option>
                                </select>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Đơn vị tính</label>
                                <input type="text" name="unit" class="form-control" placeholder="VD: cái, kg, m..."
                                       value="<%= item != null && item.getUnit() != null ? item.getUnit() : "" %>">
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Số lượng tồn kho</label>
                                <input type="number" name="stockQuantity" class="form-control" min="0"
                                       value="<%= item != null ? item.getStockQuantity() : 0 %>">
                            </div>
                            <div class="col-md-6 mb-3">
                                <label class="form-label">Tồn kho tối thiểu</label>
                                <input type="number" name="minStockLevel" class="form-control" min="0"
                                       value="<%= item != null ? item.getMinStockLevel() : 0 %>">
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label">Mô tả</label>
                            <textarea name="description" class="form-control" rows="3"><%= item != null && item.getDescription() != null ? item.getDescription() : "" %></textarea>
                        </div>

                        <div class="d-flex gap-2">
                            <button type="submit" class="btn btn-primary">
                                <i class="fas fa-save me-2"></i>Lưu
                            </button>
                            <a href="ItemController?action=list" class="btn btn-secondary">Hủy</a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
