[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$loginBody = '{"UserCode":"ADMIN","Password":"Hansol@12345"}'
$login = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
Write-Host "Login Status: $($login.isSuccess)"
$token = $login.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

$outPath = 'd:\HRM\scripts\test_exported_payslip.xlsx'
if (Test-Path $outPath) { Remove-Item $outPath -Force }

Invoke-WebRequest -Uri 'http://localhost:7014/api/ess/my-payslip/export-excel?periodId=2026-08' -Headers $headers -OutFile $outPath
Write-Host "Exported File Size: $((Get-Item $outPath).Length) bytes"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $wb = $excel.Workbooks.Open($outPath)
    $ws = $wb.Sheets.Item(1)
    Write-Host '=== GENERATED EXCEL PAYSLIP (From Template_MySalary.xlsx) ==='
    Write-Host "Cell A6: $($ws.Range('A6').Text)"
    Write-Host "Cell B7 (Họ & Tên): $($ws.Range('B7').Text)"
    Write-Host "Cell H7 (Bộ phận): $($ws.Range('H7').Text)"
    Write-Host "Cell B8 (Mã NV): $($ws.Range('B8').Text)"
    Write-Host "Cell B9 (Số tài khoản): $($ws.Range('B9').Text)"
    Write-Host "Cell B10 (Lương CB): $($ws.Range('B10').Text)"
    Write-Host "Cell H10 (Ngày công): $($ws.Range('H10').Text)"
    Write-Host "Cell B11 (Chức vụ): $($ws.Range('B11').Text)"
    Write-Host "Cell H11 (Phép năm): $($ws.Range('H11').Text)"
    Write-Host "Cell A14/B14/C14 (Thử việc): $($ws.Range('A14').Text) | $($ws.Range('B14').Text) | $($ws.Range('C14').Text)"
    Write-Host "Cell D14/E14/F14 (Chính thức): $($ws.Range('D14').Text) | $($ws.Range('E14').Text) | $($ws.Range('F14').Text)"
    Write-Host "Cell G14/H14 (PC Trách nhiệm): $($ws.Range('G14').Text) | $($ws.Range('H14').Text)"
    Write-Host "Cell I14/J14 (Mức đóng BHXH): $($ws.Range('I14').Text) | $($ws.Range('J14').Text)"
    Write-Host "Cell B35 (Total A Hours): $($ws.Range('B35').Text)"
    Write-Host "Cell E35 (Total B Hours): $($ws.Range('E35').Text)"
    Write-Host "Cell F35 (Total B Amount): $($ws.Range('F35').Text)"
    Write-Host "Cell B36 (Thực lãnh): $($ws.Range('B36').Text)"
    Write-Host "Cell B37 (Ghi chú): $($ws.Range('B37').Text)"
    $wb.Close($false)
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
