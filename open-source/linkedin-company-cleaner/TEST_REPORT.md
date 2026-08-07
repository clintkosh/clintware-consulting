# LinkedIn Company Cleaner v1.1.1 Test Report

Test date: 2026-08-06

## Installation regression fixed

Version 1.1.0 was prechecked by parsing the archive but was not validated using the exact end-user installation directory. Version 1.1.1 adds that missing regression check.

## Clean extraction and manifest-location test

1. Created an empty test directory.
2. Extracted `linkedin-company-cleaner-v1.1.1-EXTRACT-FIRST.zip` into it.
3. Confirmed `manifest.json` exists directly at the extracted directory root.
4. Confirmed all resources declared by the manifest exist.
5. Parsed the manifest as JSON and verified Manifest V3 and version 1.1.1.

Result: PASS

## Chromium extension validation

Chromium was run with:

`chromium --pack-extension=<exact-clean-extracted-directory> --no-message-box`

Chromium created both a nonempty `.crx` and `.pem`, confirming that Chromium could read the manifest and package all declared extension resources from the exact folder users must select for **Load unpacked**.

Result: PASS

## JavaScript validation

`background.js`, `lib.js`, `content.js`, and `popup.js` passed Node syntax checks.

Result: PASS

## Action dry run

- Exact company-manager navigation: PASS
- Scan: PASS
- Select all: PASS
- Start selected: PASS
- Stop: PASS
- Direct-unfollow path: PASS
- Confirmation-dialog path: PASS
- Companies completed: 2
- Failed: 0
- Skipped: 0

## Missing content-script recovery

- Initial message failure simulated: PASS
- CSS reinjected: 1 time
- Scripts reinjected: 1 time
- Retry succeeded: PASS

## Package safeguards

The archive now includes:

- `README-INSTALL-FIRST.txt`
- `VERIFY-AND-OPEN-EXTENSIONS.cmd`

The Windows verifier refuses to continue unless `manifest.json` and all required extension files are in the current directory.

## Final result

PASS
