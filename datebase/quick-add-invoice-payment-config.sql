USE FactoryERD;
GO

/*
    Quick migration cho tính năng hóa đơn / thanh toán / SMTP.
    Mục tiêu:
    - Tạo nhanh các bảng còn thiếu: Customer, Bill, Payment, SystemConfig
    - Bổ sung các cột mới cho Payment nếu DB cũ chưa có
    - Seed dữ liệu cấu hình mặc định cho SMTP / ngân hàng / QR

    QUAN TRỌNG:
    - Hệ thống sẽ từ chối bộ giá trị mặc định cũ:
      BANK_BIN = 970406
      BANK_ACCOUNT = 1234567890
      BANK_ACCOUNT_NAME = CONG TY TNHH PMS
    - Hãy sửa 3 biến bên dưới thành tài khoản nhận tiền thật trước khi chạy.

    Chạy an toàn nhiều lần trên SQL Server.
*/

DECLARE @REAL_BANK_BIN           NVARCHAR(50)  = N'YOUR_REAL_BANK_BIN';
DECLARE @REAL_BANK_ACCOUNT       NVARCHAR(100) = N'YOUR_REAL_BANK_ACCOUNT';
DECLARE @REAL_BANK_ACCOUNT_NAME  NVARCHAR(150) = N'YOUR REAL ACCOUNT NAME';
DECLARE @REAL_ADMIN_EMAIL        NVARCHAR(150) = N'';

/* ============================================================
   1) CUSTOMER
   ============================================================ */
