$ErrorActionPreference = "Stop"

$loginBody = @{
    userCode = "ADMIN"
    password = "123456"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:7014/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.data.accessToken

$headers = @{
    Authorization = "Bearer $token"
}

$outputPath = "D:\HRM\scripts\test_month8.xlsx"
if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

$exportUrl = "http://localhost:7014/api/meal-orders/admin/export-excel?fromDate=2026-08-26&toDate=2026-09-19"
Invoke-WebRequest -Uri $exportUrl -Method Get -Headers $headers -OutFile $outputPath
Write-Host "Downloaded to $outputPath (Size: $((Get-Item $outputPath).Length) bytes)"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fs = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)

$ssEntry = $zip.GetEntry("xl/sharedStrings.xml")
$sharedStrings = @()
if ($ssEntry) {
    $sr = New-Object System.IO.StreamReader($ssEntry.Open())
    $ssXml = [xml]$sr.ReadToEnd()
    $sr.Close()
    foreach ($si in $ssXml.sst.si) {
        $txt = $si.t
        if (-not $txt) { $txt = ($si.r | ForEach-Object { $_.t }) -join '' }
        $sharedStrings += $txt
    }
}

$s1Entry = $zip.GetEntry("xl/worksheets/sheet1.xml")
if ($s1Entry) {
    $sr = New-Object System.IO.StreamReader($s1Entry.Open())
    $xml = [xml]$sr.ReadToEnd()
    $sr.Close()

    Write-Host "`n--- SHEET 1 SUMMARY TABLE (AM4:AR7) ---"
    foreach ($row in $xml.worksheet.sheetData.row) {
        $r = [int]$row.r
        if ($r -ge 4 -and $r -le 7) {
            $cells = @()
            foreach ($c in $row.c) {
                $ref = $c.r
                if ($ref -match "^(A[M-R])") {
                    $val = $c.v
                    if ($c.t -eq "s" -and $val) { $val = $sharedStrings[[int]$val] }
                    $f = $c.f
                    if ($f) {
                        $cells += "$ref=[$f]=$val"
                    } else {
                        $cells += "$ref=$val"
                    }
                }
            }
            Write-Host "Row $r : $($cells -join ' | ')"
        }
    }
}

$zip.Dispose()
$fs.Close()
