-- =========================================================================================
-- Migration: V20261123_SEPARATE_SYS_USERS_AND_HR_EMPLOYEES.sql
-- Description: Tách triệt để SYS_Users (chỉ lưu tài khoản xác thực) và HR_Employees (hồ sơ nhân sự)
--              1. Đồng bộ và liên kết toàn bộ dữ liệu từ dbo.SYS_Users sang dbo.HR_Employees (bao gồm SECURITY 1111111)
--              2. Xóa khóa ngoại FK_Users_MealDepartment
--              3. Xóa các ràng buộc mặc định (DEFAULT constraints) trên 29 cột nhân sự trong SYS_Users
--              4. Xóa 29 cột hồ sơ nhân sự khỏi dbo.SYS_Users, giữ lại đúng 16 cột tài khoản xác thực
--              5. Cập nhật lại View dbo.VW_HR_Employees
-- Author: HRM Enterprise Architecture Team
-- Date: 2026-11-23
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== BƯỚC 1: ĐẢM BẢO BẢNG dbo.HR_Employees TỒN TẠI VÀ ĐỒNG BỘ DỮ LIỆU TỪ dbo.SYS_Users ===';

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
    END;

    -- Kiểm tra nếu SYS_Users vẫn còn các cột nhân sự thì MERGE dữ liệu sang HR_Employees
    IF COL_LENGTH('dbo.SYS_Users', 'IdentityNumber') IS NOT NULL
    BEGIN
        MERGE dbo.HR_Employees AS target
        USING (
            SELECT 
                u.UserId, u.UserCode, u.FullName, u.Email, u.IdentityNumber, u.BirthDate, u.Gender, u.Phone, u.Avatar,
                u.DepartmentId, u.DepartmentCode, u.PositionId, u.PositionGrade, u.PositionRole,
                u.Plant, u.Area, u.WorkLine, u.CostCenter, u.ManagerUserCode,
                ISNULL(u.VendorName, 'INTERNAL') AS VendorName, ISNULL(u.ContractType, 'OFFICIAL') AS ContractType,
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
                target.UpdatedBy = 'MIGRATION_SEPARATION'
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
        PRINT N'Đã MERGE thành công dữ liệu hồ sơ nhân sự từ SYS_Users sang HR_Employees.';
    END;

    -- Đồng bộ liên kết UserId cho mọi UserCode đã có tài khoản trong SYS_Users
    UPDATE e
    SET e.UserId = u.UserId
    FROM dbo.HR_Employees e
    INNER JOIN dbo.SYS_Users u ON e.UserCode = u.UserCode
    WHERE e.UserId IS NULL OR e.UserId <> u.UserId;
    PRINT N'Đã đồng bộ liên kết UserId giữa HR_Employees và SYS_Users.';

    PRINT N'=== BƯỚC 2: XÓA KHÓA NGOẠI FK_Users_MealDepartment ===';
    IF OBJECT_ID('dbo.FK_Users_MealDepartment', 'F') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.SYS_Users DROP CONSTRAINT FK_Users_MealDepartment;
        PRINT N'Đã xóa khóa ngoại FK_Users_MealDepartment.';
    END;

    PRINT N'=== BƯỚC 3: XÓA TOÀN BỘ RÀNG BUỘC DEFAULT TRÊN 29 CỘT NHÂN SỰ CỦA SYS_Users ===';
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
        PRINT N'Đã xóa các Default Constraints trên 29 cột nhân sự: ' + CHAR(13) + CHAR(10) + @DropConstraintSql;
    END;

    PRINT N'=== BƯỚC 4: XÓA 29 CỘT HỒ SƠ NHÂN SỰ KHỎI dbo.SYS_Users ===';
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
        PRINT N'Đã xóa 29 cột nhân sự thành công.';
    END
    ELSE
    BEGIN
        PRINT N'Các cột nhân sự đã được xóa từ trước.';
    END;

    COMMIT TRANSACTION;
    PRINT N'=== GIAO DỊCH HOÀN TẤT THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'LỖI MIGRATION: ' + @ErrMsg;
    THROW;
END CATCH;
GO

PRINT N'=== BƯỚC 5: TÁI TẠO VIEW dbo.VW_HR_Employees ===';
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
