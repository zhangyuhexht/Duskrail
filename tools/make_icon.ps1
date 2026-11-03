# Draw the Duskrail application icon and write a multi-size PNG-compressed ICO.
# ASCII only: the Windows PowerShell console is GBK.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$OutIco = "D:\tools\installer\assets\Duskrail.ico"
$OutPreview = "D:\train-sim\build\shots\icon_preview_256.png"
New-Item -ItemType Directory -Force -Path (Split-Path $OutPreview) | Out-Null

function P([float]$x, [float]$y) { return [System.Drawing.PointF]::new($x, $y) }

function Draw-Base() {
    $bmp = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $bgPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $bgPath.AddArc([System.Drawing.Rectangle]::new(0, 0, 56, 56), 180, 90)
    $bgPath.AddArc([System.Drawing.Rectangle]::new(200, 0, 56, 56), 270, 90)
    $bgPath.AddArc([System.Drawing.Rectangle]::new(200, 200, 56, 56), 0, 90)
    $bgPath.AddArc([System.Drawing.Rectangle]::new(0, 200, 56, 56), 90, 90)
    $bgPath.CloseFigure()
    $bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.RectangleF]::new(0, 0, 256, 256),
        [System.Drawing.Color]::FromArgb(255, 8, 17, 31),
        [System.Drawing.Color]::FromArgb(255, 27, 54, 87), 45.0)
    $g.FillPath($bgBrush, $bgPath)

    $rimPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(52, 143, 182, 232), [float]2.0)
    $g.DrawPath($rimPen, $bgPath)

    # Dusk sun with layered glow.
    $sunGlow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(28, 255, 155, 66))
    $g.FillEllipse($sunGlow, 126, 20, 112, 112)
    $sunGlow2 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(52, 255, 155, 66))
    $g.FillEllipse($sunGlow2, 144, 38, 76, 76)
    $sun = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 196, 107))
    $g.FillEllipse($sun, 159, 53, 46, 46)
    $sunHi = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(190, 255, 227, 168))
    $g.FillEllipse($sunHi, 163, 56, 26, 26)

    # Ridge line.
    $ridgeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(242, 10, 23, 40))
    $ridgePts = [System.Drawing.PointF[]]@(
        (P 0 176), (P 36 152), (P 68 168), (P 104 138), (P 140 164),
        (P 176 140), (P 212 162), (P 256 144), (P 256 256), (P 0 256))
    $g.FillPolygon($ridgeBrush, $ridgePts)

    # Catenary and rails.
    $wirePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(110, 110, 134, 162), [float]2.2)
    $g.DrawLine($wirePen, 0, 110, 256, 100)
    $railPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 95, 120, 146), [float]6.8)
    $railPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $railPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($railPen, 16, 240, 242, 216)
    $rail2 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 32, 50, 71), [float]4.8)
    $g.DrawLine($rail2, 36, 252, 248, 230)
    $sleeperPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 26, 43, 62), [float]4.2)
    foreach ($x in @(44, 76, 108, 140, 172, 204)) {
        $g.DrawLine($sleeperPen, $x, 238 - ($x - 44) * 0.09, $x - 14, 252 - ($x - 44) * 0.09)
    }

    # Locomotive side profile, facing left.
    $bodyBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.RectangleF]::new(32, 114, 194, 62),
        [System.Drawing.Color]::FromArgb(255, 248, 251, 254),
        [System.Drawing.Color]::FromArgb(255, 145, 168, 189), 90.0)
    $bodyPts = [System.Drawing.PointF[]]@(
        (P 32 176), (P 32 158), (P 46 140), (P 62 122), (P 90 114),
        (P 208 114), (P 226 114), (P 226 176))
    $g.FillPolygon($bodyBrush, $bodyPts)
    $hi = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(52, 255, 255, 255))
    $g.FillRectangle($hi, 40, 116, 182, 24)

    # Livery.
    $bandBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.RectangleF]::new(44, 147, 182, 16),
        [System.Drawing.Color]::FromArgb(255, 45, 99, 216),
        [System.Drawing.Color]::FromArgb(255, 22, 59, 140), 0.0)
    $g.FillRectangle($bandBrush, 44, 147, 182, 16)
    $orange = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 154, 60))
    $g.FillRectangle($orange, 44, 164, 182, 5)
    $skirt = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 34, 54, 77))
    $g.FillRectangle($skirt, 48, 178, 176, 6)

    # Cab and saloon windows.
    $dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 23, 48, 77))
    $cabPts = [System.Drawing.PointF[]]@(
        (P 54 138), (P 66 124), (P 76 120), (P 98 120), (P 98 140), (P 54 140))
    $g.FillPolygon($dark, $cabPts)
    $glass = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(184, 127, 168, 199))
    $g.FillRectangle($glass, 66, 125, 24, 10)
    foreach ($wx in @(110, 136, 162, 188)) {
        $ww = 20
        if ($wx -eq 188) { $ww = 24 }
        $g.FillRectangle($dark, $wx, 122, $ww, 15)
        $pane = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(115, 110, 156, 188))
        $g.FillRectangle($pane, $wx + 2, 124, $ww - 4, 11)
    }

    # Headlight beam.
    $beamBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
        [System.Drawing.RectangleF]::new(-16, 106, 58, 70),
        [System.Drawing.Color]::FromArgb(235, 255, 228, 160),
        [System.Drawing.Color]::FromArgb(0, 255, 158, 60), 0.0)
    $beamPts = [System.Drawing.PointF[]]@((P 42 146), (P -16 116), (P -16 176))
    $g.FillPolygon($beamBrush, $beamPts)
    $lamp = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 244, 201))
    $g.FillEllipse($lamp, 38, 140, 14, 14)

    # Pantograph.
    $pantoPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 213, 225, 238), [float]4.2)
    $pantoPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pantoPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLines($pantoPen, [System.Drawing.PointF[]]@((P 120 114), (P 120 96), (P 144 96)))
    $g.DrawLine($pantoPen, 120, 96, 108, 86)
    $g.DrawLine($pantoPen, 144, 96, 160, 86)
    $g.DrawLine($pantoPen, 100, 86, 168, 86)

    # Wheels.
    $wheel = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 11, 21, 34))
    $hub = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 141, 162, 183))
    foreach ($cx in @(80, 182)) {
        $g.FillEllipse($wheel, $cx - 12, 172, 24, 24)
        $g.FillEllipse($hub, $cx - 6, 178, 12, 12)
    }

    $bgPath.Dispose(); $bgBrush.Dispose(); $rimPen.Dispose(); $sunGlow.Dispose(); $sunGlow2.Dispose()
    $sun.Dispose(); $sunHi.Dispose(); $ridgeBrush.Dispose(); $wirePen.Dispose()
    $railPen.Dispose(); $rail2.Dispose(); $sleeperPen.Dispose(); $bodyBrush.Dispose()
    $hi.Dispose(); $bandBrush.Dispose(); $orange.Dispose(); $skirt.Dispose()
    $dark.Dispose(); $glass.Dispose(); $beamBrush.Dispose(); $lamp.Dispose()
    $pantoPen.Dispose(); $wheel.Dispose(); $hub.Dispose()
    $g.Dispose()
    return $bmp
}

