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

REM Try multiple Python commands
python --version >nul 2>&1
if %errorlevel%==0 (
    echo Using: python
    echo Opening browser for Google login...
    python -c "import webbrowser; webbrowser.open('https://notebooklm.google.com/')"
    echo.
    echo COMPLETE the Google login in the browser, then come back here.
    echo.
    pause
    echo Running authentication...
    python -m notebooklm login
    goto :check
)

py --version >nul 2>&1
if %errorlevel%==0 (
    echo Using: py launcher
    echo Opening browser for Google login...
    py -c "import webbrowser; webbrowser.open('https://notebooklm.google.com/')"
    echo.
    echo COMPLETE the Google login in the browser, then come back here.
    echo.
    pause
    echo Running authentication...
    py -m notebooklm login
    goto :check
)

python3 --version >nul 2>&1
if %errorlevel%==0 (
    echo Using: python3
    echo Opening browser for Google login...
    python3 -c "import webbrowser; webbrowser.open('https://notebooklm.google.com/')"
    echo.
    echo COMPLETE the Google login in the browser, then come back here.
    echo.
    pause
    echo Running authentication...
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
    echo 4. Browser didn't open? Try disabling popup blockers
    echo ==============================================
)
pause
