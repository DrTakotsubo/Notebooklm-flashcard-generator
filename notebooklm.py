# =============================================================================
# notebooklm.py - NotebookLM integration using notebooklm-py library
# =============================================================================
# Requires: pip install notebooklm
# Setup:    notebooklm login   (one-time Google account authentication)
# =============================================================================

import sys
import os
from pathlib import Path

# Get addon directory and set up libs path relative to it
_ADDON_DIR = Path(__file__).parent
_USER_SITE_PACKAGES = str(_ADDON_DIR / "libs")

# Force add the path
if _USER_SITE_PACKAGES not in sys.path:
    sys.path.insert(0, _USER_SITE_PACKAGES)

import json
import re
import asyncio
import traceback

# Cross-platform auth path handling
if os.environ.get("FLATPAK_ID"):
    # Flatpak environment
    _NOTEBOOKLM_DIR = Path("/var/data/.notebooklm")
else:
    # Standard environment (Linux, Windows, Mac)
    _NOTEBOOKLM_DIR = Path.home() / ".notebooklm"

# ALWAYS define _NotebookLM_AUTH_PATH (fixes NameError)
_NotebookLM_AUTH_PATH = str(_NOTEBOOKLM_DIR / "storage_state.json")
os.environ.setdefault("NOTEBOOKLM_HOME", str(_NOTEBOOKLM_DIR))

# Also set NOTEBOOKLM_AUTH_JSON from storage file if it exists (for notebooklm-py)
_storage_file = Path(_NotebookLM_AUTH_PATH)
if _storage_file.exists():
    try:
        with open(_storage_file, 'r') as f:
            storage_data = json.load(f)
            os.environ["NOTEBOOKLM_AUTH_JSON"] = json.dumps(storage_data)
    except Exception:
        pass  # If we can't read it, continue without setting the env var

# Read browser config from addon directory (created by auth_helper)
_browser_config_path = _ADDON_DIR / "browser_config.ini"
if _browser_config_path.exists():
    try:
        with open(_browser_config_path, 'r') as f:
            for line in f:
                line = line.strip()
                if '=' in line:
                    key, value = line.split('=', 1)
                    if key == "NOTEBOOKLM_BROWSER_PATH":
                        os.environ["NOTEBOOKLM_BROWSER_PATH"] = value
                    elif key == "PLAYWRIGHT_BROWSERS_PATH":
                        os.environ["PLAYWRIGHT_BROWSERS_PATH"] = value
    except Exception:
        pass  # If we can't read it, continue without browser config


def _get_auth_paths():
    """Get list of possible storage_state.json paths for reading credentials."""
    paths = []

    # Add the primary path first (user's home directory)
    paths.append(Path(_NotebookLM_AUTH_PATH))

    # Windows-specific fallback paths
    import platform
    if platform.system() == "Windows":
        # Check APPDATA (common for portable apps on Windows)
        appdata = os.environ.get("APPDATA")
        if appdata:
            appdata_path = Path(appdata) / "notebooklm" / "storage_state.json"
            if appdata_path not in paths:
                paths.append(appdata_path)

        # Check LOCALAPPDATA
        localappdata = os.environ.get("LOCALAPPDATA")
        if localappdata:
            localappdata_path = Path(localappdata) / "notebooklm" / "storage_state.json"
            if localappdata_path not in paths:
                paths.append(localappdata_path)

    # Flatpak fallback
    if os.environ.get("FLATPAK_ID"):
        flatpak_home = Path.home() / ".notebooklm" / "storage_state.json"
        if flatpak_home != Path(_NotebookLM_AUTH_PATH):
            paths.append(flatpak_home)

    # Add addon directory path (portable installs)
    addon_dir = Path(__file__).parent
    paths.append(addon_dir / "storage_state.json")

    # Check if NOTEBOOKLM_HOME is set explicitly
    explicit_home = os.environ.get("NOTEBOOKLM_HOME")
    if explicit_home:
        explicit_path = Path(explicit_home) / "storage_state.json"
        if explicit_path not in paths:
            paths.append(explicit_path)

    # Return only paths that exist
    existing = [p for p in paths if p.exists()]
    
    return existing

