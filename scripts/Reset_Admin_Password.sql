-- Reset password for ADMIN to Hansol@12345
UPDATE dbo.SYS_Users 
SET PasswordHash = '$2a$11$lSvR6ZvCc72Hhk0lxw63uudbJN1VoEdw7SBsB/xmmKt9SWcBlzXlK',
    Comment = '0',
    Status = 1
WHERE UserCode = 'ADMIN';
PRINT N'ADMIN password reset to Hansol@12345 successfully!';

