$connStr = 'Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;'
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    u.UserCode, 
    u.FullName, 
    u.DepartmentCode, 
    d.DepartmentName, 
    u.MealDepartmentId, 
    u.MealDepartmentCode, 
    md.DepartmentName AS MealDepartmentName 
FROM Users u 
LEFT JOIN Departments d ON u.DepartmentCode = d.DepartmentCode AND d.UseFlag = 1 
LEFT JOIN Departments md ON u.MealDepartmentId = md.DepartmentId AND md.UseFlag = 1 
WHERE u.MealDepartmentId IS NOT NULL
"@
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
$dt | Format-Table -AutoSize
$conn.Close()
