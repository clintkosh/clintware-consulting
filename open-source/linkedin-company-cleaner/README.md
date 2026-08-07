# LinkedIn Company Cleaner by Clintware

Current release: **v1.1.3**

Manifest V3 extension for Edge and Chromium browsers that selectively or bulk unfollows LinkedIn company Pages from the company manager.

## v1.1.3 scan fix

v1.1.2 could leave an old `__LCC_CONTENT_V110__` marker in an already-open LinkedIn tab. If the old extension receiver had been invalidated, reinjection could exit early and the popup's **Scan** button had no listener to answer it.

v1.1.3:

- uses a versioned content-worker marker
- stores/removes the current message listener when reinjecting
- pings the LinkedIn worker before every Scan/Start/Stop
- reinjects the current worker if the ping fails
- verifies LinkedIn by executing a hostname check in the active tab instead of depending on `tab.url`
- gives Scan an immediate visible status and explicit failure text

## Company manager

`https://www.linkedin.com/mynetwork/network-manager/company/?filterType=company`

## Verified release

The exact tested ZIP is represented byte-for-byte in:

`linkedin-company-cleaner-v1.1.3-EXTRACT-FIRST.zip.base64`

The Clintware download page reconstructs that payload client-side into the normal ZIP. This avoids binary mutation by the GitHub connector while preserving the tested artifact exactly.

SHA-256 of the reconstructed ZIP:

`159afded363e78acd252cb08cc41378c2cd1a97b8a54ac5b450fa9927392803e`

## Validation

The final v1.1.3 ZIP was extracted into a clean directory and tested from that extraction.

- 40/40 release checks passed
- stale-tab / missing-listener recovery passed
- Scan click returned two simulated company rows
- Select All, Start Selected, direct unfollow, confirmation-dialog unfollow, Stop, and exact navigation passed
- Chromium successfully parsed the exact extracted directory with `--pack-extension`

See `TEST_REPORT.md` for the regression details.

## Scope

Company Pages only. No people, schools, newsletters, groups, or skills. No analytics or remote code.

## License

MIT. Copyright 2026 Clintware.
