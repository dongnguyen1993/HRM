$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT UserId, UserCode, FullName, DepartmentCode FROM Users WHERE DepartmentCode LIKE 'DEPT_%'"
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
$dt | Format-Table -AutoSize
$conn.Close()
