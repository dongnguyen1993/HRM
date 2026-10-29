-- =========================================================================================
-- Migration: V20261027_01__Remove_SystemSettings_Menu.sql
-- Mô tả: Vô hiệu hóa và ẩn hoàn toàn màn hình "Cấu hình Hệ thống" (ProgramKey 1030)
-- =========================================================================================
SET NOCOUNT ON;

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'=== 1. VÔ HIỆU HÓA MENU 1030 (CẤU HÌNH HỆ THỐNG) ===';
    UPDATE [dbo].[ProgramMenus]
    SET [UseFlag] = 0,
        [MenuFlag] = 0,
        [UpdatedBy] = 'ADMIN',
        [UpdatedAt] = GETDATE()
    WHERE [ProgramKey] = '1030' 
       OR [Path] = '/system-mgmt/system-settings'
       OR [ProgramKey] = 'SYSTEM_SETTINGS';

    PRINT N'=== 2. THU HỒI QUYỀN MÀN HÌNH 1030 KHỎI CÁC NHÓM QUYỀN ===';
    DELETE FROM [dbo].[AuthorGroupMapping]
    WHERE [ProgramId] IN (SELECT [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] IN ('1030', 'SYSTEM_SETTINGS'));

    COMMIT TRANSACTION;
    PRINT N'✅ Đã vô hiệu hóa và ẩn thành công màn hình Cấu hình Hệ thống.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;
