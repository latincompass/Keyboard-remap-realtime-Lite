@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: Change to the directory where this batch file is located
cd /d "%~dp0"

:: Clear screen
cls

:: Configuration
set "PORT=8080"
set "AUTO_OPEN=1"

:: Banner
echo ================================================================================
echo                      M6-B Keyboard Tool Server
echo ================================================================================
echo.

:: Kill any existing process using the port
echo [INFO] Checking port %PORT%...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%PORT% ^| findstr LISTENING') do (
    echo [WARN] Port %PORT% is in use, trying to stop existing process...
    taskkill /F /PID %%a >nul 2>&1
    timeout /t 1 /nobreak >nul
)

:: Check PowerShell version
echo [INFO] Checking PowerShell installation...
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Host 'PowerShell version too old'; exit 1 }"
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell 5.0+ is required but not found.
    echo [ERROR] Please install PowerShell 5 or newer.
    pause
    exit /b 1
)

echo [OK] PowerShell is available
echo.
echo [INFO] Starting HTTP server with PowerShell...
echo ================================================================================
echo.
echo   Server address: http://localhost:%PORT%
echo.
echo   Press Ctrl+C to stop the server
echo.
echo ================================================================================

:: Run PowerShell server script
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1" -Port %PORT% -AutoOpen "true"

:end
echo.
echo ================================================================================
echo                      Server stopped, thank you for using!
echo ===============================================================================
pause