# ==============================================================================
# Script: Daily_Sync_Prod_To_Dev.ps1
# Mục đích: TỰ ĐỘNG HÓA SAO LƯU & ĐỒNG BỘ DỮ LIỆU TỪ DB CHÍNH SANG DB DEV HẰNG NGÀY
# Cách dùng: Chạy thủ công hoặc đặt lịch chạy tự động qua Windows Task Scheduler
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$backupFolder = "D:\BACKUP\Database"
$logFile = "$backupFolder\sync_history.log"
$sqlScriptPath = "d:\HRM\scripts\Daily_Sync_Prod_To_Dev.sql"
$serverInstance = "172.26.75.23,1433" # Hoặc "localhost\SQLEXPRESS" nếu chạy trực tiếp trên Server DB

# 1. Tạo thư mục chứa file backup nếu chưa có
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "[INIT] Đã tạo thư mục sao lưu: $backupFolder" -ForegroundColor Cyan
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logMsg = "[$timestamp] Bắt đầu đồng bộ HRM_ENTERPRISE_DB sang HRM_TEST_DB..."
Write-Host $logMsg -ForegroundColor Yellow
Add-Content -Path $logFile -Value $logMsg -Encoding UTF8

try {
    # 2. Đọc nội dung file SQL
    if (-not (Test-Path $sqlScriptPath)) {
        throw "Không tìm thấy file SQL tại đường dẫn: $sqlScriptPath"
    }
    $rawSql = [System.IO.File]::ReadAllText($sqlScriptPath, [System.Text.Encoding]::UTF8)

    # 3. Kết nối với quyền Windows Auth (hoặc tài khoản sa của máy chủ)
    # Nếu chạy trực tiếp trên Server chứa SQL Server, có thể dùng Trusted_Connection=True
    $connStr = "Server=$serverInstance;Database=master;Trusted_Connection=True;TrustServerCertificate=True;Timeout=300;"
    
    # Nếu kết nối bằng tài khoản sa (bỏ comment dòng dưới nếu cần):
    # $connStr = "Server=$serverInstance;Database=master;User Id=sa;Password=MatKhauSaCuaBan;TrustServerCertificate=True;Timeout=300;"

    $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
    $conn.Open()

    # 4. Tách các batch theo từ khóa GO và thực thi lần lượt
    $batches = [System.Text.RegularExpressions.Regex]::Split($rawSql, "(?im)^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $batchCount = 0

    foreach ($batch in $batches) {
        $trimmed = $batch.Trim()
        if ($trimmed.Length -gt 0) {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $trimmed
            $cmd.CommandTimeout = 600 # 10 phút tối đa cho thao tác backup/restore
            $cmd.ExecuteNonQuery() | Out-Null
            $batchCount++
        }
    }

    $conn.Close()

    $endTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $successMsg = "[$endTimestamp] [THÀNH CÔNG] Đồng bộ thành công ($batchCount batches đã chạy)!"
    Write-Host $successMsg -ForegroundColor Green
    Add-Content -Path $logFile -Value $successMsg -Encoding UTF8
}
catch {
    $errTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errMsg = "[$errTimestamp] [THẤT BẠI] Lỗi trong quá trình đồng bộ: $_"
    Write-Host $errMsg -ForegroundColor Red
    Add-Content -Path $logFile -Value $errMsg -Encoding UTF8
    exit 1
}

