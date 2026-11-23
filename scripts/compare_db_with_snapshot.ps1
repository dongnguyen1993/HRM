param(
    [string]$snapshotPath = "d:\HRM\scripts\DB_SNAPSHOT_BEFORE_OVERWRITE.json",
    [string]$outputPath = "d:\HRM\scripts\DB_DIFF_REPORT.md"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "         HRM ENTERPRISE - DATABASE DIFFERENCE ANALYZER                    " -ForegroundColor Cyan
Write-Host "   COMPARING LIVE HRM_TEST_DB (AFTER OVERWRITE) VS SNAPSHOT (BEFORE)      " -ForegroundColor Cyan
Write-Host "==========================================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $snapshotPath)) {
    Write-Error "Snapshot file not found: $snapshotPath"
    exit 1
}

$snapshot = Get-Content $snapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json

$server = "172.26.75.23,1433"
$database = "HRM_TEST_DB"
$user = "HRM_DEV"
$password = "Hansol@test12345"
$connStr = "Server=$server;Database=$database;User Id=$user;Password=$password;TrustServerCertificate=True;MultipleActiveResultSets=True;"

Write-Host "Connecting to live $database on $server..." -ForegroundColor Cyan
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

# 1. LIVE TABLES
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    t.TABLE_SCHEMA,
    t.TABLE_NAME,
    p.rows AS [RowCount]
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN sys.tables st ON t.TABLE_NAME = st.name
INNER JOIN sys.partitions p ON st.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME
"@
$reader = $cmd.ExecuteReader()
$liveTables = @{}
$liveTableList = @()
while ($reader.Read()) {
    $t = [string]$reader['TABLE_NAME']
    $rc = [int64]$reader['RowCount']
    $liveTables[$t] = $rc
    $liveTableList += $t
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
while ($reader.Read()) {
    $key = $reader['TABLE_NAME'] + '.' + $reader['COLUMN_NAME']
    $liveColumns[$key] = [ordered]@{
        Table = [string]$reader['TABLE_NAME']
        Column = [string]$reader['COLUMN_NAME']
        DataType = [string]$reader['DATA_TYPE']
        Nullable = [string]$reader['IS_NULLABLE']
        MaxLength = if ($reader.IsDBNull($reader.GetOrdinal('CHARACTER_MAXIMUM_LENGTH'))) { $null } else { [int]$reader['CHARACTER_MAXIMUM_LENGTH'] }
        Default = if ($reader.IsDBNull($reader.GetOrdinal('COLUMN_DEFAULT'))) { $null } else { [string]$reader['COLUMN_DEFAULT'] }
    }
}
$reader.Close()

# 3. LIVE STORED PROCEDURES
$cmd.CommandText = @"
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME NOT LIKE 'fn_diagram%' 
  AND ROUTINE_NAME NOT LIKE 'sp_%diagram%'
ORDER BY ROUTINE_NAME
"@
$reader = $cmd.ExecuteReader()
$liveProcs = @()
while ($reader.Read()) {
    $liveProcs += [string]$reader['ROUTINE_NAME']
}
$reader.Close()

# 4. LIVE MENUS
$liveMenus = @()
try {
    $cmd.CommandText = "SELECT ProgramId, ProgramKey, ProgramName, SortOrder FROM SYS_ProgramMenus ORDER BY ProgramId"
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        $liveMenus += [ordered]@{
            ProgramId = [int]$reader['ProgramId']
            ProgramKey = [string]$reader['ProgramKey']
            ProgramName = [string]$reader['ProgramName']
            SortOrder = [int]$reader['SortOrder']
        }
    }
    $reader.Close()
} catch {
    Write-Warning "Could not read SYS_ProgramMenus: $($_.Exception.Message)"
}

# 5. LIVE PERMISSION COLUMNS (Check IsUpdate vs IsSave)
$cmd.CommandText = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SYS_AuthorGroupMapping'"
$reader = $cmd.ExecuteReader()
$livePermCols = @()
while ($reader.Read()) {
    $livePermCols += [string]$reader['COLUMN_NAME']
}
$reader.Close()

$conn.Close()

# -------------------------------------------------------------
# COMPARISON LOGIC
# -------------------------------------------------------------
$snapTables = @($snapshot.Tables)
$tablesAdded = @($liveTableList | Where-Object { $snapTables -notcontains $_ })
$tablesRemoved = @($snapTables | Where-Object { $liveTableList -notcontains $_ })

