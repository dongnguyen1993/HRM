-- ============================================================================
-- SCRIPT ĐĂNG KÝ MENU SYS DESIGN & TABLE SHOWCASE (BASE TABLE)
-- Ngày tạo: 2026-11-20
-- ============================================================================

-- 1. Đăng ký Menu cha: SYS Design (Level 2 thuộc 4000_SYS)
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
    PRINT N'Đã đăng ký menu 4010_SYS_DESIGN thành công.';
END
ELSE
BEGIN
    UPDATE dbo.SYS_ProgramMenus 
    SET ProgramName = N'SYS Design', Path = '/sys/design', SortOrder = 4010, UseFlag = 1, MenuFlag = 1
    WHERE ProgramKey = '4010_SYS_DESIGN';
    PRINT N'Đã cập nhật menu 4010_SYS_DESIGN.';
END
GO

-- 2. Đăng ký Menu con: Table Showcase (Level 3 thuộc 4010_SYS_DESIGN)
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
    PRINT N'Đã đăng ký menu 4011_SYS_DESIGN_TABLE thành công.';
END
ELSE
BEGIN
    UPDATE dbo.SYS_ProgramMenus 
    SET ProgramName = N'Bảng Dữ Liệu (BaseTable)', Path = '/sys/design/table', SortOrder = 4011, UseFlag = 1, MenuFlag = 1
    WHERE ProgramKey = '4011_SYS_DESIGN_TABLE';
    PRINT N'Đã cập nhật menu 4011_SYS_DESIGN_TABLE.';
END
GO

-- 3. Cấp toàn quyền cho nhóm Quản Trị Viên (1), IT_MGMT (3005), HR_MGMT (3006)
DECLARE @ProgIdParent INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '4010_SYS_DESIGN');
DECLARE @ProgIdChild INT = (SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '4011_SYS_DESIGN_TABLE');

-- Group 1: Administrator
IF NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @ProgIdParent)
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    VALUES (1, @ProgIdParent, 1, 1, 1, 1, 1, 1);

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @ProgIdChild)
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    VALUES (1, @ProgIdChild, 1, 1, 1, 1, 1, 1);

-- Group 3005: IT_MGMT
IF EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroups WHERE GroupId = 3005)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3005 AND ProgramId = @ProgIdParent)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3005, @ProgIdParent, 1, 1, 1, 1, 1, 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3005 AND ProgramId = @ProgIdChild)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3005, @ProgIdChild, 1, 1, 1, 1, 1, 1);
END

-- Group 3006: HR_MGMT
IF EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroups WHERE GroupId = 3006)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3006 AND ProgramId = @ProgIdParent)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3006, @ProgIdParent, 1, 1, 1, 1, 1, 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping WHERE GroupId = 3006 AND ProgramId = @ProgIdChild)
        INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3006, @ProgIdChild, 1, 1, 1, 1, 1, 1);
END
GO

PRINT N'Hoàn tất đăng ký menu và phân quyền SYS Design & Table Showcase.';
