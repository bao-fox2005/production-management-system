-- ============================================================
-- DỮ LIỆU MẪU: FACTORYERD
-- Production Management System (PMS)
-- ============================================================
-- Hướng dẫn chạy:
--   1. Chạy Table.sql trước để tạo schema
--   2. Chạy file này để nạp dữ liệu mẫu ban đầu
--   3. Đăng nhập hệ thống: admin / 123456
-- ============================================================

USE FactoryERD;
GO

-- ============================================================
-- PHẦN 1: DỮ LIỆU BẢNG DANH MỤC (không có khóa ngoại)
-- Phải INSERT trước vì các bảng giao dịch phụ thuộc vào đây
-- ============================================================

-- [Users] Tài khoản đăng nhập
-- Mật khẩu lưu plain-text (UserDAO.Login dùng so sánh trực tiếp, chưa hash)
INSERT INTO Users (username, password_hash, role, full_name, email, phone, status)
VALUES
    ('admin',     '123456', 'admin',    N'Nguyễn Quản Trị',    'admin@factory.vn',   '0901000001', 'active'),
    ('congnhan1', '123456', 'employee', N'Trần Văn Bình',      'binh@factory.vn',    '0901000002', 'active'),
    ('congnhan2', '123456', 'employee', N'Lê Thị Cẩm',        'cam@factory.vn',     '0901000003', 'active'),
    ('qc1',       '123456', 'employee', N'Phạm Kiểm Tra',     'qc@factory.vn',      '0901000004', 'active');
GO

-- [Item] Vật phẩm: 3 sản phẩm đầu ra + 5 nguyên vật liệu đầu vào
-- min_stock_level: khi stock_quantity xuống dưới mức này → cảnh báo mua hàng
INSERT INTO Item (item_name, item_type, stock_quantity, unit, description, min_stock_level)
VALUES
    -- Sản phẩm đầu ra
    (N'Bàn gỗ văn phòng',  'SanPham',  10, N'Cái', N'Bàn gỗ công nghiệp, kích thước 120x60x75cm', 5),
    (N'Ghế gỗ văn phòng',  'SanPham',  20, N'Cái', N'Ghế gỗ có tựa lưng, chịu tải 120kg',         5),
    (N'Tủ hồ sơ gỗ',       'SanPham',   5, N'Cái', N'Tủ 4 ngăn, khóa số, kích thước 80x40x180cm', 2),
    -- Nguyên vật liệu đầu vào
    (N'Gỗ công nghiệp MDF', 'VatTu',  100, N'Tấm', N'MDF 18mm, kích thước 1220x2440mm',            20),
    (N'Ốc vít M5',          'VatTu',  500, N'Hộp', N'Ốc vít inox M5x20, hộp 100 cái',             100),
    (N'Đinh đóng gỗ',       'VatTu',  200, N'Kg',  N'Đinh thép 50mm',                              50),
    (N'Keo gỗ PVA',         'VatTu',   50, N'Lít', N'Keo dán gỗ PVA, đóng gói 5 lít/can',          10),
    (N'Sơn phủ gỗ',         'VatTu',   30, N'Lít', N'Sơn lót + phủ bóng, màu walnut',               5);
GO

-- [Supplier] Nhà cung cấp
INSERT INTO Supplier (supplier_name, contact_phone, email, address, city, status)
VALUES
    (N'Gỗ An Cường',        '0901234567', 'contact@ancuong.vn',    N'123 Đinh Tiên Hoàng', N'Hồ Chí Minh', 'active'),
    (N'Kim Khí Hòa Phát',   '0987654321', 'info@hoaphat.vn',       N'456 Lê Lợi',          N'Bình Dương',   'active'),
    (N'Sơn Mỹ Phẩm Lâm',   '0912345678', 'lam@sonlam.vn',         N'789 Trần Hưng Đạo',   N'Đồng Nai',     'active');
GO

