-- ============================================================
-- DATABASE SETUP: FACTORYERD
-- Production Management System (PMS)
-- ============================================================
-- Hướng dẫn chạy:
--   1. Mở SQL Server Management Studio (SSMS)
--   2. Kết nối tới: localhost, user SA, pass 12345
--   3. Chạy toàn bộ file này (F5)
--   4. Sau đó chạy data.sql để nạp dữ liệu mẫu
-- ============================================================

USE master;
GO

-- Xóa database cũ nếu tồn tại (để tạo lại sạch)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'FactoryERD')
    DROP DATABASE FactoryERD;
GO

CREATE DATABASE FactoryERD;
GO

USE FactoryERD;
GO

-- ============================================================
-- PHẦN 1: BẢNG DANH MỤC (không có khóa ngoại)
-- ============================================================

-- [Users] Quản lý tài khoản đăng nhập
--   role: 'admin' (quản trị) | 'employee' (công nhân/nhân viên)
--   status: 'active' (đang dùng) | 'inactive' (bị khóa)
--   password_hash: lưu mật khẩu plain-text (chưa mã hóa)
CREATE TABLE Users (
    user_id        INT PRIMARY KEY IDENTITY(1,1),
    username       VARCHAR(50)       NOT NULL UNIQUE,
    password_hash  VARCHAR(255)      NOT NULL,
    role           VARCHAR(20)       CHECK (role IN ('admin', 'employee')),
    full_name      NVARCHAR(100),
    email          VARCHAR(100),
    phone          VARCHAR(20),
    status         VARCHAR(20)       DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_date   DATETIME          DEFAULT GETDATE()
);

-- [Item] Quản lý vật phẩm: sản phẩm đầu ra và nguyên vật liệu đầu vào
--   item_type: 'SanPham' (thành phẩm/bán thành phẩm) | 'VatTu' (nguyên liệu)
--   stock_quantity: số lượng tồn kho hiện tại
--   min_stock_level: ngưỡng tồn kho tối thiểu – cảnh báo khi xuống dưới mức này
--   image_base64: ảnh đại diện lưu dưới dạng Base64 (không lưu file vật lý)
CREATE TABLE Item (
    item_id          INT PRIMARY KEY IDENTITY(1,1),
    item_name        NVARCHAR(100)    NOT NULL,
    item_type        VARCHAR(20)      CHECK (item_type IN ('SanPham', 'VatTu')),
    stock_quantity   INT              DEFAULT 0,
    unit             NVARCHAR(20),
    description      NVARCHAR(500),
    min_stock_level  INT              DEFAULT 0,
    image_base64     VARCHAR(MAX)
);

-- [Supplier] Nhà cung cấp nguyên vật liệu
--   status: 'active' | 'inactive'
CREATE TABLE Supplier (
    supplier_id    INT PRIMARY KEY IDENTITY(1,1),
    supplier_name  NVARCHAR(100)  NOT NULL,
    contact_phone  VARCHAR(15),
    email          VARCHAR(100),
    address        NVARCHAR(200),
    city           NVARCHAR(50),
    status         VARCHAR(20)    DEFAULT 'active' CHECK (status IN ('active', 'inactive'))
);

-- [Customer] Khách hàng đặt mua sản phẩm
--   Được gắn với Bill khi chốt đơn hàng
CREATE TABLE Customer (
    customer_id    INT PRIMARY KEY IDENTITY(1,1),
    customer_name  NVARCHAR(100)  NOT NULL,
    phone          VARCHAR(15),
    email          VARCHAR(50),
    address        NVARCHAR(200),
    city           NVARCHAR(50),
    status         VARCHAR(20)    DEFAULT 'active' CHECK (status IN ('active', 'inactive'))
);

-- [Defect_Reason] Danh mục nguyên nhân lỗi trong sản xuất
--   Dùng trong Production_Log để ghi nhận lỗi tại từng công đoạn
CREATE TABLE Defect_Reason (
    defect_id    INT PRIMARY KEY IDENTITY(1,1),
    reason_name  NVARCHAR(255) NOT NULL
);

