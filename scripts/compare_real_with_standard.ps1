param(
    [string]$standardAnalysisPath = "d:\HRM\scripts\HRM_TEST_DB_ANALYSIS.json",
    [string]$diffReportPath = "d:\HRM\scripts\REAL_VS_STANDARD_DIFF_REPORT.md",
    [string]$supplementSqlPath = "d:\HRM\scripts\V20261123_SUPPLEMENT_FOR_DB_REAL.sql"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "         SO SÁNH DB REAL (VỪA ĐỒNG BỘ QUA) VỚI DB TEST CHUẨN HÓA          " -ForegroundColor Cyan
Write-Host "==========================================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $standardAnalysisPath)) {
    Write-Error "Không tìm thấy file snapshot chuẩn: $standardAnalysisPath"
    exit 1
}

$standard = Get-Content $standardAnalysisPath -Raw -Encoding UTF8 | ConvertFrom-Json

$server = "172.26.75.23,1433"
$database = "HRM_TEST_DB"
$user = "HRM_DEV"
$password = "Hansol@test12345"
$connStr = "Server=$server;Database=$database;User Id=$user;Password=$password;TrustServerCertificate=True;MultipleActiveResultSets=True;"

$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
try {
    $conn.Open()
} catch {
    Write-Error "Không thể kết nối đến SQL Server: $($_.Exception.Message)"
    exit 1
}

# 1. LIVE TABLES (DB REAL VỪA ĐÈ VÀO)
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS [RowCount]
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
ORDER BY s.name, t.name
"@
$reader = $cmd.ExecuteReader()
$liveTables = @{}
$liveTableRows = @{}
while ($reader.Read()) {
    $t = [string]$reader['TableName']
    $rc = [int64]$reader['RowCount']
    $liveTables[$t] = $true
    $liveTableRows[$t] = $rc
}
$reader.Close()

# 2. LIVE COLUMNS
$cmd.CommandText = @"
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    COLUMN_DEFAULT,
    IS_NULLABLE,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION
"@
$reader = $cmd.ExecuteReader()
$liveColumns = @{}
$liveColumnsByTable = @{}
while ($reader.Read()) {
    $t = [string]$reader['TABLE_NAME']
    $c = [string]$reader['COLUMN_NAME']
    $key = "$t.$c"
    $colInfo = [ordered]@{
        Table = $t
        Column = $c
        DataType = [string]$reader['DATA_TYPE']
        Nullable = [string]$reader['IS_NULLABLE']
        MaxLength = if ($reader.IsDBNull($reader.GetOrdinal('CHARACTER_MAXIMUM_LENGTH'))) { $null } else { [int]$reader['CHARACTER_MAXIMUM_LENGTH'] }
        Default = if ($reader.IsDBNull($reader.GetOrdinal('COLUMN_DEFAULT'))) { $null } else { [string]$reader['COLUMN_DEFAULT'] }
    }
    $liveColumns[$key] = $colInfo
    if (-not $liveColumnsByTable.ContainsKey($t)) { $liveColumnsByTable[$t] = @() }
    $liveColumnsByTable[$t] += $colInfo
}
$reader.Close()

# 3. LIVE ROUTINES & VIEWS
$cmd.CommandText = @"
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME NOT LIKE 'fn_%' AND ROUTINE_NAME NOT LIKE 'sp_%diagram%'
ORDER BY ROUTINE_NAME
"@
$reader = $cmd.ExecuteReader()
$liveRoutines = @()
while ($reader.Read()) {
    $liveRoutines += [string]$reader['ROUTINE_NAME']
}
$reader.Close()

$cmd.CommandText = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS ORDER BY TABLE_NAME"
$reader = $cmd.ExecuteReader()
$liveViews = @()
while ($reader.Read()) {
    $liveViews += [string]$reader['TABLE_NAME']
}
$reader.Close()

# 4. LIVE MENUS
$cmd.CommandText = @"
SELECT ProgramId, ProgramKey, ProgramName, ProgramGroup, UseFlag, MenuFlag, SortOrder, Path, ApiUrl
FROM dbo.SYS_ProgramMenus
ORDER BY SortOrder, ProgramId
"@
$liveMenus = @()
try {
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $liveMenus += [ordered]@{
            ProgramId = [int]$reader['ProgramId']
            ProgramKey = [string]$reader['ProgramKey']
            ProgramName = [string]$reader['ProgramName']
            ProgramGroup = [string]$reader['ProgramGroup']
            SortOrder = [int]$reader['SortOrder']
            Path = if ($reader.IsDBNull($reader.GetOrdinal('Path'))) { "" } else { [string]$reader['Path'] }
        }
    }
    $reader.Close()
} catch {
    Write-Warning "Lỗi đọc bảng SYS_ProgramMenus: $_"
}

