[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Start-Sleep -Seconds 3

# Login ADMIN
$loginBody = '{"UserCode":"ADMIN","Password":"Hansol@12345"}'
$login = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
$headers = @{ Authorization = "Bearer $($login.data.accessToken)" }

# Export Excel
$outXlsx = 'd:\HRM\scripts\test_notes_row.xlsx'
if (Test-Path $outXlsx) { Remove-Item $outXlsx -Force }
Invoke-WebRequest -Uri 'http://localhost:7014/api/ess/my-payslip/export-excel?periodId=2026-08' -Headers $headers -OutFile $outXlsx
Write-Host "Exported Excel Size: $((Get-Item $outXlsx).Length) bytes"

# Inspect with Excel COM
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb = $excel.Workbooks.Open($outXlsx)
$ws = $wb.Worksheets.Item(1)

Write-Host "A37 Text: '$($ws.Range('A37').Text)'"
Write-Host "B37 Text: '$($ws.Range('B37').Text)'"
Write-Host "B38 Text: '$($ws.Range('B38').Text)'"
Write-Host "A39 Text: '$($ws.Range('A39').Text)'"

$wb.Close($false)
$excel.Quit()
