$body = @{
    UserCode = "ADMIN"
    Password = "123456"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:5020/api/auth/login" -Method Post -Body $body -ContentType "application/json"
$token = $loginRes.data.accessToken
Write-Host "Got token: $($token.Substring(0, 15))..."

$headers = @{
    Authorization = "Bearer $token"
}

$outFile = "d:\HRM\scripts\exported_test.xlsx"
$res = Invoke-WebRequest -Uri "http://localhost:5020/api/meal-orders/admin/export-excel?fromDate=2026-09-01&toDate=2026-09-18" -Headers $headers -OutFile $outFile -PassThru

Write-Host "Status code: $($res.StatusCode)"
Write-Host "Content-Disposition: $($res.Headers['Content-Disposition'])"
Write-Host "File size: $((Get-Item $outFile).Length) bytes"

if (Test-Path $outFile) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($outFile)
    Write-Host "Zip Entries in exported file: $($zip.Entries.Count)"
    $s1 = $zip.GetEntry("xl/worksheets/sheet1.xml")
    if ($s1) {
        $sr = New-Object System.IO.StreamReader($s1.Open())
        $xml = [xml]$sr.ReadToEnd()
        $sr.Close()
        # Find cell I3 (Lunch for GA on Day 1)
        $c = $xml.worksheet.sheetData.row | ForEach-Object { $_.c } | Where-Object { $_.r -eq "I3" }
        Write-Host "Cell I3 (GA Day 1 lunch): Value=$($c.v)"
        $c18 = $xml.worksheet.sheetData.row | ForEach-Object { $_.c } | Where-Object { $_.r -eq "Z3" }
        Write-Host "Cell Z3 (GA Day 18 lunch): Value=$($c18.v)"
    }
    $zip.Dispose()
    Remove-Item $outFile
}