_notebooklm_import_error = None
try:
    from notebooklm import NotebookLMClient
except Exception as e:
    NotebookLMClient = None
    _notebooklm_import_error = f"{type(e).__name__}: {e}\n{traceback.format_exc()}"

# Module-level state to persist notebook_id between function calls
_active_notebook_id: str | None = None

# Store event loops to prevent leaks
_event_loop: asyncio.AbstractEventLoop | None = None


def _run_async(coro):
    """Run an async coroutine in a new event loop (safe for worker threads)."""
    global _event_loop
    try:
        loop = asyncio.get_event_loop()
        if loop.is_closed():
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    _event_loop = loop
    return loop.run_until_complete(coro)


def _cleanup_event_loop():
    """Clean up the event loop when done (called at module shutdown)."""
    global _event_loop
    if _event_loop is not None and not _event_loop.is_closed():
        try:
            _event_loop.close()
        except Exception:
            pass
        _event_loop = None


def _extract_json(text: str) -> list[dict]:
    """Extract a JSON array from text, handling markdown code blocks and chatter."""
    # Try to find JSON within code blocks
    code_block = re.search(r"```(?:json)?\s*\n([\s\S]*?)\n```", text)
    if code_block:
        text = code_block.group(1)

    # Try to find a JSON array in the text
    match = re.search(r"\[\s*\{[\s\S]*\}\s*\]", text)
    if match:
        return json.loads(match.group(0))

    raise ValueError(
        "Could not extract valid JSON flashcards from NotebookLM response.\n\n"
        f"Raw response (first 1000 chars):\n{text[:1000]}"
    )


def upload_pdf(pdf_path: str, topic: str) -> str:
    """Upload a PDF file to NotebookLM and create a new notebook.

    Args:
        pdf_path: Absolute path to the PDF file on disk.
        topic:    The topic string (used as the notebook name).

    Returns:
        The notebook_id (string) that was created.

    Raises:
        RuntimeError: If notebooklm library is not installed or auth fails.
    """
    global _active_notebook_id

    if NotebookLMClient is None:
        detail = _notebooklm_import_error or "Unknown import error"
        raise RuntimeError(
            "The 'notebooklm-py' library failed to import.\n\n"
            f"Details:\n{detail}"
        )

    # Check if credentials exist (try multiple paths)
    auth_paths = _get_auth_paths()
    if not auth_paths:
        import platform
        paths_checked = [
            str(Path.home() / ".notebooklm" / "storage_state.json"),
        ]
        
        if platform.system() == "Windows":
            appdata = os.environ.get("APPDATA")
            if appdata:
                paths_checked.append(str(Path(appdata) / "notebooklm" / "storage_state.json"))
            localappdata = os.environ.get("LOCALAPPDATA")
            if localappdata:
                paths_checked.append(str(Path(localappdata) / "notebooklm" / "storage_state.json"))
        
        # Add addon directory and NOTEBOOKLM_HOME
        paths_checked.append(str(Path(__file__).parent / "storage_state.json"))
        
        explicit_home = os.environ.get("NOTEBOOKLM_HOME")
        if explicit_home:
            paths_checked.append(str(Path(explicit_home) / "storage_state.json"))
        
        paths_str = "\n  - ".join(paths_checked)
        
        raise RuntimeError(
            "NotebookLM authentication required!\n\n"
            "Credentials not found. Please run the authentication helper:\n"
            "- Windows: Double-click auth_helper.bat (do NOT run as administrator)\n"
            "- Linux/macOS: Run ./auth_helper.sh\n\n"
            f"Checked paths:\n  - {paths_str}\n\n"
            "Make sure to log in using the Playwright browser window (not your default browser)."
        )

    def _do_upload():
        async def _upload():
            # Try each valid auth path
            last_error = None
            for auth_path in auth_paths:
                try:
                    async with await NotebookLMClient.from_storage(path=str(auth_path)) as client:
                        nb = await client.notebooks.create(topic)
                        await client.sources.add_file(nb.id, Path(pdf_path), wait=True)
                        return nb.id
                except Exception as e:
                    last_error = e
                    if "auth" in str(e).lower() or "login" in str(e).lower() or "cookie" in str(e).lower():
                        continue  # Try next path
                    raise

            # All paths failed
            if last_error and ("auth" in str(last_error).lower() or "login" in str(last_error).lower() or "cookie" in str(last_error).lower()):
                raise RuntimeError(
                    "NotebookLM authentication failed!\n\n"
                    "Your credentials may be expired. Please re-run:\n"
                    "- Windows: auth_helper.bat (do NOT run as administrator)\n"
                    "- Linux/macOS: ./auth_helper.sh\n\n"
                    f"Error: {last_error}"
                ) from last_error
            if last_error:
                raise last_error
            raise RuntimeError("Authentication failed for unknown reason.")

        return _run_async(_upload())

    notebook_id = _do_upload()
    _active_notebook_id = notebook_id
    return notebook_id


