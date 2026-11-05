-- ==============================================================================
-- Migration Script: V20261104_02__Standardize_SYS_ProgramMenus_Clean.sql
-- Mục đích: CHUẨN HÓA TOÀN DIỆN VÀ LÀM SẠCH 100% BẢNG SYS_ProgramMenus
-- 1. Xóa bỏ hoàn toàn các bản ghi rác: 5000_WORK_HOURS, 6002, 3000, 3010, 1030
-- 2. Quy hoạch lại toàn bộ ProgramKey và ParentProgramKey theo Domain 4 chữ số:
--    - 1000_ESS: 1001 -> 1005
--    - 2000_HR : 2001 -> 2010
--    - 3000_GA : 3001 -> 3003
--    - 4000_SYS: 4001 -> 4009
-- 3. Chuẩn hóa tên tiếng Việt có dấu (N'...'), SortOrder, Icon, Path
-- 4. Đồng bộ đầy đủ phân quyền trong SYS_AuthorGroupMapping
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== BẮT ĐẦU CHUẨN HÓA BẢNG SYS_ProgramMenus ===';

    -- --------------------------------------------------------------------------
    -- 1. DỌN DẸP CÁC BẢN GHI RÁC KHÔNG CÒN SỬ DỤNG
    -- --------------------------------------------------------------------------
    DECLARE @GarbageKeys TABLE (ProgramKey NVARCHAR(100));
    INSERT INTO @GarbageKeys (ProgramKey)
    VALUES ('5000_WORK_HOURS'), ('6002_OVERVIEW_ANALYTICS'), ('3000'), ('3010'), ('1030');

    -- Xóa phân quyền của các menu rác
    DELETE FROM dbo.SYS_AuthorGroupMapping
    WHERE ProgramId IN (
        SELECT ProgramId FROM dbo.SYS_ProgramMenus WHERE ProgramKey IN (SELECT ProgramKey FROM @GarbageKeys)
    );

    -- Xóa các bản ghi rác khỏi SYS_ProgramMenus
    DELETE FROM dbo.SYS_ProgramMenus
    WHERE ProgramKey IN (SELECT ProgramKey FROM @GarbageKeys);
    PRINT N'[CLEANUP] Đã dọn dẹp các menu rác cũ (5000_WORK_HOURS, 6002, 3000, 3010, 1030)';

    -- --------------------------------------------------------------------------
    -- 2. CẬP NHẬT 4 ROOT MENUS (LEVEL 1)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '1000_ESS',
        ProgramName = N'Cổng Tự Phục Vụ (ESS)',
        Path = '/ess',
        ProgramGroup = 'ESS',
        Level = 1,
        ParentProgramKey = NULL,
        SortOrder = 10,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'calendar',
        Comment = N'Phân hệ Cổng Tự Phục Vụ Nhân Viên (ESS) - Tra cứu cá nhân, lịch làm việc, suất ăn & xem phiếu lương'
    WHERE ProgramKey IN ('6000_SELF_SERVICE', '1000_ESS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2000_HR',
        ProgramName = N'Quản Trị Nhân Sự',
        Path = '/hr',
        ProgramGroup = 'HR',
        Level = 1,
        ParentProgramKey = NULL,
        SortOrder = 20,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'team',
        Comment = N'Phân hệ Quản Trị Nhân Sự (HR) - Quản lý hồ sơ, hợp đồng, chấm công máy, ca kíp & tính lương'
    WHERE ProgramKey = '2000_HR';

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '3000_GA',
        ProgramName = N'Quản Trị Hành Chính',
        Path = '/ga',
        ProgramGroup = 'GA',
        Level = 1,
        ParentProgramKey = NULL,
        SortOrder = 30,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'apartment',
        Comment = N'Phân hệ Quản Trị Hành Chính (GA) - Quản lý suất ăn, lịch nhà máy & danh mục phòng ban đặt cơm'
    WHERE ProgramKey = '3000_GA';

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4000_SYS',
        ProgramName = N'Quản Trị Hệ Thống',
        Path = '/sys',
        ProgramGroup = 'SYS',
        Level = 1,
        ParentProgramKey = NULL,
        SortOrder = 40,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'setting',
        Comment = N'Phân hệ Quản Trị Hệ Thống (SYS) - Quản trị người dùng, phân quyền, nhật ký, thông báo & cấu hình thiết bị'
    WHERE ProgramKey IN ('1000_SYS', '4000_SYS');

    -- --------------------------------------------------------------------------
    -- 3. PHÂN HỆ ESS: CỔNG TỰ PHỤC VỤ (1001 -> 1005, CHA: 1000_ESS)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '1001_ESS_OVERVIEW',
        ParentProgramKey = '1000_ESS',
        ProgramGroup = 'ESS',
        Level = 2,
        Path = '/ess/user-overview',
        SortOrder = 11,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'dashboard',
        ProgramName = N'User Overview',
        Comment = N'Màn hình Tổng quan thông tin cá nhân và lối tắt thao tác nhanh'
    WHERE ProgramKey IN ('6001_USER_OVERVIEW', '1001_ESS_OVERVIEW');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '1002_ESS_WORK_SCHEDULE',
        ParentProgramKey = '1000_ESS',
        ProgramGroup = 'ESS',
        Level = 2,
        Path = '/ess/work-schedule',
        SortOrder = 12,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'calendar',
        ProgramName = N'Lịch làm việc của tôi',
        Comment = N'Xem lịch phân ca làm việc và lịch nghỉ phép cá nhân dạng Calendar tháng'
    WHERE ProgramKey IN ('6010_WORK_SCHEDULE', '1002_ESS_WORK_SCHEDULE');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '1003_ESS_DAILY_WORK_TIME',
        ParentProgramKey = '1000_ESS',
        ProgramGroup = 'ESS',
        Level = 2,
        Path = '/ess/daily-work-time',
        SortOrder = 13,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'clock-circle',
        ProgramName = N'Bảng công hàng ngày',
        Comment = N'Bảng chi tiết giờ công hàng ngày và đối soát chấm công trong tháng'
    WHERE ProgramKey IN ('6020_DAILY_WORK_TIME', '1003_ESS_DAILY_WORK_TIME');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '1004_ESS_MEAL_ORDER',
        ParentProgramKey = '1000_ESS',
        ProgramGroup = 'ESS',
        Level = 2,
        Path = '/ess/meal-order',
        SortOrder = 14,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'coffee',
        ProgramName = N'Đăng ký suất ăn',
        Comment = N'Đăng ký suất ăn theo ca ngày và ca đêm cho phòng ban nhà máy MES-Hansol'
    WHERE ProgramKey IN ('6030_MEAL_ORDER', '1004_ESS_MEAL_ORDER');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '1005_ESS_MY_PAYSLIP',
        ParentProgramKey = '1000_ESS',
        ProgramGroup = 'ESS',
        Level = 2,
        Path = '/ess/my-payslip',
        SortOrder = 15,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'wallet',
        ProgramName = N'Phiếu lương của tôi',
        Comment = N'Xem và tải phiếu lương cá nhân hàng tháng (Hỗ trợ in khổ A5 và xem tối ưu trên điện thoại)'
    WHERE ProgramKey IN ('6040_MY_PAYSLIP', '1005_ESS_MY_PAYSLIP');

    -- --------------------------------------------------------------------------
    -- 4. PHÂN HỆ HR: QUẢN TRỊ NHÂN SỰ & GIỜ CÔNG (2001 -> 2010, CHA: 2000_HR)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2001_HR_DEPT',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/departments',
        SortOrder = 21,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'apartment',
        ProgramName = N'Quản lý Phòng ban',
        Comment = N'Quản lý sơ đồ cơ cấu tổ chức và danh mục phòng ban toàn công ty'
    WHERE ProgramKey IN ('2001_DEPT', '2001_HR_DEPT');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2002_HR_CONT',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/contracts',
        SortOrder = 22,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'file-text',
        ProgramName = N'Quản lý Hợp đồng',
        Comment = N'Quản lý thông tin hợp đồng lao động, phụ lục và thời hạn hợp đồng nhân viên'
    WHERE ProgramKey IN ('2002_CONT', '2002_HR_CONT');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2003_HR_LEAV',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/leave-types',
        SortOrder = 23,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'setting',
        ProgramName = N'Cấu hình Nghỉ phép',
        Comment = N'Thiết lập danh mục các loại nghỉ phép và chế độ hưởng lương theo luật lao động'
    WHERE ProgramKey IN ('2003_LEAV', '2003_HR_LEAV');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2004_HR_PAYROLL',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/payroll',
        SortOrder = 24,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'dollar',
        ProgramName = N'Quản lý Bảng lương',
        Comment = N'Quản lý kỳ lương, import dữ liệu tính lương và xuất phiếu lương cho nhân viên'
    WHERE ProgramKey IN ('2004_PAYROLL', '2004_HR_PAYROLL');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2005_HR_SHIFT_SETUP',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/shift-setup',
        SortOrder = 25,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'schedule',
        ProgramName = N'Thiết lập Ca làm việc',
        Comment = N'Định nghĩa khung giờ ca làm việc, thời gian nghỉ giữa ca và quy tắc tính công'
    WHERE ProgramKey IN ('5010_SHIFT_SETUP', '2005_HR_SHIFT_SETUP');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2006_HR_WORK_SUMMARY',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/work-summary',
        SortOrder = 26,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'table',
        ProgramName = N'Tổng hợp Giờ công',
        Comment = N'Tổng hợp dữ liệu công hàng tháng, tính toán ngày công và giờ làm thêm'
    WHERE ProgramKey IN ('5020_WORK_SUMMARY', '2006_HR_WORK_SUMMARY');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2007_HR_MACHINE_RECORDS',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/machine-records',
        SortOrder = 27,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'database',
        ProgramName = N'Dữ liệu máy chấm công',
        Comment = N'Thu thập và đối soát log quẹt thẻ / vân tay từ hệ thống máy chấm công BioStar'
    WHERE ProgramKey IN ('5030_MACHINE_RECORDS', '2007_HR_MACHINE_RECORDS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2008_HR_TIMEOFF_REQUESTS',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/timeoff-requests',
        SortOrder = 28,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'form',
        ProgramName = N'Đơn xin Nghỉ phép',
        Comment = N'Tiếp nhận và phê duyệt đơn xin nghỉ phép, nghỉ việc riêng của nhân viên'
    WHERE ProgramKey IN ('5040_TIMEOFF_REQUESTS', '2008_HR_TIMEOFF_REQUESTS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2009_HR_OT_REGISTRATION',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/ot-registration',
        SortOrder = 29,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'clock-circle',
        ProgramName = N'Đăng ký Tăng ca',
        Comment = N'Quản lý đăng ký làm thêm giờ (OT) trước ca và sau ca làm việc'
    WHERE ProgramKey IN ('5050_OT_REGISTRATION', '2009_HR_OT_REGISTRATION');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '2010_HR_WORK_TIME_REPORT',
        ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Level = 2,
        Path = '/hr/work-time-report',
        SortOrder = 30,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'bar-chart',
        ProgramName = N'Báo cáo Giờ công',
        Comment = N'Báo cáo thống kê chi tiết tỷ lệ đi làm, vắng mặt và số giờ làm thêm toàn nhà máy'
    WHERE ProgramKey IN ('5060', '2010_HR_WORK_TIME_REPORT');

    -- --------------------------------------------------------------------------
    -- 5. PHÂN HỆ GA: QUẢN TRỊ HÀNH CHÍNH (3001 -> 3003, CHA: 3000_GA)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '3001_GA_MEAL_MANAGEMENT',
        ParentProgramKey = '3000_GA',
        ProgramGroup = 'GA',
        Level = 2,
        Path = '/ga/meal-management',
        SortOrder = 31,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'coffee',
        ProgramName = N'Quản lý suất ăn',
        Comment = N'Tổng hợp báo cáo suất ăn hàng ngày, xuất dữ liệu Canteen và kiểm soát số lượng cơm'
    WHERE ProgramKey IN ('MEAL_MANAGEMENT', '3001_GA_MEAL_MANAGEMENT');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '3002_GA_WORK_CALENDAR',
        ParentProgramKey = '3000_GA',
        ProgramGroup = 'GA',
        Level = 2,
        Path = '/ga/work-calendar',
        SortOrder = 32,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'calendar',
        ProgramName = N'Lịch làm việc & Suất ăn',
        Comment = N'Thiết lập lịch làm việc nhà máy, ngày nghỉ lễ và cấu hình các bữa ăn đặc biệt'
    WHERE ProgramKey IN ('WORK_CALENDAR', '3002_GA_WORK_CALENDAR');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '3003_GA_DEPARTMENTS',
        ParentProgramKey = '3000_GA',
        ProgramGroup = 'GA',
        Level = 2,
        Path = '/ga/departments',
        SortOrder = 33,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'team',
        ProgramName = N'Quản lý Phòng ban (GA)',
        Comment = N'Quản lý danh sách phòng ban đặt cơm phục vụ đối soát số lượng suất ăn nhà máy'
    WHERE ProgramKey IN ('GA_DEPARTMENTS', '3003_GA_DEPARTMENTS');

    -- --------------------------------------------------------------------------
    -- 6. PHÂN HỆ SYS: QUẢN TRỊ HỆ THỐNG (4001 -> 4009, CHA: 4000_SYS)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4001_SYS_USERS',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/user-management',
        SortOrder = 41,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'user',
        ProgramName = N'Quản lý Người dùng',
        Comment = N'Quản lý danh sách tài khoản, thông tin nhân viên, cấp phát và khóa quyền đăng nhập'
    WHERE ProgramKey IN ('1003', '4001_SYS_USERS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4002_SYS_PERMISSIONS',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/permission-mapping',
        SortOrder = 42,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'key',
        ProgramName = N'Phân quyền Người dùng',
        Comment = N'Thiết lập ma trận phân quyền chi tiết (Xem, Thêm, Sửa, Xóa, Lưu, In) theo vai trò'
    WHERE ProgramKey IN ('1007', '4002_SYS_PERMISSIONS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4003_SYS_MENUS',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/menu-management',
        SortOrder = 43,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'menu',
        ProgramName = N'Quản lý Menu & Màn hình',
        Comment = N'Quản lý cấu trúc cây menu đa cấp, biểu tượng icon và đường dẫn routing toàn hệ thống'
    WHERE ProgramKey IN ('1002', '4003_SYS_MENUS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4004_SYS_COMMON_CODE',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/common-code',
        SortOrder = 44,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'tags',
        ProgramName = N'Mã Dùng Chung',
        Comment = N'Quản lý từ điển mã danh mục dùng chung (Chức vụ, ca kíp, loại suất ăn, trạng thái)'
    WHERE ProgramKey IN ('1040', '4004_SYS_COMMON_CODE');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4005_SYS_AUDIT_LOGS',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/audit-logs',
        SortOrder = 45,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'file-search',
        ProgramName = N'Nhật ký Hoạt động',
        Comment = N'Theo dõi và truy vết lịch sử thao tác thêm, sửa, xóa dữ liệu nhạy cảm của người dùng'
    WHERE ProgramKey IN ('1050', '4005_SYS_AUDIT_LOGS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4006_SYS_SIGNIN_LOGS',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/sign-in-logs',
        SortOrder = 46,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'login',
        ProgramName = N'Nhật ký Đăng nhập',
        Comment = N'Giám sát lịch sử đăng nhập, địa chỉ IP, thiết bị truy cập và cảnh báo đăng nhập bất thường'
    WHERE ProgramKey IN ('1060', '4006_SYS_SIGNIN_LOGS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4007_SYS_ANNOUNCEMENTS',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/announcements',
        SortOrder = 47,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'sound',
        ProgramName = N'Bảng tin & Thông báo',
        Comment = N'Đăng tải thông báo chung, tin tức nội bộ công ty và nhắc việc đến toàn thể nhân viên'
    WHERE ProgramKey IN ('1070', '4007_SYS_ANNOUNCEMENTS');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4008_SYS_NOTIFICATION_MATRIX',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/notification-matrix',
        SortOrder = 48,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'bell',
        ProgramName = N'Cấu hình Thông Báo Động',
        Comment = N'Cấu hình ma trận nhận thông báo tự động (Email, In-App) theo sự kiện nghiệp vụ'
    WHERE ProgramKey IN ('1080', '4008_SYS_NOTIFICATION_MATRIX');

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramKey = '4009_SYS_DEVICE_SETUP',
        ParentProgramKey = '4000_SYS',
        ProgramGroup = 'SYS',
        Level = 2,
        Path = '/sys/device-setup',
        SortOrder = 49,
        UseFlag = 1,
        MenuFlag = 1,
        Icon = 'hdd',
        ProgramName = N'Cấu hình Thiết bị & Cổng Chấm Công',
        Comment = N'Thiết lập danh mục máy chấm công, địa chỉ IP kết nối và phân bổ cửa quẹt thẻ'
    WHERE ProgramKey IN ('5070_DEVICE_SETUP', '4009_SYS_DEVICE_SETUP');

    -- --------------------------------------------------------------------------
    -- 7. ĐỒNG BỘ BẢNG PHÂN QUYỀN SYS_AuthorGroupMapping
    -- --------------------------------------------------------------------------
    -- 7.1. Nhóm 1: Administrator có đầy đủ quyền với toàn bộ 31 menu
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 1, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 1 AND agm.ProgramId = pm.ProgramId);

    UPDATE agm
    SET IsSearch = 1, IsCreate = 1, IsUpdate = 1, IsDelete = 1, IsSave = 1, IsPrint = 1
    FROM dbo.SYS_AuthorGroupMapping agm
    JOIN dbo.SYS_ProgramMenus pm ON agm.ProgramId = pm.ProgramId
    WHERE agm.GroupId = 1 AND pm.UseFlag = 1;

    -- 7.2. Nhóm 3002: Quản Trị Nhân Sự (HR Officer) - cấp quyền đầy đủ phân hệ HR & ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 3002, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup IN ('HR', 'ESS')
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 3002 AND agm.ProgramId = pm.ProgramId);

    -- 7.3. Nhóm 3003: Quản Trị Hành Chính (GA Officer) - cấp quyền đầy đủ phân hệ GA & ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 3003, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup IN ('GA', 'ESS')
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 3003 AND agm.ProgramId = pm.ProgramId);

    -- 7.4. Nhóm 2003: Quản Lý Suất Ăn (Meal Manager) - cấp quyền xem/sửa phân hệ GA & ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 2003, pm.ProgramId, 1, 1, 1, 0, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND (pm.ProgramKey IN ('3001_GA_MEAL_MANAGEMENT', '3000_GA', '3002_GA_WORK_CALENDAR') OR pm.ProgramGroup = 'ESS')
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 2003 AND agm.ProgramId = pm.ProgramId);

    -- 7.5. Nhóm User (2002) & Worker (1002): Cấp quyền phân hệ ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT g.GroupId, pm.ProgramId, 1, 1, 1, 0, 1, 1
    FROM (VALUES (1002), (2002)) AS g(GroupId)
    CROSS JOIN dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup = 'ESS'
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = g.GroupId AND agm.ProgramId = pm.ProgramId);

    -- --------------------------------------------------------------------------
    -- 8. ĐỒNG BỘ TARGETLINK TRONG BẢNG SYS_NotificationEvents
    -- --------------------------------------------------------------------------
    IF OBJECT_ID('dbo.SYS_NotificationEvents', 'U') IS NOT NULL
    BEGIN
        UPDATE dbo.SYS_NotificationEvents SET TargetLink = '/ga/meal-management' WHERE EventCode IN ('MEAL_ORDER_SUBMITTED', 'MEAL_ORDER_ADJUSTED');
        UPDATE dbo.SYS_NotificationEvents SET TargetLink = '/hr/timeoff-requests' WHERE EventCode IN ('TIMEOFF_REQUEST_CREATED', 'TIMEOFF_REQUEST_PROCESSED');
        UPDATE dbo.SYS_NotificationEvents SET TargetLink = '/ess/my-payslip' WHERE EventCode = 'PAYROLL_PUBLISHED';
        UPDATE dbo.SYS_NotificationEvents SET TargetLink = '/sys/permission-mapping' WHERE EventCode = 'PERMISSION_CHANGED';
        UPDATE dbo.SYS_NotificationEvents SET TargetLink = '/sys/announcements' WHERE EventCode = 'ANNOUNCEMENT_NEW';
    END

    COMMIT TRANSACTION;
    PRINT N'✅ Đã chuẩn hóa toàn diện SYS_ProgramMenus và Phân quyền thành công 100%!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'❌ Lỗi khi chuẩn hóa SYS_ProgramMenus: %s', 16, 1, @ErrMsg);
END CATCH;

