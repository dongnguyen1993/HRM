[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Start-Sleep -Seconds 3

$baseUrl = "http://localhost:7014"

# 1. Login Admin
$loginBody = @{ UserCode = "ADMIN"; Password = "Hansol@12345" } | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $loginBody -ContentType "application/json; charset=utf-8"
$token = $loginRes.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

Write-Host "=== 1. TEST ESS MY PAYSLIP (ADMIN SELF) ==="
$selfPeriods = Invoke-RestMethod -Uri "$baseUrl/api/ess/my-payslip/periods" -Method Get -Headers $headers
Write-Host "Self Periods: Count=$($selfPeriods.data.Count)"
$selfPeriods.data | ForEach-Object { Write-Host "  -> $($_.periodId) : $($_.periodName)" }

$selfPayslip = Invoke-RestMethod -Uri "$baseUrl/api/ess/my-payslip?periodId=2026-07" -Method Get -Headers $headers
Write-Host "Self Payslip (2026-07): Emp=$($selfPayslip.data.employee.fullName), Net=$($selfPayslip.data.netReceived), Items: A=$($selfPayslip.data.itemsA.Count), B=$($selfPayslip.data.itemsB.Count), C=$($selfPayslip.data.itemsC.Count), D=$($selfPayslip.data.itemsD.Count)"

Write-Host "`n=== 2. TEST ESS MY PAYSLIP (ADMIN INSPECTING EMPLOYEE 1200837) ==="
$empPeriods = Invoke-RestMethod -Uri "$baseUrl/api/ess/my-payslip/periods?employeeCode=1200837" -Method Get -Headers $headers
Write-Host "1200837 Periods: Count=$($empPeriods.data.Count)"

$empPayslip = Invoke-RestMethod -Uri "$baseUrl/api/ess/my-payslip?periodId=2026-07&employeeCode=1200837" -Method Get -Headers $headers
Write-Host "1200837 Payslip (2026-07): Emp=$($empPayslip.data.employee.fullName), Net=$($empPayslip.data.netReceived), Items: A=$($empPayslip.data.itemsA.Count), B=$($empPayslip.data.itemsB.Count), C=$($empPayslip.data.itemsC.Count), D=$($empPayslip.data.itemsD.Count)"

Write-Host "`n=== 3. TEST HR PAYROLL MANAGEMENT ==="
$periods = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods" -Method Get -Headers $headers
Write-Host "All Periods: Count=$($periods.data.Count)"
$periods.data | ForEach-Object { Write-Host "  -> $($_.periodId) : $($_.periodName) (Published: $($_.isPublished))" }

$pubRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-09/publish" -Method Post -Headers $headers
Write-Host "Publish 2026-09: Success=$($pubRes.isSuccess), Message=$($pubRes.message)"

$unpubRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-09/unpublish" -Method Post -Headers $headers
Write-Host "Unpublish 2026-09: Success=$($unpubRes.isSuccess), Message=$($unpubRes.message)"

$export = Invoke-WebRequest -Uri "$baseUrl/api/hr/payroll/periods/2026-07/export" -Method Get -Headers $headers -UseBasicParsing
Write-Host "Export 2026-07: Status=$($export.StatusCode), Bytes=$($export.Content.Length)"
