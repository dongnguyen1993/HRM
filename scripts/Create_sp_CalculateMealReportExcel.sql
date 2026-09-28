-- ==============================================================================
-- STORED PROCEDURE: sp_CalculateMealReportExcel
-- Purpose: Calculate all meal quantities, unit prices, and revenue for
--          Hansol Meal Report Excel export (TemplateReport_MealOrder.xlsx).
-- Project: HRM Enterprise System (Hansol Standard)
-- Created: 2026-09-19
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

IF OBJECT_ID('dbo.sp_CalculateMealReportExcel', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CalculateMealReportExcel;
GO

CREATE PROCEDURE dbo.sp_CalculateMealReportExcel
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Standard meal unit prices according to Hansol factory policy
    DECLARE @DefaultMealPrice DECIMAL(18,0) = 24000;    -- Default price for Vietnamese meals
    DECLARE @KoreanLunchPrice DECIMAL(18,0) = 75000;    -- Korean specialist lunch price
    DECLARE @KoreanDayOtPrice DECIMAL(18,0) = 75000;    -- Korean specialist afternoon OT price
    DECLARE @KoreanMorningPrice DECIMAL(18,0) = 45000;  -- Korean specialist morning OT price

    -- 2. Temporary table containing all calendar dates in the selected range
    DECLARE @Dates TABLE (
        CalendarDate DATE PRIMARY KEY,
        DayNumber INT,
        DayOfWeekVi NVARCHAR(20),
        IsSunday BIT
    );

    DECLARE @CurDate DATE = @StartDate;
    WHILE @CurDate <= @EndDate
    BEGIN
        INSERT INTO @Dates (CalendarDate, DayNumber, DayOfWeekVi, IsSunday)
        VALUES (
            @CurDate,
            DAY(@CurDate),
            CASE DATEPART(WEEKDAY, @CurDate)
                WHEN 1 THEN N'Chủ Nhật'
                WHEN 2 THEN N'Thứ Hai'
                WHEN 3 THEN N'Thứ Ba'
                WHEN 4 THEN N'Thứ Tư'
                WHEN 5 THEN N'Thứ Năm'
                WHEN 6 THEN N'Thứ Sáu'
                WHEN 7 THEN N'Thứ Bảy'
            END,
            CASE WHEN DATEPART(WEEKDAY, @CurDate) = 1 THEN 1 ELSE 0 END
        );
        SET @CurDate = DATEADD(DAY, 1, @CurDate);
    END;

    -- 3. Temporary table for special meal configurations extracted from WorkCalendar
    DECLARE @SpecialDays TABLE (
        CalendarDate DATE PRIMARY KEY,
        DayNumber INT,
        IsSpecialLunch BIT,
        IsSpecialDinner BIT,
        SpecialMealPrice DECIMAL(18,0),
        SpecialMealNote NVARCHAR(250),
        LunchCount INT DEFAULT 0,
        DinnerCount INT DEFAULT 0
    );

    INSERT INTO @SpecialDays (CalendarDate, DayNumber, IsSpecialLunch, IsSpecialDinner, SpecialMealPrice, SpecialMealNote)
    SELECT 
        wc.CalendarDate,
        DAY(wc.CalendarDate),
        CASE WHEN wc.SpecialMealTypes LIKE '%DAY_LUNCH%' THEN 1 ELSE 0 END,
        CASE WHEN wc.SpecialMealTypes LIKE '%NIGHT_DINNER%' THEN 1 ELSE 0 END,
        ISNULL(NULLIF(wc.SpecialMealPrice, 0), 30000),
        wc.SpecialMealNote
    FROM WorkCalendar wc WITH (NOLOCK)
    WHERE wc.CalendarDate BETWEEN @StartDate AND @EndDate
      AND wc.HasSpecialMeal = 1
      AND (wc.SpecialMealTypes LIKE '%DAY_LUNCH%' OR wc.SpecialMealTypes LIKE '%NIGHT_DINNER%');

    -- Aggregate actual meal orders for special meal dates (Vietnamese departments only)
    UPDATE sd
    SET sd.LunchCount = ISNULL(lunchAgg.TotalLunch, 0),
        sd.DinnerCount = ISNULL(dinnerAgg.TotalDinner, 0)
    FROM @SpecialDays sd
    LEFT JOIN (
        SELECT o.OrderDate, SUM(o.DayLunchCount) AS TotalLunch
        FROM DepartmentMealOrders o WITH (NOLOCK)
        WHERE o.DepartmentCode NOT IN ('KOREAN', 'HAN')
          AND o.OrderDate BETWEEN @StartDate AND @EndDate
        GROUP BY o.OrderDate
    ) lunchAgg ON sd.CalendarDate = lunchAgg.OrderDate
    LEFT JOIN (
        SELECT o.OrderDate, SUM(o.NightDinnerCount) AS TotalDinner
        FROM DepartmentMealOrders o WITH (NOLOCK)
        WHERE o.DepartmentCode NOT IN ('KOREAN', 'HAN')
          AND o.OrderDate BETWEEN @StartDate AND @EndDate
        GROUP BY o.OrderDate
    ) dinnerAgg ON sd.CalendarDate = dinnerAgg.OrderDate;

    -- 4. Factory-wide aggregation
    -- 4.1. Vietnamese Departments
    DECLARE @TotalVietLunch INT = 0;
    DECLARE @TotalVietDayOt INT = 0;
    DECLARE @TotalVietDinner INT = 0;
    DECLARE @TotalVietNightOt INT = 0;

    SELECT 
        @TotalVietLunch = ISNULL(SUM(o.DayLunchCount), 0),
        @TotalVietDayOt = ISNULL(SUM(o.DayOtCount), 0),
        @TotalVietDinner = ISNULL(SUM(o.NightDinnerCount), 0),
        @TotalVietNightOt = ISNULL(SUM(o.NightOtCount), 0)
    FROM DepartmentMealOrders o WITH (NOLOCK)
    WHERE o.DepartmentCode NOT IN ('KOREAN', 'HAN')
      AND o.OrderDate BETWEEN @StartDate AND @EndDate;

    -- 4.2. Korean Specialist Block
    DECLARE @TotalKoreanLunch INT = 0;
    DECLARE @TotalKoreanDayOt INT = 0;
    DECLARE @TotalKoreanNightOt INT = 0;

    SELECT 
        @TotalKoreanLunch = ISNULL(SUM(o.DayLunchCount), 0),
        @TotalKoreanDayOt = ISNULL(SUM(o.DayOtCount), 0),
        @TotalKoreanNightOt = ISNULL(SUM(o.NightOtCount), 0)
    FROM DepartmentMealOrders o WITH (NOLOCK)
    WHERE o.DepartmentCode IN ('KOREAN', 'HAN')
      AND o.OrderDate BETWEEN @StartDate AND @EndDate;

    -- 4.3. Special meal quantities and amounts
    DECLARE @SpecialLunchCount INT = 0;
    DECLARE @SpecialLunchAmount DECIMAL(18,0) = 0;
    DECLARE @SpecialDinnerCount INT = 0;
    DECLARE @SpecialDinnerAmount DECIMAL(18,0) = 0;

    SELECT 
        @SpecialLunchCount = ISNULL(SUM(CASE WHEN IsSpecialLunch = 1 THEN LunchCount ELSE 0 END), 0),
        @SpecialLunchAmount = ISNULL(SUM(CASE WHEN IsSpecialLunch = 1 THEN LunchCount * SpecialMealPrice ELSE 0 END), 0),
        @SpecialDinnerCount = ISNULL(SUM(CASE WHEN IsSpecialDinner = 1 THEN DinnerCount ELSE 0 END), 0),
        @SpecialDinnerAmount = ISNULL(SUM(CASE WHEN IsSpecialDinner = 1 THEN DinnerCount * SpecialMealPrice ELSE 0 END), 0)
    FROM @SpecialDays;

    -- Normal meal quantities and amounts
    DECLARE @NormalLunchCount INT = @TotalVietLunch - @SpecialLunchCount;
    DECLARE @NormalLunchAmount DECIMAL(18,0) = @NormalLunchCount * @DefaultMealPrice;

    DECLARE @DayOtAmount DECIMAL(18,0) = @TotalVietDayOt * @DefaultMealPrice;

    DECLARE @NormalDinnerCount INT = @TotalVietDinner - @SpecialDinnerCount;
    DECLARE @NormalDinnerAmount DECIMAL(18,0) = @NormalDinnerCount * @DefaultMealPrice;

    DECLARE @NightOtAmount DECIMAL(18,0) = @TotalVietNightOt * @DefaultMealPrice;

    -- Korean meal amounts
    DECLARE @KoreanLunchDayOtAmount DECIMAL(18,0) = (@TotalKoreanLunch + @TotalKoreanDayOt) * @KoreanLunchPrice;
    DECLARE @KoreanMorningAmount DECIMAL(18,0) = @TotalKoreanNightOt * @KoreanMorningPrice;

    -- Total revenues
    DECLARE @TotalVietnamAmount DECIMAL(18,0) = @NormalLunchAmount + @DayOtAmount + @NormalDinnerAmount + @NightOtAmount + @SpecialLunchAmount + @SpecialDinnerAmount;
    DECLARE @TotalKoreanAmount DECIMAL(18,0) = @KoreanLunchDayOtAmount + @KoreanMorningAmount;
    DECLARE @GrandTotalAmount DECIMAL(18,0) = @TotalVietnamAmount + @TotalKoreanAmount;

    -- ==========================================================================
    -- RESULT SET 1: SUMMARY KPI & REVENUE ACCOUNTING (Sheet 1: AM4:AR7)
    -- ==========================================================================
    SELECT 
        @StartDate AS StartDate,
        @EndDate AS EndDate,
        @DefaultMealPrice AS DefaultMealPrice,
        @KoreanLunchPrice AS KoreanLunchPrice,
        @KoreanMorningPrice AS KoreanMorningPrice,

        -- Day Lunch (Ca trua)
        @TotalVietLunch AS TotalLunch,
        @SpecialLunchCount AS SpecialLunchCount,
        @NormalLunchCount AS NormalLunchCount,
        @NormalLunchAmount AS NormalLunchAmount,       -- AN5
        @SpecialLunchAmount AS SpecialLunchAmount,     -- AN6

        -- Afternoon OT (Ca chieu 16:30)
        @TotalVietDayOt AS TotalDayOt,
        @DayOtAmount AS DayOtAmount,                   -- AO5
        CAST(0 AS DECIMAL(18,0)) AS SpecialDayOtAmount,-- AO6

        -- Night Dinner (Ca toi / dem)
        @TotalVietDinner AS TotalNightDinner,
        @SpecialDinnerCount AS SpecialNightDinnerCount,
        @NormalDinnerCount AS NormalNightDinnerCount,
        @NormalDinnerAmount AS NormalNightDinnerAmount,-- AP5
        @SpecialDinnerAmount AS SpecialNightDinnerAmount, -- AP6

        -- Morning OT (Ca sang 04:30)
        @TotalVietNightOt AS TotalNightOt,
        @NightOtAmount AS NightOtAmount,               -- AQ5
        CAST(0 AS DECIMAL(18,0)) AS SpecialNightOtAmount,-- AQ6

        -- Korean Specialist Meals
        @TotalKoreanLunch AS KoreanLunchCount,
        @TotalKoreanDayOt AS KoreanDayOtCount,
        @TotalKoreanNightOt AS KoreanNightOtCount,
        @KoreanLunchDayOtAmount AS KoreanLunchDayOtAmount, -- AR5
        @KoreanMorningAmount AS KoreanMorningAmount,       -- AR6

        -- Grand Totals
        @TotalVietnamAmount AS TotalVietnamAmount,     -- AN7
        @TotalKoreanAmount AS TotalKoreanAmount,       -- AR7
        @GrandTotalAmount AS GrandTotalAmount;

    -- ==========================================================================
    -- RESULT SET 2: SPECIAL MEAL DAYS IN RANGE
    -- ==========================================================================
    SELECT 
        CalendarDate,
        CONVERT(VARCHAR(10), CalendarDate, 120) AS DateStr,
        DayNumber,
        IsSpecialLunch,
        IsSpecialDinner,
        SpecialMealPrice,
        SpecialMealNote,
        LunchCount,
        DinnerCount
    FROM @SpecialDays
    ORDER BY CalendarDate ASC;

    -- ==========================================================================
    -- RESULT SET 3: VIETNAMESE DEPARTMENT ORDERS
    -- ==========================================================================
    SELECT 
        o.DepartmentCode,
        ISNULL(d.DepartmentName, o.DepartmentCode) AS DepartmentName,
        o.OrderDate,
        CONVERT(VARCHAR(10), o.OrderDate, 120) AS DateStr,
        DAY(o.OrderDate) AS DayNumber,
        o.DayLunchCount,
        o.DayOtCount,
        o.NightDinnerCount,
        o.NightOtCount
    FROM DepartmentMealOrders o WITH (NOLOCK)
    LEFT JOIN Departments d WITH (NOLOCK) ON o.DepartmentCode = d.DepartmentCode
    WHERE o.DepartmentCode NOT IN ('KOREAN', 'HAN')
      AND o.OrderDate BETWEEN @StartDate AND @EndDate
    ORDER BY o.DepartmentCode, o.OrderDate;

    -- ==========================================================================
    -- RESULT SET 4: KOREAN SPECIALIST MEALS BY DATE (Sheet 3)
    -- ==========================================================================
    SELECT 
        d.CalendarDate AS OrderDate,
        CONVERT(VARCHAR(10), d.CalendarDate, 120) AS DateStr,
        d.DayNumber,
        d.DayOfWeekVi,
        d.IsSunday,
        ISNULL(k.DayLunchCount, 0) AS DayLunchCount,  -- Column E: Lunch
        ISNULL(k.DayOtCount, 0) AS DayOtCount,        -- Column F: Afternoon OT
        ISNULL(k.NightOtCount, 0) AS NightOtCount     -- Column D: Morning OT
    FROM @Dates d
    LEFT JOIN (
        SELECT 
            o.OrderDate,
            SUM(o.DayLunchCount) AS DayLunchCount,
            SUM(o.DayOtCount) AS DayOtCount,
            SUM(o.NightOtCount) AS NightOtCount
        FROM DepartmentMealOrders o WITH (NOLOCK)
        WHERE o.DepartmentCode IN ('KOREAN', 'HAN')
          AND o.OrderDate BETWEEN @StartDate AND @EndDate
        GROUP BY o.OrderDate
    ) k ON d.CalendarDate = k.OrderDate
    ORDER BY d.CalendarDate ASC;

END;
GO