-- [Routing] Quy trình sản xuất tổng thể
--   Mỗi Routing gồm nhiều Routing_Step (công đoạn theo thứ tự)
--   status: 'active' | 'inactive'
CREATE TABLE Routing (
    routing_id    INT PRIMARY KEY IDENTITY(1,1),
    routing_name  NVARCHAR(100)  NOT NULL,
    description   NVARCHAR(500),
    status        VARCHAR(20)    DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_date  DATETIME       DEFAULT GETDATE()
);

-- [Tenant] Hỗ trợ multi-tenant: mỗi tenant là một cơ sở/chi nhánh sử dụng hệ thống
--   tenant_code: mã định danh duy nhất (dùng làm key tra cứu connection pool)
--   db_host/db_name/db_user/db_password: thông tin kết nối DB riêng của tenant
--   smtp_host/smtp_user: cấu hình email của tenant
--   subscription_plan: gói đăng ký (trial, basic, pro)
--   active: 1 = đang hoạt động, 0 = tạm ngưng
--   expiration_date: ngày hết hạn gói đăng ký
CREATE TABLE Tenant (
    tenant_id           INT PRIMARY KEY IDENTITY(1,1),
    tenant_code         VARCHAR(50)     NOT NULL UNIQUE,
    tenant_name         NVARCHAR(150)   NOT NULL,
    db_host             VARCHAR(100),
    db_name             VARCHAR(100),
    db_user             VARCHAR(100),
    db_password         VARCHAR(200),
    smtp_host           VARCHAR(100),
    smtp_user           VARCHAR(100),
    contact_email       VARCHAR(100),
    contact_phone       VARCHAR(20),
    address             NVARCHAR(300),
    subscription_plan   VARCHAR(50)     DEFAULT 'trial',
    expiration_date     DATE,
    active              BIT             DEFAULT 1,
    created_date        DATE            DEFAULT GETDATE(),
    notes               NVARCHAR(500)
);

-- ============================================================
-- PHẦN 2: BẢNG GIAO DỊCH (có khóa ngoại)
-- ============================================================

-- [Routing_Step] Công đoạn chi tiết trong một quy trình sản xuất
--   estimated_time: thời gian ước tính hoàn thành (phút/công đoạn)
--   is_inspected: 0 = bình thường, 1 = cần kiểm tra chất lượng (QC) tại bước này
CREATE TABLE Routing_Step (
    step_id         INT PRIMARY KEY IDENTITY(1,1),
    routing_id      INT,
    step_name       NVARCHAR(100)  NOT NULL,
    estimated_time  INT,
    is_inspected    BIT            DEFAULT 0,
    FOREIGN KEY (routing_id) REFERENCES Routing(routing_id)
);

-- [Purchase_Order] Đề nghị mua vật tư khi tồn kho xuống thấp
--   status: 'Pending' (chờ duyệt) | 'Approved' (đã duyệt) | 'Rejected' (từ chối)
CREATE TABLE Purchase_Order (
    po_id              INT PRIMARY KEY IDENTITY(1,1),
    item_id            INT,
    supplier_id        INT,
    required_quantity  INT,
    alert_date         DATE            DEFAULT GETDATE(),
    status             VARCHAR(20)     DEFAULT 'Pending',
    notes              NVARCHAR(500),
    FOREIGN KEY (item_id)      REFERENCES Item(item_id),
    FOREIGN KEY (supplier_id)  REFERENCES Supplier(supplier_id)
);

-- [BOM] Định mức nguyên vật liệu (Bill of Materials) – header
--   Mỗi BOM gắn với một sản phẩm và có phiên bản (vd: v1.0, v2.0)
--   status: 'active' (đang dùng) | 'inactive' (ngừng dùng) | 'pending' (chờ duyệt)
CREATE TABLE BOM (
    bom_id           INT PRIMARY KEY IDENTITY(1,1),
    product_item_id  INT,
    bom_version      VARCHAR(20),
    status           VARCHAR(20)   DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    created_date     DATETIME      DEFAULT GETDATE(),
    notes            NVARCHAR(500),
    FOREIGN KEY (product_item_id) REFERENCES Item(item_id)
);

