$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb1 = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx')
$ws1 = $wb1.Worksheets.Item(1)
Write-Host "Template_MySalary A1:" $ws1.Range("A1").Text
Write-Host "Template_MySalary A6:" $ws1.Range("A6").Text
Write-Host "Template_MySalary A13:" $ws1.Range("A13").Text
$wb1.Close($false)

$wb2 = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\template_Payslip.xlsx')
$ws2 = $wb2.Worksheets.Item(1)
Write-Host "template_Payslip A1:" $ws2.Range("A1").Text
Write-Host "template_Payslip A6:" $ws2.Range("A6").Text
Write-Host "template_Payslip A13:" $ws2.Range("A13").Text
$wb2.Close($false)

$excel.Quit()
