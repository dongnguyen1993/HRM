[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$std = Get-Content 'd:\HRM\scripts\HRM_TEST_DB_ANALYSIS.json' -Raw | ConvertFrom-Json

$server = "172.26.75.23,1433"
$database = "HRM_TEST_DB"
$user = "HRM_DEV"
$password = "Hansol@test12345"
$connStr = "Server=$server;Database=$database;User Id=$user;Password=$password;TrustServerCertificate=True;"

$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION
"@
$reader = $cmd.ExecuteReader()
$liveCols = @{}
while ($reader.Read()) {
    $key = "$($reader['TABLE_NAME']).$($reader['COLUMN_NAME'])"
    $liveCols[$key] = [ordered]@{
        Table = [string]$reader['TABLE_NAME']
        Col = [string]$reader['COLUMN_NAME']
        Type = [string]$reader['DATA_TYPE']
        Nullable = [string]$reader['IS_NULLABLE']
        Len = if ($reader.IsDBNull(4)) { $null } else { [int]$reader[4] }
    }
}
$reader.Close()
$conn.Close()

Write-Host "=== COLUMNS IN STANDARD BUT MISSING IN LIVE REAL ==="
$missingCols = @()
foreach ($stTable in $std.ColumnsByTable.PSObject.Properties) {
    $tName = $stTable.Name
    foreach ($col in $stTable.Value) {
        $cName = $col.Column
        $key = "$tName.$cName"
        if (-not $liveCols.ContainsKey($key)) {
            $missingCols += $key
            Write-Host "Missing: $key ($($col.Type))"
        }
    }
}

Write-Host "`n=== COLUMNS IN LIVE REAL BUT NOT IN STANDARD (EXTRA COLS) ==="
$extraCols = @()
foreach ($key in $liveCols.Keys) {
    $parts = $key.Split('.')
    $tName = $parts[0]
    $cName = $parts[1]
    
    $found = $false
    if ($std.ColumnsByTable.$tName) {
        foreach ($c in $std.ColumnsByTable.$tName) {
            if ($c.Column -eq $cName) { $found = $true; break }
        }
    }
    if (-not $found) {
        $extraCols += $key
        Write-Host "Extra: $key"
    }
}

Write-Host "`nTotal missing columns in Real: $($missingCols.Count)"
Write-Host "Total extra columns in Real: $($extraCols.Count)"
