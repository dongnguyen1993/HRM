-- ==============================================================================
-- SCRIPT: Tạo danh mục Phòng Ban dành riêng cho Chức năng Đặt cơm & Báo cáo suất ăn
--         Tham chiếu trực tiếp từ tệp mẫu: TemplateReport_MealOrder.xlsx
-- Ngày tạo: 2026-09-18
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

SET NOCOUNT ON;

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== BẮT ĐẦU CẬP NHẬT PHÒNG BAN ĐẶT CƠM (MEAL ORDER DEPARTMENTS) ===';

    -- 1. TẠO KHỐI PHÒNG BAN CHA DÀNH CHO SUẤT ĂN (DIV_MEAL) NẾU CHƯA CÓ
    DECLARE @MealDivId INT = (SELECT DepartmentId FROM [dbo].[Departments] WHERE DepartmentCode = 'DIV_MEAL');

    IF @MealDivId IS NULL
    BEGIN
        INSERT INTO [dbo].[Departments] (
            DepartmentCode, DepartmentName, ParentDepartmentId, [Level], SortOrder, UseFlag, Comment, CreatedAt, CreatedBy
        )
        VALUES (
            'DIV_MEAL', N'Khối Suất Ăn Nhà Máy (Meal Order Division)', NULL, 1, 3, 1, 
            N'Khối phòng ban phục vụ chức năng Đặt cơm & Báo cáo suất ăn theo TemplateReport_MealOrder', 
            GETDATE(), 'ADMIN'
        );
        SET @MealDivId = SCOPE_IDENTITY();
        PRINT N'-> Đã tạo Khối cha: DIV_MEAL (DepartmentId: ' + CAST(@MealDivId AS NVARCHAR(10)) + N')';
    END
    ELSE
    BEGIN
        PRINT N'-> Khối DIV_MEAL đã tồn tại (DepartmentId: ' + CAST(@MealDivId AS NVARCHAR(10)) + N')';
    END

    -- 2. DANH SÁCH 20 PHÒNG BAN CHUẨN THEO TEMPLATE EXCEL (TemplateReport_MealOrder.xlsx)
    -- Thứ tự sắp xếp chính xác theo các dòng của Sheet "Ngày tháng 09" và "Đêm tháng 09"
    DECLARE @MealDepts TABLE (
        DepartmentCode NVARCHAR(50),
        DepartmentName NVARCHAR(150),
        SortOrder INT,
        Comment NVARCHAR(255)
    );

    INSERT INTO @MealDepts (DepartmentCode, DepartmentName, SortOrder, Comment) VALUES
    ('GA',       N'Phòng Hành Chính Tổng Hợp (GA)',        1,  N'General Affairs - Theo mẫu TemplateReport_MealOrder'),
    ('HR',       N'Phòng Nhân Sự (HR)',                    2,  N'Human Resources - Theo mẫu TemplateReport_MealOrder'),
    ('ACC',      N'Phòng Kế Toán (ACC)',                   3,  N'Accounting - Theo mẫu TemplateReport_MealOrder'),
    ('EX',       N'Phòng Xuất Nhập Khẩu (EX)',             4,  N'Export-Import - Theo mẫu TemplateReport_MealOrder'),
    ('IT',       N'Phòng Công Nghệ Thông Tin (IT)',        5,  N'Information Technology - Theo mẫu TemplateReport_MealOrder'),
    ('HSE',      N'Phòng An Toàn & Môi Trường (HSE)',      6,  N'Health Safety Environment - Theo mẫu TemplateReport_MealOrder'),
    ('PUR',      N'Phòng Thu Mua (PUR)',                   7,  N'Purchasing - Theo mẫu TemplateReport_MealOrder'),
    ('QC',       N'Phòng Quản Lý Chất Lượng (QC)',         8,  N'Quality Control - Theo mẫu TemplateReport_MealOrder'),
    ('MA',       N'Phòng Quản Lý Vật Tư (MA)',             9,  N'Material - Theo mẫu TemplateReport_MealOrder'),
    ('WH',       N'Bộ Phận Kho Vận (WH)',                  10, N'Warehouse - Theo mẫu TemplateReport_MealOrder'),
    ('3IN1',     N'Bộ Phận 3 Trong 1 (3IN1)',              11, N'3 in 1 Department - Theo mẫu TemplateReport_MealOrder'),
    ('VPSX',     N'Văn Phòng Sản Xuất (VPSX)',             12, N'Production Office - Theo mẫu TemplateReport_MealOrder'),
    ('VB',       N'Bộ Phận VB (VB)',                       13, N'VB Department - Theo mẫu TemplateReport_MealOrder'),
    ('KTSP',     N'Phòng Kỹ Thuật Sản Phẩm (KTSP)',        14, N'Product Engineering - Theo mẫu TemplateReport_MealOrder'),
    ('KTSX',     N'Phòng Kỹ Thuật Sản Xuất (KTSX)',        15, N'Process Engineering - Theo mẫu TemplateReport_MealOrder'),
    ('SALE',     N'Phòng Kinh Doanh (SALE)',               16, N'Sales - Theo mẫu TemplateReport_MealOrder'),
    ('KHSX',     N'Phòng Kế Hoạch Sản Xuất (KHSX)',        17, N'Production Planning - Theo mẫu TemplateReport_MealOrder'),
    ('DRIVER',   N'Đội Lái Xe (DRIVER)',                   18, N'Driver Team - Theo mẫu TemplateReport_MealOrder (DRI)'),
    ('SECURITY', N'Bộ Phận Bảo Vệ & An Ninh (SECURITY)',   19, N'Security Team - Theo mẫu TemplateReport_MealOrder (SEC)'),
    ('KOREAN',   N'Khối Chuyên Gia Hàn Quốc (Cơm Hàn)',    20, N'Korean Experts - Theo mẫu TemplateReport_MealOrder (Sheet Cơm Hàn)');

    -- Thêm các phòng ban chưa tồn tại
    INSERT INTO [dbo].[Departments] (
        DepartmentCode, DepartmentName, ParentDepartmentId, [Level], SortOrder, UseFlag, Comment, CreatedAt, CreatedBy
    )
    SELECT 
        src.DepartmentCode,
        src.DepartmentName,
        @MealDivId AS ParentDepartmentId,
        2 AS [Level],
        src.SortOrder,
        1 AS UseFlag,
        src.Comment,
        GETDATE() AS CreatedAt,
        'ADMIN' AS CreatedBy
    FROM @MealDepts src
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[Departments] d WHERE d.DepartmentCode = src.DepartmentCode
    );

    -- Cập nhật lại ParentDepartmentId và SortOrder nếu đã tồn tại
    UPDATE d
    SET 
        d.ParentDepartmentId = @MealDivId,
        d.SortOrder = src.SortOrder,
        d.DepartmentName = src.DepartmentName,
        d.UseFlag = 1,
        d.UpdatedAt = GETDATE(),
        d.UpdatedBy = 'ADMIN'
    FROM [dbo].[Departments] d
    INNER JOIN @MealDepts src ON d.DepartmentCode = src.DepartmentCode;

    PRINT N'-> Đã thêm/cập nhật đầy đủ 20 phòng ban đặt cơm vào bảng Departments!';

    -- 3. MIGRATION DỮ LIỆU CŨ TRONG BẢNG DepartmentMealOrders (NẾU CÓ) SANG MÃ MỚI
    UPDATE DepartmentMealOrders SET DepartmentCode = 'HR'       WHERE DepartmentCode = 'DEPT_HR';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'IT'       WHERE DepartmentCode = 'DEPT_IT';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'ACC'      WHERE DepartmentCode = 'DEPT_ACC';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'GA'       WHERE DepartmentCode = 'DEPT_GA';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'QC'       WHERE DepartmentCode = 'DEPT_QC';
    UPDATE DepartmentMealOrders SET DepartmentCode = '3IN1'     WHERE DepartmentCode = 'DEPT_3IN1';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'KHSX'     WHERE DepartmentCode = 'DEPT_PLAN';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'PUR'      WHERE DepartmentCode = 'DEPT_PURCH';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'MA'       WHERE DepartmentCode = 'DEPT_MATERIAL';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'WH'       WHERE DepartmentCode = 'DEPT_WH';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'KTSP'     WHERE DepartmentCode = 'DEPT_TECH_PROD';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'KTSX'     WHERE DepartmentCode = 'DEPT_TECHNO_PROD';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'EX'       WHERE DepartmentCode = 'DEPT_EXIM';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'SALE'     WHERE DepartmentCode = 'DEPT_SALE';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'HSE'      WHERE DepartmentCode = 'DEPT_EHS';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'SECURITY' WHERE DepartmentCode = 'DEPT_SECURITY';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'KOREAN'   WHERE DepartmentCode = 'DEPT_KOREAN';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'VPSX'     WHERE DepartmentCode = 'DEPT_LCM';
    UPDATE DepartmentMealOrders SET DepartmentCode = 'VB'       WHERE DepartmentCode = 'DEPT_PBA';

    PRINT N'-> Đã chuyển đổi dữ liệu đơn đặt cơm cũ sang mã phòng ban chuẩn!';

    -- 4. CẬP NHẬT ÁNH XẠ USER KIỂM THỬ SANG MÃ PHÒNG BAN MỚI
    UPDATE Users SET DepartmentCode = 'HR',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'HR')       WHERE UserCode = '1200801';
    UPDATE Users SET DepartmentCode = 'IT',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'IT')       WHERE UserCode = '1200802';
    UPDATE Users SET DepartmentCode = 'VB',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'VB')       WHERE UserCode = '1200803';
    UPDATE Users SET DepartmentCode = 'VPSX',     DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'VPSX')     WHERE UserCode = '1200804';
    UPDATE Users SET DepartmentCode = 'ACC',      DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'ACC')      WHERE UserCode = '1200805';
    UPDATE Users SET DepartmentCode = 'GA',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'GA')       WHERE UserCode = '1200806';
    UPDATE Users SET DepartmentCode = 'KHSX',     DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'KHSX')     WHERE UserCode = '1200807';
    UPDATE Users SET DepartmentCode = 'PUR',      DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'PUR')      WHERE UserCode = '1200808';
    UPDATE Users SET DepartmentCode = '3IN1',     DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = '3IN1')     WHERE UserCode = '1200809';
    UPDATE Users SET DepartmentCode = 'QC',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'QC')       WHERE UserCode = '1200811';
    UPDATE Users SET DepartmentCode = 'HSE',      DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'HSE')      WHERE UserCode = '1200812';
    UPDATE Users SET DepartmentCode = 'MA',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'MA')       WHERE UserCode = '1200813';
    UPDATE Users SET DepartmentCode = 'WH',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'WH')       WHERE UserCode = '1200814';
    UPDATE Users SET DepartmentCode = 'KTSP',     DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'KTSP')     WHERE UserCode = '1200815';
    UPDATE Users SET DepartmentCode = 'KTSX',     DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'KTSX')     WHERE UserCode = '1200816';
    UPDATE Users SET DepartmentCode = 'EX',       DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'EX')       WHERE UserCode = '1200817';
    UPDATE Users SET DepartmentCode = 'SALE',     DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'SALE')     WHERE UserCode = '1200818';
    UPDATE Users SET DepartmentCode = 'KOREAN',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'KOREAN')   WHERE UserCode = '1200820';
    UPDATE Users SET DepartmentCode = 'SECURITY', DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'SECURITY') WHERE UserCode = '1200824';
    UPDATE Users SET DepartmentCode = 'DRIVER',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'DRIVER')   WHERE UserCode = '1200826';

    PRINT N'-> Đã cập nhật xong ánh xạ phòng ban cho các User kiểm thử!';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(N'Lỗi khi cập nhật phòng ban: %s', 16, 1, @ErrMsg);
END CATCH;
GO
