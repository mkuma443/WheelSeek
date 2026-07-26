$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot "design\wheelseek-icon-master.png"
$iconDirectory = Join-Path $projectRoot "icons"

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Master icon not found: $sourcePath"
}

[System.IO.Directory]::CreateDirectory($iconDirectory) | Out-Null
$source = [System.Drawing.Image]::FromFile($sourcePath)

try {
    foreach ($size in @(16, 32, 48, 128)) {
        $bitmap = [System.Drawing.Bitmap]::new(
            $size,
            $size,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        $bitmap.SetResolution(96, 96)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.CompositingMode =
                [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality =
                [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode =
                [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode =
                [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode =
                [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.DrawImage(
                $source,
                [System.Drawing.Rectangle]::new(0, 0, $size, $size),
                0,
                0,
                $source.Width,
                $source.Height,
                [System.Drawing.GraphicsUnit]::Pixel
            )

            $outputPath = Join-Path $iconDirectory "icon-$size.png"
            $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }
}
finally {
    $source.Dispose()
}
