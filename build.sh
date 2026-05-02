#!/bin/bash
# =============================================================================
# build.sh - Build script for NotebookLM Flashcard Generator addon
# =============================================================================
# This script:
# 1. Installs Python dependencies to libs/ (including playwright)
# 2. Optionally downloads Playwright browsers to browsers/ folder
# 3. Creates the .ankiaddon package
# 4. Cleans up unnecessary files
# =============================================================================

set -e

echo "=============================================="
echo "NotebookLM Flashcard Generator - Build Script"
echo "=============================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Install Python dependencies to libs/
echo "Step 1: Installing Python dependencies to libs/..."
echo

# Create libs directory if it doesn't exist
mkdir -p libs

# Install required packages
pip install notebooklm-py --target=libs/ --no-deps --quiet 2>/dev/null || true
pip install playwright --target=libs/ --no-deps --quiet 2>/dev/null || true

# Install all dependencies with deps
pip install notebooklm-py playwright --target=libs/ --quiet

echo "Dependencies installed."
echo

# Step 2: Ask if user wants to bundle Chromium browser
echo "Step 2: Bundle Playwright Chromium browser?"
echo
echo "This will download Chromium (~300MB) to browsers/ folder."
echo "If you say 'no', users will need to run 'playwright install chromium' themselves."
echo
read -p "Bundle Chromium? (y/n, default: n): " BUNDLE_CHROMIUM
BUNDLE_CHROMIUM=${BUNDLE_CHROMIUM:-n}

if [[ "$BUNDLE_CHROMIUM" =~ ^[Yy]$ ]]; then
    echo
    echo "Downloading Chromium browser..."
    export PLAYWRIGHT_BROWSERS_PATH="$SCRIPT_DIR/browsers"
    mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
    python3 -m playwright install chromium
    echo "Chromium downloaded to: $PLAYWRIGHT_BROWSERS_PATH"
else
    echo "Skipping Chromium download."
fi

echo

# Step 3: Clean up unnecessary files
echo "Step 3: Cleaning up unnecessary files..."
find libs/ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find libs/ -type f -name "*.pyc" -delete 2>/dev/null || true
find libs/ -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup done."
echo

# Step 4: Create .ankiaddon package
echo "Step 4: Creating .ankiaddon package..."
OUTPUT_FILE="$SCRIPT_DIR/../NotebookLM-Flashcard-Generator.ankiaddon"

cd "$SCRIPT_DIR"
python3 -c "
import zipfile, os

addon_dir = '.'
output_file = '$OUTPUT_FILE'

with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(addon_dir):
        # Skip certain directories and files
        dirs[:] = [d for d in dirs if d not in ('.git', '__pycache__', 'browsers')]
        for file in files:
            if file.endswith('.pyc') or file == '.ankiaddon':
                continue
            if file.startswith('build') or file == 'README.md':
                continue
            filepath = os.path.join(root, file)
            arcname = os.path.relpath(filepath, addon_dir)
            zipf.write(filepath, arcname)
print(f'Created {output_file}')
"

echo
echo "=============================================="
echo "Build complete!"
echo "=============================================="
echo
echo "Output: $OUTPUT_FILE"
echo
echo "Next steps:"
echo "1. Test the addon by installing it in Anki"
echo "2. Upload to GitHub Releases"
echo "3. Update the release notes"
echo
