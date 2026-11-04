-- ==============================================================================
-- Migration Script: V20261104_01__Rename_Tables_To_Domain_Prefixes.sql
-- Mục đích: Chuẩn hóa toàn bộ tên 31 bảng trong CSDL theo tiền tố Domain chuẩn:
--   - GA_  : Quản Trị Hành Chính (3 bảng)
--   - SYS_ : Quản Trị Hệ Thống (16 bảng)
--   - HR_  : Quản Trị Nhân Sự & Chấm Công (12 bảng)
-- Lưu ý: Đổi tên dứt điểm bằng sp_rename, KHÔNG TẠO SYNONYM (CSDL sạch 100%).
-- Script có tính Idempotent (kiểm tra an toàn trước khi đổi, chạy lại không lỗi).
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== BẮT ĐẦU CHUẨN HÓA TÊN BẢNG CSDL SANG TIỀN TỐ DOMAIN ===';

    -- --------------------------------------------------------------------------
    -- 1. PHÂN HỆ QUẢN TRỊ HÀNH CHÍNH (GA - GENERAL AFFAIRS)
    -- --------------------------------------------------------------------------
    IF OBJECT_ID('dbo.DepartmentMealOrders', 'U') IS NOT NULL AND OBJECT_ID('dbo.GA_DepartmentMealOrders', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.DepartmentMealOrders', 'GA_DepartmentMealOrders';
        PRINT N'[GA] Đã đổi tên: DepartmentMealOrders -> GA_DepartmentMealOrders';
    END

    IF OBJECT_ID('dbo.GaDepartments', 'U') IS NOT NULL AND OBJECT_ID('dbo.GA_Departments', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.GaDepartments', 'GA_Departments';
        PRINT N'[GA] Đã đổi tên: GaDepartments -> GA_Departments';
    END

    IF OBJECT_ID('dbo.WorkCalendar', 'U') IS NOT NULL AND OBJECT_ID('dbo.GA_WorkCalendar', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.WorkCalendar', 'GA_WorkCalendar';
        PRINT N'[GA] Đã đổi tên: WorkCalendar -> GA_WorkCalendar';
    END

    -- --------------------------------------------------------------------------
    -- 2. PHÂN HỆ QUẢN TRỊ HỆ THỐNG (SYS - SYSTEM MANAGEMENT)
    -- --------------------------------------------------------------------------
    IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_Users', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Users', 'SYS_Users';
        PRINT N'[SYS] Đã đổi tên: Users -> SYS_Users';
    END

    IF OBJECT_ID('dbo.UserTokens', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_UserTokens', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.UserTokens', 'SYS_UserTokens';
        PRINT N'[SYS] Đã đổi tên: UserTokens -> SYS_UserTokens';
    END

    IF OBJECT_ID('dbo.User_Theme_Settings', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_UserThemeSettings', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.User_Theme_Settings', 'SYS_UserThemeSettings';
        PRINT N'[SYS] Đã đổi tên: User_Theme_Settings -> SYS_UserThemeSettings';
    END

    IF OBJECT_ID('dbo.UserAttachments', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_UserAttachments', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.UserAttachments', 'SYS_UserAttachments';
        PRINT N'[SYS] Đã đổi tên: UserAttachments -> SYS_UserAttachments';
    END

    IF OBJECT_ID('dbo.AuthorGroups', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_AuthorGroups', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.AuthorGroups', 'SYS_AuthorGroups';
        PRINT N'[SYS] Đã đổi tên: AuthorGroups -> SYS_AuthorGroups';
    END

    IF OBJECT_ID('dbo.AuthorGroupMapping', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_AuthorGroupMapping', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.AuthorGroupMapping', 'SYS_AuthorGroupMapping';
        PRINT N'[SYS] Đã đổi tên: AuthorGroupMapping -> SYS_AuthorGroupMapping';
    END

    IF OBJECT_ID('dbo.UserGroupMapping', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_UserGroupMapping', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.UserGroupMapping', 'SYS_UserGroupMapping';
        PRINT N'[SYS] Đã đổi tên: UserGroupMapping -> SYS_UserGroupMapping';
    END

    IF OBJECT_ID('dbo.ProgramMenus', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_ProgramMenus', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.ProgramMenus', 'SYS_ProgramMenus';
        PRINT N'[SYS] Đã đổi tên: ProgramMenus -> SYS_ProgramMenus';
    END

    IF OBJECT_ID('dbo.CommonCodes', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_CommonCodes', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.CommonCodes', 'SYS_CommonCodes';
        PRINT N'[SYS] Đã đổi tên: CommonCodes -> SYS_CommonCodes';
    END

    IF OBJECT_ID('dbo.AuditLogs', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_AuditLogs', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.AuditLogs', 'SYS_AuditLogs';
        PRINT N'[SYS] Đã đổi tên: AuditLogs -> SYS_AuditLogs';
    END

    IF OBJECT_ID('dbo.Announcements', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_Announcements', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Announcements', 'SYS_Announcements';
        PRINT N'[SYS] Đã đổi tên: Announcements -> SYS_Announcements';
    END

    IF OBJECT_ID('dbo.Notifications', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_Notifications', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Notifications', 'SYS_Notifications';
        PRINT N'[SYS] Đã đổi tên: Notifications -> SYS_Notifications';
    END

    IF OBJECT_ID('dbo.NotificationEvents', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_NotificationEvents', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.NotificationEvents', 'SYS_NotificationEvents';
        PRINT N'[SYS] Đã đổi tên: NotificationEvents -> SYS_NotificationEvents';
    END

    IF OBJECT_ID('dbo.NotificationMatrix', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_NotificationMatrix', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.NotificationMatrix', 'SYS_NotificationMatrix';
        PRINT N'[SYS] Đã đổi tên: NotificationMatrix -> SYS_NotificationMatrix';
    END

    IF OBJECT_ID('dbo.DeviceSetup', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_DeviceSetup', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.DeviceSetup', 'SYS_DeviceSetup';
        PRINT N'[SYS] Đã đổi tên: DeviceSetup -> SYS_DeviceSetup';
    END

    IF OBJECT_ID('dbo.SystemSettings', 'U') IS NOT NULL AND OBJECT_ID('dbo.SYS_SystemSettings', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.SystemSettings', 'SYS_SystemSettings';
        PRINT N'[SYS] Đã đổi tên: SystemSettings -> SYS_SystemSettings';
    END

    -- --------------------------------------------------------------------------
    -- 3. PHÂN HỆ QUẢN TRỊ NHÂN SỰ & CHẤM CÔNG (HR - HUMAN RESOURCE)
    -- --------------------------------------------------------------------------
    IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_Departments', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Departments', 'HR_Departments';
        PRINT N'[HR] Đã đổi tên: Departments -> HR_Departments';
    END

    IF OBJECT_ID('dbo.Positions', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_Positions', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Positions', 'HR_Positions';
        PRINT N'[HR] Đã đổi tên: Positions -> HR_Positions';
    END

    IF OBJECT_ID('dbo.LaborContracts', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_LaborContracts', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.LaborContracts', 'HR_LaborContracts';
        PRINT N'[HR] Đã đổi tên: LaborContracts -> HR_LaborContracts';
    END

    IF OBJECT_ID('dbo.LeaveTypes', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_LeaveTypes', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.LeaveTypes', 'HR_LeaveTypes';
        PRINT N'[HR] Đã đổi tên: LeaveTypes -> HR_LeaveTypes';
    END

    IF OBJECT_ID('dbo.WorkShifts', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_WorkShifts', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.WorkShifts', 'HR_WorkShifts';
        PRINT N'[HR] Đã đổi tên: WorkShifts -> HR_WorkShifts';
    END

    IF OBJECT_ID('dbo.WorkRequests', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_WorkRequests', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.WorkRequests', 'HR_WorkRequests';
        PRINT N'[HR] Đã đổi tên: WorkRequests -> HR_WorkRequests';
    END

    IF OBJECT_ID('dbo.OtRegistrations', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_OtRegistrations', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.OtRegistrations', 'HR_OtRegistrations';
        PRINT N'[HR] Đã đổi tên: OtRegistrations -> HR_OtRegistrations';
    END

    IF OBJECT_ID('dbo.MachineRecords', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_MachineRecords', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.MachineRecords', 'HR_MachineRecords';
        PRINT N'[HR] Đã đổi tên: MachineRecords -> HR_MachineRecords';
    END

    IF OBJECT_ID('dbo.WorkSummary', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_WorkSummary', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.WorkSummary', 'HR_WorkSummary';
        PRINT N'[HR] Đã đổi tên: WorkSummary -> HR_WorkSummary';
    END

    IF OBJECT_ID('dbo.Payroll_Period', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_PayrollPeriod', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Payroll_Period', 'HR_PayrollPeriod';
        PRINT N'[HR] Đã đổi tên: Payroll_Period -> HR_PayrollPeriod';
    END

    IF OBJECT_ID('dbo.Payroll_Salary_Item', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_PayrollSalaryItem', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Payroll_Salary_Item', 'HR_PayrollSalaryItem';
        PRINT N'[HR] Đã đổi tên: Payroll_Salary_Item -> HR_PayrollSalaryItem';
    END

    IF OBJECT_ID('dbo.Payroll_Employee_Monthly', 'U') IS NOT NULL AND OBJECT_ID('dbo.HR_PayrollEmployeeMonthly', 'U') IS NULL
    BEGIN
        EXEC sp_rename 'dbo.Payroll_Employee_Monthly', 'HR_PayrollEmployeeMonthly';
        PRINT N'[HR] Đã đổi tên: Payroll_Employee_Monthly -> HR_PayrollEmployeeMonthly';
    END

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT CHUẨN HÓA 31 BẢNG SANG TIỀN TỐ DOMAIN THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

