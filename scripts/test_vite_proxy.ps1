$loginBody = '{"UserCode":"ADMIN","Password":"Hansol@12345"}'
$login = Invoke-RestMethod -Uri 'http://localhost:8000/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
Write-Host "Vite Login: $($login.isSuccess)"
$token = $login.data.accessToken
$h = @{ Authorization = "Bearer $token" }

Write-Host "`n--- 1. TEST PERIODS (GRID DATA) ---"
$res = Invoke-RestMethod -Uri 'http://localhost:8000/api/ess/my-payslip/periods' -Method Get -Headers $h
Write-Host "Vite Periods: $($res.isSuccess) - Count: $($res.data.Count)"
foreach ($p in $res.data) {
    Write-Host "  -> $($p.periodId): $($p.periodName) | Basic: $($p.basicSalary) | WorkDays: $($p.totalWorkDays) | Gross: $($p.grossSalary) | Deduct: $($p.totalDeduction) | Net: $($p.netReceived)"
}

Write-Host "`n--- 2. TEST DETAIL PAYSLIP 2026-08 (MODAL DATA) ---"
$detail = Invoke-RestMethod -Uri 'http://localhost:8000/api/ess/my-payslip?periodId=2026-08' -Method Get -Headers $h
Write-Host "Detail Success: $($detail.isSuccess)"
Write-Host "Employee: $($detail.data.employee.fullName) ($($detail.data.employee.employeeCode)) - Department: $($detail.data.employee.department) - Net: $($detail.data.netReceived)"
Write-Host "Items Count: A=$($detail.data.itemsA.Count), B=$($detail.data.itemsB.Count), C=$($detail.data.itemsC.Count), D=$($detail.data.itemsD.Count)"
