param(
    [ValidateSet("ja", "en")]
    [string]$Locale = "ja"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot (
    "store\assets\$Locale\wheelseek-$Locale-01-1280x800.png"
)
$videoSourcePath = Join-Path $projectRoot "design\store-video-scene.png"
$iconPath = Join-Path $projectRoot "icons\icon-128.png"
$outputPath = Join-Path $projectRoot (
    "store\assets\$Locale\wheelseek-$Locale-promo-small-440x280.png"
)

if ($Locale -eq "en") {
    $script:uiFontFamily = "Segoe UI"
    $copy = @{
        Catch = "Find the same moment`nby broadcast time."
        FeatureClock = "Estimated broadcast-time display"
        FeatureVariable = "5–60 second variable seeking"
    }
    $catchSize = 16
}
else {
    $script:uiFontFamily = "Yu Gothic UI"
    $copy = @{
        Catch = "配信の「あの時」を`nすぐ見つける。"
        FeatureClock = "放送時刻を推測して表示"
        FeatureVariable = "5～60秒 可変シーク"
    }
    $catchSize = 20
}

foreach ($requiredPath in @($sourcePath, $videoSourcePath, $iconPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required image not found: $requiredPath"
    }
}

function New-RoundedPath {
    param(
        [single]$X,
        [single]$Y,
        [single]$Width,
        [single]$Height,
        [single]$Radius
    )

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc(
        $X + $Width - $diameter,
        $Y + $Height - $diameter,
        $diameter,
        $diameter,
        0,
        90
    )
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Fill-RoundedRectangle {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Brush]$Brush,
        [single]$X,
        [single]$Y,
        [single]$Width,
        [single]$Height,
        [single]$Radius
    )

    $path = New-RoundedPath $X $Y $Width $Height $Radius
    try {
        $Graphics.FillPath($Brush, $path)
    }
    finally {
        $path.Dispose()
    }
}

function Draw-RoundedCrop {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [System.Drawing.RectangleF]$Destination,
        [System.Drawing.RectangleF]$Source,
        [single]$Radius
    )

    $path = New-RoundedPath (
        $Destination.X
    ) (
        $Destination.Y
    ) (
        $Destination.Width
    ) (
        $Destination.Height
    ) $Radius
    $state = $Graphics.Save()
    try {
        $Graphics.SetClip($path)
        $Graphics.DrawImage(
            $Image,
            $Destination,
            $Source,
            [System.Drawing.GraphicsUnit]::Pixel
        )
    }
    finally {
        $Graphics.Restore($state)
        $path.Dispose()
    }
}

function New-PixelFont {
    param(
        [single]$Size,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular,
        [string]$Family = $script:uiFontFamily
    )

    return [System.Drawing.Font]::new(
        $Family,
        $Size,
        $Style,
        [System.Drawing.GraphicsUnit]::Pixel
    )
}

function Draw-Text {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$Brush,
        [single]$X,
        [single]$Y,
        [single]$Width,
        [single]$Height,
        [System.Drawing.StringAlignment]$Alignment =
            [System.Drawing.StringAlignment]::Near
    )

    $format = [System.Drawing.StringFormat]::new()
    try {
        $format.Alignment = $Alignment
        $format.LineAlignment = [System.Drawing.StringAlignment]::Near
        $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
        $Graphics.DrawString(
            $Text,
            $Font,
            $Brush,
            [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height),
            $format
        )
    }
    finally {
        $format.Dispose()
    }
}

