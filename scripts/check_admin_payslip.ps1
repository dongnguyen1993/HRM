[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$app = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($app.ConnectionStrings.DefaultConnection)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "
SELECT EmployeeCode, PayrollMonth, FullName, Department, QualificationPosition, BasicSalary, TotalWorkDays, GrossSalary, TotalDeduction, NetReceived
FROM dbo.HR_PayrollEmployeeMonthly
WHERE EmployeeCode = 'ADMIN';
"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "$($r['EmployeeCode']) | $($r['PayrollMonth']) | $($r['FullName']) | Dep: $($r['Department']) | Pos: $($r['QualificationPosition']) | Basic: $($r['BasicSalary']) | Days: $($r['TotalWorkDays']) | Net: $($r['NetReceived'])"
}
$conn.Close()
