$xlsxPath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fs = [System.IO.File]::Open($xlsxPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)

$s3Entry = $zip.GetEntry("xl/worksheets/sheet3.xml")
$sr = New-Object System.IO.StreamReader($s3Entry.Open())
$xml = [xml]$sr.ReadToEnd()
$sr.Close()

# Check row 7 (Sunday 30/08/2026) cells style
$r7Cells = $xml.worksheet.sheetData.row | Where-Object { $_.r -eq "7" } | ForEach-Object { $_.c }
Write-Host "Row 7 (Sunday) cells:"
foreach ($c in $r7Cells) {
    Write-Host "Cell $($c.r): s=$($c.s)"
}

# Check styles.xml for fill
$stylesEntry = $zip.GetEntry("xl/styles.xml")
$sr = New-Object System.IO.StreamReader($stylesEntry.Open())
$stylesXml = [xml]$sr.ReadToEnd()
$sr.Close()

$sId = [int]$r7Cells[0].s
$xf = $stylesXml.styleSheet.cellXfs.xf[$sId]
$fillId = [int]$xf.fillId
Write-Host "Sunday fillId: $fillId"
$fill = $stylesXml.styleSheet.fills.fill[$fillId]
Write-Host "Fill pattern: $($fill.patternFill.patternType) | rgb: $($fill.patternFill.fgColor.rgb)"

$zip.Dispose()
$fs.Dispose()
