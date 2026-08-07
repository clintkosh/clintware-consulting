# LinkedIn Company Cleaner by Clintware

Current release: **v1.1.1**

Manifest V3 browser extension for Microsoft Edge, Google Chrome, Brave, Vivaldi, and other Chromium browsers. It bulk or selectively unfollows LinkedIn company Pages from the user's own company-following list.

## Download

Use `linkedin-company-cleaner-v1.1.1-EXTRACT-FIRST.zip`.

SHA-256: `60246b721c921e3e344384b5b06ef7fbbc163091259c32a756f22abb9fe989ee`

## Important installation step

The ZIP must be extracted before using **Load unpacked**. The exact folder selected in Edge or Chrome must directly contain `manifest.json`.

The package includes `VERIFY-AND-OPEN-EXTENSIONS.cmd`, which checks that `manifest.json` and the required extension files are present before opening the extensions page.

## Company manager

The **Find followed companies** control opens:

`https://www.linkedin.com/mynetwork/network-manager/company/?filterType=company`

## Validation

v1.1.1 was regression-tested by extracting the release into an empty directory and pointing Chromium's extension packer at that exact directory. Chromium successfully read and packed the extension. The action dry run also passed Scan, Select All, Start, Stop, direct-unfollow, confirmation-dialog, and missing-content-script recovery flows.

See `TEST_REPORT.md` for the full validation record.

## Scope and privacy

- Company Pages only
- No people, schools, newsletters, groups, or skills
- Runs locally in the active LinkedIn tab
- No analytics, external APIs, or remote code

## License

MIT. Copyright 2026 Clintware.
