#!/bin/bash
# =============================================================================
# auth_helper.sh - NotebookLM Authentication Helper (Linux/macOS)
# =============================================================================
# This script helps users authenticate with NotebookLM by running the
# notebooklm login command with proper setup for system browsers.
# =============================================================================

set -e

echo "=============================================="
echo "NotebookLM Flashcard Generator - Auth Helper"
echo "=============================================="
echo

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set PYTHONPATH to use bundled libs
export PYTHONPATH="$SCRIPT_DIR/libs"
echo "Setting PYTHONPATH to: $PYTHONPATH"
echo

# Check if Python is available
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "=============================================="
    echo "ERROR: Python not found!"
    echo
    echo "This addon REQUIRES Python to be installed separately."
    echo
    echo "Install Python:"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip"
    echo "  Fedora: sudo dnf install python3 python3-pip"
    echo "  macOS: brew install python3"
    echo "=============================================="
    exit 1
fi

echo "Using Python: $($PYTHON_CMD --version)"
echo

# Install Playwright browsers (REQUIRED for notebooklm login)
echo "Installing Playwright browsers (Chromium)..."
$PYTHON_CMD -m playwright install chromium
if [[ $? -ne 0 ]]; then
    echo
    echo "WARNING: Failed to install Chromium."
    echo "The login process may fail to open a browser."
    echo "Try running manually: $PYTHON_CMD -m playwright install chromium"
    echo
    read -p "Press ENTER to continue anyway..."
fi

# Ask user if they want to use system Chrome
read -p "Use system Chrome instead of Playwright Chromium? (y/n): " USE_CHROME
if [[ "$USE_CHROME" =~ ^[Yy]$ ]]; then
    # Try to find Chrome/Chromium
    CHROME_PATH=""
    for browser in google-chrome chromium chromium-browser /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome; do
        if command -v "$browser" &> /dev/null; then
            CHROME_PATH="$browser"
            break
        elif [[ -x "$browser" ]]; then
            CHROME_PATH="$browser"
            break
        fi
    done

    if [[ -n "$CHROME_PATH" ]]; then
        # Verify the path is valid
        if [[ -x "$CHROME_PATH" ]]; then
            export NOTEBOOKLM_BROWSER_PATH="$CHROME_PATH"
            echo "Using system browser: $NOTEBOOKLM_BROWSER_PATH"
        else
            echo "ERROR: Chrome path is not executable: $CHROME_PATH"
            echo "Proceeding with Playwright's bundled Chromium..."
        fi
    else
        echo "Chrome not found in PATH. Please enter the full path:"
        read -p "Chrome path (or press ENTER to use Chromium): " MANUAL_PATH
        if [[ -n "$MANUAL_PATH" && -x "$MANUAL_PATH" ]]; then
            export NOTEBOOKLM_BROWSER_PATH="$MANUAL_PATH"
            echo "Using: $NOTEBOOKLM_BROWSER_PATH"
        else
            echo "Proceeding with Playwright's bundled Chromium..."
        fi
    fi
fi

echo
echo "=============================================="
echo "IMPORTANT: Authentication Instructions"
echo "=============================================="
echo
echo "1. A browser window will open from Playwright."
echo "2. Log in to Google in THAT browser window."
echo "3. Do NOT use your default browser (it won't work)."
echo "4. After logging in, wait for NotebookLM homepage to load."
echo "5. Come back here and press ENTER."
echo
echo "NOTE: The browser window may open BEHIND other windows."
echo "Check your taskbar/dock if you don't see it."
echo
read -p "Press ENTER when ready to start authentication..."
echo
echo "Running authentication..."
echo

# Run login
$PYTHON_CMD -m notebooklm login

# Verify credentials
STORAGE_PATH="$HOME/.notebooklm/storage_state.json"
if [[ -f "$STORAGE_PATH" ]]; then
    echo
    echo "=============================================="
    echo "SUCCESS: Credentials saved!"
    echo "Location: $STORAGE_PATH"
    echo
    echo "You can now use the addon in Anki."
    echo "=============================================="

    # For Flatpak users, copy to the correct location
    if [[ -d "$HOME/.var/app/net.ankiweb.Anki" ]]; then
        FLATPAK_PATH="$HOME/.var/app/net.ankiweb.Anki/data/.notebooklm"
        mkdir -p "$FLATPAK_PATH"
        cp "$STORAGE_PATH" "$FLATPAK_PATH/"
        echo
        echo "Credentials also copied to Flatpak path:"
        echo "$FLATPAK_PATH/storage_state.json"
    fi
else
    echo
    echo "=============================================="
    echo "ERROR: Credentials not found."
    echo
    echo "Possible issues:"
    echo "1. You didn't complete the login in the Playwright browser"
    echo "2. Playwright browser failed to open (check errors above)"
    echo "3. Missing Chromium: Run: $PYTHON_CMD -m playwright install chromium"
    echo
    echo "Try running auth_helper.sh again."
    echo "=============================================="
    exit 1
fi
