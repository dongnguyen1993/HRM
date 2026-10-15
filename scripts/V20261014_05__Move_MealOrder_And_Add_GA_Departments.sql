-- ======================================================================
-- Migration: V20261014_05__Move_MealOrder_And_Add_GA_Departments.sql
-- Description: 
--   1. Di chuyển 6030_MEAL_ORDER về 6000_SELF_SERVICE (Cổng Tự Phục Vụ)
--   2. Cấp quyền đặt cơm cho nhóm Người Dùng (GroupId = 2002)
--   3. Tạo bảng GaDepartments và nạp danh mục 20 phòng ban nhận cơm
--   4. Thêm menu GA_DEPARTMENTS cho nhóm 3000_GA (Quản Trị Hành Chính)
--   5. Phân quyền cho GA_DEPARTMENTS (Admin & GA Officer)
-- ======================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

PRINT N'=== 1. DI CHUYỂN 6030_MEAL_ORDER VỀ 6000_SELF_SERVICE ===';

UPDATE [dbo].[ProgramMenus]
SET [ParentProgramKey] = '6000_SELF_SERVICE',
    [Path] = '/self-service/meal-order',
    [ProgramGroup] = 'Self Service',
    [SortOrder] = 3,
    [Icon] = 'coffee',
    [UpdatedAt] = GETDATE(),
    [UpdatedBy] = 'ADMIN'
WHERE [ProgramKey] = '6030_MEAL_ORDER';

UPDATE [dbo].[ProgramMenus]
SET [SortOrder] = 4,
    [UpdatedAt] = GETDATE(),
    [UpdatedBy] = 'ADMIN'
WHERE [ProgramKey] = '6040_MY_PAYSLIP';

-- Cấp quyền đặt cơm cho mọi người dùng thông thường (GroupId = 2002)
DECLARE @MealOrderProgId INT;
SELECT @MealOrderProgId = [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '6030_MEAL_ORDER';

IF @MealOrderProgId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 2002 AND [ProgramId] = @MealOrderProgId)
BEGIN
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    VALUES (2002, @MealOrderProgId, 1, 1, 1, 0, 1, 0);
    PRINT N'Đã cấp quyền đặt cơm cho GroupId 2002 (Người Dùng).';
END

PRINT N'=== 2. TẠO BẢNG GaDepartments VÀ NẠP DỮ LIỆU ===';

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GaDepartments]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[GaDepartments] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [DepartmentCode] NVARCHAR(50) NOT NULL UNIQUE,
        [DepartmentName] NVARCHAR(200) NOT NULL,
        [Plant] NVARCHAR(50) NULL DEFAULT 'TECH_H',
        [Area] NVARCHAR(50) NULL DEFAULT 'PMD',
        [DefaultRepresentative] NVARCHAR(100) NULL,
        [RepresentativePhone] NVARCHAR(50) NULL,
        [DeliveryLocation] NVARCHAR(200) NULL,
        [Status] NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE / PAUSED
        [Note] NVARCHAR(500) NULL,
        [SortOrder] INT DEFAULT 0,
        [CreatedAt] DATETIME DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(50) NULL DEFAULT 'ADMIN',
        [UpdatedAt] DATETIME NULL,
        [UpdatedBy] NVARCHAR(50) NULL
    );
    PRINT N'Bảng GaDepartments đã được tạo thành công.';
END

