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
-- Dòng "default" tương ứng với tenant_code mà TenantBootstrapListener dùng làm fallback
-- tenant_code "default" không cần đăng ký lại (TenantBootstrapListener hardcode rồi)
-- Chỉ cần dữ liệu ở đây để TenantController hiển thị danh sách
INSERT INTO Tenant (tenant_code, tenant_name, db_host, db_name, db_user, db_password,
                    contact_email, contact_phone, subscription_plan, expiration_date, active, notes)
VALUES
    ('default', N'Xưởng Sản Xuất Chính', 'localhost', 'FactoryERD', 'SA', '12345',
     'admin@factory.vn', '0901000001', 'pro', '2027-12-31', 1,
     N'Tenant mặc định – kết nối database chính FactoryERD');
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
-- ĐÚNG SCHEMA MỚI: INSERT vào bảng BOM trước, lấy bom_id, rồi INSERT BOM_Detail
INSERT INTO BOM (product_item_id, bom_version, status, notes)
VALUES
    (1, 'v1.0', 'active',   N'Công thức cơ bản cho Bàn gỗ văn phòng'),
    (2, 'v1.0', 'active',   N'Công thức cơ bản cho Ghế gỗ văn phòng'),
    (3, 'v1.0', 'inactive', N'Công thức cũ – đã ngừng sử dụng');
GO

-- [BOM_Detail] Chi tiết nguyên liệu cho từng BOM
-- BOM #1 (Bàn gỗ): cần 2 tấm MDF, 20 hộp ốc vít, 0.5 lít keo, 1 lít sơn
INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes)
VALUES
    (1, 4, 2.0,  N'Tấm', 5.0, N'MDF làm mặt bàn + chân bàn; hao hụt 5% do cắt'),
    (1, 5, 1.0,  N'Hộp', 0.0, N'Ốc vít M5 để lắp ráp khung'),
    (1, 7, 0.5,  N'Lít', 0.0, N'Keo PVA dán các mối ghép'),
    (1, 8, 1.0,  N'Lít', 0.0, N'Sơn phủ 2 lớp lót + 1 lớp bóng');

-- BOM #2 (Ghế gỗ): cần 1 tấm MDF, 10 ốc, 0.3 keo, 0.8 sơn
INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes)
VALUES
    (2, 4, 1.0,  N'Tấm', 5.0, N'MDF làm mặt ngồi + tựa lưng'),
    (2, 5, 0.5,  N'Hộp', 0.0, N'Ốc vít M5 lắp ráp khung ghế'),
    (2, 7, 0.3,  N'Lít', 0.0, N'Keo PVA'),
    (2, 8, 0.8,  N'Lít', 0.0, N'Sơn phủ ghế');

-- BOM #3 (Tủ hồ sơ – ngừng dùng): để lại làm lịch sử
INSERT INTO BOM_Detail (bom_id, material_item_id, quantity_required, unit, waste_percent, notes)
VALUES
    (3, 4, 3.0,  N'Tấm', 8.0, N'MDF làm các tấm tủ – hao hụt 8% do cắt phức tạp'),
    (3, 5, 2.0,  N'Hộp', 0.0, N'Ốc vít lắp ráp tủ');
GO

-- [Work_Order] Lệnh sản xuất
INSERT INTO Work_Order (product_item_id, routing_id, order_quantity, status, start_date, due_date, notes)
VALUES
    (1, 1, 10, 'InProgress', '2026-04-01', '2026-04-10', N'Lô sản xuất Bàn gỗ tháng 4 cho khách ABC'),
    (2, 2,  5, 'New',        '2026-04-05', '2026-04-12', N'Sản xuất ghế cho Trường XYZ'),
    (1, 1,  3, 'Done',       '2026-03-01', '2026-03-10', N'Đơn hoàn thành tháng 3 – xuất kho đủ');
GO

-- [Production_Log] Nhật ký sản xuất
-- Công nhân 1 (user_id=2) làm bước Cắt gỗ (step_id=1) cho WO #1
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
-- QC tại bước kiểm tra cuối (step_id=5) của WO #3 (đã Done)
INSERT INTO QC_Inspection (wo_id, step_id, inspector_user_id, inspection_result,
                           quantity_inspected, quantity_passed, quantity_failed, notes)
