#!/bin/bash
set -e

echo "================================================"
echo "NotebookLM Flashcard Generator - Installer"
echo "================================================"
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    ADDON_DIR="$HOME/.local/share/Anki2/addons21"
    # Check Flatpak
    if [ -d "$HOME/.var/app/net.ankiweb.Anki" ]; then
        ADDON_DIR="$HOME/.var/app/net.ankiweb.Anki/data/Anki2/addons21"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    ADDON_DIR="$HOME/Library/Application Support/Anki2/addons21"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    OS="windows"
    ADDON_DIR="$APPDATA/Anki2/addons21"
else
    echo "ERROR: Unsupported OS"
    exit 1
fi

echo "Detected OS: $OS"
echo "Anki addons directory: $ADDON_DIR"
echo ""

# Create addons directory if needed
mkdir -p "$ADDON_DIR"

# Get addon ID (for AnkiWeb) or use folder name
ADDON_NAME="notebooklm-flashcard-generator"

# Clone or update repository
if [ -d "$ADDON_DIR/$ADDON_NAME" ]; then
    echo "Updating existing installation..."
    cd "$ADDON_DIR/$ADDON_NAME"
    git pull origin main
else
    echo "Downloading addon..."
    cd "$ADDON_DIR"
    git clone https://github.com/DrTakotsubo/notebooklm-flashcard-generator.git "$ADDON_NAME"
fi

echo ""
echo "================================================"
echo "Installation Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Restart Anki"
echo "2. Go to Tools → Import from NotebookLM..."
echo "3. Run authentication when prompted, or use the auth helper"
echo ""
