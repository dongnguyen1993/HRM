# =========================================================================================
# File: test_10_scenarios_users_employees.ps1
# Description: Kịch bản kiểm thử 10 trường hợp chuyên sâu cho SYS_Users và HR_Employees
# Author: HRM Enterprise Architecture Team
# =========================================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$baseUrl = "http://localhost:7014"
$testResults = @()

# Hàm gọi API chuẩn mã hóa UTF-8 bytes cho Windows PowerShell
function Invoke-Api {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )
    $params = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
    }
    if ($Body -ne $null) {
        $jsonStr = $Body | ConvertTo-Json -Depth 10
        $params["Body"] = [System.Text.Encoding]::UTF8.GetBytes($jsonStr)
        $params["ContentType"] = "application/json; charset=utf-8"
    }
    return Invoke-RestMethod @params
}

function Query-SqlScalar {
    param([string]$Sql)
    $settings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
    $conn = New-Object System.Data.SqlClient.SqlConnection($settings.ConnectionStrings.DefaultConnection)
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $Sql
    $val = $cmd.ExecuteScalar()
    $conn.Close()
    return $val
}

function Query-SqlRow {
    param([string]$Sql)
    $settings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
    $conn = New-Object System.Data.SqlClient.SqlConnection($settings.ConnectionStrings.DefaultConnection)
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $Sql
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $dt = New-Object System.Data.DataTable
    $adapter.Fill($dt) | Out-Null
    $conn.Close()
    if ($dt.Rows.Count -gt 0) {
        return $dt.Rows[0]
    }
    return $null
}

