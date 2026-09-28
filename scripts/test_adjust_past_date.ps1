$ErrorActionPreference = "Stop"

Write-Host "=== 1. LOGIN ADMIN ==="
$loginBody = @{
    userCode = "ADMIN"
    password = "123456"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:5020/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.data.accessToken
Write-Host "Login successful! Token acquired."

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "`n=== 2. TEST ADJUST FOR YESTERDAY (PAST DATE) ==="
$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
Write-Host "Sending adjust request for date: $yesterday"

$adjustBody = @{
    departmentCode = "IT"
    orderDate = $yesterday
    dayLunchCount = 10
    dayOtCount = 0
    nightDinnerCount = 0
    nightOtCount = 0
    vegetarianCount = 0
    note = "Test adjust past date"
} | ConvertTo-Json

try {
    $res = Invoke-RestMethod -Uri "http://localhost:5020/api/meal-orders/admin/adjust" -Method Put -Body $adjustBody -ContentType "application/json" -Headers $headers
    Write-Host "Response IsSuccess: $($res.isSuccess)"
    Write-Host "Response Message: $($res.message)"
} catch {
    $errStream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errStream)
    $respBody = $reader.ReadToEnd()
    Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)"
    Write-Host "Response Body: $respBody"
}

Write-Host "`n=== 3. TEST ADJUST FOR TODAY (CURRENT DATE) ==="
$today = (Get-Date).ToString("yyyy-MM-dd")
Write-Host "Sending adjust request for date: $today"

$adjustTodayBody = @{
    departmentCode = "IT"
    orderDate = $today
    dayLunchCount = 5
    dayOtCount = 0
    nightDinnerCount = 0
    nightOtCount = 0
    vegetarianCount = 0
    note = "Test adjust today"
} | ConvertTo-Json

try {
    $resToday = Invoke-RestMethod -Uri "http://localhost:5020/api/meal-orders/admin/adjust" -Method Put -Body $adjustTodayBody -ContentType "application/json" -Headers $headers
    Write-Host "Response IsSuccess: $($resToday.isSuccess)"
    Write-Host "Response Message: $($resToday.message)"
} catch {
    $errStream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errStream)
    $respBody = $reader.ReadToEnd()
    Write-Host "HTTP Status: $($_.Exception.Response.StatusCode)"
    Write-Host "Response Body: $respBody"
}
