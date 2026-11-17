[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " RUNNING COMPREHENSIVE TEST SUITE: ESS & HR OT MANAGEMENT" -ForegroundColor Cyan
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

function Get-SqlScalar ($sql) {
    $appSettings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
    $conn = New-Object System.Data.SqlClient.SqlConnection($appSettings.ConnectionStrings.DefaultConnection)
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sql
    $res = $cmd.ExecuteScalar()
    $conn.Close()
    return $res
}

# Ensure a clean state and base row exists in HR_WorkSummary for test dates
$sqlSetup = @"
DELETE FROM dbo.HR_OtRegistrations WHERE UserCode = '1200837' AND WorkDate IN ('2026-12-18', '2026-12-19', '2026-12-20');

IF NOT EXISTS (SELECT 1 FROM dbo.HR_WorkSummary WHERE UserCode = '1200837' AND WorkDate = '2026-12-18')
BEGIN
    INSERT INTO dbo.HR_WorkSummary (UserId, UserCode, FullName, UserGroup, WorkDate, ShiftId, WorkUnits, OtHours, Status, CreatedAt)
    VALUES (1, '1200837', N'Nguyễn Lâm Đồng', 'IT', '2026-12-18', 1, 1.0, 0, 'PRESENT', GETDATE());
END
ELSE
BEGIN
    UPDATE dbo.HR_WorkSummary SET OtHours = 0 WHERE UserCode = '1200837' AND WorkDate = '2026-12-18';
END

IF NOT EXISTS (SELECT 1 FROM dbo.HR_WorkSummary WHERE UserCode = '1200837' AND WorkDate = '2026-12-19')
BEGIN
    INSERT INTO dbo.HR_WorkSummary (UserId, UserCode, FullName, UserGroup, WorkDate, ShiftId, WorkUnits, OtHours, Status, CreatedAt)
    VALUES (1, '1200837', N'Nguyễn Lâm Đồng', 'IT', '2026-12-19', 1, 1.0, 0, 'PRESENT', GETDATE());
END
"@
& "d:\HRM\scripts\execute_sql.ps1" -sqlCommand $sqlSetup | Out-Null
Write-Host " [SETUP] Initialized dbo.HR_WorkSummary rows for 2026-12-18 & 2026-12-19." -ForegroundColor DarkGray

# ─── CASE 1: ESS Submit Valid OT Request ───────────────────────────────────────
Write-Host "`n--- CASE 1: ESS Submit OT Request (1200837 - 2.5h WEEKDAY_150) ---" -ForegroundColor Yellow
$otPayload1 = @{
    workDate = "2026-12-18"
    shiftId = 1
    plannedStartTime = "2026-12-18T17:30:00"
    plannedEndTime = "2026-12-18T20:00:00"
    plannedHours = 2.5
    otType = "WEEKDAY_150"
    reason = "Gia công đóng gói đơn hàng xuất khẩu gấp"
} | ConvertTo-Json
$otBytes1 = [System.Text.Encoding]::UTF8.GetBytes($otPayload1)
$submitRes1 = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-request" -Method Post -Body $otBytes1 -Headers $empHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($submitRes1 | ConvertTo-Json -Compress)" -ForegroundColor Green
$regId1 = [long]$submitRes1.data
if ($regId1 -le 0) {
    Write-Host " FAIL: Invalid RegistrationId returned: $regId1" -ForegroundColor Red
    exit 1
}
Write-Host " PASS: Created RegistrationId #$regId1" -ForegroundColor Green

# ─── CASE 2: ESS View Personal OT List ─────────────────────────────────────────
Write-Host "`n--- CASE 2: ESS View Personal OT List ---" -ForegroundColor Yellow
$myOtRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-list?month=2026-12" -Method Get -Headers $empHeaders
$found1 = $myOtRes.data | Where-Object { $_.registrationId -eq $regId1 }
if ($found1) {
    Write-Host " PASS: Found OT #$regId1 in ESS List: WorkDate=$($found1.workDate), Hours=$($found1.plannedHours), Status=$($found1.approvalStatus), Type=$($found1.otType)" -ForegroundColor Green
    if ($found1.approvalStatus -ne "PENDING" -or [math]::Round([double]$found1.plannedHours, 1) -ne 2.5) {
        Write-Host " FAIL: Mismatched status or planned hours!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host " FAIL: OT #$regId1 not found in ESS list!" -ForegroundColor Red
    exit 1
}

# ─── CASE 3: HR View Paged Pending OT Registrations ───────────────────────────
Write-Host "`n--- CASE 3: HR Manager View OT Registrations ---" -ForegroundColor Yellow
$hrListRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/ot-registration?approvalStatus=PENDING&fromDate=2026-12-01&toDate=2026-12-31" -Method Get -Headers $adminHeaders
$hrFound1 = $hrListRes.data | Where-Object { $_.registrationId -eq $regId1 }
if ($hrFound1) {
    Write-Host " PASS: HR retrieved OT #$($regId1): UserCode=$($hrFound1.userCode) ($($hrFound1.fullName)), Hours=$($hrFound1.plannedHours), Reason=$($hrFound1.reason)" -ForegroundColor Green
} else {
    Write-Host " FAIL: HR could not find pending OT #$regId1!" -ForegroundColor Red
    exit 1
}

# ─── CASE 4: HR Approve OT Request & WorkSummary Sync ─────────────────────────
Write-Host "`n--- CASE 4: HR Approve OT Request #$regId1 ---" -ForegroundColor Yellow
$approvePayload = @{
    registrationIds = @( $regId1 )
    comment = "Phê duyệt tăng ca đáp ứng tiến độ sản xuất xuất khẩu"
} | ConvertTo-Json
$approveBytes = [System.Text.Encoding]::UTF8.GetBytes($approvePayload)
$approveRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/ot-registration/approve" -Method Post -Body $approveBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($approveRes | ConvertTo-Json -Compress)" -ForegroundColor Green
if (-not $approveRes.isSuccess) {
    Write-Host " FAIL: Approve API returned failure!" -ForegroundColor Red
    exit 1
}

# ─── CASE 5: Verify Status & WorkSummary Sync ─────────────────────────────────
Write-Host "`n--- CASE 5: Verify Approval & dbo.HR_WorkSummary Sync ---" -ForegroundColor Yellow
$hrCheckRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/ot-registration?approvalStatus=APPROVED&fromDate=2026-12-18&toDate=2026-12-18" -Method Get -Headers $adminHeaders
$checkedItem = $hrCheckRes.data | Where-Object { $_.registrationId -eq $regId1 }
if ($checkedItem -and $checkedItem.approvalStatus -eq "APPROVED") {
    Write-Host " PASS: OT #$regId1 updated to APPROVED. ApprovedBy=$($checkedItem.approvedBy), ApprovedAt=$($checkedItem.approvedAt)" -ForegroundColor Green
} else {
    Write-Host " FAIL: OT #$regId1 is not in APPROVED status!" -ForegroundColor Red
    exit 1
}

# Verify WorkSummary sync via SQL
$checkSql = "SELECT OtHours FROM dbo.HR_WorkSummary WHERE UserCode = '1200837' AND WorkDate = '2026-12-18';"
$summaryOtHours = Get-SqlScalar $checkSql
Write-Host " DB OtHours: $summaryOtHours" -ForegroundColor DarkCyan
if ([math]::Round([double]$summaryOtHours, 1) -eq 2.5) {
    Write-Host " PASS: dbo.HR_WorkSummary.OtHours successfully synchronized to 2.5!" -ForegroundColor Green
} else {
    Write-Host " FAIL: dbo.HR_WorkSummary.OtHours was not updated to 2.5 (Current: $summaryOtHours)!" -ForegroundColor Red
    exit 1
}

# ─── CASE 6: Reject Flow ───────────────────────────────────────────────────────
Write-Host "`n--- CASE 6: Employee Submits 2nd OT & HR Rejects ---" -ForegroundColor Yellow
$otPayload2 = @{
    workDate = "2026-12-19"
    shiftId = 1
    plannedStartTime = "2026-12-19T18:00:00"
    plannedEndTime = "2026-12-19T21:00:00"
    plannedHours = 3.0
    otType = "WEEKEND_200"
    reason = "Bảo trì nâng cấp hệ thống dây chuyền chuyền 1"
} | ConvertTo-Json
$otBytes2 = [System.Text.Encoding]::UTF8.GetBytes($otPayload2)
$submitRes2 = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-request" -Method Post -Body $otBytes2 -Headers $empHeaders -ContentType "application/json; charset=utf-8"
$regId2 = [long]$submitRes2.data
Write-Host " Created 2nd OT #$regId2" -ForegroundColor Green

# HR Rejects OT #$regId2
$rejectPayload = @{
    registrationIds = @( $regId2 )
    comment = "Không đủ nhân lực giám sát an toàn ca tối, đề nghị dời lịch sang sáng chủ nhật"
} | ConvertTo-Json
$rejectBytes = [System.Text.Encoding]::UTF8.GetBytes($rejectPayload)
$rejectRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/ot-registration/reject" -Method Post -Body $rejectBytes -Headers $adminHeaders -ContentType "application/json; charset=utf-8"
Write-Host " Result: $($rejectRes | ConvertTo-Json -Compress)" -ForegroundColor Green

$hrCheckReject = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/ot-registration?approvalStatus=REJECTED&fromDate=2026-12-19&toDate=2026-12-19" -Method Get -Headers $adminHeaders
$rejectedItem = $hrCheckReject.data | Where-Object { $_.registrationId -eq $regId2 }
if ($rejectedItem -and $rejectedItem.approvalStatus -eq "REJECTED") {
    Write-Host " PASS: OT #$regId2 rejected successfully. ApproverComment=$($rejectedItem.approverComment)" -ForegroundColor Green
} else {
    Write-Host " FAIL: OT #$regId2 was not rejected properly!" -ForegroundColor Red
    exit 1
}

# Verify WorkSummary has OtHours = 0 for 2026-12-19
$checkSql2 = "SELECT OtHours FROM dbo.HR_WorkSummary WHERE UserCode = '1200837' AND WorkDate = '2026-12-19';"
$summaryOtHours2 = Get-SqlScalar $checkSql2
Write-Host " DB OtHours for 2026-12-19: $summaryOtHours2" -ForegroundColor DarkCyan
if ([math]::Round([double]$summaryOtHours2, 1) -eq 0.0) {
    Write-Host " PASS: dbo.HR_WorkSummary.OtHours remains 0.0 for rejected OT!" -ForegroundColor Green
} else {
    Write-Host " FAIL: dbo.HR_WorkSummary.OtHours unexpected value (Current: $summaryOtHours2)!" -ForegroundColor Red
    exit 1
}

# ─── CASE 7: Validation & Boundary Tests ───────────────────────────────────────
Write-Host "`n--- CASE 7: Boundary & Validation Tests ---" -ForegroundColor Yellow

# 7.1 Negative / Zero Hours
try {
    $badHoursPayload = @{
        workDate = "2026-12-20"
        shiftId = 1
        plannedStartTime = "2026-12-20T18:00:00"
        plannedEndTime = "2026-12-20T20:00:00"
        plannedHours = 0
        otType = "WEEKDAY_150"
        reason = "Test zero hours"
    } | ConvertTo-Json
    $badHoursBytes = [System.Text.Encoding]::UTF8.GetBytes($badHoursPayload)
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-request" -Method Post -Body $badHoursBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
    Write-Host " FAIL: Zero hours should have thrown 400 Bad Request!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Zero hours correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.2 Inverted start/end time
try {
    $badTimePayload = @{
        workDate = "2026-12-20"
        shiftId = 1
        plannedStartTime = "2026-12-20 20:00:00"
        plannedEndTime = "2026-12-20 18:00:00"
        plannedHours = 2.0
        otType = "WEEKDAY_150"
        reason = "Test inverted time"
    } | ConvertTo-Json
    $badTimeBytes = [System.Text.Encoding]::UTF8.GetBytes($badTimePayload)
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-request" -Method Post -Body $badTimeBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
    Write-Host " FAIL: Inverted time should have thrown 400 Bad Request!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Inverted time correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.3 Empty reason
try {
    $badReasonPayload = @{
        workDate = "2026-12-20"
        shiftId = 1
        plannedStartTime = "2026-12-20T18:00:00"
        plannedEndTime = "2026-12-20T20:00:00"
        plannedHours = 2.0
        otType = "WEEKDAY_150"
        reason = ""
    } | ConvertTo-Json
    $badReasonBytes = [System.Text.Encoding]::UTF8.GetBytes($badReasonPayload)
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-request" -Method Post -Body $badReasonBytes -Headers $empHeaders -ContentType "application/json; charset=utf-8"
    Write-Host " FAIL: Empty reason should have thrown 400 Bad Request!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Empty reason correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

# 7.4 Unauthenticated request
try {
    Invoke-RestMethod -Uri "http://localhost:7014/api/ess/work-schedule/ot-list" -Method Get
    Write-Host " FAIL: Unauthenticated request should have thrown 401 Unauthorized!" -ForegroundColor Red
    exit 1
} catch {
    Write-Host " PASS: Unauthenticated request correctly rejected ($($_.Exception.Message))" -ForegroundColor Green
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host " ALL OT MANAGEMENT TESTS COMPLETED SUCCESSFULLY! (ZERO ERRORS)" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
