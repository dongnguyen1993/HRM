[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$loginRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body (@{UserCode='admin';Password='Hansol@12345'} | ConvertTo-Json) -ContentType 'application/json'
$headers = @{ Authorization = "Bearer $($loginRes.data.accessToken)" }
$menus = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/permission/my-menu' -Method Get -Headers $headers

function PrintTree($items, $indent = "") {
    foreach ($item in $items) {
        Write-Host "$indent- $($item.name) ($($item.path))"
        if ($item.children -and $item.children.Count -gt 0) {
            PrintTree $item.children ($indent + "  ")
        }
    }
}

$sys = $menus.data | Where-Object { $_.path -eq '/sys' }
PrintTree @($sys)
