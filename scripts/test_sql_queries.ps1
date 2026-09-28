$connStr = 'Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;'
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

Write-Host "=== TEST 1: SELECT [GetPagedUsers] WITH MEAL DEPT JOIN ==="
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT TOP 5
    u.UserId,
    u.SecureId,
    u.Plant,
    u.UserCode,
    u.FullName,
    u.Email,
    u.Status,
    u.DepartmentCode,
    d.DepartmentName,
    u.MealDepartmentId,
    u.MealDepartmentCode,
    md.DepartmentName AS MealDepartmentName
FROM Users u WITH (NOLOCK)
LEFT JOIN Departments d WITH (NOLOCK) ON u.DepartmentCode = d.DepartmentCode AND d.UseFlag = 1
LEFT JOIN Departments md WITH (NOLOCK) ON u.MealDepartmentId = md.DepartmentId AND md.UseFlag = 1
ORDER BY u.UserId
"@
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
$dt | Format-Table -AutoSize

Write-Host "=== TEST 2: VERIFY ALL 20 MEAL DEPARTMENTS ==="
$cmd2 = $conn.CreateCommand()
$cmd2.CommandText = "SELECT DepartmentId, DepartmentCode, DepartmentName, SortOrder FROM Departments WHERE ParentDepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'DIV_MEAL') AND UseFlag = 1 ORDER BY SortOrder"
$adapter2 = New-Object System.Data.SqlClient.SqlDataAdapter($cmd2)
$dt2 = New-Object System.Data.DataTable
$adapter2.Fill($dt2) | Out-Null
Write-Host "Meal Dept count: $($dt2.Rows.Count)"
$dt2 | Format-Table -AutoSize

$conn.Close()
