-- ==============================================================================
-- MIGRATION SCRIPT: TẠO BẢNG VÀ PHÂN QUYỀN WORK CALENDAR & SPECIAL MEAL
-- Dự án: HRM Enterprise System (MES-Hansol Standard)
-- Ngày thực hiện: 2026-09-19
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

-- 1. TẠO BẢNG WorkCalendar
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WorkCalendar')
BEGIN
    CREATE TABLE [dbo].[WorkCalendar] (
        [CalendarDate]      DATE NOT NULL,
        [DayType]           VARCHAR(20) NOT NULL CONSTRAINT [DF_WorkCalendar_DayType] DEFAULT 'WORKDAY', -- WORKDAY, OFF, HOLIDAY
        [ShiftCodes]        NVARCHAR(100) NOT NULL CONSTRAINT [DF_WorkCalendar_ShiftCodes] DEFAULT 'SHIFT_DAY,SHIFT_NIGHT',
        [HasSpecialMeal]    BIT NOT NULL CONSTRAINT [DF_WorkCalendar_HasSpecialMeal] DEFAULT 0,
        [SpecialMealTypes]  NVARCHAR(200) NULL, -- 'DAY_LUNCH,NIGHT_DINNER' hoặc 'DAY_OT,NIGHT_OT'
        [SpecialMealPrice]  DECIMAL(18,0) NOT NULL CONSTRAINT [DF_WorkCalendar_SpecialMealPrice] DEFAULT 30000,
        [SpecialMealNote]   NVARCHAR(250) NULL,
        [CreatedAt]         DATETIME NOT NULL CONSTRAINT [DF_WorkCalendar_CreatedAt] DEFAULT GETDATE(),
        [UpdatedAt]         DATETIME NULL,
        [UpdatedBy]         NVARCHAR(50) NULL,
        CONSTRAINT [PK_WorkCalendar] PRIMARY KEY CLUSTERED ([CalendarDate] ASC)
    );

    CREATE NONCLUSTERED INDEX [IX_WorkCalendar_Month] 
    ON [dbo].[WorkCalendar] ([CalendarDate])
    INCLUDE ([DayType], [ShiftCodes], [HasSpecialMeal], [SpecialMealPrice]);

    PRINT 'Đã tạo bảng WorkCalendar và index IX_WorkCalendar_Month thành công.';
END
ELSE
BEGIN
    PRINT 'Bảng WorkCalendar đã tồn tại.';
END
GO

-- 2. ĐĂNG KÝ MENU VÀO BẢNG ProgramMenus
IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = 'WORK_CALENDAR')
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
        [Path],
        [Icon],
        [CreatedAt],
        [CreatedBy]
    )
    VALUES (
        'WORK_CALENDAR',
        N'Lịch Làm Việc & Suất Ăn',
        2,
        '2000_HR',
        'HR Management',
        1,
        1,
        25,
        '/hr/work-calendar',
        'calendar',
        GETDATE(),
        'SYSTEM'
    );

    PRINT 'Đã đăng ký menu WORK_CALENDAR vào ProgramMenus thành công.';
END
ELSE
BEGIN
    UPDATE [dbo].[ProgramMenus]
    SET [Path] = '/hr/work-calendar',
        [ProgramName] = N'Lịch Làm Việc & Suất Ăn',
        [UseFlag] = 1,
        [MenuFlag] = 1
    WHERE [ProgramKey] = 'WORK_CALENDAR';

    PRINT 'Đã cập nhật menu WORK_CALENDAR trong ProgramMenus.';
END
GO

-- 3. CẤP TOÀN QUYỀN CHO TẤT CẢ CÁC NHÓM QUYỀN TRONG AuthorGroupMapping
DECLARE @ProgId INT = (SELECT TOP 1 [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = 'WORK_CALENDAR');

IF @ProgId IS NOT NULL
BEGIN
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT 
        ag.[GroupId],
        @ProgId,
        1, -- IsSearch
        1, -- IsCreate
        1, -- IsUpdate
        1, -- IsDelete
        1, -- IsSave
        1  -- IsPrint
    FROM [dbo].[AuthorGroups] ag
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[AuthorGroupMapping] agm
        WHERE agm.[GroupId] = ag.[GroupId] AND agm.[ProgramId] = @ProgId
    );

    PRINT 'Đã cấp quyền truy cập WORK_CALENDAR cho toàn bộ AuthorGroups.';
END
GO
