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

# Cross-platform auth path handling - check multiple paths in priority order
def _get_auth_paths():
    """Get list of possible storage_state.json paths in priority order."""
    paths = []

    if os.environ.get("FLATPAK_ID"):
        # Flatpak: check multiple locations
        paths.append(Path("/var/data/.notebooklm/storage_state.json"))
        paths.append(Path.home() / ".notebooklm" / "storage_state.json")
    else:
        # Standard: check NOTEBOOKLM_HOME, then default
        if os.environ.get("NOTEBOOKLM_HOME"):
            paths.append(Path(os.environ["NOTEBOOKLM_HOME"]) / "storage_state.json")
        paths.append(Path.home() / ".notebooklm" / "storage_state.json")

    # Also check addon's own directory (for portable installs)
    addon_dir = Path(__file__).parent
    paths.append(addon_dir / "storage_state.json")

    # Return only paths that exist
    return [p for p in paths if p.exists()]


# Use the first valid path
_auth_paths = _get_auth_paths()
if _auth_paths:
    _NotebookLM_AUTH_PATH = str(_auth_paths[0])
    # Set NOTEBOOKLM_HOME based on found path
    os.environ.setdefault("NOTEBOOKLM_HOME", str(_auth_paths[0].parent))
else:
    # No credentials found - use default path for error messages
    if os.environ.get("FLATPAK_ID"):
        _NOTEBOOKLM_AUTH_PATH = "/var/data/.notebooklm/storage_state.json"
    else:
        _NOTEBOOKLM_AUTH_PATH = str(Path.home() / ".notebooklm" / "storage_state.json")
    os.environ.setdefault("NOTEBOOKLM_HOME", str(Path(_NotebookLM_AUTH_PATH).parent))

_notebooklm_import_error = None
try:
    from notebooklm import NotebookLMClient
except Exception as e:
    NotebookLMClient = None
    _notebooklm_import_error = f"{type(e).__name__}: {e}\n{traceback.format_exc()}"

# Module-level state to persist notebook_id between function calls
_active_notebook_id: str | None = None


def _run_async(coro):
    """Run an async coroutine in a new event loop (safe for worker threads)."""
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop.run_until_complete(coro)


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
        f"Raw response (first 500 chars):\n{text[:500]}"
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

    # Check if credentials exist
    import os
    if not os.path.exists(_NotebookLM_AUTH_PATH):
        raise RuntimeError(
            "NotebookLM authentication required!\n\n"
            "Credentials not found. Please run the authentication helper:\n"
            f"- Windows: Run auth_helper.bat as administrator\n"
            f"- Linux/macOS: Run ./auth_helper.sh\n\n"
            f"Looking for: {_NotebookLM_AUTH_PATH}\n"
            f"Make sure to log in using the Playwright browser window (not your default browser)."
        )

    def _do_upload():
        async def _upload():
            try:
                async with await NotebookLMClient.from_storage(path=_NotebookLM_AUTH_PATH) as client:
                    nb = await client.notebooks.create(topic)
                    await client.sources.add_file(nb.id, Path(pdf_path), wait=True)
                    return nb.id
            except Exception as e:
                if "auth" in str(e).lower() or "login" in str(e).lower() or "cookie" in str(e).lower():
                    raise RuntimeError(
                        "NotebookLM authentication failed!\n\n"
                        "Your credentials may be expired. Please re-run:\n"
                        "- Windows: auth_helper.bat\n"
                        "- Linux/macOS: ./auth_helper.sh\n\n"
                        f"Error: {e}"
                    ) from e
                raise

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

    # Check if credentials exist
    import os
    if not os.path.exists(_NotebookLM_AUTH_PATH):
        raise RuntimeError(
            "NotebookLM authentication required!\n\n"
            "Credentials not found. Please run the authentication helper:\n"
            f"- Windows: Run auth_helper.bat as administrator\n"
            f"- Linux/macOS: Run ./auth_helper.sh\n\n"
            f"Looking for: {_NotebookLM_AUTH_PATH}"
        )

    notebook_id = _active_notebook_id

    def _do_generate():
        async def _generate():
            try:
                async with await NotebookLMClient.from_storage(path=_NotebookLM_AUTH_PATH) as client:
                    result = await client.chat.ask(notebook_id, prompt)
                    return result.answer
            except Exception as e:
                if "auth" in str(e).lower() or "login" in str(e).lower() or "cookie" in str(e).lower():
                    raise RuntimeError(
                        "NotebookLM authentication failed!\n\n"
                        "Your credentials may be expired. Please re-run:\n"
                        "- Windows: auth_helper.bat\n"
                        "- Linux/macOS: ./auth_helper.sh\n\n"
                        f"Error: {e}"
                    ) from e
                raise

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
            async with await NotebookLMClient.from_storage(path=_NotebookLM_AUTH_PATH) as client:
                await client.notebooks.delete(notebook_id)

        _run_async(_delete())

    try:
        _do_delete()
    except Exception:
        pass
    finally:
        _active_notebook_id = None
