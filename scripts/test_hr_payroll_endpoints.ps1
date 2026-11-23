[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$baseUrl = "http://localhost:7014"

# 1. Login Admin
$loginBody = @{ UserCode = "ADMIN"; Password = "Hansol@12345" } | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $loginBody -ContentType "application/json; charset=utf-8"
$token = $loginRes.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

Write-Host "=== TEST 1: GET /api/hr/payroll/periods ==="
$periodsRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods" -Method Get -Headers $headers
Write-Host "Success: $($periodsRes.isSuccess), Total Periods: $($periodsRes.data.Count)"
$periodsRes.data | ForEach-Object {
    Write-Host "  Period: $($_.periodId) | $($_.periodName) | Published: $($_.isPublished) | Employees: $($_.totalEmployees)"
}

Write-Host "`n=== TEST 2: GET /api/hr/payroll/periods/{periodId} ==="
$periodDetail = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-07" -Method Get -Headers $headers
Write-Host "Success: $($periodDetail.isSuccess), Period: $($periodDetail.data.periodId) - $($periodDetail.data.periodName)"

Write-Host "`n=== TEST 3: GET /api/hr/payroll/periods/{periodId}/employees ==="
$empRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-07/employees" -Method Get -Headers $headers
Write-Host "Success: $($empRes.isSuccess), Total Employees in 2026-07: $($empRes.data.Count)"
$empRes.data | Select-Object -First 3 | ForEach-Object {
    Write-Host "  Emp: $($_.employeeCode) - $($_.fullName) - Net: $($_.netReceived)"
}

Write-Host "`n=== TEST 4: GET /api/hr/payroll/periods/{periodId}/employees/{employeeCode} ==="
$payslipRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-07/employees/1200837" -Method Get -Headers $headers
$totalItems = $payslipRes.data.itemsA.Count + $payslipRes.data.itemsB.Count + $payslipRes.data.itemsC.Count + $payslipRes.data.itemsD.Count
Write-Host "Success: $($payslipRes.isSuccess), Emp: $($payslipRes.data.employee.fullName), Total Items: $totalItems (A:$($payslipRes.data.itemsA.Count), B:$($payslipRes.data.itemsB.Count), C:$($payslipRes.data.itemsC.Count), D:$($payslipRes.data.itemsD.Count)), Net: $($payslipRes.data.netReceived)"

Write-Host "`n=== TEST 5: Toggle Publish / Unpublish Status ==="
# Test publish
try {
    $pubRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-09/publish" -Method Post -Headers $headers
    Write-Host "Publish 2026-09 Result: Success=$($pubRes.isSuccess), Message=$($pubRes.message)"
} catch {
    Write-Host "Publish failed: $($_.Exception.Message)"
}

# Test unpublish back
try {
    $unpubRes = Invoke-RestMethod -Uri "$baseUrl/api/hr/payroll/periods/2026-09/unpublish" -Method Post -Headers $headers
    Write-Host "Unpublish 2026-09 Result: Success=$($unpubRes.isSuccess), Message=$($unpubRes.message)"
} catch {
    Write-Host "Unpublish failed: $($_.Exception.Message)"
}

Write-Host "`n=== TEST 6: Export Excel ==="
try {
    $exportRes = Invoke-WebRequest -Uri "$baseUrl/api/hr/payroll/periods/2026-07/export" -Method Get -Headers $headers -UseBasicParsing
    Write-Host "Export 2026-07 Status: $($exportRes.StatusCode), Bytes: $($exportRes.Content.Length)"
} catch {
    Write-Host "Export failed: $($_.Exception.Message)"
}
