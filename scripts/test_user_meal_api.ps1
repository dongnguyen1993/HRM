$ErrorActionPreference = "Stop"

Write-Host "=== 1. TEST MEAL DEPARTMENTS ==="
$depts = Invoke-RestMethod -Uri "http://localhost:5020/api/meal-orders/departments" -Method Get
Write-Host "Count: $($depts.data.Count)"
$depts.data | Select-Object -First 5 departmentId, departmentCode, departmentName | Format-Table -AutoSize

Write-Host "=== 2. LOGIN TO GET TOKEN ==="
$loginBody = @{
    userCode = "admin"
    password = "sa"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:5020/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.data.accessToken
Write-Host "Login successful, User: $($loginRes.data.fullName)"

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "=== 3. TEST USER LIST API ==="
$users = Invoke-RestMethod -Uri "http://localhost:5020/api/users?page=1&pageSize=5" -Method Get -Headers $headers
Write-Host "Total users: $($users.total)"
$users.data | Select-Object userCode, fullName, departmentCode, mealDepartmentId, mealDepartmentCode, mealDepartmentName | Format-Table -AutoSize

Write-Host "=== 4. TEST MEAL CONTEXT API ==="
$ctx = Invoke-RestMethod -Uri "http://localhost:5020/api/meal-orders/context?date=2026-09-18" -Method Get -Headers $headers
Write-Host "Context Dept: $($ctx.data.departmentCode) - $($ctx.data.departmentName)"
Write-Host "Context Exists: $($ctx.data.exists)"
