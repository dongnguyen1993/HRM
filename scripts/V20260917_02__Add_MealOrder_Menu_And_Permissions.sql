-- ==============================================================================
-- SCRIPT: Thêm Menu 'Department Meal Order' vào HRM_Enterprise_DB
-- Ngày tạo: 2026-09-17
-- Mục đích:
--   1. Thêm menu con: 'Department Meal Order' (/self-service/meal-order) thuộc nhóm '6000_SELF_SERVICE'
--   2. Phân quyền truy cập (IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsSave = 1, IsPrint = 1)
--      cho tất cả các nhóm quyền (AuthorGroups)
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Đảm bảo Nhóm Menu Cha '6000_SELF_SERVICE' đang bật
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '6000_SELF_SERVICE')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '6000_SELF_SERVICE', NULL, N'Self Service', N'PORTAL', '/self-service', NULL,
            1, 1, 1, 25, N'Phân hệ Cổng Tự Phục Vụ Nhân Viên (Chuẩn MES-Hansol)', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm Menu Cha: Self Service (6000_SELF_SERVICE)';
    END

    -- 2. Thêm hoặc cập nhật Menu Con: Department Meal Order (6030_MEAL_ORDER)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '6030_MEAL_ORDER')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '6030_MEAL_ORDER', '6000_SELF_SERVICE', N'Department Meal Order', N'PORTAL', '/self-service/meal-order', '/api/meal-orders',
            2, 1, 1, 3, N'Đăng ký suất ăn ca ngày, ca đêm theo phòng ban nhà máy MES-Hansol', 'coffee', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm Menu: Department Meal Order (6030_MEAL_ORDER)';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Department Meal Order',
            [ParentProgramKey] = '6000_SELF_SERVICE',
            [Path] = '/self-service/meal-order',
            [ApiUrl] = '/api/meal-orders',
            [Level] = 2,
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 3,
            [Comment] = N'Đăng ký suất ăn ca ngày, ca đêm theo phòng ban nhà máy MES-Hansol',
            [Icon] = 'coffee',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '6030_MEAL_ORDER';
        PRINT N'-> Đã cập nhật Menu: Department Meal Order (6030_MEAL_ORDER)';
    END

    -- 3. Cấp Quyền Truy Cập (AuthorGroupMapping) cho Tất cả Nhóm Người Dùng Đang Hoạt Động
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 
        g.GroupId,
        p.ProgramId,
        1 AS IsSearch, -- Tra cứu lịch sử đặt cơm
        1 AS IsCreate, -- Tạo mới đơn đặt cơm
        1 AS IsUpdate, -- Cập nhật số lượng suất ăn
        0 AS IsDelete, -- Không cho xóa trực tiếp
        1 AS IsSave,   -- Lưu thay đổi
        1 AS IsPrint   -- In/Xuất báo cáo suất ăn
    FROM [dbo].[AuthorGroups] g WITH (NOLOCK)
    CROSS JOIN [dbo].[ProgramMenus] p WITH (NOLOCK)
    WHERE g.UseFlag = 1
      AND p.ProgramKey = '6030_MEAL_ORDER'
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] m WITH (NOLOCK)
          WHERE m.GroupId = g.GroupId AND m.ProgramId = p.ProgramId
      );

    -- 4. Đồng bộ quyền cập nhật nếu mapping đã tồn tại trước đó
    UPDATE m
    SET m.IsSearch = 1,
        m.IsCreate = 1,
        m.IsUpdate = 1,
        m.IsSave = 1,
        m.IsPrint = 1
    FROM [dbo].[AuthorGroupMapping] m
    INNER JOIN [dbo].[ProgramMenus] p ON m.ProgramId = p.ProgramId
    WHERE p.ProgramKey = '6030_MEAL_ORDER';

    PRINT N'-> Đã phân quyền AuthorGroupMapping thành công cho toàn bộ nhóm quyền!';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'LỖI THỰC THI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
