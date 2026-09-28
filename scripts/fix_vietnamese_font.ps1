$connectionStrings = @(
  "Server=localhost;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;",
  "Server=localhost,14333;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
)

$sqlScript = @"
-- 1. Fix ProgramMenus
UPDATE ProgramMenus
SET ProgramName = N'Quản lý Bảng lương Nhà máy'
WHERE ProgramKey = '2004_PAYROLL';

UPDATE ProgramMenus
SET ProgramName = N'Phiếu lương của tôi'
WHERE ProgramKey = '6040_MY_PAYSLIP';

UPDATE ProgramMenus
SET ProgramName = N'Bảng tin & Thông báo'
WHERE ProgramKey = '1070';

-- 2. Fix PayrollPeriods
UPDATE PayrollPeriods
SET PeriodName = N'Phiếu lương Tháng 05/2026',
    Note = N'Kỳ lương tính từ 11/05/2026 đến 10/06/2026 theo mẫu Hansol'
WHERE PeriodCode = 'PR_2026_05';

-- 3. Clear and re-insert SalaryComponents with 100% exact Vietnamese matching Hansol photo
DELETE FROM SalaryComponents;

INSERT INTO [dbo].[SalaryComponents] ([ComponentCode], [ComponentName], [GroupType], [CalculationType], [HasHours], [RateMultiplier], [DefaultAmount], [IsTaxable], [IsActive], [SortOrder], [Description])
VALUES
-- NHÓM A: LƯƠNG THỬ VIỆC
('A_WORK_DAYS',        N'Lương ngày công thử việc',         'A', 'FORMULA_HOURLY', 1, 1.00, 0, 1, 1, 10,  N'Ngày công thử việc 85%'),
('A_NIGHT_SHIFT',      N'PC ca đêm thử việc',               'A', 'FORMULA_HOURLY', 1, 0.30, 0, 1, 1, 20,  N'Phụ cấp 30% làm đêm thử việc'),
('A_OT_NORMAL_150',    N'Tiền tăng ca NT 150%',             'A', 'FORMULA_HOURLY', 1, 1.50, 0, 1, 1, 30,  N'Tăng ca ngày thường 150%'),
('A_OT_NIGHT_200',     N'Tiền tăng ca ĐNT 200%',            'A', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 1, 40,  N'Tăng ca đêm ngày thường 200%'),
('A_OT_NIGHT_210',     N'Tiền tăng ca ĐNT 210%',            'A', 'FORMULA_HOURLY', 1, 2.10, 0, 1, 1, 50,  N'Tăng ca đêm ngày thường 210%'),
('A_OT_SUNDAY_200',    N'Tiền tăng ca CN 200%',             'A', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 1, 60,  N'Tăng ca Chủ nhật 200%'),
('A_OT_SUN_NIGHT_270', N'Tiền tăng ca ĐCN 270%',            'A', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 1, 70,  N'Tăng ca đêm Chủ nhật 270%'),
('A_OT_HOLIDAY_300',   N'Tăng ca ngày lễ 300%',             'A', 'FORMULA_HOURLY', 1, 3.00, 0, 1, 1, 80,  N'Tăng ca ngày Lễ 300%'),
('A_OT_HOL_NIGHT_390', N'Tăng ca đêm lễ 390%',              'A', 'FORMULA_HOURLY', 1, 3.90, 0, 1, 1, 90,  N'Tăng ca đêm ngày Lễ 390%'),
('A_OT_COMP_200',      N'Tiền tăng ca nghỉ bù 200%',        'A', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 1, 100, N'Tăng ca ngày nghỉ bù 200%'),
('A_OT_COMP_NIGHT_270',N'Tiền tăng ca đêm nghỉ bù 270%',   'A', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 1, 110, N'Tăng ca đêm ngày nghỉ bù 270%'),

