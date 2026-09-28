-- ==============================================================================
-- SCRIPT: Thêm Menu Self-Service (Cổng Tự Phục Vụ) vào HRM_Enterprise_DB
-- Mục đích:
--   1. Thêm nhóm menu cha: 'Self Service' (/self-service)
--   2. Thêm 2 menu con:
--        - 'My Work Schedule' (/self-service/work-schedule)
--        - 'my Daily Work Time' (/self-service/daily-work-time)
--   3. Phân quyền truy cập (IsSearch = 1, IsCreate = 1, IsPrint = 1) cho tất cả AuthorGroups
--   4. Đổi tên các menu cũ chứa từ khóa 'Dashboard' (tránh bị Kaspersky chặn)
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Đổi tên các bản ghi cũ có từ khóa 'Dashboard' để tránh Kaspersky DLP / Web Filter
    UPDATE [dbo].[ProgramMenus]
    SET [ProgramName] = N'Home',
        [Path] = '/home'
    WHERE [ProgramKey] = '2000' AND [ProgramName] LIKE '%Dashboard%';

    UPDATE [dbo].[ProgramMenus]
    SET [ProgramName] = N'User Overview'
    WHERE [ProgramKey] = '2030' AND [ProgramName] LIKE '%Dash%';

    -- 2. Thêm Nhóm Menu Cha: 6000_SELF_SERVICE (Level 1)
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
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Self Service',
            [Path] = '/self-service',
            [UseFlag] = 1,
            [MenuFlag] = 1
        WHERE [ProgramKey] = '6000_SELF_SERVICE';
        PRINT N'-> Đã cập nhật Menu Cha: Self Service (6000_SELF_SERVICE)';
    END

    -- 3. Thêm Menu Con 1: My Work Schedule (6010_WORK_SCHEDULE)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '6010_WORK_SCHEDULE')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '6010_WORK_SCHEDULE', '6000_SELF_SERVICE', N'My Work Schedule', N'PORTAL', '/self-service/work-schedule', '/api/work-summary',
            2, 1, 1, 1, N'Lịch ca và nghỉ phép trực quan dạng Calendar tháng', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm Menu: My Work Schedule (6010_WORK_SCHEDULE)';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'My Work Schedule',
            [Path] = '/self-service/work-schedule',
            [UseFlag] = 1,
            [MenuFlag] = 1
        WHERE [ProgramKey] = '6010_WORK_SCHEDULE';
        PRINT N'-> Đã cập nhật Menu: My Work Schedule (6010_WORK_SCHEDULE)';
    END

    -- 4. Thêm Menu Con 2: my Daily Work Time (6020_DAILY_WORK_TIME)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '6020_DAILY_WORK_TIME')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '6020_DAILY_WORK_TIME', '6000_SELF_SERVICE', N'my Daily Work Time', N'PORTAL', '/self-service/daily-work-time', '/api/work-summary',
            2, 1, 1, 2, N'Bảng chi tiết công theo ngày trong tháng 19 cột', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm Menu: my Daily Work Time (6020_DAILY_WORK_TIME)';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'my Daily Work Time',
            [Path] = '/self-service/daily-work-time',
            [UseFlag] = 1,
            [MenuFlag] = 1
        WHERE [ProgramKey] = '6020_DAILY_WORK_TIME';
        PRINT N'-> Đã cập nhật Menu: my Daily Work Time (6020_DAILY_WORK_TIME)';
    END

    -- 5. Cấp Quyền Truy Cập (AuthorGroupMapping) cho Tất cả Nhóm Người Dùng Hiện Có
    -- Cấp quyền cho 3 menu mới (Self Service, My Work Schedule, my Daily Work Time)
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 
        g.GroupId,
        p.ProgramId,
        1 AS IsSearch, -- Xem lịch & bảng công
        1 AS IsCreate, -- Gửi đơn nghỉ phép
        0 AS IsUpdate,
        0 AS IsDelete,
        0 AS IsSave,
        1 AS IsPrint  -- Xuất Excel bảng công
    FROM [dbo].[AuthorGroups] g WITH (NOLOCK)
    CROSS JOIN [dbo].[ProgramMenus] p WITH (NOLOCK)
    WHERE g.UseFlag = 1
      AND p.ProgramKey IN ('6000_SELF_SERVICE', '6010_WORK_SCHEDULE', '6020_DAILY_WORK_TIME')
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] m WITH (NOLOCK)
          WHERE m.GroupId = g.GroupId AND m.ProgramId = p.ProgramId
      );

    -- Đảm bảo quyền IsSearch = 1 nếu bản ghi mapping đã tồn tại
    UPDATE m
    SET m.IsSearch = 1,
        m.IsCreate = 1,
        m.IsPrint = 1
    FROM [dbo].[AuthorGroupMapping] m
    INNER JOIN [dbo].[ProgramMenus] p ON m.ProgramId = p.ProgramId
    WHERE p.ProgramKey IN ('6000_SELF_SERVICE', '6010_WORK_SCHEDULE', '6020_DAILY_WORK_TIME');

    PRINT N'-> Đã đồng bộ phân quyền AuthorGroupMapping thành công cho toàn bộ nhóm quyền!';

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
