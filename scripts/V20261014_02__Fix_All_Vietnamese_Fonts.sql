-- ==============================================================================
-- SCRIPT: SỬA TOÀN BỘ LỖI FONT TIẾNG VIỆT CHO BẢNG PROGRAMMENUS, USERS, AUTHORGROUPS, DEPARTMENTS
-- Phiên bản: UTF-8 chuẩn xác, không bị lỗi hỏi chấm (?) hay ký tự lạ mojibake
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    -- 1. CẬP NHẬT CHUẨN TIẾNG VIỆT CHO BẢNG PROGRAMMENUS (QUẢN LÝ MENU & MÀN HÌNH)
    -- Nhóm Menu Cha Cấp 1
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Cổng Tự Phục Vụ' WHERE [ProgramKey] = '6000_SELF_SERVICE';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản Trị Nhân Sự' WHERE [ProgramKey] = '2000_HR';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản Trị Hành Chính & Suất Ăn' WHERE [ProgramKey] = '3000_GA';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản Trị Hệ Thống' WHERE [ProgramKey] = '1000_SYS';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Trang Chủ' WHERE [ProgramKey] = '2000';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Tài Khoản' WHERE [ProgramKey] = '3000';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản Lý Phòng Ban' WHERE [ProgramKey] = '4000_DEPT';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản Lý Giờ Công' WHERE [ProgramKey] = '5000_WORK_HOURS';

    -- Menu con thuộc 6000_SELF_SERVICE
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Lịch làm việc của tôi' WHERE [ProgramKey] = '6010_WORK_SCHEDULE';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Bảng công hàng ngày' WHERE [ProgramKey] = '6020_DAILY_WORK_TIME';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Đăng ký suất ăn' WHERE [ProgramKey] = '6030_MEAL_ORDER';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Phiếu lương của tôi' WHERE [ProgramKey] = '6040_MY_PAYSLIP';

    -- Menu con thuộc 2000_HR
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Phòng ban' WHERE [ProgramKey] = '2001_DEPT';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Hợp đồng' WHERE [ProgramKey] = '2002_CONT';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Cấu hình Nghỉ phép' WHERE [ProgramKey] = '2003_LEAV';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Bảng lương Nhà máy' WHERE [ProgramKey] = '2004_PAYROLL';

    -- Menu con thuộc 3000_GA
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý suất ăn' WHERE [ProgramKey] = 'MEAL_MANAGEMENT';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Lịch làm việc & Suất ăn' WHERE [ProgramKey] = 'WORK_CALENDAR';

    -- Menu con thuộc 1000_SYS
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Menu & Màn hình' WHERE [ProgramKey] = '1002';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Người dùng' WHERE [ProgramKey] = '1003';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Phân quyền Người dùng' WHERE [ProgramKey] = '1007';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Mã Dùng Chung' WHERE [ProgramKey] = '1040';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Cấu hình Hệ thống' WHERE [ProgramKey] = '1030';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Nhật ký Hoạt động' WHERE [ProgramKey] = '1050';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Nhật ký Đăng nhập' WHERE [ProgramKey] = '1060';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Bảng tin & Thông báo' WHERE [ProgramKey] = '1070';

    -- Menu con khác
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Tổng quan Phân tích' WHERE [ProgramKey] = '2001';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Tổng quan Cá nhân' WHERE [ProgramKey] = '2030';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Cài đặt Tài khoản' WHERE [ProgramKey] = '3010';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Ca làm việc' WHERE [ProgramKey] = '3001_SHFT';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Bảng chấm công' WHERE [ProgramKey] = '3002_TSHT';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Quản lý Yêu cầu & Đơn từ' WHERE [ProgramKey] = '3003_REQ';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Thiết lập Ca làm việc' WHERE [ProgramKey] = '5010_SHIFT_SETUP';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Tổng hợp Giờ công' WHERE [ProgramKey] = '5020_WORK_SUMMARY';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Dữ liệu Máy chấm công' WHERE [ProgramKey] = '5030_MACHINE_RECORDS';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Đơn xin Nghỉ phép' WHERE [ProgramKey] = '5040_TIMEOFF_REQUESTS';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Đăng ký Tăng ca' WHERE [ProgramKey] = '5050_OT_REGISTRATION';
    UPDATE [dbo].[ProgramMenus] SET [ProgramName] = N'Báo cáo Giờ công' WHERE [ProgramKey] = '5060';

    PRINT N'-> Đã sửa lỗi font cho ProgramMenus thành công!';

    -- 2. CẬP NHẬT CHUẨN TIẾNG VIỆT CHO BẢNG AUTHORGROUPS (NHÓM PHÂN QUYỀN)
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Quản Trị Viên (Administrator)', [Comment] = N'Quản trị viên toàn quyền hệ thống' WHERE [GroupId] = 1;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Ban Giám Đốc (Board)', [Comment] = N'Ban Giám Đốc điều hành' WHERE [GroupId] = 2;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Quản Lý Xưởng PBA', [Comment] = N'Quản lý sản xuất xưởng PBA' WHERE [GroupId] = 3;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Vận Hành Xưởng PBA', [Comment] = N'Nhân viên vận hành chuyền PBA' WHERE [GroupId] = 4;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Vận Hành Xưởng LCM', [Comment] = N'Nhân viên vận hành chuyền LCM' WHERE [GroupId] = 5;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Chuyên Gia LCM (Hàn Quốc)', [Comment] = N'Chuyên gia quản lý LCM Hàn Quốc' WHERE [GroupId] = 6;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Nhân Viên Bộ Phận 3in1', [Comment] = N'Nhân viên bộ phận 3 trong 1' WHERE [GroupId] = 7;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Nhóm Công Nhân (Worker)', [Comment] = N'Công nhân trực tiếp nhà máy' WHERE [GroupId] = 1002;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Người Dùng (User)', [Comment] = N'Người dùng tự phục vụ cơ bản' WHERE [GroupId] = 2002;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Quản Lý Suất Ăn (Meal Manager)', [Comment] = N'Quản trị viên quản lý suất ăn' WHERE [GroupId] = 2003;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Quản Trị Nhân Sự (HR Officer)', [Comment] = N'Nhóm Quản Trị Nhân Sự (HR Officer)' WHERE [GroupId] = 3002;
    UPDATE [dbo].[AuthorGroups] SET [GroupName] = N'Quản Trị Hành Chính & Suất Ăn (GA Officer)', [Comment] = N'Nhóm Quản Trị Hành Chính & Suất Ăn (GA Officer)' WHERE [GroupId] = 3003;

    PRINT N'-> Đã sửa lỗi font cho AuthorGroups thành công!';

    -- 3. CẬP NHẬT CHUẨN TIẾNG VIỆT CHO BẢNG USERS (HỌ VÀ TÊN NHÂN VIÊN)
    UPDATE [dbo].[Users] SET [FullName] = N'Quản Trị Viên Hệ Thống' WHERE [UserCode] = 'ADMIN';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Lâm Đồng' WHERE [UserCode] = '1200837';
    UPDATE [dbo].[Users] SET [FullName] = N'Trần Văn Nam' WHERE [UserCode] = '1200838';
    UPDATE [dbo].[Users] SET [FullName] = N'Lê Mỹ Linh' WHERE [UserCode] = '1200839';
    UPDATE [dbo].[Users] SET [FullName] = N'Phạm Hoàng Giang' WHERE [UserCode] = '1200840';
    UPDATE [dbo].[Users] SET [FullName] = N'Vũ Thị Hoa' WHERE [UserCode] = '1200841';
    UPDATE [dbo].[Users] SET [FullName] = N'Hoàng Văn Sơn' WHERE [UserCode] = '1200842';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Thị Mai' WHERE [UserCode] = '1200843';
    UPDATE [dbo].[Users] SET [FullName] = N'Đỗ Tuấn Anh' WHERE [UserCode] = '1200844';
    UPDATE [dbo].[Users] SET [FullName] = N'Bùi Minh Nguyệt' WHERE [UserCode] = '1200845';
    UPDATE [dbo].[Users] SET [FullName] = N'Phan Hoàng Long' WHERE [UserCode] = '1200846';
    UPDATE [dbo].[Users] SET [FullName] = N'Ngô Chí Thành' WHERE [UserCode] = '1200847';
    UPDATE [dbo].[Users] SET [FullName] = N'Trần Thanh Thảo' WHERE [UserCode] = '1200848';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Gia Khánh' WHERE [UserCode] = '1200849';
    UPDATE [dbo].[Users] SET [FullName] = N'Lê Quốc Bảo' WHERE [UserCode] = '1200850';
    UPDATE [dbo].[Users] SET [FullName] = N'Phạm Diệu Hương' WHERE [UserCode] = '1200851';
    UPDATE [dbo].[Users] SET [FullName] = N'Vũ Hoàng Nam' WHERE [UserCode] = '1200852';
    UPDATE [dbo].[Users] SET [FullName] = N'Hoàng Mỹ Lệ' WHERE [UserCode] = '1200853';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Ngọc Huy' WHERE [UserCode] = '1200854';
    UPDATE [dbo].[Users] SET [FullName] = N'Trần Phụng Oánh' WHERE [UserCode] = '1200855';
    UPDATE [dbo].[Users] SET [FullName] = N'Lê Xuân Trường' WHERE [UserCode] = '1200856';
    UPDATE [dbo].[Users] SET [FullName] = N'Mai Anh Chung' WHERE [UserCode] = '1200857';
    UPDATE [dbo].[Users] SET [FullName] = N'Phạm Quang Hiếu' WHERE [UserCode] = '12008734';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Văn An' WHERE [UserCode] = '1200323266';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Thị Hương' WHERE [UserCode] = '1200987';
    UPDATE [dbo].[Users] SET [FullName] = N'Phạm Văn Hưng' WHERE [UserCode] = '1200988';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Ngọc Linh' WHERE [UserCode] = '1200953';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Văn Định' WHERE [UserCode] = '1200832';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Văn An' WHERE [UserCode] = '12008456';
    UPDATE [dbo].[Users] SET [FullName] = N'Trần Văn Thanh' WHERE [UserCode] = '1200983';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Văn Bình' WHERE [UserCode] = '1201901';
    UPDATE [dbo].[Users] SET [FullName] = N'Phạm Thị Hoành' WHERE [UserCode] = '1201902';
    UPDATE [dbo].[Users] SET [FullName] = N'Trần Duy Linh' WHERE [UserCode] = '1201903';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Yến Nhi' WHERE [UserCode] = '1200802';
    UPDATE [dbo].[Users] SET [FullName] = N'Nguyễn Văn Kiểm Thử' WHERE [UserCode] = 'TEST_UI_99';

    -- Đại diện các phòng ban
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Nhân Sự' WHERE [UserCode] = '1200801';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Xưởng PBA' WHERE [UserCode] = '1200803';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Xưởng LCM' WHERE [UserCode] = '1200804';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kế Toán' WHERE [UserCode] = '1200805';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Hành Chính' WHERE [UserCode] = '1200806';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kế Hoạch' WHERE [UserCode] = '1200807';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Thu Mua' WHERE [UserCode] = '1200808';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Bộ Phận 3 Trong 1' WHERE [UserCode] = '1200809';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Sản Xuất Chung' WHERE [UserCode] = '1200810';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Quản Lý Chất Lượng' WHERE [UserCode] = '1200811';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng An Toàn Môi Trường' WHERE [UserCode] = '1200812';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Quản Lý Vật Tư' WHERE [UserCode] = '1200813';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Bộ Phận Kho Vận' WHERE [UserCode] = '1200814';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kỹ Thuật Sản Phẩm' WHERE [UserCode] = '1200815';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Công Nghệ Sản Phẩm' WHERE [UserCode] = '1200816';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Xuất Nhập Khẩu' WHERE [UserCode] = '1200817';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kinh Doanh' WHERE [UserCode] = '1200818';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Ban Tổng Giám Đốc' WHERE [UserCode] = '1200819';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Chuyên Gia Hàn Quốc' WHERE [UserCode] = '1200820';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Chuyên Gia HEVH' WHERE [UserCode] = '1200821';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Thực Tập Sinh' WHERE [UserCode] = '1200822';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Bán Thời Gian' WHERE [UserCode] = '1200823';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Đội Bảo Vệ & An Ninh' WHERE [UserCode] = '1200824';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Đội Vệ Sinh Môi Trường' WHERE [UserCode] = '1200825';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Văn Phòng Chung' WHERE [UserCode] = '1200826';

    PRINT N'-> Đã sửa lỗi font cho Users thành công!';

    -- 4. CẬP NHẬT CHUẨN TIẾNG VIỆT CHO BẢNG DEPARTMENTS (TÊN PHÒNG BAN)
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Văn Phòng (Office Division)' WHERE [DepartmentCode] = 'DIV_OFFICE';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Sản Xuất (Production Division)' WHERE [DepartmentCode] = 'DIV_PROD';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Nhân Sự (HR Dept)' WHERE [DepartmentCode] = 'DEPT_HR';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Công Nghệ Thông Tin (IT Dept)' WHERE [DepartmentCode] = 'DEPT_IT';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Xưởng Sản Xuất PBA' WHERE [DepartmentCode] = 'DEPT_PBA';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Xưởng Sản Xuất LCM' WHERE [DepartmentCode] = 'DEPT_LCM';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Kế Toán (Accounting Dept)' WHERE [DepartmentCode] = 'DEPT_ACC';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Hành Chính Tổng Hợp (GA Dept)' WHERE [DepartmentCode] = 'DEPT_GA';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Kế Hoạch Sản Xuất (Planning Dept)' WHERE [DepartmentCode] = 'DEPT_PLAN';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Thu Mua (Purchasing Dept)' WHERE [DepartmentCode] = 'DEPT_PURCH';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Bộ Phận 3 Trong 1 (3in1 Dept)' WHERE [DepartmentCode] = 'DEPT_3IN1';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Sản Xuất Chung (Production General)' WHERE [DepartmentCode] = 'DEPT_PROD_GEN';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Quản Lý Chất Lượng (QC Dept)' WHERE [DepartmentCode] = 'DEPT_QC';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Môi Trường & An Toàn (EHS Dept)' WHERE [DepartmentCode] = 'DEPT_EHS';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Quản Lý Vật Tư (Material Dept)' WHERE [DepartmentCode] = 'DEPT_MATERIAL';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Bộ Phận Kho Vận (Warehouse Dept)' WHERE [DepartmentCode] = 'DEPT_WH';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Kỹ Thuật Sản Phẩm (Tech Product)' WHERE [DepartmentCode] = 'DEPT_TECH_PROD';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Công Nghệ Sản Phẩm (Technology Product)' WHERE [DepartmentCode] = 'DEPT_TECHNO_PROD';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Xuất Nhập Khẩu (EXIM Dept)' WHERE [DepartmentCode] = 'DEPT_EXIM';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Phòng Kinh Doanh (Sales Dept)' WHERE [DepartmentCode] = 'DEPT_SALE';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Ban Tổng Giám Đốc (President Office)' WHERE [DepartmentCode] = 'DEPT_PRESIDENT';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Chuyên Gia Hàn Quốc (Korean Experts)' WHERE [DepartmentCode] = 'DEPT_KOREAN';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Chuyên Gia HEVH (Korean HEVH)' WHERE [DepartmentCode] = 'DEPT_KOREAN_HEVH';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Thực Tập Sinh (Intern Dept)' WHERE [DepartmentCode] = 'DEPT_INTERN';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Bán Thời Gian (Part-time Dept)' WHERE [DepartmentCode] = 'DEPT_PARTTIME';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Bộ Phận Bảo Vệ & An Ninh (Security Dept)' WHERE [DepartmentCode] = 'DEPT_SECURITY';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Đội Vệ Sinh Môi Trường (Cleaning Dept)' WHERE [DepartmentCode] = 'DEPT_CLEANING';
    UPDATE [dbo].[Departments] SET [DepartmentName] = N'Khối Nhân Viên Chung (General Staff)' WHERE [DepartmentCode] = 'DEPT_GENERAL';

    PRINT N'-> Đã sửa lỗi font cho Departments thành công!';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT CẬP NHẬT 100% TIẾNG VIỆT CHUẨN ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'LỖI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
