-- =========================================================================================
-- Migration: V20261029_02__Move_All_Work_Hours_To_HR_Menu.sql
-- Mô tả: Mở toàn bộ các màn hình Quản lý Giờ công và chuyển vào phân hệ Quản Trị Nhân Sự (2000_HR)
-- =========================================================================================
SET NOCOUNT ON;

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'=== 1. CHUYỂN CÁC MÀN HÌNH GIỜ CÔNG SANG NHÓM 2000_HR ===';

    -- 1.1 Thiết lập Ca làm việc (5010_SHIFT_SETUP)
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR',
        [ProgramName] = N'Thiết lập Ca làm việc',
        [ProgramGroup] = N'HR',
        [Path] = '/hr/shift-setup',
        [ApiUrl] = '/api/shift-setup',
        [Level] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 6,
        [Icon] = 'schedule',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5010_SHIFT_SETUP' OR [Path] IN ('/hr/shift-setup', '/work-hours/shift-setup');

    -- 1.2 Tổng hợp Giờ công (5020_WORK_SUMMARY)
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR',
        [ProgramName] = N'Tổng hợp Giờ công',
        [ProgramGroup] = N'HR',
        [Path] = '/hr/work-summary',
        [ApiUrl] = '/api/work-summary',
        [Level] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 7,
        [Icon] = 'table',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5020_WORK_SUMMARY' OR [Path] IN ('/hr/work-summary', '/work-hours/work-summary');

    -- 1.3 Đơn xin Nghỉ phép (5040_TIMEOFF_REQUESTS) - Sửa path chuẩn /hr/timeoff-requests
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR',
        [ProgramName] = N'Đơn xin Nghỉ phép',
        [ProgramGroup] = N'HR',
        [Path] = '/hr/timeoff-requests',
        [ApiUrl] = '/api/time-off',
        [Level] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 8,
        [Icon] = 'form',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5040_TIMEOFF_REQUESTS';

    -- 1.4 Đăng ký Tăng ca (5050_OT_REGISTRATION)
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR',
        [ProgramName] = N'Đăng ký Tăng ca',
        [ProgramGroup] = N'HR',
        [Path] = '/hr/ot-registration',
        [ApiUrl] = '/api/ot-registration',
        [Level] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 9,
        [Icon] = 'clock-circle',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5050_OT_REGISTRATION' OR [Path] IN ('/hr/ot-registration', '/work-hours/ot-registration');

    -- 1.5 Báo cáo Giờ công (5060)
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR',
        [ProgramName] = N'Báo cáo Giờ công',
        [ProgramGroup] = N'HR',
        [Path] = '/hr/work-time-report',
        [ApiUrl] = '/api/work-time-report',
        [Level] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 10,
        [Icon] = 'bar-chart',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5060' OR [Path] IN ('/hr/work-time-report', '/work-hours/work-time-report');

    -- 1.6 Thiết lập Thiết bị chấm công (5070_DEVICE_SETUP)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5070_DEVICE_SETUP' OR [Path] = '/hr/device-setup')
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName] = N'Thiết lập Máy chấm công',
            [ProgramGroup] = N'HR',
            [Path] = '/hr/device-setup',
            [ApiUrl] = '/api/device-setup',
            [Level] = 2,
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 11,
            [Icon] = 'setting',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '5070_DEVICE_SETUP' OR [Path] = '/hr/device-setup';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5070_DEVICE_SETUP', '2000_HR', N'Thiết lập Máy chấm công', N'HR', '/hr/device-setup', '/api/device-setup',
            2, 1, 1, 11, N'Cấu hình thông tin thiết bị máy chấm công (IP, cổng)', 'setting', GETDATE(), 'ADMIN'
        );
    END

    -- 1.7 Vô hiệu hóa nhóm menu cha cũ 5000_WORK_HOURS
    UPDATE [dbo].[ProgramMenus]
    SET [UseFlag] = 0, [MenuFlag] = 0, [UpdatedAt] = GETDATE(), [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5000_WORK_HOURS';

    PRINT N'=== 2. CẤP QUYỀN MÀN HÌNH CHO ADMINISTRATOR VÀ HR_OFFICER ===';

    -- Lấy danh sách ProgramId của 6 màn hình vừa chuyển
    DECLARE @MovedPrograms TABLE (ProgramId INT);
    INSERT INTO @MovedPrograms (ProgramId)
    SELECT [ProgramId] FROM [dbo].[ProgramMenus]
    WHERE [ProgramKey] IN ('5010_SHIFT_SETUP', '5020_WORK_SUMMARY', '5040_TIMEOFF_REQUESTS', '5050_OT_REGISTRATION', '5060', '5070_DEVICE_SETUP')
       OR [ParentProgramKey] = '2000_HR';

    -- 2.1 Cấp toàn quyền cho Administrator (GroupId = 1)
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT 1, p.ProgramId, 1, 1, 1, 1, 1, 1
    FROM @MovedPrograms p
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[AuthorGroupMapping] agm WHERE agm.[GroupId] = 1 AND agm.[ProgramId] = p.ProgramId
    );

    UPDATE agm
    SET [IsSearch] = 1, [IsCreate] = 1, [IsUpdate] = 1, [IsDelete] = 1, [IsSave] = 1, [IsPrint] = 1
    FROM [dbo].[AuthorGroupMapping] agm
    INNER JOIN @MovedPrograms p ON agm.[ProgramId] = p.ProgramId
    WHERE agm.[GroupId] = 1;

    -- 2.2 Cấp quyền cho nhóm HR_OFFICER (GroupId = 3002 hoặc nhóm chứa 'HR')
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT ag.[GroupId], p.ProgramId, 1, 1, 1, 1, 1, 1
    FROM [dbo].[AuthorGroups] ag
    CROSS JOIN @MovedPrograms p
    WHERE (ag.[GroupId] = 3002 OR ag.[GroupName] LIKE '%HR%' OR ag.[GroupName] LIKE N'%Nhân Sự%')
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] agm WHERE agm.[GroupId] = ag.[GroupId] AND agm.[ProgramId] = p.ProgramId
      );

    -- 2.3 Cấp quyền cho bất kỳ nhóm nào đang có quyền xem nhóm 2000_HR
    DECLARE @ParentProgramId INT = (SELECT [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '2000_HR');
    IF @ParentProgramId IS NOT NULL
    BEGIN
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT DISTINCT agm.[GroupId], p.ProgramId, 1, 1, 1, 1, 1, 1
        FROM [dbo].[AuthorGroupMapping] agm
        CROSS JOIN @MovedPrograms p
        WHERE agm.[ProgramId] = @ParentProgramId AND agm.[IsSearch] = 1
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[AuthorGroupMapping] sub WHERE sub.[GroupId] = agm.[GroupId] AND sub.[ProgramId] = p.ProgramId
          );
    END

    COMMIT TRANSACTION;
    PRINT N'✅ Đã chuyển thành công toàn bộ các màn hình Giờ công sang mục Quản Trị Nhân Sự!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

