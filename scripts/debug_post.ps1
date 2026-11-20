$loginBody = @{ UserCode = 'admin'; Password = 'Hansol@12345' } | ConvertTo-Json
$res = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
$headers = @{ Authorization = "Bearer $($res.data.accessToken)" }

$payload = @{
    UserCode = '9999001'
    FullName = 'Nguyễn Văn Test'
    Email = 'test9999@hansol.com'
    DepartmentId = 4
    DepartmentCode = 'DEPT_IT'
    PositionRole = 'ENGINEER'
    Plant = 'MAIN'
    VendorName = 'HANSOL'
    ContractType = 'Official'
    Status = 1
} | ConvertTo-Json

try {
    $postRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees' -Method Post -Headers $headers -Body $payload -ContentType 'application/json'
    Write-Host "Success: $($postRes | ConvertTo-Json)"
} catch {
    $resp = $_.Exception.Response
    $stream = $resp.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "STATUS: $($resp.StatusCode)"
    Write-Host "BODY: $($reader.ReadToEnd())"
}
