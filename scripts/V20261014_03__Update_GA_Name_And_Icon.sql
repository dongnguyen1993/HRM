-- ==============================================================================
-- SCRIPT: CẬP NHẬT TÊN NHÓM MENU "QUẢN TRỊ HÀNH CHÍNH" VÀ BIỂU TƯỢNG HANSOL
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Cập nhật nhóm menu 3000_GA trong ProgramMenus
    UPDATE [dbo].[ProgramMenus]
    SET [ProgramName] = N'Quản Trị Hành Chính',
        [Icon] = 'hansol'
    WHERE [ProgramKey] = '3000_GA';

    -- 2. Cập nhật nhóm quyền 3003 trong AuthorGroups
    UPDATE [dbo].[AuthorGroups]
    SET [GroupName] = N'Quản Trị Hành Chính (GA Officer)',
        [Comment] = N'Nhóm Quản Trị Hành Chính (GA Officer)'
    WHERE [GroupId] = 3003;

    COMMIT TRANSACTION;
    PRINT N'=== CẬP NHẬT TÊN 3000_GA THÀNH "Quản Trị Hành Chính" THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'LỖI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
