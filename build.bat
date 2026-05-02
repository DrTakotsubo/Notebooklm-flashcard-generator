@echo off
REM =============================================================================
REM build.bat - Build script for NotebookLM Flashcard Generator addon (Windows)
REM =============================================================================
REM This script:
REM 1. Installs Python dependencies to libs/ (including playwright)
REM 2. Optionally downloads Playwright browsers to browsers/ folder
REM 3. Creates the .ankiaddon package
REM 4. Cleans up unnecessary files
REM =============================================================================

echo ==============================================
echo NotebookLM Flashcard Generator - Build Script
echo ==============================================
echo.

REM Get the directory where this bat file is located
for %%i in ("%~dp0.") do set "SCRIPT_DIR=%%~fi"
cd /d "%SCRIPT_DIR%"

REM Try to find Python
python --version >nul 2>&1
if %errorlevel%==0 (
    set PYTHON_CMD=python
    goto :start_build
)

py --version >nul 2>&1
if %errorlevel%==0 (
    set PYTHON_CMD=py
    goto :start_build
)

python3 --version >nul 2>&1
if %errorlevel%==0 (
    set PYTHON_CMD=python3
    goto :start_build
)

echo ERROR: Python not found!
pause
exit /b 1

:start_build
echo Using Python: %PYTHON_CMD%
echo.

REM Step 1: Install Python dependencies to libs/
echo Step 1: Installing Python dependencies to libs/...
echo.

REM Create libs directory if it doesn't exist
if not exist "libs\" mkdir libs

REM Install required packages
%PYTHON_CMD% -m pip install notebooklm-py playwright --target=libs/ --quiet

echo Dependencies installed.
echo.

REM Step 2: Ask if user wants to bundle Chromium browser
echo Step 2: Bundle Playwright Chromium browser?
echo.
echo This will download Chromium (~300MB) to browsers/ folder.
echo If you say 'no', users will need to run 'playwright install chromium' themselves.
echo.
set /p BUNDLE_CHROMIUM="Bundle Chromium? (y/n, default: n): "
if "%BUNDLE_CHROMIUM%"=="" set BUNDLE_CHROMIUM=n

if /i "%BUNDLE_CHROMIUM%"=="y" (
    echo.
    echo Downloading Chromium browser...
    set "PLAYWRIGHT_BROWSERS_PATH=%SCRIPT_DIR%\browsers"
    mkdir "%PLAYWRIGHT_BROWSERS_PATH%" 2>nul
    %PYTHON_CMD% -m playwright install chromium
    echo Chromium downloaded to: %PLAYWRIGHT_BROWSERS_PATH%
) else (
    echo Skipping Chromium download.
)
echo.

REM Step 3: Clean up unnecessary files
echo Step 3: Cleaning up unnecessary files...
if exist "libs\__pycache__" rmdir /s /q "libs\__pycache__" 2>nul
for /r libs %%f in (*.pyc) do del /q "%%f" 2>nul
echo Cleanup done.
echo.

REM Step 4: Create .ankiaddon package
echo Step 4: Creating .ankiaddon package...
set OUTPUT_FILE=%SCRIPT_DIR%\..\NotebookLM-Flashcard-Generator.ankiaddon

cd "%SCRIPT_DIR%"
%PYTHON_CMD% -c "import zipfile, os; addon_dir='.'; output_file=r'%OUTPUT_FILE%'; zipf=zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED); [zipf.write(os.path.join(r, f), os.path.relpath(os.path.join(r, f), addon_dir)) for r,_,fs in os.walk(addon_dir) for f in fs if not f.endswith('.pyc') and not f==os.path.basename(output_file) and 'browsers' not in r]; zipf.close(); print(f'Created {output_file}')"

echo.
echo ==============================================
echo Build complete!
echo ==============================================
echo.
echo Output: %OUTPUT_FILE%
echo.
echo Next steps:
echo 1. Test the addon by installing it in Anki
echo 2. Upload to GitHub Releases
echo 3. Update the release notes
echo.
pause
