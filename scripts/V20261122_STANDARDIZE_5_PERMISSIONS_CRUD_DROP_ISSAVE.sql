-- =================================================================================================
-- Migration: V20261122_STANDARDIZE_5_PERMISSIONS_CRUD_DROP_ISSAVE.sql
-- Mô tả: Chuẩn hóa 5 quyền chuẩn CRUD: IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint (Xóa IsSave)
-- =================================================================================================

SET NOCOUNT ON;

PRINT N'1. Kiểm tra và bổ sung cột IsUpdate vào bảng SYS_AuthorGroupMapping...';

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'SYS_AuthorGroupMapping' AND COLUMN_NAME = 'IsUpdate'
)
BEGIN
    ALTER TABLE dbo.SYS_AuthorGroupMapping ADD IsUpdate BIT NOT NULL CONSTRAINT DF_SYS_AuthorGroupMapping_IsUpdate DEFAULT (0);
    PRINT N'-> Đã thêm cột IsUpdate (mặc định 0).';
END
ELSE
BEGIN
    PRINT N'-> Cột IsUpdate đã tồn tại.';
END
GO

PRINT N'2. Di chuyển dữ liệu quyền từ IsSave sang IsUpdate (nếu IsSave tồn tại)...';

IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'SYS_AuthorGroupMapping' AND COLUMN_NAME = 'IsSave'
)
BEGIN
    EXEC sp_executesql N'
        UPDATE dbo.SYS_AuthorGroupMapping
        SET IsUpdate = CASE WHEN IsUpdate = 1 OR IsSave = 1 THEN 1 ELSE 0 END;
    ';
    PRINT N'-> Đã đồng bộ dữ liệu IsSave sang IsUpdate.';

    -- Xóa Default Constraint của IsSave nếu có
    DECLARE @defConstraintName NVARCHAR(200);
    SELECT @defConstraintName = dc.name
    FROM sys.default_constraints dc
    JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.SYS_AuthorGroupMapping')
      AND c.name = 'IsSave';

    IF @defConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE dbo.SYS_AuthorGroupMapping DROP CONSTRAINT ' + @defConstraintName);
        PRINT N'-> Đã xóa Default Constraint của IsSave.';
    END

    ALTER TABLE dbo.SYS_AuthorGroupMapping DROP COLUMN IsSave;
    PRINT N'-> Đã xóa hoàn toàn cột IsSave khỏi bảng SYS_AuthorGroupMapping.';
END
ELSE
BEGIN
    PRINT N'-> Cột IsSave không tồn tại trong CSDL.';
END
GO

PRINT N'3. Đảm bảo Admin (GroupId = 1) có đầy đủ 5 quyền cho mọi menu đang hoạt động...';

UPDATE agm
SET 
    agm.IsSearch = 1,
    agm.IsCreate = 1,
    agm.IsUpdate = 1,
    agm.IsDelete = 1,
    agm.IsPrint  = 1
FROM dbo.SYS_AuthorGroupMapping agm
WHERE agm.GroupId = 1;
GO

PRINT N'4. Bổ sung quyền cho Admin với bất kỳ menu nào chưa có mapping...';

INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint)
SELECT 1, pm.ProgramId, 1, 1, 1, 1, 1
FROM dbo.SYS_ProgramMenus pm
WHERE pm.UseFlag = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm
      WHERE agm.GroupId = 1 AND agm.ProgramId = pm.ProgramId
  );
GO

PRINT N'5. Bổ sung Default Constraint cho IsUpdate nếu chưa có...';

IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints dc
    JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.SYS_AuthorGroupMapping')
      AND c.name = 'IsUpdate'
)
BEGIN
    ALTER TABLE dbo.SYS_AuthorGroupMapping ADD CONSTRAINT DF_SYS_AuthorGroupMapping_IsUpdate DEFAULT (0) FOR IsUpdate;
    PRINT N'-> Đã tạo DF_SYS_AuthorGroupMapping_IsUpdate.';
END
GO

PRINT N'Hoàn thành Migration chuẩn hóa 5 quyền CRUD: IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint (Xóa IsSave)!';
