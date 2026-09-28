$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
try {
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CommonCodes' ORDER BY ORDINAL_POSITION"
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        Write-Host ($reader["COLUMN_NAME"] + " | " + $reader["DATA_TYPE"] + " (" + $reader["CHARACTER_MAXIMUM_LENGTH"] + ") | Nullable: " + $reader["IS_NULLABLE"])
    }
    $reader.Close()

    Write-Host "`nSample CommonCodes rows:"
    $cmd.CommandText = "SELECT TOP 5 CommonCodeId, GroupCode, GroupName, Code, CodeName, SortOrder, IsActive, CreatedAt FROM CommonCodes"
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        Write-Host ($reader["GroupCode"] + " | " + $reader["GroupName"] + " | " + $reader["Code"] + " | " + $reader["CodeName"] + " | Sort:" + $reader["SortOrder"] + " | Active:" + $reader["IsActive"])
    }
    $reader.Close()
} catch {
    Write-Error $_.Exception.Message
} finally {
    $conn.Close()
}
