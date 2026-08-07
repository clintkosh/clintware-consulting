# LinkedIn Company Cleaner by Clintware v1.1.2

A Manifest V3 extension for Microsoft Edge, Google Chrome, Brave, Vivaldi, and other Chromium browsers. It is limited to LinkedIn company Pages and does not target people, schools, newsletters, groups, or skills.

## v1.1.2 installation fix

v1.1.1 could fail in Edge with `Couldn't load icon icons/icon48.png specified in icons` even though the PNG was present in the ZIP. v1.1.2 removes every icon declaration and every PNG dependency from the extension manifest. Icons are optional for Chromium extensions, so installation can no longer be blocked by an icon resource.

The release ZIP is also flat: after **Extract All**, `manifest.json` is directly inside the extracted folder you select with **Load unpacked**.

## Install

1. Download `linkedin-company-cleaner-v1.1.2-EXTRACT-FIRST.zip`.
2. Right-click it and choose **Extract All**.
3. Open the extracted folder and confirm `manifest.json` is directly visible.
4. Open `edge://extensions` or `chrome://extensions`.
5. Enable **Developer mode**.
6. Choose **Load unpacked** and select that exact extracted folder.

`VERIFY-AND-OPEN-EXTENSIONS.cmd` is included and checks the required files and confirms the manifest has no icon dependencies.

## Company list route

The **Find followed companies** button opens:

`https://www.linkedin.com/mynetwork/network-manager/company/?filterType=company`

## Validation

v1.1.2 passed:

- clean extraction with root-level `manifest.json`
- manifest dependency graph validation
- explicit no-icon/no-PNG assertion
- Chromium extension pack parsing on the exact extracted directory
- JavaScript syntax checks
- Chromium popup wiring simulation for Scan, Select All, Start, Stop, and exact company-manager navigation
- Chromium DOM simulation for direct-unfollow and confirmation-dialog flows: 2 completed, 0 failed

## Privacy

The extension runs locally in the active LinkedIn tab and contains no analytics, remote code, or third-party API calls.

## License

MIT. Copyright 2026 Clintware.
