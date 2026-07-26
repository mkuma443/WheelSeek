param(
    [ValidateSet("ja", "en")]
    [string]$Locale = "ja"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$assetDirectory = Join-Path $projectRoot "store\assets"
$outputDirectory = Join-Path $assetDirectory $Locale
$iconPath = Join-Path $projectRoot "icons\icon-128.png"
$seekScreenshotPath = Join-Path $projectRoot "design\store-video-scene.png"
$outputPath = Join-Path $outputDirectory (
    "wheelseek-$Locale-01-1280x800.png"
)

if ($Locale -eq "en") {
    $script:uiFontFamily = "Segoe UI"
    $copy = @{
        Catch = "Find the same moment`nby broadcast time."
        Body = (
            "Estimate the original broadcast time in archives.`n" +
            "Seek 5–60 seconds based on wheel speed."
        )
        PillClock = "Broadcast time"
        PillVariable = "5–60s variable"
        PillSites = "YouTube · Twitch"
        Subtitle = "Mouse-wheel seeking"
        SeekAmount = "Seek amount"
        SeekValue = "10s"
        SeekMin = "5s"
        SeekMax = "30s"
        ShiftHelp = "Hold Shift for a fixed 30-second seek"
        Experimental = "EXPERIMENTAL"
        Variable = "Variable seek"
        VariableHelp1 = "Seek 5–60 seconds based on"
        VariableHelp2 = "wheel speed"
        Clock = "Broadcast clock"
        ClockHelp1 = "Show the estimated broadcast"
        ClockHelp2 = "date and time in three lines"
        Sites = "●  YouTube and Twitch"
    }
    $catchSize = 34
}
else {
    $script:uiFontFamily = "Yu Gothic UI"
    $copy = @{
        Catch = "配信の「あの時」を、`n時刻で見つける。"
        Body = (
            "アーカイブに当時の放送時刻を表示。`n" +
            "ホイール速度に合わせて5～60秒シーク。"
        )
        PillClock = "放送時刻を推測"
        PillVariable = "5～60秒可変"
        PillSites = "YouTube・Twitch"
        Subtitle = "マウスホイールでシーク"
        SeekAmount = "シーク秒数"
        SeekValue = "10秒"
        SeekMin = "5秒"
        SeekMax = "30秒"
        ShiftHelp = "Shiftキーで固定30秒シーク"
        Experimental = "実験的機能"
        Variable = "可変シーク"
        VariableHelp1 = "ホイールの回転量に応じて"
        VariableHelp2 = "5～60秒でシーク"
        Clock = "放送時刻を表示"
        ClockHelp1 = "シーク中に当時の日付と時刻を"
        ClockHelp2 = "動画上へ3行で表示"
        Sites = "●  YouTube・Twitch対応"
    }
    $catchSize = 43
}

foreach ($requiredPath in @(
    $iconPath,
    $seekScreenshotPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required image not found: $requiredPath"
    }
}

[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

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

function Draw-RoundedImage {
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

function Draw-Pill {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [single]$X,
        [single]$Y,
        [single]$Width
    )

    $background = [System.Drawing.SolidBrush]::new(
        [System.Drawing.Color]::FromArgb(32, 74, 222, 128)
    )
    $border = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(95, 74, 222, 128),
        1
    )
    $foreground = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#9AF0B7")
    )
    $font = New-PixelFont 14 ([System.Drawing.FontStyle]::Bold)
    $path = New-RoundedPath $X $Y $Width 42 21
    try {
        $Graphics.FillPath($background, $path)
        $Graphics.DrawPath($border, $path)

        $format = [System.Drawing.StringFormat]::new()
        try {
            $format.Alignment = [System.Drawing.StringAlignment]::Center
            $format.LineAlignment = [System.Drawing.StringAlignment]::Center
            $Graphics.DrawString(
                $Text,
                $font,
                $foreground,
                [System.Drawing.RectangleF]::new($X, $Y, $Width, 42),
                $format
            )
        }
        finally {
            $format.Dispose()
        }
    }
    finally {
        $path.Dispose()
        $font.Dispose()
        $foreground.Dispose()
        $border.Dispose()
        $background.Dispose()
    }
}

