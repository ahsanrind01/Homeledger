# Homeledger

An offline Android app for US homeschooling parents to log daily learning time per child and subject, track progress against state requirements, store scanned work samples, and export PDF portfolios when school districts request records.

> **Disclaimer**: Homeledger helps you keep the records your state asks for. It is a records tool, not legal advice. Check your state's rules with your state education department.

---

## Features & Plan Comparison

Homeledger is strictly offline-first. There are no user accounts, no cloud servers, no tracking analytics, and no background network calls. All data resides on the parent's device.

| Capability / Feature | Free Plan | Homeledger Plus (Paid) |
|---|:---:|:---:|
| **Daily Learning Time Logging** | ✅ Unlimited | ✅ Unlimited |
| **Progress & Pace Calculator** | ✅ Complete | ✅ Complete |
| **Manual Zip Backup & Restore** | ✅ Always Free | ✅ Always Free |
| **View Existing Work Samples** | ✅ Full Access | ✅ Full Access |
| **Manage / Edit Existing Children** | ✅ Full Access | ✅ Full Access |
| **Active Students Allowed** | 1 Child | Multi-child (2+) |
| **Work Sample Document Scanning** | ❌ (Locked) | ✅ Camera Scanner |
| **Portfolio PDF Export** | ❌ (Locked) | ✅ District-ready PDF |

### The Lapse Guarantee
If a parent's subscription expires:
- **No data is ever deleted or hidden.**
- All children, logs, and work samples remain fully visible, editable, and exportable via backup.
- If a lapsed user already has multiple children, both children remain active and fully usable for logging. Only creating a *new* additional child is locked.

---

## Architecture & Fake Billing Simulation

To keep Homeledger lightweight and verifiable before Google Play Console deployment, **no external billing SDKs (such as `in_app_purchase`) or network dependencies are included**.

Entitlement state is handled via a clean, decoupled architecture:
1. **Domain Model (`lib/domain/entitlement.dart`)**:
   - Pure Dart state: `EntitlementPlan` (free, paid), `paidUntil`, `lastVerifiedAt`.
   - Pure function `isPaid(...)`: Validates whether the subscription is active, including a **7-day offline grace period** (`kEntitlementGraceDays`).
2. **Central Policy Gate (`lib/domain/feature_policy.dart`)**:
   - `canUse(Feature, EntitlementState, now)`: Central rule enforcement returning `FeatureAccess.allowed` or `FeatureAccess.locked`. UI screens *never* inspect subscription plans directly.
3. **Fake Entitlement Service (`lib/services/entitlement_service.dart`)**:
   - Emits real-time reactive updates via Drift database storage.
4. **Developer Simulation Menu (`lib/features/debug/debug_entitlement_screen.dart`)**:
   - Gated strictly by `kDebugMode` (inaccessible in release builds).
   - In debug builds, access via **Settings → Developer Options (Debug Only)** to simulate:
     - Free Plan
     - Paid (Active for 1 year)
     - Paid (Expired 3 days ago — active within 7-day grace period)
     - Paid (Expired 10 days ago — lapsed)

---

## How to Run

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on an Android device or emulator**:
   ```bash
   flutter run
   ```

---

## How to Test and Analyze

- **Run Static Analysis**:
  ```bash
  flutter analyze
  ```
  Enforces zero lint warnings, `prefer_const_constructors`, and `avoid_print`.

- **Run Full Automated Test Suite**:
  ```bash
  flutter test
  ```
  Runs 180+ unit, domain, repository, widget, and policy locking tests.

---

## Pre-Release Hardening Checklist

- [x] **Zero Network Calls**: Verified 0 usages of `http`, `dio`, `HttpClient`, `Socket`, `url_launcher`, analytics, or Firebase.
- [x] **No Auto Cloud Backup**: `android:allowBackup="false"` confirmed in `AndroidManifest.xml`.
- [x] **Strict Permissions**: Only `android.permission.CAMERA` requested. No Internet or Storage permissions in release.
- [x] **No Regulatory Claims**: Verified 0 occurrences of prohibited words (`compliant`, `approved`, `guaranteed`, `certified`) in user-facing UI and documentation.
- [x] **Accessibility**: Verified 48dp minimum touch targets and clean 200% text scaling across Home, Log, and Paywall views.
- [x] **Robust Error & Empty States**: Clean zero-item empty states for Home, Log, Samples, and Settings.
- [x] **Atomic Data Isolation**: Child switching verified; Child A records never bleed into Child B.
- [x] **Release APK Build**: Validated via `flutter build apk --release`.

