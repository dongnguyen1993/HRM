param(
    [string]$outputPath = "d:\HRM\scripts\HRM_TEST_DB_ANALYSIS.json"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$server = "172.26.75.23,1433"
$database = "HRM_TEST_DB"
$user = "HRM_DEV"
$password = "Hansol@test12345"
$connStr = "Server=$server;Database=$database;User Id=$user;Password=$password;TrustServerCertificate=True;MultipleActiveResultSets=True;"

$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

# 1. Tables & Row counts
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
$tables = @()
while ($reader.Read()) {
    $tables += [ordered]@{
        Schema = [string]$reader['SchemaName']
        Table = [string]$reader['TableName']
        Rows = [int64]$reader['RowCount']
    }
}
$reader.Close()

# 2. Columns summary
$cmd.CommandText = @"
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION
"@
$reader = $cmd.ExecuteReader()
$columns = @{}
while ($reader.Read()) {
    $t = [string]$reader['TABLE_NAME']
    if (-not $columns.ContainsKey($t)) { $columns[$t] = @() }
    $columns[$t] += [ordered]@{
        Column = [string]$reader['COLUMN_NAME']
        Type = [string]$reader['DATA_TYPE']
        Nullable = [string]$reader['IS_NULLABLE']
        MaxLength = if ($reader.IsDBNull($reader.GetOrdinal('CHARACTER_MAXIMUM_LENGTH'))) { $null } else { [int]$reader['CHARACTER_MAXIMUM_LENGTH'] }
        Default = if ($reader.IsDBNull($reader.GetOrdinal('COLUMN_DEFAULT'))) { $null } else { [string]$reader['COLUMN_DEFAULT'] }
    }
}
$reader.Close()

# 3. Stored Procedures & Views
$cmd.CommandText = @"
SELECT 
    ROUTINE_TYPE,
    ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME NOT LIKE 'fn_%' AND ROUTINE_NAME NOT LIKE 'sp_%diagram%'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME
"@
$reader = $cmd.ExecuteReader()
$routines = @()
while ($reader.Read()) {
    $routines += [ordered]@{
        Type = [string]$reader['ROUTINE_TYPE']
        Name = [string]$reader['ROUTINE_NAME']
    }
}
$reader.Close()

$cmd.CommandText = @"
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS ORDER BY TABLE_NAME
"@
$reader = $cmd.ExecuteReader()
$views = @()
while ($reader.Read()) {
    $views += [string]$reader['TABLE_NAME']
}
$reader.Close()

# 4. Program Menus list
$cmd.CommandText = @"
SELECT ProgramId, ProgramKey, ProgramName, ProgramGroup, UseFlag, MenuFlag, SortOrder, Path, ApiUrl
FROM dbo.SYS_ProgramMenus
ORDER BY SortOrder, ProgramId
"@
$reader = $cmd.ExecuteReader()
$menus = @()
while ($reader.Read()) {
    $menus += [ordered]@{
        ProgramId = [int]$reader['ProgramId']
        ProgramKey = [string]$reader['ProgramKey']
        ProgramName = [string]$reader['ProgramName']
        ProgramGroup = [string]$reader['ProgramGroup']
        UseFlag = [bool]$reader['UseFlag']
        MenuFlag = [bool]$reader['MenuFlag']
        SortOrder = [int]$reader['SortOrder']
        Path = if ($reader.IsDBNull($reader.GetOrdinal('Path'))) { "" } else { [string]$reader['Path'] }
        ApiUrl = if ($reader.IsDBNull($reader.GetOrdinal('ApiUrl'))) { "" } else { [string]$reader['ApiUrl'] }
    }
}
$reader.Close()

# 5. AuthorGroupMapping column verification
$cmd.CommandText = @"
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SYS_AuthorGroupMapping'
"@
$reader = $cmd.ExecuteReader()
$permColumns = @()
while ($reader.Read()) {
    $permColumns += [string]$reader['COLUMN_NAME']
}
$reader.Close()

$conn.Close()

$result = [ordered]@{
    AnalyzedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Database = $database
    TotalTables = $tables.Count
    Tables = $tables
    PermissionColumns = $permColumns
    TotalMenus = $menus.Count
    Menus = $menus
    Routines = $routines
    Views = $views
    ColumnsByTable = $columns
}

$result | ConvertTo-Json -Depth 5 | Set-Content $outputPath -Encoding UTF8
Write-Host "Database analysis exported to $outputPath successfully! Tables: $($tables.Count), Menus: $($menus.Count)"
