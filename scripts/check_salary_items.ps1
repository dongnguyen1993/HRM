[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$app = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($app.ConnectionStrings.DefaultConnection)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT DISTINCT PayrollMonth, EmployeeCode, COUNT(*) as Cnt FROM dbo.HR_PayrollSalaryItem GROUP BY PayrollMonth, EmployeeCode ORDER BY PayrollMonth, EmployeeCode;"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "$($r['PayrollMonth']) | $($r['EmployeeCode']) | Cnt: $($r['Cnt'])"
}
$conn.Close()