function Draw-Toggle {
    param(
        [System.Drawing.Graphics]$Graphics,
        [single]$X,
        [single]$Y
    )

    $track = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
    )
    $knob = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#092018")
    )
    try {
        Fill-RoundedRectangle $Graphics $track $X $Y 34 19 9.5
        $Graphics.FillEllipse($knob, $X + 18, $Y + 3, 13, 13)
    }
    finally {
        $knob.Dispose()
        $track.Dispose()
    }
}

$icon = [System.Drawing.Image]::FromFile($iconPath)
$seekScreenshot = [System.Drawing.Image]::FromFile($seekScreenshotPath)
$bitmap = [System.Drawing.Bitmap]::new(
    1280,
    800,
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
        [System.Drawing.Rectangle]::new(0, 0, 1280, 800),
        [System.Drawing.ColorTranslator]::FromHtml("#07100D"),
        [System.Drawing.ColorTranslator]::FromHtml("#111827"),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    try {
        $graphics.FillRectangle($background, 0, 0, 1280, 800)
    }
    finally {
        $background.Dispose()
    }

    for ($index = 0; $index -lt 8; $index++) {
        $glow = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(
                [Math]::Max(2, 18 - $index * 2),
                74,
                222,
                128
            )
        )
        try {
            $size = 560 + $index * 90
            $graphics.FillEllipse(
                $glow,
                850 - ($size / 2),
                410 - ($size / 2),
                $size,
                $size
            )
        }
        finally {
            $glow.Dispose()
        }
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
    $brandFont = New-PixelFont 20 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
    $catchFont = New-PixelFont $catchSize ([System.Drawing.FontStyle]::Bold)
    $bodyFont = New-PixelFont 20
    try {
        $graphics.DrawImage(
            $icon,
            [System.Drawing.Rectangle]::new(76, 150, 72, 72)
        )
        Draw-Text $graphics "WheelSeek" $brandFont $green 168 169 270 32

        Draw-Text $graphics $copy.Catch $catchFont $white 76 280 430 150

        Draw-Text $graphics $copy.Body $bodyFont $muted 80 465 420 80

        Draw-Pill $graphics $copy.PillClock 80 580 138
        Draw-Pill $graphics $copy.PillVariable 230 580 126
        Draw-Pill $graphics $copy.PillSites 368 580 140
    }
    finally {
        $bodyFont.Dispose()
        $catchFont.Dispose()
        $brandFont.Dispose()
        $muted.Dispose()
        $green.Dispose()
        $white.Dispose()
    }

    for ($offset = 20; $offset -ge 4; $offset -= 4) {
        $shadow = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(
                [Math]::Max(3, 28 - $offset),
                0,
                0,
                0
            )
        )
        try {
            Fill-RoundedRectangle $graphics $shadow (
                562 + ($offset / 3)
            ) (
                142 + ($offset / 2)
            ) 654 410 24
        }
        finally {
            $shadow.Dispose()
        }
    }

    Draw-RoundedImage $graphics $seekScreenshot (
        [System.Drawing.RectangleF]::new(562, 142, 654, 409)
    ) (
        [System.Drawing.RectangleF]::new(0, 0, 1280, 800)
    ) 22

    # Show the three-line broadcast clock produced by the enabled preference.
    $clockBackground = [System.Drawing.SolidBrush]::new(
        [System.Drawing.Color]::FromArgb(255, 6, 13, 18)
    )
    $clockBorder = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(150, 74, 222, 128),
        1
    )
    $clockWhite = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7")
    )
    $clockGreen = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
    )
    $clockDateFont = New-PixelFont 13 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
    $clockTimeFont = New-PixelFont 29 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
    $clockSeekFont = New-PixelFont 15 ([System.Drawing.FontStyle]::Bold) "Segoe UI"
    $clockPath = New-RoundedPath 777 187 224 121 12
    try {
        $graphics.FillPath($clockBackground, $clockPath)
        $graphics.DrawPath($clockBorder, $clockPath)
        Draw-Text $graphics "2027/07/26" $clockDateFont $clockWhite 777 197 224 22 (
            [System.Drawing.StringAlignment]::Center
        )
        Draw-Text $graphics "20:32:50" $clockTimeFont $clockWhite 777 219 224 40 (
            [System.Drawing.StringAlignment]::Center
        )
        Draw-Text $graphics "+5" $clockSeekFont $clockGreen 777 273 224 24 (
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

    for ($offset = 18; $offset -ge 3; $offset -= 3) {
        $shadow = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::FromArgb(
                [Math]::Max(4, 34 - $offset),
                0,
                0,
                0
            )
        )
        try {
            Fill-RoundedRectangle $graphics $shadow (
                930 + ($offset / 3)
            ) (
                294 + ($offset / 2)
            ) 274 424 18
        }
        finally {
            $shadow.Dispose()
        }
    }

    # Draw a localized preferences panel instead of reusing the English capture.
    $panelBackground = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#0A111B")
    )
    $sectionBackground = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#151E2A")
    )
    $panelWhite = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7")
    )
    $panelMuted = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
    )
    $panelGreen = [System.Drawing.SolidBrush]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80")
    )
    $panelTitleFont = New-PixelFont 17 ([System.Drawing.FontStyle]::Bold)
    $panelLabelFont = New-PixelFont 12 ([System.Drawing.FontStyle]::Bold)
    $panelSmallFont = New-PixelFont 9
    $panelTinyFont = New-PixelFont 8
    try {
        Fill-RoundedRectangle $graphics $panelBackground 930 294 274 424 17
        $graphics.DrawImage($icon, [System.Drawing.Rectangle]::new(950, 315, 36, 36))
        Draw-Text $graphics "WheelSeek" $panelTitleFont $panelWhite 998 315 170 24
        Draw-Text $graphics $copy.Subtitle $panelSmallFont $panelMuted 998 338 175 18

        Fill-RoundedRectangle $graphics $sectionBackground 949 365 236 107 11
        Draw-Text $graphics $copy.SeekAmount $panelLabelFont $panelWhite 964 378 125 20
        Draw-Text $graphics $copy.SeekValue $panelLabelFont $panelGreen 1125 378 43 20 (
            [System.Drawing.StringAlignment]::Far
        )
        $sliderTrack = [System.Drawing.Pen]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#536174"),
            3
        )
        try {
            $graphics.DrawLine($sliderTrack, 965, 413, 1168, 413)
        }
        finally {
            $sliderTrack.Dispose()
        }
        $sliderActive = [System.Drawing.Pen]::new(
            [System.Drawing.ColorTranslator]::FromHtml("#4ADE80"),
            3
        )
        try {
            $graphics.DrawLine($sliderActive, 965, 413, 1011, 413)
        }
        finally {
            $sliderActive.Dispose()
        }
        $graphics.FillEllipse($panelGreen, 1004, 406, 15, 15)
        Draw-Text $graphics $copy.SeekMin $panelTinyFont $panelMuted 964 427 35 14
        Draw-Text $graphics $copy.SeekMax $panelTinyFont $panelMuted 1134 427 34 14 (
            [System.Drawing.StringAlignment]::Far
        )
        Draw-Text $graphics $copy.ShiftHelp $panelTinyFont $panelMuted 964 449 205 14

        Fill-RoundedRectangle $graphics $sectionBackground 949 484 236 173 11
        Draw-Text $graphics $copy.Experimental $panelTinyFont $panelGreen 964 497 110 15
        Draw-Text $graphics $copy.Variable $panelLabelFont $panelWhite 964 523 150 19
        Draw-Toggle $graphics 1134 522
        Draw-Text $graphics $copy.VariableHelp1 $panelTinyFont $panelMuted 964 543 164 14
        Draw-Text $graphics $copy.VariableHelp2 $panelTinyFont $panelMuted 964 556 150 14

        Draw-Text $graphics $copy.Clock $panelLabelFont $panelWhite 964 586 160 19
        Draw-Toggle $graphics 1134 585
        Draw-Text $graphics $copy.ClockHelp1 $panelTinyFont $panelMuted 964 606 190 14
        Draw-Text $graphics $copy.ClockHelp2 $panelTinyFont $panelMuted 964 619 190 14

        Draw-Text $graphics $copy.Sites $panelTinyFont $panelGreen 956 687 190 16
    }
    finally {
        $panelTinyFont.Dispose()
        $panelSmallFont.Dispose()
        $panelLabelFont.Dispose()
        $panelTitleFont.Dispose()
        $panelGreen.Dispose()
        $panelMuted.Dispose()
        $panelWhite.Dispose()
        $sectionBackground.Dispose()
        $panelBackground.Dispose()
    }

    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
    $seekScreenshot.Dispose()
    $icon.Dispose()
}

Get-Item -LiteralPath $outputPath | Select-Object FullName, Length, LastWriteTime
