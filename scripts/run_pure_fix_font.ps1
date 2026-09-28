$sqlPath = "d:\HRM\scripts\pure_fix_font.sql"
$sqlScript = [System.IO.File]::ReadAllText($sqlPath, [System.Text.Encoding]::UTF8)

$connectionStrings = @(
  "Server=localhost;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;",
  "Server=localhost,14333;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
)

foreach ($connStr in $connectionStrings) {
  try {
    Write-Host "Executing UTF-8 SQL on $connStr..."
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sqlScript
    $cmd.ExecuteNonQuery() | Out-Null
    $conn.Close()
    Write-Host "SUCCESS: Updated Vietnamese font on $connStr" -ForegroundColor Green
  } catch {
    Write-Host "ERROR on $connStr : $_" -ForegroundColor Red
  }
}
