[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$server = "172.26.75.23,1433"
$database = "HRM_TEST_DB"
$user = "HRM_DEV"
$password = "Hansol@test12345"
$connStr = "Server=$server;Database=$database;User Id=$user;Password=$password;TrustServerCertificate=True;MultipleActiveResultSets=True;"

$snapshotPath = "d:\HRM\scripts\DB_SNAPSHOT_BEFORE_OVERWRITE.json"

Write-Host "Connecting to $database on $server..." -ForegroundColor Cyan
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

$snapshot = [ordered]@{
    ExportTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Server = $server
    Database = $database
    Tables = @()
    Columns = @()
    PrimaryKeys = @()
    ForeignKeys = @()
    Indexes = @()
    Views = @()
    StoredProcedures = @()
    ProgramMenus = @()
    AuthorGroups = @()
    AuthorGroupMapping = @()
    CommonCodes = @()
    TableSummary = @()
}

# 1. Tables and row counts
Write-Host "Exporting tables and row counts..." -ForegroundColor Yellow
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
while ($reader.Read()) {
    $snapshot.Tables += $reader['TABLE_NAME']
    $snapshot.TableSummary += [ordered]@{
        Schema = $reader['TABLE_SCHEMA']
        Table = $reader['TABLE_NAME']
        RowCount = [int64]$reader['RowCount']
    }
}
$reader.Close()

# 2. Columns
Write-Host "Exporting table columns..." -ForegroundColor Yellow
$cmd.CommandText = @"
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    COLUMN_DEFAULT,
    IS_NULLABLE,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION
"@
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $snapshot.Columns += [ordered]@{
        Table = $reader['TABLE_NAME']
        Column = $reader['COLUMN_NAME']
        Ordinal = [int]$reader['ORDINAL_POSITION']
        Default = if ($reader.IsDBNull($reader.GetOrdinal('COLUMN_DEFAULT'))) { $null } else { [string]$reader['COLUMN_DEFAULT'] }
        Nullable = [string]$reader['IS_NULLABLE']
        DataType = [string]$reader['DATA_TYPE']
        MaxLength = if ($reader.IsDBNull($reader.GetOrdinal('CHARACTER_MAXIMUM_LENGTH'))) { $null } else { [int]$reader['CHARACTER_MAXIMUM_LENGTH'] }
    }
}
$reader.Close()

# 3. Primary Keys
Write-Host "Exporting Primary Keys..." -ForegroundColor Yellow
$cmd.CommandText = @"
SELECT 
    tc.TABLE_NAME,
    kcu.COLUMN_NAME,
    tc.CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY tc.TABLE_NAME, kcu.ORDINAL_POSITION
"@
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $snapshot.PrimaryKeys += [ordered]@{
        Table = $reader['TABLE_NAME']
        Column = $reader['COLUMN_NAME']
        ConstraintName = $reader['CONSTRAINT_NAME']
    }
}
$reader.Close()

# 4. Foreign Keys
Write-Host "Exporting Foreign Keys..." -ForegroundColor Yellow
$cmd.CommandText = @"
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
ORDER BY tp.name, fk.name
"@
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $snapshot.ForeignKeys += [ordered]@{
        Name = $reader['ForeignKeyName']
        ParentTable = $reader['ParentTable']
        ParentColumn = $reader['ParentColumn']
        ReferencedTable = $reader['ReferencedTable']
        ReferencedColumn = $reader['ReferencedColumn']
    }
}
$reader.Close()

# 5. Views
Write-Host "Exporting Views..." -ForegroundColor Yellow
$cmd.CommandText = @"
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME
"@
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $snapshot.Views += [ordered]@{
        Table = $reader['TABLE_NAME']
        Definition = if ($reader.IsDBNull($reader.GetOrdinal('VIEW_DEFINITION'))) { "" } else { [string]$reader['VIEW_DEFINITION'] }
    }
}
$reader.Close()

# 6. Stored Procedures and Functions
Write-Host "Exporting Stored Procedures & Functions..." -ForegroundColor Yellow
$cmd.CommandText = @"
SELECT 
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE,
    ROUTINE_DEFINITION
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME NOT LIKE 'fn_diagram%' 
  AND ROUTINE_NAME NOT LIKE 'sp_%diagram%'
ORDER BY ROUTINE_NAME
"@
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $snapshot.StoredProcedures += [ordered]@{
        Name = $reader['ROUTINE_NAME']
        Type = $reader['ROUTINE_TYPE']
        Definition = if ($reader.IsDBNull($reader.GetOrdinal('ROUTINE_DEFINITION'))) { "" } else { [string]$reader['ROUTINE_DEFINITION'] }
    }
}
$reader.Close()

# 7. Reference Data: SYS_ProgramMenus
Write-Host "Exporting SYS_ProgramMenus records..." -ForegroundColor Yellow
$cmd.CommandText = "SELECT * FROM SYS_ProgramMenus ORDER BY ProgramId"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $row = [ordered]@{}
    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
        $colName = $reader.GetName($i)
        $row[$colName] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
    }
    $snapshot.ProgramMenus += $row
}
$reader.Close()

# 8. Reference Data: SYS_AuthorGroups
Write-Host "Exporting SYS_AuthorGroups records..." -ForegroundColor Yellow
$cmd.CommandText = "SELECT * FROM SYS_AuthorGroups ORDER BY GroupId"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $row = [ordered]@{}
    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
        $colName = $reader.GetName($i)
        $row[$colName] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
    }
    $snapshot.AuthorGroups += $row
}
$reader.Close()

# 9. Reference Data: SYS_AuthorGroupMapping
Write-Host "Exporting SYS_AuthorGroupMapping records..." -ForegroundColor Yellow
$cmd.CommandText = "SELECT * FROM SYS_AuthorGroupMapping ORDER BY GroupId, ProgramId"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $row = [ordered]@{}
    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
        $colName = $reader.GetName($i)
        $row[$colName] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
    }
    $snapshot.AuthorGroupMapping += $row
}
$reader.Close()

# 10. Reference Data: SYS_CommonCodes
Write-Host "Exporting SYS_CommonCodes records..." -ForegroundColor Yellow
$cmd.CommandText = "SELECT * FROM SYS_CommonCodes ORDER BY CodeId"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    $row = [ordered]@{}
    for ($i = 0; $i -lt $reader.FieldCount; $i++) {
        $colName = $reader.GetName($i)
        $row[$colName] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
    }
    $snapshot.CommonCodes += $row
}
$reader.Close()

$conn.Close()

$json = $snapshot | ConvertTo-Json -Depth 10
Set-Content -Path $snapshotPath -Value $json -Encoding UTF8
Write-Host "`nSUCCESS: Database Snapshot saved to $snapshotPath" -ForegroundColor Green
Write-Host ("- Tables count: {0}" -f $snapshot.Tables.Count)
Write-Host ("- Columns count: {0}" -f $snapshot.Columns.Count)
Write-Host ("- Menus count: {0}" -f $snapshot.ProgramMenus.Count)
Write-Host ("- Permission mappings count: {0}" -f $snapshot.AuthorGroupMapping.Count)
Write-Host ("- User Stored Procedures count: {0}" -f $snapshot.StoredProcedures.Count)
