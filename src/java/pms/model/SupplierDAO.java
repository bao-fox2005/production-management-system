package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import pms.utils.DBUtils;

public class SupplierDAO {

    public ArrayList<SupplierDTO> getAllSupplier() {
        ArrayList<SupplierDTO> list = new ArrayList<>();
        String sql = "SELECT * FROM Supplier ORDER BY supplier_id DESC";
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                SupplierDTO s = new SupplierDTO();
                s.setSupplierId(rs.getInt("supplier_id"));
                s.setSupplierName(rs.getString("supplier_name"));
                s.setContactPhone(rs.getString("contact_phone"));
                try { s.setEmail(rs.getString("email")); } catch (Exception e) {}
                try { s.setAddress(rs.getString("address")); } catch (Exception e) {}
                try { s.setCity(rs.getString("city")); } catch (Exception e) {}
                try { s.setStatus(rs.getString("status")); } catch (Exception e) {}
                list.add(s);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public SupplierDTO SearchByID(int id) {
        String sql = "SELECT * FROM Supplier WHERE supplier_id = ?";
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    SupplierDTO s = new SupplierDTO();
                    s.setSupplierId(rs.getInt("supplier_id"));
                    s.setSupplierName(rs.getString("supplier_name"));
                    s.setContactPhone(rs.getString("contact_phone"));
                    try { s.setEmail(rs.getString("email")); } catch (Exception e) {}
                    try { s.setAddress(rs.getString("address")); } catch (Exception e) {}
                    try { s.setCity(rs.getString("city")); } catch (Exception e) {}
                    try { s.setStatus(rs.getString("status")); } catch (Exception e) {}
                    return s;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public ArrayList<SupplierDTO> SupplierList() {
        return getAllSupplier();
    }

    public boolean Add(SupplierDTO s) {
        String sql = "INSERT INTO Supplier (supplier_name, contact_phone, email, address, city, status) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, s.getSupplierName());
            ps.setString(2, s.getContactPhone());
            ps.setString(3, s.getEmail());
            ps.setString(4, s.getAddress());
            ps.setString(5, s.getCity());
            ps.setString(6, s.getStatus() != null ? s.getStatus() : "active");
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean Update(SupplierDTO s) {
        String sql = "UPDATE Supplier SET supplier_name = ?, contact_phone = ?, email = ?, address = ?, city = ?, status = ? WHERE supplier_id = ?";
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, s.getSupplierName());
            ps.setString(2, s.getContactPhone());
            ps.setString(3, s.getEmail());
            ps.setString(4, s.getAddress());
            ps.setString(5, s.getCity());
            ps.setString(6, s.getStatus() != null ? s.getStatus() : "active");
            ps.setInt(7, s.getSupplierId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean Delete(int id) {
        String sql = "DELETE FROM Supplier WHERE supplier_id = ?";
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public int GetCurrentID() {
        String sql = "SELECT TOP 1 supplier_id FROM Supplier ORDER BY supplier_id DESC";
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("supplier_id");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    public void ReseedSQL() {
        try (Connection con = DBUtils.getConnection();
             PreparedStatement ps = con.prepareStatement("DBCC CHECKIDENT ('Supplier', RESEED, " + GetCurrentID() + ")")) {
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