def generate_flashcards(topic: str, prompt: str) -> list[dict]:
    """Send a prompt to NotebookLM and retrieve generated flashcards.

    Args:
        topic:  The topic the user entered.
        prompt: The full prompt template.

    Returns:
        A list of dicts, each with "Front" and "Back" string keys.

    Raises:
        RuntimeError: If notebooklm library is not installed or no notebook exists.
    """
    global _active_notebook_id

    if NotebookLMClient is None:
        detail = _notebooklm_import_error or "Unknown import error"
        raise RuntimeError(
            "The 'notebooklm-py' library failed to import.\n\n"
            f"Details:\n{detail}"
        )

    if not _active_notebook_id:
        raise RuntimeError("No active notebook. Call upload_pdf() first.")

    # Check if credentials exist (try multiple paths)
    auth_paths = _get_auth_paths()
    if not auth_paths:
        raise RuntimeError(
            "NotebookLM authentication required!\n\n"
            "Credentials not found. Please run the authentication helper:\n"
            f"- Windows: Double-click auth_helper.bat (do NOT run as administrator)\n"
            f"- Linux/macOS: Run ./auth_helper.sh\n\n"
            f"Looking for: {_NotebookLM_AUTH_PATH}"
        )

    notebook_id = _active_notebook_id

    def _do_generate():
        async def _generate():
            # Try each valid auth path
            last_error = None
            for auth_path in auth_paths:
                try:
                    async with await NotebookLMClient.from_storage(path=str(auth_path)) as client:
                        result = await client.chat.ask(notebook_id, prompt)
                        return result.answer
                except Exception as e:
                    last_error = e
                    if "auth" in str(e).lower() or "login" in str(e).lower() or "cookie" in str(e).lower():
                        continue  # Try next path
                    raise

            # All paths failed
            if last_error and ("auth" in str(last_error).lower() or "login" in str(last_error).lower() or "cookie" in str(last_error).lower()):
                raise RuntimeError(
                    "NotebookLM authentication failed!\n\n"
                    "Your credentials may be expired. Please re-run:\n"
                    "- Windows: auth_helper.bat (do NOT run as administrator)\n"
                    "- Linux/macOS: ./auth_helper.sh\n\n"
                    f"Error: {last_error}"
                ) from last_error
            if last_error:
                raise last_error
            raise RuntimeError("Authentication failed for unknown reason.")

        answer = _run_async(_generate())
        return _extract_json(answer)

    return _do_generate()


def delete_notebook() -> None:
    """Delete the NotebookLM notebook created during this session."""
    global _active_notebook_id

    if NotebookLMClient is None:
        return

    if not _active_notebook_id:
        return

    notebook_id = _active_notebook_id

    def _do_delete():
        async def _delete():
            # Try each valid auth path
            auth_paths = _get_auth_paths()
            for auth_path in (auth_paths if auth_paths else [Path(_NotebookLM_AUTH_PATH)]):
                try:
                    async with await NotebookLMClient.from_storage(path=str(auth_path)) as client:
                        await client.notebooks.delete(notebook_id)
                        return
                except Exception:
                    continue  # Try next path

        _run_async(_delete())

    try:
        _do_delete()
    except Exception:
        pass
    finally:
        _active_notebook_id = None