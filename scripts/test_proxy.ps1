$loginRes = Invoke-RestMethod -Uri 'http://localhost:8000/api/sys/auth/login' -Method Post -Body (@{UserCode='admin';Password='Hansol@12345'} | ConvertTo-Json) -ContentType 'application/json'
$headers = @{ Authorization = "Bearer $($loginRes.data.accessToken)" }
$empRes = Invoke-RestMethod -Uri 'http://localhost:8000/api/hr/employees?pageNumber=1&pageSize=5&useFlag=1' -Method Get -Headers $headers
Write-Host "[PROXY TEST] Success: $($empRes.isSuccess), Total: $($empRes.totalRecords), Items: $($empRes.data.Count)"
