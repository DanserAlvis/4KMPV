@echo off
setlocal
pushd "%~dp0"

if not exist "%~dp0portable-tools\safe-update.ps1" (
    echo ERROR: portable-tools\safe-update.ps1 was not found.
    echo Update cancelled to protect portable_config.
    pause
    exit /b 1
)

where pwsh >nul 2>nul
if %errorlevel% equ 0 (
    pwsh -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0portable-tools\safe-update.ps1"
) else (
    powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "%~dp0portable-tools\safe-update.ps1"
)

set "update_exit=%errorlevel%"
if not "%update_exit%"=="0" (
    echo.
    echo Update failed or was cancelled. The portable configuration was preserved.
    pause
)
popd
exit /b %update_exit%
