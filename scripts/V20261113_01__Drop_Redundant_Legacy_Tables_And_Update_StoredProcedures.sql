-- ==============================================================================
-- MIGRATION SCRIPT: V20261113_01__Drop_Redundant_Legacy_Tables_And_Update_StoredProcedures.sql
-- Mục đích:
--   1. Cập nhật 2 Stored Procedures (SP_GetDashboardAnalytics, sp_CalculateTimesheetEngine)
--      chuyển sang truy vấn các bảng có tiền tố Domain chuẩn (SYS_*, HR_*, GA_*).
--   2. Xóa bỏ khóa ngoại và 30 bảng dữ liệu cũ/dư thừa không có tiền tố Domain.
--   3. Dọn dẹp các bản ghi migration khởi tạo cũ trong __DbMigrationHistory.
-- Script có tính Idempotent (chạy lại nhiều lần an toàn, không báo lỗi).
-- ==============================================================================
SET NOCOUNT ON;
GO

-- ------------------------------------------------------------------------------
-- PHẦN 1: CẬP NHẬT STORED PROCEDURE [SP_GetDashboardAnalytics] SANG TIỀN TỐ SYS_*
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_GetDashboardAnalytics]
    @Year INT,
    @FromDate DATETIME2 = NULL,
    @ToDate DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Thống kê tổng quan (Summary)
    SELECT 
        (SELECT COUNT(1) FROM dbo.SYS_Users WITH (NOLOCK) WHERE Status = 1) AS TotalActiveUsers,
        (SELECT COUNT(1) FROM dbo.SYS_Users WITH (NOLOCK) WHERE Status = 0) AS TotalInactiveUsers,
        (SELECT COUNT(1) FROM dbo.SYS_AuthorGroups WITH (NOLOCK)) AS TotalGroups;

    -- 2. Thống kê tăng trưởng 12 tháng (Xử lý Zero Handling bằng CTE)
    ;WITH Months AS (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1 FROM Months WHERE MonthNumber < 12
    )
    SELECT 
        N'Tháng ' + CAST(M.MonthNumber AS NVARCHAR(2)) AS MonthLabel,
        ISNULL(COUNT(U.UserId), 0) AS UserCount
    FROM Months M
    LEFT JOIN dbo.SYS_Users U WITH (NOLOCK) ON M.MonthNumber = MONTH(U.CreatedAt) 
        AND YEAR(U.CreatedAt) = @Year
        AND (@FromDate IS NULL OR U.CreatedAt >= @FromDate)
        AND (@ToDate IS NULL OR U.CreatedAt <= @ToDate)
    GROUP BY M.MonthNumber
    ORDER BY M.MonthNumber;

    -- 3. Thống kê phân bổ nhân sự theo Nhóm quyền (Dữ liệu cho biểu đồ Tròn/Cột)
    SELECT 
        AG.GroupName AS Label,
        COUNT(UGM.UserId) AS Value
    FROM dbo.SYS_AuthorGroups AG WITH (NOLOCK)
    LEFT JOIN dbo.SYS_UserGroupMapping UGM WITH (NOLOCK) ON AG.GroupId = UGM.GroupId
    GROUP BY AG.GroupName;
END;
GO

