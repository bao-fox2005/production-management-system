<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quản Lý Nhà Cung Cấp</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="bg-light p-4">
    <c:set var="mode" value="${not empty supplierEdit ? 'update' : 'add'}" />
    <div class="container-fluid">
        <div class="mb-3"><a href="MainController?action=loginUser" class="btn btn-secondary shadow-sm"><i class="fa-solid fa-arrow-left"></i> Dashboard</a></div>
        <div class="row">
            <div class="col-md-4">
                <div class="card shadow border-0">
                    <div class="card-header ${mode == 'update' ? 'bg-warning text-dark' : 'bg-primary text-white'} fw-bold">
                        <i class="fa-solid fa-truck"></i> ${mode == 'update' ? 'Cập Nhật NPP' : 'Thêm Nhà Cung Cấp'}
                    </div>
                    <div class="card-body">
                        <form action="MainController" method="post">
                            <input type="hidden" name="action" value="${mode == 'update' ? 'saveUpdateSupplier' : 'addSupplier'}">
                            <c:if test="${mode == 'update'}">
                                <input type="hidden" name="id" value="${supplierEdit.supplierId}">
                            </c:if>
                            <div class="mb-3">
                                <label class="form-label fw-bold">Tên Nhà Cung Cấp</label>
                                <input type="text" name="supplierName" class="form-control border-primary" value="${supplierEdit.supplierName}" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label fw-bold">Số Điện Thoại</label>
                                <input type="text" name="contactPhone" class="form-control border-primary" value="${supplierEdit.contactPhone}" required>
                            </div>
                            <button type="submit" class="btn ${mode == 'update' ? 'btn-warning' : 'btn-primary'} w-100 fw-bold shadow-sm">LƯU THÔNG TIN</button>
                            <c:if test="${mode == 'update'}"><a href="MainController?action=listSupplier" class="btn btn-outline-secondary w-100 mt-2">Hủy Bỏ</a></c:if>
                        </form>
                    </div>
                </div>
            </div>
            <div class="col-md-8">
                <div class="card shadow border-0">
                    <div class="card-header bg-dark text-white fw-bold">Danh Sách Đối Tác Cung Cấp Vật Tư</div>
                    <div class="card-body">
                        <form action="MainController" method="get" class="mb-3 d-flex">
                            <input type="hidden" name="action" value="searchSupplier">
                            <input type="text" name="keyword" class="form-control me-2" placeholder="Nhập tên hoặc số điện thoại..." value="${param.keyword}">
                            <button type="submit" class="btn btn-outline-primary text-nowrap"><i class="fa-solid fa-magnifying-glass"></i> Tìm Kiếm</button>
                        </form>

                        <div class="table-responsive">
                            <table class="table align-middle table-hover border text-center">
                                <thead class="table-light"><tr><th>ID</th><th>Tên Nhà Cung Cấp</th><th>Số Điện Thoại</th><th>Hành Động</th></tr></thead>
                                <tbody>
                                    <c:forEach items="${supplierList}" var="s">
                                        <tr>
                                            <td class="fw-bold text-primary">NPP-${s.supplierId}</td>
                                            <td class="text-start fw-bold">${s.supplierName}</td>
                                            <td>${s.contactPhone}</td>
                                            <td>
                                                <a href="MainController?action=loadUpdateSupplier&id=${s.supplierId}" class="btn btn-sm btn-warning"><i class="fa-solid fa-pen"></i></a>
                                                <a href="MainController?action=deleteSupplier&id=${s.supplierId}" class="btn btn-sm btn-danger" onclick="return confirm('Xóa đối tác này?')"><i class="fa-solid fa-trash"></i></a>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>