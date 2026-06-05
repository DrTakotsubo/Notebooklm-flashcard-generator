@echo off
REM =============================================================================
REM update_local_anki.bat - Update files in the local Anki addon directory
REM =============================================================================

set "TARGET_DIR=%APPDATA%\Anki2\addons21\notebooklm-flashcard-generator"

if not exist "%TARGET_DIR%" (
    echo Creating target directory: %TARGET_DIR%
    mkdir "%TARGET_DIR%"
)

echo Updating source files in: %TARGET_DIR%
echo Preserving libs/ and storage_state.json...

copy /Y __init__.py "%TARGET_DIR%\"
copy /Y notebooklm.py "%TARGET_DIR%\"
copy /Y custom_login.py "%TARGET_DIR%\"
copy /Y prompt_manager.py "%TARGET_DIR%\"
copy /Y auth_helper.sh "%TARGET_DIR%\"
copy /Y auth_helper.bat "%TARGET_DIR%\"
copy /Y manifest.json "%TARGET_DIR%\"
copy /Y meta.json "%TARGET_DIR%\" 2>nul

echo =================================================
echo Update Complete! Please restart Anki.
echo =================================================
pause