-- ------------------------------------------------------------------------------
-- PHẦN 2: CẬP NHẬT STORED PROCEDURE [sp_CalculateTimesheetEngine] SANG TIỀN TỐ HR_*, SYS_*
-- ------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_CalculateTimesheetEngine]
    @FromDate DATE,
    @ToDate DATE,
    @OperatorCode NVARCHAR(50) = 'SYSTEM',
    @UserCodeFilter NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- =========================================================================
        -- 0. NẠP CẤU HÌNH CA LÀM VIỆC TỪ BẢNG WorkShifts
        -- =========================================================================
        DECLARE @DayShiftId INT = 1, @NightShiftId INT = 2;
        DECLARE @DayGrace INT = 5, @NightGrace INT = 5;

        SELECT TOP 1 @DayShiftId = ShiftId, @DayGrace = ISNULL(GracePeriodMinutes, 5)
        FROM dbo.HR_WorkShifts WITH (NOLOCK) WHERE ShiftCode = 'SHIFT_DAY' AND UseFlag = 1;

        SELECT TOP 1 @NightShiftId = ShiftId, @NightGrace = ISNULL(GracePeriodMinutes, 5)
        FROM dbo.HR_WorkShifts WITH (NOLOCK) WHERE ShiftCode = 'SHIFT_NIGHT' AND UseFlag = 1;

        -- =========================================================================
        -- 1. LỌC DỮ LIỆU THÔ: BỘ LỌC THÔNG MINH CHO MỌI SỰ KIỆN XÁC THỰC THÀNH CÔNG
        -- =========================================================================
        IF OBJECT_ID('tempdb..#CleanRawLogs') IS NOT NULL DROP TABLE #CleanRawLogs;

        SELECT 
            m.LogTimestamp,
            LTRIM(RTRIM(m.UserCode)) AS CleanUserCode,
            ISNULL(m.UserName, N'') AS CleanUserName,
            ISNULL(m.UserGroup, N'Chưa xếp nhóm') AS UserGroup,
            m.DeviceName,

            CASE 
                WHEN d.GateDirection = 'GATE_IN' OR m.DeviceName LIKE '%GATE_IN%' THEN 1 
                ELSE 0 
            END AS IsGateIn,
            
            CASE 
                WHEN d.GateDirection = 'GATE_OUT' OR m.DeviceName LIKE '%GATE_OUT%' THEN 1 
                ELSE 0 
            END AS IsGateOut,

            CASE 
                WHEN (d.GateDirection IN ('WORKSHOP', 'OFFICE') 
                      OR m.DeviceName LIKE '%PROD_FINGER%' 
                      OR m.DeviceName LIKE '%MAINOFFICE%' 
                      OR m.DeviceName LIKE '%FINGER%')
                 AND ISNULL(d.GateDirection, '') <> 'CANTEEN'
                 AND m.DeviceName NOT LIKE '%CANTEEN%'
                THEN 1 
                ELSE 0 
            END AS IsInternalDevice,
            
            -- Gán ngày làm việc: Quẹt từ 00:00 đến trước 05:00 sáng tính về ngày làm việc hôm trước
            CAST(
                CASE 
                    WHEN CAST(m.LogTimestamp AS TIME) < '05:00:00' 
                    THEN DATEADD(DAY, -1, m.LogTimestamp)
                    ELSE m.LogTimestamp
                END AS DATE
            ) AS AdjustedWorkDate
        INTO #CleanRawLogs
        FROM dbo.HR_MachineRecords m WITH (NOLOCK)
        LEFT JOIN dbo.SYS_DeviceSetup d WITH (NOLOCK) ON m.DeviceName = d.DeviceName OR m.DeviceId = d.BioStarDeviceId
        WHERE m.LogTimestamp >= CAST(@FromDate AS DATETIME)
          AND m.LogTimestamp < DATEADD(DAY, 2, CAST(@ToDate AS DATETIME))
          AND ISNULL(m.UseFlag, 1) = 1
          
          -- =========================================================================
          -- 🔥 BỘ LỌC MỚI CHUẨN XÁC: CHẤP NHẬN TẤT CẢ BIẾN THỂ CỦA AUTHENTICATION SUCCEEDED
          -- =========================================================================
          AND m.EventDescription LIKE '%authentication succeeded%'
          AND m.EventDescription NOT LIKE '%failed%'
          AND m.EventDescription NOT LIKE '%update%'
          AND m.EventDescription NOT LIKE '%enrollment%'
          AND m.EventDescription NOT LIKE '%Door%'
          
          -- LOẠI BỎ HOÀN TOÀN MÁY NHÀ ĂN (CANTEEN)
          AND ISNULL(d.GateDirection, '') <> 'CANTEEN'
          AND m.DeviceName NOT LIKE '%CANTEEN%'
          AND (@UserCodeFilter IS NULL OR @UserCodeFilter = '' OR m.UserCode LIKE '%' + @UserCodeFilter + '%');

        CREATE CLUSTERED INDEX IX_CleanRawLogs ON #CleanRawLogs(CleanUserCode, AdjustedWorkDate, LogTimestamp);

        -- =========================================================================
        -- 2. XÁC ĐỊNH CA LÀM & GIỜ VÀO THEO 2 NHÁNH (CỔNG & MÁY XƯỞNG)
        -- =========================================================================
        IF OBJECT_ID('tempdb..#IdentifiedPunches') IS NOT NULL DROP TABLE #IdentifiedPunches;

        WITH DailyEmployees AS (
            SELECT DISTINCT CleanUserCode AS UserCode, AdjustedWorkDate AS WorkDate 
            FROM #CleanRawLogs
            WHERE AdjustedWorkDate BETWEEN @FromDate AND @ToDate
        ),
        PunchAnalysis AS (
            SELECT 
                emp.UserCode,
                emp.WorkDate,
                MAX(r.CleanUserName) AS FullName,
                MAX(r.UserGroup) AS UserGroup,

                -- 1. CỔNG VÀO CA SÁNG: GATE_IN từ 05:00 đến 17:30 trong ngày
                MAX(CASE 
                    WHEN r.IsGateIn = 1 
                     AND CAST(r.LogTimestamp AS DATE) = emp.WorkDate
                     AND CAST(r.LogTimestamp AS TIME) >= '05:00:00' 
                     AND CAST(r.LogTimestamp AS TIME) <= '17:30:00'
                    THEN r.LogTimestamp 
                END) AS GateIn_Day,

                -- 2. CỔNG VÀO CA ĐÊM: GATE_IN từ sau 17:30 đến trước 05:00 sáng hôm sau
                MAX(CASE 
                    WHEN r.IsGateIn = 1 
                     AND (
                         (CAST(r.LogTimestamp AS DATE) = emp.WorkDate AND CAST(r.LogTimestamp AS TIME) > '17:30:00')
                         OR (CAST(r.LogTimestamp AS DATE) = DATEADD(DAY, 1, emp.WorkDate) AND CAST(r.LogTimestamp AS TIME) < '05:00:00')
                     )
                    THEN r.LogTimestamp 
                END) AS GateIn_Night,

                -- 5. MÁY XƯỞNG CA SÁNG: Khung 07:00 -> 07:35
                MAX(CASE 
                    WHEN r.IsInternalDevice = 1 
                     AND CAST(r.LogTimestamp AS DATE) = emp.WorkDate
                     AND CAST(r.LogTimestamp AS TIME) >= '07:00:00' 
                     AND CAST(r.LogTimestamp AS TIME) <= DATEADD(MINUTE, @DayGrace, CAST('07:30:00' AS TIME))
                    THEN r.LogTimestamp 
                END) AS InternalIn_Day,

                -- 5. MÁY XƯỞNG CA ĐÊM: Khung 19:30 -> 20:05
                MAX(CASE 
                    WHEN r.IsInternalDevice = 1 
                     AND CAST(r.LogTimestamp AS DATE) = emp.WorkDate
                     AND CAST(r.LogTimestamp AS TIME) >= '19:30:00' 
                     AND CAST(r.LogTimestamp AS TIME) <= DATEADD(MINUTE, @NightGrace, CAST('20:00:00' AS TIME))
                    THEN r.LogTimestamp 
                END) AS InternalIn_Night

            FROM DailyEmployees emp
            JOIN #CleanRawLogs r ON emp.UserCode = r.CleanUserCode AND emp.WorkDate = r.AdjustedWorkDate
            GROUP BY emp.UserCode, emp.WorkDate
        )
        SELECT 
            p.UserCode,
            p.FullName,
            p.UserGroup,
            p.WorkDate,

            -- XÁC ĐỊNH CA LÀM
            CASE 
                WHEN p.GateIn_Night IS NOT NULL OR (p.GateIn_Day IS NULL AND p.InternalIn_Night IS NOT NULL) THEN @NightShiftId
                WHEN p.GateIn_Day IS NOT NULL OR (p.GateIn_Night IS NULL AND p.InternalIn_Day IS NOT NULL) THEN @DayShiftId
                ELSE 0 
            END AS ShiftId,

            -- GIỜ VÀO CUỐI CÙNG
            COALESCE(p.GateIn_Night, p.InternalIn_Night, p.GateIn_Day, p.InternalIn_Day) AS FinalCheckIn,

            CASE 
                WHEN p.GateIn_Night IS NOT NULL OR p.GateIn_Day IS NOT NULL THEN 'GATE'
                WHEN p.InternalIn_Night IS NOT NULL OR p.InternalIn_Day IS NOT NULL THEN 'INTERNAL_FINGER'
                ELSE 'UNKNOWN'
            END AS PunchSource

        INTO #IdentifiedPunches
        FROM PunchAnalysis p;

        -- =========================================================================
        -- 3. XÁC ĐỊNH GIỜ RA (CHECK-OUT) THEO TỪNG CA
        -- =========================================================================
        IF OBJECT_ID('tempdb..#ResolvedPunches') IS NOT NULL DROP TABLE #ResolvedPunches;

        SELECT 
            p.UserCode,
            p.FullName,
            p.UserGroup,
            p.WorkDate,
            p.ShiftId,
            p.FinalCheckIn,
            p.PunchSource,

            CASE 
                -- CA ĐÊM: Giờ ra từ lúc vào đến trước 12:00 trưa hôm sau
                WHEN p.ShiftId = @NightShiftId THEN
                    (
                        SELECT MAX(outLog.LogTimestamp)
                        FROM #CleanRawLogs outLog
                        WHERE outLog.CleanUserCode = p.UserCode
                          AND outLog.LogTimestamp > ISNULL(p.FinalCheckIn, CAST(p.WorkDate AS DATETIME))
                          AND (outLog.IsGateOut = 1 OR outLog.IsInternalDevice = 1)
                          AND outLog.LogTimestamp <= DATEADD(HOUR, 12, DATEADD(DAY, 1, CAST(p.WorkDate AS DATETIME)))
                    )

                -- CA SÁNG: Giờ ra trễ nhất trong ngày cùng ngày
                WHEN p.ShiftId = @DayShiftId THEN
                    (
                        SELECT MAX(outLog.LogTimestamp)
                        FROM #CleanRawLogs outLog
                        WHERE outLog.CleanUserCode = p.UserCode
                          AND outLog.LogTimestamp > ISNULL(p.FinalCheckIn, CAST(p.WorkDate AS DATETIME))
                          AND (outLog.IsGateOut = 1 OR outLog.IsInternalDevice = 1)
                          AND CAST(outLog.LogTimestamp AS DATE) = p.WorkDate
                    )

                -- NGOẠI LỆ
                ELSE
                    (
                        SELECT MAX(outLog.LogTimestamp)
                        FROM #CleanRawLogs outLog
                        WHERE outLog.CleanUserCode = p.UserCode
                          AND CAST(outLog.LogTimestamp AS DATE) = p.WorkDate
                    )
            END AS FinalCheckOut

        INTO #ResolvedPunches
        FROM #IdentifiedPunches p;

        -- =========================================================================
        -- 4. TÍNH CÔNG VÀ SỐ PHÚT TĂNG CA SAU GIỜ TAN CA CHUẨN
        -- =========================================================================
        IF OBJECT_ID('tempdb..#CalculatedPrep') IS NOT NULL DROP TABLE #CalculatedPrep;

        SELECT 
            p.UserCode,
            ISNULL(p.FullName, p.UserCode) AS FullName,
            p.UserGroup,
            p.WorkDate,
            p.ShiftId,
            p.FinalCheckIn AS CheckInTime,
            p.FinalCheckOut AS CheckOutTime,

            -- Tổng số phút ở xưởng thực tế
            CASE 
                WHEN p.FinalCheckIn IS NOT NULL AND p.FinalCheckOut IS NOT NULL 
                THEN DATEDIFF(MINUTE, p.FinalCheckIn, p.FinalCheckOut)
                ELSE 0
            END AS TotalStayMinutes,

            -- SỐ PHÚT TĂNG CA: CHỈ TÍNH TỪ SAU 18:00 (CA NGÀY) HOẶC SAU 05:36 (CA ĐÊM)
            CASE 
                -- Ca Sáng: Quẹt ra sau 18:00:00
                WHEN p.ShiftId = @DayShiftId AND p.FinalCheckIn IS NOT NULL AND p.FinalCheckOut IS NOT NULL
                THEN DATEDIFF(MINUTE, CAST(CONVERT(VARCHAR(10), p.WorkDate, 120) + ' 18:00:00' AS DATETIME), p.FinalCheckOut)

                -- Ca Đêm: Quẹt ra sau 05:36:00 sáng hôm sau
                WHEN p.ShiftId = @NightShiftId AND p.FinalCheckIn IS NOT NULL AND p.FinalCheckOut IS NOT NULL
                THEN DATEDIFF(MINUTE, DATEADD(MINUTE, 36, DATEADD(HOUR, 5, CAST(CONVERT(VARCHAR(10), DATEADD(DAY, 1, p.WorkDate), 120) AS DATETIME))), p.FinalCheckOut)

                ELSE 0
            END AS OvertimeMinutesAfterShift

        INTO #CalculatedPrep
        FROM #ResolvedPunches p;

        -- =========================================================================
        -- 5. KẾT XUẤT KẾT QUẢ CUỐI CÙNG (CÔNG, OT BƯỚC 10P, CỜ ĐỎ)
        -- =========================================================================
        IF OBJECT_ID('tempdb..#CalculatedResults') IS NOT NULL DROP TABLE #CalculatedResults;

        SELECT 
            c.UserCode,
            c.FullName,
            c.UserGroup,
            c.WorkDate,
            CASE WHEN c.ShiftId = 0 THEN @DayShiftId ELSE c.ShiftId END AS ShiftId,
            c.CheckInTime,
            c.CheckOutTime,

            -- 1. TÍNH CÔNG CHUẨN
            CASE 
                WHEN c.ShiftId = 0 OR (c.CheckInTime IS NULL AND c.CheckOutTime IS NULL) THEN 0.0
                WHEN c.CheckInTime IS NULL OR c.CheckOutTime IS NULL THEN 0.5

                -- CA ĐÊM:
                WHEN c.ShiftId = @NightShiftId THEN
                    CASE 
                        -- Về trước 00:00 giải lao hoặc ở xưởng < 4 tiếng -> 0 CÔNG
                        WHEN c.CheckOutTime < DATEADD(DAY, 1, CAST(CONVERT(VARCHAR(10), c.WorkDate, 120) AS DATETIME)) OR c.TotalStayMinutes < 240 THEN 0.0
                        -- Về sau 00:00 giải lao nhưng trước 05:00 sáng -> 0.5 CÔNG
                        WHEN c.CheckOutTime < DATEADD(HOUR, 5, DATEADD(DAY, 1, CAST(CONVERT(VARCHAR(10), c.WorkDate, 120) AS DATETIME))) THEN 0.5
                        -- Đủ ca đêm -> 1.0 CÔNG
                        ELSE 1.0
                    END

                -- CA SÁNG:
                ELSE
                    CASE 
                        -- Về trước 12:00 trưa hoặc ở xưởng < 4 tiếng -> 0 CÔNG
                        WHEN CAST(c.CheckOutTime AS TIME) < '12:00:00' OR c.TotalStayMinutes < 240 THEN 0.0
                        -- Về sau 12:00 trưa nhưng trước 17:30 -> 0.5 CÔNG
                        WHEN CAST(c.CheckOutTime AS TIME) < '17:30:00' THEN 0.5
                        -- Đủ ca sáng -> 1.0 CÔNG
                        ELSE 1.0
                    END
            END AS WorkUnits,

            -- 2. TÍNH TĂNG CA OT (TỐI THIỂU 30 PHÚT, BƯỚC NHẢY 10 PHÚT)
            CASE 
                WHEN c.ShiftId > 0 AND c.CheckInTime IS NOT NULL AND c.CheckOutTime IS NOT NULL AND c.OvertimeMinutesAfterShift >= 30
                THEN CAST(ROUND((FLOOR(c.OvertimeMinutesAfterShift / 10.0) * 10.0) / 60.0, 1) AS DECIMAL(4,1))
                ELSE 0.0
            END AS OtHours,

            -- 3. GẮN CỜ ĐỎ CẢNH BÁO
            CASE 
                WHEN c.ShiftId = 0 
                     OR c.CheckInTime IS NULL 
                     OR c.CheckOutTime IS NULL 
                     OR (c.ShiftId = @NightShiftId AND c.CheckOutTime < DATEADD(HOUR, 5, DATEADD(DAY, 1, CAST(CONVERT(VARCHAR(10), c.WorkDate, 120) AS DATETIME))))
                     OR (c.ShiftId = @DayShiftId AND CAST(c.CheckOutTime AS TIME) < '17:30:00')
                THEN 1
                ELSE 0
            END AS IsWarning,

            -- 4. GHI CHÚ CHI TIẾT DÀNH CHO HR
            CASE 
                WHEN c.ShiftId = 0 THEN N'Không xác định được ca làm việc (Quẹt ngoài khung giờ) - Cần HR sửa tay'
                WHEN c.CheckInTime IS NULL AND c.CheckOutTime IS NULL THEN N'Không có dữ liệu quẹt thẻ trong ngày'
                WHEN c.CheckInTime IS NULL THEN N'Thiếu quẹt thẻ đầu ca (Missed Check-In) - Cần HR duyệt'
                WHEN c.CheckOutTime IS NULL THEN N'Thiếu quẹt thẻ lúc về (Missed Check-Out) - Cần HR duyệt'
                WHEN c.ShiftId = @NightShiftId AND c.CheckOutTime < DATEADD(DAY, 1, CAST(CONVERT(VARCHAR(10), c.WorkDate, 120) AS DATETIME)) 
                    THEN N'Về trước giờ nghỉ giải lao 00:00 (' + CONVERT(VARCHAR(8), c.CheckOutTime, 108) + N') - Tính 0 công'
                WHEN c.ShiftId = @NightShiftId AND c.CheckOutTime < DATEADD(HOUR, 5, DATEADD(DAY, 1, CAST(CONVERT(VARCHAR(10), c.WorkDate, 120) AS DATETIME)))
                    THEN N'Về sớm ca đêm (' + CONVERT(VARCHAR(8), c.CheckOutTime, 108) + N') - Tính 0.5 công'
                WHEN c.ShiftId = @DayShiftId AND CAST(c.CheckOutTime AS TIME) < '17:30:00'
                    THEN N'Về sớm ca ngày (' + CONVERT(VARCHAR(8), c.CheckOutTime, 108) + N') - Tính 0.5 công'
                ELSE N'Khớp ca chuẩn xác'
            END AS WarningReason,

            -- 5. TRẠNG THÁI BẢN GHI
            CASE 
                WHEN c.ShiftId = 0 
                     OR c.CheckInTime IS NULL 
                     OR c.CheckOutTime IS NULL 
                     OR (c.ShiftId = @NightShiftId AND c.CheckOutTime < DATEADD(HOUR, 5, DATEADD(DAY, 1, CAST(CONVERT(VARCHAR(10), c.WorkDate, 120) AS DATETIME))))
                     OR (c.ShiftId = @DayShiftId AND CAST(c.CheckOutTime AS TIME) < '17:30:00')
                THEN N'Pending_Review'
                ELSE N'PUNCTUAL'
            END AS Status

        INTO #CalculatedResults
        FROM #CalculatedPrep c;

        -- =========================================================================
        -- 6. MERGE NGUYÊN TỬ VÀO BẢNG WorkSummary
        -- =========================================================================
        MERGE INTO dbo.HR_WorkSummary AS target
        USING (
            SELECT 
                r.*, 
                u.UserId 
            FROM (
                SELECT *, ROW_NUMBER() OVER (PARTITION BY UserCode, WorkDate ORDER BY WorkUnits DESC, CheckInTime ASC) AS rn
                FROM #CalculatedResults
            ) r
            LEFT JOIN (
                SELECT UserCode, MAX(UserId) AS UserId 
                FROM dbo.SYS_Users WITH (NOLOCK) 
                GROUP BY UserCode
            ) u ON r.UserCode = u.UserCode
            WHERE r.rn = 1
        ) AS source
        ON (target.UserCode = source.UserCode AND target.WorkDate = source.WorkDate)
        
        WHEN MATCHED THEN
            UPDATE SET 
                target.UserId = source.UserId,
                target.FullName = ISNULL(source.FullName, target.FullName),
                target.UserGroup = ISNULL(source.UserGroup, target.UserGroup),
                target.ShiftId = source.ShiftId,
                target.CheckInTime = source.CheckInTime,
                target.CheckOutTime = source.CheckOutTime,
                target.WorkUnits = source.WorkUnits,
                target.OtHours = source.OtHours,
                target.Status = source.Status,
                target.Comment = source.WarningReason,
                target.IsWarning = source.IsWarning,
                target.WarningReason = source.WarningReason,
                target.CreatedAt = GETUTCDATE()

        WHEN NOT MATCHED THEN
            INSERT (
                UserId, UserCode, FullName, UserGroup, WorkDate, ShiftId,
                CheckInTime, CheckOutTime, LateMinutes, EarlyMinutes, 
                WorkUnits, OtHours, Status, Comment, IsWarning, WarningReason, CreatedAt
            )
            VALUES (
                source.UserId, source.UserCode, source.FullName, source.UserGroup, source.WorkDate, source.ShiftId,
                source.CheckInTime, source.CheckOutTime, 0, 0, 
                source.WorkUnits, source.OtHours, source.Status, source.WarningReason, 
                source.IsWarning, source.WarningReason, GETUTCDATE()
            );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END
