-- ==============================================================================
-- Migration Script: V20261103_01__Update_Menu_Paths_To_Domain_Prefixes.sql
-- Mục đích: Chuẩn hóa toàn bộ cột Path trong bảng ProgramMenus sang tiền tố Domain:
--   - ESS: /ess/*
--   - HR : /hr/*
--   - GA : /ga/*
--   - SYS: /sys/*
-- Lưu ý: Chạy script này trên CSDL Server trước khi deploy Backend và Frontend mới.
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    -- 1. ROOT MENUS (Level 1)
    UPDATE ProgramMenus SET Path = '/ess' WHERE ProgramKey = '6000_SELF_SERVICE';
    UPDATE ProgramMenus SET Path = '/hr'  WHERE ProgramKey = '2000_HR';
    UPDATE ProgramMenus SET Path = '/ga'  WHERE ProgramKey = '3000_GA';
    UPDATE ProgramMenus SET Path = '/sys' WHERE ProgramKey = '1000_SYS';
    UPDATE ProgramMenus SET Path = '/account' WHERE ProgramKey = '3000';
    UPDATE ProgramMenus SET Path = '/work-hours' WHERE ProgramKey = '5000_WORK_HOURS';

    -- 2. ESS DOMAIN (/ess/*)
    UPDATE ProgramMenus SET Path = '/ess/user-overview'   WHERE ProgramKey = '6001_USER_OVERVIEW';
    UPDATE ProgramMenus SET Path = '/ess/user-overview'   WHERE ProgramKey = '6002_OVERVIEW_ANALYTICS';
    UPDATE ProgramMenus SET Path = '/ess/work-schedule'   WHERE ProgramKey = '6010_WORK_SCHEDULE';
    UPDATE ProgramMenus SET Path = '/ess/daily-work-time' WHERE ProgramKey = '6020_DAILY_WORK_TIME';
    UPDATE ProgramMenus SET Path = '/ess/meal-order'       WHERE ProgramKey = '6030_MEAL_ORDER';
    UPDATE ProgramMenus SET Path = '/ess/my-payslip'       WHERE ProgramKey = '6040_MY_PAYSLIP';

    -- 3. HR DOMAIN (/hr/*)
    UPDATE ProgramMenus SET Path = '/hr/departments'      WHERE ProgramKey = '2001_DEPT';
    UPDATE ProgramMenus SET Path = '/hr/contracts'        WHERE ProgramKey = '2002_CONT';
    UPDATE ProgramMenus SET Path = '/hr/leave-types'      WHERE ProgramKey = '2003_LEAV';
    UPDATE ProgramMenus SET Path = '/hr/payroll'          WHERE ProgramKey = '2004_PAYROLL';
    UPDATE ProgramMenus SET Path = '/hr/shift-setup'      WHERE ProgramKey = '5010_SHIFT_SETUP';
    UPDATE ProgramMenus SET Path = '/hr/work-summary'     WHERE ProgramKey = '5020_WORK_SUMMARY';
    UPDATE ProgramMenus SET Path = '/hr/machine-records'  WHERE ProgramKey = '5030_MACHINE_RECORDS';
    UPDATE ProgramMenus SET Path = '/hr/timeoff-requests' WHERE ProgramKey = '5040_TIMEOFF_REQUESTS';
    UPDATE ProgramMenus SET Path = '/hr/ot-registration'  WHERE ProgramKey = '5050_OT_REGISTRATION';
    UPDATE ProgramMenus SET Path = '/hr/work-time-report' WHERE ProgramKey = '5060';

    -- 4. GA DOMAIN (/ga/*)
    UPDATE ProgramMenus SET Path = '/ga/meal-management'  WHERE ProgramKey = 'MEAL_MANAGEMENT';
    UPDATE ProgramMenus SET Path = '/ga/work-calendar'    WHERE ProgramKey = 'WORK_CALENDAR';
    UPDATE ProgramMenus SET Path = '/ga/departments'      WHERE ProgramKey = 'GA_DEPARTMENTS';

    -- 5. SYS DOMAIN (/sys/*)
    UPDATE ProgramMenus SET Path = '/sys/user-management'     WHERE ProgramKey = '1003';
    UPDATE ProgramMenus SET Path = '/sys/permission-mapping'  WHERE ProgramKey = '1007';
    UPDATE ProgramMenus SET Path = '/sys/menu-management'     WHERE ProgramKey = '1002';
    UPDATE ProgramMenus SET Path = '/sys/common-code'         WHERE ProgramKey = '1040';
    UPDATE ProgramMenus SET Path = '/sys/audit-logs'          WHERE ProgramKey = '1050';
    UPDATE ProgramMenus SET Path = '/sys/sign-in-logs'        WHERE ProgramKey = '1060';
    UPDATE ProgramMenus SET Path = '/sys/announcements'       WHERE ProgramKey = '1070';
    UPDATE ProgramMenus SET Path = '/sys/notification-matrix' WHERE ProgramKey = '1080';
    UPDATE ProgramMenus SET Path = '/sys/device-setup'        WHERE ProgramKey = '5070_DEVICE_SETUP';

    -- Vô hiệu hóa menu cũ không còn sử dụng
    UPDATE ProgramMenus SET UseFlag = 0, MenuFlag = 0 WHERE ProgramKey = '1030';
    UPDATE ProgramMenus SET Path = '/account/settings' WHERE ProgramKey = '3010';

    COMMIT TRANSACTION;
    PRINT N'Đã cập nhật toàn bộ Path sang Domain Prefixes thành công!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

