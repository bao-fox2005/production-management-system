/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package pms.model;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import pms.utils.DBUtils;

/**
 *
 * @author HP
 */
public class CustomerDAO {

    private String lastError;

    public String getLastError() {
        return lastError;
    }

    private void clearLastError() {
        lastError = null;
    }

    private void setLastError(Exception e) {
        if (e == null) {
            lastError = null;
            return;
        }
        String message = e.getMessage();
        lastError = (message == null || message.trim().isEmpty()) ? e.getClass().getSimpleName() : message;
    }

    public List<CustomerDTO> getAllCustomers() {
        clearLastError();
        List<CustomerDTO> list = new ArrayList<>();
        try {
            Connection conn = DBUtils.getConnection();
            String sql = "SELECT * FROM Customer";
            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                CustomerDTO c = new CustomerDTO(
                        rs.getInt("customer_id"),
                        rs.getString("customer_name"),
                        rs.getString("phone"),
                        rs.getString("email")
                );
                list.add(c);
            }
        } catch (Exception e) {
            setLastError(e);
            e.printStackTrace();
        }
        return list;
    }

    // Thêm khách hàng
    public boolean insertCustomer(CustomerDTO c) {
        clearLastError();
        try {
            Connection conn = DBUtils.getConnection();
            String sql = "INSERT INTO Customer(customer_name, phone, email) VALUES(?,?,?)";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, c.getCustomer_name());
            ps.setString(2, c.getPhone());
            ps.setString(3, c.getEmail());

            return ps.executeUpdate() > 0;

        } catch (Exception e) {
            setLastError(e);
            e.printStackTrace();
        }

        return false;
    }

    // Cập nhật khách hàng
    public boolean updateCustomer(CustomerDTO c) {
        clearLastError();
        try {
            Connection conn = DBUtils.getConnection();
            String sql = "UPDATE Customer SET customer_name=?, phone=?, email=? WHERE customer_id=?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, c.getCustomer_name());
            ps.setString(2, c.getPhone());
            ps.setString(3, c.getEmail());
            ps.setInt(4, c.getCustomer_id());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            setLastError(e);
            e.printStackTrace();
        }
        return false;
    }

    // Xóa khách hàng
    public boolean deleteCustomer(int id) {
        clearLastError();
        try {
            Connection conn = DBUtils.getConnection();
            String sql = "DELETE FROM Customer WHERE customer_id=?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            setLastError(e);
            e.printStackTrace();
        }
        return false;
    }

    private CustomerDTO SearchByColumn(String column, String value) {
        clearLastError();
        try {
            Connection conn = DBUtils.getConnection();
            String sql = "SELECT * FROM Customer WHERE " + column + " = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, value);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return new CustomerDTO(
                        rs.getInt("customer_id"),
                        rs.getString("customer_name"),
                        rs.getString("phone"),
                        rs.getString("email")
                );
            }

        } catch (Exception e) {
            setLastError(e);
            System.out.println(e.getMessage());
        }

        return null;
    }

    public CustomerDTO SearchByCustomerID(String id) {
        return SearchByColumn("customer_id", id);
    }
    
    public CustomerDTO SearchByCustomerName(String id) {
        return SearchByColumn("customer_name", id);
    }

    public List<CustomerDTO> searchCustomers(String keyword) {
        clearLastError();
        List<CustomerDTO> list = new ArrayList<>();
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        if (normalizedKeyword.isEmpty()) {
            return getAllCustomers();
        }

        String sql = "SELECT customer_id, customer_name, phone, email FROM Customer "
                + "WHERE CAST(customer_id AS VARCHAR(20)) LIKE ? "
                + "OR customer_name LIKE ? "
                + "OR phone LIKE ? "
                + "OR email LIKE ? "
                + "ORDER BY customer_id DESC";
        try {
            Connection conn = DBUtils.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql);
            String searchValue = "%" + normalizedKeyword + "%";
            ps.setString(1, searchValue);
            ps.setString(2, searchValue);
            ps.setString(3, searchValue);
            ps.setString(4, searchValue);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(new CustomerDTO(
                        rs.getInt("customer_id"),
                        rs.getString("customer_name"),
                        rs.getString("phone"),
                        rs.getString("email")
                ));
            }
        } catch (Exception e) {
            setLastError(e);
            e.printStackTrace();
        }
        return list;
    }
}
