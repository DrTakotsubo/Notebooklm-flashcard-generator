@echo off
echo ==============================================
echo NotebookLM Flashcard Generator - Auth Helper
echo ==============================================
echo.

REM Get the directory where this bat file is located
cd /d "%~dp0"

REM Set PYTHONPATH to use bundled libs
set PYTHONPATH=%~dp0libs%

echo Setting PYTHONPATH to: %PYTHONPATH%
echo.

REM Check if Python is available
where python >nul 2>&1
if %errorlevel%==0 (
    echo Using: python
    goto :run_auth
)

where py >nul 2>&1
if %errorlevel%==0 (
    echo Using: py launcher
    py -m notebooklm login
    goto :check
)

where python3 >nul 2>&1
if %errorlevel%==0 (
    echo Using: python3
    python3 -m notebooklm login
    goto :check
)

echo.
echo ==============================================
echo ERROR: Python not found!
echo.
echo This addon REQUIRES Python to be installed separately.
echo.
echo 1. Download Python from: https://www.python.org/downloads/
echo 2. IMPORTANT: Check "Add Python to PATH" during installation!
echo 3. After installing, RESTART your computer.
echo 4. Run this script again.
echo.
echo If you already installed Python, it might not be in PATH.
echo Try opening Command Prompt and type: python --version
echo ==============================================
pause
exit /b 1

:run_auth
REM Try to run notebooklm login
python -m notebooklm login 2>nul
if %errorlevel%==0 goto :check

REM If failed, try with explicit browser path
echo.
echo Trying alternative browser launch method...
python -c "import webbrowser; webbrowser.open('https://notebooklm.google.com')" 2>nul
python -m notebooklm login --no-browser
goto :check

:check
if %errorlevel%==0 (
    echo.
    echo ==============================================
    echo Authentication successful!
    echo You can now use the addon in Anki.
    echo ==============================================
) else (
    echo.
    echo ==============================================
    echo Authentication failed. See errors above.
    echo.
    echo Common issues:
    echo 1. NotebookLM not available in your country
    echo 2. Google authentication expired (re-run this script)
    echo 3. VPN/AdBlocker blocking the connection
    echo 4. Browser not opening? Try disabling popup blockers
    echo ==============================================
)
pause
