$loginRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body (@{UserCode='admin';Password='Hansol@12345'} | ConvertTo-Json) -ContentType 'application/json'
$headers = @{ Authorization = "Bearer $($loginRes.data.accessToken)" }

Write-Host "--- TEST 1: /api/hr/employees ---"
try {
    $res1 = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees?pageNumber=1&pageSize=15&useFlag=1' -Method Get -Headers $headers
    Write-Host "[OK] Total: $($res1.totalRecords), Items: $($res1.data.Count)"
} catch { Write-Host "[ERR 1] $($_.Exception.Message)" }

Write-Host "--- TEST 2: /api/hr/departments/tree ---"
try {
    $res2 = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/departments/tree?deptType=HR' -Method Get -Headers $headers
    Write-Host "[OK] Depts: $($res2.Count)"
} catch { Write-Host "[ERR 2] $($_.Exception.Message)" }

Write-Host "--- TEST 3: /api/sys/users/positions ---"
try {
    $res3 = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/users/positions' -Method Get -Headers $headers
    Write-Host "[OK] Positions: $($res3.data.Count)"
} catch { Write-Host "[ERR 3] $($_.Exception.Message)" }

Write-Host "--- TEST 4: /api/hr/employees/dropdown ---"
try {
    $res4 = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees/dropdown' -Method Get -Headers $headers
    Write-Host "[OK] Dropdown: $($res4.data.Count)"
} catch { Write-Host "[ERR 4] $($_.Exception.Message)" }

Write-Host "--- TEST 5: /api/sys/users ---"
try {
    $res5 = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/users?pageNumber=1&pageSize=10' -Method Get -Headers $headers
    Write-Host "[OK] Users Total: $($res5.totalRecords), Items: $($res5.data.Count)"
} catch { Write-Host "[ERR 5] $($_.Exception.Message)" }

Write-Host "--- TEST 6: /api/sys/permission/my-menu ---"
try {
    $res6 = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/permission/my-menu' -Method Get -Headers $headers
    Write-Host "[OK] Menus: $($res6.data.Count)"
} catch { Write-Host "[ERR 6] $($_.Exception.Message)" }
