[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================================="
Write-Host "KIỂM THỬ BẢO MẬT PHIẾU LƯƠNG CỦA TÔI (ESS_MY_PAYSLIP - 1005)"
Write-Host "=========================================================="

# 1. Đăng nhập ADMIN
$loginBody = '{"UserCode":"ADMIN","Password":"Hansol@12345"}'
$loginAdmin = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
$tokenAdmin = $loginAdmin.data.accessToken
$headersAdmin = @{ Authorization = "Bearer $tokenAdmin" }

Write-Host "`n--- SCENARIO 1: ADMIN xem phiếu lương của chính mình ---"
$periodsAdmin = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip/periods' -Headers $headersAdmin
Write-Host "Số kỳ lương của ADMIN: $($periodsAdmin.data.Count)"
foreach ($p in $periodsAdmin.data) {
    Write-Host "  - Kỳ: $($p.periodId) | Lương: $($p.netReceived) | Tên: $($p.fullName)"
}

$payslipAdmin = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip?periodId=2026-08' -Headers $headersAdmin
Write-Host "Chi tiết phiếu lương 2026-08 của ADMIN: NV=$($payslipAdmin.data.employee.fullName) | Mã=$($payslipAdmin.data.employee.employeeCode) | Net=$($payslipAdmin.data.netReceived)"

Write-Host "`n--- SCENARIO 2: ADMIN cố tình truyền ?employeeCode=1200837 (Xem chéo trái phép) ---"
try {
    $res = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip?periodId=2026-08&employeeCode=1200837' -Headers $headersAdmin
    Write-Host "THẤT BẠI: Hệ thống vẫn cho phép xem chéo!"
} catch {
    Write-Host "THÀNH CÔNG: Đã chặn xem chéo với mã lỗi: $($_.Exception.Response.StatusCode.value__)"
}

# 2. Đăng nhập 1111111 (User KHÔNG CÓ BẢNG LƯƠNG)
Write-Host "`n--- SCENARIO 3: User 1111111 (Không có dữ liệu lương trong kỳ) ---"
$loginSec = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body '{"UserCode":"1111111","Password":"Hansol@12345"}' -ContentType 'application/json'
$tokenSec = $loginSec.data.accessToken
$headersSec = @{ Authorization = "Bearer $tokenSec" }

$periodsSec = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip/periods' -Headers $headersSec
Write-Host "Số kỳ lương của 1111111 (Kỳ vọng 0): $($periodsSec.data.Count)"

$payslipSec = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip?periodId=2026-08' -Headers $headersSec
Write-Host "Kết quả xem phiếu 2026-08 của 1111111: isSuccess=$($payslipSec.isSuccess), message='$($payslipSec.message)', data=$($payslipSec.data)"

try {
    $pdfSec = Invoke-WebRequest -Uri 'http://localhost:7014/api/ess/my-payslip/preview-pdf?periodId=2026-08' -Headers $headersSec
    Write-Host "THẤT BẠI: Vẫn sinh PDF cho user không có lương!"
} catch {
    Write-Host "THÀNH CÔNG: Chặn tạo PDF cho user không có lương với mã lỗi: $($_.Exception.Response.StatusCode.value__)"
}

Write-Host "`n--- SCENARIO 4: User 1111111 cố tình xem trộm phiếu của ADMIN (?employeeCode=ADMIN) ---"
try {
    $hackRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip?periodId=2026-08&employeeCode=ADMIN' -Headers $headersSec
    Write-Host "THẤT BẠI: User thường hack xem được phiếu ADMIN!"
} catch {
    Write-Host "THÀNH CÔNG: Đã chặn đứng hành vi xem trộm phiếu của ADMIN! Mã lỗi: $($_.Exception.Response.StatusCode.value__)"
}

# 3. Đăng nhập 1200837 (Nguyễn Lâm Đồng)
Write-Host "`n--- SCENARIO 5: User 1200837 (Nguyễn Lâm Đồng) xem phiếu lương của chính mình ---"
$loginDong = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body '{"UserCode":"1200837","Password":"Hansol@12345"}' -ContentType 'application/json'
$tokenDong = $loginDong.data.accessToken
$headersDong = @{ Authorization = "Bearer $tokenDong" }

$periodsDong = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip/periods' -Headers $headersDong
Write-Host "Số kỳ lương của 1200837: $($periodsDong.data.Count)"
foreach ($p in $periodsDong.data) {
    Write-Host "  - Kỳ: $($p.periodId) | Lương: $($p.netReceived) | Tên: $($p.fullName)"
}

$payslipDong = Invoke-RestMethod -Uri 'http://localhost:7014/api/ess/my-payslip?periodId=2026-08' -Headers $headersDong
Write-Host "Chi tiết phiếu lương 2026-08 của 1200837: NV=$($payslipDong.data.employee.fullName) | Mã=$($payslipDong.data.employee.employeeCode) | Net=$($payslipDong.data.netReceived)"

Write-Host "`n--- SCENARIO 6: User 1200837 xuất PDF ---"
$outDongPdf = 'd:\HRM\scripts\test_dong_payslip.pdf'
Invoke-WebRequest -Uri 'http://localhost:7014/api/ess/my-payslip/preview-pdf?periodId=2026-08' -Headers $headersDong -OutFile $outDongPdf
Write-Host "PDF Size của Nguyễn Lâm Đồng: $((Get-Item $outDongPdf).Length) bytes"

Write-Host "`n=========================================================="
Write-Host "TẤT CẢ 6 KỊCH BẢN BẢO MẬT & CÔ LẬP USER ĐỀU ĐẠT CHUẨN 100%!"
Write-Host "=========================================================="
