-- ==============================================================================
-- Script: delete_outdated_positions.sql
-- Mục đích: Xóa sạch các dữ liệu cũ không đúng (L7, L8, L9) trong dbo.HR_Positions
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Đảm bảo không có User nào đang trỏ vào các Id này
UPDATE dbo.SYS_Users
SET PositionId = 1
WHERE PositionId IN (7, 8, 9) OR PositionId NOT IN (SELECT PositionId FROM dbo.HR_Positions WHERE UseFlag = 1);

-- 2. Xóa các bản ghi cũ không hợp lệ
DELETE FROM dbo.HR_Positions
WHERE PositionId IN (7, 8, 9) 
   OR PositionCode LIKE 'L[0-9]%'
   OR PositionType IS NULL
   OR UseFlag = 0;

PRINT N'Đã xóa sạch các bản ghi không đúng trong dbo.HR_Positions!';
GO
