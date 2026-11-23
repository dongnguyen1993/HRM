[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $p = 'D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx'
    $wb = $excel.Workbooks.Open($p)
    $ws = $wb.Sheets.Item(1)
    Write-Host "=== FORMULAS IN Template_MySalary.xlsx ==="
    for ($r = 1; $r -le 40; $r++) {
        for ($c = 1; $c -le 10; $c++) {
            $cell = $ws.Cells.Item($r, $c)
            $f = $cell.Formula
            if ($f -and $f.StartsWith('=')) {
                $colLetter = [char](64 + $c)
                Write-Host "$colLetter$r : $f"
            }
        }
    }
    $wb.Close($false)
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
