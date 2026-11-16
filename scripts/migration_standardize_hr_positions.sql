-- ==============================================================================
-- Script: migration_standardize_hr_positions.sql
-- Mục đích: Chuẩn hóa toàn bộ bảng dbo.HR_Positions theo tiêu chuẩn Doanh nghiệp
--           Thay thế hoàn toàn SYS_CommonCodes đối với chức vụ và cấp bậc
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Bổ sung cột PositionType vào dbo.HR_Positions nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HR_Positions') AND name = 'PositionType')
BEGIN
    ALTER TABLE dbo.HR_Positions ADD PositionType NVARCHAR(50) NULL CONSTRAINT DF_HR_Positions_PositionType DEFAULT 'ROLE';
    PRINT N'Đã thêm cột PositionType vào dbo.HR_Positions';
END
GO

-- 2. Dọn dẹp dữ liệu nhóm POSITION_GRADE và POSITION_ROLE khỏi SYS_CommonCodes (không dùng bảng common nữa)
DELETE FROM dbo.SYS_CommonCodes WHERE GroupCode IN ('POSITION_GRADE', 'POSITION_ROLE');
PRINT N'Đã dọn dẹp các mã chức vụ khỏi dbo.SYS_CommonCodes';
GO

-- 3. Tạo bảng tạm chứa dữ liệu chuẩn
IF OBJECT_ID('tempdb..#TempPositions') IS NOT NULL DROP TABLE #TempPositions;

CREATE TABLE #TempPositions (
    PositionId INT,
    PositionCode NVARCHAR(50),
    PositionName NVARCHAR(150),
    PositionType NVARCHAR(50), -- 'ROLE' (Chức vụ điều hành - 직책) hoặc 'GRADE' (Ngạch bậc lương - 직급)
    PositionLevel INT,
    SortOrder INT
);

-- Danh mục CHỨC VỤ ĐIỀU HÀNH (ROLE - 직책): Dùng duyệt đơn & phân quyền
INSERT INTO #TempPositions (PositionId, PositionCode, PositionName, PositionType, PositionLevel, SortOrder) VALUES
(1, 'MEMBER',          N'Member / Staff (Nhân viên không quản lý)',               'ROLE', 1, 1),
(2, 'SUB_LEADER',      N'Sub Leader (Phó nhóm / Phó ca / Chuyền phó)',           'ROLE', 2, 2),
(3, 'LEADER',          N'Leader (Trưởng nhóm / Trưởng ca / Chuyền trưởng)',       'ROLE', 3, 3),
(4, 'SUB_PART_LEADER', N'Sub Part Leader (Phó bộ phận)',                         'ROLE', 4, 4),
(5, 'PART_LEADER',     N'Part Leader (Trưởng bộ phận)',                          'ROLE', 5, 5),
(6, 'DIRECTOR',        N'Director (Giám đốc khối / Giám đốc xưởng)',             'ROLE', 6, 6);

-- Danh mục BẬC LƯƠNG & NGẠCH CHUYÊN MÔN (GRADE - 직급): Dùng tính lương & chế độ
INSERT INTO #TempPositions (PositionId, PositionCode, PositionName, PositionType, PositionLevel, SortOrder) VALUES
(10, 'OPERATOR',    N'Operator (Công nhân)',                             'GRADE', 1, 10),
(11, 'PART_TIME',   N'Part Time (Bán thời gian)',                        'GRADE', 1, 11),
(12, 'INTERN',      N'Intern (Thực tập sinh)',                           'GRADE', 1, 12),
(13, 'J_STAFF',     N'J. Staff (Nhân viên sơ cấp)',                      'GRADE', 2, 13),
(14, 'STAFF',       N'Staff (Nhân viên)',                                'GRADE', 3, 14),
(15, 'SR_STAFF',    N'Sr. Staff (Nhân viên cao cấp)',                    'GRADE', 4, 15),
(16, 'ASST_MGR',    N'Assistant Manager (Trợ lý / Phó phòng chuyên môn)','GRADE', 5, 16),
(17, 'MANAGER',     N'Manager (Trưởng phòng chuyên môn)',                'GRADE', 6, 17),
(18, 'SR_MGR',      N'Sr. Manager (Trưởng phòng cấp cao)',               'GRADE', 7, 18),
(19, 'TECH',        N'Tech (Kỹ thuật viên)',                             'GRADE', 2, 19),
(20, 'SR_TECH',     N'Sr. Tech (Kỹ thuật viên chính)',                   'GRADE', 3, 20),
(21, 'EX_TECH',     N'Ex. Tech (Chuyên gia kỹ thuật - Expert)',          'GRADE', 4, 21),
(22, 'MS_TECH',     N'Ms. Tech (Bậc thầy kỹ thuật - Master)',            'GRADE', 5, 22),
(23, 'SR_MS_TECH',  N'Sr. Ms Tech (Kỹ thuật viên trưởng)',               'GRADE', 6, 23);

-- Cập nhật bản ghi đã tồn tại
UPDATE p
SET p.PositionCode  = t.PositionCode,
    p.PositionName  = t.PositionName,
    p.PositionType  = t.PositionType,
    p.PositionLevel = t.PositionLevel,
    p.SortOrder     = t.SortOrder,
    p.UseFlag       = 1
FROM dbo.HR_Positions p
INNER JOIN #TempPositions t ON p.PositionId = t.PositionId;

-- Chèn các bản ghi mới chưa có trong HR_Positions
SET IDENTITY_INSERT dbo.HR_Positions ON;

INSERT INTO dbo.HR_Positions (PositionId, PositionCode, PositionName, PositionType, PositionLevel, SortOrder, UseFlag, CreatedAt, CreatedBy)
SELECT t.PositionId, t.PositionCode, t.PositionName, t.PositionType, t.PositionLevel, t.SortOrder, 1, GETDATE(), 'MIGRATION'
FROM #TempPositions t
WHERE NOT EXISTS (SELECT 1 FROM dbo.HR_Positions p WHERE p.PositionId = t.PositionId);

SET IDENTITY_INSERT dbo.HR_Positions OFF;

-- Tắt UseFlag của các vị trí cũ không còn dùng (ví dụ: L7, L8, L9, L11 cũ nếu có id 7, 8, 9, 11 mà bị đè)
UPDATE dbo.HR_Positions
SET UseFlag = 0
WHERE PositionId NOT IN (SELECT PositionId FROM #TempPositions);

DROP TABLE #TempPositions;
PRINT N'Đã chuẩn hóa 100% dữ liệu bảng dbo.HR_Positions';
GO

-- 4. Cập nhật lại PositionId trong dbo.SYS_Users tương ứng với Role điều hành
UPDATE u
SET u.PositionId = p.PositionId
FROM dbo.SYS_Users u
INNER JOIN dbo.HR_Positions p ON u.PositionRole = p.PositionCode AND p.PositionType = 'ROLE';

-- Tài khoản ADMIN gán chức vụ DIRECTOR (PositionId = 6)
UPDATE dbo.SYS_Users
SET PositionId = 6, PositionRole = 'DIRECTOR', PositionGrade = 'SR_MGR'
WHERE UserCode = 'ADMIN' OR UserCode = 'admin';

-- Các nhân viên chưa có PositionId thì gán về MEMBER (PositionId = 1)
UPDATE dbo.SYS_Users
SET PositionId = 1, PositionRole = 'MEMBER'
WHERE PositionId IS NULL OR PositionId NOT IN (SELECT PositionId FROM dbo.HR_Positions WHERE PositionType = 'ROLE');
GO