-- NHÓM B: LƯƠNG CHÍNH THỨC
('B_WORK_DAYS',        N'Lương ngày công CT',               'B', 'FORMULA_HOURLY', 1, 1.00, 0, 1, 1, 10,  N'Lương ngày công chính thức 100%'),
('B_NIGHT_SHIFT',      N'PC ca đêm chính thức',             'B', 'FORMULA_HOURLY', 1, 0.30, 0, 1, 1, 20,  N'Phụ cấp làm đêm 30%'),
('B_OT_NORMAL_150',    N'Tiền tăng ca NT 150%',             'B', 'FORMULA_HOURLY', 1, 1.50, 0, 1, 1, 30,  N'Tăng ca ngày thường 150%'),
('B_OT_NIGHT_200',     N'Tiền tăng ca ĐNT 200%',            'B', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 1, 40,  N'Tăng ca đêm ngày thường 200%'),
('B_OT_NIGHT_210',     N'Tiền tăng ca ĐNT 210%',            'B', 'FORMULA_HOURLY', 1, 2.10, 0, 1, 1, 50,  N'Tăng ca đêm ngày thường 210%'),
('B_OT_SUNDAY_200',    N'Tiền tăng ca CN 200%',             'B', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 1, 60,  N'Tăng ca Chủ nhật 200%'),
('B_OT_SUN_NIGHT_270', N'Tiền tăng ca ĐCN 270%',            'B', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 1, 70,  N'Tăng ca đêm Chủ nhật 270%'),
('B_OT_HOLIDAY_300',   N'Tăng ca ngày lễ 300%',             'B', 'FORMULA_HOURLY', 1, 3.00, 0, 1, 1, 80,  N'Tăng ca ngày Lễ 300%'),
('B_OT_HOL_NIGHT_390', N'Tăng ca đêm lễ 390%',              'B', 'FORMULA_HOURLY', 1, 3.90, 0, 1, 1, 90,  N'Tăng ca đêm ngày Lễ 390%'),
('B_OT_COMP_200',      N'Tiền tăng ca nghỉ bù 200%',        'B', 'FORMULA_HOURLY', 1, 2.00, 0, 1, 1, 100, N'Tăng ca nghỉ bù 200%'),
('B_OT_COMP_NIGHT_270',N'Tiền tăng ca đêm nghỉ bù 270%',   'B', 'FORMULA_HOURLY', 1, 2.70, 0, 1, 1, 110, N'Tăng ca đêm nghỉ bù 270%'),
('B_LEAVE_70',         N'Số ngày giờ nghỉ 70%',             'B', 'FORMULA_HOURLY', 1, 0.70, 0, 1, 1, 120, N'Nghỉ ngừng việc hưởng 70%'),

