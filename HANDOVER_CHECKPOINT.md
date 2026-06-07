# Handover & Checkpoint: NotebookLM Flashcard Generator

This document serves as a complete context checkpoint for the AI coding assistant to resume work on this Anki Addon. It summarizes the architecture, recent fixes, file map, installation setup, and next steps for the new development environment.

---

## 1. Project Overview & Architecture
* **Addon Name**: NotebookLM Flashcard Generator (Anki Addon)
* **Purpose**: Generates high-yield Anki flashcards from user-provided PDF files using Google NotebookLM.
* **Core Libraries**:
  * `notebooklm-py` (v0.7.0+) for interacting with Google NotebookLM.
  * `playwright` (with Chromium or Firefox) for capturing Google login cookies.
  * `pypdf` (v6.0.0+) for local PDF image extraction.
* **Addon Directory**:
  * Local Git Repository: `/mnt/Beta/App`
  * Active Anki Addon Folder: `~/.local/share/Anki2/addons21/notebooklm-flashcard-generator/`
  * *Note: If using Flatpak Anki, it resides in `~/.var/app/net.ankiweb.Anki/data/Anki2/addons21/notebooklm-flashcard-generator/`*

---

## 2. Key Architecture Fixes (SURVIVES OS/ADDON UPDATES)
We redesigned the library and credential paths to use a global persistent directory: **`~/.notebooklm/`** (or Flatpak equivalent).
This ensures that when a new version of the addon is installed (which deletes the local addon folder), **users do not lose their login sessions, downloaded libraries, or the 300MB Chromium browser binary**.

* **Persistent Credentials**: `~/.notebooklm/storage_state.json`
* **Persistent Python Libs**: `~/.notebooklm/libs/` (contains `playwright`, `pypdf`, `httpx`, etc.)
* **Persistent Browsers**: `~/.notebooklm/browsers/` (contains Playwright Chromium binary)
* **Persistent Settings**: `~/.notebooklm/browser_config.ini`

---

## 3. Recently Implemented Fixes & Features

### A. Linux Terminal Launching (Environment Cleanup)
Anki runs in its own Qt/Python virtual environment. Spawning system terminal emulators directly from Anki caused instant crashes due to library version conflicts (e.g. `gnome-terminal`, `konsole`, or `foot` trying to load Anki's custom Python/Qt libraries).
* **Fix**: Cleaned the environment variables (removing all `PYTHON*`, `QT_*`, and `LD_LIBRARY_PATH` keys) before launching the subprocess on Linux.
* **Terminals Supported**: Added robust detection and custom flag matching for: `x-terminal-emulator`, `xdg-terminal-exec`, `sensible-terminal`, `foot`, `kitty`, `alacritty`, `gnome-terminal`, `konsole`.

### B. Brave and Multi-Browser Support
* **Browser Auto-Detection**: Expanded the auto-detection in `auth_helper.sh` and `custom_login.py` to support **Brave**, **Firefox**, **Edge**, **Vivaldi**, **Opera**, **Chrome**, and **Chromium**.
* **Dual Playwright Engines**: If **Firefox** is detected, it automatically launches with Playwright's Firefox engine in private mode (`-private`). For Chromium-based browsers (Chrome, Brave, Edge, etc.), it launches with Playwright's Chromium engine.

### C. PDF Image Extraction & Embedding
* **Feature**: Added local PDF image extraction using `pypdf`.
* **Prompt Integration**: Added a default prompt template: **"Image/Diagram Flashcards"**. This prompt requests that NotebookLM identify figures/illustrations and return a `"Page"` key in the JSON output representing the 1-based page number.
* **Anki Note Ingestion**: When the addon reads a card with a `"Page"` key, it checks the extracted images for that page, imports them into Anki's media collection (`col.media.add_file`), and prepends `<img src="...">` tags to the Front field of the card.

### D. Prompt Manager GUI Fixes
* **Selectable Default Prompts**: Fixed a bug where default templates in the list were disabled (`ItemIsEnabled` cleared), which froze the UI and prevented users from clicking them. They are now fully selectable (so users can copy their text) while keeping the "Delete" button disabled for them.
* **Dropdown Auto-Refresh**: Fixed a bug where the main window dropdown did not update unless the manager returned `Accepted`. The manager now uses a "Close" button (returning `Accepted`), and the main window updates unconditionally upon dialog close.

---

## 4. Repository File Map
* [__init__.py](file:///mnt/Beta/App/__init__.py): Dialog window GUI (`NotebookLMDialog`), worker thread (`NotebookLMWorker`), terminal launching, and Anki card database operations.
* [notebooklm.py](file:///mnt/Beta/App/notebooklm.py): Interface to `notebooklm-py` client and background local image extraction.
* [custom_login.py](file:///mnt/Beta/App/custom_login.py): Custom Playwright script called by helper scripts to launch the browser and capture cookies.
* [prompt_manager.py](file:///mnt/Beta/App/prompt_manager.py): Manage Prompts UI and json files.
* [auth_helper.sh](file:///mnt/Beta/App/auth_helper.sh) / [auth_helper.bat](file:///mnt/Beta/App/auth_helper.bat): Setup/Authentication scripts for Linux/macOS and Windows respectively.
* [update_local_anki.sh](file:///mnt/Beta/App/update_local_anki.sh) / [update_local_anki.bat](file:///mnt/Beta/App/update_local_anki.bat): Fast in-place developer update scripts.
* [build.sh](file:///mnt/Beta/App/build.sh) / [build.bat](file:///mnt/Beta/App/build.bat): Packages the addon into a `.ankiaddon` file.

---

## 5. Setting Up on the New Distro
Once you have booted into your new Linux distribution:

1. **Install Git & Python**:
   * Ubuntu/Debian: `sudo apt install git python3 python3-pip python3-venv`
   * Arch Linux: `sudo pacman -S git python python-pip`
   * Fedora: `sudo dnf install git python3 python3-pip`

2. **Locate or Re-Clone Repository**:
   Navigate to your project directory (e.g. `cd /mnt/Beta/App`).

3. **Install dependencies locally (Developer Setup)**:
   Ensure `pypdf` and `notebooklm-py` dependencies are available:
   ```bash
   pip install pypdf notebooklm-py --target=libs/ --upgrade
   ```

4. **Verify your browser is installed**:
   Ensure **Brave** (or Chrome/Firefox) is installed on your new OS.

5. **Deploy the files to Anki in-place**:
   Run the local update script to copy the repo files straight to your active Anki directory:
   ```bash
   ./update_local_anki.sh
   ```

6. **Authentication Recovery**:
   * If your `/home` partition was preserved, your login state is already intact in `~/.notebooklm/storage_state.json`.
   * If it is a fresh `/home` install, run Anki, open the addon dialog, click **Re-authenticate**, choose option `1` in the terminal, and complete the Brave login.

---

## 6. Next Steps & Roadmap
If you want to continue extending the addon, here are the proposed next features:
1. **Support other file types for Image extraction**: E.g. allowing Slide decks or raw images to be processed.
2. **Selective image attachment**: Allowing the user to select which extracted images to attach to the cards rather than attaching all page images.
3. **Advanced Prompt Customization**: Adding field mapping configurations in the prompt manager dialog.
