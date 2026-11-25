-- =========================================================================================
-- SCRIPT CẬP NHẬT DỮ LIỆU CA LÀM VIỆC (HR_WorkShifts) & KHÓA QUYỀN SỬA SHIFT SETUP
-- Tên file: V20261125_UPDATE_HR_WORKSHIFTS_AND_LOCK_PERMISSIONS.sql
-- Dự án: HRM Enterprise System (Target: DB REAL)
-- Ngày tạo: 2026-11-25
-- Mục đích:
--   1. Mở rộng metadata chuẩn trên HR_WorkShifts (tương thích ngược 100% với code & SP cũ):
--      - DivisionType        : Khối áp dụng ('OFFICE' | 'PRODUCTION' | 'LEGACY' | 'ALL')
--      - WorkDaysPattern     : Ngày làm việc ('MON-FRI' | 'MON-SAT')
--      - ShortBreakSchedules : Giờ nghỉ giải lao tính vào giờ làm
--      - IsMealBreakPaid     : 1 = Ăn cơm TÍNH vào giờ làm; 0 = KHÔNG tính vào giờ làm
--      - EffectiveFrom / EffectiveTo : Ngày hiệu lực áp dụng (lộ trình 2026-12-11)
--   2. Chuẩn hóa & thêm mới dữ liệu ca làm việc theo bảng quy định mới (ShiftCode tường minh theo Khối):
--      - SHIFT_OFFICE_DAY   (Văn Phòng - Hành chính, T2-T6, 07:30-18:00, ăn cơm 12:06-13:00 không tính công -> 9.60h)
--      - SHIFT_OFFICE_NIGHT (Văn Phòng - Ca đêm, T2-T6, 20:00-05:36, ăn cơm 00:00-00:45 không tính công -> 9.60h, giữ nguyên lâu dài)
--      - SHIFT_PROD_DAY     (Sản Xuất - Hành chính 1, T2-T7, 07:30-16:30, ăn cơm 11:00-12:00 không tính công -> 8.00h, từ 11/12/2026)
--      - SHIFT_PROD_NIGHT   (Sản Xuất - Ca đêm, T2-T7, 20:00-04:00, ăn cơm 23:30-00:15 TÍNH công -> 8.00h, từ 11/12/2026)
--   3. Khóa quyền Thêm/Sửa/Xóa (IsCreate=0, IsUpdate=0, IsDelete=0) trên màn hình
--      2005_HR_SHIFT_SETUP trong SYS_AuthorGroupMapping (chỉ giữ quyền Xem & In/Xuất).
-- Lưu ý: Script IDEMPOTENT (chạy lại nhiều lần đều an toàn), chuỗi Unicode dùng N'...'.
-- =========================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT N'================================================================================';
PRINT N'=== [BƯỚC 1/3] MỞ RỘNG CỘT METADATA CHUẨN CHO BẢNG dbo.HR_WorkShifts ===';
PRINT N'================================================================================';

IF COL_LENGTH('dbo.HR_WorkShifts', 'DivisionType') IS NULL
BEGIN
    ALTER TABLE dbo.HR_WorkShifts
        ADD DivisionType NVARCHAR(30) NOT NULL CONSTRAINT DF_HR_WorkShifts_DivisionType DEFAULT (N'ALL');
    PRINT N'   -> Đã thêm cột DivisionType.';
END;

IF COL_LENGTH('dbo.HR_WorkShifts', 'WorkDaysPattern') IS NULL
BEGIN
    ALTER TABLE dbo.HR_WorkShifts
        ADD WorkDaysPattern VARCHAR(20) NOT NULL CONSTRAINT DF_HR_WorkShifts_WorkDaysPattern DEFAULT ('MON-FRI');
    PRINT N'   -> Đã thêm cột WorkDaysPattern.';
END;

