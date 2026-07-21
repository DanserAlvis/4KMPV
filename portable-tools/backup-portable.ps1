$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupRoot = Join-Path $root 'portable_backups'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $backupRoot "4KMPV-portable-$stamp.zip"
$stage = Join-Path ([IO.Path]::GetTempPath()) "4KMPV-backup-$stamp"

New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
New-Item -ItemType Directory -Force -Path $stage | Out-Null

try {
    $configStage = Join-Path $stage 'portable_config'
    New-Item -ItemType Directory -Force -Path $configStage | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $root 'portable_config') -Force | Where-Object { $_.Name -ne 'cache' } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $configStage -Recurse -Force
    }

    Copy-Item -LiteralPath (Join-Path $root 'portable-tools') -Destination $stage -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $root 'portable-assets') -Destination $stage -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $root 'updater.bat') -Destination $stage -Force
    Copy-Item -LiteralPath (Join-Path $root '4KMPV.exe') -Destination $stage -Force
    Copy-Item -LiteralPath (Join-Path $root 'LEEME-PORTABLE.txt') -Destination $stage -Force
    Copy-Item -LiteralPath (Join-Path $root 'SHIRO_STYLE.md') -Destination $stage -Force

    $installerStage = Join-Path $stage 'installer'
    New-Item -ItemType Directory -Force -Path $installerStage | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'installer\mpv-icon.ico') -Destination $installerStage -Force

    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal
    Get-ChildItem -LiteralPath $backupRoot -Filter '4KMPV-portable-*.zip' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 3 |
        Remove-Item -Force
    Write-Host "Portable backup created: $archive" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
