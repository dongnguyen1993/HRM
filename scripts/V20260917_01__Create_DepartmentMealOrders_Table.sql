-- =========================================================================================
-- Migration Script: Tạo bảng DepartmentMealOrders cho Cổng Self-Service nhà máy MES-Hansol
-- Ngày tạo: 2026-09-17
-- Mục đích: Đăng ký Suất ăn Phòng ban theo ngày (Ca ngày, Ca đêm, Suất ăn chay)
-- =========================================================================================

USE [HRM_Enterprise_DB];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Tạo bảng DepartmentMealOrders nếu chưa tồn tại
IF OBJECT_ID('dbo.DepartmentMealOrders', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DepartmentMealOrders] (
        [OrderId]           INT IDENTITY(1,1) NOT NULL,
        [OrderDate]         DATE NOT NULL,
        [DepartmentCode]    VARCHAR(50) NOT NULL,
        [DayLunchCount]     INT NOT NULL CONSTRAINT DF_MealOrders_DayLunch DEFAULT (0),
        [DayOtCount]        INT NOT NULL CONSTRAINT DF_MealOrders_DayOt DEFAULT (0),
        [NightDinnerCount]  INT NOT NULL CONSTRAINT DF_MealOrders_NightDinner DEFAULT (0),
        [NightOtCount]      INT NOT NULL CONSTRAINT DF_MealOrders_NightOt DEFAULT (0),
        [TotalMeals]        AS ([DayLunchCount] + [DayOtCount] + [NightDinnerCount] + [NightOtCount]) PERSISTED,
        [VegetarianCount]   INT NOT NULL CONSTRAINT DF_MealOrders_Vegetarian DEFAULT (0),
        [Note]              NVARCHAR(500) NULL,
        [OrderedBy]         VARCHAR(50) NOT NULL,
        [CreatedAt]         DATETIME NOT NULL CONSTRAINT DF_MealOrders_CreatedAt DEFAULT (GETDATE()),
        [UpdatedAt]         DATETIME NULL,
        [UpdatedBy]         VARCHAR(50) NULL,
        
        -- Khóa chính
        CONSTRAINT [PK_DepartmentMealOrders] PRIMARY KEY CLUSTERED ([OrderId] ASC),
        
        -- Ràng buộc UNIQUE: Mỗi phòng ban chỉ có 1 đơn đặt cơm duy nhất trong 1 ngày
        CONSTRAINT [UQ_MealOrder_Date_Dept] UNIQUE NONCLUSTERED ([OrderDate] ASC, [DepartmentCode] ASC)
    );

    PRINT 'Bảng dbo.DepartmentMealOrders đã được tạo thành công.';
END
ELSE
BEGIN
    PRINT 'Bảng dbo.DepartmentMealOrders đã tồn tại.';
END
GO

-- 2. Tạo chỉ mục tối ưu cho tìm kiếm theo OrderDate và DepartmentCode
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MealOrders_DateDept' AND object_id = OBJECT_ID('dbo.DepartmentMealOrders'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_MealOrders_DateDept]
    ON [dbo].[DepartmentMealOrders] ([OrderDate] ASC, [DepartmentCode] ASC)
    INCLUDE ([DayLunchCount], [DayOtCount], [NightDinnerCount], [NightOtCount], [TotalMeals], [VegetarianCount], [OrderedBy]);

    PRINT 'Chỉ mục IX_MealOrders_DateDept đã được tạo thành công.';
END
GO

-- 3. Cập nhật gán DepartmentId cho các tài khoản kiểm thử chính nếu đang NULL
-- ADMIN -> DEPT_IT (DepartmentId = 4)
UPDATE [dbo].[Users]
SET [DepartmentId] = 4
WHERE [UserCode] = 'ADMIN' AND [DepartmentId] IS NULL;

-- 1200837 -> DEPT_HR (DepartmentId = 3)
UPDATE [dbo].[Users]
SET [DepartmentId] = 3
WHERE [UserCode] = '1200837' AND [DepartmentId] IS NULL;

-- 1200838 -> DEPT_PBA (DepartmentId = 5)
UPDATE [dbo].[Users]
SET [DepartmentId] = 5
WHERE [UserCode] = '1200838' AND [DepartmentId] IS NULL;

-- 1200839 -> DEPT_LCM (DepartmentId = 6)
UPDATE [dbo].[Users]
SET [DepartmentId] = 6
WHERE [UserCode] = '1200839' AND [DepartmentId] IS NULL;

PRINT 'Hoàn tất cập nhật phòng ban cho các tài khoản thử nghiệm.';
GO
