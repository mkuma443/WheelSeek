$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$iconDirectory = Join-Path $projectRoot "icons"
[System.IO.Directory]::CreateDirectory($iconDirectory) | Out-Null

foreach ($size in @(16, 32, 48, 128)) {
    $bitmap = [System.Drawing.Bitmap]::new($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $scale = $size / 128.0
    $backgroundPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $radius = 28 * $scale
    $diameter = $radius * 2
    $bounds = [System.Drawing.RectangleF]::new(2 * $scale, 2 * $scale, 124 * $scale, 124 * $scale)
    $backgroundPath.AddArc($bounds.Left, $bounds.Top, $diameter, $diameter, 180, 90)
    $backgroundPath.AddArc($bounds.Right - $diameter, $bounds.Top, $diameter, $diameter, 270, 90)
    $backgroundPath.AddArc($bounds.Right - $diameter, $bounds.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $backgroundPath.AddArc($bounds.Left, $bounds.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $backgroundPath.CloseFigure()

    $backgroundBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml("#0B1018"))
    $graphics.FillPath($backgroundBrush, $backgroundPath)

    $ringPen = [System.Drawing.Pen]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80"),
        [Math]::Max(2, 10 * $scale)
    )
    $ringPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $ringPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawArc(
        $ringPen,
        27 * $scale,
        27 * $scale,
        74 * $scale,
        74 * $scale,
        -52,
        284
    )

    $arrowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml("#4ADE80"))
    $arrow = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new(93 * $scale, 23 * $scale),
        [System.Drawing.PointF]::new(107 * $scale, 39 * $scale),
        [System.Drawing.PointF]::new(86 * $scale, 42 * $scale)
    )
    $graphics.FillPolygon($arrowBrush, $arrow)

    $mousePath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $mousePath.AddArc(
        47 * $scale,
        42 * $scale,
        34 * $scale,
        34 * $scale,
        180,
        180
    )
    $mousePath.AddLine(81 * $scale, 59 * $scale, 81 * $scale, 74 * $scale)
    $mousePath.AddArc(
        47 * $scale,
        58 * $scale,
        34 * $scale,
        32 * $scale,
        0,
        180
    )
    $mousePath.CloseFigure()

    $mousePen = [System.Drawing.Pen]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#F4FFF7"),
        [Math]::Max(1.5, 6 * $scale)
    )
    $mousePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $mousePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $mousePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawPath($mousePen, $mousePath)

    $wheelPen = [System.Drawing.Pen]::new(
        [System.Drawing.ColorTranslator]::FromHtml("#4ADE80"),
        [Math]::Max(1.5, 6 * $scale)
    )
    $wheelPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $wheelPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawLine($wheelPen, 64 * $scale, 52 * $scale, 64 * $scale, 64 * $scale)

    $outputPath = Join-Path $iconDirectory "icon-$size.png"
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $wheelPen.Dispose()
    $mousePen.Dispose()
    $mousePath.Dispose()
    $arrowBrush.Dispose()
    $ringPen.Dispose()
    $backgroundBrush.Dispose()
    $backgroundPath.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
