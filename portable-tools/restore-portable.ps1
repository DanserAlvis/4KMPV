$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupRoot = Join-Path $root 'portable_backups'
$latest = Get-ChildItem -LiteralPath $backupRoot -Filter '4KMPV-portable-*.zip' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latest) { throw 'No portable backup was found.' }

Write-Host "Restoring: $($latest.FullName)" -ForegroundColor Cyan
Expand-Archive -LiteralPath $latest.FullName -DestinationPath $root -Force
Write-Host 'Portable product restored. Cache and mpv binaries were left untouched.' -ForegroundColor Green
