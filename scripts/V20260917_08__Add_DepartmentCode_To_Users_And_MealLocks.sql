-- ==============================================================================
-- SCRIPT: Bổ sung DepartmentCode cho Users và Cờ khóa độc lập từng bữa cho Meal Orders
-- Ngày tạo: 2026-09-17
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;

-- 1. Bổ sung cột DepartmentCode vào bảng Users nếu chưa có
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'DepartmentCode'
)
BEGIN
    ALTER TABLE [dbo].[Users] ADD [DepartmentCode] NVARCHAR(50) NULL;
    PRINT N'-> Đã thêm cột DepartmentCode vào bảng Users!';
END
GO

-- Đồng bộ DepartmentCode từ bảng Departments cho các User đã có DepartmentId
UPDATE u
SET u.DepartmentCode = d.DepartmentCode
FROM [dbo].[Users] u
INNER JOIN [dbo].[Departments] d ON u.DepartmentId = d.DepartmentId
WHERE u.DepartmentCode IS NULL OR u.DepartmentCode = '';
PRINT N'-> Đã đồng bộ DepartmentCode cho các tài khoản người dùng hiện có!';
GO

-- 2. Bổ sung 4 cờ khóa bữa ăn độc lập vào bảng DepartmentMealOrders nếu chưa có
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'DepartmentMealOrders' AND COLUMN_NAME = 'IsLockedDayLunch'
)
BEGIN
    ALTER TABLE [dbo].[DepartmentMealOrders] 
        ADD [IsLockedDayLunch] BIT NOT NULL CONSTRAINT DF_MealOrders_LockedDayLunch DEFAULT 0;
    PRINT N'-> Đã thêm cột IsLockedDayLunch vào DepartmentMealOrders!';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'DepartmentMealOrders' AND COLUMN_NAME = 'IsLockedDayOt'
)
BEGIN
    ALTER TABLE [dbo].[DepartmentMealOrders] 
        ADD [IsLockedDayOt] BIT NOT NULL CONSTRAINT DF_MealOrders_LockedDayOt DEFAULT 0;
    PRINT N'-> Đã thêm cột IsLockedDayOt vào DepartmentMealOrders!';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'DepartmentMealOrders' AND COLUMN_NAME = 'IsLockedNightDinner'
)
BEGIN
    ALTER TABLE [dbo].[DepartmentMealOrders] 
        ADD [IsLockedNightDinner] BIT NOT NULL CONSTRAINT DF_MealOrders_LockedNightDinner DEFAULT 0;
    PRINT N'-> Đã thêm cột IsLockedNightDinner vào DepartmentMealOrders!';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'DepartmentMealOrders' AND COLUMN_NAME = 'IsLockedNightOt'
)
BEGIN
    ALTER TABLE [dbo].[DepartmentMealOrders] 
        ADD [IsLockedNightOt] BIT NOT NULL CONSTRAINT DF_MealOrders_LockedNightOt DEFAULT 0;
    PRINT N'-> Đã thêm cột IsLockedNightOt vào DepartmentMealOrders!';
END
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Đồng bộ trạng thái khóa cho các đơn hiện có (nếu suất ăn > 0 thì đánh dấu đã khóa)
UPDATE [dbo].[DepartmentMealOrders]
SET 
    IsLockedDayLunch = CASE WHEN DayLunchCount > 0 THEN 1 ELSE IsLockedDayLunch END,
    IsLockedDayOt = CASE WHEN DayOtCount > 0 THEN 1 ELSE IsLockedDayOt END,
    IsLockedNightDinner = CASE WHEN NightDinnerCount > 0 THEN 1 ELSE IsLockedNightDinner END,
    IsLockedNightOt = CASE WHEN NightOtCount > 0 THEN 1 ELSE IsLockedNightOt END;

PRINT N'-> Đã cập nhật trạng thái khóa mặc định cho các đơn đặt cơm hiện có!';
PRINT N'=== THÀNH CÔNG: MIGRATION V20260917_08 HOÀN TẤT ===';
GO
