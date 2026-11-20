-- =========================================================================================
-- SCRIPT BỔ SUNG DÀNH RIÊNG CHO PHÂN HỆ SYS VÀ HR TRÊN MÔI TRƯỜNG REAL (PRODUCTION)
-- Tên file: V20261120_REAL_MIGRATION_SYS_HR_ONLY.sql
-- Phạm vi: Chỉ áp dụng cho SYS và HR (TUYỆT ĐỐI KHÔNG TÁC ĐỘNG VÀO PHÂN HỆ GA)
-- Mục đích:
--   1. Tạo bảng mới dbo.HR_Employees (Master Data Nhân sự) & các chỉ mục hiệu năng.
--   2. Di chuyển / Đồng bộ an toàn toàn bộ hồ sơ nhân viên từ dbo.SYS_Users sang dbo.HR_Employees.
--   3. Cấp toàn quyền thao tác (Search, Create, Update, Delete, Save, Print) cho Nhóm Quản Trị
--      Nhân Sự (HR_MGMT - GroupId 3006 & HR Officer - GroupId 3002) trên toàn bộ 11 màn hình HR.
--   4. Khởi tạo View chuẩn hóa dbo.VW_HR_Employees để phục vụ phân hệ HR.
-- Nguyên tắc an toàn: Idempotent (chạy 1 hay nhiều lần đều an toàn), KHÔNG DROP hay mất dữ liệu.
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'================================================================================';
    PRINT N'=== BẮT ĐẦU CẬP NHẬT PHÂN HỆ SYS VÀ HR TRÊN CSDL REAL ===';
    PRINT N'================================================================================';

    -- -----------------------------------------------------------------------------------------
    -- MỤC 1: TẠO BẢNG dbo.HR_Employees NẾU CHƯA CÓ TRÊN REAL
    -- -----------------------------------------------------------------------------------------
    PRINT N'[1/3] Kiểm tra và khởi tạo bảng dbo.HR_Employees...';

    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_Employees')
    BEGIN
        CREATE TABLE [dbo].[HR_Employees] (
            [EmployeeId]          INT IDENTITY(1,1) NOT NULL,
            [UserId]              INT NULL,
            [UserCode]            NVARCHAR(50) NOT NULL,
            [FullName]            NVARCHAR(150) NOT NULL,
            [Email]               VARCHAR(150) NULL,
            [IdentityNumber]      NVARCHAR(20) NULL,
            [BirthDate]           DATE NULL,
            [Gender]              NVARCHAR(10) NULL,
            [Phone]               NVARCHAR(20) NULL,
            [Avatar]              NVARCHAR(500) NULL,
            [DepartmentId]        INT NULL,
            [DepartmentCode]      NVARCHAR(50) NULL,
            [PositionId]          INT NULL,
            [PositionGrade]       NVARCHAR(50) NULL,
            [PositionRole]        NVARCHAR(50) NULL DEFAULT ('MEMBER'),
            [Plant]               NVARCHAR(50) NULL,
            [Area]                NVARCHAR(255) NULL,
            [WorkLine]            NVARCHAR(50) NULL DEFAULT ('SMT_LINE_01'),
            [CostCenter]          NVARCHAR(50) NULL,
            [ManagerUserCode]     NVARCHAR(50) NULL,
            [VendorName]          NVARCHAR(50) NOT NULL DEFAULT ('INTERNAL'),
            [ContractType]        NVARCHAR(50) NOT NULL DEFAULT ('OFFICIAL'),
            [JoinDate]            DATE NULL,
            [ProbationEndDate]    DATE NULL,
            [ContractEndDate]     DATE NULL,
            [ResignDate]          DATE NULL,
            [BankName]            NVARCHAR(100) NULL,
            [BankAccountNumber]   NVARCHAR(50) NULL,
            [IsPregnant]          BIT NOT NULL DEFAULT (0),
            [HasYoungChild]       BIT NOT NULL DEFAULT (0),
            [MaternityStartDate]  DATE NULL,
            [MaternityEndDate]    DATE NULL,
            [BioStarUserId]       VARCHAR(50) NULL,
            [UserGroup]           NVARCHAR(100) NULL,
            [MealDepartmentId]    INT NULL,
            [MealDepartmentCode]  NVARCHAR(500) NULL,
            [Status]              TINYINT NOT NULL DEFAULT (1),
            [UseFlag]             INT NOT NULL DEFAULT (1),
            [CreatedAt]           DATETIME2 NOT NULL DEFAULT (GETUTCDATE()),
            [CreatedBy]           NVARCHAR(50) NULL,
            [UpdatedAt]           DATETIME2 NULL,
            [UpdatedBy]           NVARCHAR(50) NULL,

            CONSTRAINT [PK_HR_Employees] PRIMARY KEY CLUSTERED ([EmployeeId] ASC),
            CONSTRAINT [FK_HR_Employees_Users] FOREIGN KEY ([UserId]) REFERENCES [dbo].[SYS_Users] ([UserId]) ON DELETE SET NULL
        );

        CREATE UNIQUE NONCLUSTERED INDEX [UQ_HR_Employees_UserCode] ON [dbo].[HR_Employees] ([UserCode]);
        CREATE NONCLUSTERED INDEX [IX_HR_Employees_UserId] ON [dbo].[HR_Employees] ([UserId]);
        CREATE NONCLUSTERED INDEX [IX_HR_Employees_DeptId] ON [dbo].[HR_Employees] ([DepartmentId]);
        CREATE NONCLUSTERED INDEX [IX_HR_Employees_DeptCode] ON [dbo].[HR_Employees] ([DepartmentCode]);
        CREATE NONCLUSTERED INDEX [IX_HR_Employees_BioStar] ON [dbo].[HR_Employees] ([BioStarUserId]) WHERE [BioStarUserId] IS NOT NULL;
        CREATE NONCLUSTERED INDEX [IX_HR_Employees_Plant] ON [dbo].[HR_Employees] ([Plant]);

        PRINT N'   -> Đã tạo mới thành công bảng dbo.HR_Employees cùng các chỉ mục hiệu năng.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Bảng dbo.HR_Employees đã tồn tại. Bỏ qua bước tạo bảng.';
    END;

    -- Đồng bộ dữ liệu hồ sơ nhân viên từ SYS_Users sang HR_Employees bằng MERGE an toàn
    MERGE dbo.HR_Employees AS target
    USING (
        SELECT 
            u.UserId,
            u.UserCode,
            u.FullName,
            u.Email,
            u.IdentityNumber,
            u.BirthDate,
            u.Gender,
            u.Phone,
            u.Avatar,
            u.DepartmentId,
            u.DepartmentCode,
            u.PositionId,
            u.PositionGrade,
            u.PositionRole,
            u.Plant,
            u.Area,
            u.WorkLine,
            u.CostCenter,
            u.ManagerUserCode,
            ISNULL(u.VendorName, 'INTERNAL') AS VendorName,
            ISNULL(u.ContractType, 'OFFICIAL') AS ContractType,
            u.JoinDate,
            u.ProbationEndDate,
            u.ContractEndDate,
            u.ResignDate,
            u.BankName,
            u.BankAccountNumber,
            ISNULL(u.IsPregnant, 0) AS IsPregnant,
            ISNULL(u.HasYoungChild, 0) AS HasYoungChild,
            u.MaternityStartDate,
            u.MaternityEndDate,
            u.BioStarUserId,
            u.UserGroup,
            u.MealDepartmentId,
            u.MealDepartmentCode,
            ISNULL(u.Status, 1) AS Status,
            ISNULL(u.UseFlag, 1) AS UseFlag,
            u.CreatedAt,
            u.CreatedBy,
            u.UpdatedAt,
            u.UpdatedBy
        FROM dbo.SYS_Users u WITH (NOLOCK)
    ) AS source
    ON (target.UserCode = source.UserCode)
    WHEN MATCHED THEN
        UPDATE SET
            target.UserId             = source.UserId,
            target.FullName           = source.FullName,
            target.Email              = source.Email,
            target.IdentityNumber     = source.IdentityNumber,
            target.BirthDate          = source.BirthDate,
            target.Gender             = source.Gender,
            target.Phone              = source.Phone,
            target.Avatar             = source.Avatar,
            target.DepartmentId       = source.DepartmentId,
            target.DepartmentCode     = source.DepartmentCode,
            target.PositionId         = source.PositionId,
            target.PositionGrade      = source.PositionGrade,
            target.PositionRole       = source.PositionRole,
            target.Plant              = source.Plant,
            target.Area               = source.Area,
            target.WorkLine           = source.WorkLine,
            target.CostCenter         = source.CostCenter,
            target.ManagerUserCode    = source.ManagerUserCode,
            target.VendorName         = source.VendorName,
            target.ContractType       = source.ContractType,
            target.JoinDate           = source.JoinDate,
            target.ProbationEndDate   = source.ProbationEndDate,
            target.ContractEndDate    = source.ContractEndDate,
            target.ResignDate         = source.ResignDate,
            target.BankName           = source.BankName,
            target.BankAccountNumber  = source.BankAccountNumber,
            target.IsPregnant         = source.IsPregnant,
            target.HasYoungChild      = source.HasYoungChild,
            target.MaternityStartDate = source.MaternityStartDate,
            target.MaternityEndDate   = source.MaternityEndDate,
            target.BioStarUserId      = source.BioStarUserId,
            target.UserGroup          = source.UserGroup,
            target.MealDepartmentId   = source.MealDepartmentId,
            target.MealDepartmentCode = source.MealDepartmentCode,
            target.Status             = source.Status,
            target.UseFlag            = source.UseFlag,
            target.UpdatedAt          = GETDATE(),
            target.UpdatedBy          = 'MIGRATION_REAL'
    WHEN NOT MATCHED THEN
        INSERT (
            UserId, UserCode, FullName, Email, IdentityNumber, BirthDate, Gender, Phone, Avatar,
            DepartmentId, DepartmentCode, PositionId, PositionGrade, PositionRole,
            Plant, Area, WorkLine, CostCenter, ManagerUserCode, VendorName, ContractType,
            JoinDate, ProbationEndDate, ContractEndDate, ResignDate, BankName, BankAccountNumber,
            IsPregnant, HasYoungChild, MaternityStartDate, MaternityEndDate, BioStarUserId,
            UserGroup, MealDepartmentId, MealDepartmentCode, Status, UseFlag,
            CreatedAt, CreatedBy, UpdatedAt, UpdatedBy
        )
        VALUES (
            source.UserId, source.UserCode, source.FullName, source.Email, source.IdentityNumber, source.BirthDate, source.Gender, source.Phone, source.Avatar,
            source.DepartmentId, source.DepartmentCode, source.PositionId, source.PositionGrade, source.PositionRole,
            source.Plant, source.Area, source.WorkLine, source.CostCenter, source.ManagerUserCode, source.VendorName, source.ContractType,
            source.JoinDate, source.ProbationEndDate, source.ContractEndDate, source.ResignDate, source.BankName, source.BankAccountNumber,
            source.IsPregnant, source.HasYoungChild, source.MaternityStartDate, source.MaternityEndDate, source.BioStarUserId,
            source.UserGroup, source.MealDepartmentId, source.MealDepartmentCode, source.Status, source.UseFlag,
            source.CreatedAt, source.CreatedBy, source.UpdatedAt, source.UpdatedBy
        );

    DECLARE @TotalEmps INT = (SELECT COUNT(1) FROM dbo.HR_Employees);
    PRINT N'   -> Đã đồng bộ thành công hồ sơ. Tổng số nhân viên trong dbo.HR_Employees: ' + CAST(@TotalEmps AS NVARCHAR(10));

    -- -----------------------------------------------------------------------------------------
    -- MỤC 2: ĐĂNG KÝ MENU VÀ CẤP ĐẦY ĐỦ QUYỀN CHO CÁC NHÓM QUẢN TRỊ & NHÂN SỰ
    -- -----------------------------------------------------------------------------------------
    PRINT N'[2/3] Đăng ký màn hình Hồ sơ Nhân viên (2011_HR_EMPLOYEES) và cập nhật quyền hạn...';

    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '2011_HR_EMPLOYEES')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ProgramName, [Level], ParentProgramKey, ProgramGroup,
            UseFlag, MenuFlag, SortOrder, [Path], ApiUrl, Icon, CreatedAt, CreatedBy
        )
        VALUES (
            '2011_HR_EMPLOYEES', N'Hồ sơ Nhân viên', 2, '2000_HR', 'HR',
            1, 1, 2011, '/hr/employees', '/api/hr/employees', 'UserOutlined', GETDATE(), 'ADMIN'
        );
        PRINT N'   -> Đã thêm menu 2011_HR_EMPLOYEES vào dbo.SYS_ProgramMenus.';
    END
    ELSE
    BEGIN
        UPDATE dbo.SYS_ProgramMenus
        SET ProgramName = N'Hồ sơ Nhân viên',
            [Level] = 2,
            ParentProgramKey = '2000_HR',
            ProgramGroup = 'HR',
            UseFlag = 1,
            MenuFlag = 1,
            SortOrder = 2011,
            [Path] = '/hr/employees',
            ApiUrl = '/api/hr/employees',
            Icon = 'UserOutlined',
            UpdatedAt = GETDATE(),
            UpdatedBy = 'ADMIN'
        WHERE ProgramKey = '2011_HR_EMPLOYEES';
        PRINT N'   -> Đã cập nhật menu 2011_HR_EMPLOYEES trong dbo.SYS_ProgramMenus.';
    END;

    -- Danh sách nhóm quản trị & HR: GroupId 1 (Admin), 3005 (IT), 3002 (HR Officer), 3006 (HR_MGMT)
    DECLARE @HrGroups TABLE (GroupId INT);
    INSERT INTO @HrGroups (GroupId)
    SELECT GroupId FROM dbo.SYS_AuthorGroups WHERE GroupId IN (1, 3002, 3005, 3006);

    -- Cấp toàn quyền (Search, Create, Update, Delete, Save, Print) cho tất cả các menu thuộc phân hệ HR
    MERGE dbo.SYS_AuthorGroupMapping AS target
    USING (
        SELECT g.GroupId, p.ProgramId
        FROM @HrGroups g
        CROSS JOIN dbo.SYS_ProgramMenus p
        WHERE p.ProgramGroup = 'HR' AND p.UseFlag = 1
    ) AS source
    ON (target.GroupId = source.GroupId AND target.ProgramId = source.ProgramId)
    WHEN MATCHED THEN
        UPDATE SET 
            IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
    WHEN NOT MATCHED THEN
        INSERT (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (source.GroupId, source.ProgramId, 1, 1, 1, 1, 1, 1);

    PRINT N'   -> Đã cấp toàn quyền cho nhóm Quản Trị Nhân Sự trên toàn bộ 11 màn hình HR.';

    -- 2.4. Chuẩn hóa khoảng trắng đầu cuối (Trim) của UserCode
    ALTER TABLE dbo.SYS_UserThemeSettings NOCHECK CONSTRAINT FK_UserTheme_UserCode;
    UPDATE dbo.SYS_Users SET UserCode = LTRIM(RTRIM(UserCode)) WHERE UserCode <> LTRIM(RTRIM(UserCode));
    UPDATE dbo.SYS_UserThemeSettings SET UserCode = LTRIM(RTRIM(UserCode)) WHERE UserCode <> LTRIM(RTRIM(UserCode));
    UPDATE dbo.HR_Employees SET UserCode = LTRIM(RTRIM(UserCode)) WHERE UserCode <> LTRIM(RTRIM(UserCode));
    ALTER TABLE dbo.SYS_UserThemeSettings CHECK CONSTRAINT FK_UserTheme_UserCode;
    PRINT N'   -> Đã chuẩn hóa khoảng trắng thừa trong UserCode.';

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'[SUCCESS] HOÀN TẤT CẬP NHẬT DỮ LIỆU SYS VÀ HR THÀNH CÔNG!';
    PRINT N'================================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO

-- -----------------------------------------------------------------------------------------
-- MỤC 3: TẠO VIEW dbo.VW_HR_Employees (ĐẶT SAU LỆNH GO ĐỂ BIÊN DỊCH TRỌN VẸN)
-- -----------------------------------------------------------------------------------------
PRINT N'[3/3] Đang khởi tạo View dbo.VW_HR_Employees...';
GO

IF OBJECT_ID('dbo.VW_HR_Employees', 'V') IS NOT NULL
    DROP VIEW dbo.VW_HR_Employees;
GO

CREATE VIEW dbo.VW_HR_Employees AS
SELECT 
    e.EmployeeId,
    e.UserId,
    e.UserCode,
    e.FullName,
    e.Email,
    e.IdentityNumber,
    e.BirthDate,
    e.Gender,
    e.Phone,
    e.Avatar,
    e.DepartmentId,
    d.DepartmentCode,
    d.DepartmentName,
    e.PositionId,
    p.PositionCode,
    p.PositionName,
    e.PositionGrade,
    e.PositionRole,
    e.Plant,
    e.Area,
    e.WorkLine,
    e.CostCenter,
    e.ManagerUserCode,
    m.FullName AS ManagerName,
    e.VendorName,
    e.ContractType,
    e.JoinDate,
    e.ProbationEndDate,
    e.ContractEndDate,
    e.ResignDate,
    e.BankName,
    e.BankAccountNumber,
    e.IsPregnant,
    e.HasYoungChild,
    e.MaternityStartDate,
    e.MaternityEndDate,
    e.BioStarUserId,
    e.UserGroup,
    e.MealDepartmentId,
    e.MealDepartmentCode,
    e.Status,
    e.UseFlag,
    u.Status AS AccountStatus,
    u.CreatedAt AS AccountCreatedAt
FROM dbo.HR_Employees e WITH (NOLOCK)
LEFT JOIN dbo.SYS_Users u WITH (NOLOCK) ON e.UserId = u.UserId
LEFT JOIN dbo.HR_Departments d WITH (NOLOCK) ON e.DepartmentId = d.DepartmentId
LEFT JOIN dbo.HR_PositionsRole p WITH (NOLOCK) ON e.PositionId = p.PositionId
LEFT JOIN dbo.HR_Employees m WITH (NOLOCK) ON e.ManagerUserCode = m.UserCode;
GO

PRINT N'[SUCCESS] Đã tạo thành công View dbo.VW_HR_Employees!';
GO

-- =========================================================================================
-- KIỂM TRA HẬU MIGRATION TRÊN REAL (POST-MIGRATION VERIFICATION)
-- =========================================================================================
PRINT N'================================================================================';
PRINT N'=== KẾT QUẢ KIỂM TRA SAU KHI CHẠY TRÊN REAL ===';
PRINT N'================================================================================';

SELECT COUNT(1) AS [1. Tong_So_Nhan_Vien_HR_Employees] FROM dbo.HR_Employees;
SELECT COUNT(1) AS [2. Tong_So_Ban_Ghi_View_VW_HR_Employees] FROM dbo.VW_HR_Employees;
SELECT ProgramId, ProgramKey, ProgramName, [Path], SortOrder FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '2011_HR_EMPLOYEES';
SELECT g.GroupName, m.IsSearch, m.IsCreate, m.IsUpdate, m.IsDelete, m.IsSave, m.IsPrint
FROM dbo.SYS_AuthorGroupMapping m 
INNER JOIN dbo.SYS_AuthorGroups g ON m.GroupId = g.GroupId 
WHERE m.ProgramId = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '2011_HR_EMPLOYEES');
GO