GO

-- ------------------------------------------------------------------------------
-- PHẦN 3: XÓA RÀNG BUỘC KHÓA NGOẠI VÀ 30 BẢNG DƯ THỪA (KHÔNG CÓ TIỀN TỐ DOMAIN)
-- ------------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Xóa khóa ngoại bảng con cũ
    IF OBJECT_ID('dbo.FK_PayrollEmployee_Period', 'F') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.Payroll_Employee_Monthly DROP CONSTRAINT FK_PayrollEmployee_Period;
        PRINT N'[OK] Đã xóa khóa ngoại FK_PayrollEmployee_Period';
    END

    -- 2. Xóa 30 bảng cũ dư thừa theo thứ tự an toàn
    DECLARE @droppedCount INT = 0;
    DECLARE @legacyTables TABLE (TableName NVARCHAR(100));
    INSERT INTO @legacyTables (TableName) VALUES 
        ('Payroll_Employee_Monthly'), ('Payroll_Salary_Item'), ('Payroll_Period'),
        ('DepartmentMealOrders'), ('GaDepartments'), ('WorkCalendar'),
        ('MachineRecords'), ('WorkSummary'), ('WorkRequests'), ('WorkShifts'),
        ('OtRegistrations'), ('LaborContracts'), ('LeaveTypes'), ('Positions'),
        ('Departments'), ('AuditLogs'), ('Announcements'), ('CommonCodes'),
        ('DeviceSetup'), ('NotificationEvents'), ('Notifications'),
        ('ProgramMenus'), ('SystemSettings'), ('User_Theme_Settings'),
        ('UserAttachments'), ('UserTokens'), ('AuthorGroupMapping'),
        ('UserGroupMapping'), ('AuthorGroups'), ('Users');

    DECLARE @tbl NVARCHAR(100);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT TableName FROM @legacyTables;
    OPEN cur;
    FETCH NEXT FROM cur INTO @tbl;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF OBJECT_ID('dbo.' + @tbl, 'U') IS NOT NULL
        BEGIN
            EXEC('DROP TABLE dbo.[' + @tbl + ']');
            PRINT N'[OK] Đã xóa bảng dư thừa: ' + @tbl;
            SET @droppedCount = @droppedCount + 1;
        END
        FETCH NEXT FROM cur INTO @tbl;
    END
    CLOSE cur;
    DEALLOCATE cur;

    PRINT N'=== Tổng cộng đã xóa ' + CAST(@droppedCount AS NVARCHAR(10)) + N' bảng dư thừa ===';

    -- 3. Dọn dẹp bản ghi khởi tạo cũ trong __DbMigrationHistory
    DELETE FROM dbo.__DbMigrationHistory 
    WHERE MigrationId IN (
        'TABLE_INIT_Announcements', 'TABLE_INIT_AuditLogs', 'TABLE_INIT_AuthorGroupMapping',
        'TABLE_INIT_AuthorGroups', 'TABLE_INIT_CommonCodes', 'TABLE_INIT_DepartmentMealOrders',
        'TABLE_INIT_Departments', 'TABLE_INIT_DeviceSetup', 'TABLE_INIT_GaDepartments',
        'TABLE_INIT_LaborContracts', 'TABLE_INIT_LeaveTypes', 'TABLE_INIT_MachineRecords',
        'TABLE_INIT_NotificationEvents', 'TABLE_INIT_NotificationMatrix', 'TABLE_INIT_Notifications',
        'TABLE_INIT_OtRegistrations', 'TABLE_INIT_Payroll_Employee_Monthly', 'TABLE_INIT_Payroll_Period',
        'TABLE_INIT_Payroll_Salary_Item', 'TABLE_INIT_Positions', 'TABLE_INIT_ProgramMenus',
        'TABLE_INIT_SystemSettings', 'TABLE_INIT_User_Theme_Settings', 'TABLE_INIT_UserAttachments',
        'TABLE_INIT_UserGroupMapping', 'TABLE_INIT_Users', 'TABLE_INIT_UserTokens',
        'TABLE_INIT_WorkCalendar', 'TABLE_INIT_WorkRequests', 'TABLE_INIT_WorkShifts',
        'TABLE_INIT_WorkSummary'
    );
    PRINT N'[OK] Đã dọn dẹp các mục khởi tạo cũ trong __DbMigrationHistory';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT DI DỜI VÀ DỌN DẸP CSDL THÀNH CÔNG ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@err, 16, 1);
END CATCH;
GO
