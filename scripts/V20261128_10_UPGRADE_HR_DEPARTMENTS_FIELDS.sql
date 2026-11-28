-- ============================================================================
-- Migration: V20261128_10_UPGRADE_HR_DEPARTMENTS_FIELDS.sql
-- Mục đích: Bổ sung cột Division (Khối: OFFICE / PROD) và ManagerUserCode (Trưởng bộ phận)
--           cho bảng dbo.HR_Departments (idempotent).
-- ============================================================================

IF COL_LENGTH('dbo.HR_Departments', 'Division') IS NULL
BEGIN
    ALTER TABLE dbo.HR_Departments ADD Division NVARCHAR(30) NULL;
END
GO

IF COL_LENGTH('dbo.HR_Departments', 'ManagerUserCode') IS NULL
BEGIN
    ALTER TABLE dbo.HR_Departments ADD ManagerUserCode NVARCHAR(50) NULL;
END
GO

-- Khởi tạo Khối mặc định theo cây cha DIV_OFFICE (1) và DIV_PROD (2) nếu chưa gán
;WITH DeptHierarchy AS (
    SELECT
        DepartmentId,
        ParentDepartmentId,
        DepartmentCode,
        CASE
            WHEN DepartmentId = 1 OR DepartmentCode = N'DIV_OFFICE' THEN N'OFFICE'
            WHEN DepartmentId = 2 OR DepartmentCode = N'DIV_PROD' THEN N'PROD'
            ELSE NULL
        END AS RootDivision
    FROM dbo.HR_Departments
    WHERE ParentDepartmentId IS NULL AND ISNULL(DeptType, 'HR') = 'HR'
    UNION ALL
    SELECT
        c.DepartmentId,
        c.ParentDepartmentId,
        c.DepartmentCode,
        COALESCE(
            p.RootDivision,
            CASE
                WHEN c.DepartmentCode = N'DIV_OFFICE' THEN N'OFFICE'
                WHEN c.DepartmentCode = N'DIV_PROD' THEN N'PROD'
                ELSE NULL
            END
        ) AS RootDivision
    FROM dbo.HR_Departments c
    INNER JOIN DeptHierarchy p ON c.ParentDepartmentId = p.DepartmentId
    WHERE ISNULL(c.DeptType, 'HR') = 'HR'
)
UPDATE d
SET d.Division = h.RootDivision
FROM dbo.HR_Departments d
INNER JOIN DeptHierarchy h ON d.DepartmentId = h.DepartmentId
WHERE h.RootDivision IS NOT NULL
  AND (d.Division IS NULL OR LTRIM(RTRIM(d.Division)) = N'');
GO
