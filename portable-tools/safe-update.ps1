param([switch]$ValidateOnly)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backupScript = Join-Path $PSScriptRoot 'backup-portable.ps1'
$backupRoot = Join-Path $root 'portable_backups'
$updater = Join-Path $root 'installer\updater.ps1'
$protectedFiles = @(
    'portable_config\input.conf',
    'portable_config\mpv.conf',
    'portable_config\script-opts\uosc.conf',
    'portable_config\scripts\anime4k-manager.lua',
    'portable_config\scripts\portable-tools.lua',
    'portable-tools\safe-update.ps1',
    '4KMPV.exe',
    'updater.bat',
    'installer\mpv-icon.ico',
    'LEEME-PORTABLE.txt',
    'SHIRO_STYLE.md'
)

if (-not (Test-Path -LiteralPath $updater)) { throw "Updater not found: $updater" }
if (-not (Test-Path -LiteralPath $backupScript)) { throw "Backup tool not found: $backupScript" }

$hashes = @{}
foreach ($relative in $protectedFiles) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) { throw "Protected file not found: $relative" }
    $hashes[$relative] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

& $backupScript
$archive = Get-ChildItem -LiteralPath $backupRoot -Filter '4KMPV-portable-*.zip' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if (-not $archive) { throw 'The safety backup was not created.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($archive.FullName)
try {
    $entryNames = @($zip.Entries | ForEach-Object { $_.FullName.Replace('/', '\') })
    foreach ($relative in $protectedFiles) {
        if ($entryNames -notcontains $relative) { throw "Backup is incomplete: $relative" }
    }
}
finally { $zip.Dispose() }

if ($ValidateOnly) {
    Write-Host 'Updater validation passed. Protected configuration is complete.' -ForegroundColor Green
    exit 0
}

$engine = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $engine) { $engine = Get-Command powershell -ErrorAction Stop }
$exitCode = 1

try {
    Write-Host 'Starting official mpv updater...' -ForegroundColor Cyan
    $arguments = @('-NoProfile', '-NoLogo', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $updater + '"'))
    $process = Start-Process -FilePath $engine.Source -ArgumentList $arguments -WorkingDirectory $root -NoNewWindow -Wait -PassThru
    $exitCode = $process.ExitCode
}
finally {
    Write-Host 'Restoring protected portable configuration...' -ForegroundColor Cyan
    Expand-Archive -LiteralPath $archive.FullName -DestinationPath $root -Force
}

foreach ($relative in $protectedFiles) {
    $path = Join-Path $root $relative
    $restoredHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($restoredHash -ne $hashes[$relative]) { throw "Integrity check failed after update: $relative" }
}

if ($exitCode -ne 0) { throw "The official updater returned exit code $exitCode. Configuration was restored." }
Write-Host 'Update completed. Configuration and custom menus passed integrity checks.' -ForegroundColor Green