IF OBJECT_ID(N'dbo.Customer', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customer (
        customer_id    INT PRIMARY KEY IDENTITY(1,1),
        customer_name  NVARCHAR(100)  NOT NULL,
        phone          VARCHAR(15)    NULL,
        email          VARCHAR(50)    NULL,
        address        NVARCHAR(200)  NULL,
        city           NVARCHAR(50)   NULL,
        status         VARCHAR(20)    DEFAULT 'active' CHECK (status IN ('active', 'inactive'))
    );
END
GO

/* ============================================================
   2) SYSTEMCONFIG
   ============================================================ */
IF OBJECT_ID(N'dbo.SystemConfig', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemConfig (
        config_key    VARCHAR(100)    NOT NULL PRIMARY KEY,
        config_value  NVARCHAR(MAX)   NULL,
        description   NVARCHAR(255)   NULL,
        updated_at    DATETIME        NOT NULL DEFAULT GETDATE()
    );
END
GO

/* Seed config mặc định nếu chưa có */
MERGE dbo.SystemConfig AS target
USING (
    SELECT 'SMTP_HOST' AS config_key, N'smtp.gmail.com' AS config_value, N'SMTP host' AS description
    UNION ALL SELECT 'SMTP_PORT', N'587', N'SMTP port'
    UNION ALL SELECT 'SMTP_USER', N'your-email@gmail.com', N'SMTP username'
    UNION ALL SELECT 'SMTP_PASSWORD', N'your-app-password', N'SMTP password'
    UNION ALL SELECT 'ADMIN_EMAIL', @REAL_ADMIN_EMAIL, N'Admin email nhận thông báo'
    UNION ALL SELECT 'BANK_BIN', @REAL_BANK_BIN, N'Ngân hàng nhận tiền mặc định'
    UNION ALL SELECT 'BANK_ACCOUNT', @REAL_BANK_ACCOUNT, N'Số tài khoản nhận tiền mặc định'
    UNION ALL SELECT 'BANK_ACCOUNT_NAME', @REAL_BANK_ACCOUNT_NAME, N'Tên tài khoản nhận tiền mặc định'
    UNION ALL SELECT 'QR_EXPIRE_MINUTES', N'1440', N'Thời hạn QR (phút)'
    UNION ALL SELECT 'MAX_FILE_SIZE_MB', N'10', N'Giới hạn upload file (MB)'
    UNION ALL SELECT 'AUTO_PAYMENT_CHECK_SECONDS', N'30', N'Chu kỳ kiểm tra thanh toán tự động'
    UNION ALL SELECT 'COMPANY_NAME', N'PMS Company', N'Tên công ty'
    UNION ALL SELECT 'COMPANY_PHONE', N'0123-456-789', N'Số điện thoại công ty'
    UNION ALL SELECT 'COMPANY_ADDRESS', N'123 Duong ABC, Quan 1, TP.HCM', N'Địa chỉ công ty'
    UNION ALL SELECT 'APP_BASE_URL', N'http://localhost:8080/production-management-system', N'Base URL ứng dụng'
    UNION ALL SELECT 'BANK_PRIMARY_BIN', @REAL_BANK_BIN, N'BIN tài khoản nhận tiền chính'
    UNION ALL SELECT 'BANK_PRIMARY_ACCOUNT', @REAL_BANK_ACCOUNT, N'Số tài khoản nhận tiền chính'
    UNION ALL SELECT 'BANK_PRIMARY_ACCOUNT_NAME', @REAL_BANK_ACCOUNT_NAME, N'Tên tài khoản nhận tiền chính'
    UNION ALL SELECT 'BANK_ALT_BIN', N'', N'BIN tài khoản nhận tiền phụ'
    UNION ALL SELECT 'BANK_ALT_ACCOUNT', N'', N'Số tài khoản nhận tiền phụ'
    UNION ALL SELECT 'BANK_ALT_ACCOUNT_NAME', N'', N'Tên tài khoản nhận tiền phụ'
    UNION ALL SELECT 'BANK_PRIMARY_PROFILE', N'PRIMARY', N'Tài khoản đang ưu tiên hiển thị'
    UNION ALL SELECT 'BANK_RECEIVER_ACCOUNTS', N'A1||' + @REAL_BANK_BIN + N'||' + @REAL_BANK_ACCOUNT + N'||' + @REAL_BANK_ACCOUNT_NAME, N'Danh sách tài khoản nhận tiền'
    UNION ALL SELECT 'BANK_ACTIVE_ACCOUNT_ID', N'A1', N'ID tài khoản nhận tiền đang active'
) AS source
ON target.config_key = source.config_key
WHEN NOT MATCHED THEN
    INSERT (config_key, config_value, description)
    VALUES (source.config_key, source.config_value, source.description);
GO

/* Chuẩn hóa config cũ nếu đang để placeholder / rỗng */
UPDATE dbo.SystemConfig
SET config_value = @REAL_BANK_BIN,
    updated_at = GETDATE()
WHERE config_key IN ('BANK_BIN', 'BANK_PRIMARY_BIN')
  AND (
      config_value IS NULL
      OR LTRIM(RTRIM(CAST(config_value AS NVARCHAR(MAX)))) = N''
      OR CAST(config_value AS NVARCHAR(MAX)) = N'970406'
      OR CAST(config_value AS NVARCHAR(MAX)) = N'YOUR_REAL_BANK_BIN'
  );

UPDATE dbo.SystemConfig
SET config_value = @REAL_BANK_ACCOUNT,
    updated_at = GETDATE()
WHERE config_key IN ('BANK_ACCOUNT', 'BANK_PRIMARY_ACCOUNT')
  AND (
      config_value IS NULL
      OR LTRIM(RTRIM(CAST(config_value AS NVARCHAR(MAX)))) = N''
      OR CAST(config_value AS NVARCHAR(MAX)) = N'1234567890'
      OR CAST(config_value AS NVARCHAR(MAX)) = N'YOUR_REAL_BANK_ACCOUNT'
  );

UPDATE dbo.SystemConfig
SET config_value = @REAL_BANK_ACCOUNT_NAME,
    updated_at = GETDATE()
WHERE config_key IN ('BANK_ACCOUNT_NAME', 'BANK_PRIMARY_ACCOUNT_NAME')
  AND (
      config_value IS NULL
      OR LTRIM(RTRIM(CAST(config_value AS NVARCHAR(MAX)))) = N''
      OR CAST(config_value AS NVARCHAR(MAX)) = N'CONG TY TNHH PMS'
      OR CAST(config_value AS NVARCHAR(MAX)) = N'YOUR REAL ACCOUNT NAME'
  );

UPDATE dbo.SystemConfig
SET config_value = N'A1||' + @REAL_BANK_BIN + N'||' + @REAL_BANK_ACCOUNT + N'||' + @REAL_BANK_ACCOUNT_NAME,
    updated_at = GETDATE()
WHERE config_key = 'BANK_RECEIVER_ACCOUNTS'
  AND (
      config_value IS NULL
      OR LTRIM(RTRIM(CAST(config_value AS NVARCHAR(MAX)))) = N''
      OR CAST(config_value AS NVARCHAR(MAX)) NOT LIKE N'%||%||%||%'
      OR CAST(config_value AS NVARCHAR(MAX)) = N'A1||970406||1234567890||CONG TY TNHH PMS'
  );

UPDATE dbo.SystemConfig
SET config_value = N'A1',
    updated_at = GETDATE()
WHERE config_key = 'BANK_ACTIVE_ACCOUNT_ID'
  AND (
      config_value IS NULL
      OR LTRIM(RTRIM(CAST(config_value AS NVARCHAR(MAX)))) = N''
  );

UPDATE dbo.SystemConfig
SET config_value = @REAL_ADMIN_EMAIL,
    updated_at = GETDATE()
WHERE config_key = 'ADMIN_EMAIL'
  AND @REAL_ADMIN_EMAIL IS NOT NULL
  AND LTRIM(RTRIM(@REAL_ADMIN_EMAIL)) <> N''
  AND (
      config_value IS NULL
      OR LTRIM(RTRIM(CAST(config_value AS NVARCHAR(MAX)))) = N''
  );
GO

/* ============================================================
   3) BILL
   ============================================================ */
IF OBJECT_ID(N'dbo.Bill', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bill (
        bill_id       INT PRIMARY KEY IDENTITY(1,1),
        wo_id         INT             NULL,
        customer_id   INT             NULL,
        total_amount  DECIMAL(18,2)   NULL,
        bill_date     DATE            DEFAULT GETDATE()
    );
END
GO

IF OBJECT_ID(N'dbo.Bill', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Work_Order', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = 'FK_Bill_Work_Order'
   )
BEGIN
    ALTER TABLE dbo.Bill
    ADD CONSTRAINT FK_Bill_Work_Order
    FOREIGN KEY (wo_id) REFERENCES dbo.Work_Order(wo_id);
END
GO

IF OBJECT_ID(N'dbo.Bill', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Customer', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = 'FK_Bill_Customer'
   )
BEGIN
    ALTER TABLE dbo.Bill
    ADD CONSTRAINT FK_Bill_Customer
    FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id);
END
GO

/* Bổ sung cột mới cho Bill nếu DB cũ chưa có schema mới */
IF COL_LENGTH('dbo.Bill', 'status') IS NULL
    ALTER TABLE dbo.Bill ADD status VARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.Bill', 'bill_created_at') IS NULL
    ALTER TABLE dbo.Bill ADD bill_created_at DATETIME NULL;
GO
IF COL_LENGTH('dbo.Bill', 'confirmed_paid_at') IS NULL
    ALTER TABLE dbo.Bill ADD confirmed_paid_at DATETIME NULL;
GO
IF COL_LENGTH('dbo.Bill', 'cancelled_at') IS NULL
    ALTER TABLE dbo.Bill ADD cancelled_at DATETIME NULL;
GO

UPDATE dbo.Bill
SET status = 'pending'
WHERE status IS NULL OR LTRIM(RTRIM(status)) = '';
GO

/* ============================================================
   4) BILL_LINE
   ============================================================ */
IF OBJECT_ID(N'dbo.Bill_Line', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bill_Line (
        line_id       INT PRIMARY KEY IDENTITY(1,1),
        bill_id       INT             NOT NULL,
        item_type     NVARCHAR(255)   NOT NULL,
        quantity      INT             NOT NULL,
        unit_price    DECIMAL(18,2)   NOT NULL,
        line_total    DECIMAL(18,2)   NOT NULL,
        created_at    DATETIME        NOT NULL DEFAULT GETDATE()
    );
END
GO

IF OBJECT_ID(N'dbo.Bill_Line', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Bill', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = 'FK_BillLine_Bill'
   )
BEGIN
    ALTER TABLE dbo.Bill_Line
    ADD CONSTRAINT FK_BillLine_Bill
    FOREIGN KEY (bill_id) REFERENCES dbo.Bill(bill_id);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_BillLine_BillId' AND object_id = OBJECT_ID('dbo.Bill_Line')
)
BEGIN
    CREATE INDEX IX_BillLine_BillId ON dbo.Bill_Line(bill_id);
END
GO

/* ============================================================
   5) PAYMENT
   ============================================================ */
IF OBJECT_ID(N'dbo.Payment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payment (
        payment_id          INT PRIMARY KEY IDENTITY(1,1),
        bill_id             INT             NOT NULL,
        amount              DECIMAL(18,2)   NOT NULL,
        payment_method      VARCHAR(30)     NOT NULL DEFAULT 'QR',
        status              VARCHAR(20)     NOT NULL DEFAULT 'PENDING',
        transaction_id      VARCHAR(100)    NULL,
        qr_code_data        VARCHAR(MAX)    NULL,
        created_at          DATETIME        NOT NULL DEFAULT GETDATE(),
        expires_at          DATETIME        NULL,
        paid_at             DATETIME        NULL,
        bank_bin            VARCHAR(20)     NULL,
        bank_account        VARCHAR(50)     NULL,
        bank_account_name   NVARCHAR(150)   NULL,
        customer_name       NVARCHAR(150)   NULL,
        customer_email      VARCHAR(100)    NULL
    );
END
GO

/* Bổ sung cột còn thiếu cho Payment nếu DB cũ đã có bảng nhưng thiếu schema mới */
IF COL_LENGTH('dbo.Payment', 'bill_id') IS NULL
    ALTER TABLE dbo.Payment ADD bill_id INT NULL;
GO
IF COL_LENGTH('dbo.Payment', 'amount') IS NULL
    ALTER TABLE dbo.Payment ADD amount DECIMAL(18,2) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'payment_method') IS NULL
    ALTER TABLE dbo.Payment ADD payment_method VARCHAR(30) NOT NULL DEFAULT 'QR';
GO
IF COL_LENGTH('dbo.Payment', 'status') IS NULL
    ALTER TABLE dbo.Payment ADD status VARCHAR(20) NOT NULL DEFAULT 'PENDING';
GO
IF COL_LENGTH('dbo.Payment', 'transaction_id') IS NULL
    ALTER TABLE dbo.Payment ADD transaction_id VARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'qr_code_data') IS NULL
    ALTER TABLE dbo.Payment ADD qr_code_data VARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'created_at') IS NULL
    ALTER TABLE dbo.Payment ADD created_at DATETIME NOT NULL DEFAULT GETDATE();
