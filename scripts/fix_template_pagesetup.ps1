$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx')
$ws = $wb.Worksheets.Item(1)

$ws.PageSetup.Orientation = 2 # xlLandscape
$ws.PageSetup.PaperSize = 11   # xlPaperA5
$ws.PageSetup.Zoom = $false
$ws.PageSetup.FitToPagesWide = 1
$ws.PageSetup.FitToPagesTall = 1
$ws.PageSetup.PrintArea = 'A1:J39'
$ws.PageSetup.LeftMargin = $excel.InchesToPoints(0.2)
$ws.PageSetup.RightMargin = $excel.InchesToPoints(0.2)
$ws.PageSetup.TopMargin = $excel.InchesToPoints(0.2)
$ws.PageSetup.BottomMargin = $excel.InchesToPoints(0.2)
$ws.PageSetup.CenterHorizontally = $true

$testPdf = 'D:\HRM\scripts\test_a5_landscape.pdf'
if (Test-Path $testPdf) { Remove-Item $testPdf -Force }
$wb.ExportAsFixedFormat(0, $testPdf)

$wb.Save()
$wb.Close($false)
$excel.Quit()
Write-Host "Exported to $testPdf"