# 5. LIVE USERS (Trừ Password)
$cmd.CommandText = @"
SELECT UserId, UserCode, FullName, Email, Status, UseFlag
FROM dbo.SYS_Users
ORDER BY UserId
"@
$liveUsers = @()
try {
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $liveUsers += [ordered]@{
            UserId = [int]$reader['UserId']
            UserCode = [string]$reader['UserCode']
            FullName = if ($reader.IsDBNull($reader.GetOrdinal('FullName'))) { "" } else { [string]$reader['FullName'] }
            Email = if ($reader.IsDBNull($reader.GetOrdinal('Email'))) { "" } else { [string]$reader['Email'] }
            Status = [int]$reader['Status']
        }
    }
    $reader.Close()
} catch {
    Write-Warning "Lỗi đọc SYS_Users: $_"
}

$conn.Close()

Write-Host "Live DB Tables count: $($liveTables.Count)" -ForegroundColor Green
Write-Host "Standard Snapshot Tables count: $($standard.TotalTables)" -ForegroundColor Green

# SO SÁNH
$missingTables = @()
$extraTables = @()
foreach ($st in $standard.Tables) {
    if (-not $liveTables.ContainsKey($st.Table)) {
        $missingTables += $st.Table
    }
}
foreach ($lt in $liveTables.Keys) {
    $found = $false
    foreach ($st in $standard.Tables) {
        if ($st.Table -eq $lt) { $found = $true; break }
    }
    if (-not $found) {
        $extraTables += $lt
    }
}

# CỘT QUYỀN TRONG SYS_AuthorGroupMapping
$hasIsUpdate = $liveColumns.ContainsKey("SYS_AuthorGroupMapping.IsUpdate")
$hasIsSave = $liveColumns.ContainsKey("SYS_AuthorGroupMapping.IsSave")

# CỘT TRONG SYS_Users
$hasIdentityNumberInUsers = $liveColumns.ContainsKey("SYS_Users.IdentityNumber")
$hasBirthDateInUsers = $liveColumns.ContainsKey("SYS_Users.BirthDate")

# BẢNG HR_Employees
$hasHrEmployees = $liveTables.ContainsKey("HR_Employees")
$hasVwHrEmployees = $liveViews -contains "VW_HR_Employees"

# SO SÁNH MENUS
$missingMenus = @()
$liveMenuKeys = $liveMenus | ForEach-Object { $_.ProgramKey }
foreach ($sm in $standard.Menus) {
    if ($liveMenuKeys -notcontains $sm.ProgramKey) {
        $missingMenus += $sm
    }
}

# SO SÁNH DÒNG
$rowDiffs = @()
foreach ($st in $standard.Tables) {
    $tableName = $st.Table
    $stdRows = $st.Rows
    $liveRows = if ($liveTableRows.ContainsKey($tableName)) { $liveTableRows[$tableName] } else { -1 }
    $diff = $liveRows - $stdRows
    $rowDiffs += [ordered]@{
        Table = $tableName
        LiveRows = $liveRows
        StandardRows = $stdRows
        Diff = $diff
    }
}

# TẠO BÁO CÁO MARKDOWN
$report = @"
# BÁO CÁO ĐỐI SOÁT CHI TIẾT: DB REAL (MỚI ĐỒNG BỘ) VS DB TEST CHUẨN HÓA
- **Thời gian phân tích:** $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
- **Server:** $server | Database: $database

---

## 1. ĐÁNH GIÁ CÁC ĐIỂM CỐT TỬ ẢNH HƯỞNG ĐẾN CODE DEPLOYMENT

