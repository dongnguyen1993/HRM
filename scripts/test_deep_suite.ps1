[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$baseUrl = "http://localhost:7014"
$proxyUrl = "http://localhost:8000"

$passed = 0
$failed = 0
$total = 0

function Test-Endpoint {
    param(
        [string]$Category,
        [string]$Description,
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers,
        [object]$Body = $null,
        [int]$ExpectedStatusCode = 200,
        [scriptblock]$CustomValidation = $null
    )
    $script:total++
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            UseBasicParsing = $true
            TimeoutSec = 15
        }
        if ($Headers) { $params.Headers = $Headers }
        if ($Body) {
            if ($Body -is [string]) {
                $params.Body = $Body
            } else {
                $params.Body = ($Body | ConvertTo-Json -Depth 5)
            }
            $params.ContentType = "application/json"
        }

        $response = $null
        try {
            $response = Invoke-RestMethod @params
            $actualStatus = 200
        } catch {
            if ($_.Exception.Response) {
                $actualStatus = [int]$_.Exception.Response.StatusCode
            } else {
                $actualStatus = 500
            }
            $response = $_
        }

        $isOk = $false
        $detail = ""

        if ($actualStatus -eq $ExpectedStatusCode) {
            if ($CustomValidation) {
                $customOk = & $CustomValidation $response
                if ($customOk) {
                    $isOk = $true
                    $detail = "Custom validation passed."
                } else {
                    $isOk = $false
                    $detail = "Custom validation failed."
                }
            } else {
                $isOk = $true
                $detail = "Status code $actualStatus matched."
            }
        } else {
            $isOk = $false
            $detail = "Expected $ExpectedStatusCode but got $actualStatus."
        }

        if ($isOk) {
            $script:passed++
            Write-Host "  [✓ PASS] [$Category] $Description - $detail" -ForegroundColor Green
        } else {
            $script:failed++
            Write-Host "  [✗ FAIL] [$Category] $Description - $detail" -ForegroundColor Red
        }
    } catch {
        $script:failed++
        Write-Host "  [✗ FAIL] [$Category] $Description - Exception: $_" -ForegroundColor Red
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   KIỂM THỬ CHUYÊN SÂU TOÀN DIỆN HỆ THỐNG HRM (75 TEST CASES)    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# -------------------------------------------------------------
# 1. AUTHENTICATION & SECURITY CASES
# -------------------------------------------------------------
Write-Host "`n--- 1. BẢO MẬT & XÁC THỰC (AUTH) ---" -ForegroundColor Yellow

$token = ""
Test-Endpoint "AUTH" "Đăng nhập hợp lệ với ADMIN" "POST" "$baseUrl/api/sys/auth/login" $null @{ userCode = "ADMIN"; password = "Hansol@12345" } 200 {
    param($r)
    if ($r.isSuccess -and $r.data.accessToken) {
        $script:token = $r.data.accessToken
        return $true
    }
    return $false
}

$authHeader = @{ Authorization = "Bearer $token" }

Test-Endpoint "AUTH" "Đăng nhập sai mật khẩu" "POST" "$baseUrl/api/sys/auth/login" $null @{ userCode = "ADMIN"; password = "WrongPassword@999" } 400
Test-Endpoint "AUTH" "Đăng nhập để trống userCode" "POST" "$baseUrl/api/sys/auth/login" $null @{ userCode = ""; password = "Hansol@12345" } 400
Test-Endpoint "AUTH" "Đăng nhập tài khoản không tồn tại" "POST" "$baseUrl/api/sys/auth/login" $null @{ userCode = "GHOST_USER_999"; password = "Hansol@12345" } 400
Test-Endpoint "AUTH" "Truy cập API bảo vệ không có Token" "GET" "$baseUrl/api/sys/users" $null $null 401
Test-Endpoint "AUTH" "Truy cập API với Token rác / giả mạo" "GET" "$baseUrl/api/sys/users" @{ Authorization = "Bearer InvalidFakeTokenXYZ" } $null 401

# -------------------------------------------------------------
# 2. PHÂN HỆ CỔNG TỰ PHỤC VỤ (ESS - 1000_ESS)
# -------------------------------------------------------------
Write-Host "`n--- 2. PHÂN HỆ ESS (CỔNG TỰ PHỤC VỤ NHÂN VIÊN) ---" -ForegroundColor Yellow

Test-Endpoint "ESS" "1001: Thống kê User Overview" "GET" "$baseUrl/api/ess/overview/overview" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.profile.fullName)
}

