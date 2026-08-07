# LinkedIn Company Cleaner v1.1.3 Test Report

Test date: 2026-08-07

## Root cause fixed

v1.1.2 still used the old page-global guard `__LCC_CONTENT_V110__`. On an already-open LinkedIn tab, that stale marker could survive an extension update while the old message receiver was no longer usable. Reinjection then exited immediately, so the popup's **Scan** action had no content listener to answer it.

v1.1.3 replaces that with a versioned worker marker and stored listener reference. The popup now also performs a worker ping, reinjects the current worker if the ping fails, pings again, and only then sends Scan/Start/Stop.

## Release gate

All runtime tests were executed against a **clean extraction of the final ZIP**, not the working source directory.

### Packaging and manifest

- Root-level `manifest.json`: PASS
- Manifest V3: PASS
- Version 1.1.3: PASS
- No icon dependency: PASS
- All manifest-declared files present: PASS
- JavaScript syntax checks: PASS
- Chromium `--pack-extension` on the exact extracted directory: PASS

### Integrated Chromium DOM sandbox

The test harness used Chromium 144's real DOM/JavaScript engine with mocked Chrome extension APIs and separate popup/LinkedIn page contexts.

The LinkedIn context deliberately began with:

- stale `__LCC_CONTENT_V110__ = true`
- no valid message listener
- two realistic company rows
- one direct-unfollow control
- one dialog-confirmation control

Results:

- stale-tab worker reinjection: PASS
- exactly one current listener registered: PASS
- old guard removed: PASS
- initial company render: PASS
- Scan button sends `LCC_SCAN`: PASS
- visible Scan completion status: PASS
- Scan returns 2 company Pages: PASS
- healthy Scan avoids unnecessary reinjection: PASS
- Select All: PASS
- Start Selected: PASS
- direct unfollow path: PASS
- confirmation-dialog unfollow path: PASS
- completed: 2
- failed: 0
- Stop button enabled during active run: PASS
- `LCC_STOP` delivered: PASS
- stop request honored: PASS
- exact company-manager navigation URL: PASS

## Final result

**40/40 checks PASS**

SHA-256: `159afded363e78acd252cb08cc41378c2cd1a97b8a54ac5b450fa9927392803e`

Git blob SHA-1 of tested ZIP: `4c61e4de887c3af06b186ac456254107bc0f68a9`
