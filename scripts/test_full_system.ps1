[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   KIỂM THỬ TOÀN DIỆN HỆ THỐNG SAU TÁI CẤU TRÚC 4 DOMAIN        " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$baseUrl = "http://localhost:7014"
$feUrl = "http://localhost:8000"

$testResults = [System.Collections.Generic.List[PSCustomObject]]::new()

function Record-Test($domain, $feature, $endpoint, $method, $passed, $details) {
    $testResults.Add([PSCustomObject]@{
        Domain   = $domain
        Feature  = $feature
        Endpoint = $endpoint
        Method   = $method
        Status   = if ($passed) { "PASS" } else { "FAIL" }
        Details  = $details
    })
    $color = if ($passed) { "Green" } else { "Red" }
    $mark = if ($passed) { "[✓ PASS]" } else { "[✗ FAIL]" }
    Write-Host "$mark [$domain] $feature ($endpoint) - $details" -ForegroundColor $color
}

# 1. ĐĂNG NHẬP & LẤY TOKEN
Write-Host "`n--- 1. XÁC THỰC HỆ THỐNG (AUTH) ---" -ForegroundColor Yellow
$loginBody = @{ userCode = "ADMIN"; password = "Hansol@12345" } | ConvertTo-Json
try {
    $auth = Invoke-RestMethod -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $auth.data.accessToken
    Record-Test "SYS" "Login / Authentication" "/api/sys/auth/login" "POST" $true "Token acquired, User: $($auth.data.fullName)"
} catch {
    Record-Test "SYS" "Login / Authentication" "/api/sys/auth/login" "POST" $false "$_"
    exit 1
}

$headers = @{ "Authorization" = "Bearer $token" }

# Helper GET test
function Test-ApiGet($domain, $feature, $path, $conditionScript, $successMsg) {
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl$path" -Method Get -Headers $headers
        $ok = & $conditionScript $res
        $details = & $successMsg $res
        Record-Test $domain $feature $path "GET" $ok $details
    } catch {
        Record-Test $domain $feature $path "GET" $false "$_"
    }
}

# Helper POST test
function Test-ApiPost($domain, $feature, $path, $body, $conditionScript, $successMsg) {
    try {
        $json = $body | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "$baseUrl$path" -Method Post -Body $json -ContentType "application/json" -Headers $headers
        $ok = & $conditionScript $res
        $details = & $successMsg $res
        Record-Test $domain $feature $path "POST" $ok $details
    } catch {
        Record-Test $domain $feature $path "POST" $false "$_"
    }
}

# ==========================================
# 2. DOMAIN ESS (CỔNG TỰ PHỤC VỤ)
# ==========================================
Write-Host "`n--- 2. KIỂM THỬ PHÂN HỆ ESS (1000_ESS) ---" -ForegroundColor Yellow

Test-ApiGet "ESS" "User Overview (New)" "/api/ess/overview/overview" { param($r) $r.isSuccess } { param($r) "User: $($r.data.profile.fullName), KPI: $($r.data.kpiStats.totalWorkUnits) công" }
Test-ApiGet "ESS" "User Overview (Legacy)" "/api/home/personal/overview" { param($r) $r.isSuccess } { param($r) "User: $($r.data.profile.fullName)" }

Test-ApiPost "ESS" "Self Punch (Check-In)" "/api/ess/overview/punch" @{ punchType = "IN" } { param($r) $r.isSuccess } { param($r) $r.message }
Test-ApiPost "ESS" "Self Punch (Legacy)" "/api/home/personal/punch" @{ punchType = "IN" } { param($r) $r.isSuccess } { param($r) $r.message }

Test-ApiGet "ESS" "Meal Order Context" "/api/meal-orders/context?date=2026-11-03" { param($r) $r.isSuccess } { param($r) "Dept: $($r.data.departmentCode), CanOrder: $($r.data.canOrder)" }
Test-ApiGet "ESS" "My Dept Monthly Orders" "/api/meal-orders/my-department?month=2026-11" { param($r) $r.isSuccess } { param($r) "Total orders: $($r.data.Count)" }
Test-ApiGet "ESS" "Canteen Daily Summary" "/api/meal-orders/canteen-summary?date=2026-11-03" { param($r) $r.isSuccess } { param($r) "Canteen summary records: $($r.data.Count)" }

