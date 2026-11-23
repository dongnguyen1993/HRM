$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false

Write-Host "--- Template_MySalary.xlsx ---"
$wb1 = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx')
$ws1 = $wb1.Worksheets.Item(1)
for ($r = 35; $r -le 40; $r++) {
    for ($c = 1; $c -le 10; $c++) {
        $val = $ws1.Cells.Item($r, $c).Text
        $formula = $ws1.Cells.Item($r, $c).Formula
        if ($val -or $formula) {
            Write-Host "Row $r Col $c ($([char](64+$c))$r): Text='$val' | Formula='$formula'"
        }
    }
}
$wb1.Close($false)

Write-Host "`n--- template_Payslip.xlsx ---"
$wb2 = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\template_Payslip.xlsx')
$ws2 = $wb2.Worksheets.Item(1)
for ($r = 35; $r -le 40; $r++) {
    for ($c = 1; $c -le 10; $c++) {
        $val = $ws2.Cells.Item($r, $c).Text
        $formula = $ws2.Cells.Item($r, $c).Formula
        if ($val -or $formula) {
            Write-Host "Row $r Col $c ($([char](64+$c))$r): Text='$val' | Formula='$formula'"
        }
    }
}
$wb2.Close($false)

$excel.Quit()
