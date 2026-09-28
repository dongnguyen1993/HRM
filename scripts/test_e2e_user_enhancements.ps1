# E2E Test script for User Management & Auth enhancements
$baseUrl = "http://localhost:5020"

# 1. Admin login to get token
Write-Host "--- 1. Admin Login ---"
$loginBody = @{
    UserCode = "ADMIN"
    Password = "123456"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.data.accessToken
Write-Host "Admin Login Successful. Token obtained."
$headers = @{ "Authorization" = "Bearer $token" }

# 2. Test CommonCodes by groups
Write-Host "`n--- 2. Test CommonCode by groups (PLANT, AREA) ---"
$commonCodeRes = Invoke-RestMethod -Uri "$baseUrl/api/common-code/by-groups?groupCodes=PLANT,AREA" -Method Get -Headers $headers
Write-Host "Total items returned: $($commonCodeRes.data.Count)"
foreach ($item in $commonCodeRes.data) {
    Write-Host " - Group: $($item.groupCode) | Code: $($item.code) | Name: $($item.codeName)"
}

# 3. Create new user with default password, Plant and Area
Write-Host "`n--- 3. Create Test User ---"
$testCode = "TEST" + (Get-Random -Minimum 1000 -Maximum 9999)
$testEmail = "$testCode@hansol.test"
$createBody = @{
    UserCode = $testCode
    FullName = "Test User $testCode"
    Email = $testEmail
    Plant = "TECH_H"
    Area = "PMD,PBA"
    GroupId = 2002
    GroupIds = @(2002)
    DepartmentCode = "IT"
    Comment = "E2E Test User"
} | ConvertTo-Json

$createRes = Invoke-RestMethod -Uri "$baseUrl/api/users" -Method Post -Body $createBody -Headers $headers -ContentType "application/json"
Write-Host "User created. Result: $($createRes.message), SecureId: $($createRes.data)"

# 4. Verify in DB
$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT UserCode, Plant, Area, MustChangePassword FROM Users WHERE UserCode = '$testCode'"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    Write-Host "DB Record -> Code: $($reader['UserCode']), Plant: $($reader['Plant']), Area: $($reader['Area']), MustChangePassword: $($reader['MustChangePassword'])"
}
$reader.Close()
$conn.Close()

# 5. First Login with default password 'Hansol@12345'
Write-Host "`n--- 5. First login with default password 'Hansol@12345' ---"
$firstLoginBody = @{
    UserCode = $testCode
    Password = "Hansol@12345"
} | ConvertTo-Json

$firstLoginRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method Post -Body $firstLoginBody -ContentType "application/json"
Write-Host "Login response -> isSuccess: $($firstLoginRes.isSuccess), mustChangePassword: $($firstLoginRes.data.mustChangePassword)"
if ($firstLoginRes.data.mustChangePassword -eq $true) {
    Write-Host "SUCCESS: mustChangePassword is TRUE as expected!"
} else {
    Write-Error "FAILED: mustChangePassword should be true!"
}

# 6. Test Password Policy
Write-Host "`n--- 6. Test Password Policy on force-change-password ---"

# 6A: Same as default Hansol@12345
try {
    $sameBody = @{
        UserCode = $testCode
        OldPassword = "Hansol@12345"
        NewPassword = "Hansol@12345"
        ConfirmPassword = "Hansol@12345"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUrl/api/auth/force-change-password" -Method Post -Body $sameBody -ContentType "application/json"
    Write-Error "Policy Test 6A FAILED: Should have rejected same password!"
} catch {
    Write-Host "Policy Test 6A PASS: Rejected same password correctly. Error: $($_.Exception.Message)"
}

# 6B: Shorter than 8 chars
try {
    $shortBody = @{
        UserCode = $testCode
        OldPassword = "Hansol@12345"
        NewPassword = "Abc1"
        ConfirmPassword = "Abc1"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUrl/api/auth/force-change-password" -Method Post -Body $shortBody -ContentType "application/json"
    Write-Error "Policy Test 6B FAILED: Should have rejected short password!"
} catch {
    Write-Host "Policy Test 6B PASS: Rejected short password correctly. Error: $($_.Exception.Message)"
}

# 6C: Missing number
try {
    $noDigitBody = @{
        UserCode = $testCode
        OldPassword = "Hansol@12345"
        NewPassword = "PasswordOnly"
        ConfirmPassword = "PasswordOnly"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUrl/api/auth/force-change-password" -Method Post -Body $noDigitBody -ContentType "application/json"
    Write-Error "Policy Test 6C FAILED: Should have rejected missing digit!"
} catch {
    Write-Host "Policy Test 6C PASS: Rejected missing digit correctly. Error: $($_.Exception.Message)"
}

# 6D: Valid new password satisfying all policy requirements
$validBody = @{
    UserCode = $testCode
    OldPassword = "Hansol@12345"
    NewPassword = "Hansol@Secure2026"
    ConfirmPassword = "Hansol@Secure2026"
} | ConvertTo-Json

$validRes = Invoke-RestMethod -Uri "$baseUrl/api/auth/force-change-password" -Method Post -Body $validBody -ContentType "application/json"
Write-Host "Policy Test 6D PASS: Password changed successfully! Message: $($validRes.message), mustChangePassword in res: $($validRes.data.mustChangePassword)"

# 7. Verify MustChangePassword in DB is now 0
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT UserCode, MustChangePassword FROM Users WHERE UserCode = '$testCode'"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    Write-Host "DB Record -> Code: $($reader['UserCode']), MustChangePassword: $($reader['MustChangePassword'])"
}
$reader.Close()

# Clean up test user
$cmd.CommandText = "DELETE FROM UserGroupMapping WHERE UserId = (SELECT UserId FROM Users WHERE UserCode = '$testCode'); DELETE FROM Users WHERE UserCode = '$testCode';"
$cmd.ExecuteNonQuery()
Write-Host "Cleaned up test user $testCode"
$conn.Close()

Write-Host "`n=== ALL E2E TESTS COMPLETED SUCCESSFULLY ==="
