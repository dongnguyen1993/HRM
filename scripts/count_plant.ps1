$conn = New-Object System.Data.SqlClient.SqlConnection('Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;')
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT Plant, COUNT(*) FROM Users GROUP BY Plant"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Output ($r[0] + ": " + $r[1])
}
$r.Close()
$conn.Close()
