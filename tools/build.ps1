$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content (Join-Path $projectRoot "manifest.json") -Raw | ConvertFrom-Json
$distDirectory = Join-Path $projectRoot "dist"
$stageDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "WheelSeek-build-$([guid]::NewGuid())"
$archivePath = Join-Path $distDirectory "WheelSeek-$($manifest.version).zip"

[System.IO.Directory]::CreateDirectory($distDirectory) | Out-Null
[System.IO.Directory]::CreateDirectory($stageDirectory) | Out-Null

try {
    foreach ($entry in @(
        "manifest.json",
        "content",
        "icons",
        "lib",
        "popup",
        "_locales"
    )) {
        Copy-Item (Join-Path $projectRoot $entry) $stageDirectory -Recurse
    }

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath
    }

    Compress-Archive -Path (Join-Path $stageDirectory "*") -DestinationPath $archivePath
    Write-Output $archivePath
}
finally {
    if (Test-Path -LiteralPath $stageDirectory) {
        Remove-Item -LiteralPath $stageDirectory -Recurse
    }
}
