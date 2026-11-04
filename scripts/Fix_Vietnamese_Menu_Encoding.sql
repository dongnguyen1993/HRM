-- ==============================================================================
-- Script: Fix_Vietnamese_Menu_Encoding.sql
-- Mục đích: Sửa triệt để toàn bộ lỗi font tiếng Việt (Mojibake) cho cả ProgramName và Comment trong ProgramMenus
-- Lưu ý: File này được lưu chuẩn UTF-8 with BOM / UTF-8
-- ==============================================================================
SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    -- --------------------------------------------------------------------------
    -- 1. ROOT MENUS (Level 1)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus 
    SET ProgramName = N'Cổng Tự Phục Vụ (ESS)',
        Comment = N'Phân hệ Cổng Tự Phục Vụ Nhân Viên (ESS) - Tra cứu cá nhân, xem phiếu lương & gửi yêu cầu'
    WHERE ProgramKey = '6000_SELF_SERVICE';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản Trị Nhân Sự',
        Comment = N'Phân hệ Quản Trị Nhân Sự (HR) - Quản lý hồ sơ, hợp đồng, chấm công, ca kíp & tính lương'
    WHERE ProgramKey = '2000_HR';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản Trị Hành Chính',
        Comment = N'Phân hệ Quản Trị Hành Chính (GA) - Quản lý suất ăn, lịch nhà máy & cơ sở vật chất'
    WHERE ProgramKey = '3000_GA';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản Trị Hệ Thống',
        Comment = N'Phân hệ Quản Trị Hệ Thống (SYS) - Quản trị tài khoản, phân quyền, bảo mật & giám sát'
    WHERE ProgramKey = '1000_SYS';

    UPDATE ProgramMenus 
    SET ProgramName = N'Tài Khoản',
        Comment = N'Quản lý thông tin tài khoản cá nhân'
    WHERE ProgramKey = '3000';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản Lý Giờ Công',
        Comment = N'Phân hệ Quản Lý Giờ Công (Đã gom vào phân hệ HR)'
    WHERE ProgramKey = '5000_WORK_HOURS';

    -- --------------------------------------------------------------------------
    -- 2. ESS SUBMENUS (Level 2 - Cổng Tự Phục Vụ)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus 
    SET ProgramName = N'User Overview',
        Comment = N'Màn hình Tổng quan thông tin cá nhân và lối tắt thao tác nhanh'
    WHERE ProgramKey = '6001_USER_OVERVIEW';

    UPDATE ProgramMenus 
    SET ProgramName = N'Overview Analytics',
        Comment = N'Màn hình Thống kê và phân tích dữ liệu tổng quan cá nhân'
    WHERE ProgramKey = '6002_OVERVIEW_ANALYTICS';

    UPDATE ProgramMenus 
    SET ProgramName = N'Lịch làm việc của tôi',
        Comment = N'Xem lịch phân ca làm việc và lịch nghỉ phép cá nhân dạng Calendar tháng'
    WHERE ProgramKey = '6010_WORK_SCHEDULE';

    UPDATE ProgramMenus 
    SET ProgramName = N'Bảng công hàng ngày',
        Comment = N'Bảng chi tiết giờ công hàng ngày và đối soát chấm công trong tháng'
    WHERE ProgramKey = '6020_DAILY_WORK_TIME';

    UPDATE ProgramMenus 
    SET ProgramName = N'Đăng ký suất ăn',
        Comment = N'Đăng ký suất ăn theo ca ngày và ca đêm cho phòng ban nhà máy MES-Hansol'
    WHERE ProgramKey = '6030_MEAL_ORDER';

    UPDATE ProgramMenus 
    SET ProgramName = N'Phiếu lương của tôi',
        Comment = N'Xem và tải phiếu lương cá nhân hàng tháng (Hỗ trợ in khổ A5 và xem tối ưu trên điện thoại)'
    WHERE ProgramKey = '6040_MY_PAYSLIP';

    -- --------------------------------------------------------------------------
    -- 3. HR SUBMENUS (Level 2 - Quản Trị Nhân Sự)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý Phòng ban',
        Comment = N'Quản lý sơ đồ cơ cấu tổ chức và danh mục phòng ban toàn công ty'
    WHERE ProgramKey = '2001_DEPT';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý Hợp đồng',
        Comment = N'Quản lý hợp đồng lao động, phụ lục và cảnh báo thời hạn hợp đồng'
    WHERE ProgramKey = '2002_CONT';

    UPDATE ProgramMenus 
    SET ProgramName = N'Cấu hình Nghỉ phép',
        Comment = N'Cấu hình các loại hình nghỉ phép và chính sách hưởng lương'
    WHERE ProgramKey = '2003_LEAV';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý Bảng lương',
        Comment = N'Quản lý kỳ lương nhà máy, import bảng lương Excel 166 cột và công bố phiếu lương'
    WHERE ProgramKey = '2004_PAYROLL';

    UPDATE ProgramMenus 
    SET ProgramName = N'Thiết lập Ca làm việc',
        Comment = N'Thiết lập khung giờ các ca làm việc, ca kíp vận hành nhà máy'
    WHERE ProgramKey = '5010_SHIFT_SETUP';

    UPDATE ProgramMenus 
    SET ProgramName = N'Tổng hợp Giờ công',
        Comment = N'Tổng hợp dữ liệu giờ công, ngày công và làm thêm giờ (OT) toàn nhà máy'
    WHERE ProgramKey = '5020_WORK_SUMMARY';

    UPDATE ProgramMenus 
    SET ProgramName = N'Dữ liệu máy chấm công',
        Comment = N'Lịch sử quẹt thẻ & log chấm công tự động đồng bộ từ máy BioStar 2'
    WHERE ProgramKey = '5030_MACHINE_RECORDS';

    UPDATE ProgramMenus 
    SET ProgramName = N'Đơn xin Nghỉ phép',
        Comment = N'Quản lý và phê duyệt đơn xin nghỉ phép của nhân viên'
    WHERE ProgramKey = '5040_TIMEOFF_REQUESTS';

    UPDATE ProgramMenus 
    SET ProgramName = N'Đăng ký Tăng ca',
        Comment = N'Quản lý và phê duyệt đăng ký làm thêm giờ (tăng ca)'
    WHERE ProgramKey = '5050_OT_REGISTRATION';

    UPDATE ProgramMenus 
    SET ProgramName = N'Báo cáo Giờ công',
        Comment = N'Báo cáo thống kê và phân tích chi tiết dữ liệu giờ công nhà máy'
    WHERE ProgramKey = '5060';

    -- --------------------------------------------------------------------------
    -- 4. GA SUBMENUS (Level 2 - Quản Trị Hành Chính)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý suất ăn',
        Comment = N'Bảng kê tổng hợp, điều chỉnh và xuất báo cáo suất ăn hàng ngày cho nhà bếp & HR đối soát'
    WHERE ProgramKey = 'MEAL_MANAGEMENT';

    UPDATE ProgramMenus 
    SET ProgramName = N'Lịch làm việc & Suất ăn',
        Comment = N'Quản lý lịch làm việc toàn nhà máy, ngày nghỉ lễ và suất ăn đặc biệt'
    WHERE ProgramKey = 'WORK_CALENDAR';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý Phòng ban (GA)',
        Comment = N'Quản lý danh mục phòng ban và phân quyền đặt cơm khối Hành chính (GA)'
    WHERE ProgramKey = 'GA_DEPARTMENTS';

    -- --------------------------------------------------------------------------
    -- 5. SYS SUBMENUS (Level 2 - Quản Trị Hệ Thống)
    -- --------------------------------------------------------------------------
    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý Người dùng',
        Comment = N'Quản lý danh sách tài khoản người dùng, trạng thái và thông tin đăng nhập'
    WHERE ProgramKey = '1003';

    UPDATE ProgramMenus 
    SET ProgramName = N'Phân quyền Người dùng',
        Comment = N'Phân quyền người dùng theo nhóm quyền (Role/Group Permissions Mapping)'
    WHERE ProgramKey = '1007';

    UPDATE ProgramMenus 
    SET ProgramName = N'Quản lý Menu & Màn hình',
        Comment = N'Quản lý danh mục Menu, cấu hình đường dẫn và phân cấp màn hình'
    WHERE ProgramKey = '1002';

    UPDATE ProgramMenus 
    SET ProgramName = N'Mã Dùng Chung',
        Comment = N'Quản lý từ điển mã dùng chung và danh mục hệ thống (Common Codes)'
    WHERE ProgramKey = '1040';

    UPDATE ProgramMenus 
    SET ProgramName = N'Nhật ký Hoạt động',
        Comment = N'Nhật ký ghi vết thao tác người dùng (Audit Trails & Activity Logs)'
    WHERE ProgramKey = '1050';

    UPDATE ProgramMenus 
    SET ProgramName = N'Nhật ký Đăng nhập',
        Comment = N'Nhật ký lịch sử đăng nhập hệ thống và phát hiện bất thường'
    WHERE ProgramKey = '1060';

    UPDATE ProgramMenus 
    SET ProgramName = N'Bảng tin & Thông báo',
        Comment = N'Quản lý bảng tin nội bộ và phát hành thông báo toàn nhà máy'
    WHERE ProgramKey = '1070';

    UPDATE ProgramMenus 
    SET ProgramName = N'Cấu hình Thông Báo Động',
        Comment = N'Cấu hình ma trận sự kiện thông báo linh hoạt theo nhóm quyền và sự kiện'
    WHERE ProgramKey = '1080';

    UPDATE ProgramMenus 
    SET ProgramName = N'Cấu hình Thiết bị & Cổng Chấm Công',
        Comment = N'Cấu hình kết nối thiết bị máy chấm công BioStar 2 & cổng kiểm soát ra vào'
    WHERE ProgramKey = '5070_DEVICE_SETUP';

    UPDATE ProgramMenus 
    SET ProgramName = N'Cấu hình Hệ thống',
        Comment = N'Cấu hình tham số vận hành chung của toàn hệ thống'
    WHERE ProgramKey = '1030';

    UPDATE ProgramMenus 
    SET ProgramName = N'Cài đặt Tài khoản',
        Comment = N'Cài đặt tài khoản và thay đổi mật khẩu cá nhân'
    WHERE ProgramKey = '3010';

    COMMIT TRANSACTION;
    PRINT N'✅ Đã khôi phục toàn bộ font tiếng Việt chuẩn cho ProgramName và Comment thành công!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'❌ Lỗi khi sửa font: %s', 16, 1, @ErrMsg);
END CATCH;
