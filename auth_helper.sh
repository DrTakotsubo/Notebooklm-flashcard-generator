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

# Determine persistent directories (outside the addon folder so they survive updates)
NOTEBOOKLM_DIR="$HOME/.notebooklm"
if [ -d "$HOME/.var/app/net.ankiweb.Anki/data" ]; then
    NOTEBOOKLM_DIR="$HOME/.var/app/net.ankiweb.Anki/data/.notebooklm"
fi
LIBS_DIR="$NOTEBOOKLM_DIR/libs"
BROWSERS_DIR="$NOTEBOOKLM_DIR/browsers"

mkdir -p "$LIBS_DIR"
mkdir -p "$BROWSERS_DIR"

# Set PYTHONPATH to use persistent libs
export PYTHONPATH="$LIBS_DIR"
echo "PYTHONPATH set to: $PYTHONPATH"
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

# Check if playwright is already installed in persistent libs
PLAYWRIGHT_INSTALLED=false
if $PYTHON_CMD -c "import sys; sys.path.insert(0, '$LIBS_DIR'); import playwright" &> /dev/null; then
    echo "Playwright already installed in persistent libs."
    PLAYWRIGHT_INSTALLED=true
    
    # Verify it actually works
    if ! $PYTHON_CMD -c "import sys; sys.path.insert(0, '$LIBS_DIR'); import playwright; import pyee; import greenlet" &> /dev/null; then
        echo "Persistent Playwright verification failed. Reinstalling..."
        PLAYWRIGHT_INSTALLED=false
    else
        echo "Persistent Playwright verified."
    fi
fi

if [ "$PLAYWRIGHT_INSTALLED" = false ]; then
    echo "Playwright not found. Installing now..."
    echo "This may take a few minutes..."
    echo

    # Clear pip cache first (fixes deserialization errors)
    $PYTHON_CMD -m pip cache purge &> /dev/null || true

    # Install notebooklm-py, pypdf and all dependencies
    $PYTHON_CMD -m pip install --upgrade --target="$LIBS_DIR" "notebooklm-py[browser]" pypdf

    if [[ $? -ne 0 ]]; then
        echo
        echo "ERROR: Failed to install Playwright and dependencies."
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

    echo
    echo "Verifying installation..."
    if ! $PYTHON_CMD -c "import sys; sys.path.insert(0, '$LIBS_DIR'); import playwright; import pyee; import greenlet" &> /dev/null; then
        echo
        echo "ERROR: Installation verification failed."
        echo "Playwright was installed but cannot be imported."
        echo
        echo "Debug information:"
        echo "PYTHONPATH: $PYTHONPATH"
        echo
        echo "Please try:"
        echo "1. Close and reopen your terminal"
        echo "2. Run as a regular user (not sudo)"
        echo "3. Manually run: $PYTHON_CMD -c 'import playwright'"
        echo
        exit 1
    fi

    echo "Playwright and dependencies installed successfully."
    echo
fi

# Browser selection menu
echo
echo "=============================================="
echo "Browser Selection"
echo "=============================================="
echo
echo "The authentication requires a browser. Choose one:"
echo
echo "1. Use system browser (Chrome/Brave/Edge/Firefox etc. - RECOMMENDED)"
echo "   - Detects and uses your installed browser"
echo "   - Faster, no extra downloads"
echo
echo "2. Use Playwright Chromium (requires download ~300MB)"
echo "   - Downloads Chromium browser automatically"
echo "   - May fail due to network/firewall issues"
echo
read -p "Enter 1 or 2 (default: 1): " BROWSER_CHOICE
BROWSER_CHOICE=${BROWSER_CHOICE:-1}

