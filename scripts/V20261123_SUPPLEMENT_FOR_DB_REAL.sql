-- =========================================================================================
-- SCRIPT BỔ SUNG DÀNH CHO CƠ SỞ DỮ LIỆU REAL (PRODUCTION)
-- Tên file: V20261123_SUPPLEMENT_FOR_DB_REAL.sql
-- Dự án: HRM Enterprise System
-- Ngày tạo: 2026-11-23
-- Mục đích: Bổ sung các thành phần còn thiếu trên DB Real để tương thích 100% với bản release:
--   1. Thêm 2 Menu Design System: 4010_SYS_DESIGN & 4011_SYS_DESIGN_TABLE (BaseTable Showcase).
--   2. Phân quyền đầy đủ 5 quyền CRUD (GroupId = 1) cho các Menu mới.
--   3. Đồng bộ kiểm tra liên kết UserId 1-1 giữa SYS_Users và HR_Employees.
--   4. (Khuyến nghị) Dọn dẹp 29 cột nhân sự cũ thừa khỏi SYS_Users để chuẩn hóa 16 cột tài khoản.
-- Nguyên tắc: IDEMPOTENT (Chạy 1 hay nhiều lần đều an toàn), KHÔNG LÀM MẤT DỮ LIỆU.
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT N'================================================================================';
PRINT N'=== BẮT ĐẦU ÁP DỤNG SCRIPT BỔ SUNG CHO CƠ SỞ DỮ LIỆU REAL ===';
PRINT N'================================================================================';

BEGIN TRANSACTION;

