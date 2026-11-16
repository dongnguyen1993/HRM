-- ==============================================================================
-- Script: migration_split_hr_positions.sql
-- Mục đích: 
-- 1. Tạo bảng dbo.HR_PositionsGrade chứa toàn bộ các ngạch bậc chuyên môn & lương (GRADE)
-- 2. Đổi tên bảng dbo.HR_Positions thành dbo.HR_PositionsRole chứa chức vụ quản lý (ROLE)
-- 3. Dọn dẹp dữ liệu GRADE và chuẩn hóa 6 chức vụ quản lý điều hành (ROLE)
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Tạo bảng dbo.HR_PositionsGrade nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_PositionsGrade')
BEGIN
    CREATE TABLE dbo.HR_PositionsGrade (
        GradeId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        GradeCode NVARCHAR(50) NOT NULL UNIQUE,
        GradeName NVARCHAR(150) NOT NULL,
        GradeLevel INT NOT NULL DEFAULT 1,
        SortOrder INT NOT NULL DEFAULT 0,
        UseFlag BIT NOT NULL DEFAULT 1,
        Comment NVARCHAR(255) NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedBy NVARCHAR(50) NULL,
        UpdatedAt DATETIME NULL,
        UpdatedBy NVARCHAR(50) NULL
    );
    PRINT N'Đã tạo bảng dbo.HR_PositionsGrade thành công!';
END
ELSE
BEGIN
    PRINT N'Bảng dbo.HR_PositionsGrade đã tồn tại sẵn.';
END
GO

-- 2. Chuyển dữ liệu sang dbo.HR_PositionsGrade
-- Dữ liệu 14 ngạch bậc chuyên môn & lương theo chuẩn file Hansol
IF OBJECT_ID('tempdb..#TempGrades') IS NOT NULL DROP TABLE #TempGrades;

CREATE TABLE #TempGrades (
    GradeCode NVARCHAR(50),
    GradeName NVARCHAR(150),
    GradeLevel INT,
    SortOrder INT
);

INSERT INTO #TempGrades (GradeCode, GradeName, GradeLevel, SortOrder) VALUES
('OPERATOR',    N'Operator (Công nhân)',                              1, 1),
('PART_TIME',   N'Part Time (Bán thời gian)',                         1, 2),
('INTERN',      N'Intern (Thực tập sinh)',                            1, 3),
('J_STAFF',     N'J. Staff (Nhân viên sơ cấp)',                       2, 4),
('STAFF',       N'Staff (Nhân viên)',                                 3, 5),
('SR_STAFF',    N'Sr. Staff (Nhân viên cao cấp)',                     4, 6),
('ASST_MGR',    N'Assistant Manager (Trợ lý / Phó phòng chuyên môn)', 5, 7),
('MANAGER',     N'Manager (Trưởng phòng chuyên môn)',                 6, 8),
('SR_MGR',      N'Sr. Manager (Trưởng phòng cấp cao)',                7, 9),
('TECH',        N'Tech (Kỹ thuật viên)',                              2, 10),
('SR_TECH',     N'Sr. Tech (Kỹ thuật viên chính)',                    3, 11),
('EX_TECH',     N'Ex. Tech (Chuyên gia kỹ thuật - Expert)',           4, 12),
('MS_TECH',     N'Ms. Tech (Bậc thầy kỹ thuật - Master)',             5, 13),
('SR_MS_TECH',  N'Sr. Ms Tech (Kỹ thuật viên trưởng)',                6, 14);

INSERT INTO dbo.HR_PositionsGrade (GradeCode, GradeName, GradeLevel, SortOrder, UseFlag, CreatedAt, CreatedBy)
SELECT t.GradeCode, t.GradeName, t.GradeLevel, t.SortOrder, 1, GETDATE(), 'MIGRATION'
FROM #TempGrades t
WHERE NOT EXISTS (SELECT 1 FROM dbo.HR_PositionsGrade g WHERE g.GradeCode = t.GradeCode);

