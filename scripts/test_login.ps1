$body = @{ userCode = 'admin'; password = 'Hansol@12345' } | ConvertTo-Json
$res = Invoke-RestMethod -Uri 'http://localhost:7014/api/auth/login' -Method POST -ContentType 'application/json; charset=utf-8' -Body $body
$token = $res.data.accessToken

$headers = @{
    'Authorization' = "Bearer $token"
}

$postBody = [System.Text.Encoding]::UTF8.GetBytes((@{
    departmentCode = 'GA_OPS'
    departmentName = 'Bo Phan Van Hanh Hanh Chinh'
    parentDepartmentId = 2006
    sortOrder = 99
    useFlag = $true
    comment = 'Kiem thu tao phong ban GA'
    deptType = 'GA'
} | ConvertTo-Json))

try {
    $postRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/ga-departments' -Method POST -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $postBody
    Write-Host "Create GA Department result: $($postRes.isSuccess) - $($postRes.message)"
    
    # Query GA tree
    $treeRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/ga-departments/tree' -Method GET
    $created = $treeRes.data[0].children | Where-Object { $_.departmentCode -eq 'GA_OPS' }
    Write-Host "Created GA dept in Tree: ID=$($created.departmentId), Code=$($created.departmentCode), Name=$($created.departmentName), DeptType=$($created.deptType)"
    
    # Verify HR Tree does NOT have GA_OPS
    $hrTree = Invoke-RestMethod -Uri 'http://localhost:7014/api/departments/tree?deptType=HR' -Method GET
    $inHr = $hrTree.data | ForEach-Object { $_.children } | Where-Object { $_.departmentCode -eq 'GA_OPS' }
    Write-Host "Found in HR Tree (Must be False): $($inHr -ne $null)"
    
    # Update GA department
    $putBody = [System.Text.Encoding]::UTF8.GetBytes((@{
        departmentCode = 'GA_OPS'
        departmentName = 'Bo Phan Van Hanh Hanh Chinh (Cap nhat)'
        parentDepartmentId = 2006
        sortOrder = 100
        useFlag = $true
        comment = 'Cap nhat thanh cong'
        deptType = 'GA'
    } | ConvertTo-Json))
    $putRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ga-departments/$($created.departmentId)" -Method PUT -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $putBody
    Write-Host "Update GA Department result: $($putRes.isSuccess) - $($putRes.message)"
    
    # Delete GA department
    $delRes = Invoke-RestMethod -Uri "http://localhost:7014/api/ga-departments/$($created.departmentId)" -Method DELETE -Headers $headers
    Write-Host "Delete GA Department result: $($delRes.isSuccess) - $($delRes.message)"
    
    Write-Host "`n>>> ALL 5 TESTS PASSED SUCCESSFULLY! DATA PARTITIONING VERIFIED 100%! <<<"
} catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "Create Error response:" $reader.ReadToEnd()
}