$source = [System.Drawing.Image]::FromFile($sourcePath)
$videoSource = [System.Drawing.Image]::FromFile($videoSourcePath)
$icon = [System.Drawing.Image]::FromFile($iconPath)
$bitmap = [System.Drawing.Bitmap]::new(
    440,
    280,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
$bitmap.SetResolution(96, 96)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode =
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode =
        [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality =
        [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.TextRenderingHint =
        [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 0, 440, 280),
        [System.Drawing.ColorTranslator]::FromHtml("#06100D"),
        [System.Drawing.ColorTranslator]::FromHtml("#111827"),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    try {
        $graphics.FillRectangle($background, 0, 0, 440, 280)
    }
    finally {
        $background.Dispose()
    }

    for ($index = 0; $index -lt 5; $index++) {
        $ring = [System.Drawing.Pen]::new(
            [System.Drawing.Color]::FromArgb(25 - ($index * 3), 74, 222, 128),
            24
        )
        try {
            $diameter = 230 + ($index * 48)
            $graphics.DrawEllipse(
                $ring,
                330 - ($diameter / 2),
                140 - ($diameter / 2),
                $diameter,
                $diameter
            )
        }
        finally {
            $ring.Dispose()
        }
    }

    if ($Locale -eq "en") {
        # Compose the video and preferences independently so the promo's own
        # circular gradient remains visible around both elements.
        $shadow = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(105, 0, 0, 0)
        )
        try {
            Fill-RoundedRectangle $graphics $shadow 202 45 224 142 10
            Fill-RoundedRectangle $graphics $shadow 328 91 95 147 7
        }
        finally {
            $shadow.Dispose()
        }

        Draw-RoundedCrop $graphics $videoSource (
            [System.Drawing.RectangleF]::new(198, 41, 224, 140)
        ) (
            [System.Drawing.RectangleF]::new(0, 0, 1280, 800)
        ) 9

        $clockBackground = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#060D12")
        )
        $clockBorder = [System.Drawing.Pen]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#4ADE80"),
            1
        )
        $clockWhite = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7")
        )
        $clockGreen = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
        )
        $clockDateFont = New-PixelFont 5 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
        $clockTimeFont = New-PixelFont 11 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
        $clockSeekFont = New-PixelFont 6 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
        $clockPath = New-RoundedPath 274 53 80 50 5
        try {
            $graphics.FillPath($clockBackground, $clockPath)
            $graphics.DrawPath($clockBorder, $clockPath)
            Draw-Text $graphics "2027/07/26" $clockDateFont $clockWhite 274 57 80 8 (
                [System.Drawing.StringAlignment]::Center
            )
            Draw-Text $graphics "20:32:50" $clockTimeFont $clockWhite 274 66 80 16 (
                [System.Drawing.StringAlignment]::Center
            )
            Draw-Text $graphics "+5" $clockSeekFont $clockGreen 274 87 80 9 (
                [System.Drawing.StringAlignment]::Center
            )
        }
        finally {
            $clockPath.Dispose()
            $clockSeekFont.Dispose()
            $clockTimeFont.Dispose()
            $clockDateFont.Dispose()
            $clockGreen.Dispose()
            $clockWhite.Dispose()
            $clockBorder.Dispose()
            $clockBackground.Dispose()
        }

        Draw-RoundedCrop $graphics $source (
            [System.Drawing.RectangleF]::new(325, 87, 96, 148)
        ) (
            [System.Drawing.RectangleF]::new(930, 294, 274, 424)
        ) 7
    }
    else {
        $shadow = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(95, 0, 0, 0)
        )
        try {
            Fill-RoundedRectangle $graphics $shadow 205 43 224 201 13
        }
        finally {
            $shadow.Dispose()
        }

        Draw-RoundedCrop $graphics $source (
            [System.Drawing.RectangleF]::new(201, 39, 224, 201)
        ) (
            [System.Drawing.RectangleF]::new(540, 126, 690, 618)
        ) 12
    }

    $white = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7")
    )
    $green = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
    )
    $muted = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#AAB8C8")
    )
    $brandFontSize = if ($Locale -eq "en") { 23 } else { 16 }
    $brandFont = New-PixelFont $brandFontSize (
        [System.Drawing.FontStyle]::Bold
    ) "Segoe UI"
    $catchFont = New-PixelFont $catchSize ([System.Drawing.FontStyle]::Bold)
    $bodyFont = New-PixelFont 12
    $pillFont = New-PixelFont 10 ([System.Drawing.FontStyle]::Bold)
    try {
        if ($Locale -eq "en") {
            $graphics.DrawImage(
                $icon,
                [System.Drawing.Rectangle]::new(20, 202, 58, 58)
            )
            Draw-Text $graphics "WheelSeek" $brandFont $green 88 217 210 32
        }
        else {
            $graphics.DrawImage(
                $icon,
                [System.Drawing.Rectangle]::new(20, 28, 40, 40)
            )
            Draw-Text $graphics "WheelSeek" $brandFont $green 70 37 120 24
        }

        Draw-Text $graphics (
            $copy.Catch
        ) $catchFont $white 20 94 178 62

        if ($Locale -ne "en") {
            $pillBackground = [System.Drawing.SolidBrush]::new(
                [System.Drawing.Color]::FromArgb(45, 74, 222, 128)
            )
            $pillBorder = [System.Drawing.Pen]::new(
                [System.Drawing.Color]::FromArgb(120, 74, 222, 128),
                1
            )
            $pillPath = New-RoundedPath 20 208 166 29 14.5
            try {
                $graphics.FillPath($pillBackground, $pillPath)
                $graphics.DrawPath($pillBorder, $pillPath)
                Draw-Text $graphics $copy.FeatureVariable $pillFont $green 34 214 142 18
            }
            finally {
                $pillPath.Dispose()
                $pillBorder.Dispose()
                $pillBackground.Dispose()
            }
        }
    }
    finally {
        $pillFont.Dispose()
        $bodyFont.Dispose()
        $catchFont.Dispose()
        $brandFont.Dispose()
        $muted.Dispose()
        $green.Dispose()
        $white.Dispose()
    }

    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
    $icon.Dispose()
    $videoSource.Dispose()
    $source.Dispose()
}

Get-Item -LiteralPath $outputPath | Select-Object FullName, Length, LastWriteTime
