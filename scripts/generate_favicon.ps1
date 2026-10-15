Add-Type -AssemblyName System.Drawing

function Create-HansolBitmap([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $scale = $size / 64.0
    $rectW = [float](50.0 * $scale)
    $rectH = [float](21.0 * $scale)
    $rectX = [float](( $size - $rectW ) / 2.0)
    $radius = [float](5.0 * $scale)
    $gap = [float](6.0 * $scale)
    $rect1Y = [float](( $size - (2.0 * $rectH + $gap) ) / 2.0)
    $rect2Y = [float]($rect1Y + $rectH + $gap)

    $path1 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2.0
    $path1.AddArc($rectX, $rect1Y, $d, $d, 180, 90)
    $path1.AddArc($rectX + $rectW - $d, $rect1Y, $d, $d, 270, 90)
    $path1.AddArc($rectX + $rectW - $d, $rect1Y + $rectH - $d, $d, $d, 0, 90)
    $path1.AddArc($rectX, $rect1Y + $rectH - $d, $d, $d, 90, 90)
    $path1.CloseFigure()

    $blueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0072CE'))
    $g.FillPath($blueBrush, $path1)
    $path1.Dispose()
    $blueBrush.Dispose()

    $path2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path2.AddArc($rectX, $rect2Y, $d, $d, 180, 90)
    $path2.AddArc($rectX + $rectW - $d, $rect2Y, $d, $d, 270, 90)
    $path2.AddArc($rectX + $rectW - $d, $rect2Y + $rectH - $d, $d, $d, 0, 90)
    $path2.AddArc($rectX, $rect2Y + $rectH - $d, $d, $d, 90, 90)
    $path2.CloseFigure()

    $greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#00A651'))
    $g.FillPath($greenBrush, $path2)
    $path2.Dispose()
    $greenBrush.Dispose()

    $g.Dispose()
    return $bmp
}

$frontendPublic = 'd:\HRM\HRM.Frontend\public'

# Generate 64x64 PNG
$bmp64 = Create-HansolBitmap 64
$bmp64.Save("$frontendPublic\favicon.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Generate 32x32 ICO
$bmp32 = Create-HansolBitmap 32
$iconHandle = $bmp32.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($iconHandle)
$stream = New-Object System.IO.FileStream("$frontendPublic\favicon.ico", [System.IO.FileMode]::Create)
$icon.Save($stream)
$stream.Close()
$icon.Dispose()
$bmp32.Dispose()
$bmp64.Dispose()

Write-Host "Favicons generated successfully in $frontendPublic"