Test-Endpoint "ESS" "1001: Tự ghi nhận Check-in (Self Punch)" "POST" "$baseUrl/api/ess/overview/punch" $authHeader @{ punchType = "IN" } 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1002: Lịch làm việc cá nhân tổng quan" "GET" "$baseUrl/api/ess/work-schedule/overview" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1002: Danh mục loại phép cá nhân" "GET" "$baseUrl/api/ess/work-schedule/leave-types" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "ESS" "1003: Bảng công hàng ngày tháng 11/2026" "GET" "$baseUrl/api/ess/daily-work-time?fromDate=2026-11-01&toDate=2026-11-30" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1004: Ngữ cảnh đặt cơm phòng ban (Meal Context)" "GET" "$baseUrl/api/ess/meal-order/context?date=2026-11-03" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1004: Danh sách đặt cơm phòng ban tháng 11/2026" "GET" "$baseUrl/api/ess/meal-order/my-department?month=2026-11" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1004: Tổng hợp suất ăn Canteen ngày 03/11/2026" "GET" "$baseUrl/api/ess/meal-order/canteen-summary?date=2026-11-03" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1005: Danh sách kỳ lương đã công bố" "GET" "$baseUrl/api/ess/my-payslip/periods" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -ge 0)
}

Test-Endpoint "ESS" "1005: Chi tiết phiếu lương kỳ 2026-08" "GET" "$baseUrl/api/ess/my-payslip?periodId=2026-08" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "ESS" "1006: Danh sách đăng ký khách vào cổng (phân trang)" "GET" "$baseUrl/api/ga/visitor-registrations?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -ge 0)
}

Test-Endpoint "ESS" "1006: Dropdown phòng ban đăng ký khách" "GET" "$baseUrl/api/ga/visitor-registrations/departments" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "ESS" "1006: Chi tiết phiếu đăng ký khách ID 1" "GET" "$baseUrl/api/ga/visitor-registrations/1" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.id -eq 1)
}

Test-Endpoint "ESS" "1006: Tra cứu phiếu khách ID không tồn tại (999999)" "GET" "$baseUrl/api/ga/visitor-registrations/999999" $authHeader $null 404

# -------------------------------------------------------------
# 3. PHÂN HỆ QUẢN TRỊ HÀNH CHÍNH (GA - 3000_GA)
# -------------------------------------------------------------
Write-Host "`n--- 3. PHÂN HỆ GA (QUẢN TRỊ HÀNH CHÍNH) ---" -ForegroundColor Yellow

Test-Endpoint "GA" "3001: Báo cáo suất ăn theo ngày (Admin Daily Report)" "GET" "$baseUrl/api/ga/meal-orders/admin/daily-report?date=2026-11-03" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "GA" "3001: Danh sách phòng ban đặt cơm GA" "GET" "$baseUrl/api/ga/meal-orders/departments" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "GA" "3001: Đơn đặt cơm phòng ban DEPT_GA tháng 11/2026" "GET" "$baseUrl/api/ga/meal-orders/my-department?departmentCode=DEPT_GA&month=2026-11" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "GA" "3002: Lịch làm việc & suất ăn tháng 11/2026" "GET" "$baseUrl/api/ga/work-calendar/month?year=2026&month=11" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -eq 30)
}

Test-Endpoint "GA" "3003: Danh sách phòng ban GA dạng phẳng" "GET" "$baseUrl/api/ga/departments" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "GA" "3003: Cây cơ cấu phòng ban GA (Tree)" "GET" "$baseUrl/api/ga/departments/tree" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "GA" "3005: Danh sách duyệt khách trạng thái PENDING" "GET" "$baseUrl/api/ga/visitor-registrations?status=PENDING&pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.pageNumber -eq 1)
}

Test-Endpoint "GA" "3006: Kiểm soát Cổng bảo vệ hôm nay" "GET" "$baseUrl/api/ga/visitor-registrations/gate/today" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "GA" "3006: Danh sách tài sản khách tại cổng" "GET" "$baseUrl/api/ga/visitor-registrations/items?detailId=1" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

