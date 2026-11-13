[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$baseUrl = "http://localhost:7014"
$results = @()

function Test-Endpoint {
    param (
        [string]$Domain,
        [string]$Feature,
        [string]$CaseName,
        [string]$Method = "GET",
        [string]$Endpoint,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int]$ExpectedStatus = 200,
        [scriptblock]$Validator = $null
    )

    $status = "FAIL"
    $details = ""
    $respCode = 0
    $uri = "$baseUrl$Endpoint"

    try {
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $Headers
            ContentType = "application/json"
        }
        if ($Body -ne $null) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }

        $response = $null
        try {
            $rawResp = Invoke-WebRequest @params -UseBasicParsing
            $respCode = [int]$rawResp.StatusCode
            $response = $rawResp.Content | ConvertFrom-Json
        } catch {
            if ($_.Exception.Response) {
                $respCode = [int]$_.Exception.Response.StatusCode
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $errBody = $reader.ReadToEnd()
                try {
                    $response = $errBody | ConvertFrom-Json
                } catch {
                    $details = $errBody
                }
            } else {
                $details = $_.Exception.Message
            }
        }

        if ($respCode -eq $ExpectedStatus) {
            if ($Validator -ne $null) {
                $vRes = & $Validator $response
                if ($vRes.Passed) {
                    $status = "PASS"
                    $details = $vRes.Message
                } else {
                    $status = "FAIL"
                    $details = $vRes.Message
                }
            } else {
                $status = "PASS"
                $details = "HTTP $respCode OK"
            }
        } else {
            $status = "FAIL"
            $details = "Expected HTTP $ExpectedStatus, got $respCode. Info: $details"
        }
    } catch {
        $status = "FAIL"
        $details = "Exception: " + $_.Exception.Message
    }

    $item = [PSCustomObject]@{
        Domain = $Domain
        Feature = $Feature
        Case = $CaseName
        Method = $Method
        Endpoint = $Endpoint
        Status = $status
        Details = $details
    }

    $script:results += $item
    $icon = if ($status -eq "PASS") { "✅" } else { "❌" }
    Write-Host "$icon [$Domain] $Feature - $CaseName : $status ($details)"
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "BẮT ĐẦU CHUỖI KIỂM THỬ TẤT CẢ CÁC CHỨC NĂNG HỆ THỐNG HRM ENTERPRISE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. AUTHENTICATION & TOKEN MANAGEMENT
# -----------------------------------------------------------------------------
Write-Host "`n--- [SYS] 1. XÁC THỰC & QUẢN LÝ PHIÊN (AUTH & TOKEN) ---" -ForegroundColor Yellow

# Case 1.1: Đăng nhập sai mật khẩu -> Phải từ chối 400
Test-Endpoint -Domain "SYS" -Feature "Auth" -CaseName "Login với mật khẩu sai" `
    -Method "POST" -Endpoint "/api/sys/auth/login" `
    -Body @{ UserCode = "ADMIN"; Password = "WrongPassword@123" } `
    -ExpectedStatus 400 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $false); Message = "Từ chối đúng: $($r.message)" }
    }

# Case 1.2: Đăng nhập chuẩn Admin -> Thành công và nhận AccessToken
$loginToken = ""
Test-Endpoint -Domain "SYS" -Feature "Auth" -CaseName "Login Admin chuẩn (ADMIN / Hansol@12345)" `
    -Method "POST" -Endpoint "/api/sys/auth/login" `
    -Body @{ UserCode = "ADMIN"; Password = "Hansol@12345" } `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        if ($r.isSuccess -eq $true -and $r.data.accessToken) {
            $script:loginToken = $r.data.accessToken
            return @{ Passed = $true; Message = "Nhận JWT Token (${script:loginToken.Length} ký tự)" }
        }
        return @{ Passed = $false; Message = "Không có AccessToken trong kết quả" }
    }

$authHeader = @{ "Authorization" = "Bearer $loginToken" }

