package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import pms.utils.DBUtils;

public class ItemDAO {

    private ItemDTO mapItem(ResultSet rs) throws Exception {
        return new ItemDTO(
                rs.getInt("item_id"),
                rs.getString("item_name"),
                rs.getString("item_type"),
                rs.getInt("stock_quantity"),
                rs.getString("unit"),
                rs.getString("description"),
                rs.getInt("min_stock_level"),
                rs.getString("image_base64")
        );
    }

    private ItemDTO SearchByColumn(String column, String value) {
        String sql = "SELECT * FROM Item WHERE " + column + " = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, value);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapItem(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private ArrayList<ItemDTO> FilterByColumn(String column, String value) {
        ArrayList<ItemDTO> iList = new ArrayList<>();
        String sql = "SELECT * FROM Item WHERE " + column + " LIKE ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, "%" + value + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    iList.add(mapItem(rs));
                }
            }
            return iList;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public ItemDTO SearchByCode(String code) {
        return SearchByColumn("item_code", code);
    }

    public ItemDTO SearchByID(String id) {
        return SearchByColumn("item_id", id);
    }

    public ItemDTO SearchByID(int id) {
        return SearchByColumn("item_id", id + "");
    }

    public ArrayList<ItemDTO> FilterByName(String name) {
        return FilterByColumn("item_name", name);
    }

    public ArrayList<ItemDTO> getAllItems() {
        ArrayList<ItemDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Item ORDER BY item_id DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapItem(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ArrayList<ItemDTO> getItemsByType(String itemType) {
        ArrayList<ItemDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Item WHERE item_type = ? ORDER BY item_id DESC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, itemType);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapItem(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ArrayList<ItemDTO> getProducts() {
        return getItemsByType("SanPham");
    }

    public ArrayList<ItemDTO> getMaterials() {
        return getItemsByType("VatTu");
    }

    public ArrayList<ItemDTO> getLowStockItems() {
        ArrayList<ItemDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Item WHERE stock_quantity <= min_stock_level ORDER BY stock_quantity ASC";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapItem(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public Boolean Delete(int id) {
        String sql = "DELETE FROM Item WHERE item_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public Boolean SoftDelete(String id) {
        return Delete(Integer.parseInt(id));
    }

    public boolean Add(ItemDTO i) {
        String sql = "INSERT INTO Item (item_name, item_type, stock_quantity, unit, description, min_stock_level, image_base64) VALUES(?,?,?,?,?,?,?)";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, i.getItemName());
            ps.setString(2, i.getItemType());
            ps.setInt(3, i.getStockQuantity());
            ps.setString(4, i.getUnit());
            ps.setString(5, i.getDescription());
            ps.setInt(6, i.getMinStockLevel());
            ps.setString(7, i.getImageBase64());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean Update(ItemDTO i) {
        String sql = "UPDATE Item SET item_name = ?, item_type = ?, stock_quantity = ?, unit = ?, description = ?, min_stock_level = ?, image_base64 = ? WHERE item_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, i.getItemName());
            ps.setString(2, i.getItemType());
            ps.setInt(3, i.getStockQuantity());
            ps.setString(4, i.getUnit());
            ps.setString(5, i.getDescription());
            ps.setInt(6, i.getMinStockLevel());
            ps.setString(7, i.getImageBase64());
            ps.setInt(8, i.getItemID());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateStock(int itemId, int newQuantity) {
        String sql = "UPDATE Item SET stock_quantity = ? WHERE item_id = ?";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, newQuantity);
            ps.setInt(2, itemId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean increaseStock(int itemId, int quantity) {
        ItemDTO item = SearchByID(itemId);
        if (item != null) {
            return updateStock(itemId, item.getStockQuantity() + quantity);
        }
        return false;
    }

    public boolean decreaseStock(int itemId, int quantity) {
        ItemDTO item = SearchByID(itemId);
        if (item != null && item.getStockQuantity() >= quantity) {
            return updateStock(itemId, item.getStockQuantity() - quantity);
        }
        return false;
    }

    public int GetCurrentID() {
        String sql = "SELECT MAX(item_id) as max_id FROM Item";
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("max_id") + 1;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 1;
    }

    public ArrayList<ItemDTO> ItemList() {
        return getAllItems();
    }

    public void ReseedSQL() {
        try (Connection con = DBUtils.getConnection();
                PreparedStatement ps = con.prepareStatement("DBCC CHECKIDENT ('Item', RESEED, " + GetCurrentID() + ")")) {
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
