$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx')
$ws = $wb.Worksheets.Item(1)
Write-Host "B7: '$($ws.Range('B7').Text)'"
Write-Host "B8: '$($ws.Range('B8').Text)'"
Write-Host "B9: '$($ws.Range('B9').Text)'"
Write-Host "B10: '$($ws.Range('B10').Text)'"
Write-Host "B35: '$($ws.Range('B35').Text)'"
Write-Host "C35: '$($ws.Range('C35').Text)'"
Write-Host "E35: '$($ws.Range('E35').Text)'"
Write-Host "F35: '$($ws.Range('F35').Text)'"
Write-Host "H35: '$($ws.Range('H35').Text)'"
Write-Host "J35: '$($ws.Range('J35').Text)'"
Write-Host "B36: '$($ws.Range('B36').Text)'"
$wb.Close($false)
$excel.Quit()