# Case 1.3: Gọi API bảo vệ không có Token -> Phải bị 401 Unauthorized
Test-Endpoint -Domain "SYS" -Feature "Auth" -CaseName "Gọi API bảo mật không có Token (Chặn 401)" `
    -Method "GET" -Endpoint "/api/sys/users/my-profile" `
    -ExpectedStatus 401 `
    -Validator {
        param($r)
        return @{ Passed = $true; Message = "Bị chặn 401 Unauthorized chuẩn xác" }
    }

# -----------------------------------------------------------------------------
# 2. PHÂN HỆ ESS (EMPLOYEE SELF-SERVICE / 1000_ESS)
# -----------------------------------------------------------------------------
Write-Host "`n--- [ESS] 2. CỔNG TỰ PHỤC VỤ NHÂN VIÊN (ESS) ---" -ForegroundColor Yellow

# Case 2.1: 1001_ESS_OVERVIEW - Tổng quan cá nhân
Test-Endpoint -Domain "ESS" -Feature "1001_ESS_OVERVIEW" -CaseName "Lấy dữ liệu tổng quan cá nhân" `
    -Method "GET" -Endpoint "/api/ess/overview" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải thông tin overview thành công" }
    }

# Case 2.2: 1002_ESS_WORK_SCHEDULE - Lịch làm việc cá nhân
Test-Endpoint -Domain "ESS" -Feature "1002_ESS_WORK_SCHEDULE" -CaseName "Lịch làm việc cá nhân tháng 11/2026" `
    -Method "GET" -Endpoint "/api/ess/work-schedule?year=2026&month=11" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải lịch làm việc thành công" }
    }

# Case 2.3: 1003_ESS_DAILY_WORK_TIME - Bảng công hàng ngày
Test-Endpoint -Domain "ESS" -Feature "1003_ESS_DAILY_WORK_TIME" -CaseName "Bảng công hàng ngày tháng 11/2026" `
    -Method "GET" -Endpoint "/api/ess/daily-work-time?fromDate=2026-11-01&toDate=2026-11-30" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải bảng công chi tiết thành công" }
    }

# Case 2.4: 1004_ESS_MEAL_ORDER - Đăng ký suất ăn cá nhân
Test-Endpoint -Domain "ESS" -Feature "1004_ESS_MEAL_ORDER" -CaseName "Thông tin đăng ký suất ăn cá nhân" `
    -Method "GET" -Endpoint "/api/ess/meal-order" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải thông tin suất ăn cá nhân thành công" }
    }

# Case 2.5: 1005_ESS_MY_PAYSLIP - Phiếu lương cá nhân
Test-Endpoint -Domain "ESS" -Feature "1005_ESS_MY_PAYSLIP" -CaseName "Xem danh mục kỳ phiếu lương của tôi" `
    -Method "GET" -Endpoint "/api/ess/my-payslip" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải phiếu lương cá nhân thành công" }
    }

# -----------------------------------------------------------------------------
# 3. PHÂN HỆ GA (GENERAL AFFAIRS / 3000_GA)
# -----------------------------------------------------------------------------
Write-Host "`n--- [GA] 3. QUẢN TRỊ HÀNH CHÍNH (GA) ---" -ForegroundColor Yellow

# Case 3.1: 3003_GA_DEPARTMENTS - Danh sách phẳng phòng ban GA
Test-Endpoint -Domain "GA" -Feature "3003_GA_DEPARTMENTS" -CaseName "Lấy danh sách phòng ban GA (dạng phẳng)" `
    -Method "GET" -Endpoint "/api/ga/departments" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count phòng ban GA" }
    }

# Case 3.2: 3003_GA_DEPARTMENTS - Danh sách cây phân cấp phòng ban GA
Test-Endpoint -Domain "GA" -Feature "3003_GA_DEPARTMENTS" -CaseName "Lấy cơ cấu cây phân cấp phòng ban GA" `
    -Method "GET" -Endpoint "/api/ga/departments/tree" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Cơ cấu Tree nạp chuẩn" }
    }

# Case 3.3: 3001_GA_MEAL_MANAGEMENT - Báo cáo suất ăn Canteen
Test-Endpoint -Domain "GA" -Feature "3001_GA_MEAL_MANAGEMENT" -CaseName "Báo cáo suất ăn Canteen ngày 12/11/2026" `
    -Method "GET" -Endpoint "/api/ga/meal-orders/admin/daily-report?date=2026-11-12" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải báo cáo Canteen thành công" }
    }

# Case 3.4: 3001_GA_MEAL_MANAGEMENT - Danh sách phòng ban nhận cơm
Test-Endpoint -Domain "GA" -Feature "3001_GA_MEAL_MANAGEMENT" -CaseName "Danh sách phòng ban đặt cơm Canteen" `
    -Method "GET" -Endpoint "/api/ga/meal-orders/departments" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count phòng ban đặt cơm" }
    }

