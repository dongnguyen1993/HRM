param (
    [string]$sqlFile,
    [string]$sqlCommand
)

# BẮT BUỘC: Đảm bảo UTF-8 cho Console & PowerShell để không bị vỡ font tiếng Việt
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$appSettings = Get-Content "d:\HRM\HRM.Backend\HRM.Backend\appsettings.json" -Encoding UTF8 | ConvertFrom-Json
$connStr = $appSettings.ConnectionStrings.DefaultConnection

$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

$rawSql = ""
if ($sqlFile) {
    # Đọc file SQL với Encoding UTF8 tường minh
    $rawSql = [System.IO.File]::ReadAllText($sqlFile, [System.Text.Encoding]::UTF8)
} else {
    $rawSql = $sqlCommand
}

# Tách các batch theo từ khóa GO (chuẩn SSMS / T-SQL)
$batches = [System.Text.RegularExpressions.Regex]::Split($rawSql, "(?im)^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline)

$totalExecuted = 0
foreach ($batch in $batches) {
    $trimmed = $batch.Trim()
    if ($trimmed.Length -gt 0) {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $trimmed
        $cmd.CommandTimeout = 120
        $cmd.ExecuteNonQuery() | Out-Null
        $totalExecuted++
    }
}

$conn.Close()
Write-Host "Execution finished. Batches executed: $totalExecuted"
