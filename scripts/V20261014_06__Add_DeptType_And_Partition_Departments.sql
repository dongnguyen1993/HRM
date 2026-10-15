-- ======================================================================
-- Migration: V20261014_06__Add_DeptType_And_Partition_Departments.sql
-- Description:
--   1. Bổ sung cột DeptType và các cột hậu cần vào bảng Departments
--   2. Phân loại DeptType = 'HR' cho cơ cấu tổ chức nhân sự
--   3. Phân loại DeptType = 'GA' cho các đơn vị/xưởng nhận cơm
-- ======================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

PRINT N'=== 1. BỔ SUNG CỘT DeptType VÀ CỘT HẬU CẦN VÀO BẢNG Departments ===';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'DeptType')
BEGIN
    ALTER TABLE [dbo].[Departments] 
    ADD [DeptType] VARCHAR(20) NOT NULL CONSTRAINT DF_Departments_DeptType DEFAULT 'HR';
    PRINT N'-> Đã thêm cột DeptType vào bảng Departments!';
END
ELSE
BEGIN
    PRINT N'-> Cột DeptType đã tồn tại.';
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'Plant')
BEGIN
    ALTER TABLE [dbo].[Departments] ADD [Plant] NVARCHAR(50) NULL;
    PRINT N'-> Đã thêm cột Plant vào bảng Departments.';
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'Area')
BEGIN
    ALTER TABLE [dbo].[Departments] ADD [Area] NVARCHAR(50) NULL;
    PRINT N'-> Đã thêm cột Area vào bảng Departments.';
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'DefaultRepresentative')
BEGIN
    ALTER TABLE [dbo].[Departments] ADD [DefaultRepresentative] NVARCHAR(100) NULL;
    PRINT N'-> Đã thêm cột DefaultRepresentative vào bảng Departments.';
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'RepresentativePhone')
BEGIN
    ALTER TABLE [dbo].[Departments] ADD [RepresentativePhone] NVARCHAR(50) NULL;
    PRINT N'-> Đã thêm cột RepresentativePhone vào bảng Departments.';
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'DeliveryLocation')
BEGIN
    ALTER TABLE [dbo].[Departments] ADD [DeliveryLocation] NVARCHAR(200) NULL;
    PRINT N'-> Đã thêm cột DeliveryLocation vào bảng Departments.';
END
GO

PRINT N'=== 2. CẬP NHẬT PHÂN LOẠI DEPTTYPE CHO CÁC PHÒNG BAN HIỆN CÓ ===';

-- 2.1 Mặc định toàn bộ là HR
UPDATE [dbo].[Departments]
SET [DeptType] = 'HR'
WHERE [DeptType] IS NULL OR [DeptType] = '';

-- 2.2 Cập nhật các đơn vị nhận cơm/hành chính sang loại GA
DECLARE @DivMealId INT;
SELECT @DivMealId = [DepartmentId] FROM [dbo].[Departments] WHERE [DepartmentCode] = 'DIV_MEAL';

IF @DivMealId IS NOT NULL
BEGIN
    UPDATE [dbo].[Departments]
    SET [DeptType] = 'GA'
    WHERE [DepartmentId] = @DivMealId OR [ParentDepartmentId] = @DivMealId;
    PRINT N'-> Đã chuyển các phòng ban thuộc DIV_MEAL sang DeptType = GA.';
END

-- Đồng bộ chi tiết từ GaDepartments sang Departments
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GaDepartments]') AND type in (N'U'))
BEGIN
    UPDATE d
    SET d.DeptType = 'GA',
        d.Plant = g.Plant,
        d.Area = g.Area,
        d.DefaultRepresentative = g.DefaultRepresentative,
        d.RepresentativePhone = g.RepresentativePhone,
        d.DeliveryLocation = g.DeliveryLocation,
        d.Comment = ISNULL(g.Note, d.Comment),
        d.UseFlag = CASE WHEN g.Status = 'ACTIVE' THEN 1 ELSE 0 END
    FROM [dbo].[Departments] d
    JOIN [dbo].[GaDepartments] g ON d.DepartmentCode = g.DepartmentCode;

    -- Thêm các phòng ban trong GaDepartments chưa có trong Departments (như PBA, LCM)
    INSERT INTO [dbo].[Departments] (
        DepartmentCode, DepartmentName, ParentDepartmentId, Level, SortOrder,
        UseFlag, Comment, Plant, Area, DefaultRepresentative, RepresentativePhone,
        DeliveryLocation, DeptType, CreatedAt, CreatedBy
    )
    SELECT 
        g.DepartmentCode, g.DepartmentName, @DivMealId, 2, g.SortOrder,
        CASE WHEN g.Status = 'ACTIVE' THEN 1 ELSE 0 END, g.Note, g.Plant, g.Area,
        g.DefaultRepresentative, g.RepresentativePhone, g.DeliveryLocation, 'GA', GETDATE(), 'ADMIN'
    FROM [dbo].[GaDepartments] g
    WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Departments] d WHERE d.DepartmentCode = g.DepartmentCode);

    PRINT N'-> Đã đồng bộ toàn bộ 22 phòng ban GA vào bảng Departments.';
END

-- Kiểm tra số lượng phân loại
SELECT DeptType, COUNT(1) AS TotalCount
FROM [dbo].[Departments]
GROUP BY DeptType;
GO
