-- ==============================================================================
-- Script: Reset_All_Users_Password.sql
-- Mục đích: ĐẶT LẠI MẬT KHẨU TẤT CẢ TÀI KHOẢN TRONG SYS_Users VỀ 'Hansol@12345'
--           - Cập nhật chuỗi hash chuẩn BCrypt Enhanced
--           - Reset số lần gõ sai (Comment = '0')
--           - Mở khóa tài khoản (Status = 1: Active)
--           - Bỏ yêu cầu bắt buộc đổi mật khẩu (MustChangePassword = 0)
-- ==============================================================================

SET NOCOUNT ON;

UPDATE dbo.SYS_Users
SET PasswordHash = '$2a$11$UAXU2BskRsWi75e8bb1dCOA44DU2PtcAXqJm8egfu1pyYEwcF3e.2',
    Comment = '0',
    Status = 1,
    MustChangePassword = 0,
    UpdatedAt = GETDATE(),
    UpdatedBy = 'ADMIN_RESET';

DECLARE @TotalUpdated INT = @@ROWCOUNT;
PRINT N'✅ Đã reset thành công mật khẩu của tất cả ' + CAST(@TotalUpdated AS NVARCHAR(10)) + N' tài khoản trong SYS_Users về: Hansol@12345!';

