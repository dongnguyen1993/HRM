-- =========================================================================================
-- ĐĂNG KÝ MENU: 2011_HR_EMPLOYEES (Hồ sơ Nhân viên) VÀO SYS_ProgramMenus & PHÂN QUYỀN
-- =========================================================================================

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
    PRINT N'[SUCCESS] Đã thêm menu 2011_HR_EMPLOYEES vào SYS_ProgramMenus!';
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
    PRINT N'[INFO] Đã cập nhật menu 2011_HR_EMPLOYEES trong SYS_ProgramMenus!';
END;
GO

DECLARE @NewProgramId INT;
SELECT @NewProgramId = ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '2011_HR_EMPLOYEES';

IF @NewProgramId IS NOT NULL
BEGIN
    DECLARE @TargetGroups TABLE (GroupId INT);
    INSERT INTO @TargetGroups (GroupId)
    SELECT GroupId FROM dbo.SYS_AuthorGroups WHERE GroupId IN (1, 3002, 3005, 3006);

    MERGE dbo.SYS_AuthorGroupMapping AS target
    USING (
        SELECT GroupId, @NewProgramId AS ProgramId
        FROM @TargetGroups
    ) AS source
    ON (target.GroupId = source.GroupId AND target.ProgramId = source.ProgramId)
    WHEN MATCHED THEN
        UPDATE SET IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
    WHEN NOT MATCHED THEN
        INSERT (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
        VALUES (source.GroupId, source.ProgramId, 1, 1, 1, 1, 1, 1);

    PRINT N'[SUCCESS] Đã cấp quyền menu 2011_HR_EMPLOYEES cho các nhóm Administrator & HR!';
END;
GO
