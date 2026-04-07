package pms.model;

public class SupplierDTO {

    private int supplierId;
    private String supplierName;
    private String contactPhone;
    private String email;
    private String address;
    private String city;
    private String status;

    public SupplierDTO() {
    }

    public SupplierDTO(int supplierId, String supplierName, String contactPhone) {
        this.supplierId = supplierId;
        this.supplierName = supplierName;
        this.contactPhone = contactPhone;
    }

    public int getSupplierId() { return supplierId; }
    public void setSupplierId(int supplierId) { this.supplierId = supplierId; }

    public String getSupplierName() { return supplierName; }
    public void setSupplierName(String supplierName) { this.supplierName = supplierName; }

    public String getContactPhone() { return contactPhone; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
