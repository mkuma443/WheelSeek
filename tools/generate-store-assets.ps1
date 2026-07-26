$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$masterIconPath = Join-Path $projectRoot "design\wheelseek-icon-master.png"
$extensionIconPath = Join-Path $projectRoot "icons\icon-128.png"
$assetDirectory = Join-Path $projectRoot "store\assets"

if (-not (Test-Path -LiteralPath $masterIconPath)) {
    throw "Master icon not found: $masterIconPath"
}

[System.IO.Directory]::CreateDirectory($assetDirectory) | Out-Null
$masterIcon = [System.Drawing.Image]::FromFile($masterIconPath)
$extensionIcon = [System.Drawing.Image]::FromFile($extensionIconPath)

function New-Canvas {
    param([int]$Width, [int]$Height)

    $bitmap = [System.Drawing.Bitmap]::new(
        $Width,
        $Height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $bitmap.SetResolution(96, 96)
    return $bitmap
}

function Initialize-Graphics {
    param([System.Drawing.Bitmap]$Bitmap)

    $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode =
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode =
        [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality =
        [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.TextRenderingHint =
        [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return $graphics
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

function Draw-RoundedRectangle {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Pen]$Pen,
        [single]$X,
        [single]$Y,
        [single]$Width,
        [single]$Height,
        [single]$Radius
    )

    $path = New-RoundedPath $X $Y $Width $Height $Radius
    try {
        $Graphics.DrawPath($Pen, $path)
    }
    finally {
        $path.Dispose()
    }
}

function Draw-RoundedImage {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [single]$X,
        [single]$Y,
        [single]$Width,
        [single]$Height,
        [single]$Radius
    )

    $path = New-RoundedPath $X $Y $Width $Height $Radius
    $state = $Graphics.Save()
    try {
        $Graphics.SetClip($path)
        $Graphics.DrawImage(
            $Image,
            [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height)
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
        [System.Drawing.FontStyle]$Style =
            [System.Drawing.FontStyle]::Regular,
        [string]$Family = "Segoe UI"
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
        $format.LineAlignment = [System.Drawing.StringAlignment]::Center
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

function Draw-BrandBackground {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$Width,
        [int]$Height
    )

    $background = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 0, $Width, $Height),
        [System.Drawing.ColorTranslator]::FromHtml("#07100D"),
        [System.Drawing.ColorTranslator]::FromHtml("#111827"),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    try {
        $Graphics.FillRectangle($background, 0, 0, $Width, $Height)
    }
    finally {
        $background.Dispose()
    }

    for ($index = 0; $index -lt 7; $index++) {
        $alpha = [Math]::Max(2, 17 - $index * 2)
        $glow = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb($alpha, 74, 222, 128)
        )
        try {
            $radius = [Math]::Min($Width, $Height) * (0.38 + $index * 0.09)
            $Graphics.FillEllipse(
                $glow,
                ($Width * 0.12) - ($radius * 0.5),
                ($Height * 0.5) - ($radius * 0.5),
                $radius,
                $radius
            )
        }
        finally {
            $glow.Dispose()
        }
    }
}

function Draw-BrowserFrame {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Address
    )

    $header = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#151D29")
    )
    $addressBrush = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#202B39")
    )
    $mutedBrush = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#91A0B4")
    )
    $addressFont = New-PixelFont 18
    try {
        $Graphics.FillRectangle($header, 0, 0, 1280, 72)
        foreach ($dot in @(
            @{ X = 24; Color = "#FF6B6B" },
            @{ X = 48; Color = "#FFD166" },
            @{ X = 72; Color = "#4ADE80" }
        )) {
            $dotBrush = [System.Drawing.SolidBrush]::new(
                [System.Drawing.ColorTranslator]::FromHtml($dot.Color)
            )
            $Graphics.FillEllipse($dotBrush, $dot.X, 27, 12, 12)
            $dotBrush.Dispose()
        }

        Fill-RoundedRectangle $Graphics $addressBrush 122 18 934 38 19
        Draw-Text $Graphics $Address $addressFont $mutedBrush 150 18 850 38
        $Graphics.DrawImage(
            $extensionIcon,
            [System.Drawing.Rectangle]::new(1202, 14, 44, 44)
        )
    }
    finally {
        $addressFont.Dispose()
        $mutedBrush.Dispose()
        $addressBrush.Dispose()
        $header.Dispose()
    }
}