# -------------------------------------------------------------
# 4. PHÂN HỆ QUẢN TRỊ NHÂN SỰ & CHẤM CÔNG (HR - 2000_HR)
# -------------------------------------------------------------
Write-Host "`n--- 4. PHÂN HỆ HR (QUẢN TRỊ NHÂN SỰ & CHẤM CÔNG) ---" -ForegroundColor Yellow

Test-Endpoint "HR" "2001: Cây cơ cấu phòng ban HR" "GET" "$baseUrl/api/hr/departments/tree" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "HR" "2001: Danh sách phòng ban HR phẳng" "GET" "$baseUrl/api/hr/departments/list" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "HR" "2002: Hợp đồng lao động phân trang" "GET" "$baseUrl/api/hr/labor-contracts?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -ge 0)
}

Test-Endpoint "HR" "2002: Tìm kiếm hợp đồng với keyword 'ADMIN'" "GET" "$baseUrl/api/hr/labor-contracts?keyword=ADMIN&pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "HR" "2003: Danh mục các loại nghỉ phép" "GET" "$baseUrl/api/hr/leave-types?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -ge 0)
}

Test-Endpoint "HR" "2004: Danh sách kỳ lương nhà máy" "GET" "$baseUrl/api/hr/payroll/periods" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "HR" "2004: Chi tiết danh sách nhân viên kỳ lương 2026-08" "GET" "$baseUrl/api/hr/payroll/periods/2026-08/employees" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "HR" "2005: Thiết lập ca làm việc phân trang" "GET" "$baseUrl/api/hr/shift-setup?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -ge 0)
}

Test-Endpoint "HR" "2005: Danh sách ca làm việc đang hoạt động" "GET" "$baseUrl/api/hr/shift-setup/active" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "HR" "2006: Đơn xin nghỉ phép phân trang" "GET" "$baseUrl/api/hr/time-off?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -ge 0)
}

Test-Endpoint "HR" "2006: Thống kê đơn nghỉ phép" "GET" "$baseUrl/api/hr/time-off/statistics" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "HR" "2006: Danh mục loại phép cho đơn nghỉ" "GET" "$baseUrl/api/hr/time-off/leave-types" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "HR" "2007: Đăng ký tăng ca (OT) phân trang" "GET" "$baseUrl/api/hr/ot-registration?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -ge 0)
}

Test-Endpoint "HR" "2007: Thống kê đăng ký tăng ca (OT)" "GET" "$baseUrl/api/hr/ot-registration/statistics" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "HR" "2008: Dữ liệu quẹt thẻ BioStar phân trang" "GET" "$baseUrl/api/hr/machine-records?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 1000)
}

Test-Endpoint "HR" "2008: Lọc quẹt thẻ BioStar theo mã nhân viên '1200493'" "GET" "$baseUrl/api/hr/machine-records?userCode=1200493&pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "HR" "2009: Tổng hợp giờ công nhân viên phân trang" "GET" "$baseUrl/api/hr/work-summary?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "HR" "2009: Thống kê tổng hợp giờ công" "GET" "$baseUrl/api/hr/work-summary/statistics" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "HR" "2010: Báo cáo giờ công tổng hợp phân trang" "GET" "$baseUrl/api/hr/work-time-report?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "HR" "2010: Báo cáo tóm tắt giờ công (Summary Stats)" "GET" "$baseUrl/api/hr/work-time-report/stats" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "HR" "2010: Báo cáo ma trận công theo tháng (Monthly Matrix)" "GET" "$baseUrl/api/hr/work-time-report/matrix?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

# -------------------------------------------------------------
# 5. PHÂN HỆ QUẢN TRỊ HỆ THỐNG (SYS - 4000_SYS)
# -------------------------------------------------------------
Write-Host "`n--- 5. PHÂN HỆ SYS (QUẢN TRỊ HỆ THỐNG) ---" -ForegroundColor Yellow

Test-Endpoint "SYS" "4001: Danh sách tài khoản người dùng phân trang" "GET" "$baseUrl/api/sys/users?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "SYS" "4001: Danh sách các nhà máy (Plants)" "GET" "$baseUrl/api/sys/users/plants" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4001: Chức vụ quản lý (Positions Role)" "GET" "$baseUrl/api/sys/users/positions?type=ROLE" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4001: Cấp bậc chuyên môn (Positions Grade)" "GET" "$baseUrl/api/sys/users/positions?type=GRADE" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4001: Dropdown phòng ban trực thuộc" "GET" "$baseUrl/api/sys/users/departments" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4001: Dropdown phòng ban ăn cơm" "GET" "$baseUrl/api/sys/users/meal-departments" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4002: Danh sách nhóm quyền hệ thống" "GET" "$baseUrl/api/sys/permission/groups" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4002: Ma trận phân quyền của nhóm 1 (Admin)" "GET" "$baseUrl/api/sys/permission/groups/1" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4002: Cây menu động phân quyền của tôi" "GET" "$baseUrl/api/sys/permission/my-menu" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4003: Cây menu quản trị hệ thống (Tree)" "GET" "$baseUrl/api/sys/program-menu/tree" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -eq 4)
}

