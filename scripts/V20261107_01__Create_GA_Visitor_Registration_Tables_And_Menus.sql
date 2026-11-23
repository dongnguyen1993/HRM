-- =========================================================================================
-- Migration: V20261107_01__Create_GA_Visitor_Registration_Tables_And_Menus.sql
-- Description: Create GA Visitor Registration tables, indexes, menus, and permissions
-- Author: huungociter (GA Domain - HRM Enterprise)
-- Date: 2026-11-07
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- -------------------------------------------------------------------------------------
    -- 1. BẢNG GA_VisitorRegistrations (Phiếu đăng ký cha)
    -- -------------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.GA_VisitorRegistrations', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.GA_VisitorRegistrations (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            RegistrationCode AS ('VR' + RIGHT('000000' + CAST(Id AS VARCHAR(6)), 6)) PERSISTED, -- VR000001
            RegistrationType NVARCHAR(20) NOT NULL, -- 'DAILY' (ngắn hạn) hoặc 'LONG_TERM' (dài hạn)
            RequestedBy NVARCHAR(50) NOT NULL,      -- UserCode nhân viên tạo
            DepartmentCode NVARCHAR(50) NULL,       -- Phòng ban nhân viên tạo
            RequestedDate DATETIME NOT NULL DEFAULT GETDATE(),
            Status NVARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
            ApprovedBy NVARCHAR(50) NULL,           -- UserCode GA duyệt
            ApprovedDate DATETIME NULL,
            RejectReason NVARCHAR(500) NULL,
            Note NVARCHAR(500) NULL,
            CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
            CreatedBy NVARCHAR(50) NOT NULL,
            UpdatedAt DATETIME NULL,
            UpdatedBy NVARCHAR(50) NULL
        );

        CREATE INDEX IX_GA_VisitorRegistrations_Status ON dbo.GA_VisitorRegistrations (Status);
        CREATE INDEX IX_GA_VisitorRegistrations_RequestedBy ON dbo.GA_VisitorRegistrations (RequestedBy);
        PRINT N'[GA] Đã tạo bảng dbo.GA_VisitorRegistrations thành công';
    END
    ELSE
    BEGIN
        PRINT N'[GA] Bảng dbo.GA_VisitorRegistrations đã tồn tại, bỏ qua tạo mới.';
    END;

    -- -------------------------------------------------------------------------------------
    -- 2. BẢNG GA_VisitorDetails (Danh sách chi tiết khách)
    -- -------------------------------------------------------------------------------------
    IF OBJECT_ID('dbo.GA_VisitorDetails', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.GA_VisitorDetails (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            RegistrationId INT NOT NULL,
            FullName NVARCHAR(200) NOT NULL,
            Gender NVARCHAR(10) NULL,               -- 'Nam', 'Nữ', 'Male', 'Female'
            DateOfBirth DATE NULL,
            IdNumber NVARCHAR(50) NOT NULL,         -- CCCD / Hộ chiếu
            Company NVARCHAR(200) NULL,             -- Nhà cung cấp / Tên công ty khách
            ContactPerson NVARCHAR(100) NULL,       -- Người liên hệ nội bộ (VD: Mr Đăng, Mr Jeong...)
            Department NVARCHAR(100) NULL,          -- Bộ phận liên hệ (EHS, PUR, QC...)
            VisitDateFrom DATE NOT NULL,            -- Ngày bắt đầu vào
            VisitDateTo DATE NOT NULL,              -- Ngày kết thúc
            TimeFrom NVARCHAR(10) NULL,             -- Giờ vào dự kiến (VD: '07:30', '08:00')
            TimeTo NVARCHAR(10) NULL,               -- Giờ ra dự kiến (VD: '17:00', '20:00')
            TotalDays INT NULL,                     -- Tổng số ngày (đối với khách dài hạn)
            Purpose NVARCHAR(500) NULL,             -- Mục đích: Thi công, Meeting, Audit, Bảo trì...
            Note NVARCHAR(500) NULL,                -- Ghi chú (chụp hình, mang thiết bị...)
            CheckInStatus NVARCHAR(20) NULL,        -- NULL, 'CHECKED_IN', 'CHECKED_OUT'
            CheckInTime DATETIME NULL,              -- Giờ thực tế vào
            CheckOutTime DATETIME NULL,             -- Giờ thực tế ra
            CheckInBy NVARCHAR(50) NULL,            -- Bảo vệ xác nhận vào
            CheckOutBy NVARCHAR(50) NULL,           -- Bảo vệ xác nhận ra
            CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
            UpdatedAt DATETIME NULL,
            CONSTRAINT FK_GA_VisitorDetails_Registration FOREIGN KEY (RegistrationId)
                REFERENCES dbo.GA_VisitorRegistrations(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_GA_VisitorDetails_Dates ON dbo.GA_VisitorDetails (VisitDateFrom, VisitDateTo);
        CREATE INDEX IX_GA_VisitorDetails_IdNumber ON dbo.GA_VisitorDetails (IdNumber);
        CREATE INDEX IX_GA_VisitorDetails_CheckInStatus ON dbo.GA_VisitorDetails (CheckInStatus);
        PRINT N'[GA] Đã tạo bảng dbo.GA_VisitorDetails thành công';
    END
    ELSE
    BEGIN
        PRINT N'[GA] Bảng dbo.GA_VisitorDetails đã tồn tại, bỏ qua tạo mới.';
    END;

    -- -------------------------------------------------------------------------------------
    -- 3. ĐĂNG KÝ MENU & PHÂN QUYỀN (SYS_ProgramMenus & SYS_AuthorGroupMapping)
    -- -------------------------------------------------------------------------------------
    -- 3004_GA_VISITOR_REGISTRATION: Đăng ký khách
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3004_GA_VISITOR_REGISTRATION')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (ProgramKey, ParentProgramKey, ProgramGroup, Level, Path, SortOrder, UseFlag, MenuFlag, Icon, ProgramName, Comment)
        VALUES ('3004_GA_VISITOR_REGISTRATION', '3000_GA', 'GA', 2, '/ga/visitor-registration', 3004, 1, 1, 'user-add', N'Đăng ký khách vào cổng', N'Tạo và quản lý danh sách khách ngắn hạn, dài hạn vào cổng nhà máy');
        PRINT N'[GA] Đã thêm menu 3004_GA_VISITOR_REGISTRATION';
    END;

    -- 3005_GA_VISITOR_APPROVAL: Phê duyệt đăng ký
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3005_GA_VISITOR_APPROVAL')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (ProgramKey, ParentProgramKey, ProgramGroup, Level, Path, SortOrder, UseFlag, MenuFlag, Icon, ProgramName, Comment)
        VALUES ('3005_GA_VISITOR_APPROVAL', '3000_GA', 'GA', 2, '/ga/visitor-approval', 3005, 1, 1, 'check-circle', N'Duyệt khách vào cổng', N'Phê duyệt và từ chối các yêu cầu đăng ký khách vào cổng nhà máy');
        PRINT N'[GA] Đã thêm menu 3005_GA_VISITOR_APPROVAL';
    END;

    -- 3006_GA_VISITOR_GATE: Chốt bảo vệ vào/ra
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3006_GA_VISITOR_GATE')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (ProgramKey, ParentProgramKey, ProgramGroup, Level, Path, SortOrder, UseFlag, MenuFlag, Icon, ProgramName, Comment)
        VALUES ('3006_GA_VISITOR_GATE', '3000_GA', 'GA', 2, '/ga/visitor-gate', 3006, 1, 1, 'safety', N'Kiểm soát Cổng bảo vệ', N'Màn hình đối soát, tìm kiếm và xác nhận khách check-in/check-out tại cổng');
        PRINT N'[GA] Đã thêm menu 3006_GA_VISITOR_GATE';
    END;

    -- -------------------------------------------------------------------------------------
    -- 4. PHÂN QUYỀN VÀO SYS_AuthorGroupMapping
    -- -------------------------------------------------------------------------------------
    DECLARE @pIdReg INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3004_GA_VISITOR_REGISTRATION');
    DECLARE @pIdApp INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3005_GA_VISITOR_APPROVAL');
    DECLARE @pIdGate INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3006_GA_VISITOR_GATE');

    -- Cấp quyền Full cho Admin Group (GroupId = 1)
    IF @pIdReg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @pIdReg)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint) VALUES (1, @pIdReg, 1, 1, 1, 1, 1);
    IF @pIdApp IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @pIdApp)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint) VALUES (1, @pIdApp, 1, 1, 1, 1, 1);
    IF @pIdGate IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @pIdGate)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint) VALUES (1, @pIdGate, 1, 1, 1, 1, 1);

    -- Cấp quyền cho GA Officer (GroupId = 3003)
    IF @pIdReg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @pIdReg)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint) VALUES (3003, @pIdReg, 1, 1, 1, 1, 1);
    IF @pIdApp IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @pIdApp)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint) VALUES (3003, @pIdApp, 1, 1, 1, 1, 1);
    IF @pIdGate IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @pIdGate)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint) VALUES (3003, @pIdGate, 1, 1, 1, 1, 1);

    -- Cấp quyền Đăng ký (3004) cho toàn bộ người dùng các nhóm quyền khác (HR, ESS User...)
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint)
    SELECT ag.GroupId, @pIdReg, 1, 1, 1, 0, 0
    FROM dbo.SYS_AuthorGroups ag
    WHERE ag.GroupId NOT IN (1, 3003)
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping m WHERE m.GroupId = ag.GroupId AND m.ProgramId = @pIdReg);

    PRINT N'[GA] Phân quyền thành công cho các phân hệ.';

    COMMIT TRANSACTION;
    PRINT N'[GA] Migration V20261107_01__Create_GA_Visitor_Registration_Tables_And_Menus thực thi hoàn tất!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT N'[GA] ❌ Lỗi xảy ra khi chạy Migration: ' + @ErrorMessage;
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
