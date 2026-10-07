-- ==============================================================================
-- Migration Script: V20261007_01__Seed_Default_Admin_Account.sql
-- Mục đích: Kiểm tra và tự động khởi tạo tài khoản quản trị viên 'admin'
--           với mật khẩu mặc định 'Hansol@12345' (BCrypt WorkFactor 11)
--           và kích hoạt cờ MustChangePassword = 1 (bắt buộc đổi mật khẩu khi đăng nhập lần đầu)
-- Ngày tạo: 2026-10-07
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== BẮT ĐẦU KIỂM TRA VÀ KHỞI TẠO TÀI KHOẢN ADMIN MẶC ĐỊNH ===';

    -- 1. Kiểm tra sự tồn tại của tài khoản admin (không phân biệt hoa/thường)
    IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE UPPER(UserCode) = 'ADMIN')
    BEGIN
        PRINT N'-> Tài khoản "admin" đã tồn tại trong CSDL. Bỏ qua bước tạo mới.';
    END
    ELSE
    BEGIN
        PRINT N'-> Không tìm thấy tài khoản "admin". Đang tiến hành tạo mới...';

        -- 2. Đảm bảo nhóm quyền Administrator tồn tại trong AuthorGroups
        DECLARE @AdminGroupId INT = NULL;

        SELECT TOP 1 @AdminGroupId = GroupId
        FROM [dbo].[AuthorGroups]
        WHERE UPPER(GroupName) IN ('ADMINISTRATOR', 'ADMIN') OR GroupId = 1
        ORDER BY CASE WHEN UPPER(GroupName) = 'ADMINISTRATOR' THEN 1 WHEN UPPER(GroupName) = 'ADMIN' THEN 2 ELSE 3 END;

        IF @AdminGroupId IS NULL
        BEGIN
            INSERT INTO [dbo].[AuthorGroups] (SecureId, GroupName, UseFlag, Comment)
            VALUES (NEWID(), 'Administrator', 1, N'Nhóm Quản trị viên Toàn quyền hệ thống');
            SET @AdminGroupId = SCOPE_IDENTITY();
            PRINT N'-> Đã tạo mới nhóm quyền "Administrator" với GroupId = ' + CAST(@AdminGroupId AS NVARCHAR(10));
        END
        ELSE
        BEGIN
            PRINT N'-> Sử dụng nhóm quyền "Administrator" hiện có: GroupId = ' + CAST(@AdminGroupId AS NVARCHAR(10));
        END

        -- 3. Băm mật khẩu mặc định Hansol@12345 với BCrypt WorkFactor 11
        DECLARE @PasswordHash VARCHAR(255) = '$2a$11$D9uPuIkrwhHV2VjSGsE0aeBpTzKLeFOV2kjZ5juPAiPRDuzYXZSEa';
        DECLARE @AdminSecureId UNIQUEIDENTIFIER = NEWID();

        -- 4. Thêm tài khoản admin vào bảng Users với MustChangePassword = 1
        INSERT INTO [dbo].[Users] (
            SecureId, UserCode, PasswordHash, FullName, Email, Status,
            Plant, Area, MustChangePassword, VendorName, ContractType,
            IsPregnant, HasYoungChild, Comment, CreatedBy, CreatedAt, UseFlag
        )
        VALUES (
            @AdminSecureId, 'admin', @PasswordHash, N'System Administrator', 'admin@hansol.com', 1,
            'TECH_H', NULL, 1, 'INTERNAL', 'OFFICIAL',
            0, 0, N'Tài khoản Quản trị viên hệ thống (Tự động khởi tạo lần đầu khởi động)', 'SYSTEM', GETUTCDATE(), 1
        );

        DECLARE @NewUserId INT = SCOPE_IDENTITY();
        PRINT N'-> Đã tạo thành công User "admin" với UserId = ' + CAST(@NewUserId AS NVARCHAR(10));

        -- 5. Ánh xạ User vào nhóm Administrator trong UserGroupMapping
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserGroupMapping] WHERE UserId = @NewUserId AND GroupId = @AdminGroupId)
        BEGIN
            INSERT INTO [dbo].[UserGroupMapping] (UserId, GroupId)
            VALUES (@NewUserId, @AdminGroupId);
            PRINT N'-> Đã gán User "admin" vào nhóm quyền GroupId = ' + CAST(@AdminGroupId AS NVARCHAR(10));
        END

        -- 6. Gán toàn bộ quyền menu cho nhóm Administrator trong AuthorGroupMapping
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProgramMenus')
        BEGIN
            INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
            SELECT @AdminGroupId, pm.ProgramId, 1, 1, 1, 1, 1, 1
            FROM [dbo].[ProgramMenus] pm
            WHERE pm.UseFlag = 1
              AND NOT EXISTS (
                  SELECT 1 FROM [dbo].[AuthorGroupMapping] agm
                  WHERE agm.GroupId = @AdminGroupId AND agm.ProgramId = pm.ProgramId
              );
            PRINT N'-> Đã cấp toàn bộ quyền ProgramMenus cho nhóm Administrator.';
        END

        -- 7. Khởi tạo cấu hình giao diện mặc định trong User_Theme_Settings
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'User_Theme_Settings')
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [dbo].[User_Theme_Settings] WHERE UserCode = 'admin')
            BEGIN
                INSERT INTO [dbo].[User_Theme_Settings] (
                    UserCode, ThemeMode, NavMode, SidebarStyle, ColorWeakness, DefaultLanguage, PrimaryColor, UpdatedAt
                )
                VALUES ('admin', 'light', 'side', 'dark', 0, 'vi-VN', '#0066CC', GETDATE());
                PRINT N'-> Đã khởi tạo cấu hình Theme mặc định cho user "admin".';
            END
        END

        PRINT N'=== HOÀN TẤT KHỞI TẠO TÀI KHOẢN ADMIN (MustChangePassword = 1, Password = Hansol@12345) ===';
    END

    COMMIT TRANSACTION;
    PRINT N'Giao dịch thực thi thành công.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT N'LỖI THỰC THI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
