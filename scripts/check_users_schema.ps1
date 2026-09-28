$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
try {
    $conn.Open()
    Write-Host "DB Connected Successfully"
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users'"
    $reader = $cmd.ExecuteReader()
    $cols = @()
    while ($reader.Read()) { $cols += $reader["COLUMN_NAME"] }
    $reader.Close()
    Write-Host ("Users Columns: " + ($cols -join ", "))

    $cmd.CommandText = "SELECT GroupCode, Code, CodeName FROM CommonCodes WHERE GroupCode IN ('PLANT', 'AREA')"
    $reader = $cmd.ExecuteReader()
    Write-Host "CommonCodes for PLANT & AREA:"
    while ($reader.Read()) {
        Write-Host (" - " + $reader["GroupCode"] + " | " + $reader["Code"] + " | " + $reader["CodeName"])
    }
    $reader.Close()

    $cmd.CommandText = "SELECT DISTINCT Plant FROM Users"
    $reader = $cmd.ExecuteReader()
    Write-Host "Distinct Plant in Users:"
    while ($reader.Read()) {
        Write-Host (" - " + $reader["Plant"])
    }
    $reader.Close()
} catch {
    Write-Error $_.Exception.Message
} finally {
    $conn.Close()
}
