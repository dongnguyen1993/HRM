$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    d.DepartmentId,
    d.DepartmentCode,
    d.DepartmentName,
    d.SortOrder
FROM Departments d WITH (NOLOCK)
WHERE d.UseFlag = 1 
  AND d.ParentDepartmentId = (SELECT TOP 1 DepartmentId FROM Departments WHERE DepartmentCode = 'DIV_MEAL')
ORDER BY d.SortOrder ASC, d.DepartmentCode ASC;
"@
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
$dt | Format-Table -AutoSize
$conn.Close()
