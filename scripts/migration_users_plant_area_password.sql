-- Migration script: Add Area and MustChangePassword, normalize Plant, insert AREA common codes

-- 1. Add Area to Users table
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'Area')
BEGIN
    ALTER TABLE Users ADD Area NVARCHAR(255) NULL;
    PRINT 'Added Area column to Users table.';
END
ELSE
BEGIN
    PRINT 'Area column already exists in Users table.';
END

-- 2. Add MustChangePassword to Users table
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'MustChangePassword')
BEGIN
    ALTER TABLE Users ADD MustChangePassword BIT NOT NULL CONSTRAINT DF_Users_MustChangePassword DEFAULT 0;
    PRINT 'Added MustChangePassword column to Users table.';
END
ELSE
BEGIN
    PRINT 'MustChangePassword column already exists in Users table.';
END

-- 3. Normalize existing Plant values in Users table to CommonCodes ('TECH_H', 'TECH_V')
UPDATE Users
SET Plant = 'TECH_H'
WHERE Plant IN ('HANSOL', 'Technics H', 'Technics test') OR Plant IS NULL OR Plant = '';

UPDATE Users
SET Plant = 'TECH_V'
WHERE Plant = 'Technics V';

PRINT 'Normalized Plant values in Users table.';

-- 4. Seed AREA in CommonCodes if not exists
IF NOT EXISTS (SELECT 1 FROM CommonCodes WHERE GroupCode = 'AREA' AND Code = 'PMD')
BEGIN
    INSERT INTO CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, Comment, CreatedAt, CreatedBy)
    VALUES ('AREA', N'Danh mục Khu vực (Area)', 'PMD', N'AREA (3IN1)', 1, 1, N'Khu vực PMD', GETDATE(), 'SYSTEM');
END

IF NOT EXISTS (SELECT 1 FROM CommonCodes WHERE GroupCode = 'AREA' AND Code = 'PBA')
BEGIN
    INSERT INTO CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, Comment, CreatedAt, CreatedBy)
    VALUES ('AREA', N'Danh mục Khu vực (Area)', 'PBA', N'AREA 1F (VB)', 2, 1, N'Khu vực PBA', GETDATE(), 'SYSTEM');
END

IF NOT EXISTS (SELECT 1 FROM CommonCodes WHERE GroupCode = 'AREA' AND Code = 'LCM')
BEGIN
    INSERT INTO CommonCodes (GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag, Comment, CreatedAt, CreatedBy)
    VALUES ('AREA', N'Danh mục Khu vực (Area)', 'LCM', N'LCM', 3, 1, N'Khu vực LCM', GETDATE(), 'SYSTEM');
END

PRINT 'Seeded AREA into CommonCodes table.';
