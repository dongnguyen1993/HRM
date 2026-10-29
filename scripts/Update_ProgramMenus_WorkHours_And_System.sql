-- =========================================================================================
-- Script: Update_ProgramMenus_WorkHours_And_System.sql
-- Mô tả: Cập nhật cấu hình Menu (ProgramMenus) cho các màn hình mới mở lại:
--        - 6 Màn hình đưa vào Quản Trị Nhân Sự (2000_HR):
--          1. Dữ liệu máy chấm công (5030_MACHINE_RECORDS -> /hr/machine-records)
--          2. Thiết lập Ca làm việc (5010_SHIFT_SETUP -> /hr/shift-setup)
--          3. Tổng hợp Giờ công (5020_WORK_SUMMARY -> /hr/work-summary)
--          4. Đơn xin Nghỉ phép (5040_TIMEOFF_REQUESTS -> /hr/timeoff-requests)
--          5. Đăng ký Tăng ca (5050_OT_REGISTRATION -> /hr/ot-registration)
--          6. Báo cáo Giờ công (5060 -> /hr/work-time-report)
--        - 1 Màn hình đưa vào Quản Trị Hệ Thống (1000_SYS):
--          7. Cấu hình Thiết bị & Cổng Chấm Công (5070_DEVICE_SETUP -> /system-mgmt/device-setup)
--        - Ẩn nhóm menu cũ (5000_WORK_HOURS)
-- Lưu ý: Script này CHỈ cập nhật bảng ProgramMenus, KHÔNG can thiệp bảng phân quyền (AuthorGroupMapping).
-- =========================================================================================

