<%@page import="pms.model.ItemDAO"%>
<%@page import="pms.model.ItemDTO"%>
<%@page import="java.util.ArrayList"%>
<%
    ItemDAO dao = new ItemDAO();
    ArrayList<ItemDTO> list = dao.getAllItems();
    for (ItemDTO i : list) {
        out.println("ID:" + i.getItemID() + " Name:" + i.getItemName() + " Type:" + i.getItemType() + "<br>");
    }
%>
