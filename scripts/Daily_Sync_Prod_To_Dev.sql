-- ==============================================================================
-- Migration / Maintenance Script: Daily_Sync_Prod_To_Dev.sql
-- Mục đích: ĐỒNG BỘ TỰ ĐỘNG DATABASE CHÍNH (PROD) SANG DATABASE DEV HẰNG NGÀY
-- Nguồn: HRM_ENTERPRISE_DB
-- Đích:  HRM_TEST_DB
-- Tên file tự động sinh theo ngày giờ: HRM_ENTERPRISE_DB_yyyyMMddHHmm.bak
-- Ví dụ: D:\BACKUP\Database\HRM_ENTERPRISE_DB_202611052115.bak
-- ==============================================================================

USE master;

-- Khởi tạo đường dẫn file backup động theo Năm-Tháng-Ngày-Giờ-Phút (yyyyMMddHHmm)
DECLARE @DateStamp NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMddHHmm');
DECLARE @BackupPath NVARCHAR(500) = N'D:\BACKUP\Database\HRM_ENTERPRISE_DB_' + @DateStamp + N'.bak';

PRINT N'=== 1. SAO LƯU (BACKUP) SANG FILE: ' + @BackupPath + N' ===';
-- Lưu ý: Không dùng WITH COMPRESSION vì SQL Server Express Edition không hỗ trợ
BACKUP DATABASE [HRM_ENTERPRISE_DB]
TO DISK = @BackupPath
WITH FORMAT, INIT, NAME = N'HRM_ENTERPRISE_DB Timestamped Backup', STATS = 10;

PRINT N'=== 2. NGẮT CÁC KẾT NỐI ĐANG HOẠT ĐỘNG VÀO DATABASE DEV ===';
-- Chuyển HRM_TEST_DB sang SINGLE_USER để đóng toàn bộ kết nối active
ALTER DATABASE [HRM_TEST_DB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

PRINT N'=== 3. KHÔI PHỤC (RESTORE) ĐÈ TỪ FILE: ' + @BackupPath + N' ===';
-- Ánh xạ đúng logical name của DB chính sang đường dẫn file vật lý của HRM_TEST_DB
RESTORE DATABASE [HRM_TEST_DB]
FROM DISK = @BackupPath
WITH REPLACE,
    MOVE N'HRM_Enterprise_DB' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\HRM_TEST_DB.mdf',
    MOVE N'HRM_Enterprise_DB_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\HRM_TEST_DB_log.ldf',
    STATS = 10;

PRINT N'=== 4. MỞ LẠI KẾT NỐI ĐA NGƯỜI DÙNG CHO DATABASE DEV ===';
ALTER DATABASE [HRM_TEST_DB] SET MULTI_USER;

PRINT N'=== 5. LIÊN KẾT LẠI TÀI KHOẢN HRM_DEV & ĐỒNG BỘ MẬT KHẨU DEV ===';
-- Đảm bảo user HRM_DEV có đầy đủ quyền thao tác sau khi restore đè
EXEC(N'
    USE [HRM_TEST_DB];
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''HRM_DEV'')
    BEGIN
        CREATE USER [HRM_DEV] FOR LOGIN [HRM_DEV];
    END;
    ALTER ROLE [db_owner] ADD MEMBER [HRM_DEV];

    -- Đồng bộ mật khẩu toàn bộ tài khoản ở môi trường Dev về mặc định Hansol@12345
    UPDATE dbo.SYS_Users 
    SET PasswordHash = ''$2a$11$lSvR6ZvCc72Hhk0lxw63uudbJN1VoEdw7SBsB/xmmKt9SWcBlzXlK'',
        Comment = ''0'',
        Status = 1,
        MustChangePassword = 0;
');

PRINT N'✅ HOÀN TẤT ĐỒNG BỘ DỮ LIỆU TỪ HRM_ENTERPRISE_DB SANG HRM_TEST_DB THÀNH CÔNG!';