Test-ApiGet "ESS" "My Payslip Published Periods" "/api/ess/my-payslip/periods" { param($r) $r.isSuccess } { param($r) "Published periods: $($r.data.Count)" }
Test-ApiGet "ESS" "My Payslip Periods (Legacy)" "/api/self-service/my-payslip/periods" { param($r) $r.isSuccess } { param($r) "Published periods: $($r.data.Count)" }

# ==========================================
# 3. DOMAIN HR (NHÂN SỰ & CHẤM CÔNG)
# ==========================================
Write-Host "`n--- 3. KIỂM THỬ PHÂN HỆ HR (2000_HR) ---" -ForegroundColor Yellow

Test-ApiGet "HR" "Cơ cấu phòng ban (Tree)" "/api/hr/departments/tree" { param($r) $r.isSuccess } { param($r) "Root nodes: $($r.data.Count)" }
Test-ApiGet "HR" "Danh sách phòng ban (List)" "/api/hr/departments/list" { param($r) $r.isSuccess } { param($r) "Departments count: $($r.data.Count)" }
Test-ApiGet "HR" "Phòng ban (Legacy)" "/api/departments/tree" { param($r) $r.isSuccess } { param($r) "Root nodes: $($r.data.Count)" }

Test-ApiGet "HR" "Hợp đồng lao động" "/api/hr/labor-contracts?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total records: $($r.totalRecords)" }
Test-ApiGet "HR" "Danh mục loại phép" "/api/hr/leave-types?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total records: $($r.totalRecords)" }

Test-ApiGet "HR" "Kỳ lương nhà máy (Periods)" "/api/hr/payroll/periods" { param($r) $r.isSuccess } { param($r) "Periods: $($r.data.Count)" }
Test-ApiGet "HR" "Kỳ lương (Legacy)" "/api/payroll/periods" { param($r) $r.isSuccess } { param($r) "Periods: $($r.data.Count)" }

Test-ApiGet "HR" "Dữ liệu quẹt thẻ BioStar" "/api/hr/machine-records?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total records: $($r.totalRecords)" }
Test-ApiGet "HR" "Thiết lập ca làm việc" "/api/hr/shift-setup?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total shifts: $($r.totalRecords)" }
Test-ApiGet "HR" "Đơn xin nghỉ phép" "/api/hr/time-off?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total requests: $($r.totalRecords)" }
Test-ApiGet "HR" "Đăng ký tăng ca" "/api/hr/ot-registration?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total registrations: $($r.totalRecords)" }
Test-ApiGet "HR" "Tổng hợp giờ công" "/api/hr/work-summary?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total summaries: $($r.totalRecords)" }
Test-ApiGet "HR" "Báo cáo giờ công" "/api/hr/work-time-report?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total reports: $($r.totalRecords)" }

# ==========================================
# 4. DOMAIN GA (HÀNH CHÍNH & SUẤT ĂN)
# ==========================================
Write-Host "`n--- 4. KIỂM THỬ PHÂN HỆ GA (3000_GA) ---" -ForegroundColor Yellow

Test-ApiGet "GA" "Cơ cấu phòng ban GA (Tree)" "/api/ga/departments/tree" { param($r) $r.isSuccess } { param($r) "Root GA: $($r.data[0].departmentName), Con: $($r.data[0].children.Count)" }
Test-ApiGet "GA" "Phòng ban GA phẳng" "/api/ga/departments" { param($r) $r.isSuccess } { param($r) "GA Depts: $($r.data.Count)" }
Test-ApiGet "GA" "Phòng ban GA (Legacy)" "/api/ga-departments" { param($r) $r.isSuccess } { param($r) "GA Depts: $($r.data.Count)" }

Test-ApiGet "GA" "Lịch làm việc & suất ăn tháng" "/api/ga/work-calendar/month?year=2026&month=11" { param($r) $r.isSuccess } { param($r) "Days in month: $($r.data.Count)" }
Test-ApiGet "GA" "Lịch làm việc (Legacy)" "/api/work-calendar/month?year=2026&month=11" { param($r) $r.isSuccess } { param($r) "Days in month: $($r.data.Count)" }