function Draw-VideoScene {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Accent = "#4ADE80"
    )

    $scene = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 72, 1280, 728),
        [System.Drawing.ColorTranslator]::FromHtml("#16253B"),
        [System.Drawing.ColorTranslator]::FromHtml("#08231A"),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )
    $horizon = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#09111B")
    )
    $accentColor = [System.Drawing.ColorTranslator]::FromHtml($Accent)
    try {
        $Graphics.FillRectangle($scene, 0, 72, 1280, 728)
        $Graphics.FillRectangle($horizon, 0, 540, 1280, 260)

        $buildingBrushes = @(
            [System.Drawing.SolidBrush]::new(
                [System.Drawing.Color]::FromArgb(215, 17, 30, 47)
            ),
            [System.Drawing.SolidBrush]::new(
                [System.Drawing.Color]::FromArgb(235, 9, 22, 34)
            )
        )
        try {
            $buildings = @(
                @(0, 360, 150, 180),
                @(128, 305, 170, 235),
                @(280, 390, 135, 150),
                @(402, 260, 205, 280),
                @(594, 340, 156, 200),
                @(736, 285, 180, 255),
                @(900, 365, 146, 175),
                @(1030, 310, 250, 230)
            )
            for ($index = 0; $index -lt $buildings.Count; $index++) {
                $item = $buildings[$index]
                $Graphics.FillRectangle(
                    $buildingBrushes[$index % 2],
                    $item[0],
                    $item[1],
                    $item[2],
                    $item[3]
                )
            }
        }
        finally {
            foreach ($brush in $buildingBrushes) {
                $brush.Dispose()
            }
        }

        $roadPen = [System.Drawing.Pen]::new(
            [System.Drawing.Color]::FromArgb(130, $accentColor),
            4
        )
        $roadPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $roadPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        try {
            $Graphics.DrawLine($roadPen, 540, 800, 616, 540)
            $Graphics.DrawLine($roadPen, 740, 800, 664, 540)
            $Graphics.DrawLine($roadPen, 620, 730, 640, 620)
        }
        finally {
            $roadPen.Dispose()
        }

        $windowBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(145, $accentColor)
        )
        try {
            foreach ($point in @(
                @(82, 410), @(192, 350), @(470, 320), @(540, 390),
                @(790, 335), @(862, 420), @(1090, 370), @(1170, 450)
            )) {
                $Graphics.FillRectangle($windowBrush, $point[0], $point[1], 32, 6)
            }
        }
        finally {
            $windowBrush.Dispose()
        }
    }
    finally {
        $horizon.Dispose()
        $scene.Dispose()
    }
}

function Draw-PlayerControls {
    param([System.Drawing.Graphics]$Graphics)

    $shade = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.Rectangle]::new(0, 670, 1280, 130),
        [System.Drawing.Color]::FromArgb(0, 0, 0, 0),
        [System.Drawing.Color]::FromArgb(225, 0, 0, 0),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )
    $track = [System.Drawing.SolidBrush]::new(
        [System.Drawing.Color]::FromArgb(120, 255, 255, 255)
    )
    $progress = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
    )
    $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $font = New-PixelFont 18 ([System.Drawing.FontStyle]::Bold)
    try {
        $Graphics.FillRectangle($shade, 0, 670, 1280, 130)
        $Graphics.FillRectangle($track, 42, 728, 1196, 5)
        $Graphics.FillRectangle($progress, 42, 728, 478, 5)
        $Graphics.FillEllipse($progress, 514, 721, 18, 18)
        Draw-Text $Graphics "▶" $font $white 40 746 40 36
        Draw-Text $Graphics "32:10 / 5:42:18" $font $white 92 746 210 36
    }
    finally {
        $font.Dispose()
        $white.Dispose()
        $progress.Dispose()
        $track.Dispose()
        $shade.Dispose()
    }
}

