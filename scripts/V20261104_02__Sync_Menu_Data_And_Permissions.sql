-- ==============================================================================
-- Migration Script: V20261104_02__Sync_Menu_Data_And_Permissions.sql
-- Mục đích: ĐỒNG BỘ TOÀN DIỆN DỮ LIỆU MENU & PHÂN QUYỀN TRÊN SERVER
-- 1. Chuẩn hóa đường dẫn Path sang tiền tố Domain (/ess/*, /ga/*, /hr/*, /sys/*)
-- 2. Chuẩn hóa tên Menu tiếng Việt có dấu chuẩn UTF-8 (tiền tố N'...')
-- 3. Gom nhóm danh mục theo kiến trúc Domain 3+1 (ESS, HR, GA, SYS)
-- 4. Đồng bộ bảng phân quyền SYS_AuthorGroupMapping cho Admin và các nhóm vai trò
-- Lưu ý: Chạy script này sau khi đã chạy V20261104_01 (đổi tên bảng sang SYS_*)
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== BẮT ĐẦU ĐỒNG BỘ DỮ LIỆU MENU & PHÂN QUYỀN TRÊN SERVER ===';

    -- --------------------------------------------------------------------------
    -- 1. CHUẨN HÓA 4 ROOT MENUS (LEVEL 1)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ProgramName = N'Cổng Tự Phục Vụ (ESS)',
        Path = '/ess',
        ProgramGroup = 'ESS',
        SortOrder = 10,
        UseFlag = 1,
        MenuFlag = 1,
        Comment = N'Phân hệ Cổng Tự Phục Vụ Nhân Viên (ESS) - Tra cứu cá nhân, xem phiếu lương & gửi yêu cầu'
    WHERE ProgramKey = '6000_SELF_SERVICE';

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramName = N'Quản Trị Nhân Sự',
        Path = '/hr',
        ProgramGroup = 'HR',
        SortOrder = 20,
        UseFlag = 1,
        MenuFlag = 1,
        Comment = N'Phân hệ Quản Trị Nhân Sự (HR) - Quản lý hồ sơ, hợp đồng, chấm công, ca kíp & tính lương'
    WHERE ProgramKey = '2000_HR';

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramName = N'Quản Trị Hành Chính',
        Path = '/ga',
        ProgramGroup = 'GA',
        SortOrder = 30,
        UseFlag = 1,
        MenuFlag = 1,
        Comment = N'Phân hệ Quản Trị Hành Chính (GA) - Quản lý suất ăn, lịch nhà máy & cơ sở vật chất'
    WHERE ProgramKey = '3000_GA';

    UPDATE dbo.SYS_ProgramMenus
    SET ProgramName = N'Quản Trị Hệ Thống',
        Path = '/sys',
        ProgramGroup = 'SYS',
        SortOrder = 40,
        UseFlag = 1,
        MenuFlag = 1,
        Comment = N'Phân hệ Quản Trị Hệ Thống (SYS) - Quản trị tài khoản, phân quyền, bảo mật & giám sát'
    WHERE ProgramKey = '1000_SYS';

    -- Vô hiệu hóa các root menu cũ không dùng
    UPDATE dbo.SYS_ProgramMenus
    SET UseFlag = 0, MenuFlag = 0, SortOrder = 90
    WHERE ProgramKey IN ('5000_WORK_HOURS', '3000', '3010');

    -- --------------------------------------------------------------------------
    -- 2. PHÂN HỆ CỔNG TỰ PHỤC VỤ (ESS / 1000_ESS / 6000_SELF_SERVICE)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE',
        ProgramGroup = 'ESS',
        Path = '/ess/user-overview',
        SortOrder = 11,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'User Overview',
        Comment = N'Màn hình Tổng quan thông tin cá nhân và lối tắt thao tác nhanh'
    WHERE ProgramKey = '6001_USER_OVERVIEW';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE',
        ProgramGroup = 'ESS',
        Path = '/ess/user-overview',
        SortOrder = 12,
        UseFlag = 1,
        MenuFlag = 0,
        ProgramName = N'Overview Analytics',
        Comment = N'Màn hình Thống kê và phân tích dữ liệu tổng quan cá nhân'
    WHERE ProgramKey = '6002_OVERVIEW_ANALYTICS';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE',
        ProgramGroup = 'ESS',
        Path = '/ess/work-schedule',
        SortOrder = 13,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Lịch làm việc của tôi',
        Comment = N'Xem lịch phân ca làm việc và lịch nghỉ phép cá nhân dạng Calendar tháng'
    WHERE ProgramKey = '6010_WORK_SCHEDULE';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE',
        ProgramGroup = 'ESS',
        Path = '/ess/daily-work-time',
        SortOrder = 14,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Bảng công hàng ngày',
        Comment = N'Bảng chi tiết giờ công hàng ngày và đối soát chấm công trong tháng'
    WHERE ProgramKey = '6020_DAILY_WORK_TIME';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE',
        ProgramGroup = 'ESS',
        Path = '/ess/meal-order',
        SortOrder = 15,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Đăng ký suất ăn',
        Comment = N'Đăng ký suất ăn theo ca ngày và ca đêm cho phòng ban nhà máy MES-Hansol'
    WHERE ProgramKey = '6030_MEAL_ORDER';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '6000_SELF_SERVICE',
        ProgramGroup = 'ESS',
        Path = '/ess/my-payslip',
        SortOrder = 16,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Phiếu lương của tôi',
        Comment = N'Xem và tải phiếu lương cá nhân hàng tháng (Hỗ trợ in khổ A5 và xem tối ưu trên điện thoại)'
    WHERE ProgramKey = '6040_MY_PAYSLIP';

    -- --------------------------------------------------------------------------
    -- 3. PHÂN HỆ QUẢN TRỊ NHÂN SỰ & CHẤM CÔNG (HR / 2000_HR)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/departments',
        SortOrder = 21,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý Phòng ban',
        Comment = N'Quản lý sơ đồ cơ cấu tổ chức và danh mục phòng ban toàn công ty'
    WHERE ProgramKey = '2001_DEPT';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/contracts',
        SortOrder = 22,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý Hợp đồng',
        Comment = N'Quản lý thông tin hợp đồng lao động, phụ lục và thời hạn hợp đồng nhân viên'
    WHERE ProgramKey = '2002_CONT';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/leave-types',
        SortOrder = 23,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Cấu hình Nghỉ phép',
        Comment = N'Thiết lập danh mục các loại nghỉ phép và chế độ hưởng lương theo luật lao động'
    WHERE ProgramKey = '2003_LEAV';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/payroll',
        SortOrder = 24,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý Bảng lương',
        Comment = N'Quản lý kỳ lương, import dữ liệu tính lương và xuất phiếu lương cho nhân viên'
    WHERE ProgramKey = '2004_PAYROLL';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/shift-setup',
        SortOrder = 25,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Thiết lập Ca làm việc',
        Comment = N'Định nghĩa khung giờ ca làm việc, thời gian nghỉ giữa ca và quy tắc tính công'
    WHERE ProgramKey = '5010_SHIFT_SETUP';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/work-summary',
        SortOrder = 26,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Tổng hợp Giờ công',
        Comment = N'Tổng hợp dữ liệu công hàng tháng, tính toán ngày công và giờ làm thêm'
    WHERE ProgramKey = '5020_WORK_SUMMARY';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/machine-records',
        SortOrder = 27,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Dữ liệu máy chấm công',
        Comment = N'Thu thập và đối soát log quẹt thẻ / vân tay từ hệ thống máy chấm công BioStar'
    WHERE ProgramKey = '5030_MACHINE_RECORDS';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/timeoff-requests',
        SortOrder = 28,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Đơn xin Nghỉ phép',
        Comment = N'Tiếp nhận và phê duyệt đơn xin nghỉ phép, nghỉ việc riêng của nhân viên'
    WHERE ProgramKey = '5040_TIMEOFF_REQUESTS';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/ot-registration',
        SortOrder = 29,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Đăng ký Tăng ca',
        Comment = N'Quản lý đăng ký làm thêm giờ (OT) trước ca và sau ca làm việc'
    WHERE ProgramKey = '5050_OT_REGISTRATION';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '2000_HR',
        ProgramGroup = 'HR',
        Path = '/hr/work-time-report',
        SortOrder = 30,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Báo cáo Giờ công',
        Comment = N'Báo cáo thống kê chi tiết tỷ lệ đi làm, vắng mặt và số giờ làm thêm toàn nhà máy'
    WHERE ProgramKey = '5060';

    -- --------------------------------------------------------------------------
    -- 4. PHÂN HỆ QUẢN TRỊ HÀNH CHÍNH (GA / 3000_GA)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '3000_GA',
        ProgramGroup = 'GA',
        Path = '/ga/meal-management',
        SortOrder = 31,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý suất ăn',
        Comment = N'Tổng hợp báo cáo suất ăn hàng ngày, xuất dữ liệu Canteen và kiểm soát số lượng cơm'
    WHERE ProgramKey = 'MEAL_MANAGEMENT';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '3000_GA',
        ProgramGroup = 'GA',
        Path = '/ga/work-calendar',
        SortOrder = 32,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Lịch làm việc & Suất ăn',
        Comment = N'Thiết lập lịch làm việc nhà máy, ngày nghỉ lễ và cấu hình các bữa ăn đặc biệt'
    WHERE ProgramKey = 'WORK_CALENDAR';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '3000_GA',
        ProgramGroup = 'GA',
        Path = '/ga/departments',
        SortOrder = 33,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý Phòng ban (GA)',
        Comment = N'Quản lý danh sách phòng ban đặt cơm phục vụ đối soát số lượng suất ăn nhà máy'
    WHERE ProgramKey = 'GA_DEPARTMENTS';

    -- --------------------------------------------------------------------------
    -- 5. PHÂN HỆ QUẢN TRỊ HỆ THỐNG (SYS / 1000_SYS)
    -- --------------------------------------------------------------------------
    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/user-management',
        SortOrder = 41,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý Người dùng',
        Comment = N'Quản lý danh sách tài khoản, thông tin nhân viên, cấp phát và khóa quyền đăng nhập'
    WHERE ProgramKey = '1003';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/permission-mapping',
        SortOrder = 42,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Phân quyền Người dùng',
        Comment = N'Thiết lập ma trận phân quyền chi tiết (Xem, Thêm, Sửa, Xóa, Lưu, In) theo vai trò'
    WHERE ProgramKey = '1007';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/menu-management',
        SortOrder = 43,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Quản lý Menu & Màn hình',
        Comment = N'Quản lý cấu trúc cây menu đa cấp, biểu tượng icon và đường dẫn routing toàn hệ thống'
    WHERE ProgramKey = '1002';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/common-code',
        SortOrder = 44,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Mã Dùng Chung',
        Comment = N'Quản lý từ điển mã danh mục dùng chung (Chức vụ, ca kíp, loại suất ăn, trạng thái)'
    WHERE ProgramKey = '1040';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/audit-logs',
        SortOrder = 45,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Nhật ký Hoạt động',
        Comment = N'Theo dõi và truy vết lịch sử thao tác thêm, sửa, xóa dữ liệu nhạy cảm của người dùng'
    WHERE ProgramKey = '1050';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/sign-in-logs',
        SortOrder = 46,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Nhật ký Đăng nhập',
        Comment = N'Giám sát lịch sử đăng nhập, địa chỉ IP, thiết bị truy cập và cảnh báo đăng nhập bất thường'
    WHERE ProgramKey = '1060';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/announcements',
        SortOrder = 47,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Bảng tin & Thông báo',
        Comment = N'Đăng tải thông báo chung, tin tức nội bộ công ty và nhắc việc đến toàn thể nhân viên'
    WHERE ProgramKey = '1070';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/notification-matrix',
        SortOrder = 48,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Cấu hình Thông Báo Động',
        Comment = N'Cấu hình ma trận nhận thông báo tự động (Email, In-App) theo sự kiện nghiệp vụ'
    WHERE ProgramKey = '1080';

    UPDATE dbo.SYS_ProgramMenus
    SET ParentProgramKey = '1000_SYS',
        ProgramGroup = 'SYS',
        Path = '/sys/device-setup',
        SortOrder = 49,
        UseFlag = 1,
        MenuFlag = 1,
        ProgramName = N'Cấu hình Thiết bị & Cổng Chấm Công',
        Comment = N'Thiết lập danh mục máy chấm công, địa chỉ IP kết nối và phân bổ cửa quẹt thẻ'
    WHERE ProgramKey = '5070_DEVICE_SETUP';

    -- Vô hiệu hóa menu cũ
    UPDATE dbo.SYS_ProgramMenus SET UseFlag = 0, MenuFlag = 0 WHERE ProgramKey = '1030';
    UPDATE dbo.SYS_ProgramMenus SET Path = '/account/settings', MenuFlag = 0 WHERE ProgramKey = '3010';

    -- --------------------------------------------------------------------------
    -- 6. ĐỒNG BỘ PHÂN QUYỀN TRONG BẢNG SYS_AuthorGroupMapping
    -- --------------------------------------------------------------------------
    -- 6.1. Nhóm 1: Administrator có đầy đủ quyền với toàn bộ 3+1
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

    -- 6.2. Nhóm 3002: Quản Trị Nhân Sự (HR Officer) - cấp quyền đầy đủ phân hệ HR & ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 3002, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup IN ('HR', 'ESS')
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 3002 AND agm.ProgramId = pm.ProgramId);

    -- 6.3. Nhóm 3003: Quản Trị Hành Chính (GA Officer) - cấp quyền đầy đủ phân hệ GA & ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 3003, pm.ProgramId, 1, 1, 1, 1, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup IN ('GA', 'ESS')
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 3003 AND agm.ProgramId = pm.ProgramId);

    -- 6.4. Nhóm 2003: Quản Lý Suất Ăn (Meal Manager) - cấp quyền xem/sửa phân hệ GA & ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT 2003, pm.ProgramId, 1, 1, 1, 0, 1, 1
    FROM dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND (pm.ProgramKey IN ('MEAL_MANAGEMENT', '3000_GA', 'WORK_CALENDAR') OR pm.ProgramGroup = 'ESS')
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = 2003 AND agm.ProgramId = pm.ProgramId);

    -- 6.5. Nhóm User (2002) & Worker (1002): Cấp quyền phân hệ ESS
    INSERT INTO dbo.SYS_AuthorGroupMapping (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT g.GroupId, pm.ProgramId, 1, 1, 1, 0, 1, 1
    FROM (VALUES (1002), (2002)) AS g(GroupId)
    CROSS JOIN dbo.SYS_ProgramMenus pm
    WHERE pm.UseFlag = 1 AND pm.ProgramGroup = 'ESS'
      AND NOT EXISTS (SELECT 1 FROM dbo.SYS_AuthorGroupMapping agm WHERE agm.GroupId = g.GroupId AND agm.ProgramId = pm.ProgramId);

    COMMIT TRANSACTION;
    PRINT N'✅ Đã đồng bộ hoàn hảo toàn bộ Menu và Phân quyền CSDL sang chuẩn Domain 3+1!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'❌ Lỗi khi đồng bộ Menu & Phân quyền: %s', 16, 1, @ErrMsg);
END CATCH;
