@echo off
chcp 65001 >nul
echo ==============================================
echo NotebookLM Flashcard Generator - Auth Helper
echo ==============================================
echo.

REM Get the directory where this bat file is located
for %%i in ("%~dp0.") do set "ADDON_DIR=%%~fi"
cd /d "%ADDON_DIR%"

REM Set PYTHONPATH to use bundled libs
set "PYTHONPATH=%ADDON_DIR%\libs"
echo PYTHONPATH set to: %PYTHONPATH%
echo.

REM Try multiple Python commands - find the FIRST working one
set PYTHON_CMD=

REM Try python first
python --version >nul 2>&1
if %errorlevel%==0 set PYTHON_CMD=python

REM Try py next
if "%PYTHON_CMD%"=="" (
    py --version >nul 2>&1
    if !errorlevel!==0 set PYTHON_CMD=py
)

REM Try python3 next
if "%PYTHON_CMD%"=="" (
    python3 --version >nul 2>&1
    if !errorlevel!==0 set PYTHON_CMD=python3
)

if "%PYTHON_CMD%"=="" (
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
)

echo Using Python: %PYTHON_CMD%
echo.

:check_playwright
echo Checking if Playwright is installed in bundled libs...
echo Checking: %ADDON_DIR%\libs

REM Check if playwright folder exists first
if exist "%ADDON_DIR%\libs\playwright" (
    echo Playwright package folder found.
    REM Try to import
    for /f "delims=" %%P in ("%ADDON_DIR%\libs") do set LIBS_PATH=%%~P
    %PYTHON_CMD% -c "import sys; sys.path.insert(0, r'%LIBS_PATH%'); import playwright" >nul 2>&1
    if %errorlevel%==0 (
        echo Playwright already installed and working.
        goto :verify_playwright_libs
    )
    echo Playwright folder exists but import failed. Will reinstall...
) else (
    echo Playwright not found in bundled libs.
)

:install_playwright
echo Playwright not found. Installing now...
echo This may take a few minutes...
echo.

REM Clear pip cache first (fixes deserialization errors)
%PYTHON_CMD% -m pip cache purge >nul 2>&1

REM Install playwright with all dependencies
%PYTHON_CMD% -m pip install --upgrade --target="%ADDON_DIR%\libs" playwright pyee greenlet typing-extensions

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to install Playwright and dependencies.
    echo.
    echo Possible causes:
    echo 1. No internet connection
    echo 2. Firewall blocking pip
    echo 3. Running as administrator with restricted network access
    echo.
    echo Solutions:
    echo 1. Run this script as a REGULAR user (not administrator)
    echo 2. Temporarily disable firewall/antivirus
    echo 3. Try manual install in Command Prompt:
    echo    %PYTHON_CMD% -m pip install playwright
    echo.
    pause
    exit /b 1
)

echo.
echo Verifying installation...
echo Checking libs folder: %ADDON_DIR%\libs

REM Check if playwright folder exists in libs
if not exist "%ADDON_DIR%\libs\playwright" (
    echo ERROR: playwright folder not found in libs!
    echo Expected: %ADDON_DIR%\libs\playwright
    pause
    exit /b 1
)

REM Try to import with proper path handling
for /f "delims=" %%P in ("%ADDON_DIR%\libs") do set LIBS_PATH=%%~P
%PYTHON_CMD% -c "import sys; sys.path.insert(0, r'%LIBS_PATH%'); import playwright; import pyee; import greenlet; print('Verification passed')" >nul 2>&1

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Installation verification failed.
    echo Playwright was installed but cannot be imported.
    echo.
    echo Debug information:
    echo Python command used: %PYTHON_CMD%
    echo Libs path: %LIBS_PATH%
    echo.
    echo Please try:
    echo 1. Close and reopen Command Prompt
    echo 2. Run as a REGULAR user (not administrator)
    echo.
    pause
    exit /b 1
)

echo Verification passed!
echo Playwright and dependencies installed successfully.
echo.
goto :ask_browser

:verify_playwright_libs
echo Verifying bundled Playwright works...
echo Checking libs folder: %ADDON_DIR%\libs

REM Check if playwright folder exists
if not exist "%ADDON_DIR%\libs\playwright" (
    echo Playwright folder not found. Installing...
    goto :install_playwright
)

REM Verify imports work
for /f "delims=" %%P in ("%ADDON_DIR%\libs") do set LIBS_PATH=%%~P
%PYTHON_CMD% -c "import sys; sys.path.insert(0, r'%LIBS_PATH%'); import playwright; import pyee; import greenlet; print('OK')" >nul 2>&1
if %errorlevel% neq 0 (
    echo Bundled Playwright verification failed. Reinstalling...
    goto :install_playwright
)
echo Bundled Playwright verified.
goto :ask_browser

:ask_browser
echo ==============================================
echo Browser Selection
echo ==============================================
echo.
echo The authentication requires a browser. Choose one:
echo.
echo 1. Use system Chrome (RECOMMENDED - no download needed)
echo    - Uses your installed Chrome browser
echo    - Faster, no extra downloads
echo.
echo 2. Use Playwright Chromium (requires download ~300MB)
echo    - Downloads Chromium browser automatically
echo    - May fail due to network/firewall issues
echo.
set /p BROWSER_CHOICE="Enter 1 or 2 (default: 1): "
if "%BROWSER_CHOICE%"=="" set BROWSER_CHOICE=1

