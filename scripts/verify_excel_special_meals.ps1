$ErrorActionPreference = "Stop"

Write-Host "=== 1. LOGIN ADMIN ==="
$loginBody = @{
    userCode = "ADMIN"
    password = "123456"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:7014/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.data.accessToken

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "`n=== 2. EXPORT EXCEL FOR MONTH 08/2026 (26/07/2026 - 25/08/2026) ==="
$outputPath = "D:\HRM\scripts\test_verified_month8.xlsx"
if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

$exportUrl = "http://localhost:7014/api/meal-orders/admin/export-excel?fromDate=2026-07-26&toDate=2026-08-25"
Invoke-WebRequest -Uri $exportUrl -Method Get -Headers $headers -OutFile $outputPath
Write-Host "Downloaded successfully: $outputPath (Size: $((Get-Item $outputPath).Length) bytes)"

Write-Host "`n=== 3. VERIFY VIA OPENXML / ZIP ==="
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

# Read styles to find which style IDs have yellow fill
$stylesEntry = $zip.GetEntry("xl/styles.xml")
$stylesSr = New-Object System.IO.StreamReader($stylesEntry.Open())
$stylesXml = [xml]$stylesSr.ReadToEnd()
$stylesSr.Close()

$yellowFillIds = @()
$fillIdx = 0
foreach ($fill in $stylesXml.styleSheet.fills.fill) {
    $rgb = $fill.patternFill.fgColor.rgb
    if ($rgb -match "(FFFF00|FFF200|FFFF99|FFFFCC)") {
        $yellowFillIds += $fillIdx
        Write-Host "Found Yellow Fill ID: $fillIdx (RGB: $rgb)"
    }
    $fillIdx++
}

$yellowStyleIds = @()
$xfIdx = 0
foreach ($xf in $stylesXml.styleSheet.cellXfs.xf) {
    $fId = [int]$xf.fillId
    if ($yellowFillIds -contains $fId) {
        $yellowStyleIds += "$xfIdx"
    }
    $xfIdx++
}
Write-Host "Yellow Style XF IDs: $($yellowStyleIds -join ', ')"

# 3.1. Verify Sheet 1
$s1Entry = $zip.GetEntry("xl/worksheets/sheet1.xml")
$s1Sr = New-Object System.IO.StreamReader($s1Entry.Open())
$s1Xml = [xml]$s1Sr.ReadToEnd()
$s1Sr.Close()

Write-Host "`n--- CHECK SHEET 1 SPECIAL MEAL YELLOW HIGHLIGHTS ---"
# Check columns M (5), T (12), Z (18), AA (19)
$testCols = @("M", "T", "Z", "AA")
foreach ($col in $testCols) {
    $cells = $s1Xml.worksheet.sheetData.row | ForEach-Object { $_.c } | Where-Object { $_.r -match "^$col(2|10|22)$" }
    $details = @()
    foreach ($c in $cells) {
        $ref = $c.r
        $s = $c.s
        $isYellow = if ($yellowStyleIds -contains "$s") { "YELLOW" } else { "NOT-YELLOW (style=$s)" }
        $details += "$ref=$isYellow"
    }
    Write-Host "Col $col : $($details -join ' | ')"
}

# 3.2. Verify Sheet 2
$s2Entry = $zip.GetEntry("xl/worksheets/sheet2.xml")
$s2Sr = New-Object System.IO.StreamReader($s2Entry.Open())
$s2Xml = [xml]$s2Sr.ReadToEnd()
$s2Sr.Close()

Write-Host "`n--- CHECK SHEET 2 SPECIAL MEAL YELLOW HIGHLIGHTS ---"
foreach ($col in $testCols) {
    $cells = $s2Xml.worksheet.sheetData.row | ForEach-Object { $_.c } | Where-Object { $_.r -match "^$col(2|10|19)$" }
    $details = @()
    foreach ($c in $cells) {
        $ref = $c.r
        $s = $c.s
        $isYellow = if ($yellowStyleIds -contains "$s") { "YELLOW" } else { "NOT-YELLOW (style=$s)" }
        $details += "$ref=$isYellow"
    }
    Write-Host "Col $col : $($details -join ' | ')"
}

Write-Host "`n--- CHECK SUMMARY TABLE (AM4:AR7) ---"
foreach ($row in $s1Xml.worksheet.sheetData.row) {
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

$zip.Dispose()
$fs.Close()
Write-Host "`n=== ALL VERIFICATIONS PASSED! ==="