Test-Endpoint "SYS" "4004: Danh mục các nhóm mã dùng chung" "GET" "$baseUrl/api/sys/common-code/groups" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4004: Danh sách mã dùng chung phân trang" "GET" "$baseUrl/api/sys/common-code?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "SYS" "4005: Nhật ký hoạt động (Audit Logs)" "GET" "$baseUrl/api/sys/audit-logs?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "SYS" "4006: Nhật ký đăng nhập (Sign-in Logs)" "GET" "$baseUrl/api/sys/sign-in-logs?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "SYS" "4007: Thiết bị máy chấm công (Device Setup)" "GET" "$baseUrl/api/sys/device-setup?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "SYS" "4007: Danh sách nhóm thiết bị chấm công" "GET" "$baseUrl/api/sys/device-setup/groups" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4008: Bảng tin thông báo hệ thống" "GET" "$baseUrl/api/sys/announcements?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.totalRecords -gt 0)
}

Test-Endpoint "SYS" "4008: Bảng tin thông báo đang hoạt động" "GET" "$baseUrl/api/sys/announcements/active?topCount=5" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4009: Danh sách sự kiện ma trận thông báo động" "GET" "$baseUrl/api/sys/notification-matrix/events" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -gt 0)
}

Test-Endpoint "SYS" "4009: Danh sách thông báo in-app của nhân viên" "GET" "$baseUrl/api/sys/notifications/my-notifications?page=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "SYS" "Cấu hình hệ thống chung (System Settings)" "GET" "$baseUrl/api/sys/system-settings" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "SYS" "Thống kê tổng quan Home Admin Overview" "GET" "$baseUrl/api/sys/home-admin/overview" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "SYS" "Thống kê biểu đồ Admin Dashboard" "GET" "$baseUrl/api/sys/dashboard/admin-stats" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

# -------------------------------------------------------------
# 6. REVERSE PROXY FRONTEND (PORT 8000 -> BACKEND 7014)
# -------------------------------------------------------------
Write-Host "`n--- 6. KIỂM THỬ REVERSE PROXY (FRONTEND :8000) ---" -ForegroundColor Yellow

Test-Endpoint "PROXY" "Reverse Proxy Cây Menu (/api/sys/program-menu/tree)" "GET" "$proxyUrl/api/sys/program-menu/tree" $authHeader $null 200 {
    param($r)
    return ($r.isSuccess -and $r.data.Count -eq 4)
}

Test-Endpoint "PROXY" "Reverse Proxy Đăng ký khách (/api/ga/visitor-registrations)" "GET" "$proxyUrl/api/ga/visitor-registrations?pageNumber=1&pageSize=5" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "PROXY" "Reverse Proxy Lịch làm việc ESS (/api/ess/work-schedule/overview)" "GET" "$proxyUrl/api/ess/work-schedule/overview" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

Test-Endpoint "PROXY" "Reverse Proxy Cơ cấu phòng ban HR (/api/hr/departments/tree)" "GET" "$proxyUrl/api/hr/departments/tree" $authHeader $null 200 {
    param($r)
    return $r.isSuccess
}

# -------------------------------------------------------------
# TỔNG KẾT
# -------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    TỔNG KẾT KẾT QUẢ KIỂM THỬ                   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Tổng số ca kiểm thử (Test Cases): $total"
Write-Host "Thành công (PASS):                $passed" -ForegroundColor Green
Write-Host "Thất bại (FAIL):                  $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
$rate = [Math]::Round(($passed / $total) * 100, 2)
Write-Host "Tỉ lệ hoàn thành:                 $rate%" -ForegroundColor $(if ($rate -eq 100) { "Green" } else { "Yellow" })
Write-Host "=================================================================`n" -ForegroundColor Cyan
