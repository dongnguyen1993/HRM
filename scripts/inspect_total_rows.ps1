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

function InspectSheet($sheetXmlName, $title) {
    Write-Host "`n=== $title ==="
    $entry = $zip.GetEntry($sheetXmlName)
    if ($entry) {
        $sr = New-Object System.IO.StreamReader($entry.Open())
        $xml = [xml]$sr.ReadToEnd()
        $sr.Close()
        foreach ($row in $xml.worksheet.sheetData.row) {
            $r = [int]$row.r
            $cells = @()
            foreach ($c in $row.c) {
                $ref = $c.r
                $val = $c.v
                if ($c.t -eq "s" -and $val) { $val = $sharedStrings[[int]$val] }
                $f = $c.f
                if ($val -or $f) {
                    if ($f) { $cells += "$ref=[$f]=$val" } else { $cells += "$ref=$val" }
                }
            }
            $line = $cells -join ' | '
            if ($line -match "TOTAL|Total|total") {
                Write-Host "Row $r : $line"
            }
        }
    }
}

InspectSheet "xl/worksheets/sheet1.xml" "SHEET 1 TOTAL ROWS"
InspectSheet "xl/worksheets/sheet2.xml" "SHEET 2 TOTAL ROWS"

$zip.Dispose()
$fs.Close()
