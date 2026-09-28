$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT TOP 10 UserCode, Email, FullName, PasswordHash FROM Users WHERE Status = 1"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
    Write-Host ($reader["UserCode"] + " | " + $reader["Email"] + " | " + $reader["FullName"] + " | Hash: " + $reader["PasswordHash"].Substring(0, 15))
}
$reader.Close()
$conn.Close()
