[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
    $filePath = 'D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Data\Salary-VN_09-2026_IT.xlsb'
    $wb = $excel.Workbooks.Open($filePath, 0, $true)
    Write-Host "=== SHEETS IN WORKBOOK ==="
    foreach ($ws in $wb.Sheets) {
        Write-Host "Sheet: $($ws.Name)"
    }
    
    $sheet = $null
    foreach ($ws in $wb.Sheets) {
        if ($ws.Name -like "*PHIẾU LƯƠNG*" -or $ws.Name -like "*PHIEU LUONG*") {
            $sheet = $ws
            break
        }
    }
    
    if ($sheet) {
        Write-Host "`n=== FOUND SHEET: $($sheet.Name) ==="
        # Read the first 40 rows and 15 columns
        for ($r = 1; $r -le 40; $r++) {
            $rowVals = @()
            for ($c = 1; $c -le 15; $c++) {
                $v = $sheet.Cells.Item($r, $c).Text
                $rowVals += if ($v) { $v } else { "" }
            }
            $nonEmpty = $rowVals | Where-Object { $_ -ne "" }
            if ($nonEmpty.Count -gt 0) {
                Write-Host ("Row {0:D2}: {1}" -f $r, ($rowVals -join " | "))
            }
        }
    } else {
        Write-Host "Sheet PHIẾU LƯƠNG not found!"
    }
    $wb.Close($false)
} catch {
    Write-Host "Error: $($_.Exception.Message)"
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