Test-ApiGet "GA" "Danh sách phòng ban đặt cơm" "/api/ga/meal-orders/departments" { param($r) $r.isSuccess } { param($r) "Meal depts: $($r.data.Count)" }
Test-ApiGet "GA" "Phòng ban đặt cơm (Legacy)" "/api/meal-orders/departments" { param($r) $r.isSuccess } { param($r) "Meal depts: $($r.data.Count)" }
Test-ApiGet "GA" "Báo cáo suất ăn theo ngày" "/api/ga/meal-orders/admin/daily-report?date=2026-11-03" { param($r) $r.isSuccess } { param($r) "Report fetched successfully" }

# ==========================================
# 5. DOMAIN SYS (QUẢN TRỊ HỆ THỐNG)
# ==========================================
Write-Host "`n--- 5. KIỂM THỬ PHÂN HỆ SYS (4000_SYS) ---" -ForegroundColor Yellow

Test-ApiGet "SYS" "Danh sách người dùng" "/api/sys/users?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total users: $($r.totalRecords)" }
Test-ApiGet "SYS" "Nhóm quyền & phân quyền" "/api/sys/permission/groups" { param($r) $r.isSuccess } { param($r) "Groups count: $($r.data.Count)" }
Test-ApiGet "SYS" "Cây menu hệ thống (Tree)" "/api/sys/program-menu/tree" { param($r) $r.isSuccess } { param($r) "Domains count: $($r.data.Count)" }
Test-ApiGet "SYS" "Nhóm mã dùng chung" "/api/sys/common-code/groups" { param($r) $r.isSuccess } { param($r) "Groups count: $($r.data.Count)" }
Test-ApiGet "SYS" "Mã dùng chung phân trang" "/api/sys/common-code?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total codes: $($r.totalRecords)" }
Test-ApiGet "SYS" "Bảng tin & Thông báo" "/api/sys/announcements?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total announcements: $($r.totalRecords)" }
Test-ApiGet "SYS" "Nhật ký hoạt động (Audit Logs)" "/api/sys/audit-logs?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total audit logs: $($r.totalRecords)" }
Test-ApiGet "SYS" "Nhật ký đăng nhập (Sign-in)" "/api/sys/sign-in-logs?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total sign-in logs: $($r.totalRecords)" }
Test-ApiGet "SYS" "Thiết bị máy chấm công" "/api/sys/device-setup?pageNumber=1&pageSize=5" { param($r) $r.isSuccess } { param($r) "Total devices: $($r.totalRecords)" }
Test-ApiGet "SYS" "Thống kê Admin Dashboard" "/api/sys/home-admin/overview" { param($r) $r.isSuccess } { param($r) "Total employees: $($r.data.employees.totalEmployees)" }
Test-ApiGet "SYS" "Ma trận thông báo động" "/api/sys/notification-matrix/events" { param($r) $r.isSuccess } { param($r) "Events: $($r.data.Count)" }
Test-ApiGet "SYS" "Thông báo cá nhân" "/api/sys/notifications/my-notifications" { param($r) $r.isSuccess } { param($r) "Notifications fetched" }

# ==========================================
# 6. KIỂM THỬ PROXY FRONTEND (PORT 8000 -> 7014)
# ==========================================
Write-Host "`n--- 6. KIỂM THỬ REVERSE PROXY FRONTEND ---" -ForegroundColor Yellow
try {
    $feTree = Invoke-RestMethod -Uri "$feUrl/api/sys/program-menu/tree" -Method Get -Headers $headers
    Record-Test "PROXY" "Reverse Proxy (FE -> BE)" "$feUrl/api/sys/program-menu/tree" "GET" ($feTree.isSuccess) "Proxied successfully through Frontend port 8000"
} catch {
    Record-Test "PROXY" "Reverse Proxy (FE -> BE)" "$feUrl/api/sys/program-menu/tree" "GET" $false "$_"
}

# ==========================================
# 7. TỔNG KẾT BÁO CÁO
# ==========================================
$totalTests = $testResults.Count
$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$passRate = [math]::Round(($passCount / $totalTests) * 100, 1)

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    TỔNG KẾT KẾT QUẢ KIỂM THỬ                   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Tổng số ca kiểm thử (Test Cases): $totalTests"
Write-Host "Thành công (PASS):                $passCount" -ForegroundColor Green
Write-Host "Thất bại (FAIL):                  $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "Tỉ lệ hoàn thành:                 $passRate%" -ForegroundColor Cyan