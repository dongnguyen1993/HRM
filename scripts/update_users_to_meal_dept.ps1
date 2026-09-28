$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
UPDATE Users SET DepartmentCode = 'IT',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'IT')   WHERE UserCode = 'ADMIN';
UPDATE Users SET DepartmentCode = 'HR',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'HR')   WHERE UserCode = '1200837';
UPDATE Users SET DepartmentCode = 'VB',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'VB')   WHERE UserCode IN ('1200838', '1200840');
UPDATE Users SET DepartmentCode = 'VPSX', DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'VPSX') WHERE UserCode = '1200839';
UPDATE Users SET DepartmentCode = 'VPSX', DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'VPSX') WHERE UserCode = '1200810';
UPDATE Users SET DepartmentCode = 'GA',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'GA')   WHERE UserCode IN ('1200819', '1200825');
UPDATE Users SET DepartmentCode = 'KOREAN', DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'KOREAN') WHERE UserCode = '1200821';
UPDATE Users SET DepartmentCode = 'HR',   DepartmentId = (SELECT DepartmentId FROM Departments WHERE DepartmentCode = 'HR')   WHERE UserCode IN ('1200822', '1200823');
"@
$rows = $cmd.ExecuteNonQuery()
Write-Host "Updated $rows user records in database."
$conn.Close()
