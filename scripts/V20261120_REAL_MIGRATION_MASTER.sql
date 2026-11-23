-- =========================================================================================
-- MASTER SCRIPT BỔ SUNG CHO MÔI TRƯỜNG REAL (PRODUCTION)
-- Tên script: V20261120_REAL_MIGRATION_MASTER.sql
-- Mục đích: Đồng bộ toàn bộ các cập nhật mới nhất cho phân hệ SYS, HR và GA lên Real:
--   1. Mở rộng độ dài cột TimeFrom, TimeTo (GA_VisitorDetails) tránh lỗi tràn chuỗi khi import.
--   2. Chuẩn hóa Menu 1006_ESS_VISITOR_REGISTRATION và phân quyền USERS/GA_MGMT.
--   3. Tạo bảng mới dbo.HR_Employees và chuyển toàn bộ hồ sơ nhân viên từ SYS_Users sang.
--   4. Tạo View chuẩn hóa dbo.VW_HR_Employees phục vụ các báo cáo và phân hệ HR.
-- Nguyên tắc an toàn: Chạy Idempotent (chạy 1 hay nhiều lần đều an toàn), KHÔNG DROP hay mất dữ liệu.
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'================================================================================';
    PRINT N'=== BẮT ĐẦU CẬP NHẬT ĐỒNG BỘ CSDL LÊN MÔI TRƯỜNG REAL ===';
    PRINT N'================================================================================';

    -- -----------------------------------------------------------------------------------------
    -- MỤC 1: MỞ RỘNG ĐỘ DÀI CỘT GIỜ GA_VisitorDetails (NVARCHAR(20))
    -- -----------------------------------------------------------------------------------------
    PRINT N'[1/4] Kiểm tra và mở rộng cột TimeFrom, TimeTo trong GA_VisitorDetails...';

    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'GA_VisitorDetails' 
          AND COLUMN_NAME = 'TimeFrom' 
          AND (CHARACTER_MAXIMUM_LENGTH < 20 OR CHARACTER_MAXIMUM_LENGTH IS NULL)
    )
    BEGIN
        ALTER TABLE dbo.GA_VisitorDetails ALTER COLUMN TimeFrom NVARCHAR(20) NULL;
        PRINT N'   -> Đã mở rộng cột TimeFrom lên NVARCHAR(20).';
    END;

    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'GA_VisitorDetails' 
          AND COLUMN_NAME = 'TimeTo' 
          AND (CHARACTER_MAXIMUM_LENGTH < 20 OR CHARACTER_MAXIMUM_LENGTH IS NULL)
    )
    BEGIN
        ALTER TABLE dbo.GA_VisitorDetails ALTER COLUMN TimeTo NVARCHAR(20) NULL;
        PRINT N'   -> Đã mở rộng cột TimeTo lên NVARCHAR(20).';
    END;

    -- -----------------------------------------------------------------------------------------
    -- MỤC 2: CHUẨN HÓA MENU ĐĂNG KÝ KHÁCH (1006_ESS_VISITOR_REGISTRATION) & PHÂN QUYỀN
    -- -----------------------------------------------------------------------------------------
    PRINT N'[2/4] Kiểm tra và chuẩn hóa Menu Đăng ký khách & Phân quyền...';

    DECLARE @VisitorRegProgId INT;
    SELECT TOP 1 @VisitorRegProgId = ProgramId
    FROM dbo.SYS_ProgramMenus
    WHERE ProgramKey IN ('1006_ESS_VISITOR_REGISTRATION', '1006_GA_VISITOR_REGISTRATION', '3004_GA_VISITOR_REGISTRATION')
       OR Path = '/ess/visitor-registration';

    IF @VisitorRegProgId IS NOT NULL
    BEGIN
        UPDATE dbo.SYS_ProgramMenus
        SET ProgramKey       = '1006_ESS_VISITOR_REGISTRATION',
            ProgramName      = N'Đăng ký khách vào cổng',
            ParentProgramKey = '1000_ESS',
            ProgramGroup     = 'ESS',
            Path             = '/ess/visitor-registration',
            Icon             = 'user-add',
            UseFlag          = 1,
            MenuFlag         = 1,
            UpdatedAt        = GETDATE(),
            UpdatedBy        = 'MIGRATION_REAL'
        WHERE ProgramId = @VisitorRegProgId;

        PRINT N'   -> Đã chuẩn hóa Menu ID ' + CAST(@VisitorRegProgId AS NVARCHAR(10)) + N' -> 1006_ESS_VISITOR_REGISTRATION.';

        -- Cấp quyền cho USERS (GroupId: 2002)
        IF EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroups WHERE GroupId = 2002)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 2002 AND ProgramId = @VisitorRegProgId)
            BEGIN
                UPDATE dbo.SYS_AuthorGroupMapping
                SET IsSearch = 1, IsCreate = 1 = 1, IsDelete = 0, IsSave = 1, IsPrint = 1
                WHERE GroupId = 2002 AND ProgramId = @VisitorRegProgId;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsDelete, IsSave, IsPrint)
                VALUES (2002, @VisitorRegProgId, 1, 1, 1, 0, 1);
            END;
            PRINT N'   -> Đã cập nhật quyền Đăng ký khách cho nhóm USERS (2002).';
        END;

        -- Cấp quyền cho GA_MGMT (GroupId: 3003)
        IF EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroups WHERE GroupId = 3003)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @VisitorRegProgId)
            BEGIN
                UPDATE dbo.SYS_AuthorGroupMapping
                SET IsSearch = 1, IsCreate = 1 = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
                WHERE GroupId = 3003 AND ProgramId = @VisitorRegProgId;
            END
            ELSE
            BEGIN
                INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsDelete, IsSave, IsPrint)
                VALUES (3003, @VisitorRegProgId, 1, 1, 1, 1, 1);
            END;
            PRINT N'   -> Đã cập nhật quyền Đăng ký khách cho nhóm GA_MGMT (3003).';
        END;
    END;

    -- -----------------------------------------------------------------------------------------
    -- MỤC 3: TẠO BẢNG dbo.HR_Employees & CHUYỂN DỮ LIỆU TỪ dbo.SYS_Users SANG
    -- -----------------------------------------------------------------------------------------
    PRINT N'[3/4] Kiểm tra và tạo bảng dbo.HR_Employees...';

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

        PRINT N'   -> Đã tạo mới bảng dbo.HR_Employees cùng các chỉ mục hiệu năng.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Bảng dbo.HR_Employees đã tồn tại.';
    END;

    -- Đồng bộ dữ liệu từ SYS_Users sang HR_Employees
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
    PRINT N'   -> Đã đồng bộ thành công dữ liệu hồ sơ nhân viên. Tổng số bản ghi trong HR_Employees: ' + CAST(@TotalEmps AS NVARCHAR(10));

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'[SUCCESS] HOÀN TẤT CÁC BƯỚC CẬP NHẬT DỮ LIỆU VÀ BẢNG THÀNH CÔNG!';
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
-- MỤC 4: TẠO VIEW dbo.VW_HR_Employees (PHẢI NẰM RIÊNG SAU LỆNH GO ĐỂ SSMS BIÊN DỊCH TRỌN VẸN)
-- -----------------------------------------------------------------------------------------
PRINT N'[4/4] Đang khởi tạo View dbo.VW_HR_Employees...';
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