-- Nạp danh mục 22 đơn vị/xưởng nhận cơm nhà máy MES-Hansol
MERGE INTO [dbo].[GaDepartments] AS target
USING (VALUES
    ('IT',       N'Phòng Công Nghệ Thông Tin (IT)',        'TECH_H', 'PMD',  N'Nguyễn Văn Admin',    '0981234567', N'Văn phòng tầng 2',          'ACTIVE', N'Ưu tiên giao cơm ca trưa trước 11h25', 1),
    ('HR',       N'Phòng Quản Trị Nhân Sự (HR)',           'TECH_H', 'PMD',  N'Lê Thị Thu',          '0982345678', N'Văn phòng tầng 2',          'ACTIVE', N'Khối văn phòng hành chính', 2),
    ('GA',       N'Phòng Hành Chính Tổng Hợp (GA)',        'TECH_H', 'PMD',  N'Trần Văn GA',         '0983456789', N'Nhà ăn tầng 1 (Bàn GA)',    'ACTIVE', N'Ban quản lý nhà ăn và suất ăn', 3),
    ('QC',       N'Phòng Quản Lý Chất Lượng (QC)',         'TECH_H', 'PBA',  N'Hoàng Minh Tuấn',     '0984567890', N'Phòng kiểm tra QC 1F',      'ACTIVE', N'Kiểm tra mẫu cơm lưu 24h', 4),
    ('WH',       N'Bộ Phận Kho Vận & Nguyên Vật Liệu (WH)','TECH_H', 'PMD',  N'Đỗ Văn Kho',          '0985678901', N'Cửa kho tổng WH',           'ACTIVE', N'Giao cơm ca ngày và đêm', 5),
    ('VPSX',     N'Văn Phòng Sản Xuất (VPSX)',             'TECH_H', 'PMD',  N'Phạm Thị Hoa',        '0986789012', N'Cửa xưởng sản xuất 1F',     'ACTIVE', N'Điều phối chuyền sản xuất', 6),
    ('3IN1',     N'Bộ Phận 3 Trong 1 (3IN1)',              'TECH_H', 'PMD',  N'Trương Văn Ba',       '0987890123', N'Bàn ăn khu 3IN1',           'ACTIVE', N'Ca kíp 3 ca 4 kíp', 7),
    ('PBA',      N'Phân Xưởng PBA',                        'TECH_H', 'PBA',  N'Nguyễn Đình Phúc',    '0988901234', N'Line chuyền xưởng PBA 1F',  'ACTIVE', N'Xưởng sản xuất mạch điện tử', 8),
    ('LCM',      N'Phân Xưởng LCM',                        'TECH_H', 'LCM',  N'Vũ Quang Huy',        '0989012345', N'Line chuyền xưởng LCM',     'ACTIVE', N'Xưởng modul hiển thị', 9),
    ('VB',       N'Bộ Phận Kỹ Thuật VB',                   'TECH_H', 'PBA',  N'Bùi Văn Vui',         '0912345678', N'Phòng điều hành VB',        'ACTIVE', N'Bộ phận kỹ thuật cao', 10),
    ('ACC',      N'Phòng Tài Chính Kế Toán (ACC)',         'TECH_H', 'PMD',  N'Mai Thị Lan',         '0913456789', N'Văn phòng tầng 2',          'ACTIVE', N'Quyết toán chi phí suất ăn', 11),
    ('PUR',      N'Phòng Thu Mua (PUR)',                   'TECH_H', 'PMD',  N'Ngô Thị Hạnh',        '0914567890', N'Văn phòng tầng 2',          'ACTIVE', N'Hợp đồng thực phẩm nhà thầu', 12),
    ('MA',       N'Phòng Quản Lý Vật Tư MA',               'TECH_H', 'PMD',  N'Đinh Văn Toàn',       '0915678901', N'Cửa kho vật tư MA',         'ACTIVE', N'Vật tư phụ trợ', 13),
    ('EX',       N'Phòng Xuất Nhập Khẩu (EX)',             'TECH_H', 'PMD',  N'Đoàn Thị Yến',        '0916789012', N'Văn phòng tầng 2',          'ACTIVE', N'Giao ca trưa', 14),
    ('SALE',     N'Phòng Kinh Doanh (SALE)',               'TECH_H', 'PMD',  N'Trịnh Văn Nam',       '0917890123', N'Văn phòng tầng 2',          'ACTIVE', N'Đội tiếp khách và kinh doanh', 15),
    ('KTSP',     N'Phòng Kỹ Thuật Sản Phẩm (KTSP)',        'TECH_H', 'PMD',  N'Lý Văn Hùng',         '0918901234', N'Phòng Lab kiểm định',       'ACTIVE', N'Nghiên cứu sản phẩm mới', 16),
    ('KTSX',     N'Phòng Kỹ Thuật Sản Xuất (KTSX)',        'TECH_H', 'PMD',  N'Phan Văn Quyết',      '0919012345', N'Văn phòng KTSX xưởng',      'ACTIVE', N'Bảo trì line máy móc', 17),
    ('KHSX',     N'Phòng Kế Hoạch Sản Xuất (KHSX)',        'TECH_H', 'PMD',  N'Tạ Thị Mai',          '0921234567', N'Bàn kế hoạch 2F',           'ACTIVE', N'Lịch sản xuất tuần', 18),
    ('HSE',      N'Ban An Toàn & Sức Khỏe Môi Trường(HSE)','TECH_H', 'PMD',  N'Đặng Văn Bình',       '0922345678', N'Trạm y tế / HSE 1F',        'ACTIVE', N'Kiểm tra vệ sinh an toàn thực phẩm', 19),
    ('SECURITY', N'Đội Bảo Vệ & An Ninh',                  'TECH_H', 'PMD',  N'Nguyễn Văn Cường',    '0923456789', N'Vọng gác cổng chính',       'ACTIVE', N'Trực 24/7 theo ca trực', 20),
    ('DRIVER',   N'Đội Lái Xe Đưa Đón',                    'TECH_H', 'PMD',  N'Phạm Văn Tài',        '0924567890', N'Nhà chờ xe cổng phụ',       'ACTIVE', N'Xe ca đưa đón CBNV', 21),
    ('KOREAN',   N'Khối Chuyên Gia Hàn Quốc',              'TECH_H', 'PMD',  N'Kim Min Soo',         '0925678901', N'Phòng ăn VIP chuyên gia',   'ACTIVE', N'Thực đơn cơm Hàn Quốc', 22)
) AS source (DepartmentCode, DepartmentName, Plant, Area, DefaultRepresentative, RepresentativePhone, DeliveryLocation, Status, Note, SortOrder)
ON target.DepartmentCode = source.DepartmentCode
WHEN MATCHED THEN
    UPDATE SET 
        DepartmentName = source.DepartmentName,
        Plant = source.Plant,
        Area = source.Area,
        DefaultRepresentative = source.DefaultRepresentative,
        RepresentativePhone = source.RepresentativePhone,
        DeliveryLocation = source.DeliveryLocation,
        Status = source.Status,
        Note = source.Note,
        SortOrder = source.SortOrder,
        UpdatedAt = GETDATE(),
        UpdatedBy = 'ADMIN'
