# NotebookLM Flashcard Generator for Anki

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Anki Version](https://img.shields.io/badge/Anki-2.1.50+-green.svg)](https://apps.ankiweb.net/)

> **Quick Start:** Download → Install → Run `auth_helper.bat` → Generate flashcards!

This Anki addon generates flashcards from PDF documents using Google's NotebookLM AI. Perfect for students, researchers, and medical professionals.

---

## What This Addon Does

1. **Upload PDF** → Sends your PDF to NotebookLM
2. **AI Processing** → NotebookLM analyzes and generates flashcards
3. **Auto-Clean** → Removes citation numbers `[1]`, fixes bullet formatting
4. **Import to Anki** → Flashcards added to your selected deck

### Key Features
- ✅ Unlimited flashcard generation
- ✅ Multiple prompt templates for medical studies
- ✅ Custom prompts via GUI
- ✅ Works on Windows, Linux, macOS
- ✅ Uses your Google account (no API keys needed)
- ✅ Auto-formats flashcards (removes citations, fixes bullets)

---

## Installation

### Step 1: Install Python (Windows only)

> ⚠️ **Required for Windows!** Linux/macOS already have Python.

1. Download Python: https://www.python.org/downloads/
2. **CHECK "Add Python to PATH"** during installation
3. Verify: Open Command Prompt → type `python --version`

If you see "python not found", Python wasn't added to PATH. Reinstall with the checkbox enabled.

### Step 2: Install the Addon

**Option A: Drag & Drop (Easiest)**
1. Download `NotebookLM-Flashcard-Generator.ankiaddon` from releases
2. Open Anki → Drag the file onto Anki window
3. Click **Yes** to confirm → Restart Anki when prompted

**Option B: Anki's Built-in Installer**
1. Anki → Tools → Add-ons
2. Click "Get Add-ons..."
3. Paste the code from AnkiWeb (if published there)

### Step 3: Authenticate (One-Time)

> ⚠️ **Required before first use!**

**Windows:**
1. Anki → Tools → Add-ons
2. Select "NotebookLM Flashcard Generator"
3. Click **View Files**
4. Double-click `auth_helper.bat`

**Linux/macOS:**
1. Anki → Tools → Add-ons
2. Select "NotebookLM Flashcard Generator"
3. Click **View Files**
4. Run `./auth_helper.sh`

The script will:
- Install Playwright (first time only)
- Open your browser
- You log into Google
- Press Enter → Authentication saved!

---

## How to Use

### Step 1: Open the Addon
- Anki → **Tools** → **Import from NotebookLM...**

### Step 2: Enter Details
- **Topic**: What to focus on (e.g., "Cardiology", "Pharmacology")
- **Prompt**: Choose a template (default: "NEET-PG: Macro/Micro")
- **PDF**: Click Browse → Select your PDF file
- **Deck**: Choose target deck (or type new name)

### Step 3: Generate
- Click **Generate Flashcards**
- Wait 1-5 minutes (depends on PDF size)
- Flashcards appear in your Anki deck!

### Step 4: Review
- Open your Anki deck
- Cards have "Front" and "Back" fields
- Citations `[1]` automatically removed
- Bullets formatted properly on separate lines

---

## Prompt Templates

| Template | Best For |
|----------|----------|
| **NEET-PG: Macro/Micro** | Medical exams - comprehensive + single facts |
| **NEET-PG: DOC, M/C, IOC** | Drug of choice, most common, investigations |
| **Medical Practical** | Exact textbook content extraction |

### Custom Prompts
Click **Manage Prompts** to add your own templates.

---

## Troubleshooting

### "Authentication failed" or "Credentials not found"

**Cause:** Not logged in through the auth helper, or session expired.

**Fix:**
1. Run `auth_helper.bat` (Windows) or `./auth_helper.sh` (Linux/macOS)
2. A browser window opens → Log into Google
3. Wait for NotebookLM homepage to load
4. Press Enter in the terminal
5. Verify file exists: `%USERPROFILE%\.notebooklm\storage_state.json` (Windows)

### "SID cookie missing" Error

**Cause:** Authentication didn't capture full session.

**Fix:**
1. Delete existing auth file: `%USERPROFILE%\.notebooklm\storage_state.json`
2. Run `auth_helper.bat` again
3. After logging in, **wait 3-5 seconds** on NotebookLM page before pressing Enter

### "Python not found" on Windows

**Fix:**
1. Reinstall Python from python.org
2. **CHECK "Add Python to PATH"** during install
3. Restart Command Prompt and try again

### "Module not found" Error

**Fix:**
1. Anki → Tools → Add-ons
2. View Files for this addon
3. Verify `libs/` folder exists
4. If missing, reinstall the addon

### Cards have weird formatting

The addon automatically cleans:
- ❌ `[1]`, `[2]` citations → ✅ Removed
- ❌ `• Point1• Point2` continuous → ✅ `• Point1` on new lines
- ❌ Extra whitespace → ✅ Trimmed

---

## FAQ

**How long does authentication last?**
~30 days. Re-run auth helper when prompted.

**Is my data safe?**
Yes! Only communicates with Google NotebookLM using your account. No data collection.

**How many flashcards can I generate?**
Unlimited! No upper limit.

**Does it work on mobile?**
AnkiDroid/AnkiWeb don't support addons. Use desktop Anki.

**How to update the addon?**
Reinstall the new `.ankiaddon` file - your auth persists.

---

## Quick Reference

| Action | Command/Location |
|--------|------------------|
| Open addon | Tools → Import from NotebookLM... |
| Re-authenticate | auth_helper.bat / auth_helper.sh |
| Auth location | `%USERPROFILE%\.notebooklm\` (Windows) |
| View logs | Anki → Tools → Add-ons → View Files |

---

## Support

- **GitHub Issues**: https://github.com/DrTakotsubo/notebooklm-flashcard-generator/issues
- **Anki Forums**: https://forums.ankiweb.net/

---

**Made with ❤️ for the Anki community**