if [[ "$BROWSER_CHOICE" == "1" ]]; then
    # Try to find common system browsers (Chrome, Brave, Edge, Chromium, Vivaldi, Opera, Firefox)
    CHROME_PATH=""
    for browser in google-chrome google-chrome-stable brave-browser brave microsoft-edge microsoft-edge-stable chromium chromium-browser vivaldi vivaldi-stable opera firefox "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" "/Applications/Vivaldi.app/Contents/MacOS/Vivaldi" "/Applications/Firefox.app/Contents/MacOS/firefox"; do
        if command -v "$browser" &> /dev/null; then
            CHROME_PATH="$(command -v "$browser")"
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
            
            # Save browser config
            echo "NOTEBOOKLM_BROWSER_PATH=$NOTEBOOKLM_BROWSER_PATH" > "$NOTEBOOKLM_DIR/browser_config.ini"
            echo "Browser configuration saved to: $NOTEBOOKLM_DIR/browser_config.ini"
        else
            echo
            echo "ERROR: Browser path is not executable: $CHROME_PATH"
            echo "Falling back to Playwright Chromium..."
            BROWSER_CHOICE="2"
        fi
    else
        echo
        echo "System browser not found in PATH."
        read -p "Enter full path to your browser (or press ENTER to use Chromium): " MANUAL_PATH
        if [[ -n "$MANUAL_PATH" && -x "$MANUAL_PATH" ]]; then
            export NOTEBOOKLM_BROWSER_PATH="$MANUAL_PATH"
            echo
            echo "Using: $NOTEBOOKLM_BROWSER_PATH"
            # Save browser config
            echo "NOTEBOOKLM_BROWSER_PATH=$NOTEBOOKLM_BROWSER_PATH" > "$NOTEBOOKLM_DIR/browser_config.ini"
            echo "Browser configuration saved to: $NOTEBOOKLM_DIR/browser_config.ini"
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

    # Set PLAYWRIGHT_BROWSERS_PATH to persistent folder
    export PLAYWRIGHT_BROWSERS_PATH="$BROWSERS_DIR"
    mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"

    $PYTHON_CMD -c "import sys; sys.path.insert(0, '$LIBS_DIR'); import playwright" -m playwright install chromium
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
        echo "3. Use system browser instead (run script again, choose option 1)"
        echo
        exit 1
    fi
    echo "Chromium installed successfully to: $PLAYWRIGHT_BROWSERS_PATH"
    
    # Save browser config
    echo "PLAYWRIGHT_BROWSERS_PATH=$PLAYWRIGHT_BROWSERS_PATH" > "$NOTEBOOKLM_DIR/browser_config.ini"
    echo "Browser configuration saved to: $NOTEBOOKLM_DIR/browser_config.ini"
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

# Set environment for notebooklm login
export PYTHONPATH="$LIBS_DIR"
export NOTEBOOKLM_HOME="$NOTEBOOKLM_DIR"

# Load browser config if exists
if [[ -f "$NOTEBOOKLM_DIR/browser_config.ini" ]]; then
    source "$NOTEBOOKLM_DIR/browser_config.ini"
    echo "Loaded browser configuration from: $NOTEBOOKLM_DIR/browser_config.ini"
fi

# Set browser path if using chromium
if [[ -d "$BROWSERS_DIR" ]]; then
    export PLAYWRIGHT_BROWSERS_PATH="$BROWSERS_DIR"
fi

echo "NOTEBOOKLM_HOME=$NOTEBOOKLM_HOME"
echo

# Run custom login script
echo
echo "Running custom login script..."
echo "================================================"
echo "CUSTOM LOGIN START"
echo "================================================"
python3 "$SCRIPT_DIR/custom_login.py"
echo "================================================"
echo "CUSTOM LOGIN END"
echo "================================================"
echo

# Verify credentials
STORAGE_PATH="$NOTEBOOKLM_DIR/storage_state.json"
if [[ -f "$STORAGE_PATH" ]]; then
    echo
    echo "=============================================="
    echo "SUCCESS: Credentials saved!"
    echo "Location: $STORAGE_PATH"
    echo
    echo "You can now use the addon in Anki."
    echo "=============================================="
else
    echo
    echo "=============================================="
    echo "ERROR: Credentials not found."
    echo
    echo "Possible issues:"
    echo "1. You didn't complete the login in the Playwright browser"
    echo "2. Playwright browser failed to open"
    echo
    echo "Try running auth_helper.sh again."
    echo "=============================================="
    exit 1
fi