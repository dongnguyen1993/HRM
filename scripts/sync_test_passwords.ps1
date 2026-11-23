[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$appSettings = Get-Content 'd:\HRM\HRM.Backend\HRM.Backend\appsettings.json' -Encoding UTF8 | ConvertFrom-Json
$conn = New-Object System.Data.SqlClient.SqlConnection($appSettings.ConnectionStrings.DefaultConnection)
$conn.Open()

# Set password of 1200837 and 1111111 to match ADMIN password hash
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT PasswordHash FROM SYS_Users WHERE UserCode = 'ADMIN'"
$adminHash = $cmd.ExecuteScalar()

$cmd.CommandText = "UPDATE SYS_Users SET PasswordHash = @H WHERE UserCode IN ('1200837', '1111111')"
$p = $cmd.Parameters.AddWithValue("@H", $adminHash)
$cmd.ExecuteNonQuery() | Out-Null
$conn.Close()
Write-Host "Updated password hash of 1200837 and 1111111 to match Hansol@12345"
