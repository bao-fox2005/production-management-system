package pms.model;

import java.sql.Date;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class BillDTO {
    private int bill_id;
    private int wo_id;
    private int customer_id;
    private double total_amount;
    private Date bill_date;
    private String status = "pending";
    private Timestamp bill_created_at;
    private Timestamp confirmed_paid_at;
    private Timestamp cancelled_at;
    private List<BillLineDTO> quoteLines;

    public BillDTO() {
        this.quoteLines = new ArrayList<>();
    }

    public BillDTO(int bill_id, int wo_id, int customer_id, double total_amount, Date bill_date) {
        this();
        this.bill_id = bill_id;
        this.wo_id = wo_id;
        this.customer_id = customer_id;
        this.total_amount = total_amount;
        this.bill_date = bill_date;
        this.status = "pending";
    }

    public BillDTO(int bill_id, int wo_id, int customer_id, double total_amount, Date bill_date, String status) {
        this();
        this.bill_id = bill_id;
        this.wo_id = wo_id;
        this.customer_id = customer_id;
        this.total_amount = total_amount;
        this.bill_date = bill_date;
        this.status = status != null ? status : "pending";
    }

    public BillDTO(int bill_id, int wo_id, int customer_id, double total_amount, Date bill_date,
                   String status, Timestamp bill_created_at, Timestamp confirmed_paid_at, Timestamp cancelled_at) {
        this();
        this.bill_id = bill_id;
        this.wo_id = wo_id;
        this.customer_id = customer_id;
        this.total_amount = total_amount;
        this.bill_date = bill_date;
        this.status = status != null ? status : "pending";
        this.bill_created_at = bill_created_at;
        this.confirmed_paid_at = confirmed_paid_at;
        this.cancelled_at = cancelled_at;
    }

    public BillDTO(int bill_id, int wo_id, int customer_id, double total_amount, Date bill_date,
                   String status, Timestamp bill_created_at, Timestamp confirmed_paid_at,
                   Timestamp cancelled_at, List<BillLineDTO> quoteLines) {
        this(bill_id, wo_id, customer_id, total_amount, bill_date, status, bill_created_at, confirmed_paid_at, cancelled_at);
        this.quoteLines = quoteLines != null ? quoteLines : new ArrayList<>();
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

    public Timestamp getBill_created_at() {
        return bill_created_at;
    }

    public void setBill_created_at(Timestamp bill_created_at) {
        this.bill_created_at = bill_created_at;
    }

    public Timestamp getConfirmed_paid_at() {
        return confirmed_paid_at;
    }

    public void setConfirmed_paid_at(Timestamp confirmed_paid_at) {
        this.confirmed_paid_at = confirmed_paid_at;
    }

    public Timestamp getCancelled_at() {
        return cancelled_at;
    }

    public void setCancelled_at(Timestamp cancelled_at) {
        this.cancelled_at = cancelled_at;
    }

    public List<BillLineDTO> getQuoteLines() {
        if (quoteLines == null) {
            quoteLines = new ArrayList<>();
        }
        return quoteLines;
    }

    public void setQuoteLines(List<BillLineDTO> quoteLines) {
        this.quoteLines = quoteLines;
    }
}
