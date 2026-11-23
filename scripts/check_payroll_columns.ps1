[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$app = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($app.ConnectionStrings.DefaultConnection)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME IN ('HR_PayrollPeriod', 'HR_PayrollEmployeeMonthly', 'HR_PayrollSalaryItem')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "$($r['TABLE_NAME']) -> $($r['COLUMN_NAME']) ($($r['DATA_TYPE']))"
}
$conn.Close()
