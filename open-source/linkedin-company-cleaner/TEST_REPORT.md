# LinkedIn Company Cleaner v1.1.0 Test Report

Test date: 2026-08-06

## Validation performed

1. Manifest JSON parse and Manifest V3 field validation.
2. JavaScript syntax checks for `background.js`, `lib.js`, `content.js`, and `popup.js`.
3. Real Chromium DOM dry run against a virtual LinkedIn company-manager page.
4. Popup action dry run with mocked Chrome extension APIs.
5. Missing-content-script recovery test.
6. Release ZIP extraction and checksum verification.

## Chromium workflow result

- Companies scanned: 2
- Direct-unfollow path: passed
- Confirmation-dialog path: passed
- Completed: 2
- Failed: 0
- Skipped: 0

Observed page actions:

1. `acme-direct`
2. `beta-open`
3. `beta-confirm`

## Popup workflow result

The following message sequence executed successfully:

1. `LCC_STATE`
2. `LCC_SCAN`
3. `LCC_START`
4. `LCC_STOP`

The Start action received both selected company IDs.

The left navigation button updated the active tab to:

`https://www.linkedin.com/mynetwork/network-manager/company/?filterType=company`

## Reinjection recovery result

The first simulated `tabs.sendMessage` failed with a missing receiver. The popup then:

- inserted `content.css` once
- executed `lib.js` and `content.js` once
- retried the message successfully

## Result

PASS
