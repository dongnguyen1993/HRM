$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx')
$ws = $wb.Worksheets.Item(1)
Write-Host "Orientation: $($ws.PageSetup.Orientation)"
Write-Host "PaperSize: $($ws.PageSetup.PaperSize)"
Write-Host "PrintArea: $($ws.PageSetup.PrintArea)"
Write-Host "FitToPagesWide: $($ws.PageSetup.FitToPagesWide)"
Write-Host "FitToPagesTall: $($ws.PageSetup.FitToPagesTall)"
Write-Host "Zoom: $($ws.PageSetup.Zoom)"
$wb.Close($false)
$excel.Quit()
