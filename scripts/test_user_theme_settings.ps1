$loginBody = @{ UserCode = 'ADMIN'; Password = 'Hansol@12345' } | ConvertTo-Json
$res = Invoke-RestMethod -Uri 'http://localhost:5020/api/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
Write-Host "Login status: $($res.isSuccess)"
Write-Host "Initial UserPreferences: $(ConvertTo-Json $res.data.userPreferences -Compress)"

$token = $res.data.accessToken
$headers = @{ Authorization = "Bearer $token" }

# 1. Update preferences with new field names
$prefBody = @{
    themeMode = 'dark'
    navMode = 'top'
    sidebarStyle = 'light'
    colorWeakness = $true
    defaultLanguage = 'ko-KR'
    primaryColor = '#1890FF'
} | ConvertTo-Json

$prefRes = Invoke-RestMethod -Uri 'http://localhost:5020/api/users/my-preferences' -Method Put -Headers $headers -Body $prefBody -ContentType 'application/json'
Write-Host "Update Preferences status: $(ConvertTo-Json $prefRes -Compress)"

# 2. Query database directly to verify User_Theme_Settings
Write-Host "`nQuerying database for ADMIN in User_Theme_Settings after update:"
sqlcmd -S localhost,1433 -U sa -P 'Sa@123456' -d HRM_Enterprise_DB -Q "SELECT UserCode, ThemeMode, NavMode, SidebarStyle, ColorWeakness, DefaultLanguage, PrimaryColor, UpdatedAt FROM User_Theme_Settings WHERE UserCode = 'ADMIN';"

# 3. Log in again to verify new preferences are loaded
$res2 = Invoke-RestMethod -Uri 'http://localhost:5020/api/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
Write-Host "`nLoaded UserPreferences after update from Auth API: $(ConvertTo-Json $res2.data.userPreferences -Compress)"

# 4. Revert preferences back to original (#00A651, light, side, light, 0, vi-VN)
$revertBody = @{
    themeMode = 'light'
    navMode = 'side'
    sidebarStyle = 'light'
    colorWeakness = $false
    defaultLanguage = 'vi-VN'
    primaryColor = '#00A651'
} | ConvertTo-Json

$revertRes = Invoke-RestMethod -Uri 'http://localhost:5020/api/users/my-preferences' -Method Put -Headers $headers -Body $revertBody -ContentType 'application/json'
Write-Host "`nReverted preferences status: $(ConvertTo-Json $revertRes -Compress)"

Write-Host "`nQuerying database for ADMIN after revert:"
sqlcmd -S localhost,1433 -U sa -P 'Sa@123456' -d HRM_Enterprise_DB -Q "SELECT UserCode, ThemeMode, NavMode, SidebarStyle, ColorWeakness, DefaultLanguage, PrimaryColor, UpdatedAt FROM User_Theme_Settings WHERE UserCode = 'ADMIN';"
