[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = "d:\HRM\HRM.Backend\HRM.Backend"
$core = Join-Path $root "Core"

Write-Host "Creating target directories..."
$dirs = @(
    "Domains\GA\DTOs", "Domains\GA\Repositories", "Domains\GA\Services",
    "Domains\ESS\DTOs", "Domains\ESS\Repositories", "Domains\ESS\Services",
    "Domains\HR\DTOs", "Domains\HR\Entities", "Domains\HR\Repositories", "Domains\HR\Services",
    "Domains\SYS\DTOs", "Domains\SYS\Entities", "Domains\SYS\Repositories", "Domains\SYS\Services",
    "Common\Primitives", "Common\Attributes", "Common\Exceptions", "Common\Helpers", "Common\Interfaces"
)

foreach ($d in $dirs) {
    $p = Join-Path $root $d
    if (-not (Test-Path $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

$allCoreFiles = Get-ChildItem -Recurse -File $core

Write-Host "Moving $($allCoreFiles.Count) files from Core to Domains & Common..."

foreach ($file in $allCoreFiles) {
    $rel = $file.FullName.Substring($core.Length + 1)
    $name = $file.Name

    $destDomain = ""
    $destSub = ""

    # Common Primitives
    if ($name -in @("BaseResponse.cs", "PagedRequest.cs", "PagedResponse.cs", "BusinessException.cs", "PermissionAttribute.cs", "CryptoHelper.cs", "DiskHealthCheck.cs", "PasswordHelper.cs", "PasswordRotationHelper.cs", "ICurrentUserService.cs")) {
        $destDomain = "Common"
        if ($name -like "*Helper.cs" -or $name -like "*HealthCheck.cs") { $destSub = "Helpers" }
        elseif ($name -eq "BusinessException.cs") { $destSub = "Exceptions" }
        elseif ($name -eq "PermissionAttribute.cs") { $destSub = "Attributes" }
        elseif ($name -eq "ICurrentUserService.cs") { $destSub = "Interfaces" }
        else { $destSub = "Primitives" }
    }
    # GA Domain
    elseif ($rel -like "*GeneralAffairs*" -or $rel -like "*\Meal*" -or $name -like "*Meal*" -or $name -like "*Visitor*" -or $name -like "*WorkCalendar*" -or $name -eq "CalendarDayDto.cs" -or $name -eq "CanteenDailySummaryDto.cs" -or $name -eq "UpdateDayShiftRequestDto.cs" -or $name -eq "BatchSpecialMealRequestDto.cs" -or $name -eq "SpecialMealDto.cs" -or $name -eq "GaDepartmentDto.cs") {
        $destDomain = "Domains\GA"
        if ($name -like "*Repository.cs") { $destSub = "Repositories" }
        elseif ($name -like "*Service.cs") { $destSub = "Services" }
        else { $destSub = "DTOs" }
    }
    # ESS Domain
    elseif ($rel -like "*HomeUser*" -or $name -like "*HomeUser*" -or $name -like "*DashboardUser*" -or $name -like "*DailyWorkTime*" -or $name -like "*MyMealOrder*" -or $name -like "*MyPayslip*" -or $name -like "*WorkSchedule*") {
        $destDomain = "Domains\ESS"
        if ($name -like "*Repository.cs") { $destSub = "Repositories" }
        elseif ($name -like "*Service.cs") { $destSub = "Services" }
        else { $destSub = "DTOs" }
    }
    # HR Domain
    elseif ($rel -like "*HumanResource*" -or $rel -like "*WorkHours*" -or $name -like "*Department*" -or $name -like "*LaborContract*" -or $name -like "*LeaveType*" -or $name -like "*Payroll*" -or $name -like "*Shift*" -or $name -like "*TimeOff*" -or $name -like "*OtRegistration*" -or $name -like "*MachineRecord*" -or $name -like "*WorkSummary*" -or $name -like "*WorkTimeReport*" -or $name -like "*Timesheet*" -or $name -like "*WorkRequest*") {
        $destDomain = "Domains\HR"
        if ($name -eq "Payroll.cs") { $destSub = "Entities" }
        elseif ($name -like "*Repository.cs") { $destSub = "Repositories" }
        elseif ($name -like "*Service.cs") { $destSub = "Services" }
        else { $destSub = "DTOs" }
    }
    # SYS Domain
    else {
        $destDomain = "Domains\SYS"
        if ($name -in @("User.cs", "UserGroupMapping.cs", "UserThemeSettings.cs", "UserToken.cs", "AuthorGroup.cs", "AuthorGroupMapping.cs", "Announcement.cs", "ProgramMenu.cs", "NotificationEntities.cs")) {
            $destSub = "Entities"
        }
        elseif ($name -like "*Repository.cs" -or $name -eq "IAuditLogQueue.cs") { $destSub = "Repositories" }
        elseif ($name -like "*Service.cs") { $destSub = "Services" }
        else { $destSub = "DTOs" }
    }

    $destPath = Join-Path (Join-Path $root $destDomain) $destSub
    $targetFile = Join-Path $destPath $name

    # Determine target namespace
    $targetNamespace = if ($destDomain -eq "Common") {
        if ($destSub -eq "Primitives") { "HRM.Backend.Common" }
        else { "HRM.Backend.Common.$destSub" }
    } else {
        "HRM.Backend.$destDomain.$destSub" -replace '\\', '.'
    }

    $content = Get-Content $file.FullName -Raw
    # Update namespace declaration
    $content = [regex]::Replace($content, 'namespace\s+HRM\.Backend\.Core[^\r\n;{]+', "namespace $targetNamespace")

    Set-Content -Path $targetFile -Value $content -Encoding UTF8
}

Write-Host "All files copied and namespaces updated in target locations."
