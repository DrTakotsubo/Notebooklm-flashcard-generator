#!/usr/bin/env python3
"""
Custom login script for NotebookLM - uses Playwright directly.
This bypasses notebooklm's internal browser launch issues.

Uses system Chrome (auto-detected) - NO Chromium download required.
"""

import sys
import os

os.environ['PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD'] = '1'

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIBS_DIR = os.path.join(SCRIPT_DIR, 'libs')
sys.path.insert(0, LIBS_DIR)


def find_chrome_path():
    """Auto-detect Chrome installation path on Windows."""
    import subprocess
    
    possible_paths = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"),
    ]
    
    env_path = os.environ.get('NOTEBOOKLM_BROWSER_PATH', '').strip()
    if env_path and os.path.exists(env_path):
        return env_path
    
    for path in possible_paths:
        if os.path.exists(path):
            return path
    
    try:
        result = subprocess.run(['where', 'chrome'], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            chrome_path = result.stdout.strip().split('\n')[0]
            if os.path.exists(chrome_path):
                return chrome_path
    except:
        pass
    
    return None


def check_cookies(context):
    """Check which cookies were captured and warn if SID is missing."""
    cookies = context.cookies()
    
    cookie_names = [c['name'] for c in cookies]
    google_domains = [c['domain'] for c in cookies if '.google.com' in c['domain']]
    
    print()
    print("Cookies captured:")
    for c in cookies:
        print(f"  - {c['name']}: {c['domain']}")
    
    has_sid = 'SID' in cookie_names
    
    if not has_sid:
        print()
        print("WARNING: SID cookie not found!")
        print("This may cause authentication issues.")
        print("Try logging in again and waiting longer on the NotebookLM page.")
    else:
        print()
        print("SUCCESS: SID cookie found - full authentication captured!")
    
    return cookie_names, google_domains


def main():
    from playwright.sync_api import sync_playwright
    
    browser_path = os.environ.get('NOTEBOOKLM_BROWSER_PATH', '').strip()
    storage_path = os.environ.get('NOTEBOOKLM_HOME', os.path.join(os.environ.get('USERPROFILE', ''), '.notebooklm'))
    storage_file = os.path.join(storage_path, 'storage_state.json')
    
    os.makedirs(storage_path, exist_ok=True)
    
    print("=" * 50)
    print("NotebookLM Custom Login")
    print("=" * 50)
    print()
    print(f"Storage path: {storage_file}")
    print()
    
    chrome_path = find_chrome_path()
    if chrome_path:
        print(f"Found Chrome: {chrome_path}")
    else:
        print("Chrome not found!")
    
    print()
    
    with sync_playwright() as p:
        launch_args = {
            "headless": False,
            "args": [
                "--disable-blink-features=AutomationControlled",
                "--password-store=basic",
                "--incognito",
            ],
            "ignore_default_args": ["--enable-automation"],
        }
        
        print("Launching browser...")
        browser = None
        
        if chrome_path:
            try:
                browser = p.chromium.launch(executable_path=chrome_path, **launch_args)
                print("SUCCESS: Browser launched using detected Chrome path")
            except Exception as e:
                print(f"ERROR with detected path: {e}")
        
        if browser is None and browser_path and os.path.exists(browser_path):
            try:
                browser = p.chromium.launch(executable_path=browser_path, **launch_args)
                print("SUCCESS: Browser launched using NOTEBOOKLM_BROWSER_PATH")
            except Exception as e:
                print(f"ERROR with env path: {e}")
        
        if browser is None:
            print()
            print("=" * 50)
            print("ERROR: Could not launch Chrome")
            print("=" * 50)
            print()
            print("Please ensure Chrome is installed.")
            if not chrome_path:
                print("Auto-detection failed. Set NOTEBOOKLM_BROWSER_PATH environment variable.")
            return 1
        
        context = browser.new_context(ignore_https_errors=True)
        
        print("Opening NotebookLM...")
        page = context.new_page()
        page.goto("https://notebooklm.google.com/")
        
        print()
        print("=" * 50)
        print("INSTRUCTIONS:")
        print("=" * 50)
        print("1. Log in to your Google account in the browser window")
        print("2. Wait until you see the NotebookLM homepage with your notebooks")
        print("3. Wait a few seconds for session to fully establish")
        print("4. Come back here and press ENTER to save authentication")
        print("=" * 50)
        print()
        input("Press ENTER when logged in...")
        
        print()
        print("Verifying cookies...")
        
        # Check cookies BEFORE saving to ensure we have SID
        cookie_names, google_domains = check_cookies(context)
        
        if 'SID' not in cookie_names:
            print()
            print("WARNING: Session may not be fully established!")
            print("Press ENTER again to refresh and retry, or Ctrl+C to abort.")
            input("Press ENTER to retry...")
            
            # Refresh the page to get fresh cookies
            page.goto("https://notebooklm.google.com/", wait_until="commit")
            page.wait_for_timeout(2000)  # Wait 2 seconds for cookies
            
            cookie_names, google_domains = check_cookies(context)
        
        # Save authentication state
        print()
        print("Saving authentication state...")
        context.storage_state(path=storage_file)
        
        context.close()
        browser.close()
        
        print()
        print("=" * 50)
        print("SUCCESS!")
        print("=" * 50)
        print(f"Authentication saved to: {storage_file}")
        print()
        
        if os.path.exists(storage_file):
            print(f"File size: {os.path.getsize(storage_file)} bytes")
            
            # Verify the saved file has correct cookies
            try:
                import json
                with open(storage_file, 'r') as f:
                    saved_data = json.load(f)
                if 'cookies' in saved_data:
                    saved_cookies = [c['name'] for c in saved_data['cookies']]
                    if 'SID' in saved_cookies:
                        print("VERIFIED: SID cookie present in saved file!")
                    else:
                        print("WARNING: SID cookie NOT in saved file!")
            except Exception as e:
                print(f"Note: Could not verify saved cookies: {e}")
        else:
            print("ERROR: File was not created!")
            return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())