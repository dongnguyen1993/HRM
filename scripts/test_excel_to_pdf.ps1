[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
try {
    $src = 'D:\HRM\scripts\test_exported_payslip.xlsx'
    $pdf = 'D:\HRM\scripts\test_exported_payslip.pdf'
    if (Test-Path $pdf) { Remove-Item $pdf -Force }
    $wb = $excel.Workbooks.Open($src)
    # 0 = xlTypePDF
    $wb.ExportAsFixedFormat(0, $pdf)
    $wb.Close($false)
    Write-Host "PDF Generated Successfully! Size: $((Get-Item $pdf).Length) bytes"
} catch {
    Write-Host "Error: $_"
} finally {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