-- [Customer] Khách hàng
INSERT INTO Customer (customer_name, phone, email, address, city, status)
VALUES
    (N'Công ty TNHH ABC',       '0911111111', 'abc@company.vn',   N'10 Nguyễn Huệ',     N'Hồ Chí Minh', 'active'),
    (N'Trường Đại học XYZ',     '0922222222', 'xyz@edu.vn',       N'1 Đại học',         N'Hà Nội',       'active'),
    (N'Văn Phòng Luật DEF',     '0933333333', 'def@law.vn',       N'55 Pasteur',        N'Hồ Chí Minh', 'active');
GO

-- [Defect_Reason] Nguyên nhân lỗi trong sản xuất
INSERT INTO Defect_Reason (reason_name)
VALUES
    (N'Trầy xước bề mặt'),
    (N'Nứt gỗ do độ ẩm'),
    (N'Thiếu ốc vít'),
    (N'Sơn không đều màu'),
    (N'Keo không dính – mối ghép hở');
GO

-- [Routing] Quy trình sản xuất
INSERT INTO Routing (routing_name, description, status)
VALUES
    (N'Quy trình sản xuất Bàn',  N'5 bước: Cắt → Bào → Lắp ráp → Sơn → Kiểm tra', 'active'),
    (N'Quy trình sản xuất Ghế',  N'4 bước: Cắt → Lắp ráp → Sơn → Kiểm tra',        'active'),
    (N'Quy trình sản xuất Tủ',   N'4 bước: Cắt → Lắp ráp → Sơn → Kiểm tra',        'active');
GO

-- [Tenant] Cấu hình multi-tenant
INSERT INTO Tenant (tenant_code, tenant_name, db_host, db_name, db_user, db_password,
                    contact_email, contact_phone, subscription_plan, expiration_date, active, notes)
VALUES
    ('default', N'Xưởng Sản Xuất Chính', 'localhost', 'FactoryERD', 'SA', '12345',
     'admin@factory.vn', '0901000001', 'pro', '2027-12-31', 1,
     N'Tenant mặc định – kết nối database chính FactoryERD');
GO

-- [SystemConfig] Cấu hình mặc định cho SMTP / QR / tài khoản nhận tiền
INSERT INTO SystemConfig (config_key, config_value, description)
VALUES
    ('SMTP_HOST', N'smtp.gmail.com', N'SMTP host'),
    ('SMTP_PORT', N'587', N'SMTP port'),
    ('SMTP_USER', N'your-email@gmail.com', N'SMTP username'),
    ('SMTP_PASSWORD', N'your-app-password', N'SMTP password'),
    ('ADMIN_EMAIL', N'admin@factory.vn', N'Admin email nhận thông báo'),
    ('BANK_BIN', N'970436', N'Ngân hàng nhận tiền mặc định'),
    ('BANK_ACCOUNT', N'1234567890', N'Số tài khoản nhận tiền mặc định'),
    ('BANK_ACCOUNT_NAME', N'CONG TY TNHH SAN XUAT FACTORY', N'Tên tài khoản nhận tiền mặc định'),
    ('QR_EXPIRE_MINUTES', N'1440', N'Thời hạn QR (phút)'),
    ('MAX_FILE_SIZE_MB', N'10', N'Giới hạn upload file (MB)'),
    ('AUTO_PAYMENT_CHECK_SECONDS', N'30', N'Chu kỳ kiểm tra thanh toán tự động'),
    ('COMPANY_NAME', N'PMS Company', N'Tên công ty'),
    ('COMPANY_PHONE', N'0123-456-789', N'Số điện thoại công ty'),
    ('COMPANY_ADDRESS', N'123 Duong ABC, Quan 1, TP.HCM', N'Địa chỉ công ty'),
    ('APP_BASE_URL', N'http://localhost:8080/production-management-system', N'Base URL ứng dụng'),
    ('BANK_PRIMARY_BIN', N'970436', N'BIN tài khoản nhận tiền chính'),
    ('BANK_PRIMARY_ACCOUNT', N'1234567890', N'Số tài khoản nhận tiền chính'),
    ('BANK_PRIMARY_ACCOUNT_NAME', N'CONG TY TNHH SAN XUAT FACTORY', N'Tên tài khoản nhận tiền chính'),
    ('BANK_ALT_BIN', N'', N'BIN tài khoản nhận tiền phụ'),
    ('BANK_ALT_ACCOUNT', N'', N'Số tài khoản nhận tiền phụ'),
    ('BANK_ALT_ACCOUNT_NAME', N'', N'Tên tài khoản nhận tiền phụ'),
    ('BANK_PRIMARY_PROFILE', N'PRIMARY', N'Tài khoản đang ưu tiên hiển thị'),
    ('BANK_RECEIVER_ACCOUNTS', N'A1||970436||1234567890||CONG TY TNHH SAN XUAT FACTORY', N'Danh sách tài khoản nhận tiền'),
    ('BANK_ACTIVE_ACCOUNT_ID', N'A1', N'ID tài khoản nhận tiền đang active');