# Case 3.5: 3001_GA_MEAL_MANAGEMENT - Tổng hợp suất ăn Canteen
Test-Endpoint -Domain "GA" -Feature "3001_GA_MEAL_MANAGEMENT" -CaseName "Tổng hợp suất ăn Canteen (canteen-summary)" `
    -Method "GET" -Endpoint "/api/ga/meal-orders/canteen-summary" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Nạp tổng hợp thành công" }
    }

# Case 3.6: 3002_GA_WORK_CALENDAR - Lịch làm việc & suất ăn tháng 11/2026
Test-Endpoint -Domain "GA" -Feature "3002_GA_WORK_CALENDAR" -CaseName "Lịch làm việc & Suất ăn tháng 11/2026" `
    -Method "GET" -Endpoint "/api/ga/work-calendar/month?year=2026&month=11" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải lịch nhà máy thành công" }
    }

# -----------------------------------------------------------------------------
# 4. PHÂN HỆ HR (HUMAN RESOURCE & CHẤM CÔNG / 2000_HR)
# -----------------------------------------------------------------------------
Write-Host "`n--- [HR] 4. QUẢN TRỊ NHÂN SỰ & CHẤM CÔNG (HR) ---" -ForegroundColor Yellow

# Case 4.1: 2001_HR_DEPARTMENTS - Danh sách phòng ban nhân sự HR
Test-Endpoint -Domain "HR" -Feature "2001_HR_DEPARTMENTS" -CaseName "Danh sách phòng ban nhân sự HR" `
    -Method "GET" -Endpoint "/api/hr/departments" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count phòng ban HR" }
    }

# Case 4.2: 2002_HR_LABOR_CONTRACTS - Danh mục hợp đồng lao động
Test-Endpoint -Domain "HR" -Feature "2002_HR_LABOR_CONTRACTS" -CaseName "Danh sách hợp đồng lao động" `
    -Method "GET" -Endpoint "/api/hr/labor-contracts" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải danh mục hợp đồng thành công" }
    }

# Case 4.3: 2003_HR_LEAVE_TYPES - Danh mục loại nghỉ phép
Test-Endpoint -Domain "HR" -Feature "2003_HR_LEAVE_TYPES" -CaseName "Danh mục các loại nghỉ phép" `
    -Method "GET" -Endpoint "/api/hr/leave-types" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count loại nghỉ phép" }
    }

# Case 4.4: 2004_HR_PAYROLL - Danh mục kỳ tính lương
Test-Endpoint -Domain "HR" -Feature "2004_HR_PAYROLL" -CaseName "Danh sách các kỳ tính lương" `
    -Method "GET" -Endpoint "/api/hr/payroll/periods" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải danh sách kỳ lương thành công" }
    }

# Case 4.5: 2005_HR_MACHINE_RECORDS - Dữ liệu quẹt thẻ BioStar
Test-Endpoint -Domain "HR" -Feature "2005_HR_MACHINE_RECORDS" -CaseName "Dữ liệu quẹt thẻ máy chấm công BioStar" `
    -Method "GET" -Endpoint "/api/hr/machine-records?pageNumber=1&pageSize=10" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải dữ liệu quẹt thẻ máy BioStar thành công" }
    }

# Case 4.6: 2006_HR_SHIFT_SETUP - Cấu hình ca kíp làm việc
Test-Endpoint -Domain "HR" -Feature "2006_HR_SHIFT_SETUP" -CaseName "Danh sách cấu hình ca kíp làm việc" `
    -Method "GET" -Endpoint "/api/hr/shift-setup" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count ca làm việc" }
    }

# Case 4.7: 2007_HR_WORK_SUMMARY - Tổng hợp giờ công
Test-Endpoint -Domain "HR" -Feature "2007_HR_WORK_SUMMARY" -CaseName "Tổng hợp giờ công tháng 11/2026" `
    -Method "GET" -Endpoint "/api/hr/work-summary?fromDate=2026-11-01&toDate=2026-11-30" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải tổng hợp bảng công thành công" }
    }

# Case 4.8: 2008_HR_TIMEOFF_REQUESTS - Danh sách đơn xin nghỉ phép
Test-Endpoint -Domain "HR" -Feature "2008_HR_TIMEOFF_REQUESTS" -CaseName "Danh sách yêu cầu xin nghỉ phép" `
    -Method "GET" -Endpoint "/api/hr/time-off" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải đơn nghỉ phép thành công" }
    }

