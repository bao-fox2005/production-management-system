<%--
  ===== welcome.jsp – Trang điểm vào hệ thống =====
  Mục đích  : Redirect ngay lập tức sang DashboardController sau khi xác thực.
  Phân quyền: AuthenticationFilter bắt buộc đăng nhập trước khi vào trang này.
  Lưu ý     : Không render HTML. Dùng getContextPath() để tương thích khi deploy
               trên các context path khác nhau (vd: /pms/ thay vì /).
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    // Chuyển hướng toàn bộ traffic sang Dashboard – đây là trang gốc của ứng dụng
    response.sendRedirect(request.getContextPath() + "/DashboardController");
%>