GO
IF COL_LENGTH('dbo.Payment', 'expires_at') IS NULL
    ALTER TABLE dbo.Payment ADD expires_at DATETIME NULL;
GO
IF COL_LENGTH('dbo.Payment', 'paid_at') IS NULL
    ALTER TABLE dbo.Payment ADD paid_at DATETIME NULL;
GO
IF COL_LENGTH('dbo.Payment', 'bank_bin') IS NULL
    ALTER TABLE dbo.Payment ADD bank_bin VARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'bank_account') IS NULL
    ALTER TABLE dbo.Payment ADD bank_account VARCHAR(50) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'bank_account_name') IS NULL
    ALTER TABLE dbo.Payment ADD bank_account_name NVARCHAR(150) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'customer_name') IS NULL
    ALTER TABLE dbo.Payment ADD customer_name NVARCHAR(150) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'customer_email') IS NULL
    ALTER TABLE dbo.Payment ADD customer_email VARCHAR(100) NULL;
GO

IF OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Bill', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.foreign_keys
       WHERE name = 'FK_Payment_Bill'
   )
BEGIN
    ALTER TABLE dbo.Payment
    ADD CONSTRAINT FK_Payment_Bill
    FOREIGN KEY (bill_id) REFERENCES dbo.Bill(bill_id);