# Case 4.9: 2009_HR_OT_REGISTRATION - Danh sách đăng ký tăng ca
Test-Endpoint -Domain "HR" -Feature "2009_HR_OT_REGISTRATION" -CaseName "Danh sách đăng ký tăng ca (OT)" `
    -Method "GET" -Endpoint "/api/hr/ot-registration" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải đăng ký OT thành công" }
    }

# Case 4.10: 2010_HR_WORK_TIME_REPORT - Báo cáo giờ công tổng hợp
Test-Endpoint -Domain "HR" -Feature "2010_HR_WORK_TIME_REPORT" -CaseName "Báo cáo giờ công nhà máy" `
    -Method "GET" -Endpoint "/api/hr/work-time-report?fromDate=2026-11-01&toDate=2026-11-12" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải báo cáo giờ công thành công" }
    }

# -----------------------------------------------------------------------------
# 5. PHÂN HỆ SYS (SYSTEM MANAGEMENT / 4000_SYS)
# -----------------------------------------------------------------------------
Write-Host "`n--- [SYS] 5. QUẢN TRỊ HỆ THỐNG (SYS) ---" -ForegroundColor Yellow

# Case 5.1: 4001_SYS_USERS - Danh sách người dùng
Test-Endpoint -Domain "SYS" -Feature "4001_SYS_USERS" -CaseName "Danh sách người dùng phân trang" `
    -Method "GET" -Endpoint "/api/sys/users?page=1&pageSize=10" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải người dùng thành công" }
    }

# Case 5.2: 4001_SYS_USERS - Thông tin cá nhân
Test-Endpoint -Domain "SYS" -Feature "4001_SYS_USERS" -CaseName "Thông tin cá nhân (my-profile)" `
    -Method "GET" -Endpoint "/api/sys/users/my-profile" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true -and $r.data.userCode -eq "ADMIN"); Message = "Tải profile Admin thành công: $($r.data.fullName)" }
    }

# Case 5.3: 4001_SYS_USERS - Danh mục phòng ban ăn cơm (Test fix mới)
Test-Endpoint -Domain "SYS" -Feature "4001_SYS_USERS" -CaseName "Dropdown phòng ban ăn cơm (GetMealDepartmentsDropdown)" `
    -Method "GET" -Endpoint "/api/sys/users/meal-departments" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -eq 22); Message = "Trả về đúng $count phòng ban ăn cơm từ GA_Departments" }
    }

# Case 5.4: 4001_SYS_USERS - Danh mục nhà máy
Test-Endpoint -Domain "SYS" -Feature "4001_SYS_USERS" -CaseName "Dropdown danh sách Nhà máy" `
    -Method "GET" -Endpoint "/api/sys/users/plants" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải danh sách nhà máy thành công" }
    }

# Case 5.5: 4002_SYS_PERMISSIONS - Danh sách nhóm quyền
Test-Endpoint -Domain "SYS" -Feature "4002_SYS_PERMISSIONS" -CaseName "Danh sách nhóm quyền (Author Groups)" `
    -Method "GET" -Endpoint "/api/sys/permission" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count nhóm quyền" }
    }

# Case 5.6: 4002_SYS_PERMISSIONS - Menu phân quyền của tôi
Test-Endpoint -Domain "SYS" -Feature "4002_SYS_PERMISSIONS" -CaseName "Lấy danh sách Menu được phân quyền (my-menu)" `
    -Method "GET" -Endpoint "/api/sys/permission/my-menu" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Admin sở hữu $count quyền màn hình" }
    }

