-- ============================================================
-- FIX: Cập nhật CHECK constraint cho cột status của Work_Order
-- ============================================================
-- Vấn đề: Constraint cũ có thể không bao gồm 'Ready', 'InProgress'
--          → lỗi khi checkMaterials hoặc startProduction
-- Cách chạy: Mở SSMS → kết nối localhost/SA → chạy file này (F5)
-- ============================================================

USE FactoryERD;
GO

-- Bước 1: Tìm và xóa TẤT CẢ CHECK constraint trên cột status của Work_Order
-- (SQL Server tự đặt tên constraint kiểu CK__Work_Orde__statu__XXXXXXXX)
DECLARE @constraintName NVARCHAR(256);

DECLARE cur CURSOR FOR
    SELECT cc.name
    FROM sys.check_constraints cc
    INNER JOIN sys.columns c 
        ON cc.parent_object_id = c.object_id 
        AND cc.parent_column_id = c.column_id
    WHERE cc.parent_object_id = OBJECT_ID('Work_Order')
      AND c.name = 'status';

OPEN cur;
FETCH NEXT FROM cur INTO @constraintName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'Đang xóa constraint: ' + @constraintName;
    EXEC('ALTER TABLE Work_Order DROP CONSTRAINT [' + @constraintName + ']');
    FETCH NEXT FROM cur INTO @constraintName;
END

CLOSE cur;
DEALLOCATE cur;
GO

-- Bước 2: Sửa các dòng Work_Order có status không hợp lệ (nếu có)
UPDATE Work_Order SET status = 'New' WHERE status = 'WaitMaterial';
UPDATE Work_Order SET status = 'InProgress' WHERE status = 'In Progress';
GO

-- Bước 3: Thêm CHECK constraint mới với đầy đủ các trạng thái hợp lệ
ALTER TABLE Work_Order
    ADD CONSTRAINT CK_WorkOrder_Status
    CHECK (status IN ('New', 'Ready', 'InProgress', 'Done', 'Cancelled'));
GO

PRINT N'✅ Đã cập nhật CHECK constraint thành công!';
PRINT N'   Các status hợp lệ: New, Ready, InProgress, Done, Cancelled';
GO
