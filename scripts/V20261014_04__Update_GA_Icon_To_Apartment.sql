-- ======================================================================
-- Migration: V20261014_04__Update_GA_Icon_To_Apartment.sql
-- Description: Đổi Icon cho menu Quản Trị Hành Chính (3000_GA) thành 'apartment'
-- ======================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

PRINT N'=== BẮT ĐẦU CẬP NHẬT ICON MENU 3000_GA THÀNH APARTMENT ===';

UPDATE [dbo].[ProgramMenus]
SET [Icon] = 'apartment',
    [UpdatedAt] = GETDATE(),
    [UpdatedBy] = 'ADMIN'
WHERE [ProgramKey] = '3000_GA';

PRINT N'Cập nhật thành công Icon cho 3000_GA.';

-- Kiểm tra kết quả
SELECT [ProgramKey], [ProgramName], [Icon], [Path]
FROM [dbo].[ProgramMenus]
WHERE [ProgramKey] = '3000_GA';
GO
