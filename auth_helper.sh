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

# Check if playwright Python package is available
if ! $PYTHON_CMD -c "import playwright" &> /dev/null; then
    echo "Playwright not found. Installing to addon directory..."
    $PYTHON_CMD -m pip install playwright --target="$SCRIPT_DIR/libs"
    if [[ $? -ne 0 ]]; then
        echo
        echo "ERROR: Failed to install Playwright."
        echo
        echo "Possible causes:"
        echo "1. No internet connection"
        echo "2. Firewall blocking pip"
        echo
        echo "Solutions:"
        echo "1. Check your internet connection"
        echo "2. Temporarily disable firewall/antivirus"
        echo "3. Try running as a regular user (not sudo)"
        echo
        exit 1
    fi
    echo "Playwright installed successfully."
fi

# Browser selection menu
echo
echo "=============================================="
echo "Browser Selection"
echo "=============================================="
echo
echo "The authentication requires a browser. Choose one:"
echo
echo "1. Use system Chrome (RECOMMENDED - no download)"
echo "   - Uses your installed Chrome browser"
echo "   - Faster, no extra downloads"
echo
echo "2. Use Playwright Chromium (requires download ~300MB)"
echo "   - Downloads Chromium browser automatically"
echo "   - May fail due to network/firewall issues"
echo
read -p "Enter 1 or 2 (default: 1): " BROWSER_CHOICE
BROWSER_CHOICE=${BROWSER_CHOICE:-1}

if [[ "$BROWSER_CHOICE" == "1" ]]; then
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
            echo
            echo "Using system browser: $NOTEBOOKLM_BROWSER_PATH"
        else
            echo
            echo "ERROR: Chrome path is not executable: $CHROME_PATH"
            echo "Falling back to Playwright Chromium..."
            BROWSER_CHOICE="2"
        fi
    else
        echo
        echo "Chrome not found in PATH."
        read -p "Enter full path to Chrome (or press ENTER to use Chromium): " MANUAL_PATH
        if [[ -n "$MANUAL_PATH" && -x "$MANUAL_PATH" ]]; then
            export NOTEBOOKLM_BROWSER_PATH="$MANUAL_PATH"
            echo
            echo "Using: $NOTEBOOKLM_BROWSER_PATH"
        else
            echo
            echo "Falling back to Playwright Chromium..."
            BROWSER_CHOICE="2"
        fi
    fi
fi

if [[ "$BROWSER_CHOICE" == "2" ]]; then
    # Install Playwright browsers
    echo
    echo "Installing Playwright browsers (Chromium)..."
    echo "This may take a few minutes and requires internet connection."
    echo
    
    # Set PLAYWRIGHT_BROWSERS_PATH to bundle browsers in addon directory
    export PLAYWRIGHT_BROWSERS_PATH="$SCRIPT_DIR/browsers"
    mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
    
    $PYTHON_CMD -m playwright install chromium
    if [[ $? -ne 0 ]]; then
        echo
        echo "ERROR: Failed to install Chromium."
        echo
        echo "Possible causes:"
        echo "1. No internet connection"
        echo "2. Firewall blocking the download"
        echo
        echo "Solutions:"
        echo "1. Check your internet connection"
        echo "2. Temporarily disable firewall/antivirus"
        echo "3. Use system Chrome instead (run script again, choose option 1)"
        echo
        exit 1
    fi
    echo "Chromium installed successfully to: $PLAYWRIGHT_BROWSERS_PATH"
fi

echo
echo "=============================================="
echo "IMPORTANT: Authentication Instructions"
echo "=============================================="
echo
echo "1. A browser window will open from Playwright (incognito/private mode)."
echo "2. Log in to Google in THAT browser window (fresh session, no saved accounts)."
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
    echo "3. You may have logged into the wrong browser window"
    echo
    echo "Try running auth_helper.sh again."
    echo "=============================================="
    exit 1
fi
