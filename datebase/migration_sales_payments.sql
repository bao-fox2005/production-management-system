USE FactoryERD;
GO

/* ============================================================
   Migration: Sales & Payments (Billing - Customer - Payment)
   - Add Bill lifecycle columns/status
   - Add Work_Order status ChoSX
   - Create Bill_Line for quote details
   - Create SystemConfig if missing
   - Backfill data from Payment
   ============================================================ */

/* ---------- 1) Ensure SystemConfig exists ---------- */
IF OBJECT_ID('dbo.SystemConfig', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SystemConfig (
        config_id     INT IDENTITY(1,1) PRIMARY KEY,
        config_key    VARCHAR(100) NOT NULL UNIQUE,
        config_value  NVARCHAR(1000) NULL,
        description   NVARCHAR(255) NULL,
        updated_at    DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

/* Seed minimum config keys if missing */
IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'SMTP_HOST')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('SMTP_HOST', 'smtp.gmail.com', N'SMTP host');

IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'SMTP_PORT')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('SMTP_PORT', '587', N'SMTP port');

IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'SMTP_USER')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('SMTP_USER', '', N'SMTP user');

IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'SMTP_PASSWORD')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('SMTP_PASSWORD', '', N'SMTP password / app password');

IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'BANK_BIN')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('BANK_BIN', '970406', N'Bank BIN for transfer');

IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'BANK_ACCOUNT')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('BANK_ACCOUNT', '1234567890', N'Bank account number');

IF NOT EXISTS (SELECT 1 FROM dbo.SystemConfig WHERE config_key = 'BANK_ACCOUNT_NAME')
    INSERT INTO dbo.SystemConfig(config_key, config_value, description)
    VALUES ('BANK_ACCOUNT_NAME', N'CONG TY TNHH PMS', N'Bank account name');
GO

/* ---------- 2) Add Bill columns ---------- */
IF COL_LENGTH('dbo.Bill', 'status') IS NULL
BEGIN
    ALTER TABLE dbo.Bill ADD status VARCHAR(20) NOT NULL CONSTRAINT DF_Bill_status DEFAULT 'pending';
END
GO

IF COL_LENGTH('dbo.Bill', 'bill_created_at') IS NULL
BEGIN
    ALTER TABLE dbo.Bill ADD bill_created_at DATETIME NOT NULL CONSTRAINT DF_Bill_bill_created_at DEFAULT GETDATE();
END
GO

IF COL_LENGTH('dbo.Bill', 'confirmed_paid_at') IS NULL
BEGIN
    ALTER TABLE dbo.Bill ADD confirmed_paid_at DATETIME NULL;
END
GO

IF COL_LENGTH('dbo.Bill', 'cancelled_at') IS NULL
BEGIN
    ALTER TABLE dbo.Bill ADD cancelled_at DATETIME NULL;
END
GO

/* Backfill bill_created_at from bill_date where possible */
UPDATE b
SET bill_created_at = ISNULL(CAST(b.bill_date AS DATETIME), GETDATE())
FROM dbo.Bill b
WHERE b.bill_created_at IS NULL;
GO

/* Backfill status from latest Payment if Payment table exists */
IF OBJECT_ID('dbo.Payment', 'U') IS NOT NULL
BEGIN
    ;WITH LatestPayment AS (
        SELECT
            p.bill_id,
            p.status,
            p.paid_at,
            ROW_NUMBER() OVER (PARTITION BY p.bill_id ORDER BY p.created_at DESC, p.payment_id DESC) AS rn
        FROM dbo.Payment p
    )
    UPDATE b
    SET
        b.status = CASE
            WHEN lp.status = 'PAID' THEN 'paid'
            WHEN lp.status = 'CANCELLED' THEN 'cancelled'
            WHEN lp.status = 'EXPIRED' THEN 'cancelled'
            ELSE 'pending'
        END,
        b.confirmed_paid_at = CASE WHEN lp.status = 'PAID' THEN lp.paid_at ELSE b.confirmed_paid_at END,
        b.cancelled_at = CASE WHEN lp.status IN ('CANCELLED', 'EXPIRED') THEN ISNULL(b.cancelled_at, GETDATE()) ELSE b.cancelled_at END
    FROM dbo.Bill b
    LEFT JOIN LatestPayment lp ON b.bill_id = lp.bill_id AND lp.rn = 1;
END
GO

/* Normalize Bill.status */
UPDATE dbo.Bill
SET status = CASE
    WHEN LOWER(ISNULL(status, 'pending')) IN ('paid') THEN 'paid'
    WHEN LOWER(ISNULL(status, 'pending')) IN ('cancelled', 'canceled', 'expired') THEN 'cancelled'
    ELSE 'pending'
END;
GO

/* Add/refresh Bill status check constraint */
DECLARE @BillStatusConstraint SYSNAME;
SELECT @BillStatusConstraint = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.default_object_id = dc.object_id
JOIN sys.tables t ON t.object_id = c.object_id
WHERE t.name = 'Bill' AND c.name = 'status';

DECLARE @BillCheckName SYSNAME;
SELECT @BillCheckName = cc.name
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID('dbo.Bill')
  AND cc.definition LIKE '%status%pending%paid%cancelled%';

IF @BillCheckName IS NULL
BEGIN
    ALTER TABLE dbo.Bill WITH NOCHECK
    ADD CONSTRAINT CK_Bill_status_pending_paid_cancelled
    CHECK (status IN ('pending', 'paid', 'cancelled'));
END
GO

/* ---------- 3) Add ChoSX to Work_Order status ---------- */
DECLARE @woConstraint SYSNAME;
SELECT @woConstraint = cc.name
FROM sys.check_constraints cc
JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.name = 'Work_Order' AND cc.definition LIKE '%status%';

IF @woConstraint IS NOT NULL
BEGIN
    EXEC ('ALTER TABLE dbo.Work_Order DROP CONSTRAINT ' + QUOTENAME(@woConstraint));
END
GO

ALTER TABLE dbo.Work_Order WITH NOCHECK
ADD CONSTRAINT CK_Work_Order_status
CHECK (status IN ('New', 'ChoSX', 'InProgress', 'Done', 'Cancelled'));
GO

/* ---------- 4) Create Bill_Line table ---------- */
IF OBJECT_ID('dbo.Bill_Line', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bill_Line (
        line_id        INT IDENTITY(1,1) PRIMARY KEY,
        bill_id        INT NOT NULL,
        item_type      NVARCHAR(100) NOT NULL,
        quantity       INT NOT NULL,
        unit_price     DECIMAL(18,2) NOT NULL,
        line_total     DECIMAL(18,2) NOT NULL,
        created_at     DATETIME NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (bill_id) REFERENCES dbo.Bill(bill_id)
    );
END
GO

/* ---------- 5) Performance indexes ---------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Bill_Status_CreatedAt' AND object_id = OBJECT_ID('dbo.Bill'))
BEGIN
    CREATE INDEX IX_Bill_Status_CreatedAt ON dbo.Bill(status, bill_created_at DESC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BillLine_BillId' AND object_id = OBJECT_ID('dbo.Bill_Line'))
BEGIN
    CREATE INDEX IX_BillLine_BillId ON dbo.Bill_Line(bill_id);
END
GO

PRINT 'Migration sales_payments completed.';
