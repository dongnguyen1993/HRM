-- ==============================================================================
-- Migration Script: V20261107_01__Create_GA_Visitor_Registration_Tables_And_Menus.sql
-- Phân hệ: GA (General Affairs - Quản Trị Hành Chính)
-- Nghiệp vụ: Đăng Ký & Quản Lý Khách Vào Cổng Nhà Máy (Visitor Registration)
-- Chuẩn hóa: HRM Enterprise (Hệ thống nhà máy Hansol/MES)
-- Tính chất: Idempotent (Có thể chạy lại nhiều lần mà không gây lỗi hoặc trùng lặp)
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'==============================================================================';
    PRINT N'=== BẮT ĐẦU MIGRATION: KHỞI TẠO BẢNG & PHÂN QUYỀN VISITOR REGISTRATION (GA) ===';
    PRINT N'==============================================================================';

    -- --------------------------------------------------------------------------
    -- 1. BẢNG CHA: dbo.GA_VisitorRegistrations (Phiếu đăng ký khách vào cổng)
    -- --------------------------------------------------------------------------
    IF OBJECT_ID('dbo.GA_VisitorRegistrations', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.GA_VisitorRegistrations (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            RegistrationCode AS ('VR' + RIGHT('000000' + CAST(Id AS VARCHAR(6)), 6)) PERSISTED, -- Mã phiếu tự tăng VR000001
            RegistrationType NVARCHAR(20) NOT NULL, -- 'DAILY' (ngắn hạn trong ngày) hoặc 'LONG_TERM' (dài hạn nhiều ngày)
            RequestedBy NVARCHAR(50) NOT NULL,      -- UserCode nhân viên tạo phiếu
            DepartmentCode NVARCHAR(50) NULL,       -- Mã phòng ban của nhân viên tạo
            RequestedDate DATETIME NOT NULL DEFAULT GETDATE(),
            Status NVARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED'
            ApprovedBy NVARCHAR(50) NULL,           -- UserCode cán bộ GA phê duyệt
            ApprovedDate DATETIME NULL,             -- Ngày giờ phê duyệt/từ chối
            RejectReason NVARCHAR(500) NULL,        -- Lý do từ chối (nếu có)
            Note NVARCHAR(500) NULL,                -- Ghi chú chung của phiếu
            CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
            CreatedBy NVARCHAR(50) NOT NULL,
            UpdatedAt DATETIME NULL,
            UpdatedBy NVARCHAR(50) NULL
        );

        CREATE INDEX IX_GA_VisitorRegistrations_Status ON dbo.GA_VisitorRegistrations (Status);
        CREATE INDEX IX_GA_VisitorRegistrations_RequestedBy ON dbo.GA_VisitorRegistrations (RequestedBy);
        CREATE INDEX IX_GA_VisitorRegistrations_RequestedDate ON dbo.GA_VisitorRegistrations (RequestedDate);
        
        PRINT N'[GA] Đã tạo bảng dbo.GA_VisitorRegistrations và indexes thành công.';
    END
    ELSE
    BEGIN
        PRINT N'[GA] Bảng dbo.GA_VisitorRegistrations đã tồn tại, bỏ qua tạo mới.';
    END

    -- --------------------------------------------------------------------------
    -- 2. BẢNG CON: dbo.GA_VisitorDetails (Danh sách chi tiết khách vào cổng)
    -- --------------------------------------------------------------------------
    IF OBJECT_ID('dbo.GA_VisitorDetails', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.GA_VisitorDetails (
            Id INT IDENTITY(1,1) PRIMARY KEY,
            RegistrationId INT NOT NULL,
            FullName NVARCHAR(200) NOT NULL,        -- Họ và tên khách
            Gender NVARCHAR(10) NULL,               -- 'Nam', 'Nữ', 'Male', 'Female'
            DateOfBirth DATE NULL,                  -- Ngày sinh
            IdNumber NVARCHAR(50) NOT NULL,         -- CCCD / Hộ chiếu
            Company NVARCHAR(200) NULL,             -- Nhà cung cấp / Đơn vị công tác của khách
            ContactPerson NVARCHAR(100) NULL,       -- Người liên hệ nội bộ (Mr Đăng, Mr Jeong...)
            Department NVARCHAR(100) NULL,          -- Bộ phận liên hệ (EHS, PUR, QC, IT, KTSX...)
            VisitDateFrom DATE NOT NULL,            -- Ngày bắt đầu vào làm việc
            VisitDateTo DATE NOT NULL,              -- Ngày kết thúc làm việc
            TimeFrom NVARCHAR(10) NULL,             -- Giờ vào dự kiến ('07:30', '08:00')
            TimeTo NVARCHAR(10) NULL,               -- Giờ ra dự kiến ('17:00', '20:00')
            TotalDays INT NULL,                     -- Tổng số ngày (đối với khách dài hạn)
            Purpose NVARCHAR(500) NULL,             -- Mục đích: Thi công, Meeting, Audit, Bảo trì...
            Note NVARCHAR(500) NULL,                -- Ghi chú (mang máy ảnh, laptop, thiết bị thi công...)
            CheckInStatus NVARCHAR(20) NULL,        -- Trạng thái cổng: NULL (chưa vào), 'CHECKED_IN', 'CHECKED_OUT'
            CheckInTime DATETIME NULL,              -- Giờ thực tế vào cổng
            CheckOutTime DATETIME NULL,             -- Giờ thực tế ra cổng
            CheckInBy NVARCHAR(50) NULL,            -- Mã bảo vệ xác nhận vào
            CheckOutBy NVARCHAR(50) NULL,           -- Mã bảo vệ xác nhận ra
            CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
            UpdatedAt DATETIME NULL,
            CONSTRAINT FK_GA_VisitorDetails_Registration FOREIGN KEY (RegistrationId)
                REFERENCES dbo.GA_VisitorRegistrations(Id) ON DELETE CASCADE
        );

        CREATE INDEX IX_GA_VisitorDetails_Dates ON dbo.GA_VisitorDetails (VisitDateFrom, VisitDateTo);
        CREATE INDEX IX_GA_VisitorDetails_IdNumber ON dbo.GA_VisitorDetails (IdNumber);
        CREATE INDEX IX_GA_VisitorDetails_CheckInStatus ON dbo.GA_VisitorDetails (CheckInStatus);
        CREATE INDEX IX_GA_VisitorDetails_RegistrationId ON dbo.GA_VisitorDetails (RegistrationId);

        PRINT N'[GA] Đã tạo bảng dbo.GA_VisitorDetails và indexes thành công.';
    END
    ELSE
    BEGIN
        PRINT N'[GA] Bảng dbo.GA_VisitorDetails đã tồn tại, bỏ qua tạo mới.';
    END

    -- --------------------------------------------------------------------------
    -- 3. KHỞI TẠO MENU CHO PHÂN HỆ GA (dbo.SYS_ProgramMenus)
    -- ParentProgramKey: '3000_GA' (Quản Trị Hành Chính)
    -- --------------------------------------------------------------------------
    PRINT N'[SYS] Đang cập nhật danh mục màn hình phân hệ GA vào SYS_ProgramMenus...';

    -- 3004_GA_VISITOR_REGISTRATION: Đăng ký khách vào cổng
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3004_GA_VISITOR_REGISTRATION')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ParentProgramKey, ProgramGroup, Level, Path, SortOrder, UseFlag, MenuFlag, Icon, ProgramName, Comment
        )
        VALUES (
            '3004_GA_VISITOR_REGISTRATION', '3000_GA', 'GA', 2, '/ga/visitor-registration', 34, 1, 1, 'user-add',
            N'Đăng ký khách vào cổng',
            N'Tạo và quản lý danh sách khách ngắn hạn, dài hạn vào cổng nhà máy'
        );
        PRINT N'  -> Đã thêm menu: 3004_GA_VISITOR_REGISTRATION';
    END
    ELSE
    BEGIN
        UPDATE dbo.SYS_ProgramMenus
        SET ParentProgramKey = '3000_GA',
            ProgramGroup = 'GA',
            Level = 2,
            Path = '/ga/visitor-registration',
            SortOrder = 34,
            UseFlag = 1,
            MenuFlag = 1,
            Icon = 'user-add',
            ProgramName = N'Đăng ký khách vào cổng',
            Comment = N'Tạo và quản lý danh sách khách ngắn hạn, dài hạn vào cổng nhà máy'
        WHERE ProgramKey = '3004_GA_VISITOR_REGISTRATION';
        PRINT N'  -> Đã cập nhật menu: 3004_GA_VISITOR_REGISTRATION';
    END

    -- 3005_GA_VISITOR_APPROVAL: Phê duyệt đăng ký khách
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3005_GA_VISITOR_APPROVAL')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ParentProgramKey, ProgramGroup, Level, Path, SortOrder, UseFlag, MenuFlag, Icon, ProgramName, Comment
        )
        VALUES (
            '3005_GA_VISITOR_APPROVAL', '3000_GA', 'GA', 2, '/ga/visitor-approval', 35, 1, 1, 'check-circle',
            N'Duyệt khách vào cổng',
            N'Phê duyệt và từ chối các yêu cầu đăng ký khách vào cổng nhà máy'
        );
        PRINT N'  -> Đã thêm menu: 3005_GA_VISITOR_APPROVAL';
    END
    ELSE
    BEGIN
        UPDATE dbo.SYS_ProgramMenus
        SET ParentProgramKey = '3000_GA',
            ProgramGroup = 'GA',
            Level = 2,
            Path = '/ga/visitor-approval',
            SortOrder = 35,
            UseFlag = 1,
            MenuFlag = 1,
            Icon = 'check-circle',
            ProgramName = N'Duyệt khách vào cổng',
            Comment = N'Phê duyệt và từ chối các yêu cầu đăng ký khách vào cổng nhà máy'
        WHERE ProgramKey = '3005_GA_VISITOR_APPROVAL';
        PRINT N'  -> Đã cập nhật menu: 3005_GA_VISITOR_APPROVAL';
    END

    -- 3006_GA_VISITOR_GATE: Chốt kiểm soát Cổng bảo vệ
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3006_GA_VISITOR_GATE')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ParentProgramKey, ProgramGroup, Level, Path, SortOrder, UseFlag, MenuFlag, Icon, ProgramName, Comment
        )
        VALUES (
            '3006_GA_VISITOR_GATE', '3000_GA', 'GA', 2, '/ga/visitor-gate', 36, 1, 1, 'safety',
            N'Kiểm soát Cổng bảo vệ',
            N'Màn hình đối soát, tìm kiếm và xác nhận khách check-in/check-out tại cổng'
        );
        PRINT N'  -> Đã thêm menu: 3006_GA_VISITOR_GATE';
    END
    ELSE
    BEGIN
        UPDATE dbo.SYS_ProgramMenus
        SET ParentProgramKey = '3000_GA',
            ProgramGroup = 'GA',
            Level = 2,
            Path = '/ga/visitor-gate',
            SortOrder = 36,
            UseFlag = 1,
            MenuFlag = 1,
            Icon = 'safety',
            ProgramName = N'Kiểm soát Cổng bảo vệ',
            Comment = N'Màn hình đối soát, tìm kiếm và xác nhận khách check-in/check-out tại cổng'
        WHERE ProgramKey = '3006_GA_VISITOR_GATE';
        PRINT N'  -> Đã cập nhật menu: 3006_GA_VISITOR_GATE';
    END

    -- --------------------------------------------------------------------------
    -- 4. PHÂN QUYỀN TRUY CẬP (dbo.SYS_AuthorGroupMapping)
    -- --------------------------------------------------------------------------
    PRINT N'[SYS] Đang phân quyền truy cập trong SYS_AuthorGroupMapping...';

    DECLARE @pIdReg INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3004_GA_VISITOR_REGISTRATION');
    DECLARE @pIdApp INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3005_GA_VISITOR_APPROVAL');
    DECLARE @pIdGate INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '3006_GA_VISITOR_GATE');

    -- 4.1. Nhóm Quản Trị Hệ Thống / Admin (GroupId = 1): Full quyền cả 3 chức năng
    IF @pIdReg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @pIdReg)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (1, @pIdReg, 1, 1, 1, 1, 1, 1);

    IF @pIdApp IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @pIdApp)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (1, @pIdApp, 1, 1, 1, 1, 1, 1);

    IF @pIdGate IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @pIdGate)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (1, @pIdGate, 1, 1, 1, 1, 1, 1);
    
    PRINT N'  -> Đã cấp full quyền Admin (GroupId = 1).';

    -- 4.2. Nhóm Quản Trị Hành Chính / GA Officer (GroupId = 3003): Full quyền cả 3 chức năng
    IF @pIdReg IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @pIdReg)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3003, @pIdReg, 1, 1, 1, 1, 1, 1);

    IF @pIdApp IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @pIdApp)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3003, @pIdApp, 1, 1, 1, 1, 1, 1);

    IF @pIdGate IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3003 AND ProgramId = @pIdGate)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3003, @pIdGate, 1, 1, 1, 1, 1, 1);

    PRINT N'  -> Đã cấp full quyền GA Officer (GroupId = 3003).';

    -- 4.3. Cấp quyền Đăng ký (3004) cho toàn bộ người dùng các nhóm quyền khác (HR Officer, User phòng ban, ESS...)
    IF @pIdReg IS NOT NULL
    BEGIN
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        SELECT ag.GroupId, @pIdReg, 1, 1, 1, 0, 1, 0
        FROM dbo.SYS_AuthorGroups ag
        WHERE ag.GroupId NOT IN (1, 3003)
          AND NOT EXISTS (
              SELECT 1 FROM dbo.SYS_AuthorGroupMapping m 
              WHERE m.GroupId = ag.GroupId AND m.ProgramId = @pIdReg
          );
        PRINT N'  -> Đã cấp quyền Đăng ký (3004) cho tất cả các nhóm quyền người dùng khác.';
    END

    COMMIT TRANSACTION;
    PRINT N'==============================================================================';
    PRINT N'=== MIGRATION HOÀN TẤT THÀNH CÔNG! DỮ LIỆU ĐÃ ĐƯỢC COMMIT VÀO CSDL.        ===';
    PRINT N'==============================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT N'==============================================================================';
    PRINT N'=== LỖI TRONG QUÁ TRÌNH MIGRATION: ' + @ErrorMessage;
    PRINT N'==============================================================================';

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
