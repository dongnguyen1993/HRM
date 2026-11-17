-- ==============================================================================
-- Script: seed_hr_leave_types.sql
-- Mục đích: Chuẩn hóa 8 loại nghỉ phép chuẩn doanh nghiệp trong dbo.HR_LeaveTypes
-- ==============================================================================
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#SeedLeaveTypes') IS NOT NULL DROP TABLE #SeedLeaveTypes;

CREATE TABLE #SeedLeaveTypes (
    LeaveTypeCode NVARCHAR(50),
    LeaveTypeName NVARCHAR(150),
    DaysPerYear DECIMAL(5,2),
    IsPaid BIT,
    Comment NVARCHAR(255)
);

INSERT INTO #SeedLeaveTypes (LeaveTypeCode, LeaveTypeName, DaysPerYear, IsPaid, Comment) VALUES
('AL',     N'Nghỉ Phép Năm Hưởng Lương',          12.0, 1, N'Nghỉ phép năm hưởng nguyên lương theo quy định'),
('SL',     N'Nghỉ Ốm Hưởng BHXH',                 30.0, 0, N'Nghỉ ốm đau có xác nhận của cơ sở y tế (BHXH chi trả)'),
('CL',     N'Nghỉ Việc Riêng Có Lương',            3.0, 1, N'Nghỉ kết hôn (3 ngày), con kết hôn (1 ngày), tang chế (3 ngày)'),
('UP',     N'Nghỉ Việc Riêng Không Lương',         0.0, 0, N'Nghỉ việc riêng thỏa thuận không hưởng lương'),
('ML',     N'Nghỉ Chế Độ Thai Sản',              180.0, 0, N'Nghỉ thai sản theo quy định luật BHXH (6 tháng)'),
('PL_PAT', N'Nghỉ Chế Độ Vợ Sinh Con',             5.0, 0, N'Nghỉ thai sản cho lao động nam khi vợ sinh con (5-14 ngày)'),
('CO',     N'Nghỉ Bù (Compensatory Leave)',        0.0, 1, N'Nghỉ bù làm việc ngày nghỉ/lễ theo phê duyệt'),
('WJ',     N'Nghỉ Tai Nạn Lao Động',               0.0, 1, N'Nghỉ điều trị do tai nạn lao động');

-- 1. Chèn loại phép chưa tồn tại
INSERT INTO dbo.HR_LeaveTypes (LeaveTypeCode, LeaveTypeName, DaysPerYear, IsPaid, UseFlag, Comment, CreatedAt, CreatedBy)
SELECT s.LeaveTypeCode, s.LeaveTypeName, s.DaysPerYear, s.IsPaid, 1, s.Comment, GETDATE(), 'SEED_DATA'
FROM #SeedLeaveTypes s
WHERE NOT EXISTS (SELECT 1 FROM dbo.HR_LeaveTypes lt WHERE lt.LeaveTypeCode = s.LeaveTypeCode);

-- 2. Cập nhật tên và thông tin chuẩn nếu đã có
UPDATE lt
SET lt.LeaveTypeName = s.LeaveTypeName,
    lt.DaysPerYear   = s.DaysPerYear,
    lt.IsPaid        = s.IsPaid,
    lt.Comment       = s.Comment,
    lt.UseFlag       = 1
FROM dbo.HR_LeaveTypes lt
INNER JOIN #SeedLeaveTypes s ON lt.LeaveTypeCode = s.LeaveTypeCode;

DROP TABLE #SeedLeaveTypes;

PRINT N'✅ Đã chuẩn hóa thành công 8 loại nghỉ phép trong dbo.HR_LeaveTypes!';
GO
