[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $p = 'D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx'
    $wb = $excel.Workbooks.Open($p)
    $ws = $wb.Sheets.Item(1)
    Write-Host "=== DETAILS OF Template_MySalary.xlsx ==="
    for ($r = 6; $r -le 39; $r++) {
        $nonEmpty = @()
        for ($c = 1; $c -le 10; $c++) {
            $cell = $ws.Cells.Item($r, $c)
            $colLetter = [char](64 + $c)
            $text = $cell.Text.Trim()
            if ($text -ne '') {
                $nonEmpty += "$colLetter$r='$text'"
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
