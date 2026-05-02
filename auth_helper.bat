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
    set PYTHON_CMD=python
    goto :check_browser
)

py --version >nul 2>&1
if %errorlevel%==0 (
    set PYTHON_CMD=py
    goto :check_browser
)

python3 --version >nul 2>&1
if %errorlevel%==0 (
    set PYTHON_CMD=python3
    goto :check_browser
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
echo ==============================================
pause
exit /b 1

:check_browser
echo Using Python: %PYTHON_CMD%
echo.

REM Ask user if they want to use system Chrome
set /p USE_CHROME="Use system Chrome instead of downloading Chromium? (Y/N): "
if /i "%USE_CHROME%"=="Y" (
    goto :find_chrome
) else (
    goto :do_login
)

:find_chrome
REM Try to find Chrome in default locations
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set NOTEBOOKLM_BROWSER_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe
    goto :chrome_found
)

if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set NOTEBOOKLM_BROWSER_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe
    goto :chrome_found
)

REM Try to find chrome in PATH
%PYTHON_CMD% -c "import shutil; print(shutil.which('chrome'))" > %temp%\chrome_path.txt 2>nul
set /p CHROME_PATH=<%temp%\chrome_path.txt
del %temp%\chrome_path.txt >nul 2>&1

if exist "%CHROME_PATH%" (
    set NOTEBOOKLM_BROWSER_PATH=%CHROME_PATH%
    goto :chrome_found
)

echo.
echo Chrome not found in default locations.
echo Please enter the full path to chrome.exe manually, or press ENTER to use Chromium.
set /p MANUAL_PATH="Chrome path (or ENTER to skip): "
if not "%MANUAL_PATH%"=="" (
    if exist "%MANUAL_PATH%" (
        set NOTEBOOKLM_BROWSER_PATH=%MANUAL_PATH%
        goto :chrome_found
    )
)
echo Proceeding with Playwright's bundled Chromium...
goto :do_login

:chrome_found
echo Using system Chrome: %NOTEBOOKLM_BROWSER_PATH%
echo.

:do_login
echo ==============================================
echo IMPORTANT: Authentication Instructions
echo ==============================================
echo.
echo 1. A browser window will open from Playwright.
echo 2. Log in to Google in THAT browser window.
echo 3. Do NOT use your default browser (it won't work).
echo 4. After logging in, wait for NotebookLM homepage to load.
echo 5. Come back here and press ENTER.
echo.
echo NOTE: The browser window may open BEHIND other windows.
echo Check your taskbar if you don't see it.
echo.
pause
echo.
echo Running authentication...
echo.

REM Run login
%PYTHON_CMD% -m notebooklm login

REM Verify credentials
set STORAGE_PATH=%USERPROFILE%\.notebooklm\storage_state.json
if exist "%STORAGE_PATH%" (
    echo.
    echo ==============================================
    echo SUCCESS: Credentials saved!
    echo Location: %STORAGE_PATH%
    echo.
    echo You can now use the addon in Anki.
    echo ==============================================
) else (
    echo.
    echo ==============================================
    echo ERROR: Credentials not found.
    echo.
    echo Possible issues:
    echo 1. You didn't complete the login in the Playwright browser
    echo 2. Playwright browser failed to open (check errors above)
    echo 3. Missing Chromium: Run: %PYTHON_CMD% -m playwright install chromium
    echo.
    echo Try running auth_helper.bat again.
    echo ==============================================
)
pause
