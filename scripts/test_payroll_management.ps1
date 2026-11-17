[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " RUNNING COMPREHENSIVE TEST SUITE: PAYROLL & MY PAYSLIP (ESS & HR)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# 1. Login as ADMIN
Write-Host "`n[AUTH] Logging in as ADMIN..." -ForegroundColor Yellow
$loginAdminJson = @{ userCode = "ADMIN"; password = "Hansol@12345" } | ConvertTo-Json
$adminBytes = [System.Text.Encoding]::UTF8.GetBytes($loginAdminJson)
$adminRes = Invoke-RestMethod -Uri "http://localhost:7014/api/sys/auth/login" -Method Post -Body $adminBytes -ContentType "application/json; charset=utf-8"
$adminToken = $adminRes.data.accessToken
$adminHeaders = @{ "Authorization" = "Bearer $adminToken" }
Write-Host " Admin Token acquired successfully." -ForegroundColor Green

# 2. Login as Employee 1200837
Write-Host "`n[AUTH] Logging in as Employee 1200837..." -ForegroundColor Yellow
$loginEmpJson = @{ userCode = "1200837"; password = "Hansol@12345" } | ConvertTo-Json
$empBytes = [System.Text.Encoding]::UTF8.GetBytes($loginEmpJson)
$empRes = Invoke-RestMethod -Uri "http://localhost:7014/api/sys/auth/login" -Method Post -Body $empBytes -ContentType "application/json; charset=utf-8"
$empToken = $empRes.data.accessToken
$empHeaders = @{ "Authorization" = "Bearer $empToken" }
Write-Host " Employee Token acquired successfully." -ForegroundColor Green

# ─── CASE 1: HR Tra cứu Danh sách các kỳ lương (Payroll Periods) ───────────────
Write-Host "`n--- CASE 1: HR Tra cứu Danh sách các kỳ lương (/api/hr/payroll/periods) ---" -ForegroundColor Yellow
$periodsRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods" -Method Get -Headers $adminHeaders
if (-not $periodsRes.isSuccess -or $periodsRes.data.Count -le 0) {
    Write-Host " FAIL: Could not retrieve payroll periods!" -ForegroundColor Red
    exit 1
}
Write-Host " PASS: Retrieved $($periodsRes.data.Count) payroll periods:" -ForegroundColor Green
foreach ($p in $periodsRes.data) {
    Write-Host "   - Period [$($p.periodId)]: $($p.periodName), TotalNet=$([double]$p.totalNetSalary) VND, Published=$($p.isPublished)" -ForegroundColor DarkCyan
}

# ─── CASE 2: HR Xem danh sách nhân viên trong kỳ lương 2026-08 ────────────────
Write-Host "`n--- CASE 2: HR Xem danh sách nhân viên trong kỳ lương 2026-08 ---" -ForegroundColor Yellow
$empListRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2026-08/employees" -Method Get -Headers $adminHeaders
if (-not $empListRes.isSuccess -or $empListRes.data.Count -le 0) {
    Write-Host " FAIL: Could not retrieve employee list for 2026-08!" -ForegroundColor Red
    exit 1
}
$emp1200837 = $empListRes.data | Where-Object { $_.employeeCode -eq "1200837" }
if ($emp1200837) {
    Write-Host " PASS: Found Employee $($emp1200837.employeeCode): $($emp1200837.fullName), BasicSalary=$($emp1200837.basicSalary), Gross=$($emp1200837.grossSalary), Net=$($emp1200837.netReceived)" -ForegroundColor Green
    if ([double]$emp1200837.netReceived -ne 10916500) {
        Write-Host " FAIL: Mismatched Net Received (expected 10916500)!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " FAIL: Employee 1200837 not found in 2026-08 payroll!" -ForegroundColor Red
    exit 1
}

# ─── CASE 3: HR Xem chi tiết phiếu lương (Bóc tách A, B, C, D) ────────────────
Write-Host "`n--- CASE 3: HR Xem chi tiết phiếu lương bóc tách (/api/hr/payroll/periods/2026-08/employees/1200837) ---" -ForegroundColor Yellow
$detailRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2026-08/employees/1200837" -Method Get -Headers $adminHeaders
if (-not $detailRes.isSuccess) {
    Write-Host " FAIL: Could not retrieve payslip detail!" -ForegroundColor Red
    exit 1
}
$d = $detailRes.data
Write-Host " PASS: Payslip breakdown retrieved:" -ForegroundColor Green
Write-Host "   - Total B (Official & OT): $([double]$d.totalB_Amount) VND" -ForegroundColor DarkCyan
Write-Host "   - Total C (Allowances):    $([double]$d.totalC_Amount) VND" -ForegroundColor DarkCyan
Write-Host "   - Total D (Deductions):    $([double]$d.totalD_Amount) VND" -ForegroundColor DarkCyan
Write-Host "   - Net Received:            $([double]$d.netReceived) VND" -ForegroundColor Green

# ─── CASE 4: HR Cập nhật thông tin lương nhân viên ────────────────────────────
Write-Host "`n--- CASE 4: HR Cập nhật thông tin lương nhân viên (PUT /api/hr/payroll/employees) ---" -ForegroundColor Yellow
$updatePayload = @{
    periodId = "2026-09"
    employeeCode = "1200837"
    notes = "Đã cập nhật thưởng tiến độ dự án Q3"
    basicSalary = 7500000
    grossSalary = 8000000
    totalDeduction = 850000
    netReceived = 7150000
} | ConvertTo-Json
$updateBytes = [System.Text.Encoding]::UTF8.GetBytes($updatePayload)
$updateRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/employees" -Method Put -Body $updateBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($updateRes | ConvertTo-Json -Compress)" -ForegroundColor Green

# Verify via detail API
$checkDetailRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2026-09/employees/1200837" -Method Get -Headers $adminHeaders
if ($checkDetailRes.data.employee.notes -eq "Đã cập nhật thưởng tiến độ dự án Q3") {
    Write-Host " PASS: Employee notes successfully updated and verified in DB!" -ForegroundColor Green
} else {
    Write-Host " FAIL: Employee notes did not persist!" -ForegroundColor Red
    exit 1
}

# ─── CASE 5: Vòng đời Công bố / Hủy công bố kỳ lương & Tác động ESS ───────────
Write-Host "`n--- CASE 5: Vòng đời Công bố / Hủy công bố (Publish/Unpublish Lifecycle) ---" -ForegroundColor Yellow

# 5.1 Ban đầu 2026-09 là UNPUBLISHED -> Nhân viên 1200837 KHÔNG được xem
Write-Host " [5.1] Employee 1200837 attempts to access unpublished period 2026-09..." -ForegroundColor DarkGray
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip?periodId=2026-09" -Method Get -Headers $empHeaders
    Write-Host " FAIL: Accessing unpublished payslip should have failed!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Correctly blocked unpublished payslip ($($_.Exception.Message))" -ForegroundColor Green
}

# 5.2 HR Publish 2026-09
Write-Host " [5.2] HR Publishes period 2026-09..." -ForegroundColor DarkGray
$pubRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2026-09/publish" -Method Post -Headers $adminHeaders
Write-Host " Result: $($pubRes | ConvertTo-Json -Compress)" -ForegroundColor Green

# 5.3 Nhân viên kiểm tra danh sách kỳ đã công bố -> Thấy 2026-09
$essPeriodsAfter = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip/periods" -Method Get -Headers $empHeaders
$found09 = $essPeriodsAfter.data | Where-Object { $_.periodId -eq "2026-09" }
if ($found09) {
    Write-Host " PASS: Period 2026-09 is now visible to employee on ESS!" -ForegroundColor Green
} else {
    Write-Host " FAIL: Period 2026-09 not visible on ESS after publish!" -ForegroundColor Red
    exit 1
}

# 5.4 Nhân viên truy cập thành công phiếu lương 2026-09
$ess09Res = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip?periodId=2026-09" -Method Get -Headers $empHeaders
if ($ess09Res.isSuccess -and $ess09Res.data.employee.employeeCode -eq "1200837") {
    Write-Host " PASS: Employee 1200837 successfully views published payslip: NetReceived=$($ess09Res.data.netReceived) VND" -ForegroundColor Green
} else {
    Write-Host " FAIL: Employee could not view published payslip!" -ForegroundColor Red
    exit 1
}

# 5.5 HR Unpublish 2026-09 (Khôi phục trạng thái chuẩn)
Write-Host " [5.5] HR Unpublishes period 2026-09 to restore state..." -ForegroundColor DarkGray
$unpubRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2026-09/unpublish" -Method Post -Headers $adminHeaders
Write-Host " Result: $($unpubRes | ConvertTo-Json -Compress)" -ForegroundColor Green

# ─── CASE 6: ESS Nhân viên gửi khiếu nại sai sót phiếu lương ──────────────────
Write-Host "`n--- CASE 6: ESS Nhân viên gửi khiếu nại phiếu lương (/api/ess/my-payslip/claim) ---" -ForegroundColor Yellow
$claimPayload = @{
    periodId = "2026-08"
    claimType = "INCORRECT_OT_HOURS"
    reason = "Đề nghị phòng nhân sự kiểm tra lại 2.5 giờ tăng ca ngày 16/11 đã được duyệt"
} | ConvertTo-Json
$claimBytes = [System.Text.Encoding]::UTF8.GetBytes($claimPayload)
$claimRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip/claim" -Method Post -Body $claimBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($claimRes | ConvertTo-Json -Compress)" -ForegroundColor Green
if (-not $claimRes.isSuccess) {
    Write-Host " FAIL: Salary claim failed!" -ForegroundColor Red
    exit 1
}
Write-Host " PASS: Salary claim submitted successfully to HR." -ForegroundColor Green

# ─── CASE 7: Validation & Security Bounds ─────────────────────────────────────
Write-Host "`n--- CASE 7: Validation & Security Bounds ---" -ForegroundColor Yellow

# 7.1 Regular employee (1200802) attempting HR-only API (Publish)
try {
    $loginRegJson = @{ userCode = "1200802"; password = "Hansol@12345" } | ConvertTo-Json
    $regBytes = [System.Text.Encoding]::UTF8.GetBytes($loginRegJson)
    $regRes = Invoke-RestMethod -Uri "http://localhost:7014/api/sys/auth/login" -Method Post -Body $regBytes -ContentType "application/json; charset=utf-8"
    $regHeaders = @{ "Authorization" = "Bearer $($regRes.data.accessToken)" }

    Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2026-08/publish" -Method Post -Headers $regHeaders
    Write-Host " FAIL: Regular employee calling HR publish should have thrown 403 Forbidden!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Regular employee calling HR API correctly blocked ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.2 Non-existent period on HR API
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/hr/payroll/periods/2099-99" -Method Get -Headers $adminHeaders
    Write-Host " FAIL: Non-existent period should return 404 Not Found!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Non-existent period correctly returned 404 ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.3 Unauthenticated access without token
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip" -Method Get
    Write-Host " FAIL: Unauthenticated access should return 401 Unauthorized!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Unauthenticated access correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host " ALL PAYROLL & MY PAYSLIP (ESS & HR) TESTS COMPLETED! (ZERO ERRORS)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
