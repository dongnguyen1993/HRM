-- =========================================================================================
-- Migration: V20261029_03__Move_Device_Setup_To_System_Menu.sql
-- Mô tả: Chuyển màn hình Device Setup (Cấu hình Thiết bị & Cổng Chấm Công - BioStar 2) 
--        vào phân hệ Quản Trị Hệ Thống (1000_SYS)
-- =========================================================================================
SET NOCOUNT ON;

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'=== 1. CẬP NHẬT MÀN HÌNH DEVICE SETUP SANG NHÓM 1000_SYS ===';

    -- Cập nhật menu trong ProgramMenus
    UPDATE [dbo].[ProgramMenus]
    SET [ParentProgramKey] = '1000_SYS',
        [ProgramName] = N'Cấu hình Thiết bị & Cổng Chấm Công',
        [ProgramGroup] = N'SYS',
        [Path] = '/system-mgmt/device-setup',
        [ApiUrl] = '/api/device-setup',
        [Level] = 2,
        [UseFlag] = 1,
        [MenuFlag] = 1,
        [SortOrder] = 100,
        [Icon] = 'hdd',
        [Comment] = N'Cấu hình thiết bị máy chấm công & cổng kiểm soát ra vào BioStar 2',
        [UpdatedAt] = GETDATE(),
        [UpdatedBy] = 'ADMIN'
    WHERE [ProgramKey] = '5070_DEVICE_SETUP' 
       OR [Path] IN ('/hr/device-setup', '/work-hours/device-setup', '/system-mgmt/device-setup');

    PRINT N'=== 2. CẤP QUYỀN MÀN HÌNH CHO ADMINISTRATOR VÀ CÁC NHÓM QUẢN TRỊ HỆ THỐNG ===';

    DECLARE @ProgramId INT = (
        SELECT TOP 1 [ProgramId] FROM [dbo].[ProgramMenus] 
        WHERE [ProgramKey] = '5070_DEVICE_SETUP' OR [Path] = '/system-mgmt/device-setup'
    );

    IF @ProgramId IS NOT NULL
    BEGIN
        -- 2.1 Cấp toàn quyền cho Administrator (GroupId = 1)
        IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 1 AND [ProgramId] = @ProgramId)
        BEGIN
            INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
            VALUES (1, @ProgramId, 1, 1, 1, 1, 1, 1);
        END
        ELSE
        BEGIN
            UPDATE [dbo].[AuthorGroupMapping]
            SET [IsSearch] = 1, [IsCreate] = 1, [IsUpdate] = 1, [IsDelete] = 1, [IsSave] = 1, [IsPrint] = 1
            WHERE [GroupId] = 1 AND [ProgramId] = @ProgramId;
        END

        -- 2.2 Cấp quyền cho các nhóm có quyền quản trị hệ thống (nhóm có quyền ở 1000_SYS)
        DECLARE @SysParentProgramId INT = (SELECT [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '1000_SYS');
        IF @SysParentProgramId IS NOT NULL
        BEGIN
            INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
            SELECT DISTINCT agm.[GroupId], @ProgramId, 1, 1, 1, 1, 1, 1
            FROM [dbo].[AuthorGroupMapping] agm
            WHERE agm.[ProgramId] = @SysParentProgramId AND agm.[IsSearch] = 1
              AND NOT EXISTS (
                  SELECT 1 FROM [dbo].[AuthorGroupMapping] sub WHERE sub.[GroupId] = agm.[GroupId] AND sub.[ProgramId] = @ProgramId
              );
        END

        -- 2.3 Đảm bảo nhóm HR cũng vẫn giữ quyền truy cập để đối soát khi cần
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT ag.[GroupId], @ProgramId, 1, 1, 1, 1, 1, 1
        FROM [dbo].[AuthorGroups] ag
        WHERE (ag.[GroupId] = 3002 OR ag.[GroupName] LIKE '%HR%' OR ag.[GroupName] LIKE N'%Nhân Sự%')
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[AuthorGroupMapping] agm WHERE agm.[GroupId] = ag.[GroupId] AND agm.[ProgramId] = @ProgramId
          );
    END

    COMMIT TRANSACTION;
    PRINT N'✅ Đã chuyển thành công màn hình Device Setup vào phân hệ Quản Trị Hệ Thống (1000_SYS)!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

