USE HRM_Enterprise_DB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thêm Menu 'MEAL_MANAGEMENT' vào ProgramMenus
IF NOT EXISTS (SELECT 1 FROM ProgramMenus WHERE ProgramKey = 'MEAL_MANAGEMENT')
BEGIN
    SET IDENTITY_INSERT ProgramMenus ON;
    INSERT INTO ProgramMenus (
        ProgramId,
        ProgramKey,
        ParentProgramKey,
        ProgramName,
        Path,
        Icon,
        Level,
        SortOrder,
        UseFlag
    )
    VALUES (
        10011,
        'MEAL_MANAGEMENT',
        '2000_HR',
        N'Meal Management',
        '/hr/meal-management',
        'coffee',
        2,
        4,
        1
    );
    SET IDENTITY_INSERT ProgramMenus OFF;
END
ELSE
BEGIN
    UPDATE ProgramMenus
    SET 
        ParentProgramKey = '2000_HR',
        ProgramName = N'Meal Management',
        Path = '/hr/meal-management',
        Icon = 'coffee',
        Level = 2,
        SortOrder = 4,
        UseFlag = 1
    WHERE ProgramKey = 'MEAL_MANAGEMENT';
END
GO

-- 2. Phân quyền đầy đủ cho Administrator và các nhóm quyền tương ứng
DECLARE @ProgramId INT = (SELECT ProgramId FROM ProgramMenus WHERE ProgramKey = 'MEAL_MANAGEMENT');

IF @ProgramId IS NOT NULL
BEGIN
    -- Nhóm 1: Administrator
    IF NOT EXISTS (SELECT 1 FROM AuthorGroupMapping WHERE GroupId = 1 AND ProgramId = @ProgramId)
    BEGIN
        INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (1, @ProgramId, 1, 1, 1, 1, 1, 1);
    END
    ELSE
    BEGIN
        UPDATE AuthorGroupMapping
        SET IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
        WHERE GroupId = 1 AND ProgramId = @ProgramId;
    END

    -- Nhóm 2: Board
    IF NOT EXISTS (SELECT 1 FROM AuthorGroupMapping WHERE GroupId = 2 AND ProgramId = @ProgramId)
    BEGIN
        INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (2, @ProgramId, 1, 0, 0, 0, 0, 1);
    END

    -- Nhóm 3: V-Manager (PBA)
    IF NOT EXISTS (SELECT 1 FROM AuthorGroupMapping WHERE GroupId = 3 AND ProgramId = @ProgramId)
    BEGIN
        INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (3, @ProgramId, 1, 0, 1, 0, 0, 1);
    END

    -- Nhóm 6: K-Manager (LCM)
    IF NOT EXISTS (SELECT 1 FROM AuthorGroupMapping WHERE GroupId = 6 AND ProgramId = @ProgramId)
    BEGIN
        INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (6, @ProgramId, 1, 0, 1, 0, 0, 1);
    END
END
GO
