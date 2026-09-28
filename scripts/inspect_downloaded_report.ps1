$body = @{ UserCode = "ADMIN"; Password = "123456" } | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "http://localhost:5020/api/auth/login" -Method Post -Body $body -ContentType "application/json"
$token = $loginRes.data.accessToken

$outFile = "d:\HRM\scripts\sample_export.xlsx"
if (Test-Path $outFile) { Remove-Item $outFile }

$client = New-Object System.Net.WebClient
$client.Headers.Add("Authorization", "Bearer $token")
$client.DownloadFile("http://localhost:5020/api/meal-orders/admin/export-excel?fromDate=2026-09-01&toDate=2026-09-18", $outFile)

Write-Host "Downloaded size: $((Get-Item $outFile).Length) bytes"

# Inspect sheet1.xml inside the zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($outFile)
Write-Host "Zip Entries count: $($zip.Entries.Count)"
$s1 = $zip.GetEntry("xl/worksheets/sheet1.xml")
if ($s1) {
    $sr = New-Object System.IO.StreamReader($s1.Open())
    $xml = [xml]$sr.ReadToEnd()
    $sr.Close()
    # Check Row 3 (GA Lunch)
    $r3 = $xml.worksheet.sheetData.row | Where-Object { $_.r -eq "3" }
    $vals = @()
    foreach ($c in $r3.c) {
        $vals += "$($c.r)=$($c.v)"
    }
    Write-Host "Row 3 cells (GA lunch): $($vals -join ' | ')"
}
$zip.Dispose()
