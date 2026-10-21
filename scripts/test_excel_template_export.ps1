$nugetPackages = Join-Path $env:USERPROFILE ".nuget\packages"
$closedXmlDll = Join-Path $nugetPackages "closedxml\0.105.1\lib\netstandard2.1\ClosedXML.dll"
$docFormatDll = Join-Path $nugetPackages "documentformat.openxml\3.1.1\lib\netstandard2.0\DocumentFormat.OpenXml.dll"
$docFormatFwDll = Join-Path $nugetPackages "documentformat.openxml.framework\3.1.1\lib\netstandard2.0\DocumentFormat.OpenXml.Framework.dll"
$sixLaborsDll = Join-Path $nugetPackages "sixlabors.fonts\1.0.0\lib\netstandard2.0\SixLabors.Fonts.dll"
$excelNumFmt = Join-Path $nugetPackages "excelnumberformat\1.1.0\lib\netstandard2.0\ExcelNumberFormat.dll"
$rbushDll = Join-Path $nugetPackages "rbush.signed\4.0.0\lib\netstandard2.0\RBush.dll"

Add-Type -Path $docFormatFwDll
Add-Type -Path $docFormatDll
Add-Type -Path $sixLaborsDll
Add-Type -Path $excelNumFmt
Add-Type -Path $rbushDll
Add-Type -Path $closedXmlDll

$backendRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "HRM.Backend\HRM.Backend"
$templatePath = Join-Path $backendRoot "wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
$wb = New-Object ClosedXML.Excel.XLWorkbook($templatePath)
Write-Host "Worksheets count: $($wb.Worksheets.Count)"
foreach ($ws in $wb.Worksheets) {
    Write-Host "Sheet name: $($ws.Name)"
}
$s1 = $wb.Worksheet(1)
Write-Host "A1 value: $($s1.Cell('A1').Value)"
$s1.Cell("I3").Value = 25 # Day 1 Lunch GA
$outputPath = Join-Path $backendRoot "wwwroot\Excel_Import\Test_Output.xlsx"
$wb.SaveAs($outputPath)
$wb.Dispose()
Write-Host "Successfully saved to $outputPath"
if (Test-Path $outputPath) { Remove-Item $outputPath }
