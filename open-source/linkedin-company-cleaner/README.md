# LinkedIn Company Cleaner by Clintware

A Manifest V3 browser extension for Microsoft Edge, Google Chrome, Brave, Vivaldi, and other Chromium browsers. It works from LinkedIn's company manager, scans company Pages only, and lets the user selectively or bulk unfollow company Pages with one run-level confirmation.

## Version 1.1.0

This release fixes the original scan failure and refreshes the interface.

- Uses LinkedIn's current company-manager route:
  `https://www.linkedin.com/mynetwork/network-manager/company/?filterType=company`
- Detects followed-company controls labeled either `Following ...` or `Unfollow ...`
- Handles both direct state changes and confirmation-dialog flows
- Reinjects the content script automatically when a previously open LinkedIn tab has no receiver
- Adds a smaller, cleaner popup interface and compact in-page progress panel
- Preserves company-only filtering through `/company/` URLs

## Download and install

1. Download `linkedin-company-cleaner-v1.1.0.zip`.
2. Extract the ZIP.
3. Open `edge://extensions` or `chrome://extensions`.
4. Enable **Developer mode**.
5. Choose **Load unpacked**.
6. Select the extracted directory containing `manifest.json`.
7. Open the extension and select **Find followed companies**.
8. On LinkedIn, open the extension again and select **Scan**.

## Privacy and scope

- Company Pages only
- Ignores people, schools, newsletters, groups, and skills
- Runs locally in the active LinkedIn tab
- No analytics, remote code, account credentials, or external APIs
- Includes selective/all-company modes, per-run limits, randomized delays, auto-scroll, progress, and stop controls

## Validation

The v1.1.0 dry run used a real headless Chromium DOM with virtual LinkedIn company rows. It verified:

- exact left-button navigation URL
- popup Scan, Select All, Start, and Stop message wiring
- scanning controls labeled `Unfollow Company` and `Following Company`
- direct-unfollow completion
- confirmation-dialog completion
- automatic content-script reinjection
- zero failed actions in the two-company end-to-end fixture

See `TEST_REPORT.md` and `TEST_RESULTS.json`.

## Compatibility

LinkedIn changes its interface frequently, so future selector maintenance may be required. This independent project is not affiliated with or authorized by LinkedIn.

## License

MIT. Copyright 2026 Clintware.
