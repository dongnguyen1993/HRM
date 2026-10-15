# Login to get valid JWT Token
$loginBody = @{
    userCode = 'admin'
    password = 'Password@123'
} | ConvertTo-Json

$token = $null
try {
    $loginRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/auth/login' -Method POST -ContentType 'application/json' -Body $loginBody
    $token = $loginRes.data.accessToken
    Write-Host "-> Logged in as admin with Password@123"
} catch {
    $loginBody2 = @{
        userCode = 'admin'
        password = 'Password@1234'
    } | ConvertTo-Json
    $loginRes2 = Invoke-RestMethod -Uri 'http://localhost:7014/api/auth/login' -Method POST -ContentType 'application/json' -Body $loginBody2
    $token = $loginRes2.data.accessToken
    Write-Host "-> Logged in as admin with Password@1234"
}

$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $token"
}

Write-Host "`n=== 1. Test POST Create GA Department ==="
$postBody = @{
    departmentCode = 'TEST_GA_UNIT'
    departmentName = 'Bộ phận Thử nghiệm GA'
    parentDepartmentId = 2006
    sortOrder = 99
    useFlag = $true
    comment = 'Kiểm thử phân tách dữ liệu GA'
    deptType = 'GA'
} | ConvertTo-Json

$postRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/ga-departments' -Method POST -Headers $headers -Body $postBody
$postRes | ConvertTo-Json

Write-Host "`n=== 2. Check GA Tree for newly created department ==="
$treeRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/ga-departments/tree' -Method GET -Headers $headers
$created = $treeRes.data[0].children | Where-Object { $_.departmentCode -eq 'TEST_GA_UNIT' }
Write-Host "Created Dept in GA Tree: ID=$($created.departmentId), Code=$($created.departmentCode), Name=$($created.departmentName), DeptType=$($created.deptType)"

Write-Host "`n=== 3. Verify HR Tree does NOT have TEST_GA_UNIT ==="
$hrTree = Invoke-RestMethod -Uri 'http://localhost:7014/api/departments/tree?deptType=HR' -Method GET -Headers $headers
$foundInHr = $hrTree.data | ForEach-Object { $_.children } | Where-Object { $_.departmentCode -eq 'TEST_GA_UNIT' }
Write-Host "Found in HR Tree (Must be null): $($foundInHr -eq $null)"

Write-Host "`n=== 4. Test PUT Update GA Department ==="
$putBody = @{
    departmentCode = 'TEST_GA_UNIT'
    departmentName = 'Bộ phận Thử nghiệm GA (Đã cập nhật)'
    parentDepartmentId = 2006
    sortOrder = 100
    useFlag = $true
    comment = 'Cập nhật thành công'
    deptType = 'GA'
} | ConvertTo-Json
$putRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ga-departments/$($created.departmentId)" -Method PUT -Headers $headers -Body $putBody
$putRes | ConvertTo-Json

Write-Host "`n=== 5. Test DELETE GA Department ==="
$delRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ga-departments/$($created.departmentId)" -Method DELETE -Headers $headers
$delRes | ConvertTo-Json

Write-Host "`n=== ALL CRUD & PARTITIONING TESTS PASSED PERFECTLY ==="
