$xlsxPath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fs = [System.IO.File]::Open($xlsxPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)

$s3Entry = $zip.GetEntry("xl/worksheets/sheet3.xml")
$sr = New-Object System.IO.StreamReader($s3Entry.Open())
$xml = [xml]$sr.ReadToEnd()
$sr.Close()

$b3 = $xml.worksheet.sheetData.row | ForEach-Object { $_.c } | Where-Object { $_.r -eq "B3" }
Write-Host "B3: r=$($b3.r) s=$($b3.s) t=$($b3.t) v=$($b3.v)"
$c3 = $xml.worksheet.sheetData.row | ForEach-Object { $_.c } | Where-Object { $_.r -eq "C3" }
Write-Host "C3: r=$($c3.r) s=$($c3.s) t=$($c3.t) f=$($c3.f.InnerText) v=$($c3.v)"

# Styles
$stylesEntry = $zip.GetEntry("xl/styles.xml")
$sr = New-Object System.IO.StreamReader($stylesEntry.Open())
$stylesXml = [xml]$sr.ReadToEnd()
$sr.Close()

$xfIndex = [int]$b3.s
$xf = $stylesXml.styleSheet.cellXfs.xf[$xfIndex]
$numFmtId = $xf.numFmtId
Write-Host "B3 style xf: numFmtId=$numFmtId"

$zip.Dispose()
$fs.Dispose()
