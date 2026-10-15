-- ==============================================================================
-- MIGRATION SCRIPT: CẤU TRÚC LẠI 4 NHÓM MENU CHA & PHÂN QUYỀN HR / GA / USER / ADMIN
-- Dự án: Hansol HRM Enterprise System
-- Ngày tạo: 2026-10-14
--
-- Mục tiêu:
--   1. Tách thành 4 nhóm menu cha độc lập (Level 1):
--      - 6000_SELF_SERVICE: Cổng Tự Phục Vụ (Dành cho mọi user)
--      - 2000_HR: Quản Trị Nhân Sự (Dành riêng cho HR)
--      - 3000_GA: Quản Trị Hành Chính & Suất Ăn (Dành riêng cho GA)
--      - 1000_SYS: Quản Trị Hệ Thống (Dành cho IT Admin)
--   2. Chuyển các ProgramKey liên quan Suất ăn (MEAL_MANAGEMENT, WORK_CALENDAR, 6030_MEAL_ORDER) sang 3000_GA.
--   3. Vô hiệu hóa nhóm cũ 4000_DEPT, 4010_MEAL_MGMT.
--   4. Cập nhật nhóm quyền và phân quyền trong AuthorGroupMapping:
--      - HR_OFFICER: Chỉ xem 2000_HR và Cổng tự phục vụ.
--      - GA_OFFICER & Meal-Manager: Chỉ xem 3000_GA và Cổng tự phục vụ.
--      - USER: Chỉ xem Cổng tự phục vụ.
--      - ADMIN: Xem được toàn bộ.
--   5. Cập nhật SidebarStyle trong User_Theme_Settings mặc định luôn là 'light'.
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== 1. CẬP NHẬT NHÓM MENU CHA 1: 6000_SELF_SERVICE (CỔNG TỰ PHỤC VỤ) ===';
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '6000_SELF_SERVICE')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '6000_SELF_SERVICE', NULL, N'Cổng Tự Phục Vụ', N'PORTAL', '/self-service', NULL,
            1, 1, 1, 10, N'Phân hệ Cổng Tự Phục Vụ Nhân Viên (Chuẩn MES-Hansol)', 'calendar', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm mới nhóm 6000_SELF_SERVICE';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Cổng Tự Phục Vụ',
            [ParentProgramKey] = NULL,
            [Level] = 1,
            [Path] = '/self-service',
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 10,
            [Icon] = 'calendar',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '6000_SELF_SERVICE';
        PRINT N'-> Đã cập nhật nhóm 6000_SELF_SERVICE';
    END

    -- Đồng bộ các menu con của 6000_SELF_SERVICE
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '6000_SELF_SERVICE', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 1
    WHERE [ProgramKey] = '6010_WORK_SCHEDULE';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '6000_SELF_SERVICE', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 2
    WHERE [ProgramKey] = '6020_DAILY_WORK_TIME';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '6000_SELF_SERVICE', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 3
    WHERE [ProgramKey] = '6040_MY_PAYSLIP';

    PRINT N'=== 2. CẬP NHẬT NHÓM MENU CHA 2: 2000_HR (QUẢN TRỊ NHÂN SỰ) ===';
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '2000_HR')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '2000_HR', NULL, N'Quản Trị Nhân Sự', N'HR', '/hr', NULL,
            1, 1, 1, 20, N'Phân hệ Quản Trị Nhân Sự (Dành riêng cho ban HR)', 'team', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm mới nhóm 2000_HR';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Quản Trị Nhân Sự',
            [ParentProgramKey] = NULL,
            [Level] = 1,
            [Path] = '/hr',
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 20,
            [Icon] = 'team',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '2000_HR';
        PRINT N'-> Đã cập nhật nhóm 2000_HR';
    END

    -- Đồng bộ các menu con của 2000_HR
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 1
    WHERE [ProgramKey] = '2001_DEPT';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 2
    WHERE [ProgramKey] = '2002_CONT';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 3
    WHERE [ProgramKey] = '2003_LEAV';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '2000_HR', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1, [SortOrder] = 4
    WHERE [ProgramKey] = '2004_PAYROLL';

    PRINT N'=== 3. CẬP NHẬT NHÓM MENU CHA 3: 3000_GA (QUẢN TRỊ HÀNH CHÍNH & SUẤT ĂN) ===';
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '3000_GA')
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '3000_GA', NULL, N'Quản Trị Hành Chính & Suất Ăn', N'GA', '/ga', NULL,
            1, 1, 1, 30, N'Phân hệ Quản Trị Hành Chính & Suất Ăn (Dành riêng cho ban GA)', 'coffee', GETDATE(), 'ADMIN'
        );
        PRINT N'-> Đã thêm mới nhóm 3000_GA';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Quản Trị Hành Chính & Suất Ăn',
            [ParentProgramKey] = NULL,
            [Level] = 1,
            [Path] = '/ga',
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 30,
            [Icon] = 'coffee',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '3000_GA';
        PRINT N'-> Đã cập nhật nhóm 3000_GA';
    END

    -- Chuyển các ProgramKey liên quan đến Suất ăn sang nhóm cha 3000_GA
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '3000_GA',
        [ProgramName] = N'Quản lý suất ăn',
        [Path] = '/ga/meal-management',
        [Level] = 2,
        [SortOrder] = 1,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [Icon] = 'coffee',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = 'MEAL_MANAGEMENT';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '3000_GA',
        [ProgramName] = N'Lịch làm việc & Suất ăn',
        [Path] = '/ga/work-calendar',
        [Level] = 2,
        [SortOrder] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [Icon] = 'calendar',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = 'WORK_CALENDAR';

    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '3000_GA',
        [ProgramName] = N'Đăng ký suất ăn',
        [Path] = '/ga/meal-order',
        [Level] = 2,
        [SortOrder] = 3,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [Icon] = 'coffee',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '6030_MEAL_ORDER';

    PRINT N'=== 4. CẬP NHẬT NHÓM MENU CHA 4: 1000_SYS (QUẢN TRỊ HỆ THỐNG) ===';
    -- Đổi ProgramKey 1000 -> 1000_SYS nếu đang dùng 1000
    IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '1000')
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramKey] = '1000_SYS',
            [ProgramName] = N'Quản Trị Hệ Thống',
            [ParentProgramKey] = NULL,
            [Level] = 1,
            [Path] = '/system-mgmt',
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 40,
            [Icon] = 'setting',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '1000';

        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '1000_SYS'
        WHERE [ParentProgramKey] = '1000';

        PRINT N'-> Đã đổi mã nhóm 1000 thành 1000_SYS';
    END
    ELSE IF EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '1000_SYS')
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramName] = N'Quản Trị Hệ Thống',
            [ParentProgramKey] = NULL,
            [Level] = 1,
            [Path] = '/system-mgmt',
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 40,
            [Icon] = 'setting',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramKey] = '1000_SYS';

        UPDATE [dbo].[ProgramMenus]
        SET [ParentProgramKey] = '1000_SYS'
        WHERE [ParentProgramKey] = '1000';
    END

    -- Đồng bộ các menu con của 1000_SYS
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '1000_SYS', [Level] = 2, [UseFlag] = 1, [MenuFlag] = 1
    WHERE [ProgramKey] IN ('1003', '1007', '1002', '1040', '1050', '1030', '1060', '1070');

    PRINT N'=== 5. VÔ HIỆU HÓA CÁC NHÓM CŨ & ẨN KHỎI SIDEBAR MENU ===';
    -- Vô hiệu hóa 4000_DEPT và 4010_MEAL_MGMT
    UPDATE [dbo].[ProgramMenus]
    SET [UseFlag] = 0, [MenuFlag] = 0
    WHERE [ProgramKey] IN ('4000_DEPT', '4010_MEAL_MGMT');

    -- Ẩn nhóm Home (2000), Account (3000), và Work Hours (5000_WORK_HOURS) khỏi Sidebar Menu chính
    UPDATE [dbo].[ProgramMenus]
    SET [MenuFlag] = 0
    WHERE [ProgramKey] IN ('2000', '3000', '5000_WORK_HOURS');

    PRINT N'=== 6. CẬP NHẬT AUTHORGROUPS (NHÓM QUYỀN) ===';
    -- 6.1 Tạo nhóm HR_OFFICER nếu chưa có
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'HR_OFFICER')
    BEGIN
        INSERT INTO [dbo].[AuthorGroups] ([GroupName], [UseFlag], [Comment])
        VALUES ('HR_OFFICER', 1, N'Nhóm Quản Trị Nhân Sự (HR Officer)');
        PRINT N'-> Đã thêm AuthorGroup: HR_OFFICER';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[AuthorGroups] SET [UseFlag] = 1 WHERE [GroupName] = 'HR_OFFICER';
    END

    -- 6.2 Tạo nhóm GA_OFFICER nếu chưa có
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'GA_OFFICER')
    BEGIN
        INSERT INTO [dbo].[AuthorGroups] ([GroupName], [UseFlag], [Comment])
        VALUES ('GA_OFFICER', 1, N'Nhóm Quản Trị Hành Chính & Suất Ăn (GA Officer)');
        PRINT N'-> Đã thêm AuthorGroup: GA_OFFICER';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[AuthorGroups] SET [UseFlag] = 1 WHERE [GroupName] = 'GA_OFFICER';
    END

    -- Đảm bảo User & Administrator bật UseFlag
    UPDATE [dbo].[AuthorGroups] SET [UseFlag] = 1 WHERE [GroupName] IN ('User', 'Administrator', 'Meal-Manager');

    PRINT N'=== 7. CẬP NHẬT PHÂN QUYỀN TRONG AuthorGroupMapping ===';
    DECLARE @AdminGroupId INT = (SELECT TOP 1 [GroupId] FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'Administrator');
    DECLARE @HrGroupId INT = (SELECT TOP 1 [GroupId] FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'HR_OFFICER');
    DECLARE @GaGroupId INT = (SELECT TOP 1 [GroupId] FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'GA_OFFICER');
    DECLARE @MealManagerGroupId INT = (SELECT TOP 1 [GroupId] FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'Meal-Manager');
    DECLARE @UserGroupId INT = (SELECT TOP 1 [GroupId] FROM [dbo].[AuthorGroups] WHERE [GroupName] = 'User');

    -- -------------------------------------------------------------
    -- 7.1 NHÓM ADMIN (Administrator): Xem & thao tác toàn bộ
    -- -------------------------------------------------------------
    IF @AdminGroupId IS NOT NULL
    BEGIN
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT @AdminGroupId, pm.[ProgramId], 1, 1, 1, 1, 1, 1
        FROM [dbo].[ProgramMenus] pm
        WHERE pm.[UseFlag] = 1
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[AuthorGroupMapping] agm
              WHERE agm.[GroupId] = @AdminGroupId AND agm.[ProgramId] = pm.[ProgramId]
          );

        UPDATE agm
        SET agm.[IsSearch] = 1, agm.[IsCreate] = 1, agm.[IsUpdate] = 1, agm.[IsDelete] = 1, agm.[IsSave] = 1, agm.[IsPrint] = 1
        FROM [dbo].[AuthorGroupMapping] agm
        INNER JOIN [dbo].[ProgramMenus] pm ON agm.[ProgramId] = pm.[ProgramId]
        WHERE agm.[GroupId] = @AdminGroupId AND pm.[UseFlag] = 1;
        PRINT N'-> Đã cấp Full quyền cho Administrator';
    END

    -- -------------------------------------------------------------
    -- 7.2 NHÓM HR_OFFICER: Chỉ xem nhóm 2000_HR và Cổng tự phục vụ
    -- -------------------------------------------------------------
    IF @HrGroupId IS NOT NULL
    BEGIN
        -- Xóa quyền cũ nếu có
        DELETE FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = @HrGroupId;

        -- Cấp quyền 2000_HR và con của nó (Toàn quyền quản trị nhân sự)
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT @HrGroupId, pm.[ProgramId], 1, 1, 1, 1, 1, 1
        FROM [dbo].[ProgramMenus] pm
        WHERE pm.[ProgramKey] = '2000_HR' OR pm.[ParentProgramKey] = '2000_HR';

        -- Cấp quyền Cổng tự phục vụ (6000_SELF_SERVICE và con)
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT @HrGroupId, pm.[ProgramId], 1, 1, 0, 0, 0, 1
        FROM [dbo].[ProgramMenus] pm
        WHERE pm.[ProgramKey] = '6000_SELF_SERVICE' OR pm.[ParentProgramKey] = '6000_SELF_SERVICE';

        -- Quyền cơ bản xem trang cá nhân
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT @HrGroupId, pm.[ProgramId], 1, 0, 0, 0, 0, 0
        FROM [dbo].[ProgramMenus] pm
        WHERE pm.[ProgramKey] IN ('2000', '2030');

        PRINT N'-> Đã phân quyền chuẩn cho HR_OFFICER (2000_HR + Self-Service)';
    END

    -- -------------------------------------------------------------
    -- 7.3 NHÓM GA_OFFICER & Meal-Manager: Chỉ xem nhóm 3000_GA và Cổng tự phục vụ
    -- -------------------------------------------------------------
    DECLARE @TargetGaGroups TABLE (GId INT);
    IF @GaGroupId IS NOT NULL INSERT INTO @TargetGaGroups VALUES (@GaGroupId);
    IF @MealManagerGroupId IS NOT NULL INSERT INTO @TargetGaGroups VALUES (@MealManagerGroupId);

    DELETE FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] IN (SELECT GId FROM @TargetGaGroups);

    -- Cấp quyền 3000_GA và con của nó (Toàn quyền quản trị suất ăn & hành chính)
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT g.GId, pm.[ProgramId], 1, 1, 1, 1, 1, 1
    FROM @TargetGaGroups g
    CROSS JOIN [dbo].[ProgramMenus] pm
    WHERE pm.[ProgramKey] = '3000_GA' OR pm.[ParentProgramKey] = '3000_GA';

    -- Cấp quyền Cổng tự phục vụ (6000_SELF_SERVICE và con)
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT g.GId, pm.[ProgramId], 1, 1, 0, 0, 0, 1
    FROM @TargetGaGroups g
    CROSS JOIN [dbo].[ProgramMenus] pm
    WHERE pm.[ProgramKey] = '6000_SELF_SERVICE' OR pm.[ParentProgramKey] = '6000_SELF_SERVICE';

    -- Quyền cơ bản xem trang cá nhân
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT g.GId, pm.[ProgramId], 1, 0, 0, 0, 0, 0
    FROM @TargetGaGroups g
    CROSS JOIN [dbo].[ProgramMenus] pm
    WHERE pm.[ProgramKey] IN ('2000', '2030');

    PRINT N'-> Đã phân quyền chuẩn cho GA_OFFICER & Meal-Manager (3000_GA + Self-Service)';

    -- -------------------------------------------------------------
    -- 7.4 NHÓM USER THƯỜNG: Chỉ cấp quyền xem Cổng tự phục vụ
    -- -------------------------------------------------------------
    IF @UserGroupId IS NOT NULL
    BEGIN
        DELETE FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = @UserGroupId;

        -- Chỉ cấp Cổng tự phục vụ (6000_SELF_SERVICE và các chức năng cá nhân)
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT @UserGroupId, pm.[ProgramId], 1, 1, 0, 0, 0, 1
        FROM [dbo].[ProgramMenus] pm
        WHERE pm.[ProgramKey] = '6000_SELF_SERVICE' OR pm.[ParentProgramKey] = '6000_SELF_SERVICE';

        -- Quyền cơ bản xem trang cá nhân
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT @UserGroupId, pm.[ProgramId], 1, 0, 0, 0, 0, 0
        FROM [dbo].[ProgramMenus] pm
        WHERE pm.[ProgramKey] IN ('2000', '2030');

        PRINT N'-> Đã phân quyền chuẩn cho USER thường (Chỉ Cổng Tự Phục Vụ)';
    END

    -- Đồng bộ người dùng phòng ban HR và GA vào nhóm quyền tương ứng nếu chưa có
    IF @HrGroupId IS NOT NULL
    BEGIN
        -- Gán các user phòng ban HR (DepartmentCode = 'HR') vào nhóm HR_OFFICER nếu chưa thuộc nhóm nào ngoài User
        INSERT INTO [dbo].[UserGroupMapping] ([UserId], [GroupId])
        SELECT u.[UserId], @HrGroupId
        FROM [dbo].[Users] u
        WHERE (u.[DepartmentCode] = 'HR' OR u.[FullName] LIKE N'%Nhân sự%')
          AND u.[UserCode] NOT IN ('ADMIN', 'SYSTEM')
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[UserGroupMapping] ugm
              WHERE ugm.[UserId] = u.[UserId] AND ugm.[GroupId] = @HrGroupId
          );
    END

    IF @GaGroupId IS NOT NULL
    BEGIN
        -- Gán các user phòng ban GA (DepartmentCode IN ('GA', 'DEPT_GA')) vào nhóm GA_OFFICER
        INSERT INTO [dbo].[UserGroupMapping] ([UserId], [GroupId])
        SELECT u.[UserId], @GaGroupId
        FROM [dbo].[Users] u
        WHERE (u.[DepartmentCode] IN ('GA', 'DEPT_GA') OR u.[FullName] LIKE N'%Hành chính%')
          AND u.[UserCode] NOT IN ('ADMIN', 'SYSTEM')
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[UserGroupMapping] ugm
              WHERE ugm.[UserId] = u.[UserId] AND ugm.[GroupId] = @GaGroupId
          );
    END

    PRINT N'=== 8. CẬP NHẬT MẶC ĐỊNH SIDEBAR STYLE LUÔN LÀ LIGHT TRONG CSDL ===';
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'User_Theme_Settings')
    BEGIN
        UPDATE [dbo].[User_Theme_Settings]
        SET [SidebarStyle] = 'light'
        WHERE [SidebarStyle] != 'light' OR [SidebarStyle] IS NULL;
        PRINT N'-> Đã cập nhật tất cả SidebarStyle trong User_Theme_Settings thành light';
    END

    COMMIT TRANSACTION;
    PRINT N'======================================================';
    PRINT N'=== CẬP NHẬT DATABASE & PHÂN QUYỀN HOÀN TẤT THÀNH CÔNG! ===';
    PRINT N'======================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT N'LỖI MIGRATION: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
