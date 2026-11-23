$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx')
$ws = $wb.Worksheets.Item(1)

$b37 = $ws.Range('B37')
Write-Host "B37 Font: $($b37.Font.Name), Size: $($b37.Font.Size), Bold: $($b37.Font.Bold)"
Write-Host "B37 Text: '$($b37.Text)'"

$b38 = $ws.Range('B38')
Write-Host "B38 Font: $($b38.Font.Name), Size: $($b38.Font.Size), Bold: $($b38.Font.Bold)"
Write-Host "B38 Text: '$($b38.Text)'"

$wb.Close($false)
$excel.Quit()
