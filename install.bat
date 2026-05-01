@echo off
echo ==============================================
echo NotebookLM Flashcard Generator - Installer
echo ==============================================
echo.

REM Try multiple possible Anki addons directories
set ADDON_NAME=notebooklm-flashcard-generator

if exist "%APPDATA%\Anki2\addons21" (
    set ADDON_DIR=%APPDATA%\Anki2\addons21
    goto :found
)

if exist "%LOCALAPPDATA%\Anki2\addons21" (
    set ADDON_DIR=%LOCALAPPDATA%\Anki2\addons21
    goto :found
)

REM If not found, ask user
echo Anki addons directory not found automatically.
echo Please enter the FULL path to your Anki2\addons21 folder:
set /p ADDON_DIR=
if not exist "%ADDON_DIR%" (
    echo ERROR: Directory not found!
    echo Typical location: C:\Users\YourName\AppData\Roaming\Anki2\addons21
    echo Please install Anki first, or find the correct path.
    pause
    exit /b 1
)

:found
echo Installing to: %ADDON_DIR%
echo.

REM Create directory if needed
if not exist "%ADDON_DIR%" mkdir "%ADDON_DIR%"

REM Check if git exists
where git >nul 2>&1
if %errorlevel%==0 (
    REM Clone repository using git
    cd /d "%ADDON_DIR%"
    if exist "%ADDON_NAME%" (
        echo Updating existing installation...
        cd "%ADDON_NAME%"
        git pull origin main
    ) else (
        echo Downloading addon...
        git clone https://github.com/DrTakotsubo/notebooklm-flashcard-generator.git "%ADDON_NAME%"
    )
) else (
    echo Git not found, downloading directly...
    cd /d "%ADDON_DIR%"
    if not exist "%ADDON_NAME%" (
        mkdir "%ADDON_NAME%"
    )
    cd "%ADDON_NAME%"
    
    REM Download files using curl or PowerShell
    where curl >nul 2>&1
    if %errorlevel%==0 (
        echo Downloading install.sh...
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/install.sh -o install.sh
        echo Downloading auth_helper.sh...
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/auth_helper.sh -o auth_helper.sh
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/auth_helper.bat -o auth_helper.bat
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/prompt_manager.py -o prompt_manager.py
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/__init__.py -o __init__.py
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/notebooklm.py -o notebooklm.py
        curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/README.md -o README.md
    ) else (
        echo curl not found, using PowerShell...
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/install.sh' -OutFile 'install.sh'"
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/auth_helper.sh' -OutFile 'auth_helper.sh'"
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/auth_helper.bat' -OutFile 'auth_helper.bat'"
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/prompt_manager.py' -OutFile 'prompt_manager.py'"
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/__init__.py' -OutFile '__init__.py'"
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/notebooklm.py' -OutFile 'notebooklm.py'"
        powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/README.md' -OutFile 'README.md'"
    )
)

echo.
echo ==============================================
echo Installation Complete!
echo ==============================================
echo.
echo IMPORTANT: Python is REQUIRED to use this addon!
echo If you see "python not found" errors:
echo 1. Download Python from: https://www.python.org/downloads/
echo 2. CHECK "Add Python to PATH" during installation!
echo 3. Restart your computer after installing Python.
echo.
echo Next steps:
echo 1. Restart Anki
echo 2. Go to Tools → Import from NotebookLM...
echo 3. Double-click auth_helper.bat in addon folder
echo.
pause
