$loginRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body (@{UserCode='1200837';Password='Hansol@12345'} | ConvertTo-Json) -ContentType 'application/json'
$headers = @{ Authorization = "Bearer $($loginRes.data.accessToken)" }
$menus = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/permission/my-menu' -Method Get -Headers $headers
Write-Host "Group: $($loginRes.data.authorGroupId)"
$menus.data | Select-Object ProgramKey, ProgramName, path | Format-Table -AutoSize
if ($menus.data) {
    foreach ($m in $menus.data) {
        Write-Host "Menu: $($m.path)"
        if ($m.children) {
            $m.children | Select-Object ProgramKey, ProgramName, path | Format-Table -AutoSize
        }
    }
}