| Hạng mục kiểm tra | Trạng thái trên DB Real hiện tại | Chuẩn Code Backend/Frontend | Mức độ nghiêm trọng | Hành động cần thiết |
| :--- | :---: | :---: | :---: | :--- |
| **Cột [IsUpdate] trong SYS_AuthorGroupMapping** | $(if ($hasIsUpdate) { "✅ ĐÃ CÓ" } else { "❌ CHƯA CÓ (THIẾU)" }) | Bắt buộc có | **NGHIÊM TRỌNG (500)** | $(if ($hasIsUpdate) { "Đã chuẩn hóa." } else { "Bổ sung cột IsUpdate ngay." }) |
| **Cột cũ [IsSave] trong SYS_AuthorGroupMapping** | $(if ($hasIsSave) { "⚠️ CÒN TỒN TẠI" } else { "✅ ĐÃ XÓA SẠCH" }) | Bắt buộc xóa | **CẢNH BÁO** | $(if ($hasIsSave) { "Chuyển dữ liệu sang IsUpdate và drop cột IsSave." } else { "Đã sạch." }) |
| **Bảng [HR_Employees] (Hồ sơ Nhân viên)** | $(if ($hasHrEmployees) { "✅ ĐÃ TỒN TẠI ($($liveTableRows['HR_Employees']) dòng)" } else { "❌ CHƯA CÓ (THIẾU)" }) | Bắt buộc có | **NGHIÊM TRỌNG (500)** | $(if ($hasHrEmployees) { "Đã chuẩn." } else { "Tạo bảng và chuyển dữ liệu từ SYS_Users sang." }) |
| **View [dbo.VW_HR_Employees]** | $(if ($hasVwHrEmployees) { "✅ ĐÃ CÓ" } else { "❌ CHƯA CÓ (THIẾU)" }) | Bắt buộc có | **NGHIÊM TRỌNG (500)** | $(if ($hasVwHrEmployees) { "Đã chuẩn." } else { "Tạo view VW_HR_Employees." }) |
| **29 cột nhân sự cũ trong [SYS_Users]** | $(if ($hasIdentityNumberInUsers) { "⚠️ VẪN CÒN (Chưa dọn)" } else { "✅ ĐÃ DỌN SẠCH" }) | Tách sang HR_Employees | **CẢNH BÁO KIẾN TRÚC** | $(if ($hasIdentityNumberInUsers) { "Đồng bộ sang HR_Employees rồi dọn sạch." } else { "Đã chuẩn 16 cột tài khoản." }) |
| **Số lượng Menu chương trình (SYS_ProgramMenus)** | **$($liveMenus.Count) Menus** | **$($standard.TotalMenus) Menus** | **TRUNG BÌNH (404/403)** | $(if ($missingMenus.Count -gt 0) { "Cần bổ sung $($missingMenus.Count) menu thiếu." } else { "Đã đủ $($standard.TotalMenus) menu." }) |

---

## 2. BẢNG DỮ LIỆU (TABLES DIFF)
- **Tổng số bảng trên DB Real:** $($liveTables.Count)
- **Tổng số bảng trên DB Test Chuẩn:** $($standard.TotalTables)

$(if ($missingTables.Count -gt 0) {
"### ❌ Các bảng THIẾU trên DB Real (cần bổ sung):`n" + ($missingTables | ForEach-Object { "- **$_**" } | Out-String)
} else {
"### ✅ Không có bảng nào bị thiếu so với DB Test Chuẩn."
})

$(if ($extraTables.Count -gt 0) {
"### ℹ️ Các bảng THỪA / MỚI trên DB Real:`n" + ($extraTables | ForEach-Object { "- **$_**" } | Out-String)
} else {
"### ✅ Không có bảng thừa."
})

---

## 3. MENU CHƯƠNG TRÌNH THIẾU (SYS_ProgramMenus DIFF)
$(if ($missingMenus.Count -gt 0) {
"| ProgramKey | Tên Menu | Nhóm | SortOrder | Path |`n| :--- | :--- | :---: | :---: | :--- |`n" +
(($missingMenus | ForEach-Object { "| **$($_.ProgramKey)** | $($_.ProgramName) | $($_.ProgramGroup) | $($_.SortOrder) | $($_.Path) |" }) -join "`n")
} else {
"✅ Toàn bộ $($standard.TotalMenus) Menu chương trình đồng nhất 100% giữa 2 DB."
})

---

## 4. ĐỐI SOÁT SỐ LƯỢNG BẢN GHI (ROW COUNT DIFF)
| Tên Bảng | DB Real (Vừa đồng bộ) | DB Test Chuẩn | Chênh lệch (Real - Test) |
| :--- | :---: | :---: | :---: |
$($rowDiffs | ForEach-Object {
    $diffStr = if ($_.Diff -gt 0) { "+$($_.Diff)" } elseif ($_.Diff -lt 0) { "$($_.Diff)" } else { "0 (Đồng nhất)" }
    "| $($_.Table) | $($_.LiveRows) | $($_.StandardRows) | $diffStr |"
} | Out-String)

"@

$report | Set-Content $diffReportPath -Encoding UTF8
Write-Host "Báo cáo phân tích đã ghi tại: $diffReportPath" -ForegroundColor Green
