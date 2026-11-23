$appSettings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($appSettings.ConnectionStrings.DefaultConnection)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT EmployeeCode, FullName, PayrollMonth, Notes FROM HR_PayrollEmployeeMonthly WHERE Notes IS NOT NULL AND Notes != ''"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "$($r['EmployeeCode']) | $($r['PayrollMonth']) | $($r['Notes'])"
}
$conn.Close()
