-- =========================================================================================
-- Migration: V20261120_03__Create_HR_Employees_Table_And_Migrate_Data.sql
-- Description: BƯỚC 1 - Tạo bảng mới dbo.HR_Employees (Hồ sơ nhân sự) theo chuẩn kiến trúc
--              3+1 Domains và đồng bộ dữ liệu hồ sơ nhân sự từ dbo.SYS_Users sang.
-- Author: HRM Enterprise Architecture Team
-- Date: 2026-11-20
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
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
            target.UserId = source.UserId, target.FullName = source.FullName, target.Email = source.Email,
            target.IdentityNumber = source.IdentityNumber, target.BirthDate = source.BirthDate, target.Gender = source.Gender,
            target.Phone = source.Phone, target.Avatar = source.Avatar, target.DepartmentId = source.DepartmentId,
            target.DepartmentCode = source.DepartmentCode, target.PositionId = source.PositionId,
            target.PositionGrade = source.PositionGrade, target.PositionRole = source.PositionRole,
            target.Plant = source.Plant, target.Area = source.Area, target.WorkLine = source.WorkLine,
            target.CostCenter = source.CostCenter, target.ManagerUserCode = source.ManagerUserCode,
            target.VendorName = source.VendorName, target.ContractType = source.ContractType,
            target.JoinDate = source.JoinDate, target.ProbationEndDate = source.ProbationEndDate,
            target.ContractEndDate = source.ContractEndDate, target.ResignDate = source.ResignDate,
            target.BankName = source.BankName, target.BankAccountNumber = source.BankAccountNumber,
            target.IsPregnant = source.IsPregnant, target.HasYoungChild = source.HasYoungChild,
            target.MaternityStartDate = source.MaternityStartDate, target.MaternityEndDate = source.MaternityEndDate,
            target.BioStarUserId = source.BioStarUserId, target.UserGroup = source.UserGroup,
            target.MealDepartmentId = source.MealDepartmentId, target.MealDepartmentCode = source.MealDepartmentCode,
            target.Status = source.Status, target.UseFlag = source.UseFlag,
            target.UpdatedAt = GETDATE(), target.UpdatedBy = 'MIGRATION_STEP1'
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

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

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
