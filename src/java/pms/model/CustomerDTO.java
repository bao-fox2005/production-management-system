/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package pms.model;

/**
 *
 * @author HP
 */
public class CustomerDTO {
    private int customer_id;
    private String customer_name;
    private String phone;
    private String email;

    // Constructor rỗng
    public CustomerDTO() {
    }

    // Constructor đầy đủ
    public CustomerDTO(int customer_id, String customer_name, String phone, String email) {
        this.customer_id = customer_id;
        this.customer_name = customer_name;
        this.phone = phone;
        this.email = email;
    }

    // Getter và Setter
    public int getCustomer_id() {
        return customer_id;
    }

    public void setCustomer_id(int customer_id) {
        this.customer_id = customer_id;
    }

    public String getCustomer_name() {
        return customer_name;
    }

    public void setCustomer_name(String customer_name) {
        this.customer_name = customer_name;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
