-- ======================================================================
-- MIGRATION SCRIPT: V20260926_01__Create_User_Theme_Settings_Table.sql
-- Tách riêng thông số tùy chọn giao diện (Theme Mode, Navigation Mode,
-- Sidebar Style, Color Weakness, Default Language, Primary Color)
-- ra bảng độc lập User_Theme_Settings quản lý theo UserCode.
-- ======================================================================

SET NOCOUNT ON;

-- 1. Tạo bảng riêng User_Theme_Settings quản lý theo UserCode
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'User_Theme_Settings')
BEGIN
    CREATE TABLE User_Theme_Settings (
        UserCode NVARCHAR(50) NOT NULL PRIMARY KEY, -- Khóa chính liên kết theo UserCode
        ThemeMode VARCHAR(20) DEFAULT 'light',       -- 'light' (Sáng), 'dark' (Dịu mắt ban đêm)
        NavMode VARCHAR(20) DEFAULT 'side',          -- 'side' (Thanh bên), 'top' (Thanh trên), 'mix' (Hỗn hợp)
        SidebarStyle VARCHAR(20) DEFAULT 'dark',     -- 'light' (Thanh bên sáng), 'dark' (Thanh bên tối)
        ColorWeakness BIT DEFAULT 0,                 -- 0: Tắt, 1: Bật chế độ mù màu
        DefaultLanguage VARCHAR(10) DEFAULT 'vi-VN', -- 'vi-VN' (Tiếng Việt), 'en-US' (English), 'ko-KR' (한국어)
        PrimaryColor VARCHAR(30) DEFAULT '#0066CC',  -- Mã màu chủ đạo (Primary brand color)
        UpdatedAt DATETIME DEFAULT GETDATE(),
        
        CONSTRAINT FK_UserTheme_UserCode FOREIGN KEY (UserCode) 
            REFERENCES Users(UserCode) ON DELETE CASCADE
    );
    PRINT '-> Da tao thanh cong bang User_Theme_Settings.';
END
ELSE
BEGIN
    PRINT '-> Bang User_Theme_Settings da ton tai.';
END
GO

-- 2. Di chuyển dữ liệu cấu hình hiện có từ bảng Users sang User_Theme_Settings (nếu các cột cũ còn tồn tại)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ThemeMode')
BEGIN
    INSERT INTO User_Theme_Settings (UserCode, ThemeMode, NavMode, SidebarStyle, ColorWeakness, DefaultLanguage, PrimaryColor, UpdatedAt)
    SELECT 
        u.UserCode,
        ISNULL(u.ThemeMode, 'light'),
        ISNULL(u.NavMode, 'side'),
        ISNULL(u.SidebarTheme, 'dark'),
        ISNULL(u.ColorWeak, 0),
        ISNULL(u.PreferredLanguage, 'vi-VN'),
        ISNULL(u.PrimaryColor, '#0066CC'),
        GETDATE()
    FROM Users u
    WHERE u.UserCode IS NOT NULL 
      AND NOT EXISTS (SELECT 1 FROM User_Theme_Settings ts WHERE ts.UserCode = u.UserCode);

    PRINT '-> Da di chuyen du lieu tuy chon giao dien tu Users sang User_Theme_Settings.';
END
GO

-- Đảm bảo toàn bộ các User chưa có bản ghi Theme đều được khởi tạo bản ghi mặc định
INSERT INTO User_Theme_Settings (UserCode, ThemeMode, NavMode, SidebarStyle, ColorWeakness, DefaultLanguage, PrimaryColor, UpdatedAt)
SELECT 
    u.UserCode,
    'light',
    'side',
    'dark',
    0,
    'vi-VN',
    '#0066CC',
    GETDATE()
FROM Users u
WHERE u.UserCode IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM User_Theme_Settings ts WHERE ts.UserCode = u.UserCode);
GO

-- 3. Xóa các Default Constraint cũ trên bảng Users trước khi DROP COLUMN
DECLARE @dropConstraintsSql NVARCHAR(MAX) = N'';

SELECT @dropConstraintsSql += N'ALTER TABLE Users DROP CONSTRAINT ' + QUOTENAME(dc.name) + N';' + CHAR(13)
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE dc.parent_object_id = OBJECT_ID('Users')
  AND c.name IN ('ThemeMode', 'NavMode', 'SidebarTheme', 'SidebarStyle', 'ColorWeak', 'ColorWeakness', 'PreferredLanguage', 'DefaultLanguage', 'PrimaryColor');

IF LEN(@dropConstraintsSql) > 0
BEGIN
    EXEC sp_executesql @dropConstraintsSql;
    PRINT '-> Da xoa cac default constraint tren cac cot theme cua Users.';
END
GO

-- 4. Xóa bỏ các cột cấu hình giao diện cũ khỏi bảng Users để dọn dẹp CSDL
DECLARE @dropColumnsSql NVARCHAR(MAX) = N'';

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ThemeMode')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN ThemeMode;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'NavMode')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN NavMode;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'SidebarTheme')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN SidebarTheme;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'SidebarStyle')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN SidebarStyle;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ColorWeak')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN ColorWeak;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ColorWeakness')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN ColorWeakness;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PreferredLanguage')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN PreferredLanguage;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'DefaultLanguage')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN DefaultLanguage;' + CHAR(13);

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PrimaryColor')
    SET @dropColumnsSql += N'ALTER TABLE Users DROP COLUMN PrimaryColor;' + CHAR(13);

IF LEN(@dropColumnsSql) > 0
BEGIN
    EXEC sp_executesql @dropColumnsSql;
    PRINT '-> Da xoa bo thanh cong cac cot theme cu khoi bang Users.';
END
GO

PRINT '=== HOAN TAT MIGRATION USER_THEME_SETTINGS ===';
