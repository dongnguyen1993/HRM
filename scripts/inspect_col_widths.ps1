[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $p = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx"
    $wb = $excel.Workbooks.Open($p)
    $ws = $wb.Sheets.Item(1)
    Write-Host "=== COLUMN WIDTHS IN Template_MySalary.xlsx ==="
    for ($c = 1; $c -le 10; $c++) {
        $colLetter = [char](64 + $c)
        $w = $ws.Columns.Item($c).ColumnWidth
        Write-Host "Col $colLetter ($c): Width = $w"
    }
    
    Write-Host "`n=== ROW 14-25 TEXT AND CELL FONT SIZES ==="
    for ($r = 14; $r -le 25; $r++) {
        $txtA = $ws.Cells.Item($r, 1).Text
        $fontA = $ws.Cells.Item($r, 1).Font.Size
        $txtD = $ws.Cells.Item($r, 4).Text
        $fontD = $ws.Cells.Item($r, 4).Font.Size
        Write-Host ("Row {0}: Col A='{1}' (Font: {2}) | Col D='{3}' (Font: {4})" -f $r, $txtA, $fontA, $txtD, $fontD)
    }
    $wb.Close($false)
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
