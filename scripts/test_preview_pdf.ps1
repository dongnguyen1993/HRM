[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$loginBody = '{"UserCode":"ADMIN","Password":"Hansol@12345"}'
$login = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
Write-Host "Login Status: $($login.isSuccess)"
$token = $login.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

$outPdf = 'd:\HRM\scripts\test_api_preview.pdf'
if (Test-Path $outPdf) { Remove-Item $outPdf -Force }

Invoke-WebRequest -Uri 'http://localhost:7014/api/ess/my-payslip/preview-pdf?periodId=2026-08' -Headers $headers -OutFile $outPdf
Write-Host "Preview PDF File Size: $((Get-Item $outPdf).Length) bytes"

# Verify PDF Header (%PDF-)
$bytes = [System.IO.File]::ReadAllBytes($outPdf)
$magic = [System.Text.Encoding]::ASCII.GetString($bytes[0..4])
Write-Host "PDF Magic Bytes: $magic"
if ($magic.StartsWith("%PDF")) {
    Write-Host "SUCCESS: Valid PDF document generated and returned from API!"
} else {
    Write-Host "FAILURE: Output is not a valid PDF! Content: $([System.Text.Encoding]::UTF8.GetString($bytes[0..[Math]::Min(200, $bytes.Length)]))"
}
