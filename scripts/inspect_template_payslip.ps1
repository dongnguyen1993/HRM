[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $wb = $excel.Workbooks.Open('D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\template_Payslip.xlsx')
    $ws = $wb.Sheets.Item(1)
    Write-Host "=== template_Payslip.xlsx ==="
    for ($r = 1; $r -le 42; $r++) {
        $nonEmpty = @()
        for ($c = 1; $c -le 10; $c++) {
            $t = $ws.Cells.Item($r, $c).Text.Trim()
            if ($t -ne '') {
                $colLetter = [char](64 + $c)
                $nonEmpty += "$colLetter$r='$t'"
            }
        }
        if ($nonEmpty.Count -gt 0) {
            Write-Host ("Row {0:D2}: {1}" -f $r, ($nonEmpty -join ', '))
        }
    }
    $wb.Close($false)
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
