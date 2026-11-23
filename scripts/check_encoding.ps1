[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$files = Get-ChildItem -Path 'd:\HRM\HRM.Frontend\src\pages\ESS\MyPayslip', 'd:\HRM\HRM.Frontend\src\pages\HR\Payroll' -Recurse -Include *.tsx,*.ts
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $bad1 = $c.Contains([char]0xFFFD)
    $bad2 = $c.Contains("Ã")
    $bad3 = $c.Contains("Ä‘")
    $bad4 = $c.Contains("B?ng")
    Write-Host "$($f.FullName) - FFFD: $bad1, MojibakeA: $bad2, MojibakeD: $bad3, BadQ: $bad4"
}
