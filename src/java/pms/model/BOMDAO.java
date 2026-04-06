package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

public class BOMDAO {

    private BOMDTO mapBOM(ResultSet rs) throws Exception {
        return new BOMDTO(
                rs.getInt("bom_id"),
                rs.getInt("product_item_id"),
                rs.getString("product_name"),
                rs.getString("bom_version"),
                rs.getString("status"),
                rs.getTimestamp("created_date"),
                rs.getString("notes")
        );
    }

    private BOMDetailDTO mapBOMDetail(ResultSet rs) throws Exception {
        return new BOMDetailDTO(
                rs.getInt("bom_detail_id"),
                rs.getInt("bom_id"),
                rs.getInt("material_item_id"),
                rs.getString("material_name"),
                rs.getDouble("quantity_required"),
                rs.getString("unit"),
                rs.getDouble("waste_percent"),
                rs.getString("notes")
        );
    }

    public List<BOMDTO> getAllBOMS() {
        List<BOMDTO> list = new ArrayList<>();
        String sql = "SELECT b.*, i.item_name as product_name "
                + "FROM BOM b "
                + "LEFT JOIN Item i ON b.product_item_id = i.item_id "
                + "ORDER BY b.created_date DESC";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapBOM(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<BOMDTO> getBOMSByProduct(int productItemId) {
        List<BOMDTO> list = new ArrayList<>();
        String sql = "SELECT b.*, i.item_name as product_name "
                + "FROM BOM b "
                + "LEFT JOIN Item i ON b.product_item_id = i.item_id "
                + "WHERE b.product_item_id = ? "
                + "ORDER BY b.created_date DESC";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productItemId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapBOM(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<BOMDTO> getBOMSByStatus(String status) {
        List<BOMDTO> list = new ArrayList<>();
        String sql = "SELECT b.*, i.item_name as product_name "
                + "FROM BOM b "
                + "LEFT JOIN Item i ON b.product_item_id = i.item_id "
                + "WHERE b.status = ? "
                + "ORDER BY b.created_date DESC";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapBOM(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public BOMDTO getBOMById(int bomId) {
        String sql = "SELECT b.*, i.item_name as product_name "
                + "FROM BOM b "
                + "LEFT JOIN Item i ON b.product_item_id = i.item_id "
                + "WHERE b.bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, bomId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    BOMDTO bom = mapBOM(rs);
                    bom.setDetails(getBOMDetails(bomId));
                    return bom;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<BOMDetailDTO> getBOMDetails(int bomId) {
        List<BOMDetailDTO> list = new ArrayList<>();
        String sql = "SELECT bd.*, i.item_name as material_name "
                + "FROM BOM_Detail bd "
                + "LEFT JOIN Item i ON bd.material_item_id = i.item_id "
                + "WHERE bd.bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, bomId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapBOMDetail(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insertBOM(BOMDTO bom) {
        String sql = "INSERT INTO BOM (product_item_id, bom_version, status, notes) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, bom.getProductItemId());
            ps.setString(2, bom.getBomVersion());
            ps.setString(3, bom.getStatus() != null ? bom.getStatus() : "active");
            ps.setString(4, bom.getNotes());
            int rows = ps.executeUpdate();
            if (rows > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        bom.setBomId(rs.getInt(1));
                    }
                }
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateBOM(BOMDTO bom) {
        String sql = "UPDATE BOM SET product_item_id = ?, bom_version = ?, status = ?, notes = ? WHERE bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, bom.getProductItemId());
            ps.setString(2, bom.getBomVersion());
            ps.setString(3, bom.getStatus());
            ps.setString(4, bom.getNotes());
            ps.setInt(5, bom.getBomId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteBOM(int bomId) {
        String sqlDetail = "DELETE FROM BOM_Detail WHERE bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sqlDetail)) {
            ps.setInt(1, bomId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }

        String sqlBom = "DELETE FROM BOM WHERE bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sqlBom)) {
            ps.setInt(1, bomId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean addBOMDetail(BOMDetailDTO detail) {
        String sql = "INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, detail.getBomId());
            ps.setInt(2, detail.getMaterialItemId());
            ps.setDouble(3, detail.getQuantityRequired());
            ps.setString(4, detail.getUnit());
            ps.setDouble(5, detail.getWastePercent());
            ps.setString(6, detail.getNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateBOMDetail(BOMDetailDTO detail) {
        String sql = "UPDATE BOM_Detail SET material_item_id = ?, quantity_required = ?, unit = ?, waste_percent = ?, notes = ? WHERE bom_detail_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, detail.getMaterialItemId());
            ps.setDouble(2, detail.getQuantityRequired());
            ps.setString(3, detail.getUnit());
            ps.setDouble(4, detail.getWastePercent());
            ps.setString(5, detail.getNotes());
            ps.setInt(6, detail.getBomDetailId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteBOMDetail(int detailId) {
        String sql = "DELETE FROM BOM_Detail WHERE bom_detail_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, detailId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteBOMDetailsByBomId(int bomId) {
        String sql = "DELETE FROM BOM_Detail WHERE bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, bomId);
            ps.executeUpdate();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean cloneBOM(int sourceBomId, String newVersion) {
        BOMDTO sourceBOM = getBOMById(sourceBomId);
        if (sourceBOM == null) {
            return false;
        }

        BOMDTO newBOM = new BOMDTO();
        newBOM.setProductItemId(sourceBOM.getProductItemId());
        newBOM.setBomVersion(newVersion);
        newBOM.setStatus("active");
        newBOM.setNotes(sourceBOM.getNotes());

        if (!insertBOM(newBOM)) {
            return false;
        }

        List<BOMDetailDTO> details = sourceBOM.getDetails();
        if (details != null) {
            for (BOMDetailDTO detail : details) {
                detail.setBomId(newBOM.getBomId());
                detail.setBomDetailId(0);
                addBOMDetail(detail);
            }
        }

        return true;
    }

    public boolean updateStatus(int bomId, String status) {
        String sql = "UPDATE BOM SET status = ? WHERE bom_id = ?";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, bomId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deactivateBOM(int bomId) {
        return updateStatus(bomId, "inactive");
    }

    public boolean activateBOM(int bomId) {
        return updateStatus(bomId, "active");
    }
}
