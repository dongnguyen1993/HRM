$conn = New-Object System.Data.SqlClient.SqlConnection('Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;')
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT DISTINCT Plant FROM Users"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Output ("User.Plant: " + $r[0])
}
$r.Close()
$conn.Close()
