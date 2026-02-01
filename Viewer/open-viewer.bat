@echo off
setlocal

echo ======================================
echo Documentation Viewer - Quick Start
echo ======================================
echo.

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"
set "DOC_ROOT=%SCRIPT_DIR%.."

echo Opening viewer with file:// protocol...
echo Note: Some features may be limited. For full functionality, use start-server.ps1
echo.

REM Open the viewer in default browser
start "" "%SCRIPT_DIR%index.html"

echo.
echo Viewer opened in your default browser.
echo.
echo For full functionality with document loading:
echo   1. Open PowerShell in this directory
echo   2. Run: .\start-server.ps1
echo.
pause