# Case 5.7: 4003_SYS_MENUS - Quản lý 31 Menu hệ thống
Test-Endpoint -Domain "SYS" -Feature "4003_SYS_MENUS" -CaseName "Danh sách 31 Menu chương trình hệ thống" `
    -Method "GET" -Endpoint "/api/sys/program-menu" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $total = 0
        foreach ($root in $r.data) { $total += $root.children.Count }
        return @{ Passed = ($r.isSuccess -eq $true -and $total -ge 30); Message = "Cơ cấu $($r.data.Count) Root Domains và $total màn hình chi tiết" }
    }

# Case 5.8: 4004_SYS_COMMON_CODE - Danh mục mã dùng chung
Test-Endpoint -Domain "SYS" -Feature "4004_SYS_COMMON_CODE" -CaseName "Danh mục mã dùng chung (Common Code)" `
    -Method "GET" -Endpoint "/api/sys/common-code" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải danh mục mã dùng chung thành công" }
    }

# Case 5.9: 4005_SYS_AUDIT_LOGS - Nhật ký hoạt động
Test-Endpoint -Domain "SYS" -Feature "4005_SYS_AUDIT_LOGS" -CaseName "Nhật ký truy vết thao tác (Audit Logs)" `
    -Method "GET" -Endpoint "/api/sys/audit-logs?page=1&pageSize=10" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải nhật ký kiểm toán thành công" }
    }

# Case 5.10: 4006_SYS_SIGNIN_LOGS - Nhật ký đăng nhập
Test-Endpoint -Domain "SYS" -Feature "4006_SYS_SIGNIN_LOGS" -CaseName "Nhật ký đăng nhập người dùng (Sign-in Logs)" `
    -Method "GET" -Endpoint "/api/sys/sign-in-logs?page=1&pageSize=10" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải nhật ký đăng nhập thành công" }
    }

# Case 5.11: 4007_SYS_ANNOUNCEMENTS - Bảng tin thông báo
Test-Endpoint -Domain "SYS" -Feature "4007_SYS_ANNOUNCEMENTS" -CaseName "Danh sách bảng tin & thông báo toàn công ty" `
    -Method "GET" -Endpoint "/api/sys/announcements" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải bảng tin thành công" }
    }

# Case 5.12: 4008_SYS_NOTIFICATION_MATRIX - Ma trận thông báo động
Test-Endpoint -Domain "SYS" -Feature "4008_SYS_NOTIFICATION_MATRIX" -CaseName "Cấu hình ma trận thông báo động" `
    -Method "GET" -Endpoint "/api/sys/notification-matrix" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải ma trận thông báo thành công" }
    }

# Case 5.13: 4009_SYS_DEVICE_SETUP - Cấu hình máy chấm công & cổng
Test-Endpoint -Domain "SYS" -Feature "4009_SYS_DEVICE_SETUP" -CaseName "Danh sách thiết bị chấm công BioStar & cổng bảo vệ" `
    -Method "GET" -Endpoint "/api/sys/device-setup" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        $count = $r.data.Count
        return @{ Passed = ($r.isSuccess -eq $true -and $count -gt 0); Message = "Tìm thấy $count thiết bị chấm công" }
    }

# Case 5.14: Home Admin Overview
Test-Endpoint -Domain "SYS" -Feature "HomeAdmin" -CaseName "Tổng quan số liệu quản trị (Admin Dashboard)" `
    -Method "GET" -Endpoint "/api/sys/home-admin/overview" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải số liệu thống kê Dashboard thành công" }
    }

# Case 5.15: System Dashboard Stats
Test-Endpoint -Domain "SYS" -Feature "Dashboard" -CaseName "Chỉ số tình trạng hệ thống (System Stats)" `
    -Method "GET" -Endpoint "/api/sys/dashboard/stats" -Headers $authHeader `
    -ExpectedStatus 200 `
    -Validator {
        param($r)
        return @{ Passed = ($r.isSuccess -eq $true); Message = "Tải chỉ số hệ thống thành công" }
    }

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "TỔNG KẾT KẾT QUẢ KIỂM THỬ TOÀN DIỆN" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failedCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $results.Count

Write-Host "Tổng số ca kiểm thử: $totalCount"
Write-Host "✅ Thành công (PASS): $passedCount" -ForegroundColor Green
if ($failedCount -gt 0) {
    Write-Host "❌ Thất bại (FAIL): $failedCount" -ForegroundColor Red
} else {
    Write-Host "🎉 100% CÁC CA KIỂM THỬ ĐỀU ĐẠT CHUẨN XUẤT SẮC!" -ForegroundColor Green
}

$results | Format-Table Domain, Feature, Case, Status, Details -AutoSize
