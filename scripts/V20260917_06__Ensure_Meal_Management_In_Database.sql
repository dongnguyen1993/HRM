-- ==============================================================================
-- SCRIPT: Bổ sung đầy đủ Menu và Phân quyền 'Meal Management' vào CSDL
-- Mục đích:
--   1. Cập nhật ProgramMenus: Meal Management (MEAL_MANAGEMENT) thuộc nhóm 2000_HR
--   2. Phân quyền AuthorGroupMapping cho TẤT CẢ các nhóm quyền (AuthorGroups)
--   3. Đồng bộ quyền Menu Cha 2000_HR để menu hiển thị trên thanh điều hướng
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Đảm bảo Nhóm Menu Cha '2000_HR' (Human Resource) đang bật
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '2000_HR')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '2000_HR', NULL, N'Human Resource', N'HR', '/hr', NULL,
            1, 1, 1, 2, N'Phân hệ Quản Trị Nhân Sự & Báo Cơm (Chuẩn MES-Hansol)', 'team', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm Menu Cha: Human Resource (2000_HR)';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Human Resource',
            [Path] = '/hr',
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [Icon] = 'team'
        WHERE [ProgramKey] = '2000_HR';
        PRINT N'-> Đã cập nhật Menu Cha: Human Resource (2000_HR)';
    END

    -- 2. Thêm hoặc cập nhật Menu Con: Meal Management (MEAL_MANAGEMENT)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = 'MEAL_MANAGEMENT')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            'MEAL_MANAGEMENT', '2000_HR', N'Meal Management', N'HR', '/hr/meal-management', '/api/meal-orders',
            2, 1, 1, 4, N'Quản lý, báo cáo tổng hợp và đối soát suất ăn hàng ngày dành cho HR và Bếp ăn MES-Hansol', 'coffee', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm Menu: Meal Management (MEAL_MANAGEMENT)';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Meal Management',
            [ParentProgramKey] = '2000_HR',
            [ProgramGroup] = N'HR',
            [Path] = '/hr/meal-management',
            [ApiUrl] = '/api/meal-orders',
            [Level] = 2,
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 4,
            [Comment] = N'Quản lý, báo cáo tổng hợp và đối soát suất ăn hàng ngày dành cho HR và Bếp ăn MES-Hansol',
            [Icon] = 'coffee',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = 'MEAL_MANAGEMENT';
        PRINT N'-> Đã cập nhật Menu: Meal Management (MEAL_MANAGEMENT)';
    END

    -- 3. Phân quyền Menu Cha 2000_HR cho tất cả AuthorGroups đang hoạt động
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 
        g.GroupId,
        p.ProgramId,
        1 AS IsSearch,
        0 AS IsCreate,
        0 AS IsUpdate,
        0 AS IsDelete,
        0 AS IsSave,
        1 AS IsPrint
    FROM [dbo].[AuthorGroups] g WITH (NOLOCK)
    CROSS JOIN [dbo].[ProgramMenus] p WITH (NOLOCK)
    WHERE g.UseFlag = 1
      AND p.ProgramKey = '2000_HR'
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] m WITH (NOLOCK)
          WHERE m.GroupId = g.GroupId AND m.ProgramId = p.ProgramId
      );

    -- 4. Phân quyền Menu Con MEAL_MANAGEMENT cho tất cả AuthorGroups đang hoạt động
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 
        g.GroupId,
        p.ProgramId,
        1 AS IsSearch, -- Xem báo cáo đối soát
        CASE WHEN g.GroupId IN (1, 2, 3, 6) THEN 1 ELSE 0 END AS IsCreate,
        CASE WHEN g.GroupId IN (1, 2, 3, 6) THEN 1 ELSE 0 END AS IsUpdate, -- HR / Quản lý được điều chỉnh
        0 AS IsDelete,
        CASE WHEN g.GroupId IN (1, 2, 3, 6) THEN 1 ELSE 0 END AS IsSave,
        1 AS IsPrint   -- Xuất file Excel
    FROM [dbo].[AuthorGroups] g WITH (NOLOCK)
    CROSS JOIN [dbo].[ProgramMenus] p WITH (NOLOCK)
    WHERE g.UseFlag = 1
      AND p.ProgramKey = 'MEAL_MANAGEMENT'
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] m WITH (NOLOCK)
          WHERE m.GroupId = g.GroupId AND m.ProgramId = p.ProgramId
      );

    -- Cập nhật quyền đầy đủ cho Administrator (GroupId = 1)
    UPDATE m
    SET m.IsSearch = 1, m.IsCreate = 1, m.IsUpdate = 1, m.IsDelete = 1, m.IsSave = 1, m.IsPrint = 1
    FROM [dbo].[AuthorGroupMapping] m
    INNER JOIN [dbo].[ProgramMenus] p ON m.ProgramId = p.ProgramId
    WHERE p.ProgramKey IN ('2000_HR', 'MEAL_MANAGEMENT') AND m.GroupId = 1;

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT THÊM MENU VÀ PHÂN QUYỀN VÀO DATABASE THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT N'LỖI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
