# ==============================================================================
# SCRIPT KHỞI TẠO HOẶC RESTORE DATABASE HRM_ENTERPRISE_DB VÀO DOCKER SQL SERVER
# ==============================================================================

Write-Host "Đang kiểm tra container SQL Server (hrm-sqlserver)..." -ForegroundColor Cyan
$containerId = docker ps -q -f "name=hrm-sqlserver"

if (-not $containerId) {
    Write-Host "[LỖI] Container 'hrm-sqlserver' chưa chạy. Vui lòng chạy 'docker compose up -d' trước!" -ForegroundColor Red
    exit 1
}

Write-Host "Đang chờ SQL Server sẵn sàng..." -ForegroundColor Yellow
$maxRetries = 10
$retry = 0
$isReady = $false

while ($retry -lt $maxRetries) {
    $test = docker exec hrm-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Sa@123456 -C -Q "SELECT 1" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $isReady = $true
        break
    }
    Start-Sleep -Seconds 3
    $retry++
}

if (-not $isReady) {
    Write-Host "[LỖI] SQL Server không phản hồi sau $maxRetries lần thử." -ForegroundColor Red
    exit 1
}

Write-Host "SQL Server đã sẵn sàng. Đang kiểm tra xem database HRM_Enterprise_DB đã tồn tại chưa..." -ForegroundColor Green
$dbCheck = docker exec hrm-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Sa@123456 -C -Q "IF DB_ID('HRM_Enterprise_DB') IS NOT NULL PRINT 'EXISTS'" 2>&1

if ($dbCheck -like "*EXISTS*") {
    Write-Host "Database 'HRM_Enterprise_DB' đã tồn tại trong container." -ForegroundColor Yellow
} else {
    Write-Host "Đang thực thi file HRM_Enterprise_DB.sql để tạo cấu trúc và dữ liệu bảng..." -ForegroundColor Cyan
    docker exec hrm-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Sa@123456 -C -i /docker-init/HRM_Enterprise_DB.sql
    Write-Host "Đã khởi tạo database HRM_Enterprise_DB thành công!" -ForegroundColor Green
}
