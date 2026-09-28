$loginBody = @{ UserCode = 'ADMIN'; Password = 'Hansol@12345' } | ConvertTo-Json
$res = Invoke-RestMethod -Uri 'http://localhost:5020/api/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
$headers = @{ Authorization = "Bearer " + $res.data.accessToken }

Write-Host "1. Testing /api/users/positions:"
$posRes = Invoke-RestMethod -Uri 'http://localhost:5020/api/users/positions' -Method Get -Headers $headers
Write-Host "Positions found: $($posRes.data.Count)"
foreach ($p in $posRes.data) {
    Write-Host "$($p.positionId) | $($p.positionCode) | $($p.positionName)"
}

Write-Host "`n2. Testing /api/users (page 1):"
$usersRes = Invoke-RestMethod -Uri 'http://localhost:5020/api/users?pageNumber=1&pageSize=3' -Method Get -Headers $headers
Write-Host "Users total records: $($usersRes.totalRecords)"
$firstUser = $usersRes.data[0]
Write-Host "First user properties:"
$firstUser | ConvertTo-Json
