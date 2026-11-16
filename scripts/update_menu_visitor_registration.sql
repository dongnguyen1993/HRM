-- ==============================================================================
-- Script: update_menu_visitor_registration.sql
-- Mục đích: Đổi mã menu 3004_GA_VISITOR_REGISTRATION -> 1006_GA_VISITOR_REGISTRATION
--           Cập nhật SortOrder = 1006 để nằm cuối nhóm Cổng tự phục vụ ESS
-- ==============================================================================

SET NOCOUNT ON;

UPDATE dbo.SYS_ProgramMenus
SET ProgramKey = '1006_GA_VISITOR_REGISTRATION',
    SortOrder = 1006,
    ParentProgramKey = '1000_ESS',
    ProgramGroup = 'ESS',
    UpdatedAt = GETDATE(),
    UpdatedBy = 'ADMIN'
WHERE ProgramKey = '3004_GA_VISITOR_REGISTRATION';

PRINT N'Đã cập nhật mã menu 3004_GA_VISITOR_REGISTRATION thành 1006_GA_VISITOR_REGISTRATION!';
GO
