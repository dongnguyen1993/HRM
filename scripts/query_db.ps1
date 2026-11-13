param (
    [string]$query
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$appSettings = Get-Content "d:\HRM\HRM.Backend\HRM.Backend\appsettings.json" -Encoding UTF8 | ConvertFrom-Json
$connStr = $appSettings.ConnectionStrings.DefaultConnection
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = $query
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$ds = New-Object System.Data.DataSet
$adapter.Fill($ds) | Out-Null
foreach ($table in $ds.Tables) {
    $table | Format-Table -AutoSize
}
$conn.Close()

