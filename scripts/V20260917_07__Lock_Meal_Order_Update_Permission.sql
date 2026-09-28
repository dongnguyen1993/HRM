-- ==============================================================================
-- SCRIPT: Khóa Quyền Chỉnh Sửa Menu 'Department Meal Order' (6030_MEAL_ORDER)
-- Ngày tạo: 2026-09-17
-- Mục đích:
--   Chỉ cho phép quyền Tra Cứu (IsSearch = 1) và Tạo Mới (IsCreate = 1).
--   Khóa hoàn toàn quyền Cập Nhật (IsUpdate = 0) và Xóa (IsDelete = 0)
--   trên màn hình Đăng ký Suất ăn Phòng ban.
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Cập nhật quyền trong bảng AuthorGroupMapping cho Menu '6030_MEAL_ORDER'
    -- Đặt IsUpdate = 0, IsDelete = 0 cho tất cả các nhóm quyền
    UPDATE m
    SET m.IsSearch = 1,
        m.IsCreate = 1,
        m.IsUpdate = 0, -- KHÓA QUYỀN SỬA
        m.IsDelete = 0, -- KHÓA QUYỀN XÓA
        m.IsSave = 1,
        m.IsPrint = 1
    FROM [dbo].[AuthorGroupMapping] m
    INNER JOIN [dbo].[ProgramMenus] p ON m.ProgramId = p.ProgramId
    WHERE p.ProgramKey = '6030_MEAL_ORDER';

    PRINT N'-> Đã cập nhật AuthorGroupMapping: Khóa quyền IsUpdate = 0 cho Menu 6030_MEAL_ORDER!';

    -- 2. Kiểm tra lại dữ liệu phân quyền hiện tại
    SELECT 
        g.GroupId,
        g.GroupName,
        p.ProgramKey,
        p.ProgramName,
        m.IsSearch,
        m.IsCreate,
        m.IsUpdate,
        m.IsDelete
    FROM [dbo].[AuthorGroupMapping] m
    INNER JOIN [dbo].[AuthorGroups] g ON m.GroupId = g.GroupId
    INNER JOIN [dbo].[ProgramMenus] p ON m.ProgramId = p.ProgramId
    WHERE p.ProgramKey = '6030_MEAL_ORDER';

    COMMIT TRANSACTION;
    PRINT N'=== THÀNH CÔNG: ĐÃ KHÓA QUYỀN SỬA CHO ĐĂNG KÝ SUẤT ĂN PHÒNG BAN ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'LỖI THỰC THI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
