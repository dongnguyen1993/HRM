-- ==============================================================================
-- Migration Script: V20261102_01__Standardize_Domain_3Plus1_Menus_And_Permissions.sql
-- Mục đích: BƯỚC 1 - Chuẩn hóa ranh giới Domain & Phân quyền Menu trong CSDL
-- Mô hình phân chia 3 + 1:
--   1. SYS (1000_SYS)          : Quản Trị Hệ Thống
--   2. HR  (2000_HR)           : Quản Trị Nhân Sự
--   3. GA  (3000_GA)           : Quản Trị Hành Chính
--   +1. ESS (6000_SELF_SERVICE): Cổng Tự Phục Vụ Nhân Viên
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    -- --------------------------------------------------------------------------
    -- 1. CHUẨN HÓA 4 ROOT MENUS (LEVEL 1)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus
    SET ProgramName = N'Cổng Tự Phục Vụ (ESS)',
        ProgramGroup = 'ESS',
        SortOrder = 10,
        UseFlag = 1,
        MenuFlag = 1
    WHERE ProgramKey = '6000_SELF_SERVICE';

    UPDATE ProgramMenus
    SET ProgramName = N'Quản Trị Nhân Sự',
        ProgramGroup = 'HR',
        SortOrder = 20,
        UseFlag = 1,
        MenuFlag = 1
    WHERE ProgramKey = '2000_HR';

    UPDATE ProgramMenus
    SET ProgramName = N'Quản Trị Hành Chính',
        ProgramGroup = 'GA',
        SortOrder = 30,
        UseFlag = 1,
        MenuFlag = 1
    WHERE ProgramKey = '3000_GA';

    UPDATE ProgramMenus
    SET ProgramName = N'Quản Trị Hệ Thống',
        ProgramGroup = 'SYS',
        SortOrder = 40,
        UseFlag = 1,
        MenuFlag = 1
    WHERE ProgramKey = '1000_SYS';

    -- Vô hiệu hóa các root menu cũ không dùng
    UPDATE ProgramMenus
    SET UseFlag = 0, MenuFlag = 0, SortOrder = 90
    WHERE ProgramKey IN ('5000_WORK_HOURS', '3000', '3010');

    -- --------------------------------------------------------------------------
    -- 2. CHUẨN HÓA CÁC MÀN HÌNH CON THUỘC DOMAIN ESS (6000_SELF_SERVICE)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE', ProgramGroup = 'ESS', SortOrder = 11, UseFlag = 1, MenuFlag = 1, ProgramName = N'User Overview'
    WHERE ProgramKey = '6001_USER_OVERVIEW';

    UPDATE ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE', ProgramGroup = 'ESS', SortOrder = 12, UseFlag = 1, MenuFlag = 0, ProgramName = N'Overview Analytics'
    WHERE ProgramKey = '6002_OVERVIEW_ANALYTICS';

    UPDATE ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE', ProgramGroup = 'ESS', SortOrder = 13, UseFlag = 1, MenuFlag = 1, ProgramName = N'Lịch làm việc của tôi'
    WHERE ProgramKey = '6010_WORK_SCHEDULE';

    UPDATE ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE', ProgramGroup = 'ESS', SortOrder = 14, UseFlag = 1, MenuFlag = 1, ProgramName = N'Bảng công hàng ngày'
    WHERE ProgramKey = '6020_DAILY_WORK_TIME';

    UPDATE ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE', ProgramGroup = 'ESS', SortOrder = 15, UseFlag = 1, MenuFlag = 1, ProgramName = N'Đăng ký suất ăn'
    WHERE ProgramKey = '6030_MEAL_ORDER';

    UPDATE ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE', ProgramGroup = 'ESS', SortOrder = 16, UseFlag = 1, MenuFlag = 1, ProgramName = N'Phiếu lương của tôi'
    WHERE ProgramKey = '6040_MY_PAYSLIP';

    -- --------------------------------------------------------------------------
    -- 3. CHUẨN HÓA CÁC MÀN HÌNH CON THUỘC DOMAIN HR (2000_HR)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 21, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý Phòng ban'
    WHERE ProgramKey = '2001_DEPT';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 22, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý Hợp đồng'
    WHERE ProgramKey = '2002_CONT';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 23, UseFlag = 1, MenuFlag = 1, ProgramName = N'Cấu hình Nghỉ phép'
    WHERE ProgramKey = '2003_LEAV';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 24, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý Bảng lương'
    WHERE ProgramKey = '2004_PAYROLL';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 25, UseFlag = 1, MenuFlag = 1, ProgramName = N'Thiết lập Ca làm việc'
    WHERE ProgramKey = '5010_SHIFT_SETUP';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 26, UseFlag = 1, MenuFlag = 1, ProgramName = N'Tổng hợp Giờ công'
    WHERE ProgramKey = '5020_WORK_SUMMARY';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 27, UseFlag = 1, MenuFlag = 1, ProgramName = N'Dữ liệu máy chấm công'
    WHERE ProgramKey = '5030_MACHINE_RECORDS';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 28, UseFlag = 1, MenuFlag = 1, ProgramName = N'Đơn xin Nghỉ phép'
    WHERE ProgramKey = '5040_TIMEOFF_REQUESTS';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 29, UseFlag = 1, MenuFlag = 1, ProgramName = N'Đăng ký Tăng ca'
    WHERE ProgramKey = '5050_OT_REGISTRATION';

    UPDATE ProgramMenus
    SET ParentProgramKey = '2000_HR', ProgramGroup = 'HR', SortOrder = 30, UseFlag = 1, MenuFlag = 1, ProgramName = N'Báo cáo Giờ công'
    WHERE ProgramKey = '5060';

    -- --------------------------------------------------------------------------
    -- 4. CHUẨN HÓA CÁC MÀN HÌNH CON THUỘC DOMAIN GA (3000_GA)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus
    SET ParentProgramKey = '3000_GA', ProgramGroup = 'GA', SortOrder = 31, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý suất ăn'
    WHERE ProgramKey = 'MEAL_MANAGEMENT';

    UPDATE ProgramMenus
    SET ParentProgramKey = '3000_GA', ProgramGroup = 'GA', SortOrder = 32, UseFlag = 1, MenuFlag = 1, ProgramName = N'Lịch làm việc & Suất ăn'
    WHERE ProgramKey = 'WORK_CALENDAR';

    UPDATE ProgramMenus
    SET ParentProgramKey = '3000_GA', ProgramGroup = 'GA', SortOrder = 33, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý Phòng ban (GA)'
    WHERE ProgramKey = 'GA_DEPARTMENTS';

    -- --------------------------------------------------------------------------
    -- 5. CHUẨN HÓA CÁC MÀN HÌNH CON THUỘC DOMAIN SYS (1000_SYS)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 41, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý Người dùng'
    WHERE ProgramKey = '1003';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 42, UseFlag = 1, MenuFlag = 1, ProgramName = N'Phân quyền Người dùng'
    WHERE ProgramKey = '1007';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 43, UseFlag = 1, MenuFlag = 1, ProgramName = N'Quản lý Menu & Màn hình'
    WHERE ProgramKey = '1002';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 44, UseFlag = 1, MenuFlag = 1, ProgramName = N'Mã Dùng Chung'
    WHERE ProgramKey = '1040';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 45, UseFlag = 1, MenuFlag = 1, ProgramName = N'Nhật ký Hoạt động'
    WHERE ProgramKey = '1050';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 46, UseFlag = 1, MenuFlag = 1, ProgramName = N'Nhật ký Đăng nhập'
    WHERE ProgramKey = '1060';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 47, UseFlag = 1, MenuFlag = 1, ProgramName = N'Bảng tin & Thông báo'
    WHERE ProgramKey = '1070';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 48, UseFlag = 1, MenuFlag = 1, ProgramName = N'Cấu hình Thông Báo Động'
    WHERE ProgramKey = '1080';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 49, UseFlag = 1, MenuFlag = 1, ProgramName = N'Cấu hình Thiết bị & Cổng Chấm Công'
    WHERE ProgramKey = '5070_DEVICE_SETUP';

    UPDATE ProgramMenus
    SET ParentProgramKey = '1000_SYS', ProgramGroup = 'SYS', SortOrder = 50, UseFlag = 1, MenuFlag = 0, ProgramName = N'Cấu hình Hệ thống'
    WHERE ProgramKey = '1030';

    -- --------------------------------------------------------------------------
    -- 6. ĐỒNG BỘ PHÂN QUYỀN AUTHORGROUPMAPPING
    -- --------------------------------------------------------------------------
    -- 6.1. Nhóm 1: Administrator có đầy đủ quyền với toàn bộ 3 + 1
    INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 1, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM ProgramMenus pm
    WHERE pm.UseFlag = 1
      AND NOT EXISTS (SELECT 1 FROM AuthorGroupMapping agm WHERE agm.GroupId = 1 AND agm.ProgramId = pm.ProgramId);

    UPDATE agm
    SET IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
    FROM AuthorGroupMapping agm
    JOIN ProgramMenus pm ON agm.ProgramId = pm.ProgramId
    WHERE agm.GroupId = 1 AND pm.UseFlag = 1;

    -- 6.2. Nhóm 3002: Quản Trị Nhân Sự (HR Officer) - cấp quyền đầy đủ phân hệ HR & ESS
    INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 3002, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup IN ('HR', 'ESS')
      AND NOT EXISTS (SELECT 1 FROM AuthorGroupMapping agm WHERE agm.GroupId = 3002 AND agm.ProgramId = pm.ProgramId);

    -- 6.3. Nhóm 3003: Quản Trị Hành Chính (GA Officer) - cấp quyền đầy đủ phân hệ GA & ESS
    INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 3003, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup IN ('GA', 'ESS')
      AND NOT EXISTS (SELECT 1 FROM AuthorGroupMapping agm WHERE agm.GroupId = 3003 AND agm.ProgramId = pm.ProgramId);

    -- 6.4. Nhóm 2003: Quản Lý Suất Ăn (Meal Manager) - cấp quyền xem/sửa phân hệ GA
    INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 2003, pm.ProgramId, 1, 1, 1, 0, 1, 1
    FROM ProgramMenus pm
    WHERE pm.UseFlag = 1 AND (pm.ProgramKey IN ('MEAL_MANAGEMENT', '3000_GA', 'WORK_CALENDAR') OR pm.ProgramGroup = 'ESS')
      AND NOT EXISTS (SELECT 1 FROM AuthorGroupMapping agm WHERE agm.GroupId = 2003 AND agm.ProgramId = pm.ProgramId);

    -- 6.5. Nhóm User (2002) & Worker (1002): Cấp quyền phân hệ ESS
    INSERT INTO AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT g.GroupId, pm.ProgramId, 1, 1, 1, 0, 1, 1
    FROM (VALUES (1002), (2002)) AS g(GroupId)
    CROSS JOIN ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup = 'ESS'
      AND NOT EXISTS (SELECT 1 FROM AuthorGroupMapping agm WHERE agm.GroupId = g.GroupId AND agm.ProgramId = pm.ProgramId);

    COMMIT TRANSACTION;
    PRINT N'✅ Chuẩn hóa ranh giới Domain & Phân quyền Menu trong CSDL thành công!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'❌ Lỗi khi chuẩn hóa Menu & Phân quyền: %s', 16, 1, @ErrMsg);
END CATCH;
