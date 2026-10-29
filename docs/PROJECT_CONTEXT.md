# Homeledger project context (read this before every task)

## Product
Offline Android app for US homeschooling parents: log daily learning time per child and subject, see progress against the state requirement, save scanned work samples, export a PDF portfolio. No server, no login, no analytics, no ads.
Free plan: 1 child, logging, progress, manual backup. Paid plan (yearly): PDF export, scanning, more than one child.

## Tech
Flutter (Android only), Dart with null safety, flutter_riverpod, drift (SQLite, from step 2), plain Navigator. Add a package only when a step names it. For every new package: say why, and verify the current version and API on pub.dev. Never guess an API.

## Data rules
- A log day is a plain text date YYYY-MM-DD. Never store a day as a timestamp.
- Totals are never stored. Always compute them from entries.
- A work sample is a file in private app storage plus a database row holding its path. Create and delete them together.
- Deleting a child deletes its entries and samples in one transaction, after confirmation.
- A lapsed subscription never deletes or hides data. It only locks paid actions.

## Business rules
- Time logged for one child on one day: block above 24 hours, warn above 10 hours.
- Future dates are not allowed. Past dates are allowed.
- Expected hours to date = required hours x (elapsed school days / total school days), where elapsed days include today. A child is On pace if hours done >= 90% of expected hours, otherwise Behind.

## Wording
- Never write 'compliant', 'approved' or 'guaranteed' in the app or in the PDF. Use 'helps you keep the records your state asks for'.
- Every disclaimer says: records tool, not legal advice.

## Privacy
- No network access from the app, except Google Play Billing added much later. No analytics, no crash-reporting SDK, no ads.
- The only Android permission is CAMERA.

## UI
- Simple English text. Material 3. Tap targets at least 48 dp. Respect the system text size. No emoji.

## How the agent works
- Plan first, then write code in small steps. Run 'flutter analyze' and 'flutter test' after every step.
- Never invent facts, especially state rules, prices or APIs. If unsure, stop and ask me.
- Do not add features, packages or files outside the current step.
- After every step, add an entry to docs/WALKTHROUGH.md: what you built, file by file, why each file exists, and what would break without it.
