-- ==============================================================================
-- Script: V20261015_03__Create_Dynamic_Notification_Matrix.sql
-- Description: Tạo bảng và dữ liệu mẫu cho tính năng Cấu hình Thông Báo Động
--              (Dynamic Notification Matrix) không hardcode người nhận.
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

-- 1. BẢNG CÁC SỰ KIỆN THÔNG BÁO (NotificationEvents)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NotificationEvents')
BEGIN
    CREATE TABLE [dbo].[NotificationEvents] (
        [EventCode] VARCHAR(50) NOT NULL PRIMARY KEY,
        [EventName] NVARCHAR(150) NOT NULL,
        [Module] NVARCHAR(50) NOT NULL,
        [TitleTemplate] NVARCHAR(250) NOT NULL,
        [MessageTemplate] NVARCHAR(500) NOT NULL,
        [TargetLink] NVARCHAR(250) NULL,
        [NotifyRequester] BIT NOT NULL DEFAULT 0,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [UpdatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [UpdatedBy] NVARCHAR(50) NULL
    );
END
GO

-- 2. BẢNG MA TRẬN PHÂN QUYỀN NHẬN THÔNG BÁO (NotificationMatrix)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NotificationMatrix')
BEGIN
    CREATE TABLE [dbo].[NotificationMatrix] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [EventCode] VARCHAR(50) NOT NULL,
        [RecipientType] VARCHAR(20) NOT NULL, -- 'ROLE' | 'USER'
        [RecipientId] NVARCHAR(50) NOT NULL,  -- GroupId (ROLE) hoặc UserCode (USER)
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(50) NULL,
        CONSTRAINT [FK_NotificationMatrix_EventCode] FOREIGN KEY ([EventCode]) REFERENCES [dbo].[NotificationEvents]([EventCode]) ON DELETE CASCADE,
        CONSTRAINT [UQ_NotificationMatrix] UNIQUE ([EventCode], [RecipientType], [RecipientId])
    );
END
GO

-- 3. BẢNG LƯU TRỮ THÔNG BÁO TỪNG TÀI KHOẢN (Notifications)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notifications')
BEGIN
    CREATE TABLE [dbo].[Notifications] (
        [NotificationId] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [RecipientUserCode] NVARCHAR(50) NOT NULL,
        [EventCode] VARCHAR(50) NULL,
        [Title] NVARCHAR(250) NOT NULL,
        [Message] NVARCHAR(1000) NOT NULL,
        [Type] VARCHAR(20) NOT NULL DEFAULT 'info', -- 'info' | 'success' | 'warning' | 'error'
        [Link] NVARCHAR(250) NULL,
        [IsRead] BIT NOT NULL DEFAULT 0,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [ReadAt] DATETIME NULL
    );

    CREATE NONCLUSTERED INDEX [IX_Notifications_User_Read_CreatedAt]
    ON [dbo].[Notifications] ([RecipientUserCode], [IsRead], [CreatedAt] DESC);
END
GO

-- 4. SEED DỮ LIỆU CÁC SỰ KIỆN CHUẨN CỦA TOÀN HỆ THỐNG
MERGE [dbo].[NotificationEvents] AS target
USING (VALUES
    ('MEAL_ORDER_SUBMITTED', N'Đăng ký chốt suất ăn bộ phận', N'MEAL', N'[Suất ăn] {DepartmentName} đã gửi đăng ký suất ăn', N'{DepartmentName} đã đăng ký {TotalMeals} suất ăn cho ngày {OrderDate}. Người tạo: {RequesterName}.', N'/human-resource/meal-management', 0, 1),
    ('MEAL_ORDER_ADJUSTED', N'Điều chỉnh suất ăn quá khứ / đột xuất', N'MEAL', N'[Suất ăn] Điều chỉnh suất ăn ngày {OrderDate}', N'{DepartmentName} đã cập nhật lại suất ăn ngày {OrderDate}. Lý do: {Reason}. Người thực hiện: {RequesterName}.', N'/human-resource/meal-management', 0, 1),
    ('TIMEOFF_REQUEST_CREATED', N'Đăng ký đơn xin nghỉ phép mới', N'TIMEOFF', N'[Nghỉ phép] Yêu cầu xin nghỉ từ {RequesterName}', N'Nhân viên {RequesterName} ({RequesterCode}) gửi yêu cầu nghỉ loại {LeaveType} từ ngày {FromDate} đến {ToDate}. Lý do: {Reason}.', N'/work-hours/time-off', 0, 1),
    ('TIMEOFF_REQUEST_PROCESSED', N'Kết quả xét duyệt đơn nghỉ phép', N'TIMEOFF', N'[Nghỉ phép] Đơn xin nghỉ đã được xử lý', N'Đơn xin nghỉ từ ngày {FromDate} đến {ToDate} của bạn đã được {Status} bởi {ApproverName}. Ghi chú: {Reason}.', N'/work-hours/time-off', 1, 1),
    ('PAYROLL_PUBLISHED', N'Công bố phiếu lương hàng tháng', N'PAYROLL', N'[Bảng lương] Phiếu lương kỳ {PeriodName} đã phát hành', N'Phiếu lương kỳ {PeriodName} của bạn đã sẵn sàng tra cứu. Vui lòng vào màn hình Phiếu lương cá nhân để kiểm tra chi tiết thu nhập.', N'/payroll/my-payslip', 1, 1),
    ('PERMISSION_CHANGED', N'Cập nhật phân quyền tài khoản / nhóm quyền', N'PERMISSION', N'[Bảo mật] Cập nhật phân quyền hệ thống', N'Phân quyền của đối tượng {TargetName} đã được cập nhật bởi quản trị viên {OperatorName}.', N'/system-mgmt/permission-mapping', 0, 1),
    ('ANNOUNCEMENT_NEW', N'Bảng tin & Thông báo toàn công ty', N'ANNOUNCEMENT', N'[Bảng tin] {Title}', N'{Title}. Người đăng: {AuthorName}. Bấm vào để xem nội dung chi tiết.', N'/system-mgmt/announcements', 0, 1)
) AS source ([EventCode], [EventName], [Module], [TitleTemplate], [MessageTemplate], [TargetLink], [NotifyRequester], [IsActive])
ON target.[EventCode] = source.[EventCode]
WHEN MATCHED THEN
    UPDATE SET 
        target.[EventName] = source.[EventName],
        target.[Module] = source.[Module],
        target.[TitleTemplate] = source.[TitleTemplate],
        target.[MessageTemplate] = source.[MessageTemplate],
        target.[TargetLink] = source.[TargetLink],
        target.[NotifyRequester] = source.[NotifyRequester],
        target.[IsActive] = source.[IsActive],
        target.[UpdatedAt] = GETDATE()
