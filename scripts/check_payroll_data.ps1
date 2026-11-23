[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$app = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($app.ConnectionStrings.DefaultConnection)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "
SELECT PeriodId, PeriodName, IsPublished, TotalEmployees FROM dbo.HR_PayrollPeriod;
SELECT DISTINCT EmployeeCode, FullName, PayrollMonth FROM dbo.HR_PayrollEmployeeMonthly;
"
$r = $cmd.ExecuteReader()
Write-Host "=== PERIODS ==="
while ($r.Read()) {
    Write-Host "$($r['PeriodId']) | $($r['PeriodName']) | Published: $($r['IsPublished']) | TotalEmp: $($r['TotalEmployees'])"
}
$r.NextResult() | Out-Null
Write-Host "=== EMPLOYEES ==="
while ($r.Read()) {
    Write-Host "$($r['EmployeeCode']) | $($r['FullName']) | Month: $($r['PayrollMonth'])"
}
$conn.Close()
