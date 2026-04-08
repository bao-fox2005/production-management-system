/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package pms.model;

import java.sql.Date;

/**
 *
 * @author HP
 */
public class BillDTO {
    private int bill_id;
    private int wo_id;
    private int customer_id;
    private double total_amount;
    private Date bill_date;
    private String status = "pending"; // default status
    
    public BillDTO() {
    }

    public BillDTO(int bill_id, int wo_id, int customer_id, double total_amount, Date bill_date) {
        this.bill_id = bill_id;
        this.wo_id = wo_id;
        this.customer_id = customer_id;
        this.total_amount = total_amount;
        this.bill_date = bill_date;
        this.status = "pending";
    }

    public BillDTO(int bill_id, int wo_id, int customer_id, double total_amount, Date bill_date, String status) {
        this.bill_id = bill_id;
        this.wo_id = wo_id;
        this.customer_id = customer_id;
        this.total_amount = total_amount;
        this.bill_date = bill_date;
        this.status = status != null ? status : "pending";
    }

    public int getBill_id() {
        return bill_id;
    }

    public void setBill_id(int bill_id) {
        this.bill_id = bill_id;
    }

    public int getWo_id() {
        return wo_id;
    }

    public void setWo_id(int wo_id) {
        this.wo_id = wo_id;
    }

    public int getCustomer_id() {
        return customer_id;
    }

    public void setCustomer_id(int customer_id) {
        this.customer_id = customer_id;
    }

    public double getTotal_amount() {
        return total_amount;
    }

    public void setTotal_amount(double total_amount) {
        this.total_amount = total_amount;
    }

    public Date getBill_date() {
        return bill_date;
    }

    public void setBill_date(Date bill_date) {
        this.bill_date = bill_date;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status != null ? status : "pending";
    }
    
    
}
