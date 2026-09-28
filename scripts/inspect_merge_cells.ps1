$xlsxPath = "D:\HRM\HRM.Backend\HRM.Backend\wwwroot\Excel_Import\TemplateReport_MealOrder.xlsx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fs = [System.IO.File]::Open($xlsxPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Read)

$s1Entry = $zip.GetEntry("xl/worksheets/sheet1.xml")
if ($s1Entry) {
    $sr = New-Object System.IO.StreamReader($s1Entry.Open())
    $xml = [xml]$sr.ReadToEnd()
    $sr.Close()
    Write-Host "=== MERGE CELLS IN SHEET 1 ==="
    foreach ($m in $xml.worksheet.mergeCells.mergeCell) {
        if ($m.ref -match "A[M-S]") {
            Write-Host "Merge: $($m.ref)"
        }
    }
}

$zip.Dispose()
$fs.Close()
