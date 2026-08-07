# LinkedIn Company Cleaner v1.1.2 Test Report

Test date: 2026-08-07

## Regression addressed

v1.1.1 failed for the user in Microsoft Edge with:

`Couldn't load icon icons/icon48.png specified in icons.`

The v1.1.1 ZIP did physically contain a valid 48x48 PNG, but Edge still rejected the icon reference. v1.1.2 removes the optional extension icon declarations entirely. The v1.1.2 release contains no PNG files.

## Archive layout test

The final ZIP was extracted into a clean empty directory.

Result:

- `manifest.json` directly at extraction root: PASS
- nested `manifest.json`: NONE
- archive contains a single installation level: PASS

## Manifest dependency test

Manifest-declared file dependencies:

- `background.js`
- `popup.html`
- `lib.js`
- `content.js`
- `content.css`

All exist, are readable, and are non-empty: PASS

Additional assertions:

- `icons` manifest property absent: PASS
- `action.default_icon` absent: PASS
- PNG files in release: 0

This specifically prevents recurrence of the v1.1.1 icon-loading failure.

## Chromium parse test

Chromium successfully packed the exact clean-extracted directory using `--pack-extension`, confirming it parsed the Manifest V3 structure and declared resources.

Result: PASS

A separate attempt to use the system Chromium's `--load-extension` switch was blocked by an administrator policy in the execution environment (`Loading of unpacked extensions is disabled by the administrator`). This environment policy is unrelated to the extension, so it is not counted as an extension pass/fail signal.

## JavaScript syntax

`background.js`, `lib.js`, `content.js`, and `popup.js` passed Node syntax validation.

Result: PASS

## Chromium popup action simulation

The popup was rendered in Chromium with mocked Chrome extension APIs.

Verified:

- version label v1.1.2: PASS
- initial state/scan data rendering: PASS
- Scan sends `LCC_SCAN`: PASS
- Select All selects both fixture companies: PASS
- Start sends both selected company IDs in `LCC_START`: PASS
- Stop sends `LCC_STOP`: PASS
- Find followed companies navigates to `https://www.linkedin.com/mynetwork/network-manager/company/?filterType=company`: PASS

## Chromium content workflow simulation

Virtual LinkedIn company-manager DOM contained two company rows:

1. direct unfollow path
2. confirmation-dialog unfollow path

Result:

- companies discovered: 2
- completed: 2
- failed: 0
- content-script ping version: 1.1.2

## Final result

PASS

v1.1.2 should be used instead of v1.1.1.
