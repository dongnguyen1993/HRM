Add-Type -Path "D:\HRM\HRM.Backend\HRM.Backend\bin\Debug\net8.0\ClosedXML.dll"
$wb = New-Object ClosedXML.Excel.XLWorkbook("D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx")
$s1 = $wb.Worksheet(1)
for ($r = 1; $r -le 6; $r++) {
    $vals = @()
    for ($c = 1; $c -le 35; $c++) {
        $v = $s1.Cell($r, $c).GetString()
        if ($v) { $vals += "Col$c=$v" }
    }
    Write-Host "Row $r : $($vals -join ' | ')"
}
$wb.Dispose()