DROP TABLE #TempGrades;
PRINT N'Đã nạp 14 ngạch bậc chuyên môn vào bảng dbo.HR_PositionsGrade!';
GO

-- 3. Đổi tên bảng dbo.HR_Positions thành dbo.HR_PositionsRole (nếu chưa đổi)
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_Positions')
   AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_PositionsRole')
BEGIN
    EXEC sp_rename 'dbo.HR_Positions', 'HR_PositionsRole';
    PRINT N'Đã đổi tên bảng dbo.HR_Positions thành dbo.HR_PositionsRole!';
END
ELSE IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_PositionsRole')
BEGIN
    PRINT N'Bảng dbo.HR_PositionsRole đã được đổi tên từ trước.';
END
GO

-- 4. Xóa dữ liệu GRADE khỏi bảng dbo.HR_PositionsRole (xử lý an toàn không phụ thuộc cột PositionType)
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_PositionsRole')
BEGIN
    -- 4.1. Đảm bảo SYS_Users không trỏ vào Id sắp xóa
    UPDATE dbo.SYS_Users
    SET PositionId = 1
    WHERE PositionId IN (
        SELECT PositionId FROM dbo.HR_PositionsRole 
        WHERE PositionCode IN (SELECT GradeCode FROM dbo.HR_PositionsGrade)
           OR PositionCode LIKE 'L[0-9]%'
    );

    -- 4.2. Xóa các bản ghi GRADE theo danh sách GradeCode hoặc mã L1-L9 cũ
    DELETE FROM dbo.HR_PositionsRole
    WHERE PositionCode IN (SELECT GradeCode FROM dbo.HR_PositionsGrade)
       OR PositionCode LIKE 'L[0-9]%';

    -- 4.3. Nếu bảng có cột PositionType, xóa thêm các bản ghi PositionType = 'GRADE' bằng Dynamic SQL để tránh lỗi compile Msg 207
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HR_PositionsRole') AND name = 'PositionType')
    BEGIN
        EXEC sp_executesql N'DELETE FROM dbo.HR_PositionsRole WHERE PositionType = ''GRADE'';';
    END

    PRINT N'Đã tách sạch dữ liệu GRADE ra khỏi bảng dbo.HR_PositionsRole!';
END
GO

-- 5. Nạp bổ sung 6 chức vụ quản lý điều hành (ROLE) chuẩn nếu chưa có
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'HR_PositionsRole')
BEGIN
    IF OBJECT_ID('tempdb..#TempRoles') IS NOT NULL DROP TABLE #TempRoles;
    
    CREATE TABLE #TempRoles (
        PositionCode NVARCHAR(50),
        PositionName NVARCHAR(150),
        SortOrder INT
    );

    INSERT INTO #TempRoles (PositionCode, PositionName, SortOrder) VALUES
    ('MEMBER',          N'Member / Staff (Nhân viên không quản lý)',               1),
    ('SUB_LEADER',      N'Sub Leader (Phó nhóm / Phó ca / Chuyền phó)',           2),
    ('LEADER',          N'Leader (Trưởng nhóm / Trưởng ca / Chuyền trưởng)',       3),
    ('SUB_PART_LEADER', N'Sub Part Leader (Phó bộ phận)',                         4),
    ('PART_LEADER',     N'Part Leader (Trưởng bộ phận)',                          5),
    ('DIRECTOR',        N'Director (Giám đốc khối / Giám đốc xưởng)',             6);

    INSERT INTO dbo.HR_PositionsRole (PositionCode, PositionName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    SELECT r.PositionCode, r.PositionName, r.SortOrder, 1, GETDATE(), 'MIGRATION'
    FROM #TempRoles r
    WHERE NOT EXISTS (SELECT 1 FROM dbo.HR_PositionsRole pr WHERE pr.PositionCode = r.PositionCode);

    DROP TABLE #TempRoles;
    PRINT N'Đã đảm bảo 6 chức vụ điều hành chuẩn trong dbo.HR_PositionsRole!';
END
GO
