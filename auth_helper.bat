@echo off
echo ===============================================
echo NotebookLM Flashcard Generator - Auth Helper
echo ===============================================
echo.

REM Get the directory where this bat file is located
cd /d "%~dp0"

REM Set PYTHONPATH to use bundled libs
set PYTHONPATH=%~dp0libs

echo Setting PYTHONPATH to: %PYTHONPATH%
echo.

REM Try different Python commands
echo Attempting authentication...
echo.

REM Try python first
python -m notebooklm login 2>nul
if %errorlevel%==0 goto success

REM Try py command
py -m notebooklm login 2>nul
if %errorlevel%==0 goto success

REM Try python3
python3 -m notebooklm login 2>nul
if %errorlevel%==0 goto success

echo.
echo ===============================================
echo ERROR: Python not found!
echo.
echo Please install Python from: https://www.python.org/downloads/
echo IMPORTANT: Check "Add Python to PATH" during installation!
echo ===============================================
pause
exit /b 1

:success
echo.
echo ===============================================
echo Authentication successful!
echo You can now use the addon in Anki.
echo ===============================================
pause
