-- ============================================================================
-- MIGRATION: V20260922_01__Create_Payroll_And_Payslip_Module.sql
-- MÔ TẢ: Phân hệ Quản lý Bảng Lương Nhà Máy (HR) & Tra cứu Phiếu Lương Cá Nhân (User)
-- CHUẨN MẪU: Công ty TNHH Hansol Electronics Vietnam Hochiminhcity
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PayrollPeriods')
BEGIN
    CREATE TABLE [dbo].[PayrollPeriods] (
        [PeriodId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [PeriodCode] VARCHAR(50) NOT NULL UNIQUE,
        [PeriodName] NVARCHAR(150) NOT NULL,
        [FromDate] DATE NOT NULL,
        [ToDate] DATE NOT NULL,
        [PaymentDate] DATE NULL,
        [StandardWorkingDays] DECIMAL(4,1) NOT NULL DEFAULT 23.0,
        [Status] VARCHAR(30) NOT NULL DEFAULT 'DRAFT', -- DRAFT, CALCULATED, APPROVED, PUBLISHED, LOCKED
        [TotalEmployees] INT NOT NULL DEFAULT 0,
        [TotalNetSalary] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [Note] NVARCHAR(500) NULL,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
        [UpdatedAt] DATETIME NULL,
        [UpdatedBy] VARCHAR(50) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SalaryComponents')
BEGIN
    CREATE TABLE [dbo].[SalaryComponents] (
        [ComponentId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [ComponentCode] VARCHAR(50) NOT NULL UNIQUE,
        [ComponentName] NVARCHAR(150) NOT NULL,
        [GroupType] CHAR(1) NOT NULL, -- 'A': Lương thử việc, 'B': Lương chính thức, 'C': Phụ cấp, 'D': Khoản trừ
        [CalculationType] VARCHAR(30) NOT NULL DEFAULT 'MANUAL', -- FORMULA_HOURLY, FIXED_AMOUNT, RATE_PERCENT, MANUAL
        [HasHours] BIT NOT NULL DEFAULT 0, -- Có hiển thị cột Ngày/Giờ hay không
        [RateMultiplier] DECIMAL(5,2) NOT NULL DEFAULT 1.0, -- Hệ số (1.5, 2.0, 2.1, 2.7, 3.0, 3.9)
        [DefaultAmount] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [IsTaxable] BIT NOT NULL DEFAULT 1,
        [IsActive] BIT NOT NULL DEFAULT 1, -- Bật / Tắt trực tiếp trên giao diện
        [SortOrder] INT NOT NULL DEFAULT 0,
        [Description] NVARCHAR(250) NULL,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
        [UpdatedAt] DATETIME NULL,
        [UpdatedBy] VARCHAR(50) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EmployeePayslips')
BEGIN
    CREATE TABLE [dbo].[EmployeePayslips] (
        [PayslipId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [SecureId] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        [PeriodId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[PayrollPeriods]([PeriodId]) ON DELETE CASCADE,
        [UserCode] VARCHAR(50) NOT NULL,
        [FullName] NVARCHAR(150) NOT NULL,
        [DepartmentCode] VARCHAR(50) NULL,
        [DepartmentName] NVARCHAR(150) NULL,
        [PositionName] NVARCHAR(100) NULL,
        [OrderNo] INT NULL, -- STT trên bảng lương (vd 40)
        [BankAccountNo] VARCHAR(50) NULL,
        [JoinDate] DATE NULL,
        [StandardDays] DECIMAL(4,1) NOT NULL DEFAULT 23.0,
        [AnnualLeaveAvailable] DECIMAL(4,1) NOT NULL DEFAULT 0,
        [BasicSalary] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [InsuranceSalary] DECIMAL(18,2) NOT NULL DEFAULT 0,
        
        -- Các định mức phụ cấp hiển thị trên Header phiếu lương
        [HeaderPcAtvs] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [HeaderPccc] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [HeaderPcTrachNhiem] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [HeaderPcChucVu] DECIMAL(18,2) NOT NULL DEFAULT 0,

        -- Tổng hợp 4 nhóm A, B, C, D
        [TotalProbationA] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [TotalProbationHoursA] DECIMAL(8,2) NOT NULL DEFAULT 0,
        [TotalOfficialB] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [TotalOfficialHoursB] DECIMAL(8,2) NOT NULL DEFAULT 0,
        [TotalAllowanceC] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [TotalDeductionD] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [NetSalary] DECIMAL(18,2) NOT NULL DEFAULT 0, -- Thực lãnh = A + B + C - D

        [Note] NVARCHAR(500) NULL,
        [Status] VARCHAR(30) NOT NULL DEFAULT 'DRAFT', -- DRAFT, APPROVED, PUBLISHED
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
        [UpdatedAt] DATETIME NULL,
        [UpdatedBy] VARCHAR(50) NULL,
        CONSTRAINT UQ_Period_User UNIQUE ([PeriodId], [UserCode])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PayslipDetails')
BEGIN
    CREATE TABLE [dbo].[PayslipDetails] (
        [DetailId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [PayslipId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[EmployeePayslips]([PayslipId]) ON DELETE CASCADE,
        [ComponentCode] VARCHAR(50) NOT NULL,
        [ComponentName] NVARCHAR(150) NOT NULL,
        [GroupType] CHAR(1) NOT NULL, -- A, B, C, D
        [HoursOrDays] DECIMAL(8,2) NOT NULL DEFAULT 0,
        [Amount] DECIMAL(18,2) NOT NULL DEFAULT 0,
        [SortOrder] INT NOT NULL DEFAULT 0
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SalaryClaims')
BEGIN
    CREATE TABLE [dbo].[SalaryClaims] (
        [ClaimId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [SecureId] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        [PayslipId] INT NOT NULL FOREIGN KEY REFERENCES [dbo].[EmployeePayslips]([PayslipId]) ON DELETE CASCADE,
        [PeriodId] INT NOT NULL,
        [UserCode] VARCHAR(50) NOT NULL,
        [FullName] NVARCHAR(150) NOT NULL,
        [ComponentCode] VARCHAR(50) NULL,
        [ComponentName] NVARCHAR(150) NULL,
        [ClaimType] VARCHAR(50) NOT NULL DEFAULT 'WRONG_HOURS', -- WRONG_HOURS, WRONG_ALLOWANCE, WRONG_DEDUCTION, OTHER
        [CurrentAmount] DECIMAL(18,2) NULL,
        [ExpectedAmount] DECIMAL(18,2) NULL,
        [Reason] NVARCHAR(1000) NOT NULL,
        [Status] VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, IN_REVIEW, RESOLVED, REJECTED
        [ResolutionNote] NVARCHAR(1000) NULL,
        [ResolvedBy] VARCHAR(50) NULL,
        [ResolvedAt] DATETIME NULL,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

-- ============================================================================
-- SEED DANH MỤC THÀNH PHẦN LƯƠNG CHUẨN HANSOL ELECTRONICS VIETNAM
-- ============================================================================

-- 1. NHÓM A: LƯƠNG THỬ VIỆC
MERGE INTO [dbo].[SalaryComponents] AS target
USING (VALUES
    ('A_WORK_DAYS',        N'Lương ngày công thử việc',       'A', 'FORMULA_HOURLY', 1, 1.00, 0, 1, 10, N'Ngày công thử việc 85%'),
    ('A_NIGHT_SHIFT',      N'PC ca đêm thử việc',            'A', 'FORMULA_HOURLY', 1, 0.30, 0, 1, 20, N'Phụ cấp 30% làm đêm thử việc'),
    ('A_OT_NORMAL_150',    N'Tiền tăng ca NT 150%',          'A', 'FORMULA_HOURLY', 1, 1.50, 0, 1, 30, N'Tăng ca ngày thường 150%'),
    ('A_OT_NIGHT_200',     N'Tiền tăng ca ĐNT 200%',         'A', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 40, N'Tăng ca đêm ngày thường 200%'),
    ('A_OT_NIGHT_210',     N'Tiền tăng ca ĐNT 210%',         'A', 'FORMULA_HOURLY', 1, 2.10, 0, 1, 50, N'Tăng ca đêm ngày thường 210%'),
    ('A_OT_SUNDAY_200',    N'Tiền tăng ca CN 200%',          'A', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 60, N'Tăng ca Chủ nhật 200%'),
    ('A_OT_SUN_NIGHT_270', N'Tiền tăng ca ĐCN 270%',         'A', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 70, N'Tăng ca đêm Chủ nhật 270%'),
    ('A_OT_HOLIDAY_300',   N'Tăng ca ngày lễ 300%',          'A', 'FORMULA_HOURLY', 1, 3.00, 0, 1, 80, N'Tăng ca ngày Lễ 300%'),
    ('A_OT_HOL_NIGHT_390', N'Tăng ca đêm lễ 390%',           'A', 'FORMULA_HOURLY', 1, 3.90, 0, 1, 90, N'Tăng ca đêm ngày Lễ 390%'),
    ('A_OT_COMP_200',      N'Tiền tăng ca nghỉ bù 200%',     'A', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 100, N'Tăng ca ngày nghỉ bù 200%'),
    ('A_OT_COMP_NIGHT_270',N'Tiền tăng ca đêm nghỉ bù 270%', 'A', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 110, N'Tăng ca đêm ngày nghỉ bù 270%')
) AS source ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
ON (target.[ComponentCode] = source.[ComponentCode])
WHEN NOT MATCHED THEN
    INSERT ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
    VALUES (source.[ComponentCode], source.[ComponentName], source.[GroupType], source.[CalculationType], source.[HasHours], source.[RateMultiplier], source.[DefaultAmount], source.[IsTaxable], source.[SortOrder], source.[Description]);

-- 2. NHÓM B: LƯƠNG CHÍNH THỨC
MERGE INTO [dbo].[SalaryComponents] AS target
USING (VALUES
    ('B_WORK_DAYS',        N'Lương ngày công CT',            'B', 'FORMULA_HOURLY', 1, 1.00, 0, 1, 10, N'Lương ngày công chính thức 100%'),
    ('B_NIGHT_SHIFT',      N'PC ca đêm chính thức',          'B', 'FORMULA_HOURLY', 1, 0.30, 0, 1, 20, N'Phụ cấp làm đêm 30%'),
    ('B_OT_NORMAL_150',    N'Tiền tăng ca NT 150%',          'B', 'FORMULA_HOURLY', 1, 1.50, 0, 1, 30, N'Tăng ca ngày thường 150%'),
    ('B_OT_NIGHT_200',     N'Tiền tăng ca ĐNT 200%',         'B', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 40, N'Tăng ca đêm ngày thường 200%'),
    ('B_OT_NIGHT_210',     N'Tiền tăng ca ĐNT 210%',         'B', 'FORMULA_HOURLY', 1, 2.10, 0, 1, 50, N'Tăng ca đêm ngày thường 210%'),
    ('B_OT_SUNDAY_200',    N'Tiền tăng ca CN 200%',          'B', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 60, N'Tăng ca Chủ nhật 200%'),
    ('B_OT_SUN_NIGHT_270', N'Tiền tăng ca ĐCN 270%',         'B', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 70, N'Tăng ca đêm Chủ nhật 270%'),
    ('B_OT_HOLIDAY_300',   N'Tăng ca ngày lễ 300%',          'B', 'FORMULA_HOURLY', 1, 3.00, 0, 1, 80, N'Tăng ca ngày Lễ 300%'),
    ('B_OT_HOL_NIGHT_390', N'Tăng ca đêm lễ 390%',           'B', 'FORMULA_HOURLY', 1, 3.90, 0, 1, 90, N'Tăng ca đêm ngày Lễ 390%'),
    ('B_OT_COMP_200',      N'Tiền tăng ca nghỉ bù 200%',     'B', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 100, N'Tăng ca nghỉ bù 200%'),
    ('B_OT_COMP_NIGHT_270',N'Tiền tăng ca đêm nghỉ bù 270%', 'B', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 110, N'Tăng ca đêm nghỉ bù 270%'),
    ('B_LEAVE_70',         N'Số ngày giờ nghỉ 70%',          'B', 'FORMULA_HOURLY', 1, 0.70, 0, 1, 120, N'Nghỉ ngừng việc hưởng 70%')
) AS source ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
ON (target.[ComponentCode] = source.[ComponentCode])
WHEN NOT MATCHED THEN
    INSERT ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
    VALUES (source.[ComponentCode], source.[ComponentName], source.[GroupType], source.[CalculationType], source.[HasHours], source.[RateMultiplier], source.[DefaultAmount], source.[IsTaxable], source.[SortOrder], source.[Description]);

-- 3. NHÓM C: KHOẢN PHỤ CẤP
MERGE INTO [dbo].[SalaryComponents] AS target
USING (VALUES
    ('C_PC_TRACH_NHIEM',   N'PC trách nhiệm',                'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 10, N'Phụ cấp trách nhiệm công việc'),
    ('C_PC_CHUYEN_CAN',    N'PC chuyên cần',                 'C', 'FIXED_AMOUNT', 0, 1.0, 300000, 1, 20, N'Thưởng chuyên cần đi làm đầy đủ'),
    ('C_PC_PCCC',          N'PC PCCC',                       'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 30, N'Đội PCCC cơ sở'),
    ('C_PC_DOI_SONG',      N'PC đời sống',                   'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 40, N'Hỗ trợ đời sống sinh hoạt'),
    ('C_PC_KIEM_TRA',      N'PC kiểm tra',                   'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 50, N'Phụ cấp kiểm tra chất lượng'),
    ('C_THUONG_NX',        N'Thưởng NX',                     'C', 'MANUAL',       0, 1.0, 0, 1, 60, N'Thưởng năng suất chuyền / xưởng'),
    ('C_NV_GUONG_MAU',     N'NV gương mẫu',                  'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 70, N'Thưởng nhân viên gương mẫu'),
    ('C_PC_KY_NANG',       N'PC kỹ năng',                    'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 80, N'Phụ cấp tay nghề / kỹ năng'),
    ('C_PC_NUOI_CON_NHO',  N'PC nuôi con nhỏ',               'C', 'FIXED_AMOUNT', 0, 1.0, 50000, 0, 90, N'Hỗ trợ nuôi con dưới 6 tuổi'),
    ('C_PC_AN_TOAN_VSV',   N'PC An toàn VSV',                'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 100, N'An toàn vệ sinh viên'),
    ('C_PC_CHUC_VU',       N'PC Chức vụ',                    'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 110, N'Phụ cấp chức danh quản lý'),
    ('C_BU_LUONG',         N'Bù lương',                      'C', 'MANUAL',       0, 1.0, 0, 1, 120, N'Bù truy lĩnh hoặc sai sót'),
    ('C_KET_HON_MA_CHAY',  N'Kết Hôn, Ma Chay',              'C', 'MANUAL',       0, 1.0, 0, 0, 130, N'Trợ cấp hiếu hỉ công đoàn'),
    ('C_TRO_CAP_THOI_VIEC',N'Trợ cấp thôi việc',             'C', 'MANUAL',       0, 1.0, 0, 0, 140, N'Trợ cấp thôi việc nghỉ chế độ'),
    ('C_TIEN_COM',         N'Tiền cơm',                      'C', 'FIXED_AMOUNT', 0, 1.0, 0, 0, 150, N'Trợ cấp tiền ăn ca nếu không ăn nhà ăn'),
    ('C_THUONG_TET',       N'Thưởng Tết',                    'C', 'MANUAL',       0, 1.0, 0, 1, 160, N'Thưởng Lễ Tết'),
    ('C_CHI_TRA_PHEP_NAM', N'Chi trả phép năm tồn TV',       'C', 'MANUAL',       0, 1.0, 0, 1, 170, N'Thanh toán ngày phép năm chưa sử dụng'),
    ('C_CHE_DO_PHU_NU',    N'Tiền chế độ Phụ Nữ',            'C', 'FIXED_AMOUNT', 0, 1.0, 0, 0, 180, N'Chế độ vệ sinh thai sản phụ nữ'),
    ('C_HOAN_THUE',        N'Hoàn thuế',                     'C', 'MANUAL',       0, 1.0, 0, 0, 190, N'Hoàn thuế thu nhập cá nhân'),
    ('C_KHAM_SK_PHI_GT',   N'tiền khám SK & phí giới thiệu', 'C', 'MANUAL',       0, 1.0, 0, 0, 200, N'Phí khám sức khỏe & giới thiệu nhân sự'),
    ('C_MBO',              N'MBO',                           'C', 'MANUAL',       0, 1.0, 0, 1, 210, N'Thưởng hiệu suất công việc MBO')
) AS source ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
ON (target.[ComponentCode] = source.[ComponentCode])
WHEN NOT MATCHED THEN
    INSERT ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
    VALUES (source.[ComponentCode], source.[ComponentName], source.[GroupType], source.[CalculationType], source.[HasHours], source.[RateMultiplier], source.[DefaultAmount], source.[IsTaxable], source.[SortOrder], source.[Description]);

-- 4. NHÓM D: KHOẢN TRỪ
MERGE INTO [dbo].[SalaryComponents] AS target
USING (VALUES
    ('D_MUC_DONG_BHXH',    N'Mức đóng BHXH',                 'D', 'MANUAL',       0, 1.0, 0, 0, 10, N'Căn cứ lương đóng BHXH'),
    ('D_BHXH_8',           N'BHXH (8%)',                     'D', 'RATE_PERCENT', 0, 0.08, 0, 0, 20, N'Trừ BHXH 8% lương đóng bảo hiểm'),
    ('D_BHYT_1_5',         N'BHYT (1,5%)',                   'D', 'RATE_PERCENT', 0, 0.015, 0, 0, 30, N'Trừ BHYT 1.5% lương đóng bảo hiểm'),
    ('D_BHTN_1',           N'BHTN (1%)',                     'D', 'RATE_PERCENT', 0, 0.01, 0, 0, 40, N'Trừ BHTN 1% lương đóng bảo hiểm'),
    ('D_CONG_DOAN',        N'Công Đoàn',                     'D', 'RATE_PERCENT', 0, 0.01, 0, 0, 50, N'Đoàn phí công đoàn'),
    ('D_VI_PHAM_HDLD',     N'Trừ vi phạm HĐLĐ',              'D', 'MANUAL',       0, 1.0, 0, 0, 60, N'Khấu trừ do vi phạm nội quy hợp đồng'),
    ('D_THUE_TNCN',        N'Thuế TNCN',                     'D', 'MANUAL',       0, 1.0, 0, 0, 70, N'Thuế thu nhập cá nhân tạm khấu trừ'),
    ('D_KHAU_TRU_BHYT',    N'Khấu trừ thẻ BHYT',             'D', 'MANUAL',       0, 1.0, 0, 0, 80, N'Khấu trừ chi phí thẻ BHYT'),
    ('D_SO_NGUOI_GIAM_TRU',N'Số người giảm trừ',             'D', 'MANUAL',       0, 1.0, 0, 0, 90, N'Số người phụ thuộc giảm trừ gia cảnh'),
    ('D_NV_GUONG_MAU',     N'NV gương mẫu',                  'D', 'MANUAL',       0, 1.0, 0, 0, 100, N'Thu hồi thưởng NV gương mẫu nếu vi phạm'),
    ('D_DONG_PHUC',        N'Tiền đồng phục',                'D', 'MANUAL',       0, 1.0, 0, 0, 110, N'Khấu trừ tiền đồng phục'),
    ('D_THIEN_TAI',        N'Tiền thiên tai',                'D', 'MANUAL',       0, 1.0, 0, 0, 120, N'Đóng góp quỹ cứu trợ thiên tai')
) AS source ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
ON (target.[ComponentCode] = source.[ComponentCode])
WHEN NOT MATCHED THEN
    INSERT ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [SortOrder], [Description])
    VALUES (source.[ComponentCode], source.[ComponentName], source.[GroupType], source.[CalculationType], source.[HasHours], source.[RateMultiplier], source.[DefaultAmount], source.[IsTaxable], source.[SortOrder], source.[Description]);

-- ============================================================================
-- SEED KỲ LƯƠNG & PHIẾU LƯƠNG THỰC TẾ THEO ẢNH CỦA USER
-- ============================================================================

DECLARE @PeriodId INT;
IF NOT EXISTS (SELECT 1 FROM [dbo].[PayrollPeriods] WHERE PeriodCode = 'PR_2026_05')
BEGIN
    INSERT INTO [dbo].[PayrollPeriods] (PeriodCode, PeriodName, FromDate, ToDate, PaymentDate, StandardWorkingDays, Status, TotalEmployees, TotalNetSalary, Note)
    VALUES ('PR_2026_05', N'Phiếu lương Tháng 05/2026', '2026-05-11', '2026-06-10', '2026-06-15', 23.0, 'PUBLISHED', 1, 14238000, N'Kỳ lương tính từ 11/05/2026 đến 10/06/2026 theo mẫu Hansol');
    SET @PeriodId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SELECT @PeriodId = PeriodId FROM [dbo].[PayrollPeriods] WHERE PeriodCode = 'PR_2026_05';
END

-- Thêm phiếu lương mẫu khớp với ảnh chụp: Nguyễn Lâm Đồng (1200837)
IF NOT EXISTS (SELECT 1 FROM [dbo].[EmployeePayslips] WHERE PeriodId = @PeriodId AND UserCode = '1200837')
BEGIN
    INSERT INTO [dbo].[EmployeePayslips] (
        PeriodId, UserCode, FullName, DepartmentCode, DepartmentName, PositionName, OrderNo, BankAccountNo,
        JoinDate, StandardDays, AnnualLeaveAvailable, BasicSalary, InsuranceSalary,
        HeaderPcAtvs, HeaderPccc, HeaderPcTrachNhiem, HeaderPcChucVu,
        TotalProbationA, TotalProbationHoursA, TotalOfficialB, TotalOfficialHoursB,
        TotalAllowanceC, TotalDeductionD, NetSalary, Note, Status
    )
    VALUES (
        @PeriodId, '1200837', N'Nguyễn Lâm Đồng', 'DEPT_IT', N'Phòng Công Nghệ Thông Tin (IT)', N'Sub Part Leader', 40, '1029384756',
        '2026-06-08', 23.0, 0, 11500000, 5200000,
        0, 0, 1500000, 1200000,
        13850000, 28.80, 0, 0,
        1250000, 862000, 14238000, N'Lương thử việc tháng 05 - Đạt chỉ tiêu hiệu suất Sub Part Leader', 'PUBLISHED'
    );

    DECLARE @PayslipId INT = SCOPE_IDENTITY();

    -- Chi tiết Nhóm A: Lương Thử Việc
    INSERT INTO [dbo].[PayslipDetails] (PayslipId, ComponentCode, ComponentName, GroupType, HoursOrDays, Amount, SortOrder) VALUES
    (@PayslipId, 'A_WORK_DAYS', N'Lương ngày công thử việc', 'A', 28.80, 13850000, 10);

    -- Chi tiết Nhóm C: Khoản Phụ Cấp
    INSERT INTO [dbo].[PayslipDetails] (PayslipId, ComponentCode, ComponentName, GroupType, HoursOrDays, Amount, SortOrder) VALUES
    (@PayslipId, 'C_PC_TRACH_NHIEM', N'PC trách nhiệm', 'C', 0, 800000, 10),
    (@PayslipId, 'C_PC_CHUC_VU',     N'PC Chức vụ',     'C', 0, 450000, 20);

    -- Chi tiết Nhóm D: Khoản Trừ
    INSERT INTO [dbo].[PayslipDetails] (PayslipId, ComponentCode, ComponentName, GroupType, HoursOrDays, Amount, SortOrder) VALUES
    (@PayslipId, 'D_MUC_DONG_BHXH', N'Mức đóng BHXH', 'D', 0, 5200000, 10),
    (@PayslipId, 'D_BHXH_8',        N'BHXH (8%)',     'D', 0, 416000, 20),
    (@PayslipId, 'D_BHYT_1_5',      N'BHYT (1,5%)',   'D', 0, 78000, 30),
    (@PayslipId, 'D_BHTN_1',        N'BHTN (1%)',     'D', 0, 52000, 40),
    (@PayslipId, 'D_CONG_DOAN',     N'Công Đoàn',     'D', 0, 52000, 50),
    (@PayslipId, 'D_THUE_TNCN',     N'Thuế TNCN',     'D', 0, 264000, 60);
END
GO

-- ============================================================================
-- ĐĂNG KÝ MENU & PHÂN QUYỀN
-- ============================================================================

-- 1. Menu HR: Quản lý Bảng lương Nhà máy (/hr/payroll)
IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE ProgramKey = '2004_PAYROLL')
BEGIN
    INSERT INTO [dbo].[ProgramMenus] (
        ProgramKey, ProgramName, Level, ParentProgramKey, ProgramGroup, UseFlag, MenuFlag,
        SortOrder, Path, Icon, CreatedAt, CreatedBy
    )
    VALUES (
        '2004_PAYROLL', N'Quản lý Bảng lương Nhà máy', 2, '2000_HR', N'Human Resource', 1, 1,
        50, '/hr/payroll', 'dollar', GETDATE(), 'ADMIN'
    );
END

-- 2. Menu Self-Service: Phiếu lương của tôi (/self-service/my-payslip)
IF NOT EXISTS (SELECT 1 FROM [dbo].[ProgramMenus] WHERE ProgramKey = '6040_MY_PAYSLIP')
BEGIN
    INSERT INTO [dbo].[ProgramMenus] (
        ProgramKey, ProgramName, Level, ParentProgramKey, ProgramGroup, UseFlag, MenuFlag,
        SortOrder, Path, Icon, CreatedAt, CreatedBy
    )
    VALUES (
        '6040_MY_PAYSLIP', N'Phiếu lương của tôi', 2, '6000_SELF_SERVICE', N'Self Service', 1, 1,
        40, '/self-service/my-payslip', 'wallet', GETDATE(), 'ADMIN'
    );
END
GO

-- Cấp quyền trong AuthorGroupMapping:
DECLARE @PayrollProgramId INT = (SELECT ProgramId FROM [dbo].[ProgramMenus] WHERE ProgramKey = '2004_PAYROLL');
DECLARE @MyPayslipProgramId INT = (SELECT ProgramId FROM [dbo].[ProgramMenus] WHERE ProgramKey = '6040_MY_PAYSLIP');

IF @PayrollProgramId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE GroupId = 1 AND ProgramId = @PayrollProgramId)
BEGIN
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    VALUES (1, @PayrollProgramId, 1, 1, 1, 1, 1, 1);
END

IF @MyPayslipProgramId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE GroupId = 1 AND ProgramId = @MyPayslipProgramId)
BEGIN
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    VALUES (1, @MyPayslipProgramId, 1, 1, 1, 1, 1, 1);
END

-- Cấp quyền xem phiếu lương cá nhân cho tất cả các nhóm người dùng khác
IF @MyPayslipProgramId IS NOT NULL
BEGIN
    INSERT INTO [dbo].[AuthorGroupMapping] (GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint)
    SELECT ag.GroupId, @MyPayslipProgramId, 1, 1, 0, 0, 0, 1
    FROM [dbo].[AuthorGroups] ag
    WHERE ag.GroupId > 1
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] m 
          WHERE m.GroupId = ag.GroupId AND m.ProgramId = @MyPayslipProgramId
      );
END
GO
