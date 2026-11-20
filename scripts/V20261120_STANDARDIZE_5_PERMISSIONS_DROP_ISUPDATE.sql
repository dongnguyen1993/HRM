-- ==============================================================================
-- Migration: V20261120_STANDARDIZE_5_PERMISSIONS_DROP_ISUPDATE.sql
-- Mục đích: Chuẩn hóa 5 quyền chính thức (IsSearch, IsCreate, IsSave, IsDelete, IsPrint)
--          Đồng bộ IsUpdate vào IsSave và xóa bỏ cột IsUpdate khỏi SYS_AuthorGroupMapping
-- ==============================================================================

USE [HRM_TEST_DB];
GO

-- 1. Bảo toàn quyền: Đảm bảo nếu bản ghi có IsUpdate = 1 thì IsSave cũng là 1
IF COL_LENGTH('dbo.SYS_AuthorGroupMapping', 'IsUpdate') IS NOT NULL
BEGIN
    UPDATE dbo.SYS_AuthorGroupMapping
    SET IsSave = 1
    WHERE IsUpdate = 1;
    PRINT N'[OK] Đã hợp nhất dữ liệu IsUpdate = 1 sang IsSave = 1.';
END
GO

-- 2. Xóa bỏ Default Constraint của cột IsUpdate (nếu có)
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = name 
FROM sys.default_constraints 
WHERE parent_object_id = OBJECT_ID('dbo.SYS_AuthorGroupMapping') 
  AND parent_column_id = COLUMNPROPERTY(OBJECT_ID('dbo.SYS_AuthorGroupMapping'), 'IsUpdate', 'ColumnId');

IF @ConstraintName IS NOT NULL
BEGIN
    DECLARE @DropConstraintSql NVARCHAR(500) = N'ALTER TABLE dbo.SYS_AuthorGroupMapping DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
    EXEC sp_executesql @DropConstraintSql;
    PRINT N'[OK] Đã xóa Default Constraint: ' + @ConstraintName;
END
GO

-- 3. Xóa bỏ cột IsUpdate khỏi bảng dbo.SYS_AuthorGroupMapping
IF COL_LENGTH('dbo.SYS_AuthorGroupMapping', 'IsUpdate') IS NOT NULL
BEGIN
    ALTER TABLE dbo.SYS_AuthorGroupMapping DROP COLUMN IsUpdate;
    PRINT N'[OK] Đã xóa cột IsUpdate khỏi dbo.SYS_AuthorGroupMapping.';
END
ELSE
BEGIN
    PRINT N'[INFO] Cột IsUpdate không tồn tại trong dbo.SYS_AuthorGroupMapping.';
END
GO

-- 4. Xác nhận cấu trúc cột mới của dbo.SYS_AuthorGroupMapping
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'SYS_AuthorGroupMapping';
GO