SET NOCOUNT ON;

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'=== 1. CẬP NHẬT CÁC MÀN HÌNH VÀO PHÂN HỆ QUẢN TRỊ NHÂN SỰ (2000_HR) ===';

    -- 1.1 Dữ liệu máy chấm công (5030_MACHINE_RECORDS)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5030_MACHINE_RECORDS' OR [Path] IN ('/hr/machine-records', '/work-hours/machine-records'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName]      = N'Dữ liệu máy chấm công',
            [ProgramGroup]     = N'HR',
            [Path]             = '/hr/machine-records',
            [ApiUrl]           = '/api/machine-records',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 5,
            [Icon]             = 'database',
            [Comment]          = N'Lịch sử quẹt thẻ & log chấm công từ máy BioStar 2',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5030_MACHINE_RECORDS' OR [Path] IN ('/hr/machine-records', '/work-hours/machine-records');
        PRINT N'  -> Đã cập nhật: Dữ liệu máy chấm công (/hr/machine-records)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5030_MACHINE_RECORDS', '2000_HR', N'Dữ liệu máy chấm công', N'HR', '/hr/machine-records', '/api/machine-records',
            2, 1, 1, 5, N'Lịch sử quẹt thẻ & log chấm công từ máy BioStar 2', 'database', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Dữ liệu máy chấm công (/hr/machine-records)';
    END

    -- 1.2 Thiết lập Ca làm việc (5010_SHIFT_SETUP)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5010_SHIFT_SETUP' OR [Path] IN ('/hr/shift-setup', '/work-hours/shift-setup'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName]      = N'Thiết lập Ca làm việc',
            [ProgramGroup]     = N'HR',
            [Path]             = '/hr/shift-setup',
            [ApiUrl]           = '/api/shift-setup',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 6,
            [Icon]             = 'schedule',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5010_SHIFT_SETUP' OR [Path] IN ('/hr/shift-setup', '/work-hours/shift-setup');
        PRINT N'  -> Đã cập nhật: Thiết lập Ca làm việc (/hr/shift-setup)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5010_SHIFT_SETUP', '2000_HR', N'Thiết lập Ca làm việc', N'HR', '/hr/shift-setup', '/api/shift-setup',
            2, 1, 1, 6, N'Quản lý danh mục các ca làm việc nhà máy', 'schedule', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Thiết lập Ca làm việc (/hr/shift-setup)';
    END

    -- 1.3 Tổng hợp Giờ công (5020_WORK_SUMMARY)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5020_WORK_SUMMARY' OR [Path] IN ('/hr/work-summary', '/work-hours/work-summary'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName]      = N'Tổng hợp Giờ công',
            [ProgramGroup]     = N'HR',
            [Path]             = '/hr/work-summary',
            [ApiUrl]           = '/api/work-summary',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 7,
            [Icon]             = 'table',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5020_WORK_SUMMARY' OR [Path] IN ('/hr/work-summary', '/work-hours/work-summary');
        PRINT N'  -> Đã cập nhật: Tổng hợp Giờ công (/hr/work-summary)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5020_WORK_SUMMARY', '2000_HR', N'Tổng hợp Giờ công', N'HR', '/hr/work-summary', '/api/work-summary',
            2, 1, 1, 7, N'Bảng tổng hợp đối soát công nhân viên', 'table', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Tổng hợp Giờ công (/hr/work-summary)';
    END

    -- 1.4 Đơn xin Nghỉ phép (5040_TIMEOFF_REQUESTS)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5040_TIMEOFF_REQUESTS' OR [Path] IN ('/hr/timeoff-requests', '/work-hours/timeoff-requests'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName]      = N'Đơn xin Nghỉ phép',
            [ProgramGroup]     = N'HR',
            [Path]             = '/hr/timeoff-requests',
            [ApiUrl]           = '/api/time-off',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 8,
            [Icon]             = 'form',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5040_TIMEOFF_REQUESTS' OR [Path] IN ('/hr/timeoff-requests', '/work-hours/timeoff-requests');
        PRINT N'  -> Đã cập nhật: Đơn xin Nghỉ phép (/hr/timeoff-requests)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5040_TIMEOFF_REQUESTS', '2000_HR', N'Đơn xin Nghỉ phép', N'HR', '/hr/timeoff-requests', '/api/time-off',
            2, 1, 1, 8, N'Quản lý phê duyệt đơn nghỉ phép của nhân viên', 'form', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Đơn xin Nghỉ phép (/hr/timeoff-requests)';
    END

    -- 1.5 Đăng ký Tăng ca (5050_OT_REGISTRATION)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5050_OT_REGISTRATION' OR [Path] IN ('/hr/ot-registration', '/work-hours/ot-registration'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName]      = N'Đăng ký Tăng ca',
            [ProgramGroup]     = N'HR',
            [Path]             = '/hr/ot-registration',
            [ApiUrl]           = '/api/ot-registration',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 9,
            [Icon]             = 'clock-circle',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5050_OT_REGISTRATION' OR [Path] IN ('/hr/ot-registration', '/work-hours/ot-registration');
        PRINT N'  -> Đã cập nhật: Đăng ký Tăng ca (/hr/ot-registration)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5050_OT_REGISTRATION', '2000_HR', N'Đăng ký Tăng ca', N'HR', '/hr/ot-registration', '/api/ot-registration',
            2, 1, 1, 9, N'Đăng ký kế hoạch và phê duyệt tăng ca', 'clock-circle', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Đăng ký Tăng ca (/hr/ot-registration)';
    END

    -- 1.6 Báo cáo Giờ công (5060)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5060' OR [Path] IN ('/hr/work-time-report', '/work-hours/work-time-report'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '2000_HR',
            [ProgramName]      = N'Báo cáo Giờ công',
            [ProgramGroup]     = N'HR',
            [Path]             = '/hr/work-time-report',
            [ApiUrl]           = '/api/work-time-report',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 10,
            [Icon]             = 'bar-chart',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5060' OR [Path] IN ('/hr/work-time-report', '/work-hours/work-time-report');
        PRINT N'  -> Đã cập nhật: Báo cáo Giờ công (/hr/work-time-report)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5060', '2000_HR', N'Báo cáo Giờ công', N'HR', '/hr/work-time-report', '/api/work-time-report',
            2, 1, 1, 10, N'Báo cáo phân tích giờ làm việc toàn nhà máy', 'bar-chart', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Báo cáo Giờ công (/hr/work-time-report)';
    END

    PRINT N'=== 2. CẬP NHẬT MÀN HÌNH VÀO PHÂN HỆ QUẢN TRỊ HỆ THỐNG (1000_SYS) ===';

    -- 2.1 Cấu hình Thiết bị & Cổng Chấm Công - BioStar 2 (5070_DEVICE_SETUP)
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '5070_DEVICE_SETUP' OR [Path] IN ('/system-mgmt/device-setup', '/hr/device-setup', '/work-hours/device-setup'))
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '1000_SYS',
            [ProgramName]      = N'Cấu hình Thiết bị & Cổng Chấm Công',
            [ProgramGroup]     = N'SYS',
            [Path]             = '/system-mgmt/device-setup',
            [ApiUrl]           = '/api/device-setup',
            [Level]            = 2,
            [UseFlag]          = 1,
            [MenuFlag]         = 1,
            [SortOrder]        = 100,
            [Icon]             = 'hdd',
            [Comment]          = N'Cấu hình thiết bị máy chấm công & cổng kiểm soát ra vào BioStar 2',
            [UpdatedAt]        = GETDATE(),
            [UpdatedBy]        = 'ADMIN'
        WHERE [ProgramKey] = '5070_DEVICE_SETUP' OR [Path] IN ('/system-mgmt/device-setup', '/hr/device-setup', '/work-hours/device-setup');
        PRINT N'  -> Đã cập nhật: Cấu hình Thiết bị & Cổng Chấm Công (/system-mgmt/device-setup)';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5070_DEVICE_SETUP', '1000_SYS', N'Cấu hình Thiết bị & Cổng Chấm Công', N'SYS', '/system-mgmt/device-setup', '/api/device-setup',
            2, 1, 1, 100, N'Cấu hình thiết bị máy chấm công & cổng kiểm soát ra vào BioStar 2', 'hdd', GETDATE(), 'ADMIN'
        );
        PRINT N'  -> Đã thêm mới: Cấu hình Thiết bị & Cổng Chấm Công (/system-mgmt/device-setup)';
    END

    PRINT N'=== 3. VÔ HIỆU HÓA PHÂN HỆ MENU CŨ (5000_WORK_HOURS) ===';

    -- 3.1 Ẩn phân hệ cha 5000_WORK_HOURS
    UPDATE [dbo].[ProgramMenus]
    SET [UseFlag]   = 0,
        [MenuFlag]  = 0,
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5000_WORK_HOURS';
    PRINT N'  -> Đã vô hiệu hóa nhóm menu cha cũ: 5000_WORK_HOURS';

    COMMIT TRANSACTION;
    PRINT N'✅ HOÀN TẤT CẬP NHẬT TOÀN BỘ CẤU HÌNH MENU TRONG PROGRAMMENUS THÀNH CÔNG!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

