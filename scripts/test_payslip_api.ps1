[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Login as ADMIN
$loginBody = @{
    UserCode = "ADMIN"
    Password = "Hansol@12345"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:7014/api/sys/auth/login" -Method Post -Body $loginBody -ContentType "application/json; charset=utf-8"
Write-Host "Login Success: $($loginRes.isSuccess)"
$token = $loginRes.data.accessToken

# 2. Call GET /api/ess/my-payslip/periods
$headers = @{
    Authorization = "Bearer $token"
}

try {
    $resPeriods = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip/periods" -Method Get -Headers $headers
    Write-Host "Periods Success: $($resPeriods.isSuccess)"
    $resPeriods.data | ForEach-Object {
        Write-Host "Period: $($_.periodId) - $($_.periodName) (Published: $($_.isPublished))"
    }
} catch {
    Write-Host "Error calling /api/ess/my-payslip/periods: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Response Body: $($reader.ReadToEnd())"
    }
}

# 3. Call GET /api/ess/my-payslip
try {
    $resPayslip = Invoke-RestMethod -Uri "http://localhost:7014/api/ess/my-payslip?periodId=2026-07" -Method Get -Headers $headers
    Write-Host "Payslip Success: $($resPayslip.isSuccess)"
    Write-Host "Employee: $($resPayslip.data.employee.fullName) - NetReceived: $($resPayslip.data.employee.netReceived)"
} catch {
    Write-Host "Error calling /api/ess/my-payslip: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Response Body: $($reader.ReadToEnd())"
    }
}
