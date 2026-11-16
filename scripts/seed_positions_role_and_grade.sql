-- ==============================================================================
-- Script: seed_positions_role_and_grade.sql
-- Mục đích: Bổ sung bộ dữ liệu chuẩn doanh nghiệp sản xuất quy mô lớn cho 2 bảng:
--   1. dbo.HR_PositionsRole: Chức vụ quản lý điều hành (직책 - Jik-chaek)
--   2. dbo.HR_PositionsGrade: Bậc lương / Ngạch bậc chuyên môn (직급 - Jik-geup)
-- ==============================================================================
SET NOCOUNT ON;

-- ==============================================================================
-- PHẦN 1: BỔ SUNG DỮ LIỆU BẢNG dbo.HR_PositionsRole (CHỨC VỤ QUẢN LÝ ĐIỀU HÀNH)
-- ==============================================================================
IF OBJECT_ID('tempdb..#SeedRoles') IS NOT NULL DROP TABLE #SeedRoles;

CREATE TABLE #SeedRoles (
    PositionCode NVARCHAR(50),
    PositionName NVARCHAR(150),
    PositionLevel INT,
    SortOrder INT
);

INSERT INTO #SeedRoles (PositionCode, PositionName, PositionLevel, SortOrder) VALUES
-- Cấp nhân viên / tổ viên
('MEMBER',            N'Member / Staff (Nhân viên không quản lý / Tổ viên)',        1, 1),
('LINE_LEADER',       N'Line Leader (Trưởng chuyền / Trưởng dây chuyền)',           2, 2),
('SUB_LEADER',        N'Sub Leader (Phó nhóm / Phó ca / Chuyền phó)',              2, 3),
('LEADER',            N'Leader / Team Leader (Trưởng nhóm / Trưởng ca / Tổ trưởng)', 3, 4),
('CHIEF_LEADER',      N'Chief Leader (Tổ trưởng chính / Trưởng ca cao cấp)',        3, 5),

-- Cấp bộ phận & giám sát xưởng
('SUPERVISOR',        N'Supervisor (Giám sát viên sản xuất / Vận hành)',            4, 6),
('SUB_PART_LEADER',   N'Sub Part Leader (Phó bộ phận)',                             4, 7),
('PART_LEADER',       N'Part Leader (Trưởng bộ phận)',                              5, 8),
('SECTION_CHIEF',     N'Section Chief (Trưởng ban / Trưởng khu vực xưởng)',         5, 9),

-- Cấp quản lý phòng ban
('DEPUTY_MANAGER',    N'Deputy Manager (Phó phòng ban)',                            6, 10),
('DEPARTMENT_HEAD',   N'Department Head (Trưởng phòng ban / Quản lý khối)',         7, 11),

-- Cấp lãnh đạo điều hành nhà máy
('DEPUTY_DIRECTOR',   N'Deputy Director (Phó giám đốc khối / Phó giám đốc xưởng)',  8, 12),
('DIRECTOR',          N'Director (Giám đốc khối / Giám đốc xưởng)',                 9, 13),
('GENERAL_DIRECTOR',  N'General Director (Tổng giám đốc / Giám đốc điều hành CEO)', 10, 14);

-- Chèn các chức vụ chưa có
INSERT INTO dbo.HR_PositionsRole (PositionCode, PositionName, PositionLevel, PositionType, SortOrder, UseFlag, CreatedAt, CreatedBy)
SELECT 
    s.PositionCode, 
    s.PositionName, 
    s.PositionLevel, 
    'ROLE', 
    s.SortOrder, 
    1, 
    GETDATE(), 
    'SEED_DATA'
FROM #SeedRoles s
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.HR_PositionsRole r WHERE r.PositionCode = s.PositionCode
);

-- Cập nhật lại tên và thứ tự nếu đã có sẵn
UPDATE r
SET r.PositionName  = s.PositionName,
    r.PositionLevel = s.PositionLevel,
    r.SortOrder     = s.SortOrder,
    r.UseFlag       = 1
FROM dbo.HR_PositionsRole r
INNER JOIN #SeedRoles s ON r.PositionCode = s.PositionCode;

DROP TABLE #SeedRoles;
PRINT N'✅ Đã nạp và chuẩn hóa 14 chức vụ quản lý điều hành vào dbo.HR_PositionsRole!';
GO

-- ==============================================================================
-- PHẦN 2: BỔ SUNG DỮ LIỆU BẢNG dbo.HR_PositionsGrade (BẬC LƯƠNG & NGẠCH CHUYÊN MÔN)
-- ==============================================================================
IF OBJECT_ID('tempdb..#SeedGrades') IS NOT NULL DROP TABLE #SeedGrades;

CREATE TABLE #SeedGrades (
    GradeCode NVARCHAR(50),
    GradeName NVARCHAR(150),
    GradeLevel INT,
    SortOrder INT,
    Comment NVARCHAR(255)
);

INSERT INTO #SeedGrades (GradeCode, GradeName, GradeLevel, SortOrder, Comment) VALUES
-- Khối Sản xuất & Trực tiếp (Direct Labor)
('INTERN',              N'Intern (Thực tập sinh)',                                1, 1,  N'Thực tập sinh học việc'),
('PART_TIME',           N'Part Time (Bán thời gian / Thời vụ)',                   1, 2,  N'Lao động thời vụ theo giờ'),
('OPERATOR',            N'Operator (Công nhân bậc 1)',                            1, 3,  N'Công nhân sản xuất trực tiếp'),
('OPERATOR_2',          N'Operator Level 2 (Công nhân bậc 2)',                    1, 4,  N'Công nhân có thâm niên từ 1-3 năm'),
('SR_OPERATOR',         N'Sr. Operator (Công nhân lành nghề / Bậc 3)',            2, 5,  N'Công nhân lành nghề trên 3 năm'),
('LEAD_OPERATOR',       N'Lead Operator (Công nhân kỹ thuật chuyền)',             2, 6,  N'Công nhân hỗ trợ kỹ thuật dây chuyền'),