IF COL_LENGTH('dbo.HR_WorkShifts', 'ShortBreakSchedules') IS NULL
BEGIN
    ALTER TABLE dbo.HR_WorkShifts
        ADD ShortBreakSchedules NVARCHAR(100) NULL;
    PRINT N'   -> Đã thêm cột ShortBreakSchedules.';
END;

IF COL_LENGTH('dbo.HR_WorkShifts', 'IsMealBreakPaid') IS NULL
BEGIN
    ALTER TABLE dbo.HR_WorkShifts
        ADD IsMealBreakPaid BIT NOT NULL CONSTRAINT DF_HR_WorkShifts_IsMealBreakPaid DEFAULT (0);
    PRINT N'   -> Đã thêm cột IsMealBreakPaid.';
END;

IF COL_LENGTH('dbo.HR_WorkShifts', 'EffectiveFrom') IS NULL
BEGIN
    ALTER TABLE dbo.HR_WorkShifts
        ADD EffectiveFrom DATE NULL;
    PRINT N'   -> Đã thêm cột EffectiveFrom.';
END;

IF COL_LENGTH('dbo.HR_WorkShifts', 'EffectiveTo') IS NULL
BEGIN
    ALTER TABLE dbo.HR_WorkShifts
        ADD EffectiveTo DATE NULL;
    PRINT N'   -> Đã thêm cột EffectiveTo.';
