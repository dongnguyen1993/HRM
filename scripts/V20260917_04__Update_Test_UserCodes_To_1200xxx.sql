USE HRM_Enterprise_DB;
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;

-- 1. Cập nhật UserCode và Email cho 26 tài khoản đại diện phòng ban từ mã chữ sang số chuẩn '1200xxx' (1200801 -> 1200826)
UPDATE Users SET UserCode = '1200801', Email = '1200801@hansol.com' WHERE UserCode = 'user_hr';
UPDATE Users SET UserCode = '1200802', Email = '1200802@hansol.com' WHERE UserCode = 'user_it';
UPDATE Users SET UserCode = '1200803', Email = '1200803@hansol.com' WHERE UserCode = 'user_pba';
UPDATE Users SET UserCode = '1200804', Email = '1200804@hansol.com' WHERE UserCode = 'user_lcm';
UPDATE Users SET UserCode = '1200805', Email = '1200805@hansol.com' WHERE UserCode = 'user_acc';
UPDATE Users SET UserCode = '1200806', Email = '1200806@hansol.com' WHERE UserCode = 'user_ga';
UPDATE Users SET UserCode = '1200807', Email = '1200807@hansol.com' WHERE UserCode = 'user_plan';
UPDATE Users SET UserCode = '1200808', Email = '1200808@hansol.com' WHERE UserCode = 'user_purch';
UPDATE Users SET UserCode = '1200809', Email = '1200809@hansol.com' WHERE UserCode = 'user_3in1';
UPDATE Users SET UserCode = '1200810', Email = '1200810@hansol.com' WHERE UserCode = 'user_prod_gen';
UPDATE Users SET UserCode = '1200811', Email = '1200811@hansol.com' WHERE UserCode = 'user_qc';
UPDATE Users SET UserCode = '1200812', Email = '1200812@hansol.com' WHERE UserCode = 'user_ehs';
UPDATE Users SET UserCode = '1200813', Email = '1200813@hansol.com' WHERE UserCode = 'user_material';
UPDATE Users SET UserCode = '1200814', Email = '1200814@hansol.com' WHERE UserCode = 'user_wh';
UPDATE Users SET UserCode = '1200815', Email = '1200815@hansol.com' WHERE UserCode = 'user_tech_prod';
UPDATE Users SET UserCode = '1200816', Email = '1200816@hansol.com' WHERE UserCode = 'user_techno_prod';
UPDATE Users SET UserCode = '1200817', Email = '1200817@hansol.com' WHERE UserCode = 'user_exim';
UPDATE Users SET UserCode = '1200818', Email = '1200818@hansol.com' WHERE UserCode = 'user_sale';
UPDATE Users SET UserCode = '1200819', Email = '1200819@hansol.com' WHERE UserCode = 'user_president';
UPDATE Users SET UserCode = '1200820', Email = '1200820@hansol.com' WHERE UserCode = 'user_korean';
UPDATE Users SET UserCode = '1200821', Email = '1200821@hansol.com' WHERE UserCode = 'user_korean_hevh';
UPDATE Users SET UserCode = '1200822', Email = '1200822@hansol.com' WHERE UserCode IN ('user_intern', 'user_intem');
UPDATE Users SET UserCode = '1200823', Email = '1200823@hansol.com' WHERE UserCode = 'user_parttime';
UPDATE Users SET UserCode = '1200824', Email = '1200824@hansol.com' WHERE UserCode = 'user_security';
UPDATE Users SET UserCode = '1200825', Email = '1200825@hansol.com' WHERE UserCode = 'user_cleaning';
UPDATE Users SET UserCode = '1200826', Email = '1200826@hansol.com' WHERE UserCode = 'user_general';

-- 2. Đồng bộ các bảng liên quan nếu có dữ liệu tham chiếu
UPDATE DepartmentMealOrders SET OrderedBy = '1200801' WHERE OrderedBy = 'user_hr';
UPDATE DepartmentMealOrders SET OrderedBy = '1200802' WHERE OrderedBy = 'user_it';
UPDATE DepartmentMealOrders SET OrderedBy = '1200803' WHERE OrderedBy = 'user_pba';
UPDATE DepartmentMealOrders SET OrderedBy = '1200804' WHERE OrderedBy = 'user_lcm';
UPDATE DepartmentMealOrders SET OrderedBy = '1200805' WHERE OrderedBy = 'user_acc';
UPDATE DepartmentMealOrders SET OrderedBy = '1200806' WHERE OrderedBy = 'user_ga';
UPDATE DepartmentMealOrders SET OrderedBy = '1200807' WHERE OrderedBy = 'user_plan';
UPDATE DepartmentMealOrders SET OrderedBy = '1200808' WHERE OrderedBy = 'user_purch';
UPDATE DepartmentMealOrders SET OrderedBy = '1200809' WHERE OrderedBy = 'user_3in1';
UPDATE DepartmentMealOrders SET OrderedBy = '1200810' WHERE OrderedBy = 'user_prod_gen';
UPDATE DepartmentMealOrders SET OrderedBy = '1200811' WHERE OrderedBy = 'user_qc';
UPDATE DepartmentMealOrders SET OrderedBy = '1200812' WHERE OrderedBy = 'user_ehs';
UPDATE DepartmentMealOrders SET OrderedBy = '1200813' WHERE OrderedBy = 'user_material';
UPDATE DepartmentMealOrders SET OrderedBy = '1200814' WHERE OrderedBy = 'user_wh';
UPDATE DepartmentMealOrders SET OrderedBy = '1200815' WHERE OrderedBy = 'user_tech_prod';
UPDATE DepartmentMealOrders SET OrderedBy = '1200816' WHERE OrderedBy = 'user_techno_prod';
UPDATE DepartmentMealOrders SET OrderedBy = '1200817' WHERE OrderedBy = 'user_exim';
UPDATE DepartmentMealOrders SET OrderedBy = '1200818' WHERE OrderedBy = 'user_sale';
UPDATE DepartmentMealOrders SET OrderedBy = '1200819' WHERE OrderedBy = 'user_president';
UPDATE DepartmentMealOrders SET OrderedBy = '1200820' WHERE OrderedBy = 'user_korean';
UPDATE DepartmentMealOrders SET OrderedBy = '1200821' WHERE OrderedBy = 'user_korean_hevh';
UPDATE DepartmentMealOrders SET OrderedBy = '1200822' WHERE OrderedBy IN ('user_intern', 'user_intem');
UPDATE DepartmentMealOrders SET OrderedBy = '1200823' WHERE OrderedBy = 'user_parttime';
UPDATE DepartmentMealOrders SET OrderedBy = '1200824' WHERE OrderedBy = 'user_security';
UPDATE DepartmentMealOrders SET OrderedBy = '1200825' WHERE OrderedBy = 'user_cleaning';
UPDATE DepartmentMealOrders SET OrderedBy = '1200826' WHERE OrderedBy = 'user_general';

COMMIT TRANSACTION;
GO
