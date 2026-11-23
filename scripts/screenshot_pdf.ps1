[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$chromePaths = @(
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
)

$browser = $null
foreach ($p in $chromePaths) {
    if (Test-Path $p) {
        $browser = $p
        break
    }
}

if (-not $browser) {
    Write-Host "No Chrome or Edge found!"
    exit 1
}

Write-Host "Using browser: $browser"
$pdfPath = 'D:\HRM\scripts\test_api_preview.pdf'
$outImg = 'D:\HRM\scripts\preview_screenshot.png'

# Convert to file URI
$uri = "file:///$($pdfPath.Replace('\', '/'))"
& $browser --headless --disable-gpu --screenshot="$outImg" --window-size=1200,850 "$uri"
Start-Sleep -Seconds 2

if (Test-Path $outImg) {
    Write-Host "Screenshot created successfully! Size: $((Get-Item $outImg).Length) bytes"
} else {
    Write-Host "Failed to create screenshot."
}
