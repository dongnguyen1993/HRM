$appSettings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($appSettings.ConnectionStrings.DefaultConnection)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT EmployeeCode, ItemCode, ItemName, Category, DaysHours, Amount FROM HR_PayrollSalaryItem WHERE PayrollMonth = '2026-08' ORDER BY EmployeeCode, Category, SortOrder"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Host "$($r['EmployeeCode']) | $($r['ItemCode']) | $($r['ItemName']) | $($r['DaysHours']) | $($r['Amount'])"
}
$conn.Close()