-- [BOM_Detail] Chi tiết nguyên liệu của mỗi BOM
--   Mỗi dòng = 1 nguyên liệu cần thiết để sản xuất sản phẩm trong BOM cha
--   quantity_required: số lượng cần cho 1 đơn vị sản phẩm
--   waste_percent: tỷ lệ hao hụt (%) – dùng để tính nguyên liệu thực tế cần mua
CREATE TABLE BOM_Detail (
    bom_detail_id     INT PRIMARY KEY IDENTITY(1,1),
    bom_id            INT,
    material_item_id  INT,
    quantity_required DECIMAL(10,2),
    unit              NVARCHAR(20),
    waste_percent     DECIMAL(5,2)  DEFAULT 0,
    notes             NVARCHAR(200),
    FOREIGN KEY (bom_id)            REFERENCES BOM(bom_id),
    FOREIGN KEY (material_item_id)  REFERENCES Item(item_id)
);

-- [Work_Order] Lệnh sản xuất – yêu cầu sản xuất một lô hàng
--   status: 'New' → 'InProgress' → 'Done' | 'Cancelled'
--   start_date / due_date: kế hoạch; completed_date: thực tế hoàn thành
CREATE TABLE Work_Order (
    wo_id              INT PRIMARY KEY IDENTITY(1,1),
    product_item_id    INT,
    routing_id         INT,
    order_quantity     INT,
    status             VARCHAR(20)   DEFAULT 'New'
                           CHECK (status IN ('New', 'InProgress', 'Done', 'Cancelled')),
    start_date         DATE,
    due_date           DATE,
    completed_date     DATE,
    notes              NVARCHAR(500),
    FOREIGN KEY (product_item_id)  REFERENCES Item(item_id),
    FOREIGN KEY (routing_id)       REFERENCES Routing(routing_id)
);

-- [Production_Log] Nhật ký sản xuất từng công đoạn của từng lệnh sản xuất
--   produced_quantity: số lượng đã sản xuất trong ca/ngày
--   defect_id: NULL nếu không có lỗi, có giá trị nếu phát hiện lỗi
CREATE TABLE Production_Log (
    log_id             INT PRIMARY KEY IDENTITY(1,1),
    wo_id              INT,
    step_id            INT,
    worker_user_id     INT,
    produced_quantity  INT,
    defect_id          INT  NULL,
    log_date           DATE DEFAULT GETDATE(),
    FOREIGN KEY (wo_id)           REFERENCES Work_Order(wo_id),
    FOREIGN KEY (step_id)         REFERENCES Routing_Step(step_id),
    FOREIGN KEY (worker_user_id)  REFERENCES Users(user_id),
    FOREIGN KEY (defect_id)       REFERENCES Defect_Reason(defect_id)
);

-- [QC_Inspection] Phiếu kiểm tra chất lượng (Quality Control)
--   QcInspectionDAO tự tạo bảng này nếu chưa tồn tại (fail-safe)
--   inspection_result: 'PASS' | 'FAIL' | 'PARTIAL'
--   quantity_failed = quantity_inspected - quantity_passed (tính tự động ở DAO)
CREATE TABLE QC_Inspection (
    inspection_id       INT PRIMARY KEY IDENTITY(1,1),
    wo_id               INT            NOT NULL,
    step_id             INT            NOT NULL,
    inspector_user_id   INT            NOT NULL,
    inspection_result   VARCHAR(20)    NOT NULL,
    quantity_inspected  INT            NOT NULL DEFAULT 0,
    quantity_passed     INT            NOT NULL DEFAULT 0,
    quantity_failed     INT            NOT NULL DEFAULT 0,
    notes               NVARCHAR(500)  NULL,
    inspection_date     DATETIME       NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (wo_id)              REFERENCES Work_Order(wo_id),
    FOREIGN KEY (step_id)            REFERENCES Routing_Step(step_id),
    FOREIGN KEY (inspector_user_id)  REFERENCES Users(user_id)
);

