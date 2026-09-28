$xlsxPath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fs = [System.IO.File]::Open($xlsxPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
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

$s3Entry = $zip.GetEntry("xl/worksheets/sheet3.xml")
if ($s3Entry) {
    $sr = New-Object System.IO.StreamReader($s3Entry.Open())
    $xml = [xml]$sr.ReadToEnd()
    $sr.Close()
    Write-Host "=== SHEET 3 ALL ROWS ==="
    foreach ($row in $xml.worksheet.sheetData.row) {
        $r = $row.r
        $cells = @()
        foreach ($c in $row.c) {
            $ref = $c.r
            $val = $c.v
            if ($c.t -eq "s" -and $val) { $val = $sharedStrings[[int]$val] }
            $f = $c.f
            if ($f) { $val = "FORMULA($f)=$val" }
            if ($val) { $cells += "$ref=$val" }
        }
        Write-Host "Row $r : $($cells -join ' | ')"
    }
}

$wbEntry = $zip.GetEntry("xl/workbook.xml")
if ($wbEntry) {
    $sr = New-Object System.IO.StreamReader($wbEntry.Open())
    $xml = [xml]$sr.ReadToEnd()
    $sr.Close()
    Write-Host "`n=== SHEETS IN WORKBOOK ==="
    foreach ($sh in $xml.workbook.sheets.sheet) {
        Write-Host "SheetId=$($sh.sheetId) | r:id=$($sh.'id') | Name=$($sh.name)"
    }
}

$zip.Dispose()
$fs.Dispose()