GO

-- ============================================================
-- PHẦN 2: DỮ LIỆU BẢNG GIAO DỊCH (có khóa ngoại)
-- INSERT theo thứ tự phụ thuộc: Routing_Step → BOM → Work_Order → ...
-- ============================================================

-- [Routing_Step] Công đoạn chi tiết
-- Routing_id 1 = Quy trình Bàn (5 bước)
INSERT INTO Routing_Step (routing_id, step_name, estimated_time, is_inspected)
VALUES
    (1, N'Cắt gỗ theo kích thước',  30, 0),  -- Không cần QC
    (1, N'Bào và làm nhẵn bề mặt',  20, 0),
    (1, N'Lắp ráp khung bàn',        45, 0),
    (1, N'Sơn phủ bề mặt',           60, 0),
    (1, N'Kiểm tra chất lượng cuối', 15, 1); -- Cần QC tại bước này

-- Routing_id 2 = Quy trình Ghế (4 bước)
INSERT INTO Routing_Step (routing_id, step_name, estimated_time, is_inspected)
VALUES
    (2, N'Cắt gỗ ghế',               25, 0),
    (2, N'Lắp ráp khung ghế',         40, 0),
    (2, N'Sơn phủ ghế',               50, 0),
    (2, N'Kiểm tra chất lượng cuối',  10, 1);

-- Routing_id 3 = Quy trình Tủ (4 bước)
INSERT INTO Routing_Step (routing_id, step_name, estimated_time, is_inspected)
VALUES
    (3, N'Cắt tấm gỗ tủ',            35, 0),
    (3, N'Lắp ráp tủ',                60, 0),
    (3, N'Sơn tủ',                    70, 0),
    (3, N'Kiểm tra và lắp khóa',      20, 1);
GO

-- [Purchase_Order] Đề nghị mua hàng
INSERT INTO Purchase_Order (item_id, supplier_id, required_quantity, status, notes)
VALUES
    (4, 1, 50, 'Pending',  N'Mua gấp MDF cho lô sản xuất tháng 4'),
    (5, 2, 200, 'Approved', N'Đã duyệt – chờ nhà cung cấp giao'),
    (8, 3, 20, 'Pending',  N'Sơn teak màu nâu đậm');
GO

-- [BOM] Định mức nguyên liệu – Header
INSERT INTO BOM (product_item_id, bom_version, status, notes)
VALUES
    (1, 'v1.0', 'active',   N'Công thức cơ bản cho Bàn gỗ văn phòng'),
    (2, 'v1.0', 'active',   N'Công thức cơ bản cho Ghế gỗ văn phòng'),
    (3, 'v1.0', 'inactive', N'Công thức cũ – đã ngừng sử dụng');
GO

-- [BOM_Detail] Chi tiết nguyên liệu cho từng BOM
INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes)
VALUES
    (1, 4, 2.0,  N'Tấm', 5.0, N'MDF làm mặt bàn + chân bàn; hao hụt 5% do cắt'),
    (1, 5, 1.0,  N'Hộp', 0.0, N'Ốc vít M5 để lắp ráp khung'),
    (1, 7, 0.5,  N'Lít', 0.0, N'Keo PVA dán các mối ghép'),
    (1, 8, 1.0,  N'Lít', 0.0, N'Sơn phủ 2 lớp lót + 1 lớp bóng');

INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes)
VALUES
    (2, 4, 1.0,  N'Tấm', 5.0, N'MDF làm mặt ngồi + tựa lưng'),
    (2, 5, 0.5,  N'Hộp', 0.0, N'Ốc vít M5 lắp ráp khung ghế'),
    (2, 7, 0.3,  N'Lít', 0.0, N'Keo PVA'),
    (2, 8, 0.8,  N'Lít', 0.0, N'Sơn phủ ghế');

INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes)
VALUES
    (3, 4, 3.0,  N'Tấm', 8.0, N'MDF làm các tấm tủ – hao hụt 8% do cắt phức tạp'),
    (3, 5, 2.0,  N'Hộp', 0.0, N'Ốc vít lắp ráp tủ');
GO

-- [Work_Order] Lệnh sản xuất
-- Status hợp lệ: New, Ready, InProgress, Done, Cancelled
INSERT INTO Work_Order (product_item_id, routing_id, order_quantity, status, start_date, due_date, notes)
VALUES
    (1, 1, 10, 'InProgress', '2026-04-01', '2026-04-10', N'Lô sản xuất Bàn gỗ tháng 4 cho khách ABC'),
    (2, 2,  5, 'New',        '2026-04-05', '2026-04-12', N'Sản xuất ghế cho Trường XYZ'),
    (1, 1,  3, 'Done',       '2026-03-01', '2026-03-10', N'Đơn hoàn thành tháng 3 – xuất kho đủ');
GO

-- [Production_Log] Nhật ký sản xuất
INSERT INTO Production_Log (wo_id, step_id, worker_user_id, produced_quantity, defect_id, log_date)
VALUES
    (1, 1, 2, 10, NULL,  '2026-04-01'),  -- Cắt gỗ không lỗi
    (1, 2, 2,  9, NULL,  '2026-04-02'),  -- Bào nhẵn: 9/10 cái đạt
    (1, 2, 3,  1, 1,     '2026-04-02'),  -- 1 cái bị trầy xước (defect_id=1)
    (1, 3, 2, 10, NULL,  '2026-04-03'),  -- Lắp ráp xong
    (3, 1, 2,  3, NULL,  '2026-03-01'),  -- WO #3 đã Done
    (3, 2, 3,  3, NULL,  '2026-03-02');
GO

-- [QC_Inspection] Kiểm tra chất lượng
INSERT INTO QC_Inspection (wo_id, step_id, inspector_user_id, inspection_result,
                           quantity_inspected, quantity_passed, quantity_failed, notes)
VALUES
    (3, 5, 4, 'PASS', 3, 3, 0, N'Lô Bàn tháng 3 đạt toàn bộ, xuất kho'),
    (1, 5, 4, 'PARTIAL', 10, 8, 2, N'2 cái Bàn tháng 4 có vết trầy – gửi lại sơn lại');
GO

-- [Bill] Hóa đơn chốt đơn
INSERT INTO Bill (wo_id, customer_id, total_amount, bill_date, status, bill_created_at, confirmed_paid_at, cancelled_at)
VALUES
    (3, 1, 7500000.00, '2026-03-12', 'paid',    '2026-03-12 08:55:00', '2026-03-12 09:07:23', NULL),
    (1, 3, 25000000.00, '2026-04-09', 'pending', '2026-04-09 10:00:00', NULL, NULL);
GO

-- [Bill_Line] Chi tiết hóa đơn
INSERT INTO Bill_Line (bill_id, item_type, quantity, unit_price, line_total, created_at)
VALUES
    (1, N'Bàn gỗ văn phòng', 3, 2500000.00, 7500000.00, '2026-03-12 08:56:00'),
    (2, N'Bàn gỗ văn phòng', 10, 2500000.00, 25000000.00, '2026-04-09 10:01:00');
GO

