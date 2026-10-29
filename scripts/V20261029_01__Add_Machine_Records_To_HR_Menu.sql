-- =========================================================================================
-- Migration: V20261029_01__Add_Machine_Records_To_HR_Menu.sql
-- Mô tả: Mở màn hình "Dữ liệu máy chấm công" và đưa vào phân hệ Quản Trị Nhân Sự (2000_HR)
-- =========================================================================================
SET NOCOUNT ON;

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'=== 1. CẬP NHẬT / THÊM MỚI MENU DỮ LIỆU MÁY CHẤM CÔNG VÀO 2000_HR ===';

    DECLARE @ProgramId INT = NULL;

    -- Kiểm tra xem menu 5030_MACHINE_RECORDS hoặc path /work-hours/machine-records đã tồn tại chưa
    SELECT @ProgramId = [ProgramId]
    FROM [dbo].[ProgramMenus]
    WHERE [ProgramKey] IN ('5030_MACHINE_RECORDS', 'MACHINE_RECORDS', '2005_MACHINE_RECORDS')
       OR [Path] IN ('/hr/machine-records', '/work-hours/machine-records');

    IF @ProgramId IS NOT NULL
    BEGIN
        UPDATE [dbo].[ProgramMenus]
        SET [ProgramKey] = '5030_MACHINE_RECORDS',
            [ParentProgramKey] = '2000_HR',
            [ProgramName] = N'Dữ liệu máy chấm công',
            [ProgramGroup] = N'HR',
            [Path] = '/hr/machine-records',
            [ApiUrl] = '/api/machine-records',
            [Level] = 2,
            [UseFlag] = 1,
            [MenuFlag] = 1,
            [SortOrder] = 5,
            [Icon] = 'field-time',
            [Comment] = N'Màn hình quản lý dữ liệu máy chấm công (BioStar 2)',
            [UpdatedAt] = GETDATE(),
            [UpdatedBy] = 'ADMIN'
        WHERE [ProgramId] = @ProgramId;

        PRINT N'-> Đã cập nhật thành công menu Dữ liệu máy chấm công (ProgramId = ' + CAST(@ProgramId AS NVARCHAR(10)) + N') vào nhóm 2000_HR.';
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[ProgramMenus] (
            [ProgramKey], [ParentProgramKey], [ProgramName], [ProgramGroup], [Path], [ApiUrl],
            [Level], [UseFlag], [MenuFlag], [SortOrder], [Comment], [Icon], [CreatedAt], [CreatedBy]
        )
        VALUES (
            '5030_MACHINE_RECORDS', '2000_HR', N'Dữ liệu máy chấm công', N'HR', '/hr/machine-records', '/api/machine-records',
            2, 1, 1, 5, N'Màn hình quản lý dữ liệu máy chấm công (BioStar 2)', 'field-time', GETDATE(), 'ADMIN'
        );

        SET @ProgramId = SCOPE_IDENTITY();
        PRINT N'-> Đã thêm mới menu Dữ liệu máy chấm công (ProgramId = ' + CAST(@ProgramId AS NVARCHAR(10)) + N') vào nhóm 2000_HR.';
    END

    PRINT N'=== 2. CẤP QUYỀN MÀN HÌNH CHO ADMINISTRATOR VÀ HR_OFFICER ===';

    -- 2.1 Cấp toàn quyền cho nhóm Administrator (GroupId = 1)
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AuthorGroupMapping] WHERE [GroupId] = 1 AND [ProgramId] = @ProgramId)
    BEGIN
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        VALUES (1, @ProgramId, 1, 1, 1, 1, 1, 1);
        PRINT N'-> Đã cấp quyền cho nhóm Administrator';
    END
    ELSE
    BEGIN
        UPDATE [dbo].[AuthorGroupMapping]
        SET [IsSearch] = 1, [IsCreate] = 1, [IsUpdate] = 1, [IsDelete] = 1, [IsSave] = 1, [IsPrint] = 1
        WHERE [GroupId] = 1 AND [ProgramId] = @ProgramId;
    END

    -- 2.2 Cấp toàn quyền cho các nhóm Quản trị Nhân sự (HR_OFFICER)
    INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
    SELECT ag.[GroupId], @ProgramId, 1, 1, 1, 1, 1, 1
    FROM [dbo].[AuthorGroups] ag
    WHERE (ag.[GroupId] = 3002 OR ag.[GroupName] LIKE '%HR%' OR ag.[GroupName] LIKE N'%Nhân Sự%')
      AND NOT EXISTS (
          SELECT 1 FROM [dbo].[AuthorGroupMapping] agm 
          WHERE agm.[GroupId] = ag.[GroupId] AND agm.[ProgramId] = @ProgramId
      );

    -- 2.3 Cấp quyền cho bất kỳ nhóm nào đang có quyền xem nhóm cha 2000_HR
    DECLARE @ParentProgramId INT = (SELECT [ProgramId] FROM [dbo].[ProgramMenus] WHERE [ProgramKey] = '2000_HR');
    IF @ParentProgramId IS NOT NULL
    BEGIN
        INSERT INTO [dbo].[AuthorGroupMapping] ([GroupId], [ProgramId], [IsSearch], [IsCreate], [IsUpdate], [IsDelete], [IsSave], [IsPrint])
        SELECT DISTINCT agm.[GroupId], @ProgramId, 1, 1, 1, 1, 1, 1
        FROM [dbo].[AuthorGroupMapping] agm
        WHERE agm.[ProgramId] = @ParentProgramId AND agm.[IsSearch] = 1
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[AuthorGroupMapping] sub 
              WHERE sub.[GroupId] = agm.[GroupId] AND sub.[ProgramId] = @ProgramId
          );
    END

    COMMIT TRANSACTION;
    PRINT N'✅ Đã mở màn hình Dữ liệu máy chấm công và phân quyền vào mục Quản Trị Nhân Sự thành công!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH;

