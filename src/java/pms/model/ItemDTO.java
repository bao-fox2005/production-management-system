package pms.model;

public class ItemDTO {

    private int itemID;
    private String itemName;
    private String itemType;
    private int stockQuantity;
    private String unit;
    private String description;
    private int minStockLevel;
    private String imageBase64;

    public ItemDTO() {
    }

    public ItemDTO(int itemID, String itemName, String itemType, int stockQuantity, String unit, String description, int minStockLevel, String imageBase64) {
        this.itemID = itemID;
        this.itemName = itemName;
        this.itemType = itemType;
        this.stockQuantity = stockQuantity;
        this.unit = unit;
        this.description = description;
        this.minStockLevel = minStockLevel;
        this.imageBase64 = imageBase64;
    }

    public int getItemID() {
        return itemID;
    }

    public void setItemID(int itemID) {
        this.itemID = itemID;
    }

    public String getItemName() {
        return itemName;
    }

    public void setItemName(String itemName) {
        this.itemName = itemName;
    }

    public String getItemType() {
        return itemType;
    }

    public void setItemType(String itemType) {
        this.itemType = itemType;
    }

    public int getStockQuantity() {
        return stockQuantity;
    }

    public void setStockQuantity(int stockQuantity) {
        this.stockQuantity = stockQuantity;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public int getMinStockLevel() {
        return minStockLevel;
    }

    public void setMinStockLevel(int minStockLevel) {
        this.minStockLevel = minStockLevel;
    }

    public String getImageBase64() {
        return imageBase64;
    }

    public void setImageBase64(String imageBase64) {
        this.imageBase64 = imageBase64;
    }

    public boolean isLowStock() {
        return stockQuantity <= minStockLevel;
    }

    public boolean isProduct() {
        return "SanPham".equals(itemType);
    }

    public boolean isMaterial() {
        return "VatTu".equals(itemType);
    }
}
