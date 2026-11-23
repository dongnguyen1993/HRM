-- =========================================================================================
-- SCRIPT DEPLOYMENT CƠ SỞ DỮ LIỆU LÊN MÔI TRƯỜNG REAL (PRODUCTION)
-- Tên file: V20261123_REAL_PRODUCTION_DEPLOYMENT_SCRIPT.sql
-- Dự án: HRM Enterprise System (Phân hệ 3+1 Domains: SYS, HR, GA, ESS)
-- Ngày tạo: 2026-11-23
-- Mục đích: Đồng bộ cấu trúc CSDL môi trường REAL để tương thích 100% với phiên bản phát hành mới:
--   1. Chuẩn hóa 5 quyền chức năng chuẩn CRUD (Thêm IsUpdate, Xóa triệt để IsSave).
--   2. Đăng ký các Menu chương trình mới (Hồ sơ Nhân viên 2011, BaseTable Showcase 4010/4011).
--   3. Tách triệt để dbo.SYS_Users (Tài khoản) và dbo.HR_Employees (Hồ sơ Nhân sự).
--   4. Cập nhật View chuẩn hóa dbo.VW_HR_Employees.
-- Nguyên tắc an toàn: IDEMPOTENT (Chạy 1 hay nhiều lần đều an toàn), KHÔNG LÀM MẤT DỮ LIỆU.
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT N'================================================================================';
PRINT N'=== BẮT ĐẦU QUÁ TRÌNH CẬP NHẬT CSDL REAL CHO PHIÊN BẢN PUBLIC MỚI ===';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY
    -- =========================================================================================
    -- BƯỚC 1: CHUẨN HÓA 5 QUYỀN CHỨC NĂNG CRUD TRÊN BẢNG SYS_AuthorGroupMapping
    -- =========================================================================================
    PRINT N'[BƯỚC 1/4] Chuẩn hóa 5 quyền chức năng CRUD (IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint)...';

    -- 1.1 Thêm cột IsUpdate nếu chưa có
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'SYS_AuthorGroupMapping' AND COLUMN_NAME = 'IsUpdate'
    )
    BEGIN
        ALTER TABLE dbo.SYS_AuthorGroupMapping ADD IsUpdate BIT NOT NULL CONSTRAINT DF_SYS_AuthorGroupMapping_IsUpdate DEFAULT (0);
        PRINT N'   -> Đã thêm cột IsUpdate (mặc định 0).';
    END
    ELSE
    BEGIN
        PRINT N'   -> Cột IsUpdate đã tồn tại sẵn.';
    END;

    -- 1.2 Di chuyển dữ liệu quyền từ IsSave sang IsUpdate (nếu IsSave còn tồn tại) và xóa IsSave
    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'SYS_AuthorGroupMapping' AND COLUMN_NAME = 'IsSave'
    )
    BEGIN
        EXEC sp_executesql N'
            UPDATE dbo.SYS_AuthorGroupMapping
            SET IsUpdate = CASE WHEN IsUpdate = 1 OR IsSave = 1 THEN 1 ELSE 0 END;
        ';
        PRINT N'   -> Đã chuyển toàn bộ dữ liệu quyền từ IsSave sang IsUpdate.';

        -- Xóa Default Constraint của IsSave nếu có
        DECLARE @defConstraintIsSave NVARCHAR(200);
        SELECT @defConstraintIsSave = dc.name
        FROM sys.default_constraints dc
        JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE dc.parent_object_id = OBJECT_ID('dbo.SYS_AuthorGroupMapping')
          AND c.name = 'IsSave';

        IF @defConstraintIsSave IS NOT NULL
        BEGIN
            EXEC('ALTER TABLE dbo.SYS_AuthorGroupMapping DROP CONSTRAINT [' + @defConstraintIsSave + ']');
            PRINT N'   -> Đã xóa Default Constraint của IsSave.';
        END;

        ALTER TABLE dbo.SYS_AuthorGroupMapping DROP COLUMN IsSave;
        PRINT N'   -> Đã xóa hoàn toàn cột cũ IsSave khỏi bảng SYS_AuthorGroupMapping.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Cột IsSave đã được dọn sạch từ trước.';
    END;

    -- 1.3 Cấp đầy đủ 5 quyền cho Quản Trị Viên (GroupId = 1) trên mọi menu đang hoạt động
    UPDATE agm
    SET 
        agm.IsSearch = 1,
        agm.IsCreate = 1,
        agm.IsUpdate = 1,
        agm.IsDelete = 1,
        agm.IsPrint  = 1
    FROM dbo.SYS_AuthorGroupMapping agm
    WHERE agm.GroupId = 1;
    PRINT N'   -> Đã đồng bộ 5 quyền đầy đủ cho Quản Trị Viên (GroupId = 1).';


    -- =========================================================================================
    -- BƯỚC 2: ĐĂNG KÝ CÁC MENU MỚI VÀO BẢNG SYS_ProgramMenus & PHÂN QUYỀN
    -- =========================================================================================
    PRINT N'[BƯỚC 2/4] Kiểm tra và đăng ký Menu mới (Hồ sơ nhân viên & BaseTable Showcase)...';

    -- 2.1 Menu 2011_HR_EMPLOYEES (Hồ sơ Nhân viên)
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
        PRINT N'   -> Đã thêm menu 2011_HR_EMPLOYEES vào SYS_ProgramMenus.';
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
        PRINT N'   -> Đã cập nhật menu 2011_HR_EMPLOYEES.';
    END;

    -- Phân quyền menu 2011_HR_EMPLOYEES cho Admin (1) và các nhóm HR (3002, 3005, 3006 nếu có)
    DECLARE @ProgIdEmp INT;
    SELECT @ProgIdEmp = ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '2011_HR_EMPLOYEES';

    IF @ProgIdEmp IS NOT NULL
    BEGIN
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint)
        SELECT g.GroupId, @ProgIdEmp, 1, 1, 1, 1, 1
        FROM dbo.SYS_AuthorGroups g
        WHERE g.GroupId IN (1, 3002, 3005, 3006)
          AND NOT EXISTS (
              SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm
              WHERE agm.GroupId = g.GroupId AND agm.ProgramId = @ProgIdEmp
          );
    END;

    -- 2.2 Menu 4010_SYS_DESIGN & 4011_SYS_DESIGN_TABLE (BaseTable Showcase)
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '4010_SYS_DESIGN')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ProgramName, Level, ParentProgramKey, ProgramGroup, 
            UseFlag, MenuFlag, Path, SortOrder, CreatedBy, CreatedAt
        )
        VALUES (
            '4010_SYS_DESIGN', N'SYS Design', 2, '4000_SYS', 'SYS', 
            1, 1, '/sys/design', 4010, 'ADMIN', GETDATE()
        );
        PRINT N'   -> Đã thêm menu 4010_SYS_DESIGN.';
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '4011_SYS_DESIGN_TABLE')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ProgramName, Level, ParentProgramKey, ProgramGroup, 
            UseFlag, MenuFlag, Path, SortOrder, CreatedBy, CreatedAt
        )
        VALUES (
            '4011_SYS_DESIGN_TABLE', N'Bảng Dữ Liệu (BaseTable)', 3, '4010_SYS_DESIGN', 'SYS', 
            1, 1, '/sys/design/table', 4011, 'ADMIN', GETDATE()
        );
        PRINT N'   -> Đã thêm menu 4011_SYS_DESIGN_TABLE.';
    END;

    -- Cấp quyền menu 4010, 4011 cho Admin
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint)
    SELECT 1, pm.ProgramId, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.ProgramKey IN ('4010_SYS_DESIGN', '4011_SYS_DESIGN_TABLE')
      AND NOT EXISTS (
          SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm
          WHERE agm.GroupId = 1 AND agm.ProgramId = pm.ProgramId
      );


    -- =========================================================================================
    -- BƯỚC 3: TÁCH TRIỆT ĐỂ SYS_Users (TÀI KHOẢN) VÀ HR_Employees (HỒ SƠ NHÂN SỰ)
    -- =========================================================================================
    PRINT N'[BƯỚC 3/4] Tách bảng SYS_Users và HR_Employees theo chuẩn kiến trúc 3+1 Domains...';

    -- 3.1 Khởi tạo bảng dbo.HR_Employees nếu chưa có trên REAL
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
        PRINT N'   -> Đã khởi tạo bảng dbo.HR_Employees cùng toàn bộ Index hiệu năng.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Bảng dbo.HR_Employees đã tồn tại.';
    END;

    -- 3.2 Di chuyển / Đồng bộ an toàn toàn bộ dữ liệu nhân sự từ SYS_Users sang HR_Employees
    IF COL_LENGTH('dbo.SYS_Users', 'IdentityNumber') IS NOT NULL
    BEGIN
        PRINT N'   -> Tiến hành đồng bộ (MERGE) toàn bộ hồ sơ nhân sự từ SYS_Users sang HR_Employees...';
        EXEC sp_executesql N'
            MERGE dbo.HR_Employees AS target
            USING (
                SELECT 
                    u.UserId, u.UserCode, u.FullName, u.Email, u.IdentityNumber, u.BirthDate, u.Gender, u.Phone, u.Avatar,
                    u.DepartmentId, u.DepartmentCode, u.PositionId, u.PositionGrade, u.PositionRole,
                    u.Plant, u.Area, u.WorkLine, u.CostCenter, u.ManagerUserCode,
                    ISNULL(u.VendorName, ''INTERNAL'') AS VendorName, ISNULL(u.ContractType, ''OFFICIAL'') AS ContractType,
                    u.JoinDate, u.ProbationEndDate, u.ContractEndDate, u.ResignDate, u.BankName, u.BankAccountNumber,
                    ISNULL(u.IsPregnant, 0) AS IsPregnant, ISNULL(u.HasYoungChild, 0) AS HasYoungChild,
                    u.MaternityStartDate, u.MaternityEndDate, u.BioStarUserId, u.UserGroup,
                    u.MealDepartmentId, u.MealDepartmentCode, ISNULL(u.Status, 1) AS Status, ISNULL(u.UseFlag, 1) AS UseFlag,
                    u.CreatedAt, u.CreatedBy, u.UpdatedAt, u.UpdatedBy
                FROM dbo.SYS_Users u WITH (NOLOCK)
            ) AS source
            ON (target.UserCode = source.UserCode)
            WHEN MATCHED THEN
                UPDATE SET
                    target.UserId = source.UserId,
                    target.FullName = source.FullName,
                    target.Email = source.Email,
                    target.IdentityNumber = COALESCE(source.IdentityNumber, target.IdentityNumber),
                    target.BirthDate = COALESCE(source.BirthDate, target.BirthDate),
                    target.Gender = COALESCE(source.Gender, target.Gender),
                    target.Phone = COALESCE(source.Phone, target.Phone),
                    target.Avatar = COALESCE(source.Avatar, target.Avatar),
                    target.DepartmentId = COALESCE(source.DepartmentId, target.DepartmentId),
                    target.DepartmentCode = COALESCE(source.DepartmentCode, target.DepartmentCode),
                    target.PositionId = COALESCE(source.PositionId, target.PositionId),
                    target.PositionGrade = COALESCE(source.PositionGrade, target.PositionGrade),
                    target.PositionRole = COALESCE(source.PositionRole, target.PositionRole),
                    target.Plant = COALESCE(source.Plant, target.Plant),
                    target.Area = COALESCE(source.Area, target.Area),
                    target.WorkLine = COALESCE(source.WorkLine, target.WorkLine),
                    target.CostCenter = COALESCE(source.CostCenter, target.CostCenter),
                    target.ManagerUserCode = COALESCE(source.ManagerUserCode, target.ManagerUserCode),
                    target.VendorName = COALESCE(source.VendorName, target.VendorName),
                    target.ContractType = COALESCE(source.ContractType, target.ContractType),
                    target.JoinDate = COALESCE(source.JoinDate, target.JoinDate),
                    target.ProbationEndDate = COALESCE(source.ProbationEndDate, target.ProbationEndDate),
                    target.ContractEndDate = COALESCE(source.ContractEndDate, target.ContractEndDate),
                    target.ResignDate = COALESCE(source.ResignDate, target.ResignDate),
                    target.BankName = COALESCE(source.BankName, target.BankName),
                    target.BankAccountNumber = COALESCE(source.BankAccountNumber, target.BankAccountNumber),
                    target.IsPregnant = source.IsPregnant,
                    target.HasYoungChild = source.HasYoungChild,
                    target.MaternityStartDate = COALESCE(source.MaternityStartDate, target.MaternityStartDate),
                    target.MaternityEndDate = COALESCE(source.MaternityEndDate, target.MaternityEndDate),
                    target.BioStarUserId = COALESCE(source.BioStarUserId, target.BioStarUserId),
                    target.UserGroup = COALESCE(source.UserGroup, target.UserGroup),
                    target.MealDepartmentId = COALESCE(source.MealDepartmentId, target.MealDepartmentId),
                    target.MealDepartmentCode = COALESCE(source.MealDepartmentCode, target.MealDepartmentCode),
                    target.Status = source.Status,
                    target.UseFlag = source.UseFlag,
                    target.UpdatedAt = GETDATE(),
                    target.UpdatedBy = ''DEPLOYMENT_REAL''
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
        ';
        PRINT N'   -> Đã MERGE thành công toàn bộ hồ sơ nhân sự sang HR_Employees.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Các cột nhân sự trong SYS_Users đã được dọn sạch từ trước, bỏ qua MERGE.';
    END;

    -- 3.3 Cập nhật liên kết UserId cho mọi UserCode đã có tài khoản
    UPDATE e
    SET e.UserId = u.UserId
    FROM dbo.HR_Employees e
    INNER JOIN dbo.SYS_Users u ON e.UserCode = u.UserCode
    WHERE e.UserId IS NULL OR e.UserId <> u.UserId;
    PRINT N'   -> Đã đồng bộ liên kết UserId 1-1 giữa HR_Employees và SYS_Users.';

    -- 3.4 Xóa khóa ngoại FK_Users_MealDepartment (nếu có)
    IF OBJECT_ID('dbo.FK_Users_MealDepartment', 'F') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.SYS_Users DROP CONSTRAINT FK_Users_MealDepartment;
        PRINT N'   -> Đã xóa khóa ngoại FK_Users_MealDepartment.';
    END;

    -- 3.5 Xóa toàn bộ Default Constraints trên 29 cột nhân sự cũ của SYS_Users
    DECLARE @DropConstraintSql NVARCHAR(MAX) = N'';
    SELECT @DropConstraintSql += N'ALTER TABLE dbo.SYS_Users DROP CONSTRAINT [' + dc.name + N'];' + CHAR(13) + CHAR(10)
    FROM sys.default_constraints dc
    INNER JOIN sys.tables t ON dc.parent_object_id = t.object_id
    INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE t.name = 'SYS_Users'
      AND c.name IN (
        'DepartmentId', 'DepartmentCode', 'PositionId', 'PositionGrade', 'PositionRole',
        'MealDepartmentId', 'MealDepartmentCode', 'IdentityNumber', 'BirthDate', 'Gender',
        'Phone', 'BankName', 'BankAccountNumber', 'VendorName', 'ContractType',
        'ProbationEndDate', 'ContractEndDate', 'ResignDate', 'JoinDate', 'IsPregnant',
        'HasYoungChild', 'MaternityStartDate', 'MaternityEndDate', 'ManagerUserCode',
        'WorkLine', 'CostCenter', 'BioStarUserId', 'UserGroup', 'Avatar'
      );

    IF LEN(@DropConstraintSql) > 0
    BEGIN
        EXEC sp_executesql @DropConstraintSql;
        PRINT N'   -> Đã xóa Default Constraints trên 29 cột nhân sự cũ của SYS_Users.';
    END;

    -- 3.6 Xóa 29 cột nhân sự cũ khỏi dbo.SYS_Users
    DECLARE @DropColumnsSql NVARCHAR(MAX) = N'';
    DECLARE @ColsToDrop TABLE (ColName NVARCHAR(100));
    INSERT INTO @ColsToDrop (ColName) VALUES
        ('IdentityNumber'), ('BirthDate'), ('Gender'), ('Phone'), ('BankName'), ('BankAccountNumber'),
        ('DepartmentId'), ('PositionId'), ('VendorName'), ('ContractType'), ('ProbationEndDate'),
        ('ContractEndDate'), ('IsPregnant'), ('HasYoungChild'), ('MaternityStartDate'), ('MaternityEndDate'),
        ('ManagerUserCode'), ('WorkLine'), ('CostCenter'), ('BioStarUserId'), ('UserGroup'), ('Avatar'),
        ('JoinDate'), ('ResignDate'), ('DepartmentCode'), ('MealDepartmentId'), ('MealDepartmentCode'),
        ('PositionGrade'), ('PositionRole');

    SELECT @DropColumnsSql += N'ALTER TABLE dbo.SYS_Users DROP COLUMN [' + c.ColName + N'];' + CHAR(13) + CHAR(10)
    FROM @ColsToDrop c
    WHERE COL_LENGTH('dbo.SYS_Users', c.ColName) IS NOT NULL;

    IF LEN(@DropColumnsSql) > 0
    BEGIN
        EXEC sp_executesql @DropColumnsSql;
        PRINT N'   -> Đã xóa sạch 29 cột nhân sự cũ khỏi dbo.SYS_Users. Bảng SYS_Users giờ đây thuần khiết chỉ lưu 16 cột tài khoản!';
    END
    ELSE
    BEGIN
        PRINT N'   -> Các cột nhân sự cũ đã được dọn sạch từ trước.';
    END;

    COMMIT TRANSACTION;
    PRINT N'=== GIAO DỊCH CHÍNH HOÀN TẤT THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'[LỖI]: ' + @ErrMsg;
    THROW;
