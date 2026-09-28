$xlsxPath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fs = [System.IO.File]::Open($xlsxPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)

$ss = @()
$ssEntry = $zip.GetEntry("xl/sharedStrings.xml")
if ($ssEntry) {
    $sr = New-Object System.IO.StreamReader($ssEntry.Open())
    $xml = [xml]$sr.ReadToEnd()
    $sr.Close()
    foreach ($si in $xml.sst.si) {
        $t = $si.t
        if (-not $t) { $t = ($si.r | ForEach-Object { $_.t }) -join '' }
        $ss += $t
    }
}

function DumpB($sName) {
    Write-Host "`n=== $sName ==="
    $e = $zip.GetEntry($sName)
    if ($e) {
        $sr = New-Object System.IO.StreamReader($e.Open())
        $xml = [xml]$sr.ReadToEnd()
        $sr.Close()
        foreach ($row in $xml.worksheet.sheetData.row) {
            foreach ($c in $row.c) {
                if ($c.r -match "^B\d+") {
                    $v = $c.v
                    if ($c.t -eq "s" -and $v) { $v = $ss[[int]$v] }
                    Write-Host "$($c.r): $v"
                }
            }
        }
    }
}

DumpB "xl/worksheets/sheet1.xml"
DumpB "xl/worksheets/sheet2.xml"

$zip.Dispose()
$fs.Close()
