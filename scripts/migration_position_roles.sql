-- Migration script: Chuẩn hóa chức danh 직급 (PositionGrade) và chức vụ điều hành 직책 (PositionRole)
-- Tuân thủ bảng mã Unicode N'...' và quy chuẩn Domain

-- 1. Bổ sung cột vào SYS_Users
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SYS_Users') AND name = 'PositionGrade')
BEGIN
    ALTER TABLE dbo.SYS_Users ADD PositionGrade NVARCHAR(50) NULL;
    PRINT N'Đã thêm cột PositionGrade vào SYS_Users';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SYS_Users') AND name = 'PositionRole')
BEGIN
    ALTER TABLE dbo.SYS_Users ADD PositionRole NVARCHAR(50) NULL CONSTRAINT DF_SYS_Users_PositionRole DEFAULT 'MEMBER';
    PRINT N'Đã thêm cột PositionRole vào SYS_Users';
END
GO

-- Cập nhật dữ liệu mặc định cho các User hiện có
UPDATE dbo.SYS_Users
SET PositionRole = 'MEMBER'
WHERE PositionRole IS NULL;

UPDATE dbo.SYS_Users
SET PositionRole = 'DIRECTOR'
WHERE UserCode = 'ADMIN' OR UserCode = 'admin';
GO

-- 2. Thêm nhóm mã dùng chung POSITION_GRADE (직급)
IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'OPERATOR')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'OPERATOR', N'Operator (Công nhân)', 1, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'PART_TIME')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'PART_TIME', N'Part Time (Bán thời gian)', 2, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'INTERN')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'INTERN', N'Intern (Thực tập sinh)', 3, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'J_STAFF')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'J_STAFF', N'J. Staff (Nhân viên sơ cấp)', 4, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'STAFF')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'STAFF', N'Staff (Nhân viên)', 5, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'SR_STAFF')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'SR_STAFF', N'Sr. Staff (Nhân viên cao cấp)', 6, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'ASST_MGR')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'ASST_MGR', N'Assistant Manager (Trợ lý / Phó phòng chuyên môn)', 7, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'MANAGER')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'MANAGER', N'Manager (Trưởng phòng chuyên môn)', 8, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'SR_MGR')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'SR_MGR', N'Sr. Manager (Trưởng phòng cấp cao)', 9, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'TECH')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'TECH', N'Tech (Kỹ thuật viên)', 10, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'SR_TECH')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'SR_TECH', N'Sr. Tech (Kỹ thuật viên chính)', 11, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'EX_TECH')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'EX_TECH', N'Ex. Tech (Chuyên gia kỹ thuật - Expert)', 12, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'MS_TECH')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'MS_TECH', N'Ms. Tech (Bậc thầy kỹ thuật - Master)', 13, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_GRADE' AND Code = 'SR_MS_TECH')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_GRADE', N'Cấp bậc chuyên môn (직급)', 'SR_MS_TECH', N'Sr. Ms Tech (Kỹ thuật viên trưởng)', 14, 1, GETDATE(), 'MIGRATION');
GO

-- 3. Thêm nhóm mã dùng chung POSITION_ROLE (직책)
IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_ROLE' AND Code = 'MEMBER')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_ROLE', N'Chức vụ quản lý điều hành (직책)', 'MEMBER', N'Member / Staff (Nhân viên không quản lý)', 1, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_ROLE' AND Code = 'SUB_LEADER')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_ROLE', N'Chức vụ quản lý điều hành (직책)', 'SUB_LEADER', N'Sub Leader (Phó nhóm / Phó ca / Chuyền phó)', 2, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_ROLE' AND Code = 'LEADER')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_ROLE', N'Chức vụ quản lý điều hành (직책)', 'LEADER', N'Leader (Trưởng nhóm / Trưởng ca / Chuyền trưởng)', 3, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_ROLE' AND Code = 'SUB_PART_LEADER')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_ROLE', N'Chức vụ quản lý điều hành (직책)', 'SUB_PART_LEADER', N'Sub Part Leader (Phó bộ phận)', 4, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_ROLE' AND Code = 'PART_LEADER')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_ROLE', N'Chức vụ quản lý điều hành (직책)', 'PART_LEADER', N'Part Leader (Trưởng bộ phận)', 5, 1, GETDATE(), 'MIGRATION');

IF NOT EXISTS (SELECT 1 FROM dbo.SYS_CommonCodes WHERE GroupCode = 'POSITION_ROLE' AND Code = 'DIRECTOR')
    INSERT INTO dbo.SYS_CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, CreatedAt, CreatedBy)
    VALUES ('POSITION_ROLE', N'Chức vụ quản lý điều hành (직책)', 'DIRECTOR', N'Director (Giám đốc khối / Giám đốc xưởng)', 6, 1, GETDATE(), 'MIGRATION');
GO
