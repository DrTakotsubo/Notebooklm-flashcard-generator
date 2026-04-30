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

_NotebookLM_AUTH_PATH = str(_NOTEBOOKLM_DIR / "storage_state.json")
os.environ.setdefault("NOTEBOOKLM_HOME", str(_NOTEBOOKLM_DIR))

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
        RuntimeError: If notebooklm library is not installed.
    """
    global _active_notebook_id

    if NotebookLMClient is None:
        detail = _notebooklm_import_error or "Unknown import error"
        raise RuntimeError(
            "The 'notebooklm-py' library failed to import.\n\n"
            f"Details:\n{detail}"
        )

    def _do_upload():
        async def _upload():
            async with await NotebookLMClient.from_storage(path=_NotebookLM_AUTH_PATH) as client:
                nb = await client.notebooks.create(topic)
                await client.sources.add_file(nb.id, Path(pdf_path), wait=True)
                return nb.id

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

    notebook_id = _active_notebook_id

    def _do_generate():
        async def _generate():
            async with await NotebookLMClient.from_storage(path=_NotebookLM_AUTH_PATH) as client:
                result = await client.chat.ask(notebook_id, prompt)
                return result.answer

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