END;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'================================================================================';
    PRINT N'=== [BƯỚC 2/3] CẬP NHẬT & BỔ SUNG DỮ LIỆU CA LÀM VIỆC (HR_WorkShifts) ===';
    PRINT N'================================================================================';

    -- ---------------------------------------------------------------------------------
    -- 2.1 KHỐI VĂN PHÒNG - CA HÀNH CHÍNH (SHIFT_OFFICE_DAY)
    --   - Thứ 2 - Thứ 6 | 07:30 - 18:00 (10.5h)
    --   - Giải lao tính công: 09:30-09:40, 15:00-15:10
    --   - Ăn cơm KHÔNG tính công: 12:06-13:00 (54 phút = 0.90h) => Công chuẩn = 9.60h
    --   - Đổi tên mã từ SHIFT_DAY -> SHIFT_OFFICE_DAY ngay trên bản ghi cũ để giữ nguyên ShiftId=1.
    -- ---------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM dbo.HR_WorkShifts WHERE ShiftCode = 'SHIFT_OFFICE_DAY')
    BEGIN
        UPDATE dbo.HR_WorkShifts
        SET ShiftName           = N'Văn Phòng - Hành Chính (07:30 - 18:00)',
            StartTime           = CAST('07:30:00' AS TIME(7)),
            EndTime             = CAST('18:00:00' AS TIME(7)),
            BreakStartTime      = CAST('12:06:00' AS TIME(7)),
            BreakEndTime        = CAST('13:00:00' AS TIME(7)),
            GracePeriodMinutes  = 5,
            TotalWorkHours      = 9.60,
            IsOvernight         = 0,
            Description         = N'[Văn Phòng | T2-T6] Giải lao 09:30-09:40, 15:00-15:10 (tính công); Ăn cơm 12:06-13:00 (không tính công).',
            UseFlag             = 1,
            DivisionType        = N'OFFICE',
            WorkDaysPattern     = 'MON-FRI',
            ShortBreakSchedules = N'09:30-09:40, 15:00-15:10',
            IsMealBreakPaid     = 0,
            EffectiveFrom       = NULL,
            EffectiveTo         = NULL
        WHERE ShiftCode = 'SHIFT_OFFICE_DAY';
        PRINT N'   -> Đã cập nhật SHIFT_OFFICE_DAY (Văn Phòng - Hành Chính).';
    END
    ELSE IF EXISTS (SELECT 1 FROM dbo.HR_WorkShifts WHERE ShiftCode = 'SHIFT_DAY')
    BEGIN
        UPDATE dbo.HR_WorkShifts
        SET ShiftCode           = 'SHIFT_OFFICE_DAY',
            ShiftName           = N'Văn Phòng - Hành Chính (07:30 - 18:00)',
            StartTime           = CAST('07:30:00' AS TIME(7)),
            EndTime             = CAST('18:00:00' AS TIME(7)),
            BreakStartTime      = CAST('12:06:00' AS TIME(7)),
            BreakEndTime        = CAST('13:00:00' AS TIME(7)),
            GracePeriodMinutes  = 5,
            TotalWorkHours      = 9.60,
            IsOvernight         = 0,
            Description         = N'[Văn Phòng | T2-T6] Giải lao 09:30-09:40, 15:00-15:10 (tính công); Ăn cơm 12:06-13:00 (không tính công).',
            UseFlag             = 1,
            DivisionType        = N'OFFICE',
            WorkDaysPattern     = 'MON-FRI',
            ShortBreakSchedules = N'09:30-09:40, 15:00-15:10',
            IsMealBreakPaid     = 0,
            EffectiveFrom       = NULL,
            EffectiveTo         = NULL
        WHERE ShiftCode = 'SHIFT_DAY';
        PRINT N'   -> Đã chuẩn hóa SHIFT_DAY -> SHIFT_OFFICE_DAY (giữ nguyên ShiftId).';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.HR_WorkShifts (
            ShiftCode, ShiftName, StartTime, EndTime, BreakStartTime, BreakEndTime,
            GracePeriodMinutes, TotalWorkHours, IsOvernight, Description, UseFlag, CreatedAt,
            DivisionType, WorkDaysPattern, ShortBreakSchedules, IsMealBreakPaid, EffectiveFrom, EffectiveTo
        )
        VALUES (
            'SHIFT_OFFICE_DAY', N'Văn Phòng - Hành Chính (07:30 - 18:00)',
            CAST('07:30:00' AS TIME(7)), CAST('18:00:00' AS TIME(7)),
            CAST('12:06:00' AS TIME(7)), CAST('13:00:00' AS TIME(7)),
            5, 9.60, 0,
            N'[Văn Phòng | T2-T6] Giải lao 09:30-09:40, 15:00-15:10 (tính công); Ăn cơm 12:06-13:00 (không tính công).',
            1, GETUTCDATE(),
            N'OFFICE', 'MON-FRI', N'09:30-09:40, 15:00-15:10', 0, NULL, NULL
        );
        PRINT N'   -> Đã thêm mới SHIFT_OFFICE_DAY (Văn Phòng - Hành Chính).';
    END;

    -- ---------------------------------------------------------------------------------
    -- 2.2 KHỐI VĂN PHÒNG - CA ĐÊM (SHIFT_OFFICE_NIGHT) - GIỮ NGUYÊN NHƯ CŨ, KHÔNG GIỚI HẠN NGÀY
    --   - Thứ 2 - Thứ 6 | 20:00 - 05:36 (qua ngày, IsOvernight = 1)
    --   - Ăn cơm KHÔNG tính công: 00:00-00:45 (45 phút) => Công chuẩn = 9.60h
    --   - Đổi tên mã từ SHIFT_NIGHT -> SHIFT_OFFICE_NIGHT ngay trên bản ghi cũ để giữ nguyên ShiftId=2.
    -- ---------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM dbo.HR_WorkShifts WHERE ShiftCode = 'SHIFT_OFFICE_NIGHT')
    BEGIN
        UPDATE dbo.HR_WorkShifts
        SET ShiftName           = N'Văn Phòng - Ca Đêm (20:00 - 05:36)',
            StartTime           = CAST('20:00:00' AS TIME(7)),
            EndTime             = CAST('05:36:00' AS TIME(7)),
            BreakStartTime      = CAST('00:00:00' AS TIME(7)),
            BreakEndTime        = CAST('00:45:00' AS TIME(7)),
            GracePeriodMinutes  = 5,
            TotalWorkHours      = 9.60,
            IsOvernight         = 1,
            Description         = N'[Văn Phòng | Giữ nguyên] Khung quẹt vào 19:30 - 20:05, về sau 05:36 sáng hôm sau, ăn cơm 00:00-00:45, công chuẩn 9.6h.',
            UseFlag             = 1,
            DivisionType        = N'OFFICE',
            WorkDaysPattern     = 'MON-FRI',
            ShortBreakSchedules = NULL,
            IsMealBreakPaid     = 0,
            EffectiveFrom       = NULL,
            EffectiveTo         = NULL
        WHERE ShiftCode = 'SHIFT_OFFICE_NIGHT';
        PRINT N'   -> Đã cập nhật SHIFT_OFFICE_NIGHT (Văn Phòng - Ca Đêm 20:00 - 05:36).';
    END
    ELSE IF EXISTS (SELECT 1 FROM dbo.HR_WorkShifts WHERE ShiftCode = 'SHIFT_NIGHT')
    BEGIN
        UPDATE dbo.HR_WorkShifts
        SET ShiftCode           = 'SHIFT_OFFICE_NIGHT',
            ShiftName           = N'Văn Phòng - Ca Đêm (20:00 - 05:36)',
            StartTime           = CAST('20:00:00' AS TIME(7)),
            EndTime             = CAST('05:36:00' AS TIME(7)),
            BreakStartTime      = CAST('00:00:00' AS TIME(7)),
            BreakEndTime        = CAST('00:45:00' AS TIME(7)),
            GracePeriodMinutes  = 5,
            TotalWorkHours      = 9.60,
            IsOvernight         = 1,
            Description         = N'[Văn Phòng | Giữ nguyên] Khung quẹt vào 19:30 - 20:05, về sau 05:36 sáng hôm sau, ăn cơm 00:00-00:45, công chuẩn 9.6h.',
            UseFlag             = 1,
            DivisionType        = N'OFFICE',
            WorkDaysPattern     = 'MON-FRI',
            ShortBreakSchedules = NULL,
            IsMealBreakPaid     = 0,
            EffectiveFrom       = NULL,
            EffectiveTo         = NULL
        WHERE ShiftCode = 'SHIFT_NIGHT';
        PRINT N'   -> Đã chuẩn hóa SHIFT_NIGHT -> SHIFT_OFFICE_NIGHT (giữ nguyên ShiftId).';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.HR_WorkShifts (
            ShiftCode, ShiftName, StartTime, EndTime, BreakStartTime, BreakEndTime,
            GracePeriodMinutes, TotalWorkHours, IsOvernight, Description, UseFlag, CreatedAt,
            DivisionType, WorkDaysPattern, ShortBreakSchedules, IsMealBreakPaid, EffectiveFrom, EffectiveTo
        )
        VALUES (
            'SHIFT_OFFICE_NIGHT', N'Văn Phòng - Ca Đêm (20:00 - 05:36)',
            CAST('20:00:00' AS TIME(7)), CAST('05:36:00' AS TIME(7)),
            CAST('00:00:00' AS TIME(7)), CAST('00:45:00' AS TIME(7)),
            5, 9.60, 1,
            N'[Văn Phòng | Giữ nguyên] Khung quẹt vào 19:30 - 20:05, về sau 05:36 sáng hôm sau, ăn cơm 00:00-00:45, công chuẩn 9.6h.',
            1, GETUTCDATE(),
            N'OFFICE', 'MON-FRI', NULL, 0, NULL, NULL
        );
        PRINT N'   -> Đã thêm mới SHIFT_OFFICE_NIGHT (Văn Phòng - Ca Đêm 20:00 - 05:36).';
    END;

    -- ---------------------------------------------------------------------------------
    -- 2.3 KHỐI SẢN XUẤT - HÀNH CHÍNH 1 (SHIFT_PROD_DAY) - ÁP DỤNG TỪ 11/12/2026
    --   - Thứ 2 - Thứ 7 | 07:30 - 16:30 (9.0h)
    --   - Giải lao tính công: 09:30-09:40, 15:00-15:10
    --   - Ăn cơm KHÔNG tính công: 11:00-12:00 (60 phút = 1.00h) => Công chuẩn = 8.00h
    -- ---------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM dbo.HR_WorkShifts WHERE ShiftCode = 'SHIFT_PROD_DAY')
    BEGIN
        UPDATE dbo.HR_WorkShifts
        SET ShiftName           = N'Sản Xuất - Hành Chính 1 (07:30 - 16:30)',
            StartTime           = CAST('07:30:00' AS TIME(7)),
            EndTime             = CAST('16:30:00' AS TIME(7)),
            BreakStartTime      = CAST('11:00:00' AS TIME(7)),
            BreakEndTime        = CAST('12:00:00' AS TIME(7)),
            GracePeriodMinutes  = 5,
            TotalWorkHours      = 8.00,
            IsOvernight         = 0,
            Description         = N'[Sản Xuất | T2-T7 | Từ 11/12/2026] Giải lao 09:30-09:40, 15:00-15:10 (tính công); Ăn cơm 11:00-12:00 (không tính công).',
            UseFlag             = 1,
            DivisionType        = N'PRODUCTION',
            WorkDaysPattern     = 'MON-SAT',
            ShortBreakSchedules = N'09:30-09:40, 15:00-15:10',
            IsMealBreakPaid     = 0,
            EffectiveFrom       = '2026-12-11',
            EffectiveTo         = NULL
        WHERE ShiftCode = 'SHIFT_PROD_DAY';
        PRINT N'   -> Đã cập nhật SHIFT_PROD_DAY (Sản Xuất - Hành Chính 1).';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.HR_WorkShifts (
            ShiftCode, ShiftName, StartTime, EndTime, BreakStartTime, BreakEndTime,
            GracePeriodMinutes, TotalWorkHours, IsOvernight, Description, UseFlag, CreatedAt,
            DivisionType, WorkDaysPattern, ShortBreakSchedules, IsMealBreakPaid, EffectiveFrom, EffectiveTo
        )
        VALUES (
            'SHIFT_PROD_DAY', N'Sản Xuất - Hành Chính 1 (07:30 - 16:30)',
            CAST('07:30:00' AS TIME(7)), CAST('16:30:00' AS TIME(7)),
            CAST('11:00:00' AS TIME(7)), CAST('12:00:00' AS TIME(7)),
            5, 8.00, 0,
            N'[Sản Xuất | T2-T7 | Từ 11/12/2026] Giải lao 09:30-09:40, 15:00-15:10 (tính công); Ăn cơm 11:00-12:00 (không tính công).',
            1, GETUTCDATE(),
            N'PRODUCTION', 'MON-SAT', N'09:30-09:40, 15:00-15:10', 0, '2026-12-11', NULL
        );
        PRINT N'   -> Đã thêm mới SHIFT_PROD_DAY (Sản Xuất - Hành Chính 1).';
    END;

    -- ---------------------------------------------------------------------------------
    -- 2.4 KHỐI SẢN XUẤT - CA ĐÊM MỚI (SHIFT_PROD_NIGHT) - ÁP DỤNG TỪ 11/12/2026
    --   - Thứ 2 - Thứ 7 | 20:00 - 04:00 (8.0h qua ngày, IsOvernight = 1)
    --   - Giải lao tính công: 22:00-22:10, 02:10-02:20
    --   - Ăn cơm TÍNH VÀO GIỜ LÀM: 23:30-00:15 (45 phút) => Công chuẩn = 8.00h (IsMealBreakPaid = 1)
    -- ---------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM dbo.HR_WorkShifts WHERE ShiftCode = 'SHIFT_PROD_NIGHT')
    BEGIN
        UPDATE dbo.HR_WorkShifts
        SET ShiftName           = N'Sản Xuất - Ca Đêm (20:00 - 04:00)',
            StartTime           = CAST('20:00:00' AS TIME(7)),
            EndTime             = CAST('04:00:00' AS TIME(7)),
            BreakStartTime      = CAST('23:30:00' AS TIME(7)),
            BreakEndTime        = CAST('00:15:00' AS TIME(7)),
            GracePeriodMinutes  = 5,
            TotalWorkHours      = 8.00,
            IsOvernight         = 1,
            Description         = N'[Sản Xuất | T2-T7 | Từ 11/12/2026] Giải lao 22:00-22:10, 02:10-02:20 (tính công); Ăn cơm 23:30-00:15 (TÍNH vào giờ làm).',
            UseFlag             = 1,
            DivisionType        = N'PRODUCTION',
            WorkDaysPattern     = 'MON-SAT',
            ShortBreakSchedules = N'22:00-22:10, 02:10-02:20',
            IsMealBreakPaid     = 1,
            EffectiveFrom       = '2026-12-11',
            EffectiveTo         = NULL
        WHERE ShiftCode = 'SHIFT_PROD_NIGHT';
        PRINT N'   -> Đã cập nhật SHIFT_PROD_NIGHT (Sản Xuất - Ca Đêm).';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.HR_WorkShifts (
            ShiftCode, ShiftName, StartTime, EndTime, BreakStartTime, BreakEndTime,
            GracePeriodMinutes, TotalWorkHours, IsOvernight, Description, UseFlag, CreatedAt,
            DivisionType, WorkDaysPattern, ShortBreakSchedules, IsMealBreakPaid, EffectiveFrom, EffectiveTo
        )
        VALUES (
            'SHIFT_PROD_NIGHT', N'Sản Xuất - Ca Đêm (20:00 - 04:00)',
            CAST('20:00:00' AS TIME(7)), CAST('04:00:00' AS TIME(7)),
            CAST('23:30:00' AS TIME(7)), CAST('00:15:00' AS TIME(7)),
            5, 8.00, 1,
            N'[Sản Xuất | T2-T7 | Từ 11/12/2026] Giải lao 22:00-22:10, 02:10-02:20 (tính công); Ăn cơm 23:30-00:15 (TÍNH vào giờ làm).',
            1, GETUTCDATE(),
            N'PRODUCTION', 'MON-SAT', N'22:00-22:10, 02:10-02:20', 1, '2026-12-11', NULL
        );
        PRINT N'   -> Đã thêm mới SHIFT_PROD_NIGHT (Sản Xuất - Ca Đêm).';
    END;

    PRINT N'================================================================================';
    PRINT N'=== [BƯỚC 3/3] KHÓA QUYỀN THÊM/SỬA/XÓA MÀN HÌNH 2005_HR_SHIFT_SETUP ===';
    PRINT N'================================================================================';

    -- Thu hồi quyền Create/Update/Delete của tất cả nhóm người dùng trong SYS_AuthorGroupMapping
    -- cho màn hình 2005_HR_SHIFT_SETUP (chỉ cho phép Xem/Tìm kiếm & In).
    -- Lưu ý: Tài khoản Super Admin đặc biệt (ADMIN, SYSTEM, 1200837) vẫn bypass theo HasPermissionAttribute.
    UPDATE agm
    SET agm.IsCreate = 0,
        agm.IsUpdate = 0,
        agm.IsDelete = 0
    FROM dbo.SYS_AuthorGroupMapping agm
    INNER JOIN dbo.SYS_ProgramMenus pm ON agm.ProgramId = pm.ProgramId
    WHERE pm.ProgramKey = '2005_HR_SHIFT_SETUP';

    PRINT N'   -> Đã khóa IsCreate=0, IsUpdate=0, IsDelete=0 cho màn hình 2005_HR_SHIFT_SETUP (' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' nhóm quyền).';

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT CẬP NHẬT DỮ LIỆU CA & PHÂN QUYỀN THÀNH CÔNG! ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT N'LỖI SQL: ' + @ErrMsg;
    RAISERROR(@ErrMsg, 16, 1);
END CATCH;
GO