WHEN NOT MATCHED THEN
    INSERT (DepartmentCode, DepartmentName, Plant, Area, DefaultRepresentative, RepresentativePhone, DeliveryLocation, Status, Note, SortOrder, CreatedAt, CreatedBy)
    VALUES (source.DepartmentCode, source.DepartmentName, source.Plant, source.Area, source.DefaultRepresentative, source.RepresentativePhone, source.DeliveryLocation, source.Status, source.Note, source.SortOrder, GETDATE(), 'ADMIN');

PRINT N'Đã nạp 22 phòng ban/xưởng cho GaDepartments.';

PRINT N'=== 3. THÊM MENU GA_DEPARTMENTS CHO 3000_GA ===';

IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = 'GA_DEPARTMENTS')
BEGIN
    INSERT INTO [dbo].[ProgramMenus] (
        [ProgramKey], [ProgramName], [Level], [ParentProgramKey], [ProgramGroup], 
        [UseFlag], [MenuFlag], [SortOrder], [Path], [Icon], [CreatedAt], [CreatedBy]
    )
    VALUES (
        'GA_DEPARTMENTS', N'Quản lý Phòng ban (GA)', 2, '3000_GA', 'General Affairs',
        1, 1, 3, '/ga/departments', 'team', GETDATE(), 'ADMIN'
    );
    PRINT N'Đã thêm bản ghi GA_DEPARTMENTS vào ProgramMenus.';
END
ELSE
BEGIN
    UPDATE [dbo].[ProgramMenus]
    SET [ProgramName] = N'Quản lý Phòng ban (GA)',
        [ParentProgramKey] = '3000_GA',
        [Level] = 2,
        [Path] = '/ga/departments',
        [ProgramGroup] = 'General Affairs',
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 3,
        [Icon] = 'team',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = 'GA_DEPARTMENTS';
    PRINT N'Đã cập nhật bản ghi GA_DEPARTMENTS trong ProgramMenus.';
END

-- Phân quyền cho GA_DEPARTMENTS
DECLARE @GaDeptProgId INT;
SELECT @GaDeptProgId = [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = 'GA_DEPARTMENTS';

IF @GaDeptProgId IS NOT NULL
BEGIN
    -- Nhóm Quản Trị Viên (GroupId = 1)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 1 AND [ProgramId] = @GaDeptProgId)
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        VALUES (1, @GaDeptProgId, 1, 1, 1, 1, 1, 1);
    ELSE
        UPDATE [dbo].[AuthorGroupMapping]
        SET [IsSearch] = 1, [IsCreate] = 1, [IsUpdate] = 1, [IsDelete] = 1, [IsSave] = 1, [IsPrint] = 1
        WHERE [GroupId] = 1 AND [ProgramId] = @GaDeptProgId;

    -- Nhóm Quản Trị Hành Chính GA Officer (GroupId = 3003)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 3003 AND [ProgramId] = @GaDeptProgId)
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        VALUES (3003, @GaDeptProgId, 1, 1, 1, 0, 1, 1);
    ELSE
        UPDATE [dbo].[AuthorGroupMapping]
        SET [IsSearch] = 1, [IsCreate] = 1, [IsUpdate] = 1, [IsDelete] = 0, [IsSave] = 1, [IsPrint] = 1
        WHERE [GroupId] = 3003 AND [ProgramId] = @GaDeptProgId;

    -- Nhóm Quản Lý Suất Ăn Meal Manager (GroupId = 2003)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 2003 AND [ProgramId] = @GaDeptProgId)
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        VALUES (2003, @GaDeptProgId, 1, 1, 1, 0, 1, 1);
    ELSE
        UPDATE [dbo].[AuthorGroupMapping]
        SET [IsSearch] = 1, [IsCreate] = 1, [IsUpdate] = 1, [IsDelete] = 0, [IsSave] = 1, [IsPrint] = 1
        WHERE [GroupId] = 2003 AND [ProgramId] = @GaDeptProgId;

    PRINT N'Đã phân quyền thành công cho GA_DEPARTMENTS.';
END

GO
