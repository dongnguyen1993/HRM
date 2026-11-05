-- ==============================================================================
-- Migration Script: Reset_SYS_ProgramMenus_Identity_1_To_31.sql
-- Mục đích: RESET TOÀN BỘ ProgramId CỦA SYS_ProgramMenus VỀ TUẦN TỰ TỪ 1 ĐẾN 31
--           1. Khắc phục triệt để hiện tượng ProgramId bị nhảy số (lên đến 14013)
--           2. Sắp xếp ProgramId tuần tự 1..31 theo đúng thứ tự 4 Domain (ESS, HR, GA, SYS)
--           3. Chuẩn hóa SortOrder theo đúng mã 4 chữ số (1000..1005, 2000..2010, 3000..3003, 4000..4009)
--           4. Đồng bộ và bảo toàn 100% dữ liệu phân quyền trong SYS_AuthorGroupMapping
--           5. Thiết lập DBCC CHECKIDENT về 31 để bản ghi mới sinh ra từ 32
-- ==============================================================================

SET NOCOUNT ON;
BEGIN TRANSACTION;

BEGIN TRY
    PRINT N'=== 1. SAO LƯU DỮ LIỆU PHÂN QUYỀN VÀ MENU HIỆN TẠI VÀO BẢNG TẠM ===';

    -- 1.1. Lưu toàn bộ phân quyền hiện tại ánh xạ theo ProgramKey duy nhất
    IF OBJECT_ID('tempdb..#PermBackup') IS NOT NULL DROP TABLE #PermBackup;
    SELECT 
        agm.GroupId,
        pm.ProgramKey,
        agm.IsSearch,
        agm.IsCreate,
        agm.IsUpdate,
        agm.IsDelete,
        agm.IsSave,
        agm.IsPrint
    INTO #PermBackup
    FROM dbo.SYS_AuthorGroupMapping agm
    INNER JOIN dbo.SYS_ProgramMenus pm ON agm.ProgramId = pm.ProgramId;

    DECLARE @PermCount INT = (SELECT COUNT(*) FROM #PermBackup);
    PRINT N'   [BACKUP] Đã sao lưu ' + CAST(@PermCount AS NVARCHAR(10)) + N' bản ghi phân quyền từ SYS_AuthorGroupMapping.';

    -- 1.2. Tạo danh sách 31 menu chuẩn và đánh số NewProgramId từ 1 đến 31
    IF OBJECT_ID('tempdb..#MenuBackup') IS NOT NULL DROP TABLE #MenuBackup;
    SELECT 
        ROW_NUMBER() OVER (ORDER BY 
            CASE 
                WHEN ProgramKey LIKE '1000%' THEN 1000
                WHEN ProgramKey LIKE '1001%' THEN 1001
                WHEN ProgramKey LIKE '1002%' THEN 1002
                WHEN ProgramKey LIKE '1003%' THEN 1003
                WHEN ProgramKey LIKE '1004%' THEN 1004
                WHEN ProgramKey LIKE '1005%' THEN 1005
                WHEN ProgramKey LIKE '2000%' THEN 2000
                WHEN ProgramKey LIKE '2001%' THEN 2001
                WHEN ProgramKey LIKE '2002%' THEN 2002
                WHEN ProgramKey LIKE '2003%' THEN 2003
                WHEN ProgramKey LIKE '2004%' THEN 2004
                WHEN ProgramKey LIKE '2005%' THEN 2005
                WHEN ProgramKey LIKE '2006%' THEN 2006
                WHEN ProgramKey LIKE '2007%' THEN 2007
                WHEN ProgramKey LIKE '2008%' THEN 2008
                WHEN ProgramKey LIKE '2009%' THEN 2009
                WHEN ProgramKey LIKE '2010%' THEN 2010
                WHEN ProgramKey LIKE '3000%' THEN 3000
                WHEN ProgramKey LIKE '3001%' THEN 3001
                WHEN ProgramKey LIKE '3002%' THEN 3002
                WHEN ProgramKey LIKE '3003%' THEN 3003
                WHEN ProgramKey LIKE '4000%' THEN 4000
                WHEN ProgramKey LIKE '4001%' THEN 4001
                WHEN ProgramKey LIKE '4002%' THEN 4002
                WHEN ProgramKey LIKE '4003%' THEN 4003
                WHEN ProgramKey LIKE '4004%' THEN 4004
                WHEN ProgramKey LIKE '4005%' THEN 4005
                WHEN ProgramKey LIKE '4006%' THEN 4006
                WHEN ProgramKey LIKE '4007%' THEN 4007
                WHEN ProgramKey LIKE '4008%' THEN 4008
                WHEN ProgramKey LIKE '4009%' THEN 4009
                ELSE 9999
            END
        ) AS NewProgramId,
        ProgramKey, 
        ProgramName, 
        Level, 
        ParentProgramKey, 
        ProgramGroup,
        UseFlag, 
        MenuFlag, 
        NameSpace, 
        ClassName, 
        AssemblyName, 
        CASE 
            WHEN ProgramKey LIKE '1000%' THEN 1000
            WHEN ProgramKey LIKE '1001%' THEN 1001
            WHEN ProgramKey LIKE '1002%' THEN 1002
            WHEN ProgramKey LIKE '1003%' THEN 1003
            WHEN ProgramKey LIKE '1004%' THEN 1004
            WHEN ProgramKey LIKE '1005%' THEN 1005
            WHEN ProgramKey LIKE '2000%' THEN 2000
            WHEN ProgramKey LIKE '2001%' THEN 2001
            WHEN ProgramKey LIKE '2002%' THEN 2002
            WHEN ProgramKey LIKE '2003%' THEN 2003
            WHEN ProgramKey LIKE '2004%' THEN 2004
            WHEN ProgramKey LIKE '2005%' THEN 2005
            WHEN ProgramKey LIKE '2006%' THEN 2006
            WHEN ProgramKey LIKE '2007%' THEN 2007
            WHEN ProgramKey LIKE '2008%' THEN 2008
            WHEN ProgramKey LIKE '2009%' THEN 2009
            WHEN ProgramKey LIKE '2010%' THEN 2010
            WHEN ProgramKey LIKE '3000%' THEN 3000
            WHEN ProgramKey LIKE '3001%' THEN 3001
            WHEN ProgramKey LIKE '3002%' THEN 3002
            WHEN ProgramKey LIKE '3003%' THEN 3003
            WHEN ProgramKey LIKE '4000%' THEN 4000
            WHEN ProgramKey LIKE '4001%' THEN 4001
            WHEN ProgramKey LIKE '4002%' THEN 4002
            WHEN ProgramKey LIKE '4003%' THEN 4003
            WHEN ProgramKey LIKE '4004%' THEN 4004
            WHEN ProgramKey LIKE '4005%' THEN 4005
            WHEN ProgramKey LIKE '4006%' THEN 4006
            WHEN ProgramKey LIKE '4007%' THEN 4007
            WHEN ProgramKey LIKE '4008%' THEN 4008
            WHEN ProgramKey LIKE '4009%' THEN 4009
            ELSE SortOrder
        END AS NewSortOrder,
        Comment, 
        CreatedAt, 
        CreatedBy, 
        GETDATE() AS UpdatedAt, 
        'SYSTEM_RESET' AS UpdatedBy, 
        Path, 
        ApiUrl, 
        Icon
    INTO #MenuBackup
    FROM dbo.SYS_ProgramMenus;

    DECLARE @MenuCount INT = (SELECT COUNT(*) FROM #MenuBackup);
    PRINT N'   [BACKUP] Đã chuẩn bị ' + CAST(@MenuCount AS NVARCHAR(10)) + N' menu để gán lại ProgramId từ 1 đến ' + CAST(@MenuCount AS NVARCHAR(10)) + N'.';

    PRINT N'=== 2. XÓA DỮ LIỆU CŨ THEO THỨ TỰ CHA - CON ===';
    
    -- Xóa bảng con trước để không vi phạm FK
    DELETE FROM dbo.SYS_AuthorGroupMapping;
    PRINT N'   [DELETE] Đã làm trống bảng phân quyền SYS_AuthorGroupMapping.';

    -- Xóa bảng cha
    DELETE FROM dbo.SYS_ProgramMenus;
    PRINT N'   [DELETE] Đã làm trống bảng menu SYS_ProgramMenus.';

    -- Reset Identity về 0
    DBCC CHECKIDENT ('dbo.SYS_ProgramMenus', RESEED, 0);
    PRINT N'   [RESEED] Đã reset Identity của SYS_ProgramMenus về 0.';

    PRINT N'=== 3. CHÈN LẠI MENU VỚI PROGRAMID TUẦN TỰ TỪ 1 ĐẾN 31 ===';
    
    SET IDENTITY_INSERT dbo.SYS_ProgramMenus ON;

    INSERT INTO dbo.SYS_ProgramMenus (
        ProgramId, ProgramKey, ProgramName, Level, ParentProgramKey, ProgramGroup,
        UseFlag, MenuFlag, NameSpace, ClassName, AssemblyName, SortOrder,
        Comment, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, Path, ApiUrl, Icon
    )
    SELECT 
        NewProgramId, ProgramKey, ProgramName, Level, ParentProgramKey, ProgramGroup,
        UseFlag, MenuFlag, NameSpace, ClassName, AssemblyName, NewSortOrder,
        Comment, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, Path, ApiUrl, Icon
    FROM #MenuBackup
    ORDER BY NewProgramId;

    SET IDENTITY_INSERT dbo.SYS_ProgramMenus OFF;
    PRINT N'   [INSERT] Đã chèn 31 menu với ProgramId từ 1 đến 31 thành công.';

    -- Đặt Identity kế tiếp bắt đầu từ 31 (bản ghi tiếp theo sẽ là 32)
    DBCC CHECKIDENT ('dbo.SYS_ProgramMenus', RESEED, @MenuCount);
    PRINT N'   [RESEED] Đã đặt Identity của SYS_ProgramMenus ở mốc ' + CAST(@MenuCount AS NVARCHAR(10)) + N'.';

    PRINT N'=== 4. PHỤC HỒI DỮ LIỆU PHÂN QUYỀN KHỚP VỚI PROGRAMID MỚI ===';
    
    INSERT INTO dbo.SYS_AuthorGroupMapping (
        GroupId, ProgramId, IsSearch, IsCreate, IsUpdate, IsDelete, IsSave, IsPrint
    )
    SELECT 
        pb.GroupId,
        pm.ProgramId,
        pb.IsSearch,
        pb.IsCreate,
        pb.IsUpdate,
        pb.IsDelete,
        pb.IsSave,
        pb.IsPrint
    FROM #PermBackup pb
    INNER JOIN dbo.SYS_ProgramMenus pm ON pb.ProgramKey = pm.ProgramKey;

    DECLARE @NewPermCount INT = (SELECT COUNT(*) FROM dbo.SYS_AuthorGroupMapping);
    PRINT N'   [RESTORE] Đã phục hồi ' + CAST(@NewPermCount AS NVARCHAR(10)) + N' bản ghi phân quyền khớp 100% với ProgramId mới!';

    PRINT N'=== 5. KIỂM TRA ĐỐI SOÁT TÍNH TOÀN VẸN ===';
    IF @NewPermCount <> @PermCount
    BEGIN
        RAISERROR(N'[LỖI] Số lượng phân quyền phục hồi (%d) không khớp ban đầu (%d)! Đang Rollback...', 16, 1, @NewPermCount, @PermCount);
    END

    IF @MenuCount <> 31
    BEGIN
        RAISERROR(N'[LỖI] Số lượng menu phục hồi (%d) khác 31! Đang Rollback...', 16, 1, @MenuCount);
    END

    COMMIT TRANSACTION;
    PRINT N'=== HOÀN TẤT RESET PROGRAMID THÀNH CÔNG RỰC RỠ! (ProgramId: 1 -> 31) ===';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    PRINT N'[ERROR] ' + @ErrMsg;
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;