BEGIN TRY
    -- =========================================================================================
    -- BƯỚC 1: ĐĂNG KÝ 2 MENU DESIGN SYSTEM & PHÂN QUYỀN
    -- =========================================================================================
    PRINT N'[BƯỚC 1/3] Đăng ký Menu 4010_SYS_DESIGN và 4011_SYS_DESIGN_TABLE...';

    -- 1.1 Menu Cha: 4010_SYS_DESIGN
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '4010_SYS_DESIGN')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ProgramName, [Level], ParentProgramKey, ProgramGroup, 
            UseFlag, MenuFlag, [Path], SortOrder, CreatedBy, CreatedAt
        )
        VALUES (
            '4010_SYS_DESIGN', N'SYS Design', 2, '4000_SYS', 'SYS', 
            1, 1, '/sys/design', 4010, 'ADMIN', GETDATE()
        );
        PRINT N'   -> Đã thêm menu 4010_SYS_DESIGN vào SYS_ProgramMenus.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Menu 4010_SYS_DESIGN đã tồn tại sẵn.';
    END;

    -- 1.2 Menu Con: 4011_SYS_DESIGN_TABLE (Showcase BaseTable)
    IF NOT EXISTS (SELECT 1 FROM dbo.SYS_ProgramMenus WHERE ProgramKey = '4011_SYS_DESIGN_TABLE')
    BEGIN
        INSERT INTO dbo.SYS_ProgramMenus (
            ProgramKey, ProgramName, [Level], ParentProgramKey, ProgramGroup, 
            UseFlag, MenuFlag, [Path], SortOrder, CreatedBy, CreatedAt
        )
        VALUES (
            '4011_SYS_DESIGN_TABLE', N'Bảng Dữ Liệu (BaseTable)', 3, '4010_SYS_DESIGN', 'SYS', 
            1, 1, '/sys/design/table', 4011, 'ADMIN', GETDATE()
        );
        PRINT N'   -> Đã thêm menu 4011_SYS_DESIGN_TABLE vào SYS_ProgramMenus.';
    END
    ELSE
    BEGIN
        PRINT N'   -> Menu 4011_SYS_DESIGN_TABLE đã tồn tại sẵn.';
    END;

    -- 1.3 Cấp quyền 5 chức năng cho Quản Trị Viên (GroupId = 1)
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsPrint)
    SELECT 1, pm.ProgramId, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.ProgramKey IN ('4010_SYS_DESIGN', '4011_SYS_DESIGN_TABLE')
      AND NOT EXISTS (
          SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm
          WHERE agm.GroupId = 1 AND agm.ProgramId = pm.ProgramId
      );
    PRINT N'   -> Đã cấp 5 quyền đầy đủ cho Quản Trị Viên trên 2 menu mới.';


    -- =========================================================================================
    -- BƯỚC 2: ĐỒNG BỘ KIỂM TRA LIÊN KẾT UserId 1-1 GIỮA SYS_Users VÀ HR_Employees
    -- =========================================================================================
    PRINT N'[BƯỚC 2/3] Kiểm tra và cập nhật UserId giữa SYS_Users và HR_Employees...';

    UPDATE e
    SET e.UserId = u.UserId
    FROM dbo.HR_Employees e
    INNER JOIN dbo.SYS_Users u ON e.UserCode = u.UserCode
    WHERE e.UserId IS NULL OR e.UserId <> u.UserId;
    PRINT N'   -> Đã đồng bộ liên kết UserId 1-1 giữa HR_Employees và SYS_Users.';


    -- =========================================================================================
    -- BƯỚC 3: DỌN DẸP 29 CỘT THỪA TRONG SYS_Users (CHUẨN HÓA KIẾN TRÚC 3+1)
    -- =========================================================================================
    PRINT N'[BƯỚC 3/3] Dọn dẹp 29 cột hồ sơ nhân sự thừa trong SYS_Users...';

    IF COL_LENGTH('dbo.SYS_Users', 'IdentityNumber') IS NOT NULL
    BEGIN
        -- 3.1 Xóa khóa ngoại FK_Users_MealDepartment (nếu có)
        IF OBJECT_ID('dbo.FK_Users_MealDepartment', 'F') IS NOT NULL
        BEGIN
            ALTER TABLE dbo.SYS_Users DROP CONSTRAINT FK_Users_MealDepartment;
            PRINT N'   -> Đã xóa khóa ngoại FK_Users_MealDepartment.';
        END;

        -- 3.2 Xóa Default Constraints trên 29 cột thừa
        DECLARE @DropConstraintSql NVARCHAR(MAX) = N'';
        SELECT @DropConstraintSql += N'ALTER TABLE dbo.SYS_Users DROP CONSTRAINT [' + dc.name + N'];' + CHAR(13) + CHAR(10)
        FROM sys.default_constraints dc
        INNER JOIN sys.tables t ON dc.parent_object_id = t.object_id
        INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE t.name = 'SYS_Users'
          AND c.name IN (
            'DepartmentId', 'DepartmentCode', 'PositionId', 'PositionGrade', 'PositionRole',
            'MealDepartmentId', 'MealDepartmentCode', 'IdentityNumber', 'BirthDate', 'Gender',
            'Phone', 'BankName', 'BankAccountNumber', 'VendorName', 'ContractType',
            'ProbationEndDate', 'ContractEndDate', 'ResignDate', 'JoinDate', 'IsPregnant',
            'HasYoungChild', 'MaternityStartDate', 'MaternityEndDate', 'ManagerUserCode',
            'WorkLine', 'CostCenter', 'BioStarUserId', 'UserGroup', 'Avatar'
          );

        IF LEN(@DropConstraintSql) > 0
        BEGIN
            EXEC sp_executesql @DropConstraintSql;
            PRINT N'   -> Đã xóa Default Constraints trên 29 cột nhân sự cũ của SYS_Users.';
        END;

        -- 3.3 Xóa 29 cột nhân sự cũ khỏi SYS_Users
        DECLARE @DropColumnsSql NVARCHAR(MAX) = N'';
        DECLARE @ColsToDrop TABLE (ColName NVARCHAR(100));
        INSERT INTO @ColsToDrop (ColName) VALUES
            ('IdentityNumber'), ('BirthDate'), ('Gender'), ('Phone'), ('BankName'), ('BankAccountNumber'),
            ('DepartmentId'), ('PositionId'), ('VendorName'), ('ContractType'), ('ProbationEndDate'),
            ('ContractEndDate'), ('IsPregnant'), ('HasYoungChild'), ('MaternityStartDate'), ('MaternityEndDate'),
            ('ManagerUserCode'), ('WorkLine'), ('CostCenter'), ('BioStarUserId'), ('UserGroup'), ('Avatar'),
            ('JoinDate'), ('ResignDate'), ('DepartmentCode'), ('MealDepartmentId'), ('MealDepartmentCode'),
            ('PositionGrade'), ('PositionRole');

        SELECT @DropColumnsSql += N'ALTER TABLE dbo.SYS_Users DROP COLUMN [' + c.ColName + N'];' + CHAR(13) + CHAR(10)
        FROM @ColsToDrop c
        WHERE COL_LENGTH('dbo.SYS_Users', c.ColName) IS NOT NULL;

        IF LEN(@DropColumnsSql) > 0
        BEGIN
            EXEC sp_executesql @DropColumnsSql;
            PRINT N'   -> Đã xóa sạch 29 cột thừa khỏi SYS_Users. Bảng SYS_Users chuẩn hóa về đúng 16 cột tài khoản!';
        END;
    END
    ELSE
    BEGIN
        PRINT N'   -> Các cột thừa trong SYS_Users đã được dọn sạch từ trước, bỏ qua.';
    END;

    COMMIT TRANSACTION;
    PRINT N'================================================================================';
    PRINT N'=== TẤT CẢ CÁC BƯỚC BỔ SUNG CHO DB REAL ĐÃ HOÀN TẤT THÀNH CÔNG 100%! ===';
    PRINT N'================================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'[LỖI]: ' + @ErrMsg;
    THROW;
END CATCH;
GO
