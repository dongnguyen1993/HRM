-- ==============================================================================
-- Migration: Chuyển User Overview & Overview Analytics vào Cổng Tự Phục Vụ
-- và Xóa vĩnh viễn các Menu đã bị xóa mềm (UseFlag = 0)
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Đảm bảo nhóm cha CỔNG TỰ PHỤC VỤ (6000_SELF_SERVICE) tồn tại
IF NOT EXISTS (SELECT 1 FROM ProgramMenus WHERE ProgramKey = '6000_SELF_SERVICE')
BEGIN
    INSERT INTO ProgramMenus (ProgramKey, ParentProgramKey, ProgramName, ProgramGroup, Path, ApiUrl, Level, UseFlag, MenuFlag, SortOrder, Comment, CreatedAt, CreatedBy)
    VALUES ('6000_SELF_SERVICE', NULL, N'Cổng Tự Phục Vụ', 'Self Service', '/self-service', NULL, 1, 1, 1, 10, N'Cổng thông tin tự phục vụ cá nhân', GETDATE(), 'ADMIN');
END

-- 2. Chuyển "User Overview" (Tổng quan cá nhân) vào 6000_SELF_SERVICE
IF EXISTS (SELECT 1 FROM ProgramMenus WHERE ProgramKey IN ('2030', '6001_USER_OVERVIEW'))
BEGIN
    UPDATE ProgramMenus
    SET ProgramKey = '6001_USER_OVERVIEW',
        ParentProgramKey = '6000_SELF_SERVICE',
        ProgramName = N'User Overview',
        ProgramGroup = 'Self Service',
        Path = '/self-service/user-overview',
        Level = 2,
        SortOrder = 1,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'dashboard',
        Comment = N'Màn hình Tổng quan cá nhân nhân viên',
        UpdatedAt = GETDATE(),
        UpdatedBy = 'ADMIN'
    WHERE ProgramKey IN ('2030', '6001_USER_OVERVIEW');
END
ELSE
BEGIN
    INSERT INTO ProgramMenus (ProgramKey, ParentProgramKey, ProgramName, ProgramGroup, Path, ApiUrl, Level, UseFlag, MenuFlag, SortOrder, Comment, Icon, CreatedAt, CreatedBy)
    VALUES ('6001_USER_OVERVIEW', '6000_SELF_SERVICE', N'User Overview', 'Self Service', '/self-service/user-overview', NULL, 2, 1, 1, 1, N'Màn hình Tổng quan cá nhân nhân viên', 'dashboard', GETDATE(), 'ADMIN');
END

-- 3. Chuyển "Overview Analytics" (Tổng quan phân tích) vào 6000_SELF_SERVICE
IF EXISTS (SELECT 1 FROM ProgramMenus WHERE ProgramKey IN ('2001', '6002_OVERVIEW_ANALYTICS'))
BEGIN
    UPDATE ProgramMenus
    SET ProgramKey = '6002_OVERVIEW_ANALYTICS',
        ParentProgramKey = '6000_SELF_SERVICE',
        ProgramName = N'Overview Analytics',
        ProgramGroup = 'Self Service',
        Path = '/self-service/overview-analytics',
        Level = 2,
        SortOrder = 2,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'bar-chart',
        Comment = N'Màn hình Thống kê phân tích tổng quan',
        UpdatedAt = GETDATE(),
        UpdatedBy = 'ADMIN'
    WHERE ProgramKey IN ('2001', '6002_OVERVIEW_ANALYTICS');
END
ELSE
BEGIN
    INSERT INTO ProgramMenus (ProgramKey, ParentProgramKey, ProgramName, ProgramGroup, Path, ApiUrl, Level, UseFlag, MenuFlag, SortOrder, Comment, Icon, CreatedAt, CreatedBy)
    VALUES ('6002_OVERVIEW_ANALYTICS', '6000_SELF_SERVICE', N'Overview Analytics', 'Self Service', '/self-service/overview-analytics', NULL, 2, 1, 1, 2, N'Màn hình Thống kê phân tích tổng quan', 'bar-chart', GETDATE(), 'ADMIN');
END

-- 4. Sắp xếp lại thứ tự các menu con trong CỔNG TỰ PHỤC VỤ
UPDATE ProgramMenus SET SortOrder = 3 WHERE ProgramKey = '6010_WORK_SCHEDULE';
UPDATE ProgramMenus SET SortOrder = 4 WHERE ProgramKey = '6020_DAILY_WORK_TIME';
UPDATE ProgramMenus SET SortOrder = 5 WHERE ProgramKey = '6030_MEAL_ORDER';
UPDATE ProgramMenus SET SortOrder = 6 WHERE ProgramKey = '6040_MY_PAYSLIP';

-- 5. Cấp quyền xem cho tất cả các nhóm quyền đối với Cổng Tự Phục Vụ & 2 màn hình mới
INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
SELECT ag.GroupId, pm.ProgramId, 1, 0, 0, 0, 0, 0
FROM AuthorGroups ag
CROSS JOIN ProgramMenus pm
WHERE pm.ProgramKey IN ('6000_SELF_SERVICE', '6001_USER_OVERVIEW', '6002_OVERVIEW_ANALYTICS')
  AND NOT EXISTS (
      SELECT 1 FROM AuthorGroupMapping x WHERE x.GroupId = ag.GroupId AND x.ProgramId = pm.ProgramId
  );

UPDATE AuthorGroupMapping
SET IsSearch = 1
WHERE ProgramId IN (
    SELECT ProgramId FROM ProgramMenus WHERE ProgramKey IN ('6000_SELF_SERVICE', '6001_USER_OVERVIEW', '6002_OVERVIEW_ANALYTICS')
);

-- Admin toàn quyền
UPDATE AuthorGroupMapping
SET IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
WHERE GroupId = 1 AND ProgramId IN (
    SELECT ProgramId FROM ProgramMenus WHERE ProgramKey IN ('6000_SELF_SERVICE', '6001_USER_OVERVIEW', '6002_OVERVIEW_ANALYTICS')
);

-- 6. Xóa bỏ hoàn toàn các màn hình đã bị xóa mềm (UseFlag = 0) và nhóm Trang Chủ (2000) cũ
DELETE FROM AuthorGroupMapping
WHERE ProgramId IN (
    SELECT ProgramId FROM ProgramMenus WHERE UseFlag = 0 OR ProgramKey = '2000'
);

DELETE FROM ProgramMenus
WHERE UseFlag = 0 OR ProgramKey = '2000';

PRINT N'Cập nhật thành công: Đã chuyển User Overview và Overview Analytics vào Cổng Tự Phục Vụ, dọn dẹp toàn bộ menu bị xóa mềm!';
