-- ======================================================================
-- MIGRATION: V20261015_01__Cleanup_GA_Department_Structure.sql
-- Mục đích: Chuẩn hóa toàn diện dữ liệu cơ cấu tổ chức phòng ban phân hệ GA (Hành chính)
-- Gỡ bỏ triệt để các yếu tố suất ăn / giao cơm
-- ======================================================================
USE [HRM_Enterprise_DB];
GO

-- 1. Cập nhật khối cấp 1 của GA từ DIV_MEAL thành DIV_GA
UPDATE [dbo].[Departments]
SET DepartmentCode = 'DIV_GA',
    DepartmentName = N'Khối Quản Trị Hành Chính (General Affairs Division)',
    Comment = N'Khối cơ cấu tổ chức Hành chính - General Affairs',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'DIV_MEAL' AND DeptType = 'GA';

-- 2. Chuẩn hóa tên và ghi chú các phòng ban GA
UPDATE [dbo].[Departments]
SET DepartmentName = N'Khối Chuyên Gia Hàn Quốc (Korean Experts)',
    Comment = N'Bộ phận Chuyên gia Hàn Quốc',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'KOREAN' AND DeptType = 'GA';

UPDATE [dbo].[Departments]
SET Comment = N'Phòng Thu Mua & Quản lý Nhà Cung Cấp',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'PUR' AND DeptType = 'GA';

UPDATE [dbo].[Departments]
SET Comment = N'Phòng Quản Lý Chất Lượng & Tiêu Chuẩn',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'QC' AND DeptType = 'GA';

UPDATE [dbo].[Departments]
SET Comment = N'Bộ phận Kho Vận & Quản Lý Cơ Sở Vật Chất',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'WH' AND DeptType = 'GA';

UPDATE [dbo].[Departments]
SET Comment = N'Phòng Hành Chính Tổng Hợp',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'GA' AND DeptType = 'GA';

UPDATE [dbo].[Departments]
SET Comment = N'Phòng Quản Lý Môi Trường, An Toàn & Sức Khỏe',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'MIGRATION'
WHERE DepartmentCode = 'HSE' AND DeptType = 'GA';

PRINT N'-> Đã chuẩn hóa toàn bộ dữ liệu cơ cấu phòng ban GA trong bảng Departments!';
GO
