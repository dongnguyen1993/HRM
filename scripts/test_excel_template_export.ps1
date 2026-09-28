$closedXmlDll = "C:\Users\dong.nguyenlam\.nuget\packages\closedxml\0.105.1\lib\netstandard2.1\ClosedXML.dll"
$docFormatDll = "C:\Users\dong.nguyenlam\.nuget\packages\documentformat.openxml\3.1.1\lib\netstandard2.0\DocumentFormat.OpenXml.dll"
$docFormatFwDll = "C:\Users\dong.nguyenlam\.nuget\packages\documentformat.openxml.framework\3.1.1\lib\netstandard2.0\DocumentFormat.OpenXml.Framework.dll"
$sixLaborsDll = "C:\Users\dong.nguyenlam\.nuget\packages\sixlabors.fonts\1.0.0\lib\netstandard2.0\SixLabors.Fonts.dll"
$excelNumFmt = "C:\Users\dong.nguyenlam\.nuget\packages\excelnumberformat\1.1.0\lib\netstandard2.0\ExcelNumberFormat.dll"
$rbushDll = "C:\Users\dong.nguyenlam\.nuget\packages\rbush.signed\4.0.0\lib\netstandard2.0\RBush.dll"

Add-Type -Path $docFormatFwDll
Add-Type -Path $docFormatDll
Add-Type -Path $sixLaborsDll
Add-Type -Path $excelNumFmt
Add-Type -Path $rbushDll
Add-Type -Path $closedXmlDll

$templatePath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
$wb = New-Object ClosedXML.Excel.XLWorkbook($templatePath)
Write-Host "Worksheets count: $($wb.Worksheets.Count)"
foreach ($ws in $wb.Worksheets) {
    Write-Host "Sheet name: $($ws.Name)"
}
$s1 = $wb.Worksheet(1)
Write-Host "A1 value: $($s1.Cell('A1').Value)"
$s1.Cell("I3").Value = 25 # Day 1 Lunch GA
$outputPath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Test_Output.xlsx"
$wb.SaveAs($outputPath)
$wb.Dispose()
Write-Host "Successfully saved to $outputPath"
if (Test-Path $outputPath) { Remove-Item $outputPath }