-- [Payment] Thanh toán
INSERT INTO Payment (bill_id, amount, payment_method, status, transaction_id,
                     created_at, expires_at, paid_at,
                     bank_bin, bank_account, bank_account_name, customer_name)
VALUES
    (1, 7500000.00,  'QR', 'PAID', 'VCB20260312001',
     '2026-03-12 09:00:00', '2026-03-12 09:15:00', '2026-03-12 09:07:23',
     '970436', '1234567890', N'CONG TY TNHH SAN XUAT FACTORY', N'Công ty TNHH ABC'),
    (2, 25000000.00, 'QR', 'PENDING', NULL,
     '2026-04-09 10:00:00', '2026-04-09 10:15:00', NULL,
     '970436', '1234567890', N'CONG TY TNHH SAN XUAT FACTORY', N'Văn Phòng Luật DEF');
GO

-- [Inventory_Log] Lịch sử xuất/nhập kho
-- ★ Tên bảng: Inventory_Log (có dấu gạch dưới, khớp Table.sql)
INSERT INTO Inventory_Log (item_id, change_type, quantity_before, quantity_change, quantity_after,
                           reference_type, reference_id, reason, performed_by, log_date)
VALUES
    (4, 'IN',  50,  50, 100, 'PurchaseOrder', 1, N'Nhập 50 tấm MDF từ Gỗ An Cường', 1, '2026-03-28'),
    (4, 'OUT', 100, 20,  80, 'WorkOrder',     1, N'Xuất 20 tấm MDF cho đơn Bàn tháng 4', 2, '2026-04-01'),
    (5, 'IN',  300, 200, 500, 'PurchaseOrder', 2, N'Nhập ốc vít M5 đã được duyệt', 1, '2026-03-30'),
    (1, 'IN',    7,   3,  10, 'WorkOrder',     3, N'Hoàn thành WO #3 – nhập 3 Bàn vào kho', 1, '2026-03-10'),
    (1, 'OUT',  10,   3,   7, 'Manual',        NULL, N'Giao hàng cho Công ty ABC theo Bill #1', 1, '2026-03-12');
GO

-- ============================================================
-- PHẦN 3: KIỂM TRA DỮ LIỆU ĐÃ INSERT
-- ============================================================
SELECT 'Users'          AS TableName, COUNT(*) AS RowCount FROM Users           UNION ALL
SELECT 'Item',                         COUNT(*)             FROM Item            UNION ALL
SELECT 'Supplier',                     COUNT(*)             FROM Supplier        UNION ALL
SELECT 'Customer',                     COUNT(*)             FROM Customer        UNION ALL
SELECT 'Defect_Reason',                COUNT(*)             FROM Defect_Reason   UNION ALL
SELECT 'Routing',                      COUNT(*)             FROM Routing         UNION ALL
SELECT 'Routing_Step',                 COUNT(*)             FROM Routing_Step    UNION ALL
SELECT 'Tenant',                       COUNT(*)             FROM Tenant          UNION ALL
SELECT 'SystemConfig',                 COUNT(*)             FROM SystemConfig    UNION ALL
SELECT 'Purchase_Order',               COUNT(*)             FROM Purchase_Order  UNION ALL
SELECT 'BOM',                          COUNT(*)             FROM BOM             UNION ALL
SELECT 'BOM_Detail',                   COUNT(*)             FROM BOM_Detail      UNION ALL
SELECT 'Work_Order',                   COUNT(*)             FROM Work_Order      UNION ALL
SELECT 'Production_Log',               COUNT(*)             FROM Production_Log  UNION ALL
SELECT 'QC_Inspection',                COUNT(*)             FROM QC_Inspection   UNION ALL
SELECT 'Bill',                         COUNT(*)             FROM Bill            UNION ALL
SELECT 'Bill_Line',                    COUNT(*)             FROM Bill_Line       UNION ALL
SELECT 'Payment',                      COUNT(*)             FROM Payment         UNION ALL
SELECT 'Inventory_Log',                COUNT(*)             FROM Inventory_Log;
GO