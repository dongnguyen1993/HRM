[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $files = @('template_Payslip.xlsx', 'Template_MySalary.xlsx')
    foreach ($f in $files) {
        $p = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\$f"
        $wb = $excel.Workbooks.Open($p)
        $ws = $wb.Sheets.Item(1)
        Write-Host "`n=== FILE: $f ==="
        for ($r = 34; $r -le 41; $r++) {
            $h = $ws.Rows.Item($r).Hidden
            $rowHeight = $ws.Rows.Item($r).RowHeight
            $valA = $ws.Cells.Item($r, 1).Text
            $valB = $ws.Cells.Item($r, 2).Text
            $valD = $ws.Cells.Item($r, 4).Text
            Write-Host "Row $r (Height: $rowHeight, Hidden: $h) => A: '$valA' | B: '$valB' | D: '$valD'"
        }
        $wb.Close($false)
    }
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