function Draw-SeekOverlay {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Date,
        [string]$Time,
        [string]$Seek,
        [bool]$ShowClock
    )

    $width = if ($ShowClock) { 230 } else { 112 }
    $height = if ($ShowClock) { 126 } else { 64 }
    $x = (1280 - $width) / 2
    $y = 106
    $card = [System.Drawing.SolidBrush]::new(
        [System.Drawing.Color]::FromArgb(235, 8, 12, 20)
    )
    $border = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(65, 255, 255, 255),
        1
    )
    $primary = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $secondary = [System.Drawing.SolidBrush]::new(
        [System.Drawing.Color]::FromArgb(205, 255, 255, 255)
    )
    $dateFont = New-PixelFont 17 ([System.Drawing.FontStyle]::Bold)
    $timeFont = New-PixelFont 34 ([System.Drawing.FontStyle]::Bold)
    $seekFont = New-PixelFont 18 ([System.Drawing.FontStyle]::Bold)
    try {
        Fill-RoundedRectangle $Graphics $card $x $y $width $height 16
        Draw-RoundedRectangle $Graphics $border $x $y $width $height 16

        if ($ShowClock) {
            Draw-Text $Graphics $Date $dateFont $secondary $x ($y + 10) $width 24 (
                [System.Drawing.StringAlignment]::Center
            )
            Draw-Text $Graphics $Time $timeFont $primary $x ($y + 34) $width 48 (
                [System.Drawing.StringAlignment]::Center
            )
            Draw-Text $Graphics $Seek $seekFont $secondary $x ($y + 86) $width 28 (
                [System.Drawing.StringAlignment]::Center
            )
        }
        else {
            Draw-Text $Graphics $Seek $timeFont $primary $x $y $width $height (
                [System.Drawing.StringAlignment]::Center
            )
        }
    }
    finally {
        $seekFont.Dispose()
        $timeFont.Dispose()
        $dateFont.Dispose()
        $secondary.Dispose()
        $primary.Dispose()
        $border.Dispose()
        $card.Dispose()
    }
}

function Draw-SettingsPopup {
    param([System.Drawing.Graphics]$Graphics)

    $x = 858
    $y = 90
    $width = 374
    $height = 626
    $card = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#0B1018")
    )
    $panel = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#151C27")
    )
    $primary = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#EEF4FF")
    )
    $muted = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#8E9CAF")
    )
    $green = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
    )
    $track = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#344052")
    )
    $titleFont = New-PixelFont 23 ([System.Drawing.FontStyle]::Bold)
    $labelFont = New-PixelFont 16 ([System.Drawing.FontStyle]::Bold)
    $smallFont = New-PixelFont 13
    try {
        Fill-RoundedRectangle $Graphics $card $x $y $width $height 20
        $Graphics.DrawImage(
            $extensionIcon,
            [System.Drawing.Rectangle]::new($x + 24, $y + 22, 52, 52)
        )
        Draw-Text $Graphics "WheelSeek" $titleFont $primary ($x + 90) ($y + 20) 240 30
        Draw-Text $Graphics "Scroll to seek videos" $smallFont $muted (
            $x + 90
        ) ($y + 51) 240 22

        Fill-RoundedRectangle $Graphics $panel ($x + 20) ($y + 94) 334 154 14
        Draw-Text $Graphics "Seek amount" $labelFont $primary (
            $x + 38
        ) ($y + 108) 190 26
        Draw-Text $Graphics "10s" $labelFont $green (
            $x + 275
        ) ($y + 108) 52 26 (
            [System.Drawing.StringAlignment]::Far
        )
        $Graphics.FillRectangle($track, $x + 42, $y + 163, 286, 5)
        $Graphics.FillRectangle($green, $x + 42, $y + 163, 58, 5)
        $Graphics.FillEllipse($green, $x + 91, $y + 154, 22, 22)
        Draw-Text $Graphics "5s" $smallFont $muted (
            $x + 38
        ) ($y + 184) 70 20
        Draw-Text $Graphics "30s" $smallFont $muted (
            $x + 258
        ) ($y + 184) 70 20 (
            [System.Drawing.StringAlignment]::Far
        )
        Draw-Text $Graphics "Hold Shift for a fixed 30-second seek." $smallFont (
            $muted
        ) ($x + 38) ($y + 211) 290 22

        Fill-RoundedRectangle $Graphics $panel ($x + 20) ($y + 264) 334 220 14
        Draw-Text $Graphics "EXPERIMENTAL" $smallFont $green (
            $x + 38
        ) ($y + 277) 160 20
        Draw-Text $Graphics "Variable seek" $labelFont $primary (
            $x + 38
        ) ($y + 316) 210 26
        Draw-Text $Graphics "5–60 seconds based on wheel intensity" $smallFont (
            $muted
        ) ($x + 38) ($y + 343) 230 24
        Draw-Text $Graphics "Broadcast clock" $labelFont $primary (
            $x + 38
        ) ($y + 397) 210 26
        Draw-Text $Graphics "Show local broadcast time while seeking" $smallFont (
            $muted
        ) ($x + 38) ($y + 424) 230 24

        foreach ($toggleY in @(($y + 322), ($y + 403))) {
            Fill-RoundedRectangle $Graphics $green ($x + 282) $toggleY 46 26 13
            $knob = [System.Drawing.SolidBrush]::new(
                [System.Drawing.ColorTranslator]::FromHtml("#07120C")
            )
            $Graphics.FillEllipse($knob, $x + 305, $toggleY + 4, 18, 18)
            $knob.Dispose()
        }

        Draw-Text $Graphics "●  YouTube and Twitch" $smallFont $green (
            $x + 28
        ) ($y + 572) 220 22
    }
    finally {
        $smallFont.Dispose()
        $labelFont.Dispose()
        $titleFont.Dispose()
        $track.Dispose()
        $green.Dispose()
        $muted.Dispose()
        $primary.Dispose()
        $panel.Dispose()
        $card.Dispose()
    }
}

