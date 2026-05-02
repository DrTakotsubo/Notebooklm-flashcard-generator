"""Debug NotebookLM authentication."""
import sys
import os

# Add libs to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'libs'))

_notebooklm_import_error = None
try:
    from notebooklm import NotebookLMClient
except Exception as e:
    NotebookLMClient = None
    _notebooklm_import_error = f"{type(e).__name__}: {e}"

import asyncio


async def check_auth():
    if NotebookLMClient is None:
        print(f"❌ Failed to import notebooklm library: {_notebooklm_import_error}")
        print("\nPossible solutions:")
        print("1. Make sure Python is installed and in your PATH")
        print("2. Run the auth_helper.sh/auth_helper.bat to install dependencies")
        print("3. Check that the libs/ folder exists in the addon directory")
        return False

    try:
        async with await NotebookLMClient.from_storage() as client:
            notebooks = await client.notebooks.list()
            print(f"✅ Authentication working! Found {len(notebooks)} notebooks.")
            return True
    except FileNotFoundError:
        print("❌ Authentication failed: storage_state.json not found.")
        print("\nPlease run the authentication helper:")
        print("  - Windows: Double-click auth_helper.bat")
        print("  - Linux/macOS: Run ./auth_helper.sh")
        return False
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        return False


if __name__ == "__main__":
    success = asyncio.get_event_loop().run_until_complete(check_auth())
    sys.exit(0 if success else 1)