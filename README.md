# NotebookLM Flashcard Generator for Anki

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Anki Version](https://img.shields.io/badge/Anki-2.1.50+-green.svg)](https://apps.ankiweb.net/)

An Anki addon that generates flashcards from PDF documents using Google's NotebookLM AI. Perfect for students, researchers, and medical professionals who want to convert study materials into spaced repetition flashcards automatically.

## What This Addon Does

This addon bridges Anki with Google NotebookLM to automate flashcard creation:

1. **Upload PDF** → Addon uploads your PDF to a new NotebookLM notebook
2. **AI Processing** → NotebookLM analyzes the content using your chosen prompt template
3. **Generate Flashcards** → AI creates comprehensive flashcards following Medical education principles (Macro/Micro approach)
4. **Import to Anki** → Flashcards are automatically imported into your selected Anki deck
5. **Cleanup** → NotebookLM notebook is deleted after import (your PDF isn't stored)

### Key Benefits

- ✅ **Saves hours** of manual flashcard creation
- ✅ **Unlimited flashcards** - no upper limit on generation
- ✅ **Multiple prompt templates** for different learning needs
- ✅ **Custom prompts** - add, edit, and delete your own prompts through GUI
- ✅ **Cross-platform** - works on Linux, Windows, and macOS
- ✅ **Privacy-focused** - uses your own Google account, no third-party data collection
- ✅ **Bundled dependencies** - no manual pip install required
- ✅ **Easy authentication** - one-click helper scripts for all platforms

---

## Table of Contents

- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [How to Use](#how-to-use)
- [Managing Prompts](#managing-prompts)
- [Prompt Templates](#prompt-templates)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Privacy & Security](#privacy--security)
- [License](#license)

---

## Installation

### Method 1: One-Command Install (Easiest)

Run this single command in your terminal:

**Linux/macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/install.sh | bash
```

**Windows (Command Prompt):**
```cmd
curl -sSL https://raw.githubusercontent.com/DrTakotsubo/notebooklm-flashcard-generator/main/install.bat -o install.bat && install.bat
```

This will:
1. Detect your OS and Anki directory
2. Download/clone the addon automatically
3. Prompt you to restart Anki

---

### Method 2: Drag-and-Drop Install (Recommended)

1. Download `NotebookLM-Flashcard-Generator.ankiaddon` from the [Latest Release](https://github.com/DrTakotsubo/notebooklm-flashcard-generator/releases/latest)
2. Open Anki
3. Drag and drop the `.ankiaddon` file onto Anki's main window
4. Click **Yes** on the confirmation dialog
5. Restart Anki when prompted

---

### Method 3: Manual Install

1. Download and unzip the addon source code
2. Locate your Anki addons folder:
   - **Linux (Standard)**: `~/.local/share/Anki2/addons21/`
   - **Linux (Flatpak)**: `~/.var/app/net.ankiweb.Anki/data/Anki2/addons21/`
   - **Windows**: Press `Win+R` → type `%APPDATA%\Anki2\addons21\` → press Enter
   - **macOS**: Finder → `Cmd+Shift+G` → type `~/Library/Application Support/Anki2/addons21/`
3. Copy the `notebooklm-flashcard-generator` folder into the addons21 folder
4. Restart Anki

---

## First-Time Setup

### Step 1: Verify Prerequisites

- **Anki 2.1.50+** installed ([download here](https://apps.ankiweb.net/))
- **Google Account** with access to [NotebookLM](https://notebooklm.google.com/) (must be available in your region)

### Step 2: Authenticate with Google

The addon uses NotebookLM's API, which requires a one-time Google authentication.

#### **Easiest Method (All Platforms):**

1. Open Anki → **Tools** → **Addons**
2. Select "NotebookLM Flashcard Generator"
3. Click **View Files** button (opens addon folder in Explorer/Finder)
4. **Windows**: Double-click `auth_helper.bat`
5. **Linux/macOS**: Right-click `auth_helper.sh` → "Run" or run `./auth_helper.sh` in terminal

#### **Alternative: Manual Command Line**

**Linux/macOS:**
```bash
cd ~/.local/share/Anki2/addons21/notebooklm-flashcard-generator  # Adjust for Flatpak if needed
bash auth_helper.sh
```

**Windows:**
```cmd
cd %APPDATA%\Anki2\addons21\notebooklm-flashcard-generator
auth_helper.bat
```

#### Complete OAuth in Browser

1. A browser window will open automatically
2. Log in with your Google account (must have NotebookLM access)
3. Grant the requested permissions
4. Terminal will show "Authentication successful"
5. Your session is saved to `~/.notebooklm/` (Linux/macOS) or `C:\Users\You\.notebooklm\` (Windows)

> **Note:** Authentication expires after ~30 days. Re-run the auth helper when needed.

---

## How to Use

### Step-by-Step Guide

#### 1. Open the Addon

- Launch Anki
- Go to **Tools** → **Import from NotebookLM...**
- A dialog window will appear

#### 2. Enter a Topic

- Type a descriptive topic for your flashcards
- **Examples**: "Cardiology", "World War II", "Python Basics", "Pharmacology Chapter 5"
- This helps NotebookLM focus on relevant content

#### 3. Select a Prompt Template

- Choose from the dropdown menu or click **Manage Prompts** to customize
- **NEET-PG: Macro/Micro (All Subjects)** - Comprehensive medical flashcards
- **NEET-PG: DOC, M/C, IOC, Genes** - Fact-based medical flashcards
- **Medical Practical Exams (Verbatim)** - Exact textbook content extraction
- **Your custom prompts** - if you've added any via Prompt Manager

> **Tip:** Click **Manage Prompts** to add, edit, or delete prompt templates through a GUI.

#### 4. Select Your PDF File

- Click **Browse...**
- Navigate to your PDF file
- Select a PDF (must not be password-protected)
- Path will appear in the "PDF File" field

#### 5. Choose Target Deck

- Select an existing Anki deck from the dropdown
- Or type a new deck name (it will be created automatically)

#### 6. Generate Flashcards

- Click **Generate Flashcards**
- Progress updates will appear:
  1. "Uploading PDF to NotebookLM..."
  2. "Generating flashcards..."
  3. "Cleaning up NotebookLM notebook..."
- **Wait time**: 1-5 minutes depending on PDF size and complexity

#### 7. Review Imported Cards

- A success message will show the number of flashcards added
- Open your Anki deck to review the new cards
- Cards are created as "Basic" note type with "Front" and "Back" fields

---

## Managing Prompts

### Opening Prompt Manager

1. Open the addon dialog (**Tools** → **Import from NotebookLM...**)
2. Click **Manage Prompts** (next to the Prompt dropdown)
3. A new window will open showing all available prompts

### Adding a New Prompt

1. Click **Add New**
2. Enter a **Prompt Name** (e.g., "My Custom Prompt")
3. Enter the **Prompt Text** - must instruct NotebookLM to return JSON with "Front" and "Back" keys
4. Click **Save Prompt**

**Example prompt template:**
```
You are an expert tutor. Analyze the provided document and generate flashcards.
Return ONLY a valid JSON array of objects with "Front" and "Back" keys.
Generate as many relevant, high-quality flashcards as possible from the source material, with no upper limit.
```

### Editing Prompts

- **Default prompts** (NEET-PG, etc.) cannot be edited - they are read-only
- **Custom prompts** (added by you) can be edited freely

### Deleting Prompts

- **Default prompts** cannot be deleted
- **Custom prompts** can be deleted (click **Delete** button)

### Saving

All custom prompts are saved to `user_prompts.json` in the addon folder and persist across Anki restarts.

---

## Prompt Templates

### 1. NEET-PG: Macro/Micro (All Subjects)

**Best for**: Comprehensive medical topic review

**Generates two types of cards:**
- **[MACRO] Cards**: Complete concepts, protocols, tables (comprehensive recall)
- **[MICRO] Cards**: Single facts - drug of choice, most common causes, markers (rapid-fire recall)

**Example:**
- Front: `[MACRO] Complete management algorithm for Diabetic Ketoacidosis?`
- Back: `• Fluid resuscitation: 0.9% NS\n• IV regular insulin bolus + infusion\n• Potassium replacement as needed`

### 2. NEET-PG: DOC, M/C, IOC, Genes

**Best for**: High-yield fact memorization

**Extracts:**
- **[DOC]** - Drug of Choice
- **[m/c]** - Most Common causes
- **[IOC]** - Investigation of Choice
- **[Radiology]** - Imaging findings
- **[Histopathology]** - Biopsy findings
- **[Marker]** - Tumor/genetic markers

### 3. Medical Practical Exams (Verbatim)

**Best for**: Exam preparation using exact textbook language

**Extracts verbatim:**
- Definitions
- Clinical gradings and criteria
- Causes and etiologies
- Clinical features (symptoms & signs)
- Differential diagnoses
- Investigation protocols
- Management/treatment plans
- Complications
- Pathophysiology mechanisms

---

## Configuration

Edit the configuration variables at the top of `__init__.py` (lines 1-159):

### `NOTEBOOKLM_PROMPTS`

Add or modify prompt templates (note: use Prompt Manager GUI instead for easier management):

```python
NOTEBOOKLM_PROMPTS = {
    "Your Custom Prompt Name": """\
Your prompt text here...
Return ONLY a valid JSON array of objects with "Front" and "Back" keys.
Generate as many relevant, high-quality flashcards as possible from the source material, with no upper limit.
""",
}
```

### `FLASHARD_NOTE_TYPE`

Change the Anki note type (default: `"Basic"`):

```python
FLASHARD_NOTE_TYPE = "Basic"  # or "Cloze", "Basic (and reversed)", etc.
```

### `ADDON_MENU_TEXT`

Change the menu item text:

```python
ADDON_MENU_TEXT = "Import from NotebookLM..."
```

### `NOTEBOOKLM_NOTEBOOK_NAME`

Change the default notebook name prefix:

```python
NOTEBOOKLM_NOTEBOOK_NAME = "Anki Flashcard Notebook"
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **"notebooklm library not found"** | Reinstall addon → ensure `libs/` folder exists in addon directory |
| **"Authentication failed"** | Re-run auth helper: `auth_helper.bat` (Windows) or `./auth_helper.sh` (Linux/macOS)<br>Sessions expire ~30 days<br>Disable VPN/adblockers temporarily |
| **"Could not extract valid JSON"** | NotebookLM added conversational text<br>Try re-running the generation<br>Simplify the prompt if persistent |
| **PDF upload fails** | Use non-password-protected PDF<br>Check internet connection<br>Ensure PDF isn't corrupted |
| **Addon missing from Tools menu** | Fully restart Anki<br>Confirm addon folder is in correct `addons21` directory<br>Check Anki's addon manager for errors |
| **"No module named notebooklm"** | Verify `libs/notebooklm` directory exists<br>Reinstall addon if missing |
| **"python not found" on Windows** | 1. Try `py -m notebooklm login` instead<br>2. If still fails, install Python from python.org<br>3. Check "Add Python to PATH" during install |
| **"Folder not found" on Windows** | 1. Open Anki → Tools → Addons<br>2. Right-click "NotebookLM Flashcard Generator"<br>3. Click "View Files" to open folder<br>4. Use that path in Command Prompt |

### Debug Steps

1. Check Anki's addon manager for error messages
2. Verify authentication: `python -m notebooklm notebooks list`
3. Test with a small PDF first
4. Check internet connectivity

---

## Privacy & Security

### What the Addon Does

- ✅ **Only communicates with Google NotebookLM** using your authenticated session
- ✅ **No data collection** - no telemetry, tracking, or third-party servers
- ✅ **Local processing** - flashcards are imported directly into your local Anki collection
- ✅ **Temporary cloud storage** - PDFs are uploaded to your NotebookLM notebook, then deleted after import

### What the Addon Does NOT Do

- ❌ No unauthorized network requests
- ❌ No data exfiltration
- ❌ No hardcoded credentials or API keys
- ❌ No access to unrelated files

### Data Flow

```
Your PDF → NotebookLM API (your account) → Flashcard JSON → Your Anki Deck
```

All authentication uses your own Google account session stored locally at `~/.notebooklm/storage_state.json`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright (c) 2026 Takotsubo**

---

## Contributing

Contributions are welcome! Feel free to:
- Report bugs via [GitHub Issues](https://github.com/DrTakotsubo/notebooklm-flashcard-generator/issues)
- Suggest features
- Submit pull requests

---

## Support

- **Anki Forum**: [Community Support](https://forums.ankiweb.net/)
- **GitHub Issues**: [Report Bugs](https://github.com/DrTakotsubo/notebooklm-flashcard-generator/issues)
- **NotebookLM Help**: [Google Support](https://support.google.com/notebooklm/)

---

## Acknowledgments

- [notebooklm-py](https://github.com/teng-lin/notebooklm-py) - The Python client for NotebookLM API
- [Anki](https://apps.ankiweb.net/) - The best spaced repetition software
- Google NotebookLM team for the AI API

---

**Made with ❤️ for the Anki community**
