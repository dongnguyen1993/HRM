-- =========================================================================================
-- Migration: V20261028_01__Remove_Overview_And_Welcome_Analytics_Menu.sql
-- Mô tả: Vô hiệu hóa và xóa bỏ hoàn toàn menu "Welcome Analytics" và "Overview Analytics"
-- =========================================================================================
SET NOCOUNT ON;

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'=== 1. VÔ HIỆU HÓA MENU 6002_OVERVIEW_ANALYTICS & WELCOME ===';
    UPDATE [dbo].[ProgramMenus]
    SET [UseFlag] = 0,
        [MenuFlag] = 0,
        [UpdatedBy] = 'ADMIN',
        [UpdatedAt] = GETDATE()
    WHERE [ProgramKey] IN ('6002_OVERVIEW_ANALYTICS', 'WELCOME_ANALYTICS', 'OVERVIEW_ANALYTICS')
       OR [Path] IN ('/self-service/overview-analytics', '/home/welcome', '/welcome');

    PRINT N'=== 2. THU HỒI QUYỀN MÀN HÌNH KHỎI CÁC NHÓM QUYỀN ===';
    DELETE FROM [dbo].[AuthorGroupMapping]
    WHERE [ProgramId] IN (
        SELECT [ProgramId] FROM [dbo].[ProgramMenus] 
        WHERE [ProgramKey] IN ('6002_OVERVIEW_ANALYTICS', 'WELCOME_ANALYTICS', 'OVERVIEW_ANALYTICS')
           OR [Path] IN ('/self-service/overview-analytics', '/home/welcome', '/welcome')
    );

    COMMIT TRANSACTION;
    PRINT N'✅ Đã vô hiệu hóa và thu hồi quyền thành công cho Overview Analytics & Welcome Analytics.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

