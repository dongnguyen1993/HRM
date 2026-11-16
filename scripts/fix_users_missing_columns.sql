-- ==============================================================================
-- Script: fix_users_missing_columns.sql
-- Mục đích: Sửa lỗi 500 khi gọi API /api/sys/users
--           Bổ sung các cột PositionGrade, PositionRole vào dbo.SYS_Users
--           Bổ sung cột PositionLevel, PositionType vào dbo.HR_PositionsRole
-- ==============================================================================
SET NOCOUNT ON;

-- 1. Bổ sung các cột PositionGrade, PositionRole vào dbo.SYS_Users nếu chưa có
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SYS_Users') AND name = 'PositionGrade')
BEGIN
    ALTER TABLE dbo.SYS_Users ADD PositionGrade NVARCHAR(50) NULL;
    PRINT N'✅ Đã thêm cột PositionGrade vào dbo.SYS_Users';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.SYS_Users') AND name = 'PositionRole')
BEGIN
    ALTER TABLE dbo.SYS_Users ADD PositionRole NVARCHAR(50) NULL CONSTRAINT DF_SYS_Users_PositionRole DEFAULT 'MEMBER';
    PRINT N'✅ Đã thêm cột PositionRole vào dbo.SYS_Users';
END
GO

-- 2. Cập nhật dữ liệu mặc định cho User hiện có
UPDATE dbo.SYS_Users
SET PositionRole = 'MEMBER'
WHERE PositionRole IS NULL;

UPDATE dbo.SYS_Users
SET PositionRole = 'DIRECTOR'
WHERE UserCode IN ('ADMIN', 'admin');
GO

-- 3. Bổ sung cột PositionLevel vào dbo.HR_PositionsRole (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HR_PositionsRole') AND name = 'PositionLevel')
BEGIN
    ALTER TABLE dbo.HR_PositionsRole ADD PositionLevel INT NULL CONSTRAINT DF_HR_PositionsRole_PositionLevel DEFAULT 1;
    PRINT N'✅ Đã thêm cột PositionLevel vào dbo.HR_PositionsRole';
END
GO

-- 4. Bổ sung cột PositionType vào dbo.HR_PositionsRole (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HR_PositionsRole') AND name = 'PositionType')
BEGIN
    ALTER TABLE dbo.HR_PositionsRole ADD PositionType NVARCHAR(50) NULL CONSTRAINT DF_HR_PositionsRole_PositionType DEFAULT 'ROLE';
    PRINT N'✅ Đã thêm cột PositionType vào dbo.HR_PositionsRole';
END
GO

-- 5. Đảm bảo PositionId trong SYS_Users hợp lệ (trỏ về 1 nếu đang null hoặc trỏ sai)
UPDATE dbo.SYS_Users
SET PositionId = 1
WHERE PositionId IS NULL 
   OR PositionId NOT IN (SELECT PositionId FROM dbo.HR_PositionsRole);
GO

PRINT N'🚀 ĐÃ HOÀN TẤT ĐỒNG BỘ CSDL! Hãy tải lại trang (F5) trên trình duyệt.';
GO
