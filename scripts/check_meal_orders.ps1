$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    CONVERT(VARCHAR(10), OrderDate, 120) AS OrderDate,
    COUNT(*) AS DeptCount,
    SUM(TotalMeals) AS TotalMeals,
    SUM(DayLunchCount) AS Lunch,
    SUM(DayOtCount) AS DayOt,
    SUM(NightDinnerCount) AS Dinner,
    SUM(NightOtCount) AS NightOt,
    SUM(VegetarianCount) AS Veg
FROM DepartmentMealOrders
GROUP BY OrderDate
ORDER BY OrderDate DESC;
"@
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dt = New-Object System.Data.DataTable
$adapter.Fill($dt) | Out-Null
$dt | Format-Table -AutoSize
$conn.Close()
