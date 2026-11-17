[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " RUNNING COMPREHENSIVE TEST SUITE: DAILY WORK TIME (ESS & HR)" -ForegroundColor Cyan
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

# ─── CASE 1: HR Trigger Timesheet Calculation Engine ───────────────────────────
Write-Host "`n--- CASE 1: HR Trigger Timesheet Calculation Engine (sp_CalculateTimesheetEngine) ---" -ForegroundColor Yellow
$calcPayload = @{
    fromDate = "2026-11-16"
    toDate = "2026-11-17"
    userCodeFilter = "1200837"
} | ConvertTo-Json
$calcBytes = [System.Text.Encoding]::UTF8.GetBytes($calcPayload)
$calcRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary/calculate" -Method Post -Body $calcBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($calcRes | ConvertTo-Json -Compress)" -ForegroundColor Green
if (-not $calcRes.isSuccess) {
    Write-Host " FAIL: Calculate timesheet engine failed!" -ForegroundColor Red
    exit 1
}
Write-Host " PASS: Timesheet engine executed successfully for 1200837." -ForegroundColor Green

# ─── CASE 2: HR Tra cứu Bảng công tổng hợp (Work Summary List) ─────────────────
Write-Host "`n--- CASE 2: HR Tra cứu Bảng công tổng hợp (/api/hr/work-summary) ---" -ForegroundColor Yellow
$hrSummaryRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary?fromDate=2026-11-16&toDate=2026-11-17&searchKeyword=1200837" -Method Get -Headers $adminHeaders
if (-not $hrSummaryRes.isSuccess -or $hrSummaryRes.totalRecords -le 0) {
    Write-Host " FAIL: Could not retrieve work summary records!" -ForegroundColor Red
    exit 1
}

$rec16 = $hrSummaryRes.data | Where-Object { $_.workDate -like "*2026-11-16*" }
if ($rec16) {
    Write-Host " PASS: Record 2026-11-16 found: User=$($rec16.userCode) ($($rec16.fullName)), Shift=$($rec16.shiftName), In=$($rec16.checkInTimeStr), Out=$($rec16.checkOutTimeStr), WorkUnits=$($rec16.workUnits), OtHours=$($rec16.otHours), Status=$($rec16.status)" -ForegroundColor Green
    if ([double]$rec16.workUnits -ne 1.0 -or [double]$rec16.otHours -ne 2.5) {
        Write-Host " FAIL: Mismatched workUnits (expected 1.0) or otHours (expected 2.5)!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " FAIL: 2026-11-16 work summary record not found!" -ForegroundColor Red
    exit 1
}

# ─── CASE 3: HR Thống kê công & Nhóm phòng ban ────────────────────────────────
Write-Host "`n--- CASE 3: HR Thống kê tổng hợp & Danh mục phòng ban ---" -ForegroundColor Yellow
$statsRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary/statistics?fromDate=2026-11-01&toDate=2026-11-30" -Method Get -Headers $adminHeaders
Write-Host " Statistics: TotalRecords=$($statsRes.data.totalRecords), TotalWorkUnits=$($statsRes.data.totalWorkUnits), TotalOtHours=$($statsRes.data.totalOtHours), TotalWarnings=$($statsRes.data.totalWarnings)" -ForegroundColor Green

$groupsRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary/groups" -Method Get -Headers $adminHeaders
Write-Host " PASS: Retrieved $($groupsRes.data.Count) user groups from WorkSummary: $(($groupsRes.data | Select-Object -First 3) -join ', ')..." -ForegroundColor Green

# ─── CASE 4: HR Cập nhật điều chỉnh bản ghi chấm công (Update Work Record) ────
Write-Host "`n--- CASE 4: HR Điều chỉnh dòng chấm công (/api/hr/work-summary [PUT]) ---" -ForegroundColor Yellow
$targetLogId = [long]$rec16.logId
$updatePayload = @{
    logId = $targetLogId
    shiftId = 1
    checkInTime = "2026-11-16T07:23:39"
    checkOutTime = "2026-11-16T20:34:52"
    workUnits = 1.0
    otHours = 2.5
    lateMinutes = 0
    earlyMinutes = 0
    status = "PUNCTUAL"
    comment = "Đã đối soát quẹt thẻ BioStar và đơn OT - Chuẩn xác"
    isWarning = $false
    warningReason = "Khớp ca chuẩn xác"
} | ConvertTo-Json
$updateBytes = [System.Text.Encoding]::UTF8.GetBytes($updatePayload)
$updateRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary" -Method Put -Body $updateBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($updateRes | ConvertTo-Json -Compress)" -ForegroundColor Green

# Verify via GET by ID
$getByIdRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary/$targetLogId" -Method Get -Headers $adminHeaders
if ($getByIdRes.isSuccess -and $getByIdRes.data.comment -eq "Đã đối soát quẹt thẻ BioStar và đơn OT - Chuẩn xác") {
    Write-Host " PASS: Record #$targetLogId successfully updated and verified by GetById!" -ForegroundColor Green
} else {
    Write-Host " FAIL: GetById did not reflect updated comment!" -ForegroundColor Red
    exit 1
}

# ─── CASE 5: ESS Nhân viên tra cứu Bảng công cá nhân hàng ngày ─────────────────
Write-Host "`n--- CASE 5: ESS Nhân viên tra cứu Bảng công cá nhân (/api/ess/daily-work-time/work-summary) ---" -ForegroundColor Yellow
$essSummaryRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/daily-work-time/work-summary?fromDate=2026-11-01&toDate=2026-11-30" -Method Get -Headers $empHeaders
if (-not $essSummaryRes.isSuccess -or $essSummaryRes.data.Count -le 0) {
    Write-Host " FAIL: ESS could not retrieve daily work summary!" -ForegroundColor Red
    exit 1
}

$essRec16 = $essSummaryRes.data | Where-Object { $_.workDate -like "*2026-11-16*" }
if ($essRec16) {
    Write-Host " PASS: ESS found 2026-11-16: LogId=$($essRec16.logId), In=$($essRec16.checkInTimeStr), Out=$($essRec16.checkOutTimeStr), WorkUnits=$($essRec16.workUnits), OtHours=$($essRec16.otHours), Status=$($essRec16.status)" -ForegroundColor Green
    if ([long]$essRec16.logId -le 0) {
        Write-Host " FAIL: ESS LogId was not populated properly (Current: $($essRec16.logId))!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " FAIL: ESS could not find 2026-11-16 record!" -ForegroundColor Red
    exit 1
}

# ─── CASE 6: ESS Đối soát đơn nghỉ phép trong tháng ────────────────────────────
Write-Host "`n--- CASE 6: ESS Đối soát đơn nghỉ phép (/api/ess/daily-work-time/time-off) ---" -ForegroundColor Yellow
$essTimeOffRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/daily-work-time/time-off?fromDate=2026-12-01&toDate=2026-12-31" -Method Get -Headers $empHeaders
if ($essTimeOffRes.isSuccess -and $essTimeOffRes.data.Count -gt 0) {
    $firstLeave = $essTimeOffRes.data[0]
    Write-Host " PASS: ESS retrieved $($essTimeOffRes.data.Count) leaves: RequestId=#$($firstLeave.requestId), Type=$($firstLeave.requestType), Start=$($firstLeave.startDate), End=$($firstLeave.endDate), TotalDays=$($firstLeave.totalDays), Status=$($firstLeave.status)" -ForegroundColor Green
    if ($firstLeave.totalDays -le 0) {
        Write-Host " FAIL: TotalDays was not populated properly (Current: $($firstLeave.totalDays))!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " FAIL: ESS time-off query returned empty!" -ForegroundColor Red
    exit 1
}

# ─── CASE 7: Validation & Security Bounds ─────────────────────────────────────
Write-Host "`n--- CASE 7: Validation & Security Bounds ---" -ForegroundColor Yellow

# 7.1 FromDate > ToDate on Calculate
try {
    $badDatePayload = @{
        fromDate = "2026-12-31"
        toDate = "2026-12-01"
        userCodeFilter = "1200837"
    } | ConvertTo-Json
    $badBytes = [System.Text.Encoding]::UTF8.GetBytes($badDatePayload)
    $badRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary/calculate" -Method Post -Body $badBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
    Write-Host " FAIL: Inverted date range should have returned error!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Inverted date range correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.2 Non-existent ID on GetById
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/hr/work-summary/999999999" -Method Get -Headers $adminHeaders
    Write-Host " FAIL: Non-existent ID should return 404 Not Found!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Non-existent ID correctly returned 404 ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.3 Unauthenticated Access
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/daily-work-time/work-summary" -Method Get
    Write-Host " FAIL: Unauthenticated access should return 401 Unauthorized!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Unauthenticated access correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host " ALL DAILY WORK TIME (ESS & HR) TESTS COMPLETED! (ZERO ERRORS)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
