$ErrorActionPreference = "Stop"

Write-Host "=== TEST /api/departments/list ==="
$res = Invoke-RestMethod -Uri "http://localhost:5020/api/departments/list" -Method Get
Write-Host "Total departments returned: $($res.data.Count)"

$mealCodes = @('DIV_MEAL', 'GA', 'HR', 'ACC', 'EX', 'IT', 'HSE', 'PUR', 'QC', 'MA', 'WH', '3IN1', 'VPSX', 'VB', 'KTSP', 'KTSX', 'SALE', 'KHSX', 'DRIVER', 'SECURITY', 'KOREAN')
$containsMealDept = $res.data | Where-Object { $mealCodes -contains $_.departmentCode.ToUpper() }

if ($containsMealDept) {
    Write-Warning "Found meal department in attendance department list:"
    $containsMealDept | Format-Table departmentId, departmentCode, departmentName
} else {
    Write-Host "SUCCESS: No meal departments found in attendance departments list!" -ForegroundColor Green
}

Write-Host "`nSample of attendance departments returned:"
$res.data | Select-Object -First 10 departmentId, departmentCode, departmentName, level | Format-Table -AutoSize