-- Khối Kỹ thuật & Công nghệ (Technical)
('TECH',                N'Tech (Kỹ thuật viên)',                                  2, 7,  N'Kỹ thuật viên bảo trì / thiết bị'),
('SR_TECH',             N'Sr. Tech (Kỹ thuật viên chính)',                        3, 8,  N'Kỹ thuật viên có kinh nghiệm'),
('EX_TECH',             N'Ex. Tech (Chuyên gia kỹ thuật - Expert)',               4, 9,  N'Chuyên gia kỹ thuật tay nghề cao'),
('MS_TECH',             N'Ms. Tech (Bậc thầy kỹ thuật - Master)',                 5, 10, N'Bậc thầy kỹ thuật công nghệ'),
('SR_MS_TECH',          N'Sr. Ms Tech (Kỹ thuật viên trưởng)',                    6, 11, N'Kỹ thuật viên trưởng toàn xưởng'),

-- Khối Kỹ sư (Engineering)
('J_ENGINEER',          N'Junior Engineer (Kỹ sư sơ cấp)',                        2, 12, N'Kỹ sư mới tốt nghiệp'),
('ENGINEER',            N'Engineer (Kỹ sư)',                                      3, 13, N'Kỹ sư chính thức'),
('SR_ENGINEER',         N'Senior Engineer (Kỹ sư cao cấp)',                       4, 14, N'Kỹ sư có kinh nghiệm dày dặn'),
('LEAD_ENGINEER',       N'Lead Engineer (Kỹ sư trưởng dự án)',                    5, 15, N'Kỹ sư trưởng nhóm kỹ thuật / R&D'),
('PRINCIPAL_ENGINEER',  N'Principal Engineer (Chuyên gia kỹ thuật công nghệ cao)', 6, 16, N'Kỹ sư trưởng khối công nghệ'),

-- Khối Văn phòng & Nghiệp vụ (Office Staff & Professional)
('J_STAFF',             N'J. Staff (Nhân viên sơ cấp)',                           2, 17, N'Nhân viên văn phòng mới vào'),
('STAFF',               N'Staff (Nhân viên)',                                     3, 18, N'Nhân viên chính thức'),
('SR_STAFF',            N'Sr. Staff (Nhân viên cao cấp)',                         4, 19, N'Nhân viên văn phòng có kinh nghiệm'),
('SPECIALIST',          N'Specialist (Chuyên viên nghiệp vụ)',                    4, 20, N'Chuyên viên độc lập xử lý nghiệp vụ'),
('SR_SPECIALIST',       N'Senior Specialist (Chuyên viên cao cấp)',               5, 21, N'Chuyên viên giàu kinh nghiệm'),

-- Khối Quản lý chuyên môn & Lãnh đạo (Management & Executive Grade)
('ASST_MGR',            N'Assistant Manager (Trợ lý / Phó phòng chuyên môn)',     5, 22, N'Ngạch cấp phó phòng chuyên môn'),
('MANAGER',             N'Manager (Trưởng phòng chuyên môn)',                     6, 23, N'Ngạch cấp trưởng phòng chuyên môn'),
('SR_MGR',              N'Sr. Manager (Trưởng phòng cấp cao)',                    7, 24, N'Ngạch cấp trưởng phòng cấp cao'),
('EXPERT',              N'Principal / Advisor (Cố vấn / Chuyên gia cao cấp)',     8, 25, N'Cố vấn chiến lược / chuyên gia cấp cao'),
('DIRECTOR_GRADE',      N'Director (Ngạch Giám đốc điều hành)',                   9, 26, N'Ngạch lãnh đạo khối');

-- Chèn các ngạch bậc chưa có
INSERT INTO dbo.HR_PositionsGrade (GradeCode, GradeName, GradeLevel, SortOrder, UseFlag, Comment, CreatedAt, CreatedBy)
SELECT 
    g.GradeCode, 
    g.GradeName, 
    g.GradeLevel, 
    g.SortOrder, 
    1, 
    g.Comment, 
    GETDATE(), 
    'SEED_DATA'
FROM #SeedGrades g
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.HR_PositionsGrade pg WHERE pg.GradeCode = g.GradeCode
);

-- Cập nhật lại tên và thứ tự nếu đã có sẵn
UPDATE pg
SET pg.GradeName  = g.GradeName,
    pg.GradeLevel = g.GradeLevel,
    pg.SortOrder  = g.SortOrder,
    pg.Comment    = g.Comment,
    pg.UseFlag    = 1
FROM dbo.HR_PositionsGrade pg
INNER JOIN #SeedGrades g ON pg.GradeCode = g.GradeCode;

DROP TABLE #SeedGrades;
PRINT N'✅ Đã nạp và chuẩn hóa 26 ngạch bậc chuyên môn vào dbo.HR_PositionsGrade!';
GO

PRINT N'🚀 HOÀN TẤT NẠP DỮ LIỆU ĐẦY ĐỦ CHO CẢ 2 BẢNG HR_PositionsRole VÀ HR_PositionsGrade!';
GO
