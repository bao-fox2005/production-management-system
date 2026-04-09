<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="pms.utils.DBUtils"%>
<%
    out.println("ITEMS:<br>");
    String sql = "SELECT item_id, item_name, item_type FROM Item";
    try (Connection conn = DBUtils.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {
        while (rs.next()) {
            out.println("ID:" + rs.getInt("item_id") + " Name:" + rs.getString("item_name") + " Type:" + rs.getString("item_type") + "<br>");
        }
    } catch (Exception e) { e.printStackTrace(); }
%>