-- [Bill] Hóa đơn chốt đơn hàng
--   Kết nối lệnh sản xuất với khách hàng đặt hàng
--   total_amount: tổng tiền hóa đơn (VNĐ)
CREATE TABLE Bill (
    bill_id       INT PRIMARY KEY IDENTITY(1,1),
    wo_id         INT,
    customer_id   INT,
    total_amount  DECIMAL(18,2),
    bill_date     DATE DEFAULT GETDATE(),
    FOREIGN KEY (wo_id)        REFERENCES Work_Order(wo_id),
    FOREIGN KEY (customer_id)  REFERENCES Customer(customer_id)
);

-- [Payment] Thanh toán QR/Chuyển khoản cho hóa đơn
--   payment_method: 'QR' | 'BankTransfer' | 'Cash'
--   status: 'PENDING' → 'PAID' | 'EXPIRED' | 'CANCELLED'
--   transaction_id: mã giao dịch từ ngân hàng (sau khi thanh toán)
--   qr_code_data: nội dung mã QR bank (VietQR format)
--   expires_at: thời hạn QR còn hiệu lực
CREATE TABLE Payment (
    payment_id          INT PRIMARY KEY IDENTITY(1,1),
    bill_id             INT             NOT NULL,
    amount              DECIMAL(18,2)   NOT NULL,
    payment_method      VARCHAR(30)     NOT NULL DEFAULT 'QR',
    status              VARCHAR(20)     NOT NULL DEFAULT 'PENDING'
                            CHECK (status IN ('PENDING', 'PAID', 'EXPIRED', 'CANCELLED')),
    transaction_id      VARCHAR(100)    NULL,
    qr_code_data        VARCHAR(MAX)    NULL,
    created_at          DATETIME        NOT NULL DEFAULT GETDATE(),
    expires_at          DATETIME        NULL,
    paid_at             DATETIME        NULL,
    bank_bin            VARCHAR(20)     NULL,
    bank_account        VARCHAR(50)     NULL,
    bank_account_name   NVARCHAR(150)   NULL,
    customer_name       NVARCHAR(150)   NULL,
    customer_email      VARCHAR(100)    NULL,
    FOREIGN KEY (bill_id) REFERENCES Bill(bill_id)
);

-- [InventoryLog] Lịch sử xuất/nhập kho
--   QcInspectionDAO và InventoryLogDAO tự tạo bảng này nếu chưa có
--   change_type: 'IN' (nhập kho) | 'OUT' (xuất kho)
--   quantity_change: số lượng thay đổi (luôn dương; dấu hiệu xác định bởi change_type)
--   reference_type: loại giao dịch gốc gây ra thay đổi (WorkOrder, PurchaseOrder, Manual...)
CREATE TABLE InventoryLog (
    log_id          INT PRIMARY KEY IDENTITY(1,1),
    item_id         INT            NOT NULL,
    change_type     VARCHAR(10)    NOT NULL CHECK (change_type IN ('IN', 'OUT')),
    quantity_change INT            NOT NULL,
    reference_type  NVARCHAR(50),
    reference_id    INT,
    notes           NVARCHAR(300),
    changed_by      INT,
    changed_at      DATETIME       DEFAULT GETDATE(),
    FOREIGN KEY (item_id)    REFERENCES Item(item_id),
    FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

-- [EncryptedFile] File đính kèm được mã hóa bằng mật khẩu
--   stored_name: tên file thực lưu trên disk (được rename để tránh trùng)
--   password_hash: hash của mật khẩu mã hóa file
--   related_table/related_id: liên kết tùy chọn tới bản ghi khác (vd: WorkOrder #5)
CREATE TABLE EncryptedFile (
    file_id           INT PRIMARY KEY IDENTITY(1,1),
    original_name     NVARCHAR(255)  NOT NULL,
    stored_name       VARCHAR(255)   NOT NULL,
    file_extension    VARCHAR(20)    NOT NULL,
    file_size         BIGINT         NOT NULL,
    password_hash     VARCHAR(512)   NOT NULL,
    uploader_id       INT            NULL,
    file_description  NVARCHAR(500),
    related_table     VARCHAR(50),
    related_id        INT            DEFAULT 0,
    uploaded_at       DATETIME       DEFAULT GETDATE(),
    FOREIGN KEY (uploader_id) REFERENCES Users(user_id)
);