END
GO

/* Thêm check constraint status nếu chưa có */
IF OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1
       FROM sys.check_constraints
       WHERE name = 'CK_Payment_Status'
   )
BEGIN
    ALTER TABLE dbo.Payment
    ADD CONSTRAINT CK_Payment_Status
    CHECK (status IN ('PENDING', 'PAID', 'EXPIRED', 'CANCELLED'));
END
GO

/* ============================================================
   6) INVENTORY_LOG (schema theo DAO hiện tại)
   ============================================================ */
IF OBJECT_ID(N'dbo.Inventory_Log', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Inventory_Log (
        log_id            INT PRIMARY KEY IDENTITY(1,1),
        item_id           INT            NOT NULL,
        change_type       VARCHAR(10)    NOT NULL,
        quantity_before   INT            NULL,
        quantity_change   INT            NOT NULL,
        quantity_after    INT            NULL,
        reference_type    NVARCHAR(50)   NULL,
        reference_id      INT            NULL,
        reason            NVARCHAR(300)  NULL,
        performed_by      INT            NULL,
        log_date          DATE           NOT NULL DEFAULT GETDATE()
    );
END
GO

IF OBJECT_ID(N'dbo.Inventory_Log', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Item', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InventoryLog_Item'
   )
BEGIN
    ALTER TABLE dbo.Inventory_Log
    ADD CONSTRAINT FK_InventoryLog_Item
    FOREIGN KEY (item_id) REFERENCES dbo.Item(item_id);
END
GO

IF OBJECT_ID(N'dbo.Inventory_Log', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_InventoryLog_User'
   )
BEGIN
    ALTER TABLE dbo.Inventory_Log
    ADD CONSTRAINT FK_InventoryLog_User
    FOREIGN KEY (performed_by) REFERENCES dbo.Users(user_id);
END
GO

/* Nếu DB cũ chỉ có bảng InventoryLog thì copy dữ liệu sang Inventory_Log để code hiện tại đọc được */
IF OBJECT_ID(N'dbo.InventoryLog', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Inventory_Log', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.Inventory_Log (
        item_id, change_type, quantity_before, quantity_change, quantity_after,
        reference_type, reference_id, reason, performed_by, log_date
    )
    SELECT
        src.item_id,
        src.change_type,
        NULL,
        src.quantity_change,
        NULL,
        src.reference_type,
        src.reference_id,
        src.notes,
        src.changed_by,
        CAST(src.changed_at AS DATE)
    FROM dbo.InventoryLog src
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Inventory_Log dest
        WHERE dest.item_id = src.item_id
          AND ISNULL(dest.change_type, '') = ISNULL(src.change_type, '')
          AND ISNULL(dest.quantity_change, 0) = ISNULL(src.quantity_change, 0)
          AND ISNULL(dest.reference_type, '') = ISNULL(src.reference_type, '')
          AND ISNULL(dest.reference_id, 0) = ISNULL(src.reference_id, 0)
          AND ISNULL(dest.performed_by, 0) = ISNULL(src.changed_by, 0)
          AND ISNULL(dest.log_date, '1900-01-01') = CAST(src.changed_at AS DATE)
    );
END
GO

/* ============================================================
   7) INDEX GỢI Ý
   ============================================================ */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Bill_CustomerId' AND object_id = OBJECT_ID('dbo.Bill')
)
BEGIN
    CREATE INDEX IX_Bill_CustomerId ON dbo.Bill(customer_id);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Payment_BillId_Status' AND object_id = OBJECT_ID('dbo.Payment')
)
BEGIN
    CREATE INDEX IX_Payment_BillId_Status ON dbo.Payment(bill_id, status);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_InventoryLog_Item_LogDate' AND object_id = OBJECT_ID('dbo.Inventory_Log')
)
BEGIN
    CREATE INDEX IX_InventoryLog_Item_LogDate ON dbo.Inventory_Log(item_id, log_date);
END
GO

PRINT N'Quick migration cho hóa đơn / thanh toán / SMTP đã chạy xong.';
GO