WHEN NOT MATCHED THEN
    INSERT ([EventCode], [EventName], [Module], [TitleTemplate], [MessageTemplate], [TargetLink], [NotifyRequester], [IsActive])
    VALUES (source.[EventCode], source.[EventName], source.[Module], source.[TitleTemplate], source.[MessageTemplate], source.[TargetLink], source.[NotifyRequester], source.[IsActive]);
GO

-- 5. SEED MA TRẬN NHẬN THÔNG BÁO MẶC ĐỊNH CHO CÁC SỰ KIỆN
-- 2003: Quản Lý Suất Ăn (Meal Manager)
-- 3003: Quản Trị Hành Chính (GA Officer)
-- 3002: Quản Trị Nhân Sự (HR Officer)
-- 1: Quản Trị Viên (Administrator)
MERGE [dbo].[NotificationMatrix] AS target
USING (VALUES
    ('MEAL_ORDER_SUBMITTED', 'ROLE', '2003'),
    ('MEAL_ORDER_SUBMITTED', 'ROLE', '3003'),
    ('MEAL_ORDER_ADJUSTED', 'ROLE', '2003'),
    ('MEAL_ORDER_ADJUSTED', 'ROLE', '3003'),
    ('TIMEOFF_REQUEST_CREATED', 'ROLE', '3002'),
    ('TIMEOFF_REQUEST_CREATED', 'ROLE', '1'),
    ('TIMEOFF_REQUEST_PROCESSED', 'ROLE', '3002'),
    ('PAYROLL_PUBLISHED', 'ROLE', '3002'),
    ('PERMISSION_CHANGED', 'ROLE', '1'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '1'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '2'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '3'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '4'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '5'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '6'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '7'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '1002'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '2002'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '2003'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '3002'),
    ('ANNOUNCEMENT_NEW', 'ROLE', '3003')
) AS source ([EventCode], [RecipientType], [RecipientId])
ON target.[EventCode] = source.[EventCode] 
   AND target.[RecipientType] = source.[RecipientType] 
   AND target.[RecipientId] = source.[RecipientId]
WHEN NOT MATCHED THEN
    INSERT ([EventCode], [RecipientType], [RecipientId], [CreatedAt])
    VALUES (source.[EventCode], source.[RecipientType], source.[RecipientId], GETDATE());
GO

-- 6. TẠO MENU CẤU HÌNH THÔNG BÁO ĐỘNG TRONG ProgramMenus
IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '1080' OR [Path] = '/system-mgmt/notification-matrix')
BEGIN
    INSERT INTO [dbo].[ProgramMenus] (
        [ProgramKey],
        [ProgramName],
        [Level],
        [ParentProgramKey],
        [ProgramGroup],
        [UseFlag],
        [MenuFlag],
        [SortOrder],
        [Comment],
        [CreatedAt],
        [CreatedBy],
        [Path],
        [Icon]
    ) VALUES (
        '1080',
        N'Cấu hình Thông Báo Động',
        2,
        '1000_SYS',
        'SYSTEM',
        1,
        1,
        90,
        N'Cấu hình ma trận sự kiện thông báo linh hoạt theo nhóm quyền và tài khoản',
        GETDATE(),
        'SYSTEM',
        '/system-mgmt/notification-matrix',
        'BellOutlined'
    );
END
GO

-- 7. CẤP QUYỀN CHO NHÓM ADMINISTRATOR (GroupId = 1)
DECLARE @ProgId INT = (SELECT TOP 1 [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '1080');
IF @ProgId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 1 AND [ProgramId] = @ProgId)
BEGIN
    INSERT INTO [dbo].[AuthorGroupMapping] (
        [GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint]
    ) VALUES (
        1, @ProgId, 1, 1, 1, 1, 1, 1
    );
END
GO