# Compare columns
$snapCols = @{}
foreach ($c in $snapshot.Columns) {
    $k = $c.Table + '.' + $c.Column
    $snapCols[$k] = $c
}

$colsAdded = @($liveColumns.Keys | Where-Object { -not $snapCols.ContainsKey($_) })
$colsRemoved = @($snapCols.Keys | Where-Object { -not $liveColumns.ContainsKey($_) })

# Stored procedures diff
$snapProcs = @($snapshot.StoredProcedures | ForEach-Object { $_.Name })
$procsAdded = @($liveProcs | Where-Object { $snapProcs -notcontains $_ })
$procsRemoved = @($snapProcs | Where-Object { $liveProcs -notcontains $_ })

# Special Check: 5 Canonical CRUD permissions in SYS_AuthorGroupMapping
$hasIsUpdate = $livePermCols -contains 'IsUpdate'
$hasIsSave = $livePermCols -contains 'IsSave'
$hasIsEdit = $livePermCols -contains 'IsEdit'

# Build Markdown Report
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Bao Cao So Sanh Co So Du Lieu: Live HRM_TEST_DB (DB_Real) vs Snapshot Chuan Hoa")
$lines.Add("Thoi gian thuc hien: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("Thoi gian snapshot chuan: $($snapshot.ExportTime)")
$lines.Add("")

$lines.Add("## 1. Danh Gia Trang Thai Cot Quyen Chuan CRUD (SYS_AuthorGroupMapping)")
$lines.Add("| Tieu chi | Trang thai Live DB | Danh gia | Ghi chu |")
$lines.Add("|:---|:---:|:---:|:---|")

$statusIsUpdate = if ($hasIsUpdate) { "CO TON TAI (YES)" } else { "CHUA CO (MISSING)" }
$evalIsUpdate = if ($hasIsUpdate) { "OK" } else { "CAN CHAY MIGRATION" }
$lines.Add("| Cot IsUpdate (Quyen cap nhat chuan) | $statusIsUpdate | $evalIsUpdate | Backend & Frontend yeu cau |")

$statusIsSave = if ($hasIsSave) { "DANG TON TAI (VAN CON)" } else { "DA XOA (CLEAN)" }
$evalIsSave = if ($hasIsSave) { "CAN DROP COT" } else { "OK" }
$lines.Add("| Cot cu IsSave | $statusIsSave | $evalIsSave | Bi loai bo theo chuan CRUD |")

$statusIsEdit = if ($hasIsEdit) { "DANG TON TAI (CU)" } else { "KHONG CO (CLEAN)" }
$lines.Add("| Cot cu IsEdit | $statusIsEdit | $(if ($hasIsEdit) { 'CAN DROP' } else { 'OK' }) | Khong su dung |")
$lines.Add("")

$lines.Add("## 2. Bang Du Lieu (Tables Diff)")
$lines.Add("- **Tong so bang Live DB:** $($liveTableList.Count)")
$lines.Add("- **Tong so bang Snapshot:** $($snapTables.Count)")
$lines.Add("")

if ($tablesAdded.Count -gt 0) {
    $lines.Add("### Bang Moi Trong Live DB (Khong co trong Snapshot):")
    $lines.Add("> Co the la bang du lieu goc tu DB_Real chua qua chuan hoa domain:")
    foreach ($t in $tablesAdded) {
        $lines.Add("- Table: $t (Rows: $($liveTables[$t]))")
    }
    $lines.Add("")
} else {
    $lines.Add("- Khong co bang moi phat sinh.")
}

if ($tablesRemoved.Count -gt 0) {
    $lines.Add("### Bang Bi Thieu Trong Live DB (Co trong Snapshot nhung Live khong co):")
    $lines.Add("> Can bo sung lai script tao bang:")
    foreach ($t in $tablesRemoved) {
        $lines.Add("- Table: $t")
    }
    $lines.Add("")
} else {
    $lines.Add("- Khong co bang nao bi thieu so voi Snapshot.")
}
$lines.Add("")

$lines.Add("## 3. Cot Du Lieu (Columns Diff)")
if ($colsAdded.Count -gt 0) {
    $lines.Add("### Cot Moi Trong Live DB ($($colsAdded.Count) cot):")
    foreach ($k in $colsAdded) {
        $c = $liveColumns[$k]
        $lines.Add("- Column: $($c.Table).$($c.Column) ($($c.DataType))")
    }
    $lines.Add("")
} else {
    $lines.Add("- Khong co cot moi phat sinh.")
}

if ($colsRemoved.Count -gt 0) {
    $lines.Add("### Cot Bi Thieu Trong Live DB ($($colsRemoved.Count) cot):")
    foreach ($k in $colsRemoved) {
        $c = $snapCols[$k]
        $lines.Add("- Column: $($c.Table).$($c.Column) ($($c.DataType))")
    }
    $lines.Add("")
} else {
    $lines.Add("- Khong co cot nao bi thieu so voi Snapshot.")
}
$lines.Add("")

$lines.Add("## 4. Stored Procedures & Functions Diff")
if ($procsAdded.Count -gt 0) {
    $lines.Add("### SP Moi:")
    foreach ($p in $procsAdded) { $lines.Add("- SP: $p") }
}
if ($procsRemoved.Count -gt 0) {
    $lines.Add("### SP Bi Thieu:")
    foreach ($p in $procsRemoved) { $lines.Add("- SP: $p") }
}
if ($procsAdded.Count -eq 0 -and $procsRemoved.Count -eq 0) {
    $lines.Add("- Danh sach Stored Procedures dong nhat 100%.")
}
$lines.Add("")

$lines.Add("## 5. Danh Muc Menu Chuong Trinh (SYS_ProgramMenus Diff)")
$snapMenus = @($snapshot.ProgramMenus)
$liveMenuKeys = @($liveMenus | ForEach-Object { $_.ProgramKey })
$snapMenuKeys = @($snapMenus | ForEach-Object { $_.ProgramKey })
$menusAdded = @($liveMenuKeys | Where-Object { $snapMenuKeys -notcontains $_ })
$menusRemoved = @($snapMenuKeys | Where-Object { $liveMenuKeys -notcontains $_ })
$lines.Add("- **Tong so menu Live DB:** $($liveMenus.Count)")
$lines.Add("- **Tong so menu Snapshot:** $($snapMenus.Count)")
if ($menusAdded.Count -gt 0) {
    $lines.Add("### Menu Moi Trong Live DB:")
    foreach ($m in $menusAdded) { $lines.Add("- Menu: $m") }
}
if ($menusRemoved.Count -gt 0) {
    $lines.Add("### Menu Bi Thieu Trong Live DB:")
    foreach ($m in $menusRemoved) { $lines.Add("- Menu: $m") }
}
if ($menusAdded.Count -eq 0 -and $menusRemoved.Count -eq 0) {
    $lines.Add("- Danh muc 37 Menu dong nhat 100%.")
}
$lines.Add("")

$lines.Add("## 6. So Sanh So Luong Dong Du Lieu (Row Count)")
$lines.Add("| Ten Bang | Dong trong Live DB | Dong trong Snapshot | Chenh lech |")
$lines.Add("|:---|:---:|:---:|:---:|")

$allTableNames = @(($liveTableList + $snapTables) | Select-Object -Unique | Sort-Object)
foreach ($t in $allTableNames) {
    $liveCount = if ($liveTables.ContainsKey($t)) { $liveTables[$t] } else { "(Khong ton tai)" }
    $snapRow = $snapshot.TableSummary | Where-Object { $_.Table -eq $t } | Select-Object -First 1
    $snapCount = if ($snapRow) { $snapRow.RowCount } else { "(Khong ton tai)" }
    
    $diff = if ($liveCount -ne "(Khong ton tai)" -and $snapCount -ne "(Khong ton tai)") {
        $diffVal = $liveCount - $snapCount
        if ($diffVal -gt 0) { "+$diffVal" } elseif ($diffVal -lt 0) { "$diffVal" } else { "0 (Dong nhat)" }
    } else {
        "N/A"
    }
    $lines.Add("| $t | $liveCount | $snapCount | $diff |")
}

$reportContent = $lines -join "`r`n"
Set-Content -Path $outputPath -Value $reportContent -Encoding UTF8

Write-Host "`nComparison completed! Report generated at: $outputPath" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host ("- Tables in Live DB: {0} (Snapshot had: {1})" -f $liveTableList.Count, $snapTables.Count)
Write-Host ("- Tables added: {0}" -f $tablesAdded.Count)
Write-Host ("- Tables missing: {0}" -f $tablesRemoved.Count)
Write-Host ("- Columns added: {0}" -f $colsAdded.Count)
Write-Host ("- Columns missing: {0}" -f $colsRemoved.Count)
Write-Host ("- Has IsUpdate: {0}" -f $hasIsUpdate)
Write-Host ("- Has IsSave: {0}" -f $hasIsSave)
