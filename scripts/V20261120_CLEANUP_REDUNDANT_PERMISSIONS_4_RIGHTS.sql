-- ============================================================================
-- MIGRATION SCRIPT: DỌN DẸP DỮ LIỆU PHÂN QUYỀN DƯ THỪA & CHUẨN HÓA 4 QUYỀN
-- (Use, Edit, Delete, Print)
-- ============================================================================

BEGIN TRANSACTION;

PRINT N'1. Đang xóa các dòng phân quyền rác (toàn bộ cờ bằng 0)...';
DELETE FROM dbo.SYS_AuthorGroupMapping
WHERE IsSearch = 0 
  AND IsCreate = 0 
  AND IsUpdate = 0 
  AND IsDelete = 0 
  AND IsSave = 0 
  AND IsPrint = 0;

PRINT N'2. Đang đồng bộ hóa quyền Edit (IsCreate, IsUpdate, IsSave) thống nhất...';
UPDATE dbo.SYS_AuthorGroupMapping
SET IsCreate = 1, IsUpdate = 1, IsSave = 1
WHERE IsCreate = 1 OR IsUpdate = 1 OR IsSave = 1;

PRINT N'3. Đang đồng bộ hóa quyền Use (IsSearch) cho tất cả các menu có quyền Edit, Delete, Print...';
UPDATE dbo.SYS_AuthorGroupMapping
SET IsSearch = 1
WHERE (IsCreate = 1 OR IsUpdate = 1 OR IsDelete = 1 OR IsPrint = 1)
  AND IsSearch = 0;

PRINT N'4. Đảm bảo nhóm Quản Trị Viên (GroupId = 1) có đầy đủ 4 quyền trên tất cả menu đang dùng...';
INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
SELECT 1, pm.ProgramId, 1, 1, 1, 1, 1, 1
FROM dbo.SYS_ProgramMenus pm
WHERE pm.UseFlag = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm 
      WHERE agm.GroupId = 1 AND agm.ProgramId = pm.ProgramId
  );

UPDATE dbo.SYS_AuthorGroupMapping
SET IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
WHERE GroupId = 1;

COMMIT TRANSACTION;

PRINT N'===> DỌN DẸP VÀ CHUẨN HÓA 4 QUYỀN HOÀN TẤT THÀNH CÔNG!';
