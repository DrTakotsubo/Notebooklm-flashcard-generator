#!/bin/bash
echo "================================================"
echo "NotebookLM Flashcard Generator - Auth Helper"
echo "================================================"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Set PYTHONPATH
export PYTHONPATH="$SCRIPT_DIR/libs"

echo "Setting PYTHONPATH to: $PYTHONPATH"
echo ""

# Try python3 first, then python
if command -v python3 &> /dev/null; then
    echo "Running: python3 -m notebooklm login"
    python3 -m notebooklm login
elif command -v python &> /dev/null; then
    echo "Running: python -m notebooklm login"
    python -m notebooklm login
else
    echo "ERROR: Python not found!"
    echo "Please install Python from https://www.python.org/downloads/"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "Authentication successful!"
    echo "You can now use the addon in Anki."
    echo "================================================"
else
    echo ""
    echo "================================================"
    echo "Authentication failed. See errors above."
    echo "================================================"
fi