END CATCH;
GO

-- =========================================================================================
-- BƯỚC 4: TÁI TẠO VIEW CHUẨN HÓA dbo.VW_HR_Employees
-- =========================================================================================
PRINT N'[BƯỚC 4/4] Khởi tạo / Làm mới View dbo.VW_HR_Employees...';
IF OBJECT_ID('dbo.VW_HR_Employees', 'V') IS NOT NULL
    DROP VIEW dbo.VW_HR_Employees;
GO

CREATE VIEW dbo.VW_HR_Employees AS
SELECT 
    e.EmployeeId, e.UserId, e.UserCode, e.FullName, e.Email, e.IdentityNumber, e.BirthDate, e.Gender, e.Phone, e.Avatar,
    e.DepartmentId, d.DepartmentCode, d.DepartmentName, e.PositionId, p.PositionCode, p.PositionName,
    e.PositionGrade, e.PositionRole, e.Plant, e.Area, e.WorkLine, e.CostCenter, e.ManagerUserCode,
    m.FullName AS ManagerName, e.VendorName, e.ContractType, e.JoinDate, e.ProbationEndDate, e.ContractEndDate, e.ResignDate,
    e.BankName, e.BankAccountNumber, e.IsPregnant, e.HasYoungChild, e.MaternityStartDate, e.MaternityEndDate,
    e.BioStarUserId, e.UserGroup, e.MealDepartmentId, e.MealDepartmentCode, e.Status, e.UseFlag,
    u.Status AS AccountStatus, u.CreatedAt AS AccountCreatedAt
FROM dbo.HR_Employees e WITH (NOLOCK)
LEFT JOIN dbo.SYS_Users u WITH (NOLOCK) ON e.UserId = u.UserId
LEFT JOIN dbo.HR_Departments d WITH (NOLOCK) ON e.DepartmentId = d.DepartmentId
LEFT JOIN dbo.HR_PositionsRole p WITH (NOLOCK) ON e.PositionId = p.PositionId
LEFT JOIN dbo.HR_Employees m WITH (NOLOCK) ON e.ManagerUserCode = m.UserCode;
GO

PRINT N'================================================================================';
PRINT N'=== TẤT CẢ CÁC BƯỚC MIGRATION LÊN MÔI TRƯỜNG REAL ĐÃ HOÀN TẤT 100%! ===';
PRINT N'================================================================================';
