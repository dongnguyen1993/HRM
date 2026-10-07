-- ==============================================================================
-- Migration Script: V20261007_02__Periodic_Password_Rotation_Procedure.sql
-- Mục đích: Thủ tục lưu trữ (Stored Procedure) kích hoạt đổi mật khẩu định kỳ
--           vào các mốc ngày 30 của tháng 4, 8, 12 cho toàn bộ User (trừ admin).
-- Ngày tạo: 2026-10-07
-- ==============================================================================

USE [HRM_Enterprise_DB];
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_EnforcePeriodicPasswordRotation]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentDate DATETIME = GETUTCDATE();
    DECLARE @Year INT = YEAR(@CurrentDate);

    DECLARE @Apr30 DATETIME = DATEFROMPARTS(@Year, 4, 30);
    DECLARE @Aug30 DATETIME = DATEFROMPARTS(@Year, 8, 30);
    DECLARE @Dec30 DATETIME = DATEFROMPARTS(@Year, 12, 30);

    -- Xác định mốc đổi mật khẩu định kỳ gần nhất đã xảy ra
    DECLARE @MilestoneDate DATETIME;
    IF @CurrentDate >= @Dec30
        SET @MilestoneDate = @Dec30;
    ELSE IF @CurrentDate >= @Aug30
        SET @MilestoneDate = @Aug30;
    ELSE IF @CurrentDate >= @Apr30
        SET @MilestoneDate = @Apr30;
    ELSE
        SET @MilestoneDate = DATEFROMPARTS(@Year - 1, 12, 30);

    -- Cập nhật cờ MustChangePassword = 1 cho tất cả các tài khoản
    -- có thời điểm đổi mật khẩu lần cuối trước mốc định kỳ (ngoại trừ tài khoản admin)
    UPDATE Users
    SET MustChangePassword = 1,
        UpdatedAt = GETDATE(),
        UpdatedBy = 'SYSTEM_ROTATION'
    WHERE UPPER(UserCode) <> 'ADMIN'
      AND MustChangePassword = 0
      AND (
          COALESCE(UpdatedAt, CreatedAt) < @MilestoneDate
      );

    DECLARE @Count INT = @@ROWCOUNT;
    PRINT N'Đã kích hoạt MustChangePassword = 1 cho ' + CAST(@Count AS NVARCHAR(10)) + N' tài khoản theo mốc: ' + CONVERT(NVARCHAR(20), @MilestoneDate, 103);
    
    SELECT @Count AS UsersFlaggedForPasswordChange, @MilestoneDate AS MilestoneDateApplied;
END;
GO
