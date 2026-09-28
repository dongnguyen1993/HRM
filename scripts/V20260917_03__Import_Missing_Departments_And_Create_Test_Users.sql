-- ==============================================================================
-- SCRIPT: Import các Phòng Ban còn thiếu từ MachineRecords vào Departments
--         và tạo mỗi phòng ban 1 User riêng để kiểm thử (Test Users)
-- Ngày tạo: 2026-09-17
-- Mật khẩu chung cho tất cả các tài khoản test: 123456
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- ==========================================================================
    -- 1. IMPORT CÁC PHÒNG BAN CÒN THIẾU TỪ DANH SÁCH USERGROUP MACHINERECORDS
    -- ==========================================================================
    PRINT N'=== 1. BẮT ĐẦU IMPORT PHÒNG BAN MỚI ===';

    -- Bảng tạm chứa danh mục phòng ban chuẩn hóa theo MachineRecords
    DECLARE @DeptList TABLE (
        DepartmentCode VARCHAR(50),
        DepartmentName NVARCHAR(150),
        ParentDepartmentCode VARCHAR(50),
        SortOrder INT,
        Comment NVARCHAR(255)
    );

    INSERT INTO @DeptList (DepartmentCode, DepartmentName, ParentDepartmentCode, SortOrder, Comment) VALUES
    -- Khối Sản Xuất (DIV_PROD)
    ('DEPT_3IN1',       N'Bộ Phận 3 Trong 1 (3in1 Dept)',               'DIV_PROD',   10, N'Tương ứng UserGroup 3in1 trong máy chấm công'),
    ('DEPT_PROD_GEN',   N'Khối Sản Xuất Chung (Production General)',    'DIV_PROD',   11, N'Tương ứng UserGroup PRODUCTION trong máy chấm công'),
    ('DEPT_QC',         N'Phòng Quản Lý Chất Lượng (QC Dept)',          'DIV_PROD',   12, N'Tương ứng UserGroup QC trong máy chấm công'),
    ('DEPT_EHS',        N'Phòng Môi Trường & An Toàn (EHS Dept)',       'DIV_PROD',   13, N'Tương ứng UserGroup EHS trong máy chấm công'),
    ('DEPT_MATERIAL',   N'Phòng Quản Lý Vật Tư (Material Dept)',        'DIV_PROD',   14, N'Tương ứng UserGroup MATERIAL trong máy chấm công'),
    ('DEPT_WH',         N'Bộ Phận Kho Vận (Warehouse Dept)',            'DIV_PROD',   15, N'Tương ứng UserGroup WAREHOUSE trong máy chấm công'),
    ('DEPT_TECH_PROD',  N'Phòng Kỹ Thuật Sản Phẩm (Tech Product)',      'DIV_PROD',   16, N'Tương ứng UserGroup TECHNICAL PRODUCT trong máy chấm công'),
    ('DEPT_TECHNO_PROD',N'Phòng Công Nghệ Sản Phẩm (Technology Product)','DIV_PROD', 17, N'Tương ứng UserGroup TECHNOLOGY PRODUCT trong máy chấm công'),

    -- Khối Văn Phòng (DIV_OFFICE)
    ('DEPT_EXIM',       N'Phòng Xuất Nhập Khẩu (EXIM Dept)',            'DIV_OFFICE', 20, N'Tương ứng UserGroup EXIM trong máy chấm công'),
    ('DEPT_SALE',       N'Phòng Kinh Doanh (Sales Dept)',               'DIV_OFFICE', 21, N'Tương ứng UserGroup SALE trong máy chấm công'),
    ('DEPT_PRESIDENT',  N'Ban Tổng Giám Đốc (President Office)',        'DIV_OFFICE', 22, N'Tương ứng UserGroup PRESIDENT trong máy chấm công'),
    ('DEPT_KOREAN',     N'Khối Chuyên Gia Hàn Quốc (Korean Experts)',   'DIV_OFFICE', 23, N'Tương ứng UserGroup KOREAN trong máy chấm công'),
    ('DEPT_KOREAN_HEVH',N'Chuyên Gia HEVH (Korean HEVH)',               'DIV_OFFICE', 24, N'Tương ứng UserGroup KOREAN HEVH trong máy chấm công'),
    ('DEPT_INTERN',     N'Khối Thực Tập Sinh (Intern Dept)',            'DIV_OFFICE', 25, N'Tương ứng UserGroup INTERN trong máy chấm công'),
    ('DEPT_PARTTIME',   N'Khối Bán Thời Gian (Part-time Dept)',         'DIV_OFFICE', 26, N'Tương ứng UserGroup PART TIME trong máy chấm công'),
    ('DEPT_SECURITY',   N'Bộ Phận Bảo Vệ & An Ninh (Security Dept)',    'DIV_OFFICE', 27, N'Tương ứng UserGroup Bao Ve trong máy chấm công'),
    ('DEPT_CLEANING',   N'Đội Vệ Sinh Môi Trường (Cleaning Dept)',      'DIV_OFFICE', 28, N'Tương ứng UserGroup Ve Sinh trong máy chấm công'),
    ('DEPT_GENERAL',    N'Khối Nhân Viên Chung (General Staff)',        'DIV_OFFICE', 29, N'Tương ứng UserGroup All Users trong máy chấm công');

    -- Thêm các phòng ban chưa tồn tại
    INSERT INTO [dbo].[Departments] (
        DepartmentCode, DepartmentName, ParentDepartmentId, [Level], SortOrder, UseFlag, Comment, CreatedAt, CreatedBy
    )
    SELECT 
        src.DepartmentCode,
        src.DepartmentName,
        parent.DepartmentId AS ParentDepartmentId,
        2 AS [Level],
        src.SortOrder,
        1 AS UseFlag,
        src.Comment,
        GETDATE() AS CreatedAt,
        'ADMIN' AS CreatedBy
    FROM @DeptList src
    LEFT JOIN [dbo].[Departments] parent ON src.ParentDepartmentCode = parent.DepartmentCode
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[Departments] d WHERE d.DepartmentCode = src.DepartmentCode
    );

    PRINT N'-> Đã import xong các phòng ban còn thiếu vào bảng Departments!';

    -- ==========================================================================
    -- 2. TẠO MỖI PHÒNG BAN 1 USER RIÊNG ĐỂ TEST ĐĂNG KÝ SUẤT ĂN
    -- ==========================================================================
    PRINT N'=== 2. TẠO TÀI KHOẢN KIỂM THỬ CHO TỪNG PHÒNG BAN ===';

    -- Lấy chuỗi hash chuẩn của mật khẩu '123456'
    DECLARE @PasswordHash VARCHAR(255) = (SELECT TOP 1 PasswordHash FROM [dbo].[Users] WHERE UserCode = 'ADMIN');
    IF @PasswordHash IS NULL
        SET @PasswordHash = '$2a$11$9L4HR9vxKxfWYj7m4auRke2bUM0enzG084GWNO2CEx7yT1TN0uc3y';

    -- Danh sách ánh xạ User Test cho từng phòng ban (bao gồm cả phòng ban cũ và mới)
    DECLARE @TestUserList TABLE (
        UserCode NVARCHAR(50),
        FullName NVARCHAR(150),
        Email VARCHAR(150),
        DepartmentCode VARCHAR(50),
        UserGroup NVARCHAR(100)
    );

    INSERT INTO @TestUserList (UserCode, FullName, Email, DepartmentCode, UserGroup) VALUES
    ('user_hr',          N'Đại Diện - Phòng Nhân Sự',                  'user_hr@hansol.com',          'DEPT_HR',          'HR'),
    ('user_it',          N'Đại Diện - Phòng IT',                       'user_it@hansol.com',          'DEPT_IT',          'IT'),
    ('user_pba',         N'Đại Diện - Xưởng PBA',                      'user_pba@hansol.com',         'DEPT_PBA',         'PBA'),
    ('user_lcm',         N'Đại Diện - Xưởng LCM',                      'user_lcm@hansol.com',         'DEPT_LCM',         'PRODUCTION'),
    ('user_acc',         N'Đại Diện - Phòng Kế Toán',                  'user_acc@hansol.com',         'DEPT_ACC',         'ACC'),
    ('user_ga',          N'Đại Diện - Phòng Hành Chính',               'user_ga@hansol.com',          'DEPT_GA',          'GA'),
    ('user_plan',        N'Đại Diện - Phòng Kế Hoạch',                 'user_plan@hansol.com',        'DEPT_PLAN',        'PLANNING'),
    ('user_purch',       N'Đại Diện - Phòng Thu Mua',                  'user_purch@hansol.com',       'DEPT_PURCH',       'PUR'),
    ('user_3in1',        N'Đại Diện - Bộ Phận 3 Trong 1',              'user_3in1@hansol.com',        'DEPT_3IN1',        '3in1'),
    ('user_prod_gen',    N'Đại Diện - Khối Sản Xuất Chung',            'user_prod_gen@hansol.com',    'DEPT_PROD_GEN',    'PRODUCTION'),
    ('user_qc',          N'Đại Diện - Phòng QC Quản Lý Chất Lượng',    'user_qc@hansol.com',          'DEPT_QC',          'QC'),
    ('user_ehs',         N'Đại Diện - Phòng An Toàn Môi Trường',       'user_ehs@hansol.com',         'DEPT_EHS',         'EHS'),
    ('user_material',    N'Đại Diện - Phòng Quản Lý Vật Tư',           'user_material@hansol.com',    'DEPT_MATERIAL',    'MATERIAL'),
    ('user_wh',          N'Đại Diện - Bộ Phận Kho Vận',                'user_wh@hansol.com',          'DEPT_WH',          'WAREHOUSE'),
    ('user_tech_prod',   N'Đại Diện - Phòng Kỹ Thuật Sản Phẩm',        'user_tech_prod@hansol.com',   'DEPT_TECH_PROD',   'TECHNICAL PRODUCT'),
    ('user_techno_prod', N'Đại Diện - Phòng Công Nghệ Sản Phẩm',       'user_techno_prod@hansol.com', 'DEPT_TECHNO_PROD', 'TECHNOLOGY PRODUCT'),
    ('user_exim',        N'Đại Diện - Phòng Xuất Nhập Khẩu',           'user_exim@hansol.com',        'DEPT_EXIM',        'EXIM'),
    ('user_sale',        N'Đại Diện - Phòng Kinh Doanh',               'user_sale@hansol.com',        'DEPT_SALE',        'SALE'),
    ('user_president',   N'Đại Diện - Ban Tổng Giám Đốc',              'user_president@hansol.com',   'DEPT_PRESIDENT',   'PRESIDENT'),
    ('user_korean',      N'Đại Diện - Chuyên Gia Hàn Quốc',            'user_korean@hansol.com',      'DEPT_KOREAN',      'KOREAN'),
    ('user_korean_hevh', N'Đại Diện - Chuyên Gia HEVH',                'user_korean_hevh@hansol.com', 'DEPT_KOREAN_HEVH', 'KOREAN HEVH'),
    ('user_intern',      N'Đại Diện - Khối Thực Tập Sinh',             'user_intern@hansol.com',      'DEPT_INTERN',      'INTERN'),
    ('user_parttime',    N'Đại Diện - Khối Bán Thời Gian',             'user_parttime@hansol.com',    'DEPT_PARTTIME',    'PART TIME'),
    ('user_security',    N'Đại Diện - Đội Bảo Vệ & An Ninh',           'user_security@hansol.com',    'DEPT_SECURITY',    'Bao Ve'),
    ('user_cleaning',    N'Đại Diện - Đội Vệ Sinh Môi Trường',         'user_cleaning@hansol.com',    'DEPT_CLEANING',    'Ve Sinh'),
    ('user_general',     N'Đại Diện - Khối Văn Phòng Chung',           'user_general@hansol.com',     'DEPT_GENERAL',     'All Users');

    -- Thêm các User kiểm thử vào bảng Users nếu chưa có
    INSERT INTO [dbo].[Users] (
        Plant, SecureId, UserCode, PasswordHash, FullName, Email, [Status], Comment,
        CreatedAt, CreatedBy, DepartmentId, VendorName, ContractType,
        IsPregnant, HasYoungChild, UserGroup, UseFlag
    )
    SELECT 
        'HANSOL' AS Plant,
        NEWID() AS SecureId,
        t.UserCode,
        @PasswordHash AS PasswordHash,
        t.FullName,
        t.Email,
        1 AS [Status],
        NULL AS Comment,
        GETDATE() AS CreatedAt,
        'ADMIN' AS CreatedBy,
        d.DepartmentId,
        'HANSOL' AS VendorName,
        'OFFICIAL' AS ContractType,
        0 AS IsPregnant,
        0 AS HasYoungChild,
        t.UserGroup,
        1 AS UseFlag
    FROM @TestUserList t
    INNER JOIN [dbo].[Departments] d ON t.DepartmentCode = d.DepartmentCode
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[Users] u WHERE u.UserCode = t.UserCode
    );

    PRINT N'-> Đã thêm/cập nhật xong 26 User kiểm thử đại diện cho 26 phòng ban!';

    -- ==========================================================================
    -- 3. GÁN NHÓM QUYỀN (USERGROUPMAPPING) CHO CÁC TEST USER VÀO GROUP 1 (ADMIN)
    -- ==========================================================================
    -- Gán vào GroupId = 1 (Administrator) để các tài khoản test có đầy đủ quyền truy cập toàn bộ tính năng và Cổng Self-Service
    INSERT INTO [dbo].[UserGroupMapping] (UserId, GroupId)
    SELECT 
        u.UserId,
        1 AS GroupId -- Nhóm Administrator
    FROM [dbo].[Users] u
    WHERE u.UserCode IN (SELECT UserCode FROM @TestUserList)
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[UserGroupMapping] ugm WHERE ugm.UserId = u.UserId
      );

    PRINT N'-> Đã gán quyền UserGroupMapping thành công cho toàn bộ User kiểm thử!';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT THÀNH CÔNG TOÀN BỘ SCRIPT ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'LỖI THỰC THI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
