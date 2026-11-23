[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $p1 = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\template_Payslip.xlsx"
    $p2 = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx"
    $wb1 = $excel.Workbooks.Open($p1)
    $wb2 = $excel.Workbooks.Open($p2)
    $ws1 = $wb1.Sheets.Item(1)
    $ws2 = $wb2.Sheets.Item(1)
    
    Write-Host "Comparing Rows 1 to 40..."
    for ($r = 1; $r -le 40; $r++) {
        $t1 = $ws1.Cells.Item($r, 1).Text.Trim()
        $t2 = $ws2.Cells.Item($r, 1).Text.Trim()
        if ($t1 -ne $t2) {
            Write-Host "Row $r DIFF => Payslip: '$t1' vs MySalary: '$t2'"
        }
    }
    $wb1.Close($false)
    $wb2.Close($false)
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
