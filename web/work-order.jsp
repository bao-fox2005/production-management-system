<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quản Lý Lệnh Sản Xuất</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="bg-light p-4">
    <c:set var="mode" value="${not empty woEdit ? 'update' : 'add'}" />

    <div class="container-fluid">
        <div class="mb-3">
            <a href="MainController?action=loginUser" class="btn btn-secondary shadow-sm">
                <i class="fa-solid fa-arrow-left me-1"></i> Quay lại Dashboard
            </a>
        </div>

        <div class="row">
            <div class="col-md-4">
                <div class="card shadow border-0 sticky-top">
                    <div class="card-header ${mode == 'update' ? 'bg-warning text-dark' : 'bg-primary text-white'} fw-bold">
                        <i class="fa-solid ${mode == 'update' ? 'fa-pen-to-square' : 'fa-file-signature'} me-2"></i> 
                        ${mode == 'update' ? 'Cập Nhật Lệnh Sản Xuất' : 'Tạo Lệnh Làm Việc Mới'}
                    </div>
                    <div class="card-body">
                        <form action="MainController" method="post">
                            <input type="hidden" name="action" value="${mode == 'update' ? 'saveUpdateWorkOrder' : 'addWorkOrder'}">
                            
                            <c:if test="${mode == 'update'}">
                                <div class="mb-2">
                                    <label class="form-label fw-bold">Mã Lệnh</label>
                                    <input type="text" name="id" class="form-control bg-light" value="${woEdit.workOrderID}" readonly>
                                </div>
                            </c:if>

                            <div class="mb-2">
                                <label class="form-label fw-bold">Khách Hàng</label>
                                <select name="cId" class="form-select border-primary" required>
                                    <option value="">-- Chọn khách hàng --</option>
                                    <c:forEach items="${listC}" var="c">
                                        <option value="${c.customer_id}" ${woEdit.customerID == c.customer_id ? 'selected' : ''}>${c.customer_name}</option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="mb-2">
                                <label class="form-label fw-bold">Sản Phẩm</label>
                                <select name="pId" class="form-select border-primary" required>
                                    <option value="">-- Chọn sản phẩm --</option>
                                    <c:forEach items="${listI}" var="i">
                                        <c:if test="${i.itemType == 'SanPham'}">
                                            <option value="${i.itemID}" ${woEdit.productItemID == i.itemID ? 'selected' : ''}>${i.itemName}</option>
                                        </c:if>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="mb-2">
                                <label class="form-label fw-bold">Quy Trình</label>
                                <select name="rId" class="form-select border-primary" required>
                                    <option value="">-- Chọn quy trình --</option>
                                    <c:forEach items="${listR}" var="r">
                                        <option value="${r.routingId}" ${woEdit.routingID == r.routingId ? 'selected' : ''}>${r.routingName}</option>
                                    </c:forEach>
                                </select>
                            </div>

                            <div class="mb-3">
                                <label class="form-label fw-bold">Số Lượng</label>
                                <input type="number" name="qty" class="form-control border-primary" value="${mode == 'update' ? woEdit.quantity : '1'}" min="1" required>
                            </div>

                            <c:if test="${mode == 'update'}">
                                <div class="mb-3">
                                    <label class="form-label fw-bold text-danger">Trạng Thái Lệnh</label>
                                    <select name="status" class="form-select border-danger">
                                        <option value="New" ${woEdit.status == 'New' ? 'selected' : ''}>New (Mới)</option>
                                        <option value="InProgress" ${woEdit.status == 'InProgress' ? 'selected' : ''}>In Progress (Đang làm)</option>
                                        <option value="Completed" ${woEdit.status == 'Completed' ? 'selected' : ''}>Completed (Xong)</option>
                                    </select>
                                </div>
                            </c:if>

                            <button type="submit" class="btn ${mode == 'update' ? 'btn-warning fw-bold' : 'btn-primary fw-bold'} w-100 shadow-sm">
                                ${mode == 'update' ? 'LƯU CẬP NHẬT' : 'PHÁT LỆNH XUỐNG XƯỞNG'}
                            </button>
                            
                            <c:if test="${mode == 'update'}">
                                <a href="MainController?action=listWorkOrder" class="btn btn-outline-secondary w-100 mt-2">Hủy Bỏ</a>
                            </c:if>
                        </form>
                    </div>
                </div>
            </div>
            
            <div class="col-md-8">
                <div class="card shadow border-0">
                    <div class="card-header bg-dark text-white fw-bold d-flex justify-content-between align-items-center">
                        <span>Quản Lý Tiến Độ Các Lệnh Sản Xuất</span>
                    </div>
                    <div class="card-body">
                        
                        <form action="MainController" method="get" class="mb-3 d-flex">
                            <input type="hidden" name="action" value="searchWorkOrder">
                            <input type="text" name="keyword" class="form-control me-2" placeholder="Tìm theo Mã Lệnh, Trạng Thái hoặc Tên Khách Hàng..." value="${param.keyword}">
                            <button type="submit" class="btn btn-outline-primary text-nowrap"><i class="fa-solid fa-magnifying-glass"></i> Tìm Lệnh</button>
                        </form>

                        <div class="table-responsive" style="max-height: 500px; overflow-y: auto;">
                            <table class="table align-middle table-hover border">
                                <thead class="table-light sticky-top text-center">
                                    <tr>
                                        <th>Mã Lệnh</th>
                                        <th>Khách Hàng</th>
                                        <th>Sản Phẩm</th>
                                        <th>Số Lượng</th>
                                        <th>Trạng Thái</th>
                                        <th>Hành Động</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <c:forEach items="${listWO}" var="wo">
                                        <tr class="text-center">
                                            <td class="fw-bold text-primary">#WO-${wo.workOrderID}</td>
                                            
                                            <td class="text-start">
                                                <i class="fa-solid fa-user text-muted me-1"></i> 
                                                <c:forEach items="${listC}" var="c">
                                                    <c:if test="${c.customer_id == wo.customerID}"><b>${c.customer_name}</b></c:if>
                                                </c:forEach>
                                            </td> 
                                            
                                            <td class="text-start">
                                                <i class="fa-solid fa-box text-muted me-1"></i>
                                                <c:forEach items="${listI}" var="i">
                                                    <c:if test="${i.itemID == wo.productItemID}">${i.itemName}</c:if>
                                                </c:forEach>
                                            </td>

                                            <td><b class="text-danger fs-5">${wo.quantity}</b> cái</td>
                                            
                                            <td>
                                                <span class="badge ${wo.status == 'Completed' ? 'bg-success' : (wo.status == 'New' ? 'bg-info text-dark' : 'bg-warning text-dark')}">
                                                    ${wo.status}
                                                </span>
                                            </td>

                                            <td>
                                                <a href="MainController?action=loadUpdateWorkOrder&id=${wo.workOrderID}" class="btn btn-sm btn-warning shadow-sm" title="Sửa Trạng Thái/Lệnh"><i class="fa-solid fa-pen"></i></a>
                                                <a href="MainController?action=deleteWorkOrder&id=${wo.workOrderID}" class="btn btn-sm btn-danger shadow-sm" onclick="return confirm('Bạn có chắc muốn xóa lệnh WO-${wo.workOrderID} này?')" title="Xóa Lệnh"><i class="fa-solid fa-trash"></i></a>
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