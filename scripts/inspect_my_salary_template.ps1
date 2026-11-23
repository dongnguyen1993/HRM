[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $filePath = 'D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\Template_MySalary.xlsx'
    $wb = $excel.Workbooks.Open($filePath)
    Write-Host "=== WORKBOOK: $filePath ==="
    Write-Host "Sheet Count: $($wb.Sheets.Count)"
    for ($i = 1; $i -le $wb.Sheets.Count; $i++) {
        $s = $wb.Sheets.Item($i)
        Write-Host "Sheet $i : $($s.Name) | UsedRange: $($s.UsedRange.Address)"
    }
    
    $ws = $wb.Sheets.Item(1)
    Write-Host "=== SHEET: $($ws.Name) CONTENT ==="
    $maxR = [Math]::Min($ws.UsedRange.Rows.Count + $ws.UsedRange.Row, 50)
    for ($r = 1; $r -le $maxR; $r++) {
        $vals = @()
        for ($c = 1; $c -le 12; $c++) {
            $t = $ws.Cells.Item($r, $c).Text
            $vals += $t
        }
        $line = ($vals -join ' | ').TrimEnd(' |')
        if ($line.Replace('|', '').Trim() -ne '') {
            Write-Host ('R{0:D2}: {1}' -f $r, $line)
        }
    }
    
    Write-Host "=== COLUMN WIDTHS ==="
    for ($c = 1; $c -le 10; $c++) {
        $col = $ws.Columns.Item($c)
        Write-Host ("Col {0}: Width={1}, WidthPts={2}" -f $c, $col.ColumnWidth, $col.Width)
    }

    Write-Host "=== PAGE SETUP ==="
    Write-Host "PaperSize: $($ws.PageSetup.PaperSize)"
    Write-Host "Orientation: $($ws.PageSetup.Orientation)"
    Write-Host "Zoom: $($ws.PageSetup.Zoom)"
    Write-Host "FitToPagesWide: $($ws.PageSetup.FitToPagesWide)"
    Write-Host "FitToPagesTall: $($ws.PageSetup.FitToPagesTall)"

    $wb.Close($false)
} finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
