$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT u.UserId, u.UserCode, u.FullName, u.DepartmentCode, d.DepartmentCode AS DeptTableCode, d.DepartmentName, d.ParentDepartmentId
FROM Users u
LEFT JOIN Departments d ON u.DepartmentId = d.DepartmentId
WHERE u.UserCode IN ('ADMIN', '1200837', '1200801', '1200802', '1200803', '1200804', '1200805', '1200806')
"@
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
$dt | Format-Table -AutoSize
$conn.Close()
