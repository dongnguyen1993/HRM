-- ==============================================================================
-- SCRIPT: Cập nhật chuẩn font tiếng Việt có dấu cho bảng Departments và Users
-- Ngày tạo: 2026-09-17
-- Hướng dẫn: Có thể chạy trực tiếp trong SSMS (SQL Server Management Studio)
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. CẬP NHẬT TÊN PHÒNG BAN CHUẨN TIẾNG VIỆT (BẢNG DEPARTMENTS)
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

    PRINT N'-> Đã sửa lỗi font cho toàn bộ 28 Phòng Ban thành công!';

    -- 2. CẬP NHẬT HỌ TÊN TEST USER CHUẨN TIẾNG VIỆT (BẢNG USERS)
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Nhân Sự' WHERE [UserCode] = 'user_hr';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng IT' WHERE [UserCode] = 'user_it';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Xưởng PBA' WHERE [UserCode] = 'user_pba';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Xưởng LCM' WHERE [UserCode] = 'user_lcm';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kế Toán' WHERE [UserCode] = 'user_acc';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Hành Chính' WHERE [UserCode] = 'user_ga';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kế Hoạch' WHERE [UserCode] = 'user_plan';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Thu Mua' WHERE [UserCode] = 'user_purch';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Bộ Phận 3 Trong 1' WHERE [UserCode] = 'user_3in1';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Sản Xuất Chung' WHERE [UserCode] = 'user_prod_gen';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Quản Lý Chất Lượng' WHERE [UserCode] = 'user_qc';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng An Toàn Môi Trường' WHERE [UserCode] = 'user_ehs';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Quản Lý Vật Tư' WHERE [UserCode] = 'user_material';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Bộ Phận Kho Vận' WHERE [UserCode] = 'user_wh';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kỹ Thuật Sản Phẩm' WHERE [UserCode] = 'user_tech_prod';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Công Nghệ Sản Phẩm' WHERE [UserCode] = 'user_techno_prod';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Xuất Nhập Khẩu' WHERE [UserCode] = 'user_exim';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Phòng Kinh Doanh' WHERE [UserCode] = 'user_sale';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Ban Tổng Giám Đốc' WHERE [UserCode] = 'user_president';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Chuyên Gia Hàn Quốc' WHERE [UserCode] = 'user_korean';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Chuyên Gia HEVH' WHERE [UserCode] = 'user_korean_hevh';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Thực Tập Sinh' WHERE [UserCode] = 'user_intern';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Bán Thời Gian' WHERE [UserCode] = 'user_parttime';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Đội Bảo Vệ & An Ninh' WHERE [UserCode] = 'user_security';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Đội Vệ Sinh Môi Trường' WHERE [UserCode] = 'user_cleaning';
    UPDATE [dbo].[Users] SET [FullName] = N'Đại Diện - Khối Văn Phòng Chung' WHERE [UserCode] = 'user_general';

    PRINT N'-> Đã sửa lỗi font cho toàn bộ 26 User kiểm thử thành công!';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT CẬP NHẬT CHUẨN FONT TIẾNG VIỆT ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'LỖI: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
