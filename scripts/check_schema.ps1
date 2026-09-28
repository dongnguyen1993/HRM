$conn = New-Object System.Data.SqlClient.SqlConnection('Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;')
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT GroupCode, GroupName, Code, CodeName, SortOrder, UseFlag FROM CommonCodes ORDER BY GroupCode, SortOrder"
$r = $cmd.ExecuteReader()
while ($r.Read()) {
    Write-Output ($r[0] + " | " + $r[1] + " | " + $r[2] + " | " + $r[3] + " | " + $r[4] + " | " + $r[5])
}
$r.Close()
$conn.Close()
