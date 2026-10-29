# Reachability Audit: Features and Rules from docs/PROJECT_CONTEXT.md

This document audits every feature, data rule, business rule, and constraint specified in [docs/PROJECT_CONTEXT.md](file:///Users/mac/Documents/Homeledger/docs/PROJECT_CONTEXT.md) and maps out how a parent reaches each item by tapping from the Home screen, or identifies it as **Not reachable**.

---

## 1. Feature & Rule Reachability Table

| Category | Feature / Rule from `PROJECT_CONTEXT.md` | Tapping Route from Home | Status / Reachability |
| :--- | :--- | :--- | :--- |
| **Product** | Daily learning time logging per child and subject | Home -> "Log time" button (or bottom nav "Log") -> `LogScreen` | **Reachable** (1 tap) |
| **Product** | View progress against state / custom requirement | Home -> Progress card (or bottom nav "Progress") -> `ProgressScreen` | **Reachable** (1 tap) |
| **Product** | Save scanned / picked work samples | Home -> bottom nav "Samples" -> `SampleLibraryScreen` -> tap "Scan work" | **Reachable** (2 taps) |
| **Product** | View work sample details / full-screen image | Home -> bottom nav "Samples" -> tap any sample thumbnail -> `SampleViewerScreen` | **Reachable** (2 taps) |
| **Product** | Export PDF portfolio | Home -> bottom nav "Export" -> `ExportOptionsScreen` -> "Create PDF" | **Reachable** (2 taps) |
| **Product** | Free plan: 1 child tracking | Home -> Settings icon in AppBar -> `SettingsScreen` -> view or edit single child | **Reachable** (2 taps) |
| **Product** | Free plan: Manual backup & restore | Home -> Settings icon -> `SettingsScreen` -> "Back up now" or "Restore from backup" | **Reachable** (2 taps) |
| **Product** | Paid plan: PDF export (Plus) | Home -> bottom nav "Export" -> "Create PDF (Plus)" -> dialog -> `PaywallScreen` | **Reachable** (when locked) |
| **Product** | Paid plan: Scanning (Plus) | Home -> bottom nav "Samples" -> "Scan work (Plus)" -> dialog -> `PaywallScreen` | **Reachable** (when locked) |
| **Product** | Paid plan: More than one child (Plus) | Home -> Settings icon -> `SettingsScreen` -> "Add child (Plus)" -> `PaywallScreen` | **Reachable** (when childCount >= 1) |
| **Entitlement** | Standalone "Upgrade" / "Plan" row in Settings | *None* | **Not reachable** (No plan or upgrade row exists in Settings) |
| **Entitlement** | "Restore purchase" row in Settings / Main screens | *None* (Only exists as button inside `PaywallScreen`) | **Not reachable directly** (Only reachable after triggering a locked paid action) |
| **Entitlement** | Developer subscription debug screen | Home -> Settings icon -> `SettingsScreen` -> bottom row (Debug mode only) | **Reachable** (Debug builds only) |
| **Data rules** | Plain text date YYYY-MM-DD storage | Home -> bottom nav "Log" -> select date via picker | **Enforced internally** |
| **Data rules** | Computed totals from entries | Home -> Progress card; `ProgressScreen`; PDF portfolio | **Enforced internally** |
| **Data rules** | Work sample file + DB row combined lifecycle | `SampleLibraryScreen` (create/delete) and `SampleViewerScreen` (delete) | **Reachable** |
| **Data rules** | Cascade delete child, entries, & samples | Home -> Settings icon -> `SettingsScreen` -> tap Delete child icon -> confirm dialog | **Reachable** |
| **Data rules** | Lapsed subscription locks actions without deleting data | Evaluated in `FeatureAccess`; locked banners/dialogs appear on Samples/Export/Settings | **Reachable** |
| **Business rules**| Block time logging > 24 hours per day | Home -> bottom nav "Log" -> enter > 24h -> error message blocks submission | **Reachable & Enforced** |
| **Business rules**| Warn time logging > 10 hours per day | Home -> bottom nav "Log" -> enter > 10h -> warning confirmation dialog | **Reachable & Enforced** |
| **Business rules**| Block future dates in time logging | Home -> bottom nav "Log" -> date picker restricts max date to today | **Reachable & Enforced** |
| **Business rules**| Pace calculation (90% threshold, calendar days) | Home -> Progress card; `ProgressScreen` metrics | **Reachable & Enforced** |
| **Wording** | Forbidden claim words omitted | All user-facing screens, Settings disclaimer, and PDF output | **Enforced via tests** |
| **Wording** | "Records tool, not legal advice" disclaimer | Onboarding; `SettingsScreen` card; `PrivacyPolicyScreen`; PDF footer | **Reachable** |
| **Privacy** | Privacy policy screen | Home -> Settings icon -> `SettingsScreen` -> tap "Privacy policy" row | **Reachable** |
| **Privacy** | Zero server/network calls; local-only storage | Entire app | **Enforced in code** |

---

## 2. Detailed Audit of Settings Screen Rows

Every row on `SettingsScreen` ([lib/features/settings/settings_screen.dart](file:///Users/mac/Documents/Homeledger/lib/features/settings/settings_screen.dart)) from top to bottom:

1. **Parent name (optional)**:
   - *Reachability*: Home -> Settings icon -> tap tile.
   - *Behavior*: Opens edit dialog to store parent/educator name for portfolio cover pages.
2. **Children section**:
   - *Reachability*: Home -> Settings icon -> Children list.
   - *Behavior*: Shows all children with Edit and Delete icons.
   - *Add Child action*:
     - If 0 children: Displays "Add child" -> opens `AddChildScreen`.
     - If >= 1 children on Free plan: Displays "Add child (Plus)" with lock icon -> opens `PaywallScreen`.
     - If on Paid plan: Displays "Add child" -> opens `AddChildScreen`.
3. **Subjects row**:
   - *Reachability*: Home -> Settings icon -> "Subjects" tile.
   - *Behavior*: Navigates to `SubjectsScreen` to manage core/custom subjects.
4. **Backup & restore section (Free Plan - Always Unlocked)**:
   - *Row A ("Back up now")*: Creates zip archive and launches Android system share sheet.
   - *Row B ("Restore from backup")*: Opens file picker for `.zip` backup, displays inspection confirmation dialog with student/entry/sample counts, and executes atomic database and file restore.
5. **About Homeledger**:
   - *Reachability*: Read-only tile displaying `'Version 1.0.0 (1)'`.
6. **Privacy policy**:
   - *Reachability*: Home -> Settings icon -> "Privacy policy" tile.
   - *Behavior*: Opens `PrivacyPolicyScreen` with full plain-English offline privacy disclosures.
7. **Legal disclaimer**:
   - *Reachability*: Embedded visual card at the bottom of the screen displaying `AppStrings.fullDisclaimer`.
8. **Developer: Subscription debug (Debug Mode Only)**:
   - *Reachability*: Guarded with `if (kDebugMode)` at the bottom of the list. Opens `DebugEntitlementScreen`. In release builds, this row is completely absent.

---

## 3. Free Versus Paid Limits and Where They Are Shown

| Limit | Free Plan Behavior | Paid (Plus) Plan Behavior | Where Shown to Parent |
| :--- | :--- | :--- | :--- |
| **Number of children** | 1 child allowed | Unlimited children | `SettingsScreen`: "Add child (Plus)" button with lock icon when 1 child already exists. Tapping navigates to `PaywallScreen`. |
| **Work sample scanning** | Locked (cannot scan/save samples) | Unlocked (unlimited camera scans and photo picker imports) | `SampleLibraryScreen`: Main button is "Scan work (Plus)" with lock icon. Tapping opens upgrade explanation dialog leading to `PaywallScreen`. |
| **PDF portfolio export** | Locked (cannot generate PDF) | Unlocked (export full portfolio with attendance, logs, and sample images) | `ExportOptionsScreen`: Main button is "Create PDF (Plus)" with lock icon. Tapping opens upgrade explanation dialog leading to `PaywallScreen`. |
| **Time logging** | Unlimited | Unlimited | `LogScreen`: Always free and fully functional. |
| **Progress tracking** | Unlimited | Unlimited | Home and `ProgressScreen`: Always free and fully functional. |
| **Backup & restore** | Unlimited | Unlimited | `SettingsScreen`: Always free; never locked. |

---

## 4. Specific Items Flagged in Audit

1. **Upgrade or Plan Row**:
   - **Finding**: **Not present as a standalone row in Settings**.
   - A parent on the free plan has no dedicated "Upgrade to Plus" or "My Subscription" row in Settings. The paywall is only reached contextually when attempting to add a second child in Settings, scan a sample in Samples, or export a PDF in Export.
2. **Restore Purchase Row**:
   - **Finding**: **Not present in Settings or top-level navigation**.
   - A parent who reinstalls the app or moves to a new device cannot restore an existing subscription from Settings.
   - The "Restore purchases" action only exists inside `PaywallScreen`. Therefore, a parent must first tap a locked Plus feature to open the paywall before finding the "Restore purchases" button.
