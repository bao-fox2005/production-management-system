<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="pms.utils.DBUtils"%>
<%
    out.println("BILLS:<br>");
    String sql = "SELECT bill_id, status, total_amount, bill_date FROM Bill";
    try (Connection conn = DBUtils.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            out.println("ID:" + rs.getInt("bill_id") + " Status:" + rs.getString("status") + " Amount:" + rs.getDouble("total_amount") + " Date:" + rs.getDate("bill_date") + "<br>");
        }
    } catch (Exception e) { e.printStackTrace(); }
%>
