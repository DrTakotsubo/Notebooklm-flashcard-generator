"""Debug NotebookLM authentication."""
import sys
import os

# Add libs to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'libs'))

from notebooklm import NotebookLMClient
import asyncio

async def check_auth():
    try:
        async with await NotebookLMClient.from_storage() as client:
            notebooks = await client.notebooks.list()
            print(f"✅ Authentication working! Found {len(notebooks)} notebooks.")
            return True
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.get_event_loop().run_until_complete(check_auth())
    sys.exit(0 if success else 1)