VALUES
    (3, 5, 4, 'PASS', 3, 3, 0, N'Lô Bàn tháng 3 đạt toàn bộ, xuất kho'),
    (1, 5, 4, 'PARTIAL', 10, 8, 2, N'2 cái Bàn tháng 4 có vết trầy – gửi lại sơn lại');
GO

-- [Bill] Hóa đơn chốt đơn
INSERT INTO Bill (wo_id, customer_id, total_amount, bill_date)
VALUES
    (3, 1, 7500000.00, '2026-03-12'),   -- WO #3 Done → xuất hóa đơn cho khách ABC
    (1, 3, 25000000.00, '2026-04-09');  -- WO #1 đang chạy nhưng đặt cọc trước
GO

-- [Payment] Thanh toán
-- Bill #1: đã thanh toán QR
-- Bill #2: đang chờ thanh toán
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

-- [InventoryLog] Lịch sử xuất/nhập kho
INSERT INTO InventoryLog (item_id, change_type, quantity_change, reference_type, reference_id,
                          notes, changed_by, changed_at)
VALUES
    -- Nhập kho MDF khi mua hàng
    (4, 'IN',  50, 'PurchaseOrder', 1, N'Nhập 50 tấm MDF từ Gỗ An Cường',   1, '2026-03-28 08:00:00'),
    -- Xuất kho MDF cho lệnh sản xuất WO #1
    (4, 'OUT', 20, 'WorkOrder',     1, N'Xuất 20 tấm MDF cho đơn Bàn tháng 4', 2, '2026-04-01 07:30:00'),
    -- Nhập kho ốc vít
    (5, 'IN', 200, 'PurchaseOrder', 2, N'Nhập ốc vít M5 đã được duyệt',      1, '2026-03-30 09:00:00'),
    -- Xuất kho sản phẩm hoàn thành (tăng kho thành phẩm)
    (1, 'IN',   3, 'WorkOrder',     3, N'Hoàn thành WO #3 – nhập 3 Bàn vào kho', 1, '2026-03-10 16:00:00'),
    -- Xuất kho giao khách hàng
    (1, 'OUT',  3, 'Manual',        NULL, N'Giao hàng cho Công ty ABC theo Bill #1', 1, '2026-03-12 10:00:00');
GO

-- ============================================================
-- PHẦN 3: KIỂM TRA DỮ LIỆU ĐÃ INSERT
-- Chạy các lệnh này để xác nhận dữ liệu hợp lệ
-- ============================================================
SELECT 'Users'          AS TableName, COUNT(*) AS RowCount FROM Users          UNION ALL
SELECT 'Item',                         COUNT(*)             FROM Item           UNION ALL
SELECT 'Supplier',                     COUNT(*)             FROM Supplier       UNION ALL
SELECT 'Customer',                     COUNT(*)             FROM Customer       UNION ALL
SELECT 'Defect_Reason',                COUNT(*)             FROM Defect_Reason  UNION ALL
SELECT 'Routing',                      COUNT(*)             FROM Routing        UNION ALL
SELECT 'Routing_Step',                 COUNT(*)             FROM Routing_Step   UNION ALL
SELECT 'Tenant',                       COUNT(*)             FROM Tenant         UNION ALL
SELECT 'Purchase_Order',               COUNT(*)             FROM Purchase_Order UNION ALL
SELECT 'BOM',                          COUNT(*)             FROM BOM            UNION ALL
SELECT 'BOM_Detail',                   COUNT(*)             FROM BOM_Detail     UNION ALL
SELECT 'Work_Order',                   COUNT(*)             FROM Work_Order     UNION ALL
SELECT 'Production_Log',               COUNT(*)             FROM Production_Log UNION ALL
SELECT 'QC_Inspection',                COUNT(*)             FROM QC_Inspection  UNION ALL
SELECT 'Bill',                         COUNT(*)             FROM Bill           UNION ALL
SELECT 'Payment',                      COUNT(*)             FROM Payment        UNION ALL
SELECT 'InventoryLog',                 COUNT(*)             FROM InventoryLog;
GO