function Save-Bitmap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$FileName
    )

    $outputPath = Join-Path $assetDirectory $FileName
    $Bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    return $outputPath
}

try {
    Copy-Item -LiteralPath $extensionIconPath -Destination (
        Join-Path $assetDirectory "icon-128.png"
    ) -Force

    $small = New-Canvas 440 280
    $graphics = Initialize-Graphics $small
    try {
        Draw-BrandBackground $graphics 440 280
        Draw-RoundedImage $graphics $masterIcon 22 30 220 220 26
        $white = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7")
        )
        $green = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
        )
        $wordmark = New-PixelFont 29 ([System.Drawing.FontStyle]::Bold)
        $caption = New-PixelFont 11 ([System.Drawing.FontStyle]::Bold)
        try {
            Draw-Text $graphics "WheelSeek" $wordmark $white 250 100 175 40
            Draw-Text $graphics "MOUSE-WHEEL SEEKING" $caption $green (
                252
            ) 142 168 22
        }
        finally {
            $caption.Dispose()
            $wordmark.Dispose()
            $green.Dispose()
            $white.Dispose()
        }
        Save-Bitmap $small "promo-small-440x280.png" | Out-Null
    }
    finally {
        $graphics.Dispose()
        $small.Dispose()
    }

    $marquee = New-Canvas 1400 560
    $graphics = Initialize-Graphics $marquee
    try {
        Draw-BrandBackground $graphics 1400 560
        Draw-RoundedImage $graphics $masterIcon 42 20 520 520 44
        $white = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7")
        )
        $green = [System.Drawing.SolidBrush]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
        )
        $wordmark = New-PixelFont 92 ([System.Drawing.FontStyle]::Bold)
        $caption = New-PixelFont 24 ([System.Drawing.FontStyle]::Bold)
        try {
            Draw-Text $graphics "WheelSeek" $wordmark $white 600 190 720 110
            Draw-Text $graphics "SCROLL  •  SEEK  •  SYNC" $caption $green (
                610
            ) 305 650 44
        }
        finally {
            $caption.Dispose()
            $wordmark.Dispose()
            $green.Dispose()
            $white.Dispose()
        }
        Save-Bitmap $marquee "promo-marquee-1400x560.png" | Out-Null
    }
    finally {
        $graphics.Dispose()
        $marquee.Dispose()
    }

}
finally {
    $extensionIcon.Dispose()
    $masterIcon.Dispose()
}

Get-ChildItem -LiteralPath $assetDirectory -Filter "*.png" |
    Sort-Object Name |
    Select-Object Name, Length