function Resize-Icon([System.Drawing.Bitmap]$src, [int]$size) {
    $bmp = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $size, $size)
    $g.Dispose()
    return $bmp
}

$base = Draw-Base
$base.Save($OutPreview, [System.Drawing.Imaging.ImageFormat]::Png)
$sizes = @(256, 128, 64, 48, 32, 16)
$pngs = @()
foreach ($s in $sizes) {
    if ($s -eq 256) {
        $bmp = $base
    } else {
        $bmp = Resize-Icon $base $s
    }
    $ms = [System.IO.MemoryStream]::new()
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngs += ,$ms.ToArray()
    $ms.Dispose()
    if ($s -ne 256) { $bmp.Dispose() }
}

# ICONDIR + ICONDIRENTRY[] + PNG payloads.
$fs = [System.IO.File]::Create($OutIco)
$bw = [System.IO.BinaryWriter]::new($fs)
$bw.Write([UInt16]0)
$bw.Write([UInt16]1)
$bw.Write([UInt16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $bw.Write([Byte]$(if ($s -ge 256) { 0 } else { $s }))
    $bw.Write([Byte]$(if ($s -ge 256) { 0 } else { $s }))
    $bw.Write([Byte]0)
    $bw.Write([Byte]0)
    $bw.Write([UInt16]1)
    $bw.Write([UInt16]32)
    $bw.Write([UInt32]$pngs[$i].Length)
    $bw.Write([UInt32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($png in $pngs) { $bw.Write($png) }
$bw.Flush(); $bw.Close(); $fs.Close()
$base.Dispose()
Write-Output ("OK: {0} ({1:N0} bytes) + preview" -f $OutIco, (Get-Item $OutIco).Length)
