-- Reset password for ADMIN to Hansol@12345 (BCrypt Enhanced WorkFactor 11)
UPDATE dbo.SYS_Users 
SET PasswordHash = '$2a$11$UAXU2BskRsWi75e8bb1dCOA44DU2PtcAXqJm8egfu1pyYEwcF3e.2',
    Comment = '0',
    Status = 1,
    MustChangePassword = 0
WHERE UserCode IN ('admin', 'ADMIN');
PRINT N'ADMIN password reset to Hansol@12345 successfully!';

