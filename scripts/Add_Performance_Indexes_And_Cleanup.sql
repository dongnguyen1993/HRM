-- =========================================================================================
-- MIGRATION SCRIPT: TỐI ƯU HÓA CHỈ MỤC (INDEXES) VÀ DỌN DẸP SCHEMA CHO HRM_ENTERPRISE_DB
-- Ngày thực hiện: 15/09/2026 (Giai đoạn 4: Performance & Scaling)
-- =========================================================================================

USE HRM_Enterprise_DB;
GO

PRINT N'>>> BẮT ĐẦU CẬP NHẬT TỐI ƯU HÓA DATABASE SCHEMA...';
GO

-- 1. Bổ sung Index cho bảng MachineRecords (Tối ưu truy vấn nhật ký quẹt thẻ theo thời gian và nhân viên)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_MachineRecords_LogTimestamp_UserCode' AND object_id = OBJECT_ID('dbo.MachineRecords'))
BEGIN
    PRINT N'1. Tạo chỉ mục IX_MachineRecords_LogTimestamp_UserCode trên bảng MachineRecords...';
    CREATE NONCLUSTERED INDEX IX_MachineRecords_LogTimestamp_UserCode
    ON [dbo].[MachineRecords] ([LogTimestamp] DESC, [UserCode] ASC)
    INCLUDE ([DeviceId], [DeviceName], [UserName], [EventDescription], [CreatedAt]);
    PRINT N'   -> Tạo thành công!';
END
ELSE
BEGIN
    PRINT N'1. Chỉ mục IX_MachineRecords_LogTimestamp_UserCode đã tồn tại.';
END
GO

-- 2. Bổ sung Index cho bảng WorkSummary (Tối ưu truy vấn báo cáo và công làm việc theo ngày và nhân viên)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_WorkSummary_WorkDate_UserCode' AND object_id = OBJECT_ID('dbo.WorkSummary'))
BEGIN
    PRINT N'2. Tạo chỉ mục IX_WorkSummary_WorkDate_UserCode trên bảng WorkSummary...';
    CREATE NONCLUSTERED INDEX IX_WorkSummary_WorkDate_UserCode
    ON [dbo].[WorkSummary] ([WorkDate] DESC, [UserCode] ASC)
    INCLUDE ([CheckInTime], [CheckOutTime], [Status], [LateMinutes], [EarlyMinutes], [WorkUnits], [OtHours]);
    PRINT N'   -> Tạo thành công!';
END
ELSE
BEGIN
    PRINT N'2. Chỉ mục IX_WorkSummary_WorkDate_UserCode đã tồn tại.';
END
GO

-- 3. Bổ sung Index cho bảng UserTokens (Tối ưu truy vấn kiểm tra hết hạn và thu hồi Refresh Token)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_UserTokens_ExpiresAt_IsRevoked' AND object_id = OBJECT_ID('dbo.UserTokens'))
BEGIN
    PRINT N'3. Tạo chỉ mục IX_UserTokens_ExpiresAt_IsRevoked trên bảng UserTokens...';
    CREATE NONCLUSTERED INDEX IX_UserTokens_ExpiresAt_IsRevoked
    ON [dbo].[UserTokens] ([ExpiresAt] ASC, [IsRevoked] ASC)
    INCLUDE ([UserId], [RefreshToken]);
    PRINT N'   -> Tạo thành công!';
END
ELSE
BEGIN
    PRINT N'3. Chỉ mục IX_UserTokens_ExpiresAt_IsRevoked đã tồn tại.';
END
GO

-- 4. Bổ sung Index cho bảng AuditLogs (Tối ưu sắp xếp nhật ký thao tác người dùng theo thời gian mới nhất)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditLogs_CreatedAt_Desc' AND object_id = OBJECT_ID('dbo.AuditLogs'))
BEGIN
    PRINT N'4. Tạo chỉ mục IX_AuditLogs_CreatedAt_Desc trên bảng AuditLogs...';
    CREATE NONCLUSTERED INDEX IX_AuditLogs_CreatedAt_Desc
    ON [dbo].[AuditLogs] ([CreatedAt] DESC)
    INCLUDE ([OperatorId], [Action], [TableName], [RecordId], [IpAddress]);
    PRINT N'   -> Tạo thành công!';
END
ELSE
BEGIN
    PRINT N'4. Chỉ mục IX_AuditLogs_CreatedAt_Desc đã tồn tại.';
END
GO

-- 5. Dọn dẹp bảng backup thủ công tạm thời RawDeviceLogs_Backup_1200825
IF OBJECT_ID('dbo.RawDeviceLogs_Backup_1200825', 'U') IS NOT NULL
BEGIN
    PRINT N'5. Xóa bảng backup thủ công tạm thời RawDeviceLogs_Backup_1200825...';
    DROP TABLE [dbo].[RawDeviceLogs_Backup_1200825];
    PRINT N'   -> Đã xóa thành công!';
END
ELSE
BEGIN
    PRINT N'5. Bảng RawDeviceLogs_Backup_1200825 không tồn tại hoặc đã được xóa trước đó.';
END
GO

PRINT N'>>> HOÀN TẤT CẬP NHẬT TỐI ƯU HÓA DATABASE SCHEMA!';
GO
