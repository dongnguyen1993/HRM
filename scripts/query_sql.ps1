param (
    [string]$sqlCommand
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$appSettings = Get-Content "d:\HRM\HRM.Backend\HRM.Backend\appsettings.json" -Encoding UTF8 | ConvertFrom-Json
$connStr = $appSettings.ConnectionStrings.DefaultConnection

$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = $sqlCommand
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$dataset = New-Object System.Data.DataSet
$adapter.Fill($dataset) | Out-Null
$conn.Close()

$dataset.Tables[0] | Format-Table -AutoSize | Out-String | Write-Host

