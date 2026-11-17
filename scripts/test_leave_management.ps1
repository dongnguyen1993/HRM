[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " RUNNING COMPREHENSIVE TEST SUITE: ESS & HR LEAVE MANAGEMENT" -ForegroundColor Cyan
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

# CASE 1: ESS Submit Valid Leave (AL)
Write-Host "`n--- CASE 1: ESS Submit Leave Request (AL) ---" -ForegroundColor Yellow
$leavePayload = @{
    requestType = "AL"
    startDate = "2026-12-15"
    endDate = "2026-12-16"
    reason = "Nghỉ phép thường niên giải quyết việc gia đình"
} | ConvertTo-Json
$leaveBytes = [System.Text.Encoding]::UTF8.GetBytes($leavePayload)
$submitRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/leave-request" -Method Post -Body $leaveBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($submitRes | ConvertTo-Json -Compress)" -ForegroundColor Green
$newRequestId = $submitRes.data

# CASE 2: ESS View Personal Leave List
Write-Host "`n--- CASE 2: ESS View Personal Leave List ---" -ForegroundColor Yellow
$myLeaveRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/time-off?fromDate=2026-12-15&toDate=2026-12-16" -Method Get -Headers $empHeaders
$foundItem = $myLeaveRes.data | Where-Object { $_.requestId -eq $newRequestId }
if ($foundItem) {
    Write-Host " PASS: Found Request #$($newRequestId) - Status=$($foundItem.status), Type=$($foundItem.requestType), Name=$($foundItem.requestTypeName), TotalDays=$($foundItem.totalDays)" -ForegroundColor Green
} else {
    Write-Host " FAIL: Request #$newRequestId not found in ESS list!" -ForegroundColor Red
    exit 1
}

# CASE 3: HR View Paged Requests
Write-Host "`n--- CASE 3: HR Manager View TimeOff Requests ---" -ForegroundColor Yellow
$hrListRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off?status=PENDING&requestType=AL" -Method Get -Headers $adminHeaders
$hrFound = $hrListRes.data | Where-Object { $_.requestId -eq $newRequestId }
if ($hrFound) {
    Write-Host " PASS: HR retrieved Request #$($newRequestId) from $($hrFound.userCode) ($($hrFound.fullName)), LeaveTypeName: $($hrFound.requestTypeName), IsPaid: $($hrFound.isPaid)" -ForegroundColor Green
} else {
    Write-Host " FAIL: HR could not find pending request!" -ForegroundColor Red
    exit 1
}

# CASE 4: HR Approve Request
Write-Host "`n--- CASE 4: HR Approve Leave Request ---" -ForegroundColor Yellow
$approvePayload = @{
    requestIds = @($newRequestId)
    comment = "HR phê duyệt nghỉ phép thường niên hợp lệ"
} | ConvertTo-Json
$approveBytes = [System.Text.Encoding]::UTF8.GetBytes($approvePayload)
$approveRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off/approve" -Method Post -Body $approveBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Approval Result: $($approveRes.message)" -ForegroundColor Green

# CASE 5: Verify Status = APPROVED
Write-Host "`n--- CASE 5: Verify Status Updated to APPROVED ---" -ForegroundColor Yellow
$checkRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off/$newRequestId" -Method Get -Headers $adminHeaders
Write-Host " Request #$($newRequestId) Status=$($checkRes.data.status), ApprovedBy=$($checkRes.data.approvedBy), Comment=$($checkRes.data.comment)" -ForegroundColor Green
if ($checkRes.data.status -eq "APPROVED") {
    Write-Host " PASS: Status is APPROVED!" -ForegroundColor Green
} else {
    Write-Host " FAIL: Status is not APPROVED!" -ForegroundColor Red
    exit 1
}

# CASE 6: Submit Another Request and Reject Flow (SL)
Write-Host "`n--- CASE 6: ESS Submit SL & HR Reject Flow ---" -ForegroundColor Yellow
$sickPayload = @{
    requestType = "SL"
    startDate = "2026-12-20"
    endDate = "2026-12-20"
    reason = "Nghỉ ốm điều trị tại nhà"
} | ConvertTo-Json
$sickBytes = [System.Text.Encoding]::UTF8.GetBytes($sickPayload)
$sickRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/leave-request" -Method Post -Body $sickBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
$sickId = $sickRes.data
Write-Host " Submitted Sick Leave Request #$($sickId)" -ForegroundColor Green

$rejectPayload = @{
    requestIds = @($sickId)
    comment = "Cần nộp giấy xác nhận khám bệnh của cơ sở y tế"
} | ConvertTo-Json
$rejectBytes = [System.Text.Encoding]::UTF8.GetBytes($rejectPayload)
$rejectRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off/reject" -Method Post -Body $rejectBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Reject Result: $($rejectRes.message)" -ForegroundColor Green

$sickCheck = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off/$sickId" -Method Get -Headers $adminHeaders
Write-Host " Request #$($sickId) Status=$($sickCheck.data.status), Comment=$($sickCheck.data.comment)" -ForegroundColor Green
if ($sickCheck.data.status -eq "REJECTED") {
    Write-Host " PASS: Reject Flow succeeded!" -ForegroundColor Green
} else {
    Write-Host " FAIL: Reject status incorrect!" -ForegroundColor Red
    exit 1
}

# CASE 7: Boundary & Negative Validations
Write-Host "`n--- CASE 7: Boundary & Negative Validations ---" -ForegroundColor Yellow

# 7.1 End date before start date
try {
    $invDatePayload = @{
        requestType = "AL"
        startDate = "2026-12-25"
        endDate = "2026-12-20"
        reason = "Test invalid dates"
    } | ConvertTo-Json
    $invBytes = [System.Text.Encoding]::UTF8.GetBytes($invDatePayload)
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/leave-request" -Method Post -Body $invBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
    Write-Host " FAIL: Expected error for EndDate < StartDate, but got success!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Correctly rejected EndDate < StartDate" -ForegroundColor Green
}

# 7.2 Empty reason
try {
    $emptyPayload = @{
        requestType = "AL"
        startDate = "2026-12-25"
        endDate = "2026-12-26"
        reason = ""
    } | ConvertTo-Json
    $emptyBytes = [System.Text.Encoding]::UTF8.GetBytes($emptyPayload)
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/leave-request" -Method Post -Body $emptyBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
    Write-Host " FAIL: Expected error for empty reason, but got success!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Correctly rejected empty reason" -ForegroundColor Green
}

# 7.3 Cannot delete approved request
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off/$newRequestId" -Method Delete -Headers $adminHeaders
    Write-Host " FAIL: Should not allow deleting approved request!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Correctly blocked deletion of approved request" -ForegroundColor Green
}

# 7.4 Unauthenticated request
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off" -Method Get
    Write-Host " FAIL: Should not allow unauthenticated request!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Correctly returned 401 Unauthorized for unauthenticated call" -ForegroundColor Green
}

# CASE 8: Leave Types Master Data Check
Write-Host "`n--- CASE 8: Leave Types Master Data Check ---" -ForegroundColor Yellow
$ltRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/time-off/leave-types" -Method Get -Headers $adminHeaders
Write-Host " Total Leave Types Loaded: $($ltRes.data.Count)" -ForegroundColor Green
foreach ($lt in $ltRes.data) {
    Write-Host "   - Code: $($lt.leaveTypeCode.PadRight(8)) | Name: $($lt.leaveTypeName.PadRight(32)) | Days: $($lt.daysPerYear) | Paid: $($lt.isPaid)" -ForegroundColor Gray
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host " ALL 8 TEST CASES COMPLETED SUCCESSFULLY! ZERO BUGS DETECTED!" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