-- NHÓM C: KHOẢN PHỤ CẤP
('C_PC_TRACH_NHIEM',   N'PC trách nhiệm',                   'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 10,  N'Phụ cấp trách nhiệm công việc'),
('C_PC_CHUYEN_CAN',    N'PC chuyên cần',                    'C', 'FIXED_AMOUNT', 0, 1.0, 300000, 1, 1, 20,  N'Thưởng chuyên cần đi làm đầy đủ'),
('C_PC_PCCC',          N'PC PCCC',                          'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 30,  N'Đội PCCC cơ sở'),
('C_PC_DOI_SONG',      N'PC đời sống',                      'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 40,  N'Hỗ trợ đời sống sinh hoạt'),
('C_PC_KIEM_TRA',      N'PC kiểm tra',                      'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 50,  N'Phụ cấp kiểm tra chất lượng'),
('C_THUONG_NX',        N'Thưởng NX',                        'C', 'MANUAL',       0, 1.0, 0, 1, 1, 60,  N'Thưởng năng suất chuyền / xưởng'),
('C_NV_GUONG_MAU',     N'NV gương mẫu',                     'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 70,  N'Thưởng nhân viên gương mẫu'),
('C_PC_KY_NANG',       N'PC kỹ năng',                       'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 80,  N'Phụ cấp tay nghề / kỹ năng'),
('C_PC_NUOI_CON_NHO',  N'PC nuôi con nhỏ',                  'C', 'FIXED_AMOUNT', 0, 1.0, 50000, 0, 1, 90,  N'Hỗ trợ nuôi con dưới 6 tuổi'),
('C_PC_AN_TOAN_VSV',   N'PC An toàn VSV',                   'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 100, N'An toàn vệ sinh viên'),
('C_PC_CHUC_VU',       N'PC Chức vụ',                       'C', 'FIXED_AMOUNT', 0, 1.0, 0, 1, 1, 110, N'Phụ cấp chức danh quản lý'),
('C_BU_LUONG',         N'Bù lương',                         'C', 'MANUAL',       0, 1.0, 0, 1, 1, 120, N'Bù truy lĩnh hoặc sai sót'),
('C_KET_HON_MA_CHAY',  N'Kết Hôn, Ma Chay',                 'C', 'MANUAL',       0, 1.0, 0, 0, 1, 130, N'Trợ cấp hiếu hỉ công đoàn'),
('C_TRO_CAP_THOI_VIEC',N'Trợ cấp thôi việc',                'C', 'MANUAL',       0, 1.0, 0, 0, 1, 140, N'Trợ cấp thôi việc nghỉ chế độ'),
('C_TIEN_COM',         N'Tiền cơm',                         'C', 'FIXED_AMOUNT', 0, 1.0, 0, 0, 1, 150, N'Trợ cấp tiền ăn ca nếu không ăn nhà ăn'),
('C_THUONG_TET',       N'Thưởng Tết',                       'C', 'MANUAL',       0, 1.0, 0, 1, 1, 160, N'Thưởng Lễ Tết'),
('C_CHI_TRA_PHEP_NAM', N'Chi trả phép năm tồn TV',          'C', 'MANUAL',       0, 1.0, 0, 1, 1, 170, N'Thanh toán ngày phép năm chưa sử dụng'),
('C_CHE_DO_PHU_NU',    N'Tiền chế độ Phụ Nữ',               'C', 'FIXED_AMOUNT', 0, 1.0, 0, 0, 1, 180, N'Chế độ vệ sinh thai sản phụ nữ'),
('C_HOAN_THUE',        N'Hoàn thuế',                        'C', 'MANUAL',       0, 1.0, 0, 0, 1, 190, N'Hoàn thuế thu nhập cá nhân'),
('C_KHAM_SK_PHI_GT',   N'tiền khám SK & phí giới thiệu',    'C', 'MANUAL',       0, 1.0, 0, 0, 1, 200, N'Phí khám sức khỏe & giới thiệu nhân sự'),
('C_MBO',              N'MBO',                              'C', 'MANUAL',       0, 1.0, 0, 1, 1, 210, N'Thưởng hiệu suất công việc MBO'),

-- NHÓM D: KHOẢN TRỪ
('D_MUC_DONG_BHXH',    N'Mức đóng BHXH',                    'D', 'MANUAL',       0, 1.0, 0, 0, 1, 10,  N'Căn cứ lương đóng BHXH'),
('D_BHXH_8',           N'BHXH (8%)',                        'D', 'RATE_PERCENT', 0, 0.08, 0, 0, 1, 20,  N'Trừ BHXH 8% lương đóng bảo hiểm'),
('D_BHYT_1_5',         N'BHYT (1,5%)',                      'D', 'RATE_PERCENT', 0, 0.015, 0, 0, 1, 30,  N'Trừ BHYT 1.5% lương đóng bảo hiểm'),
('D_BHTN_1',           N'BHTN (1%)',                        'D', 'RATE_PERCENT', 0, 0.01, 0, 0, 1, 40,  N'Trừ BHTN 1% lương đóng bảo hiểm'),
('D_CONG_DOAN',        N'Công Đoàn',                        'D', 'RATE_PERCENT', 0, 0.01, 0, 0, 1, 50,  N'Đoàn phí công đoàn'),
('D_VI_PHAM_HDLD',     N'Trừ vi phạm HĐLĐ',                 'D', 'MANUAL',       0, 1.0, 0, 0, 1, 60,  N'Khấu trừ do vi phạm nội quy hợp đồng'),
('D_THUE_TNCN',        N'Thuế TNCN',                        'D', 'MANUAL',       0, 1.0, 0, 0, 1, 70,  N'Thuế thu nhập cá nhân tạm khấu trừ'),
('D_KHAU_TRU_BHYT',    N'Khấu trừ thẻ BHYT',                'D', 'MANUAL',       0, 1.0, 0, 0, 1, 80,  N'Khấu trừ chi phí thẻ BHYT'),
('D_SO_NGUOI_GIAM_TRU',N'Số người giảm trừ',                'D', 'MANUAL',       0, 1.0, 0, 0, 1, 90,  N'Số người phụ thuộc giảm trừ gia cảnh'),
('D_NV_GUONG_MAU',     N'NV gương mẫu',                     'D', 'MANUAL',       0, 1.0, 0, 0, 1, 100, N'Thu hồi thưởng NV gương mẫu nếu vi phạm'),
('D_DONG_PHUC',        N'Tiền đồng phục',                   'D', 'MANUAL',       0, 1.0, 0, 0, 1, 110, N'Khấu trừ tiền đồng phục'),
('D_THIEN_TAI',        N'Tiền thiên tai',                   'D', 'MANUAL',       0, 1.0, 0, 0, 1, 120, N'Đóng góp quỹ cứu trợ thiên tai');

-- 4. Clean and re-seed Payslip Details for employee 1200837
DELETE FROM PayslipDetails WHERE PayslipId = 1;

UPDATE EmployeePayslips
SET FullName = N'Nguyễn Lâm Đồng',
    DepartmentName = N'IT',
    PositionName = N'Sub Part Leader',
    BankAccountNo = '9704070000000000',
    JoinDate = '2026-06-08',
    StandardDays = 23.0,
    AnnualLeaveAvailable = 0,
    BasicSalary = 13850000,
    InsuranceSalary = 5200000,
    HeaderPcAtvs = 0,
    HeaderPccc = 0,
    HeaderPcTrachNhiem = 800000,
    HeaderPcChucVu = 450000,
    TotalProbationA = 13850000,
    TotalProbationHoursA = 28.80,
    TotalOfficialB = 0,
    TotalOfficialHoursB = 0,
    TotalAllowanceC = 1250000,
    TotalDeductionD = 862000,
    NetSalary = 14238000
WHERE PayslipId = 1;

INSERT INTO PayslipDetails (PayslipId, ComponentCode, ComponentName, GroupType, HoursOrDays, Amount, SortOrder)
VALUES
(1, 'A_WORK_DAYS',          N'Lương ngày công thử việc', 'A', 28.80, 13850000, 10),
(1, 'C_PC_TRACH_NHIEM',     N'PC trách nhiệm',           'C', 0,     800000,   10),
(1, 'C_PC_CHUC_VU',         N'PC Chức vụ',               'C', 0,     450000,   110),
(1, 'D_MUC_DONG_BHXH',      N'Mức đóng BHXH',            'D', 0,     5200000,  10),
(1, 'D_BHXH_8',             N'BHXH (8%)',                'D', 0,     416000,   20),
(1, 'D_BHYT_1_5',           N'BHYT (1,5%)',              'D', 0,     78000,    30),
(1, 'D_BHTN_1',             N'BHTN (1%)',                'D', 0,     52000,    40),
(1, 'D_CONG_DOAN',          N'Công Đoàn',                'D', 0,     52000,    50),
(1, 'D_THUE_TNCN',          N'Thuế TNCN',                'D', 0,     264000,   70);
"@

foreach ($connStr in $connectionStrings) {
  try {
    Write-Host "Connecting to $connStr..."
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sqlScript
    $cmd.ExecuteNonQuery() | Out-Null
    $conn.Close()
    Write-Host "Successfully updated Vietnamese data on $connStr!" -ForegroundColor Green
  } catch {
    Write-Host "Error updating $connStr : $_" -ForegroundColor Red
  }
}
