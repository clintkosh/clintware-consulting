# LinkedIn Company Cleaner by Clintware

A Manifest V3 browser extension for Microsoft Edge, Google Chrome, Brave, Vivaldi, and other Chromium browsers. It scans the LinkedIn company Pages shown in your own **Interests → Companies** list, lets you select specific companies or select all, and handles LinkedIn's repeated Unfollow prompts after one run-level confirmation.

## Download

- `linkedin-company-cleaner-v1.0.0.zip`
- SHA-256: `117b10f923a68f76da1d338107826d0f77695b2d05a37a4e662c53f31bff6b9b`

The ZIP contains the complete unpacked extension source with `manifest.json` at its root.

## Scope

- Company Pages only: URLs must match `linkedin.com/company/...`
- Ignores people, schools, newsletters, groups, and skills
- Runs locally in the active LinkedIn tab
- Sends no LinkedIn data to Clintware or any third party
- Includes selective and all-company modes, a per-run maximum, randomized delay, auto-scroll, progress, and stop controls

## Install

1. Download and extract the ZIP.
2. Open `edge://extensions` or `chrome://extensions`.
3. Enable **Developer mode**.
4. Choose **Load unpacked**.
5. Select the extracted folder containing `manifest.json`.
6. Open LinkedIn, click the extension, and use **Open company following**.

## Compatibility

LinkedIn changes its interface frequently, so this tool may require updates. LinkedIn's published rules state that it does not permit browser extensions that automate activity on its website. This independent project is not affiliated with or authorized by LinkedIn.

## Validation

The v1.0.0 package passed Manifest JSON validation, JavaScript syntax checks, and five Node unit tests before publication.

## License

MIT. Copyright 2026 Clintware.
