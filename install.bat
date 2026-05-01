@echo off
echo ===============================================
echo NotebookLM Flashcard Generator - Installer
echo ===============================================
echo.

REM Get Anki addons directory
set ADDON_DIR=%APPDATA%\Anki2\addons21
set ADDON_NAME=notebooklm-flashcard-generator

echo Installing to: %ADDON_DIR%
echo.

REM Create directory if needed
if not exist "%ADDON_DIR%" mkdir "%ADDON_DIR%"

REM Clone repository
cd /d "%ADDON_DIR%"
if exist "%ADDON_NAME%" (
    echo Updating existing installation...
    cd "%ADDON_NAME%"
    git pull origin main
) else (
    echo Downloading addon...
    git clone https://github.com/DrTakotsubo/notebooklm-flashcard-generator.git "%ADDON_NAME%"
)

echo.
echo ===============================================
echo Installation Complete!
echo ===============================================
echo.
echo Next steps:
echo 1. Restart Anki
echo 2. Go to Tools → Import from NotebookLM...
echo 3. Double-click auth_helper.bat in addon folder
echo.
pause
