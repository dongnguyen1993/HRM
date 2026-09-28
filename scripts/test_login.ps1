$passwords = @("123456", "admin", "admin123", "Admin@123", "Password123!", "12345678", "Admin123")
foreach ($p in $passwords) {
    try {
        $body = @{ UserCode = "ADMIN"; Password = $p } | ConvertTo-Json
        $res = Invoke-RestMethod -Uri "http://localhost:5020/api/auth/login" -Method Post -Body $body -ContentType "application/json"
        if ($res.isSuccess) {
            Write-Host "SUCCESS with password: $p"
            Write-Host "Token: $($res.data.accessToken.Substring(0, 20))..."
            break
        }
    } catch {
        # continue
    }
}
