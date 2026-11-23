[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$appSettings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($appSettings.ConnectionStrings.DefaultConnection)
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT DISTINCT EmployeeCode, FullName, PayrollMonth FROM HR_PayrollEmployeeMonthly ORDER BY EmployeeCode"
$r = $cmd.ExecuteReader()
Write-Host "--- Employees with payroll ---"
while ($r.Read()) {
    Write-Host "$($r['EmployeeCode']) | $($r['FullName']) | $($r['PayrollMonth'])"
}
$r.Close()

$cmd.CommandText = "SELECT UserId, UserCode, FullName, Status FROM SYS_Users"
$r = $cmd.ExecuteReader()
Write-Host "`n--- SYS_Users ---"
while ($r.Read()) {
    Write-Host "$($r['UserId']) | $($r['UserCode']) | $($r['FullName']) | Status: $($r['Status'])"
}
$r.Close()
$conn.Close()
