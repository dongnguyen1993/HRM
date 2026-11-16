[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "RA SOAT QUY CHUAN DOMAIN TOAN BO HE THONG HRM ENTERPRISE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Rà soát Backend Controllers & Routes
Write-Host "`n--- 1. BACKEND CONTROLLER ROUTES ---" -ForegroundColor Yellow
$controllerFiles = Get-ChildItem -Path "d:\HRM\HRM.Backend\HRM.Backend\Domains" -Recurse -Filter "*Controller.cs"
$ctrlResults = @()

foreach ($f in $controllerFiles) {
    $rel = $f.FullName.Replace("d:\HRM\HRM.Backend\HRM.Backend\", "")
    $lines = Get-Content $f.FullName -Encoding UTF8
    $routes = @()
    foreach ($l in $lines) {
        if ($l -match '\[Route\("([^"]+)"\)\]') {
            $routes += $matches[1]
        }
    }
    
    $expectedDomain = ""
    if ($rel -match 'Domains[\\/]([A-Za-z]+)[\\/]Controllers') {
        $expectedDomain = $matches[1].ToLower()
    }
    
    $valid = $true
    $nonStandardRoutes = @()
    foreach ($r in $routes) {
        if (-not $r.StartsWith("api/$expectedDomain")) {
            $valid = $false
            $nonStandardRoutes += $r
        }
    }
    
    $ctrlResults += [PSCustomObject]@{
        File = $f.Name
        Domain = $expectedDomain.ToUpper()
        Routes = ($routes -join ", ")
        IsValid = $valid
        Issues = ($nonStandardRoutes -join ", ")
    }
}

$ctrlResults | Format-Table -AutoSize File, Domain, Routes, IsValid, Issues

# 2. Rà soát các file Query Dapper SQL theo bảng có tiền tố
Write-Host "`n--- 2. DAPPER SQL QUERIES & TABLE PREFIXES ---" -ForegroundColor Yellow
$sqlFiles = Get-ChildItem -Path "d:\HRM\HRM.Backend\HRM.Backend\Domains" -Recurse -Filter "*.sql"
$legacyTableNames = @(
    "Users", "Departments", "LaborContracts", "LeaveTypes", "Payroll_Period", 
    "Payroll_Salary_Item", "Payroll_Employee_Monthly", "WorkShifts", "WorkSummary", 
    "MachineRecords", "WorkRequests", "OtRegistrations", "WorkCalendar", "DepartmentMealOrders", 
    "ProgramMenus", "AuthorGroups", "AuthorGroupMapping", "CommonCodes", "AuditLogs", 
    "SignInLogs", "Announcements", "NotificationEvents", "Notifications", "DeviceSetup"
)

$sqlResults = @()
foreach ($sf in $sqlFiles) {
    $content = Get-Content $sf.FullName -Raw -Encoding UTF8
    $foundLegacy = @()
    
    foreach ($tbl in $legacyTableNames) {
        $pattern = "(FROM|JOIN|INTO|UPDATE)\s+(dbo\.)?$tbl\b"
        if ($content -match $pattern) {
            $fullMatch = $matches[0]
            if ($fullMatch -notmatch "(SYS_|HR_|GA_|ESS_)$tbl\b") {
                $foundLegacy += $tbl
            }
        }
    }
    
    $sqlResults += [PSCustomObject]@{
        SqlFile = $sf.Name
        Path = $sf.FullName.Replace("d:\HRM\HRM.Backend\HRM.Backend\Domains\", "")
        HasLegacyTable = ($foundLegacy.Count -gt 0)
        LegacyTables = ($foundLegacy -join ", ")
    }
}

$sqlResults | Format-Table -AutoSize SqlFile, HasLegacyTable, LegacyTables

# 3. Rà soát Frontend API Service URLs
Write-Host "`n--- 3. FRONTEND API CALLS IN SERVICES ---" -ForegroundColor Yellow
$feServices = Get-ChildItem -Path "d:\HRM\HRM.Frontend\src\pages" -Recurse -Filter "service.ts"
$feResults = @()

foreach ($fs in $feServices) {
    $rel = $fs.FullName.Replace("d:\HRM\HRM.Frontend\src\pages\", "")
    $domain = ""
    if ($rel -match '^([A-Za-z]+)[\\/]') {
        $domain = $matches[1].ToLower()
    }
    
    $content = Get-Content $fs.FullName -Raw -Encoding UTF8
    $pattern = '/api/[a-zA-Z0-9_\-\/${}]+'
    $matchesApi = [regex]::Matches($content, $pattern)
    $apis = @()
    $nonStandard = @()
    
    foreach ($m in $matchesApi) {
        $val = $m.Value
        $apis += $val
        if ($domain -in @("hr", "ga", "sys", "ess")) {
            if (-not $val.StartsWith("/api/$domain") -and -not $val.StartsWith("/api/hubs")) {
                $nonStandard += $val
            }
        }
    }
    
    $feResults += [PSCustomObject]@{
        ServiceFile = $rel
        Domain = $domain.ToUpper()
        ApiCount = $apis.Count
        HasNonStandard = ($nonStandard.Count -gt 0)
        NonStandardApis = (($nonStandard | Select-Object -Unique) -join ", ")
    }
}

$feResults | Format-Table -AutoSize ServiceFile, Domain, ApiCount, HasNonStandard, NonStandardApis

# 4. Rà soát xem có Component nào gọi API trực tiếp không qua service.ts không
Write-Host "`n--- 4. DIRECT API CALLS IN COMPONENTS (OUTSIDE SERVICE.TS) ---" -ForegroundColor Yellow
$allPages = Get-ChildItem -Path "d:\HRM\HRM.Frontend\src\pages" -Recurse -Include "*.ts", "*.tsx"
$directCalls = @()

foreach ($ap in $allPages) {
    if ($ap.Name -eq "service.ts" -or $ap.Name.EndsWith(".d.ts")) { continue }
    $content = Get-Content $ap.FullName -Raw -Encoding UTF8
    $matchesApi = [regex]::Matches($content, 'request\s*(?:<[^>]+>)?\s*\(\s*[\x27\x22\x60](/api/[^\x27\x22\x60]+)[\x27\x22\x60]')
    foreach ($m in $matchesApi) {
        $directCalls += [PSCustomObject]@{
            File = $ap.FullName.Replace("d:\HRM\HRM.Frontend\src\pages\", "")
            Api = $m.Groups[1].Value
        }
    }
}

if ($directCalls.Count -eq 0) {
    Write-Host "HOAN TOAN TUAN THU: Khong co component nao goi API lung tung, 100% di qua Service layer!" -ForegroundColor Green
} else {
    $directCalls | Format-Table -AutoSize
}

# 5. Rà soát cấu trúc 1-1-1-1-1 (UI - Controller - Service - Repository - Query)
Write-Host "`n--- 5. CHECK 1-1-1-1-1 ARCHITECTURE COVERAGE ---" -ForegroundColor Yellow
$domains = @("ESS", "GA", "HR", "SYS")
foreach ($dm in $domains) {
    $cCount = (Get-ChildItem -Path "d:\HRM\HRM.Backend\HRM.Backend\Domains\$dm\Controllers" -Filter "*Controller.cs" -ErrorAction SilentlyContinue).Count
    $sCount = (Get-ChildItem -Path "d:\HRM\HRM.Backend\HRM.Backend\Domains\$dm\Services" -Filter "*Service.cs" -ErrorAction SilentlyContinue).Count
    $rCount = (Get-ChildItem -Path "d:\HRM\HRM.Backend\HRM.Backend\Domains\$dm\Repositories" -Filter "*Repository.cs" -ErrorAction SilentlyContinue).Count
    $qCount = (Get-ChildItem -Path "d:\HRM\HRM.Backend\HRM.Backend\Domains\$dm\Queries" -Filter "*.sql" -ErrorAction SilentlyContinue).Count
    $uiCount = (Get-ChildItem -Path "d:\HRM\HRM.Frontend\src\pages\$dm" -Directory -ErrorAction SilentlyContinue).Count
    
    Write-Host "[$dm Domain]: UI Folders: $uiCount | Controllers: $cCount | Services: $sCount | Repositories: $rCount | SQL Queries: $qCount" -ForegroundColor Cyan
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "KET THUC RA SOAT TOAN BO HE THONG" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
