[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $dir = 'D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import'
    $files = @('template_Payslip.xlsx', 'template_Salary.xlsx', 'Template_MySalary.xlsx')
    foreach ($fn in $files) {
        $path = Join-Path $dir $fn
        if (Test-Path $path) {
            $wb = $excel.Workbooks.Open($path)
            Write-Host "=== FILE: $fn ==="
            for ($i = 1; $i -le $wb.Sheets.Count; $i++) {
                $ws = $wb.Sheets.Item($i)
                Write-Host "  Sheet $($ws.Name) | UsedRange: $($ws.UsedRange.Address)"
                Write-Host "    A1: $($ws.Range('A1').Text)"
                Write-Host "    A6: $($ws.Range('A6').Text)"
                Write-Host "    A7: $($ws.Range('A7').Text)"
                Write-Host "    A12: $($ws.Range('A12').Text)"
                Write-Host "    A13: $($ws.Range('A13').Text)"
                Write-Host "    A14: $($ws.Range('A14').Text)"
            }
            $wb.Close($false)
        } else {
            Write-Host "File not found: $fn"
        }
    }
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
