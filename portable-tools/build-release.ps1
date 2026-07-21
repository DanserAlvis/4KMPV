param(
    [string]$Version = '1.0.0'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$archive = Join-Path $dist "4KMPV-Shiro-Portable-v$Version.zip"
$stage = Join-Path ([IO.Path]::GetTempPath()) ("4KMPV-release-" + [guid]::NewGuid().ToString('N'))

$files = @(
    '4KMPV.exe',
    'mpv.exe',
    'mpv.com',
    'd3dcompiler_43.dll',
    'updater.bat',
    'LEEME-PORTABLE.txt',
    'README.md',
    'SHIRO_STYLE.md'
)
$directories = @(
    'doc',
    'installer',
    'mpv',
    'portable-assets',
    'portable-tools',
    'portable_config'
)

New-Item -ItemType Directory -Force -Path $dist | Out-Null
New-Item -ItemType Directory -Force -Path $stage | Out-Null

try {
    foreach ($relative in $files) {
        $source = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $source)) { throw "Required file not found: $relative" }
        Copy-Item -LiteralPath $source -Destination $stage -Force
    }

    foreach ($relative in $directories) {
        $source = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $source)) { throw "Required directory not found: $relative" }
        Copy-Item -LiteralPath $source -Destination $stage -Recurse -Force
    }

    $privatePaths = @(
        'portable_config\cache',
        'portable_config\state',
        'portable_config\scripts\uosc\bin\ziggy-linux',
        'portable_config\scripts\uosc\bin\ziggy-darwin'
    )
    foreach ($relative in $privatePaths) {
        $target = Join-Path $stage $relative
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $stage 'portable_config\state') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $stage 'portable_config\cache') | Out-Null

    Get-ChildItem -LiteralPath (Join-Path $stage 'portable-assets') -File | Where-Object {
        $_.Name -like '*-source.png' -or
        $_.Name -like '*-legacy.png' -or
        $_.Name -like '*-legacy.ico' -or
        $_.Name -eq 'mpv-icon-original.ico'
    } | Remove-Item -Force

    if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $entryNames = @($zip.Entries | ForEach-Object { $_.FullName.Replace('/', '\') })
        foreach ($forbidden in @('last-session.json', 'watch_history.jsonl', 'anime4k.json')) {
            if ($entryNames -match [regex]::Escape($forbidden)) { throw "Private file found in release: $forbidden" }
        }
        foreach ($required in @('4KMPV.exe', 'mpv.exe', 'portable_config\mpv.conf', 'portable_config\scripts\anime4k-manager.lua')) {
            if ($entryNames -notcontains $required) { throw "Release is incomplete: $required" }
        }
    }
    finally {
        $zip.Dispose()
    }

    Write-Host "Release package created: $archive" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $stage) {
        $resolvedStage = (Resolve-Path -LiteralPath $stage).Path
        $resolvedTemp = (Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).Path
        if (-not $resolvedStage.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove a staging directory outside TEMP: $resolvedStage"
        }
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}