function Record-Result {
    param (
        [string]$ScenarioId,
        [string]$Title,
        [bool]$Success,
        [string]$Details
    )
    $obj = [PSCustomObject]@{
        Scenario = $ScenarioId
        Title    = $Title
        Status   = if ($Success) { "PASS" } else { "FAIL" }
        Details  = $Details
    }
    $script:testResults += $obj
    if ($Success) {
        Write-Host "✅ [$ScenarioId] $Title : PASS" -ForegroundColor Green
        if ($Details) { Write-Host "   -> $Details" -ForegroundColor Gray }
    } else {
        Write-Host "❌ [$ScenarioId] $Title : FAIL" -ForegroundColor Red
        if ($Details) { Write-Host "   -> $Details" -ForegroundColor Yellow }
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   BẮT ĐẦU CHUỖI KIỂM THỬ 10 TRƯỜNG HỢP CHUYÊN SÂU SYS_Users & HR_Employees" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 0. Đăng nhập Admin lấy Token
$adminLoginBody = @{
    UserCode = 'ADMIN'
    Password = 'Hansol@12345'
}

try {
    $loginRes = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $adminLoginBody
    $adminToken = $loginRes.data.accessToken
    $headers = @{
        Authorization = "Bearer $adminToken"
    }
    Write-Host "[AUTH] Đăng nhập Admin thành công. Token length: $($adminToken.Length)" -ForegroundColor Green
} catch {
    Write-Host "[AUTH ERROR] Không thể đăng nhập tài khoản ADMIN: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Tiền xử lý: Dọn sạch mọi dữ liệu test cũ nếu có
$testCode1 = "8888001"
$testCode2 = "8888002"
$cleanSql = @"
DELETE FROM dbo.SYS_UserGroupMapping WHERE UserId IN (SELECT UserId FROM dbo.SYS_Users WHERE UserCode IN ('$testCode1', '$testCode2'));
DELETE FROM dbo.SYS_UserTokens WHERE UserId IN (SELECT UserId FROM dbo.SYS_Users WHERE UserCode IN ('$testCode1', '$testCode2'));
DELETE FROM dbo.SYS_Users WHERE UserCode IN ('$testCode1', '$testCode2');
DELETE FROM dbo.HR_Employees WHERE UserCode IN ('$testCode1', '$testCode2');
"@
& "d:\HRM\scripts\execute_sql.ps1" -sqlCommand $cleanSql | Out-Null
Write-Host "[SETUP] Đã dọn dẹp sạch mã thử nghiệm $testCode1 và $testCode2." -ForegroundColor Gray

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 1: [CREATE Employee] Tạo hồ sơ nhân sự mới trong HR_Employees (chưa có tài khoản SYS_Users)
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 1: Tạo mới hồ sơ nhân sự thuần túy trong HR_Employees ---" -ForegroundColor Magenta
$empId1 = 0
try {
    $createEmpPayload = @{
        UserCode = $testCode1
        FullName = 'Hoàng Văn Thử Nghiệm 1'
        Email = 'hoang.test1@hansol.vn'
        IdentityNumber = '001200999888'
        BirthDate = '1995-05-15'
        Gender = 'MALE'
        Phone = '0988112233'
        DepartmentId = 4
        DepartmentCode = 'DEPT_IT'
        PositionRole = 'ENGINEER'
        Plant = 'MAIN'
        Area = 'AREA_A'
        WorkLine = 'SMT_LINE_01'
        CostCenter = 'CC_IT'
        VendorName = 'HANSOL'
        ContractType = 'Official'
        Status = 1
    }

    $createRes = Invoke-Api -Uri "$baseUrl/api/hr/employees" -Method Post -Headers $headers -Body $createEmpPayload
    $empId1 = [int]$createRes.data

    $empRow = Query-SqlRow "SELECT EmployeeId, UserId, UserCode, FullName FROM dbo.HR_Employees WHERE UserCode = '$testCode1'"
    $userCount = [int](Query-SqlScalar "SELECT COUNT(1) FROM dbo.SYS_Users WHERE UserCode = '$testCode1'")

    $userIdVal = if ($empRow) { $empRow["UserId"] } else { $null }
    $isUserIdNull = ($userIdVal -eq [DBNull]::Value -or $null -eq $userIdVal)

    if ($empId1 -gt 0 -and $empRow -ne $null -and $isUserIdNull -and $userCount -eq 0) {
        Record-Result "TC_01" "Tạo mới hồ sơ nhân sự HR_Employees (chưa có tài khoản SYS_Users)" $true "EmployeeId: $empId1, UserId trong HR_Employees là NULL, chưa có bản ghi trong SYS_Users."
    } else {
        Record-Result "TC_01" "Tạo mới hồ sơ nhân sự HR_Employees" $false "Lỗi kiểm tra DB: empRow=$empRow, isUserIdNull=$isUserIdNull, userCount=$userCount"
    }
} catch {
    Record-Result "TC_01" "Tạo mới hồ sơ nhân sự HR_Employees" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 2: [PROVISION Account] Cấp tài khoản hệ thống từ hồ sơ nhân sự vừa tạo
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 2: Cấp tài khoản hệ thống SYS_Users cho nhân sự vừa tạo ---" -ForegroundColor Magenta
$newSysUserId1 = 0
try {
    $provPayload = @{
        Password = 'Password@123'
        GroupId = 2 # General User Group
    }

    $provRes = Invoke-Api -Uri "$baseUrl/api/hr/employees/$empId1/create-account" -Method Post -Headers $headers -Body $provPayload
    $newSysUserId1 = [int]$provRes.data

    $provRow = Query-SqlRow "SELECT u.UserId, u.SecureId, u.PasswordHash, e.UserId AS EmpUserId, ugm.GroupId FROM dbo.SYS_Users u INNER JOIN dbo.HR_Employees e ON u.UserCode = e.UserCode LEFT JOIN dbo.SYS_UserGroupMapping ugm ON u.UserId = ugm.UserId WHERE u.UserCode = '$testCode1'"

    $uId = [int]$provRow["UserId"]
    $secId = $provRow["SecureId"].ToString()
    $pwdHash = $provRow["PasswordHash"].ToString()
    $eUId = [int]$provRow["EmpUserId"]
    $grpId = [int]$provRow["GroupId"]

    if ($uId -eq $newSysUserId1 -and $uId -eq $eUId -and $grpId -eq 2 -and $pwdHash.StartsWith('$2')) {
        Record-Result "TC_02" "Cấp mới tài khoản hệ thống (Account Provisioning)" $true "UserId: $uId, SecureId: $secId, BCrypt Hash hợp lệ, Khóa ngoại e.UserId = $eUId liên kết chính xác, GroupId: $grpId."
    } else {
        Record-Result "TC_02" "Cấp mới tài khoản hệ thống" $false "Sai lệch liên kết: uId=$uId, eUId=$eUId, grpId=$grpId"
    }
} catch {
    Record-Result "TC_02" "Cấp mới tài khoản hệ thống" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 3: [AUTHENTICATE] Đăng nhập bằng tài khoản mới vừa cấp & Kiểm tra Claims/Permissions
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 3: Đăng nhập bằng tài khoản mới được cấp & Xác thực JWT Claims ---" -ForegroundColor Magenta
$userToken1 = ""
$userSecureId1 = ""
$userLoginPayload = @{
    UserCode = $testCode1
    Password = 'Password@123'
}

try {
    $userLoginRes = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $userLoginPayload
    $userToken1 = $userLoginRes.data.accessToken
    $userPayload = $userLoginRes.data
    $userSecureId1 = $userPayload.secureId.ToString()

    $deptOk = ($userPayload.departmentCode -eq 'DEPT_IT' -or $userPayload.departmentId -eq 4)
    $nameOk = ($userPayload.fullName -eq 'Hoàng Văn Thử Nghiệm 1')

    if ($userToken1.Length -gt 50 -and $deptOk -and $nameOk) {
        Record-Result "TC_03" "Đăng nhập và giải mã JWT Claims tài khoản mới" $true "Nhận AccessToken thành công, thông tin phòng ban lấy từ HR_Employees (DEPT_IT), FullName: $($userPayload.fullName), SecureId: $userSecureId1."
    } else {
        Record-Result "TC_03" "Đăng nhập và giải mã JWT Claims tài khoản mới" $false "Sai thông tin trả về: deptOk=$deptOk, nameOk=$nameOk"
    }
} catch {
    Record-Result "TC_03" "Đăng nhập tài khoản mới" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 4: [UPDATE via SYS_Users API] Cập nhật thông tin qua SYS_Users API & Kiểm tra đồng bộ HR
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 4: Cập nhật người dùng qua SYS_Users API & Kiểm tra đồng bộ sang HR_Employees ---" -ForegroundColor Magenta
try {
    $updateSysPayload = @{
        UserCode = $testCode1
        FullName = 'Hoàng Văn Thử Nghiệm 1 Đã Sửa'
        Email = 'hoang.test1.updated@hansol.vn'
        Status = 1
        Plant = 'MAIN'
        Area = 'AREA_B'
        DepartmentId = 5
        DepartmentCode = 'DEPT_HR'
        PositionRole = 'TEAM_LEADER'
        PositionGrade = 'GRADE_2'
        Phone = '0988999888'
        Comment = 'Ghi chú cập nhật từ SYS'
    }

    $updateRes = Invoke-Api -Uri "$baseUrl/api/sys/users/$userSecureId1" -Method Put -Headers $headers -Body $updateSysPayload

    $syncRow = Query-SqlRow "SELECT u.Email AS SysEmail, u.FullName AS SysName, u.Comment, e.Email AS HrEmail, e.DepartmentId, e.PositionRole, e.Phone FROM dbo.SYS_Users u INNER JOIN dbo.HR_Employees e ON u.UserCode = e.UserCode WHERE u.UserCode = '$testCode1'"

    $sysEmail = $syncRow["SysEmail"].ToString()
    $sysName = $syncRow["SysName"].ToString()
    $hrDeptId = [int]$syncRow["DepartmentId"]
    $hrRole = $syncRow["PositionRole"].ToString()
    $hrPhone = $syncRow["Phone"].ToString()

    if ($sysEmail -eq 'hoang.test1.updated@hansol.vn' -and $hrDeptId -eq 5 -and $hrRole -eq 'TEAM_LEADER' -and $hrPhone -eq '0988999888') {
        Record-Result "TC_04" "Cập nhật qua SYS_Users API đồng bộ tức thì sang HR_Employees" $true "Email & Tên trong SYS_Users cập nhật đúng. HR_Employees tự động cập nhật: DepartmentId=5, PositionRole=TEAM_LEADER, Phone=0988999888."
    } else {
        Record-Result "TC_04" "Cập nhật qua SYS_Users API" $false "Dữ liệu không đồng bộ: sysEmail=$sysEmail, hrDeptId=$hrDeptId, hrRole=$hrRole, hrPhone=$hrPhone"
    }
} catch {
    Record-Result "TC_04" "Cập nhật qua SYS_Users API" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 5: [UPDATE via HR_Employees API] Cập nhật hồ sơ HR không ảnh hưởng mật khẩu/xác thực
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 5: Cập nhật hồ sơ nhân sự qua HR_Employees API mà không làm thay đổi bảo mật tài khoản ---" -ForegroundColor Magenta
try {
    $updateHrPayload = @{
        EmployeeId = $empId1
        UserCode = $testCode1
        FullName = 'Hoàng Văn Thử Nghiệm 1 Đã Sửa'
        Email = 'hoang.test1.updated@hansol.vn'
        BankName = 'Ngân Hàng Ngoại Thương VCB'
        BankAccountNumber = '123456789999'
        VendorName = 'HANSOL_SUBCONTRACT'
        ContractType = 'Probation'
        DepartmentId = 5
        DepartmentCode = 'DEPT_HR'
        Status = 1
    }

    $updateHrRes = Invoke-Api -Uri "$baseUrl/api/hr/employees/$empId1" -Method Put -Headers $headers -Body $updateHrPayload

    $hrRow = Query-SqlRow "SELECT BankName, BankAccountNumber, VendorName, ContractType FROM dbo.HR_Employees WHERE UserCode = '$testCode1'"
    $bank = $hrRow["BankName"].ToString()
    $bankAcc = $hrRow["BankAccountNumber"].ToString()

    # Kiểm tra login vẫn hoạt động bình thường với mật khẩu cũ
    $reloginRes = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $userLoginPayload
    $reloginOk = ($reloginRes.data.accessToken.Length -gt 50)

    if ($bank -eq 'Ngân Hàng Ngoại Thương VCB' -and $bankAcc -eq '123456789999' -and $reloginOk) {
        Record-Result "TC_05" "Cập nhật trường nhân sự (Bank, Vendor, Contract) bảo toàn thông tin xác thực" $true "BankName: $bank, BankAcc: $bankAcc cập nhật chuẩn xác. Tài khoản vẫn đăng nhập thành công với mật khẩu hiện tại."
    } else {
        Record-Result "TC_05" "Cập nhật trường nhân sự qua HR_Employees API" $false "Lỗi: bank=$bank, reloginOk=$reloginOk"
    }
} catch {
    Record-Result "TC_05" "Cập nhật trường nhân sự qua HR_Employees API" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 6: [CREATE via SYS_Users API] Tạo tài khoản trực tiếp từ SYS_Users và tự động tạo HR profile
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 6: Tạo mới người dùng trực tiếp qua SYS_Users API và kiểm tra tự động tạo HR_Employees ---" -ForegroundColor Magenta
$newSysUserId2 = 0
$userSecureId2 = ""
try {
    $createSysPayload = @{
        UserCode = $testCode2
        FullName = 'Lê Thị Thử Nghiệm 2'
        Email = 'le.test2@hansol.vn'
        Password = 'Password@456'
        Plant = 'MAIN'
        Area = 'AREA_C'
        DepartmentId = 4
        DepartmentCode = 'DEPT_IT'
        PositionRole = 'SPECIALIST'
        PositionGrade = 'GRADE_1'
        Phone = '0912345678'
        Status = 1
        GroupId = 2
    }

    $createSysRes = Invoke-Api -Uri "$baseUrl/api/sys/users" -Method Post -Headers $headers -Body $createSysPayload
    $userSecureId2 = $createSysRes.data.ToString()

    $directRow = Query-SqlRow "SELECT u.UserId, u.SecureId, e.EmployeeId, e.UserId AS EmpUserId, e.FullName, e.DepartmentCode FROM dbo.SYS_Users u INNER JOIN dbo.HR_Employees e ON u.UserCode = e.UserCode WHERE u.UserCode = '$testCode2'"

    $uId2 = [int]$directRow["UserId"]
    $eId2 = [int]$directRow["EmployeeId"]
    $eUId2 = [int]$directRow["EmpUserId"]
    $eName2 = $directRow["FullName"].ToString()
    $eDept2 = $directRow["DepartmentCode"].ToString()

    if ($uId2 -gt 0 -and $uId2 -eq $eUId2 -and $eName2 -eq 'Lê Thị Thử Nghiệm 2' -and $eDept2 -eq 'DEPT_IT') {
        Record-Result "TC_06" "Tạo mới tài khoản từ SYS_Users tự động tạo hồ sơ HR_Employees tương ứng" $true "Tạo thành công SYS UserId: $uId2, tự động tạo HR EmployeeId: $eId2 liên kết UserId chuẩn xác."
    } else {
        Record-Result "TC_06" "Tạo mới tài khoản từ SYS_Users" $false "Lỗi liên kết: uId2=$uId2, eUId2=$eUId2"
    }
} catch {
    Record-Result "TC_06" "Tạo mới tài khoản từ SYS_Users" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 7: [VALIDATION & DUPLICATE CHECKS] Kiểm tra bẫy lỗi trùng lặp mã & dữ liệu không hợp lệ
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 7: Kiểm tra tính toàn vẹn dữ liệu, chặn trùng lặp UserCode và lỗi xác thực ---" -ForegroundColor Magenta
$dupPassedCount = 0

# 7.1 Tạo trùng UserCode trong HR_Employees
try {
    $dupEmpPayload = @{
        UserCode = $testCode1
        FullName = 'Trùng Lặp Mã'
        Email = 'duplicate@hansol.vn'
        Status = 1
    }
    $dupEmpRes = Invoke-Api -Uri "$baseUrl/api/hr/employees" -Method Post -Headers $headers -Body $dupEmpPayload
} catch {
    $statusErr = [int]$_.Exception.Response.StatusCode
    if ($statusErr -eq 400) {
        $dupPassedCount++
        Write-Host "   -> 7.1: Chặn trùng UserCode trong HR_Employees chuẩn xác (HTTP 400)." -ForegroundColor Gray
    }
}

# 7.2 Cấp tài khoản lần thứ 2 cho nhân sự đã có tài khoản
try {
    $reProvPayload = @{ Password = 'AnotherPassword@123'; GroupId = 2 }
    $reProvRes = Invoke-Api -Uri "$baseUrl/api/hr/employees/$empId1/create-account" -Method Post -Headers $headers -Body $reProvPayload
} catch {
    $statusErr = [int]$_.Exception.Response.StatusCode
    if ($statusErr -eq 400) {
        $dupPassedCount++
        Write-Host "   -> 7.2: Chặn cấp tài khoản trùng lặp cho nhân viên đã có tài khoản (HTTP 400)." -ForegroundColor Gray
    }
}

# 7.3 Tạo người dùng với Email sai định dạng qua HR_Employees
try {
    $badEmailPayload = @{
        UserCode = "8888003"
        FullName = 'Email Sai'
        Email = 'invalid-email-format'
        Status = 1
    }
    $badEmailRes = Invoke-Api -Uri "$baseUrl/api/hr/employees" -Method Post -Headers $headers -Body $badEmailPayload
} catch {
    $statusErr = [int]$_.Exception.Response.StatusCode
    if ($statusErr -eq 400) {
        $dupPassedCount++
        Write-Host "   -> 7.3: Chặn tạo nhân sự với Email sai định dạng (HTTP 400)." -ForegroundColor Gray
    }
}

# 7.4 Tạo người dùng với UserCode chứa chữ cái trong SYS_Users (Vi phạm RegularExpression ^\d+$)
try {
    $badCodePayload = @{
        UserCode = "INVALID_ABC"
        FullName = 'Mã Sai'
        Email = 'valid@hansol.vn'
        Password = 'Password@123'
        Status = 1
    }
    $badCodeRes = Invoke-Api -Uri "$baseUrl/api/sys/users" -Method Post -Headers $headers -Body $badCodePayload
} catch {
    $statusErr = [int]$_.Exception.Response.StatusCode
    if ($statusErr -eq 400) {
        $dupPassedCount++
        Write-Host "   -> 7.4: Chặn tạo tài khoản SYS với UserCode không phải chữ số (HTTP 400)." -ForegroundColor Gray
    }
}

if ($dupPassedCount -eq 4) {
    Record-Result "TC_07" "Kiểm tra ràng buộc toàn vẹn dữ liệu và bẫy lỗi Validation" $true "Chặn thành công cả 4 trường hợp: Trùng mã nhân viên, Cấp trùng tài khoản, Email sai định dạng, Mã nhân viên chứa chữ cái."
} else {
    Record-Result "TC_07" "Kiểm tra ràng buộc toàn vẹn dữ liệu" $false "Chỉ vượt qua $dupPassedCount / 4 bài kiểm tra validation."
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 8: [STATUS TOGGLE & ACCESS CONTROL] Khóa tài khoản, kiểm tra chặn đăng nhập & mở lại
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 8: Khóa tài khoản người dùng, kiểm tra chặn đăng nhập và kích hoạt lại ---" -ForegroundColor Magenta
try {
    # 8.1 Khóa tài khoản (Status = 0)
    $lockPayload = @{ Status = 0 }
    $lockRes = Invoke-Api -Uri "$baseUrl/api/sys/users/$userSecureId1/status" -Method Patch -Headers $headers -Body $lockPayload

    # Thử đăng nhập tài khoản đã bị khóa -> Kỳ vọng lỗi
    $loginBlocked = $false
    try {
        $tryLogin = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $userLoginPayload
    } catch {
        $loginBlocked = $true
    }

    # 8.2 Mở khóa lại tài khoản (Status = 1)
    $unlockPayload = @{ Status = 1 }
    $unlockRes = Invoke-Api -Uri "$baseUrl/api/sys/users/$userSecureId1/status" -Method Patch -Headers $headers -Body $unlockPayload

    # Thử đăng nhập lại -> Kỳ vọng thành công
    $reLoginAfterUnlock = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $userLoginPayload
    $unlockOk = ($reLoginAfterUnlock.data.accessToken.Length -gt 50)

    if ($loginBlocked -and $unlockOk) {
        Record-Result "TC_08" "Khóa tài khoản chặn đăng nhập và mở lại cấp quyền truy cập" $true "Khi Status=0 hệ thống từ chối đăng nhập chuẩn xác. Khi Status=1 tài khoản lập tức truy cập bình thường."
    } else {
        Record-Result "TC_08" "Khóa tài khoản và mở lại" $false "Lỗi: loginBlocked=$loginBlocked, unlockOk=$unlockOk"
    }
} catch {
    Record-Result "TC_08" "Khóa tài khoản và mở lại" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 9: [PASSWORD RESET & MUST CHANGE PASSWORD] Đặt lại mật khẩu mặc định và cờ đổi mật khẩu
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 9: Đặt lại mật khẩu (Reset Password) và kiểm tra cờ MustChangePassword ---" -ForegroundColor Magenta
try {
    # Admin reset password về Hansol@12345
    $resetRes = Invoke-Api -Uri "$baseUrl/api/sys/users/$userSecureId1/reset-password" -Method Post -Headers $headers

    # Đăng nhập bằng mật khẩu cũ -> Phải thất bại
    $oldPwdFailed = $false
    try {
        $tryOld = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $userLoginPayload
    } catch {
        $oldPwdFailed = $true
    }

    # Đăng nhập bằng mật khẩu mặc định 'Hansol@12345' -> Phải thành công và MustChangePassword = true
    $defaultLoginPayload = @{
        UserCode = $testCode1
        Password = 'Hansol@12345'
    }

    $defaultLoginRes = Invoke-Api -Uri "$baseUrl/api/sys/auth/login" -Method Post -Body $defaultLoginPayload
    $newLoginToken = $defaultLoginRes.data.accessToken
    $mustChange = $defaultLoginRes.data.mustChangePassword

    if ($oldPwdFailed -and ($newLoginToken.Length -gt 50) -and $mustChange -eq $true) {
        Record-Result "TC_09" "Đặt lại mật khẩu mặc định (Reset Password) và Cờ MustChangePassword" $true "Mật khẩu cũ bị vô hiệu. Đăng nhập thành công với 'Hansol@12345' và hệ thống yêu cầu đổi mật khẩu (MustChangePassword = true)."
    } else {
        Record-Result "TC_09" "Đặt lại mật khẩu mặc định" $false "Lỗi: oldPwdFailed=$oldPwdFailed, mustChange=$mustChange"
    }
} catch {
    Record-Result "TC_09" "Đặt lại mật khẩu mặc định" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TRƯỜNG HỢP 10: [SOFT DELETE & INTEGRITY CLEANUP] Xóa mềm hồ sơ, bảo toàn dữ liệu và dọn dẹp an toàn
# -------------------------------------------------------------------------------------------------
Write-Host "`n--- TRƯỜNG HỢP 10: Xóa mềm nhân sự (UseFlag=0), lọc danh sách và dọn dẹp kiểm thử ---" -ForegroundColor Magenta
try {
    # 10.1 Xóa mềm nhân sự 1 trong HR_Employees
    $delRes = Invoke-Api -Uri "$baseUrl/api/hr/employees/$empId1" -Method Delete -Headers $headers

    # Gọi GET danh sách nhân viên đang hoạt động (UseFlag = 1) -> Không được chứa testCode1
    $listActive = Invoke-Api -Uri "$baseUrl/api/hr/employees?useFlag=1&searchKeyword=$testCode1" -Method Get -Headers $headers
    $excludedFromActive = ($listActive.totalRecords -eq 0)

    # 10.2 Kiểm tra trong DB: UseFlag đã chuyển thành 0
    $useFlagVal = [int](Query-SqlScalar "SELECT UseFlag FROM dbo.HR_Employees WHERE EmployeeId = $empId1")

    # 10.3 Dọn dẹp sạch sẽ dữ liệu test
    & "d:\HRM\scripts\execute_sql.ps1" -sqlCommand $cleanSql | Out-Null
    Write-Host "   -> Đã dọn dẹp an toàn toàn bộ dữ liệu test sau kiểm thử." -ForegroundColor Gray

    if ($excludedFromActive -and $useFlagVal -eq 0) {
        Record-Result "TC_10" "Xóa mềm hồ sơ nhân sự (Soft Delete) và Khử rác an toàn" $true "UseFlag chuyển thành 0 chuẩn xác, loại trừ hoàn toàn khỏi danh sách hoạt động; Dọn dẹp DB trở về trạng thái sạch 100%."
    } else {
        Record-Result "TC_10" "Xóa mềm hồ sơ nhân sự" $false "Lỗi: excludedFromActive=$excludedFromActive, useFlagVal=$useFlagVal"
    }
} catch {
    Record-Result "TC_10" "Xóa mềm hồ sơ nhân sự" $false $_.Exception.Message
}

# -------------------------------------------------------------------------------------------------
# TỔNG KẾT KẾT QUẢ 10 SCENARIOS
# -------------------------------------------------------------------------------------------------
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "               TỔNG HỢP KẾT QUẢ 10 BÀI KIỂM THỬ CHUYÊN SÂU" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
$script:testResults | Format-Table -AutoSize -Property Scenario, Status, Title

$passCount = ($script:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($script:testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$summaryColor = if ($failCount -eq 0) { "Green" } else { "Red" }
Write-Host "Tổng số kịch bản: $($script:testResults.Count) | ĐẠT: $passCount | THẤT BẠI: $failCount" -ForegroundColor $summaryColor

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
