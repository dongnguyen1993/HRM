# ==============================================================================
# SCRIPT XUẤT DOCKER IMAGES THÀNH CÁC FILE .TAR ĐỂ CHUYỂN SANG SERVER OFFLINE
# ==============================================================================

$outDir = "d:\HRM\docker-images"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

Write-Host "1. Đang build toàn bộ hệ thống bằng Docker Compose..." -ForegroundColor Cyan
docker compose build

Write-Host "2. Đang xuất Docker Image Database (MSSQL 2022)..." -ForegroundColor Yellow
docker save -o "$outDir\hrm-sqlserver.tar" mcr.microsoft.com/mssql/server:2022-latest

Write-Host "3. Đang xuất Docker Image Backend..." -ForegroundColor Yellow
docker save -o "$outDir\hrm-backend.tar" hrm-backend

Write-Host "4. Đang xuất Docker Image Frontend..." -ForegroundColor Yellow
docker save -o "$outDir\hrm-frontend.tar" hrm-frontend

Write-Host "Hoàn thành! Toàn bộ file image đã được lưu tại: $outDir" -ForegroundColor Green
Write-Host "Trên máy chủ local, bạn chỉ cần chạy:" -ForegroundColor Cyan
Write-Host "  docker load -i hrm-sqlserver.tar"
Write-Host "  docker load -i hrm-backend.tar"
Write-Host "  docker load -i hrm-frontend.tar"
Write-Host "  docker compose up -d"
