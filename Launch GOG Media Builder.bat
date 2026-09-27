@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GogMediaBuilder.ps1"
if errorlevel 1 (
    echo.
    echo The builder could not start. Press any key to close this window.
    pause >nul
)
endlocal
