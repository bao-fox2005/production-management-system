<%--
  ===== BangDieuKien.jsp – Alias redirect sang Dashboard =====
  Mục đích  : File này là lối tắt legacy (cũ). Bất kỳ URL nào trỏ vào đây
               đều được redirect về DashboardController ngay lập tức.
  Tại sao   : Một số bookmark/link cũ trong code có thể trỏ đến "BangDieuKien.jsp".
               File này đảm bảo không bị 404 trong khi vẫn giữ trải nghiệm liền mạch.
  Phân quyền: Xử lý bởi AuthenticationFilter (bắt buộc đăng nhập).
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Redirect về Dashboard – trang chính sau đăng nhập
    response.sendRedirect("DashboardController");
    return; // Ngăn code HTML bên dưới được xử lý
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0;url=DashboardController">
    <title>Chuyển hướng bảng điều khiển</title>
</head>
<body>
</body>
</html>
