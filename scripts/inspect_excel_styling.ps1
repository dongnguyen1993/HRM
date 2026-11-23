[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
    $filePath = 'D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Data\Salary-VN_09-2026_IT.xlsb'
    $wb = $excel.Workbooks.Open($filePath, 0, $true)
    $ws = $wb.Sheets.Item("PHIẾU LƯƠNG")
    
    Write-Host "=== COLUMN WIDTHS (Cols 1-10) ==="
    for ($c = 1; $c -le 10; $c++) {
        $colLetter = [char](64 + $c)
        Write-Host "Col $c ($colLetter): Width = $($ws.Columns.Item($c).ColumnWidth)"
    }
    
    Write-Host "`n=== MERGED CELLS IN RANGE A1:J40 ==="
    $range = $ws.Range("A1:J40")
    for ($r = 1; $r -le 40; $r++) {
        for ($c = 1; $c -le 10; $c++) {
            $cell = $ws.Cells.Item($r, $c)
            if ($cell.MergeCells -and ($cell.Address -eq $cell.MergeArea.Item(1,1).Address)) {
                Write-Host "Merged: $($cell.MergeArea.Address) -> Text: '$($cell.Text)'"
            }
        }
    }

    Write-Host "`n=== ROW HEIGHTS (Rows 1-40) ==="
    for ($r = 1; $r -le 40; $r++) {
        Write-Host ("Row {0:D2} : Height = {1}" -f $r, $ws.Rows.Item($r).RowHeight)
    }
    
    $wb.Close($false)
} catch {
    Write-Host "Error: $($_.Exception.Message)"
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