if "%BROWSER_CHOICE%"=="1" (
    goto :find_chrome
) else if "%BROWSER_CHOICE%"=="2" (
    goto :install_chromium
) else (
    echo Invalid choice. Please enter 1 or 2.
    goto :ask_browser
)

:find_chrome
echo.
echo Looking for system Chrome...
set NOTEBOOKLM_BROWSER_PATH=

REM Try to find Chrome in default locations
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set NOTEBOOKLM_BROWSER_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe
    goto :verify_chrome
)

if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set NOTEBOOKLM_BROWSER_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe
    goto :verify_chrome
)

REM Try to find chrome in PATH
for %%i in (chrome.exe) do set CHROME_PATH=%%~$PATH:i
if not "%CHROME_PATH%"=="" (
    set NOTEBOOKLM_BROWSER_PATH=%CHROME_PATH%
    goto :verify_chrome
)

echo Chrome not found in default locations.
echo.
set /p MANUAL_PATH="Enter full path to chrome.exe (or press ENTER to try Chromium): "
if not "%MANUAL_PATH%"=="" (
    if exist "%MANUAL_PATH%" (
        set NOTEBOOKLM_BROWSER_PATH=%MANUAL_PATH%
        goto :verify_chrome
    ) else (
        echo Path not found: %MANUAL_PATH%
    )
)

echo.
echo Falling back to Playwright Chromium...
goto :install_chromium

:verify_chrome
if not exist "%NOTEBOOKLM_BROWSER_PATH%" (
    echo ERROR: Chrome path is invalid: %NOTEBOOKLM_BROWSER_PATH%
    echo Falling back to Playwright Chromium...
    goto :install_chromium
)
echo Using system Chrome: %NOTEBOOKLM_BROWSER_PATH%
echo.

REM Save browser path to config file for addon
echo NOTEBOOKLM_BROWSER_PATH=%NOTEBOOKLM_BROWSER_PATH% > "%ADDON_DIR%\browser_config.ini"
echo Browser configuration saved to: %ADDON_DIR%\browser_config.ini
echo.

REM Set environment variable for this session
set NOTEBOOKLM_BROWSER_PATH=%NOTEBOOKLM_BROWSER_PATH%
goto :do_login

:install_chromium
echo.
echo Installing Playwright Chromium browser...
echo This may take a few minutes and requires internet connection.
echo.
set PLAYWRIGHT_BROWSERS_PATH=%ADDON_DIR%\browsers
if not exist "%ADDON_DIR%\browsers" mkdir "%ADDON_DIR%\browsers"
%PYTHON_CMD% -m playwright install chromium
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to install Chromium.
    echo.
    echo Possible causes:
    echo 1. No internet connection
    echo 2. Firewall blocking the download
    echo 3. Running as administrator with restricted network access
    echo.
    echo Solutions:
    echo 1. Run this script as a REGULAR user (not administrator)
    echo 2. Temporarily disable firewall/antivirus
    echo 3. Use system Chrome instead (run script again, choose option 1)
    echo.
    pause
    exit /b 1
)
echo Chromium installed successfully.
echo.

REM Save browser config for addon
echo PLAYWRIGHT_BROWSERS_PATH=%ADDON_DIR%\browsers > "%ADDON_DIR%\browser_config.ini"
echo Browser configuration saved to: %ADDON_DIR%\browser_config.ini
echo.

goto :do_login

:do_login
echo ==============================================
echo IMPORTANT: Authentication Instructions
echo ==============================================
echo.
echo 1. A browser window will open from Playwright (incognito/private mode).
echo 2. Log in to Google in THAT browser window (fresh session, no saved accounts).
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

REM Set environment for notebooklm login
set PYTHONPATH=%ADDON_DIR%\libs

REM Load browser config if exists
if exist "%ADDON_DIR%\browser_config.ini" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%ADDON_DIR%\browser_config.ini") do (
        if "%%a"=="NOTEBOOKLM_BROWSER_PATH" set NOTEBOOKLM_BROWSER_PATH=%%b
        if "%%a"=="PLAYWRIGHT_BROWSERS_PATH" set PLAYWRIGHT_BROWSERS_PATH=%%b
    )
)

REM Set browser path if using chromium
if exist "%ADDON_DIR%\browsers" (
    set PLAYWRIGHT_BROWSERS_PATH=%ADDON_DIR%\browsers
)

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

    REM Also copy credentials to addon directory for portability
    copy /Y "%STORAGE_PATH%" "%ADDON_DIR%\storage_state.json" >nul 2>&1
    if exist "%ADDON_DIR%\storage_state.json" (
        echo Credentials also copied to addon directory for portability:
        echo %ADDON_DIR%\storage_state.json
        echo.
    )

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
    echo 3. You may have logged into the wrong browser window
    echo.
    echo Try running auth_helper.bat again.
    echo ==============================================
)
pause
