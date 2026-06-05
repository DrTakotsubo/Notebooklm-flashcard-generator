#!/bin/bash
# =============================================================================
# update_local_anki.sh - Update files in the local Anki addon directory
# =============================================================================
# This script copies only the source code files (.py, .sh, .bat, manifest.json)
# to the active Anki addon folder, preserving libs/ and storage_state.json.
# =============================================================================

set -e

# Detect OS and Anki Addon Directory
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ADDON_DIR="$HOME/.local/share/Anki2/addons21"
    if [ -d "$HOME/.var/app/net.ankiweb.Anki" ]; then
        ADDON_DIR="$HOME/.var/app/net.ankiweb.Anki/data/Anki2/addons21"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ADDON_DIR="$HOME/Library/Application Support/Anki2/addons21"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    ADDON_DIR="$APPDATA/Anki2/addons21"
else
    echo "ERROR: Unsupported OS"
    exit 1
fi

TARGET_DIR="$ADDON_DIR/notebooklm-flashcard-generator"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Creating target directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

echo "Updating source files in: $TARGET_DIR"
echo "Preserving libs/ and storage_state.json..."

# Copy only source files, scripts, and manifest
cp __init__.py "$TARGET_DIR/"
cp notebooklm.py "$TARGET_DIR/"
cp custom_login.py "$TARGET_DIR/"
cp prompt_manager.py "$TARGET_DIR/"
cp auth_helper.sh "$TARGET_DIR/"
cp auth_helper.bat "$TARGET_DIR/"
cp manifest.json "$TARGET_DIR/"
cp meta.json "$TARGET_DIR/" 2>/dev/null || true

echo "================================================="
echo "Update Complete! Please restart Anki."
echo "================================================="
