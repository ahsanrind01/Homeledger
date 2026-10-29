# Walkthrough
One entry per step. Plain English, for a student.

---

## How the Whole App Fits Together (Architectural Overview)

Homeledger is structured as a layered, clean offline-first Flutter application with unidirectional data flow and zero cloud dependency:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION / UI LAYER                         │
│  HomeScreen • LogScreen • ProgressScreen • SampleLibraryScreen        │
│  WorkSampleCaptureScreen • ExportOptionsScreen • SettingsScreen       │
│  AddChildScreen • PaywallScreen • DebugEntitlementScreen (Debug Only) │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ Watches / Listens
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT (RIVERPOD)                       │
│  Providers wire UI to domain logic, reactive SQLite database streams,  │
│  and asynchronous file/service operations.                             │
└──────────────────┬─────────────────────────────────┬───────────────────┘
                   │ Delegates                       │ Observes / Emits
                   ▼                                 ▼
┌────────────────────────────────────┐ ┌─────────────────────────────────┐
│       SERVICES / ISOLATES          │ │          DOMAIN LAYER           │
│  • BackupService (VACUUM INTO)     │ │  • ProgressCalculator           │
│  • ExportService (PDF generation)  │ │  • LogValidator                 │
│  • SampleStorageService (images)   │ │  • FeaturePolicy (canUse)       │
│  • FakeEntitlementService (SQLite) │ │  • Entitlement (isPaid + grace) │
│                                    │ │  • RuleProfile & RuleResolver   │
│                                    │ │  • ImageProcessor (isolate)     │
└──────────────────┬─────────────────┘ └─────────────────────────────────┘
                   │ Persists & Reads
                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          OFFLINE DATA LAYER                            │
│  • Drift SQLite Database (AppDatabase: 7 tables)                       │
│    - Children, Subjects, LogEntries, WorkSamples, CustomRules,         │
│      AppSettings, Entitlements                                         │
│  • Local App Storage: `samples/` directory for work sample images      │
└────────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Tenets
1. **Unidirectional Data Flow**: The UI only displays data provided by Riverpod providers and dispatches user actions through domain validators and repositories.
2. **Pure Domain Logic**: All calculations (`ProgressCalculator`, `LogValidator`, `canUse`, `isPaid`) are pure Dart functions with zero database, clock, or UI dependencies. They accept plain arguments and return deterministic results, making them easy to unit test.
3. **Isolate-Offloaded Heavy Work**: Heavy tasks (atomic SQLite snapshots, zip archiving, image downsizing, and PDF rendering) execute in background worker isolates or async pipelines without freezing the UI thread.
4. **Strict Zero-Network Privacy**: Homeledger declares zero network permissions (`android:allowBackup="false"`, no Internet permission) and contains 0 network packages. All records belong exclusively to the parent.

---

## Step 1: Project setup

In this step, we initialized the project from scratch for Android, set up Riverpod and core dependencies, defined our foundational design system with Material 3, created a clean folder structure, configured static analysis and linting, and verified the project with a widget test.

### What was built

#### Project Configuration & Toolchain
- **`pubspec.yaml`**: Configured the project metadata and dependencies.
  - *Why it exists*: Declares our application's direct packages (`flutter_riverpod`, `path`, `path_provider`, `intl`), dev dependencies (`flutter_lints`, `flutter_test`), and assets/fonts configuration.
  - *What would break without it*: Flutter would not know which packages to download or compile, causing the entire Dart build to fail immediately.
- **`analysis_options.yaml`**: Configured static analysis using `flutter_lints` with additional rules `prefer_const_constructors: true` and `avoid_print: true`.
  - *Why it exists*: Catches potential bugs and performance issues at compile time and enforces clean coding standards.
  - *What would break without it*: Code quality warnings and standard rules wouldn't be enforced, allowing mutable widget instantiations and accidental stdout logging.
- **`android/app/src/main/AndroidManifest.xml`**: Android app manifest configured with `android:allowBackup="false"` per project decisions.
  - *Why it exists*: Informs the Android OS about the application identity, launch activity, and system backup behavior.
  - *What would break without it*: Android cannot install or launch the application.

#### Source Code (`lib/`)
- **`lib/main.dart`**: Entry point of the application. Initializes Flutter bindings and runs `HomeledgerApp` wrapped inside Riverpod's `ProviderScope`.
  - *Why it exists*: Every Flutter application begins execution in `main()`. Wrapping with `ProviderScope` ensures Riverpod state management is available anywhere in the widget tree.
  - *What would break without it*: The application cannot launch, and any Riverpod providers used later will throw a `ProviderScope not found` exception.
- **`lib/app/app.dart`**: Application shell defining the root `MaterialApp`.
  - *Why it exists*: Sets up the top-level app configuration, theme bindings (light and dark mode supporting system settings), disables the debug banner, and provides the initial route via plain `Navigator` to `HomeScreen`.
  - *What would break without it*: Widgets would lack Material styling, theming, text directionality, and navigation context.
- **`lib/app/theme.dart`**: Material 3 theme configurations (`AppTheme.lightTheme` and `AppTheme.darkTheme`).
  - *Why it exists*: Centralizes color schemes and typography so the entire app maintains a coherent, accessible look that seamlessly respects the device's system theme.
  - *What would break without it*: The app would fall back to unstyled default themes with no dark mode support.
- **`lib/core/strings.dart`**: Application string constants (`AppStrings`).
  - *Why it exists*: Centralizes user-facing text strings like the app name (`Homeledger`) and legal disclaimer (`Records tool, not legal advice.`) to avoid hardcoding strings and prevent wording mistakes.
  - *What would break without it*: Inconsistent or mistyped wording across screens, violating product disclaimer requirements.
- **`lib/core/constants.dart`**: Core numerical and business rule constants (`AppConstants`).
  - *Why it exists*: Defines constants for accessibility tap targets (48 dp), daily log hour limits (warn at 10h, block at 24h), and pace calculation thresholds (90%).
  - *What would break without it*: Magic numbers would be scattered across business logic, making updates error-prone.
- **`lib/features/home/home_screen.dart`**: Placeholder home screen.
  - *Why it exists*: Serves as the landing screen displaying the app title and the required legal disclaimer text: "Records tool, not legal advice."
  - *What would break without it*: The app would have no initial screen to display upon launch.
- **`lib/data/.gitkeep` & `lib/domain/.gitkeep`**: Placeholder marker files for upcoming architecture layers.
  - *Why they exist*: Git does not track empty folders; `.gitkeep` ensures the repository preserves the directory structure for data access (database/repositories) and domain logic (models/rules).
  - *What would break without it*: The architecture folder layout would not be preserved in source control.

#### Tests (`test/`)
- **`test/widget_test.dart`**: Automated widget test verifying startup.
  - *Why it exists*: Boots the application within a test harness and asserts that the app name and disclaimer text are rendered.
  - *What would break without it*: Automated CI / test suites cannot automatically verify that the app shell renders properly.

#### Documentation (`docs/` & root)
- **`docs/PROJECT_CONTEXT.md`**: Foundational product rules, privacy boundaries, and constraints.
- **`docs/DECISIONS.md`**: Architectural and product decisions.
- **`docs/WALKTHROUGH.md`**: Step-by-step plain English explanations for every step.
- **`README.md`**: Project overview, folder map, and instructions on running and testing.

## Step 2: Offline data layer

In this step, we built the entire offline data layer: Drift SQLite database, six database tables, formatters, six repositories, Riverpod providers, exported schema tooling, and unit tests. No screens or UI were modified.

### Key Architectural Concepts (Explained for Students)

1. **What each table is for**:
   - **`children`**: Stores homeschool student profiles (name, school year start/end dates, rule ID, creation timestamp).
   - **`subjects`**: Stores learning subjects (e.g. Math, Reading, History) with a case-insensitive unique name constraint, a flag indicating if it is core curriculum, and a display sort order.
   - **`log_entries`**: Stores daily learning time recorded for a child in a subject. Time is stored in integer minutes.
   - **`work_samples`**: Stores metadata and file paths for saved/scanned student work samples on disk.
   - **`custom_rules`**: Stores parent-defined homeschool requirement goals (required hours and/or required days).
   - **`entitlement`**: A single-row table storing the device's subscription state (`paidUntil`, `lastVerifiedAt`, `plan`).

2. **Why `day` is stored as plain text (`YYYY-MM-DD`)**:
   - A school day is a calendar day, not a point in time. Storing UTC timestamps or `DateTime` objects causes timezone bugs: for example, a parent logging hours at 11:00 PM local time might be saved as the next day in UTC, causing hours to appear on the wrong date. Plain text ISO `YYYY-MM-DD` strings are timezone-neutral, easy to read, and sort chronologically with standard SQLite comparison operators (`>=` and `<=`).

3. **Why totals are queried and never stored**:
   - Caching totals in the database creates synchronization bugs. If a log entry is edited, deleted, or backdated, any stored total becomes out of date. By using SQL aggregate functions (`SUM(minutes)` and `COUNT(DISTINCT day)`), the database engine calculates the accurate total directly from the raw entries in microseconds, ensuring there is only ever one source of truth.

4. **Why `deleteChildCascade` returns file paths instead of deleting files inside the transaction**:
   - Database transactions can only roll back database rows, not filesystem operations. If code inside a database transaction deleted files from disk and the database commit subsequently failed, those work sample files would be permanently lost. By running the deletion of entries, samples, and the child in an atomic SQL transaction and returning the collected file paths, the caller can safely delete files from disk *after* the database commit succeeds.

### What was built (File by File)

#### Core Utilities
- **`lib/core/formatters.dart`**: Formats integer minutes into human-readable text like `'2 h 15 min'`, `'2 h'`, `'45 min'`, or `'0 min'`.
  - *Why it exists*: Encapsulates time formatting logic so the app never shows raw minutes or confusing decimal hours.
  - *What would break without it*: UI screens would duplicate formatting logic or show raw numbers like `135` instead of `'2 h 15 min'`.

#### Database Layer (`lib/data/db/`)
- **`lib/data/db/app_database.dart`**: Drift SQLite database definition with all 6 tables, migration scaffold (`schemaVersion = 1`), and `PRAGMA foreign_keys = ON;` in `beforeOpen`.
  - *Why it exists*: Serves as the central SQLite database definition with strongly typed Dart models.
  - *What would break without it*: The application would have no local persistence engine.
- **`lib/data/db/app_database.g.dart`**: Generated Drift code containing companion classes, table runners, and data models.
  - *Why it exists*: Generated automatically by `build_runner` to provide type-safe queries.
  - *What would break without it*: The database cannot compile.
- **`drift_schemas/drift_schema_v1.json`**: Dumped schema definition exported using Drift's schema tooling (`dart run drift_dev schema dump`).
  - *Why it exists*: Preserves a snapshot of database schema version 1 for automated migration testing in future steps.
  - *What would break without it*: Future schema migrations would not be able to verify backwards compatibility against schema v1.

#### Repositories (`lib/data/repositories/`)
- **`lib/data/repositories/child_repository.dart`**: Repository for managing children. Contains `deleteChildCascade` which atomically deletes entries, sample rows, and child in one transaction and returns sample file paths.
  - *Why it exists*: Abstracts child persistence and cascade cleanup.
  - *What would break without it*: Deleting a child would orphan foreign-keyed log entries and sample rows.
- **`lib/data/repositories/subject_repository.dart`**: Repository for adding, updating, watching, and listing subjects.
  - *Why it exists*: Manages curriculum subjects and enforces case-insensitive name uniqueness.
  - *What would break without it*: Duplicate subjects (e.g., "Math" and "math") could be created.
- **`lib/data/repositories/log_repository.dart`**: Repository for daily learning logs. Queries `totalMinutes`, `minutesBySubject`, and `distinctDaysLogged` directly via SQL aggregate queries across inclusive date boundaries.
  - *Why it exists*: Provides time logging queries without ever storing cached totals.
  - *What would break without it*: Progress calculations and state requirement tracking would lack aggregated data.
- **`lib/data/repositories/sample_repository.dart`**: Repository for work sample records with filtering by subject and date range.
  - *Why it exists*: Tracks metadata and disk locations of student work samples.
  - *What would break without it*: Work samples could not be indexed or associated with children and subjects.
- **`lib/data/repositories/custom_rule_repository.dart`**: Repository for custom rule profiles. Validates that at least one of `requiredHours` or `requiredDays` is provided.
  - *Why it exists*: Allows parents in states with non-standard hours/days to define their own targets.
  - *What would break without it*: Custom rules with empty targets could be saved, breaking pace calculations.
- **`lib/data/repositories/entitlement_repository.dart`**: Repository for the single-row device entitlement state.
  - *Why it exists*: Tracks whether the device has a yearly subscription or free plan.
  - *What would break without it*: The app could not query or update subscription status.

#### State Management (`lib/data/`)
- **`lib/data/providers.dart`**: Riverpod providers for `AppDatabase` and each repository.
  - *Why it exists*: Allows widgets and domain logic across the app to inject repositories cleanly.
  - *What would break without it*: Components would have to instantiate database connections manually, creating database locking conflicts.

#### Automated Tests (`test/`)
- **`test/core/formatters_test.dart`**: Unit tests for minute-to-hour string formatting.
- **`test/data/database_test.dart`**: Tests testing in-memory SQLite schema, CRUD on all 6 tables, foreign key enforcement, unique subject name constraint, and custom rule check constraint.
- **`test/data/repositories_test.dart`**: Tests testing each repository method, date boundary queries (inclusive of start and end dates), distinct day counting, and cascade deletion verifying nothing is left behind.

## Step 3: Rule profiles and loader

In this step, we built the rule profile domain model, asset loader, custom rule resolution service, and Riverpod providers. No screens were added or modified.

### Key Architectural Concepts (Explained for Students)

1. **Why states are data and not code**:
   - In the United States, homeschool laws vary dramatically by jurisdiction. One state requires 1,000 hours; another requires 180 days; another requires both hours and specific core subjects; others have no hourly requirements at all. Furthermore, legislative statutes change over time.
   - If we hardcoded state rules into Dart code using `switch` or `if/else` statements, any change to a state law would require altering application logic, risking regression bugs.
   - By decoupling state rules into plain JSON data files (`assets/rules/*.json`), the app treats all rules neutrally. The application engine simply calculates progress against whatever targets the data profile specifies.

2. **How to add a new state by adding a JSON file**:
   - **Step 1**: Find the official state education department statute or legislative code (following [`docs/ADDING_A_STATE.md`](file:///Users/mac/Documents/Homeledger/docs/ADDING_A_STATE.md)). Never copy numbers from blogs.
   - **Step 2**: Create a new JSON file under `assets/rules/<state_id>.json` with the required targets, official URL, and verification date.
   - **Step 3**: Add the filename to the array in `assets/rules/index.json`.
   - **Step 4**: Run `flutter test` — the automated loader test suite will immediately parse and validate the new file for correct schema, valid dates, and positive numbers.

3. **Why the loader skips bad files instead of crashing**:
   - Asset loading should never crash an application in production. If a single JSON file is corrupted or fails validation, `RuleProfileLoader` catches the error, appends a readable diagnostic message to `errors`, and continues loading all other valid profiles.

4. **How rule resolution works**:
   - When a child's record references a rule ID:
     - If `ruleId` starts with `'custom:'` (e.g. `'custom:1'`), `RuleResolver` queries the SQLite `custom_rules` table via `CustomRuleRepository` and converts the database row into a `RuleProfile` with `isCustom: true`.
     - Otherwise, `RuleResolver` searches the registered asset rule profiles.
     - If neither matches, it returns `RuleResolutionMissing(ruleId, message)` rather than throwing an exception. The UI can display a friendly notice without crashing.

### What was built (File by File)

#### Domain Model (`lib/domain/`)
- **`lib/domain/rule_profile.dart`**: The immutable `RuleProfile` class containing `id`, `label`, `requiredHours`, `requiredDays`, `coreSubjects`, `sourceUrl`, `lastChecked`, `isCustom`, and `notes`.
  - *Why it exists*: Serves as the domain model for all requirement comparisons in the app.
  - *What would break without it*: Business logic would have no consistent data structure to evaluate student pace or required subjects.
- **`lib/domain/rule_resolution.dart`**: Sealed class (`RuleResolutionFound`, `RuleResolutionMissing`) representing rule resolution results.
  - *Why it exists*: Provides a type-safe, crash-proof result type for rule lookups.
  - *What would break without it*: Callers would either receive null or unhandled exceptions when encountering deleted custom rules or missing profiles.

#### Assets (`assets/rules/`)
- **`assets/rules/index.json`**: Manifest listing registered asset rule JSON filenames.
  - *Why it exists*: Allows `RuleProfileLoader` to discover which profile files to load without reflection or hardcoding filenames in Dart code.
  - *What would break without it*: Flutter has no built-in API to list all files in an asset folder at runtime.
- **`assets/rules/placeholder_example.json`**: The sole placeholder profile (`placeholder_example`), explicitly marked as a placeholder with 100 hours and 100 days.
  - *Why it exists*: Demonstrates and tests profile loading without guessing real state laws.
  - *What would break without it*: The app would have zero standard profiles to load in testing.

#### Data Layer (`lib/data/`)
- **`lib/data/rule_profile_loader.dart`**: Loads, decodes, and validates JSON files from `assets/rules/`.
  - *Why it exists*: Validates that IDs are non-empty and unique, labels exist, numbers are non-negative, at least one target is positive, and dates are valid calendar dates.
  - *What would break without it*: Malformed JSON or invalid targets would enter the domain layer and corrupt pace calculations.
- **`lib/data/rule_resolver.dart`**: Coordinates rule resolution across SQLite custom rules and asset profiles.
  - *Why it exists*: Unifies custom parent goals and standard state profiles under one simple resolution API.
  - *What would break without it*: Every screen or feature would need duplicate if/else logic to fetch custom vs standard rules.
- **`lib/data/providers.dart`**: Riverpod providers for `ruleProfileLoaderProvider`, `ruleProfilesProvider`, `ruleResolverProvider`, and `resolveRuleProvider`.
  - *Why it exists*: Provides reactive dependency injection of loaded profiles and resolver across the app.
  - *What would break without it*: UI widgets would need to manually load assets and pass dependencies through widget constructors.

#### Documentation (`docs/`)
- **`docs/ADDING_A_STATE.md`**: Checklist and technical instructions for researching and adding official state profiles.
  - *Why it exists*: Guides future state research with the rule: *"Never copy from a blog. Use the state education department."*
  - *What would break without it*: Risk of unverified numbers or inaccurate legal claims being introduced into the project.

#### Tests (`test/`)
- **`test/domain/rule_profile_test.dart`**: Unit tests verifying `RuleProfile` instantiation, serialization, equality, and constructor asserts.
- **`test/data/rule_profile_loader_test.dart`**: Unit tests verifying validation rules, error handling, date verification, and resilience against corrupted JSON.
- **`test/data/rule_resolver_test.dart`**: Tests verifying custom rule resolution from SQLite, standard profile resolution, missing rule handling, and real project asset bundle loading.

## Step 4: Progress calculator

In this step, we built the core mathematical calculation engine that computes homeschooling progress against state and custom requirements. The calculator is written as a pure, dependency-free Dart class without screens or database access.

### Key Architectural Concepts (Explained for Students)

1. **Why the calculator is a pure Dart class with no database or clock access**:
   - The progress indicator is the most scrutinized number in the entire app. If it is buggy or flaky, parents lose trust immediately.
   - By keeping `ProgressCalculator` 100% pure (no `DateTime.now()`, no database queries, no Flutter dependencies), the calculation is completely deterministic: identical inputs will *always* produce identical outputs.
   - Passing `today` as an explicit parameter allows us to test past, present, future, leap year, and boundary dates instantly in unit tests without mocking system clocks.

2. **Why date math is normalized to UTC calendar dates**:
   - Local `DateTime` objects carry local timezone offsets and Daylight Saving Time (DST) shifts. In autumn, a day can have 25 hours; in spring, a day has 23 hours.
   - If you subtract local dates with `difference().inDays`, integer division by 24 hours can produce off-by-one errors across DST transitions.
   - By stripping hours/minutes and creating `DateTime.utc(dt.year, dt.month, dt.day)`, every day has exactly 86,400 seconds. Days are counted purely as calendar days:
     `totalSchoolDays = end.difference(start).inDays + 1`.

3. **How integer vs. floating-point math is handled**:
   - `expected = (required * elapsed) / total`.
   - We perform the division using floating-point math to prevent integer truncation, and `.round()` the final result to the nearest integer minute. This keeps all minute values throughout the app as clean integers while avoiding rounding loss.

4. **The 90% Pace Rule**:
   - A child is considered **On pace** if their completed time/days is at least 90% (`kEnoughPaceFactor = 0.90`) of expected time/days:
     `done >= expected * 0.90`.
   - If a rule profile mandates both hours and days, both are computed. If either metric falls below 90%, the overall status is **Behind**.

### Worked Example in Plain Numbers

Imagine a homeschool year with the following parameters:
- **School Year**: September 1, 2026 to June 30, 2027
  - `totalSchoolDays`: 303 calendar days (inclusive of both boundaries).
- **Requirement**: 1,000 hours = 60,000 minutes.
- **Evaluation Date (`today`)**: January 15, 2027
  - `elapsedSchoolDays`: 137 days (September 30 + October 31 + November 30 + December 31 + January 15).
  - `daysRemainingInYear`: 303 - 137 = 166 days.

**Step-by-step calculation**:
1. **Expected Minutes to Date**:
   $$\text{expectedMinutes} = \frac{60,000 \times 137}{303} = 27,128.71 \xrightarrow{\text{round}} 27,129 \text{ minutes } (\approx 452\text{ h } 9\text{ min})$$
2. **Pace Threshold (90%)**:
   $$\text{threshold} = 27,129 \times 0.90 = 24,416.1 \text{ minutes } (\approx 406\text{ h } 56\text{ min})$$
3. **Evaluating Student Performance**:
   - **Scenario A (410 hours logged = 24,600 minutes)**:
     $24,600 \ge 24,416 \implies$ Status is **On pace** (`ProgressStatus.onPace`).
     Percentage completed: $(24,600 / 60,000) \times 100 = 41.0\%$.
   - **Scenario B (400 hours logged = 24,000 minutes)**:
     $24,000 < 24,416 \implies$ Status is **Behind** (`ProgressStatus.behind`).
     Percentage completed: $(24,000 / 60,000) \times 100 = 40.0\%$.

### What was built (File by File)

#### Core Constants (`lib/core/`)
- **`lib/core/constants.dart`**: Added top-level constant `kEnoughPaceFactor = 0.90` and `AppConstants.kEnoughPaceFactor`.
  - *Why it exists*: Centralizes the 90% pace threshold so that no magic numbers are hardcoded in the calculation formula.
  - *What would break without it*: Changing the pace threshold in the future would require hunting for magic numbers in calculation logic.

#### Domain Calculation Engine (`lib/domain/`)
- **`lib/domain/progress_calculator.dart`**: Contains `ProgressStatus` enum, `ProgressResult` immutable data class, and `ProgressCalculator.calculate(...)`.
  - *Why it exists*: Encapsulates all progress math, date-only clamping, leap year handling, and core subject summation into a single pure Dart class.
  - *What would break without it*: Screens and reports would have inconsistent progress and pace calculations, susceptible to timezone and DST glitches.

#### Automated Tests (`test/domain/`)
- **`test/domain/progress_calculator_test.dart`**: Comprehensive test suite covering all 12 edge cases:
  1. 100 required hours, 100-day year, today = day 50 (45.0 h is On pace, 44.9 h is Behind).
  2. Day 1 with 0 hours logged (marks Behind; fairness noted).
  3. Today before the start date (Not started, 0 expected).
  4. Today after the end date (Finished, final percentage shown).
  5. Today equals the end date (final day evaluation).
  6. School year containing February 29 (leap year 2028).
  7. School year crossing year-end (September to June).
  8. DST changes inside the year (result identical to run without DST).
  9. Single-day school year (1 total day, no division by zero).
  10. Days-only rules and mixed hours-and-days rules where one is behind.
  11. Core subjects summation with missing core subjects defaulting to 0.
  12. Invalid date bounds (end before start) returning error result safely.

## Step 5: Setup and settings screens

In this step, we built the initial onboarding and management screens for Homeledger: the one-time legal disclaimer, the add/edit child screen, the subject management screen, the settings screen, and the startup routing gate. We also upgraded the database to schema version 2 to store application settings.

### Key Architectural Concepts (Explained for Students)

1. **Why we created a schema version 2 migration instead of altering version 1**:
   - Once a database schema is published or snapshotted in production (version 1), you cannot go back and rewrite history. If users already have an existing database on their devices, modifying schema v1 code would break existing installations or corrupt their data.
   - Database migrations provide a safe, repeatable path from version $N$ to version $N+1$. When the database engine sees `from < 2`, it executes `migrator.createTable(appSettings)` without altering existing tables, preserving student data, subjects, and logs intact.

2. **Why subjects cannot be deleted when used in log entries**:
   - In homeschooling records, log entries document learning time that actually took place. If a subject (e.g. "Math") is deleted while log entries reference it, foreign keys would either block the deletion or cascade and permanently destroy past learning records.
   - Deleting entries is strictly prevented. Instead, the UI counts active log entries and blocks subject deletion with a clear message: `"This subject is used by X log entries. It cannot be deleted while entries use it."`

3. **Why the Delete Child dialog counts entries and work samples before confirming**:
   - Deleting a child is permanent and cascade-deletes their logs, sample records, and files from disk.
   - To prevent accidental loss of homeschooling portfolios, the confirmation dialog explicitly specifies the child's name and exact counts: `"This will delete X log entries and Y work samples for [Child]. This cannot be undone."`
   - The deletion executes in an atomic database transaction (`deleteChildCascade`) which returns file paths. Physical files are deleted after the database commits, safely ignoring files already missing.

4. **Startup Routing & The Disclaimer Gate**:
   - On first launch, the app displays the legal disclaimer: `"Homeledger helps you keep the records your state asks for. It is a records tool, not legal advice. Check your state's rules with your state education department."`
   - Tapping `"I understand"` records `disclaimer_accepted = true` in the `app_settings` table.
   - If no child profile exists, the app transitions directly to `AddChildScreen(isFirstChild: true)`. Once saved, it transitions to `HomeScreen`.
   - On all future launches, the app skips the disclaimer and routes directly to `HomeScreen` (or `AddChildScreen` if no child exists).

### What was built (File by File)

#### Database & Repositories (`lib/data/`)
- **`lib/data/db/app_database.dart`**: Added `AppSettings` table (`key`, `value`), bumped `schemaVersion` to 2, and implemented `onUpgrade` migration creating `appSettings`.
- **`drift_schemas/drift_schema_v2.json`**: Dumped schema snapshot for version 2.
- **`lib/data/repositories/settings_repository.dart`**: Manages `isDisclaimerAccepted()` and key-value app settings.
- **`lib/data/repositories/subject_repository.dart`**: Added `seedDefaultSubjects()` (seeds Math, Reading, Writing, Science, History, Other on first run if empty), `countLogEntriesForSubject()`, and `reorder()`.
- **`lib/data/repositories/log_repository.dart` & `sample_repository.dart`**: Added `countForChild(childId)` to count records for deletion confirmations.
- **`lib/data/providers.dart`**: Added providers for `settingsRepositoryProvider`, `subjectsStreamProvider`, and `childrenStreamProvider`.

#### UI Screens (`lib/features/` & `lib/app/`)
- **`lib/features/setup/disclaimer_screen.dart`**: One-time disclaimer screen with `"I understand"` button, accessible layout, and persistent database flag.
- **`lib/features/children/add_child_screen.dart`**: Add and edit child form with name validation (max 40 chars), rule picker (lists asset profiles + custom rules), "Make my own rule" dialog (saving custom hours/days), date pickers (using Flutter's `showDatePicker`), and inline validations (end after start, school year <= 400 days).
- **`lib/features/subjects/subjects_screen.dart`**: Curriculum management with automatic default seeding, reordering (`ReorderableListView`), add/rename dialogs, core subject toggle, and deletion protection blocking removal if entries exist.
- **`lib/features/settings/settings_screen.dart`**: Settings dashboard with Children section (add, edit, cascade delete), Subjects link, About (version 1.0.0), Privacy policy placeholder ("Coming soon"), and full Legal Disclaimer card.
- **`lib/features/home/home_screen.dart`**: Minimal landing screen displaying first child's name and `"Open settings"` button.
- **`lib/app/app.dart`**: Configured `AppStartupGate` routing based on disclaimer acceptance and child profile presence.

#### Automated Tests (`test/`)
- **`test/data/migration_test.dart`**: Verifies schema upgrade from v1 to v2, verifying `PRAGMA user_version` bumps to 2, existing v1 data is preserved, and `app_settings` functions.
- **`test/features/disclaimer_widget_test.dart`**: Verifies disclaimer is shown on first launch, tapping "I understand" persists to DB, and restart bypasses disclaimer.
- **`test/features/add_child_widget_test.dart`**: Verifies name validation (empty/length), date validation (end before start, >400 days), custom rule creation, and placeholder example warning.
- **`test/features/subjects_widget_test.dart`**: Verifies first-run subject seeding, deletion blocking when entries exist, and confirmed deletion for unused subjects.
- **`test/features/delete_child_widget_test.dart`**: Verifies cascade delete confirmation dialog content, exact entry/sample counts, database cleanup, and disk file deletion.

## Step 6: Daily log, Home and Progress screens

In this step, we built the core day-to-day screens of Homeledger: the daily log screen, the primary dashboard on Home, and the comprehensive progress screen. These screens wire together the pure domain logic of `ProgressCalculator` (from Step 4), `LogValidator`, Drift database queries, and reactive Riverpod providers.

### Key Architectural Concepts (Explained for Students)

1. **The Core Data Flow (`tap -> validator -> repository -> database -> provider -> screen`)**:
   Every state change in Homeledger follows a strictly unidirectional, reactive path:
   ```mermaid
   graph LR
     A["1. Tap (UI Action)"] --> B["2. LogValidator (Pure Function)"]
     B --> C["3. LogRepository"]
     C --> D["4. SQLite Database (Drift)"]
     D --> E["5. Riverpod Providers (watch)"]
     E --> F["6. Screen (Reactive Rebuild)"]
   ```
   - **Step 1: Tap (`tap`)**: The parent taps a quick button (`+15`, `+30`, `+60` min), submits custom minutes, or edits/deletes an entry.
   - **Step 2: Validation (`validator`)**: `LogValidator.validate(...)` is called. It is a 100% pure Dart function that verifies:
     - Minutes must be $> 0$.
     - Total time for that child and date cannot exceed 24 hours (1440 min) (blocked with a clear error message).
     - Daily total exceeding 10 hours (600 min) triggers a confirmation dialog allowing the parent to confirm past it.
     - Dates cannot be in the future (compared date-only against the injected clock).
     - Notes cannot exceed 200 characters.
   - **Step 3: Repository (`repository`)**: If validation passes (and any warning is confirmed), the UI invokes `logRepo.add()`, `update()`, or `delete()`.
   - **Step 4: Database (`database`)**: Drift writes the change to the `log_entries` SQLite table inside the database file.
   - **Step 5: Provider (`provider`)**: Drift's reactive query stream (`watchForChild`, `watchTotalMinutes`, `watchForDay`) detects the table change and emits new stream events. `childProgressProvider` receives the stream update and recalculates `ProgressCalculator.calculate()` using the injected `clockProvider`.
   - **Step 6: Screen (`screen`)**: Riverpod notifies listeners (`ConsumerWidget` / `ConsumerStatefulWidget`). `HomeScreen`, `LogScreen`, and `ProgressScreen` rebuild automatically with the new pace status, percentages, today's total, and updated entry rows without polling or manual refreshes.

2. **Ultra-Fast Daily Logging UX (1–2 Taps)**:
   - For a homeschooling parent, logging must not be a chore. If logging takes 5 or 6 taps every day, parents stop logging.
   - When opened from Home via the prominent "Log time" button, `LogScreen` automatically restores the child's last used subject (persisted in `app_settings` via `SettingsRepository`).
   - Tapping a quick button (`+15 min`, `+30 min`, `+60 min`) logs the entry immediately.
   - From Home, logging takes exactly **2 taps** (Tap 1: "Log time" -> Tap 2: "+30 min"). Inside the log screen, logging takes **1 tap**.

3. **The Non-Destructive Undo Pattern**:
   - Quick logging adds an entry immediately without asking for extra confirmation. Instead, a SnackBar appears: `"Added 30 min of Math."` with an `"Undo"` action. Tapping Undo removes the entry from the database.
   - Deleting an entry asks nothing (no annoying "Are you sure?" modal), but displays a SnackBar with an `"Undo"` action. Tapping Undo restores the deleted entry with its original timestamp and attributes.

4. **Clock Injection (`clockProvider`)**:
   - `DateTime.now()` is never called directly in screens, models, or repositories (with only the root `clockProvider` definition and `ClockRefresher` interacting directly with system time).
   - The current time is injected via `clockProvider`. In production, this yields the real system time. In automated widget and unit tests, `clockProvider` is overridden with a fixed date (e.g. `DateTime(2026, 9, 15)`), guaranteeing repeatable, deterministic testing independent of time zones, DST changes, or execution time.


5. **No Chart Packages (Plain Flutter Widgets)**:
   - Third-party chart libraries often introduce heavy dependency trees, breaking changes across Flutter SDK versions, and poor accessibility.
   - The progress screen draws horizontal bar charts using plain Flutter widgets (`ClipRRect`, `FractionallySizedBox`, `Container`, and `Row`) styled with Material 3 design tokens. It scales cleanly with system accessibility font scaling and dark mode.

6. **Crash-Proof Missing Rule Resolution**:
   - If a child's rule cannot be resolved (`RuleResolutionMissing`), the app never crashes. Instead, it renders a friendly error card explaining that the rule could not be found, along with a `"Choose a rule"` button navigating to `AddChildScreen` to select or create a profile.

7. **Strict Regulatory Wording**:
   - The status is labeled strictly as `'On pace'`, `'Behind'`, `'Not started'`, or `'Finished'`.
   - The terms `"compliant"`, `"approved"`, and `"guaranteed"` are strictly forbidden.
   - Every progress view displays the required disclaimer: `"Records tool, not legal advice."`

### What was built (File by File)

#### Domain Logic (`lib/domain/`)
- **`lib/domain/log_validator.dart`**: Pure Dart validator for log entries (`validate()`, `LogValidationResult`, `LogValidationAction`). Validates positive minutes, 24h ceiling, 10h warning threshold, non-future dates, and 200-char note limits.
  - *Why it exists*: Encapsulates all validation rules into one testable pure function, avoiding duplicated logic in screens and dialogs.
  - *What would break without it*: Inconsistent validation rules between adding, editing, and quick buttons.

#### Formatters & Utilities (`lib/core/`)
- **`lib/core/formatters.dart`**: Added `formatIsoDate(DateTime dt)` and `formatProgressSummary(minutesDone, requiredMinutes, daysLogged, requiredDays)`.
  - *Why it exists*: Standardizes ISO date strings (`YYYY-MM-DD`) and progress requirement text (`X h Y min of Z h`).

#### Data & Providers (`lib/data/`)
- **`lib/data/repositories/settings_repository.dart`**: Added `getLastUsedSubjectId(childId)` and `setLastUsedSubjectId(childId, subjectId)`.
- **`lib/data/repositories/log_repository.dart`**: Added reactive stream methods: `watchTotalMinutes(childId, from, to)`, `watchMinutesBySubject(childId, from, to)`, `watchDistinctDaysLogged(childId, from, to)`, and `watchForChild(childId)`.
- **`lib/data/providers.dart`**:
  - `clockProvider`: Injected system time provider.
  - `selectedChildIdProvider`: `NotifierProvider` tracking the currently selected student.
  - `todayMinutesProvider`: `StreamProvider.family` watching today's total logged minutes.
  - `weekMinutesProvider`: `StreamProvider.family` watching Monday-to-today logged minutes.
  - `childProgressProvider`: `StreamProvider.family` watching database changes, calculating `ProgressCalculator.calculate()`, and emitting `ChildProgressState`.

#### UI Screens (`lib/features/`)
- **`lib/features/log/log_screen.dart`**: Daily time logger with date picker (future dates blocked), subject chips (persisting last used), quick add buttons (`+15`, `+30`, `+60`), custom minutes input, optional note, 10h warning confirmation, day's entries list, inline edit dialog (`_EditEntryDialog`), and instant Undo on delete and quick-add.
- **`lib/features/home/home_screen.dart`**: Primary parent dashboard with multi-child dropdown selector (hidden if only one child exists), status card (`On pace` / `Behind` / `Not started` / `Finished`, percentage, `X h Y min of Z h`), today's and this week's totals, prominent "Log time" button, shortcuts grid (Progress, disabled placeholders for Samples and Export, Settings), and friendly missing-rule fallback card.
- **`lib/features/progress/progress_screen.dart`**: Academic progress report showing required vs done, expected to date, remaining hours/days, days left in school year, core subjects breakdown, plain Flutter widget bar chart comparing hours per subject, and legal disclaimer: `'Records tool, not legal advice.'`

#### Automated Tests (`test/`)
- **`test/domain/log_validator_test.dart`**: Unit tests verifying:
  - 23 h + 1 h allowed (with 10h warning).
  - 23 h + 61 min blocked (>24h).
  - 10 h warning threshold.
  - Future dates blocked, past and today dates allowed.
  - Zero and negative minutes blocked.
  - Note character limit (200 chars allowed, 201 chars blocked).
- **`test/features/home_and_log_widget_test.dart`**: Widget tests verifying:
  - Quick `+30` adds an entry and Undo removes it.
  - Blocked entry (`>24 h`) shows error message and does not log.
  - Editing an entry updates today's total on Home.
  - Home status changes reactively after logging using a fixed clock (Behind -> On pace).
  - Missing child rule renders friendly card and choose-rule button without crashing.
- **`test/features/progress_widget_test.dart`**: Widget tests verifying:
  - Progress screen displays all metrics, core subjects section, bar chart, and disclaimer.
  - Missing rule error card and choose-rule button render cleanly without crashing.
## Step 7: Work sample capture and sample library

In this step, we built the work sample capture pipeline, the background image processing isolate, relative path storage, the thumbnail library screen with filters, the full-screen pinch-zoom viewer, deletion synchronization, and automatic background orphan cleanup.

### Key Architectural Concepts (Explained for Students)

1. **How the File and Database Row Stay in Sync**:
   A common architectural trap in offline mobile development is having disk files and database rows get out of sync (e.g. creating a row when the image failed to write, or leaving an image on disk when the database transaction failed). We solve this with an **atomic save-with-rollback protocol**:
   ```mermaid
   graph TD
     A["1. Process Image (Isolate)"] --> B["2. Write JPEG to Disk (samples/<childId>/<uuid>.jpg)"]
     B -- File write fails --> C["Abort: Create no DB row"]
     B -- File write succeeds --> D["3. Insert DB Row (SampleRepository)"]
     D -- DB insert succeeds --> E["Success: Image & Row in Sync"]
     D -- DB insert fails --> F["Rollback: Delete newly created file from disk"]
   ```
   - **Step 1 (Process)**: The uncompressed camera/scanner image is processed inside a background isolate (`Isolate.run`), producing a compressed JPEG buffer ($\le 1600$ px longest side, $80\%$ quality).
   - **Step 2 (File first)**: The file is written to the child's private documents directory: `samples/<childId>/<unique_id>.jpg`. If this filesystem write fails, execution aborts and no row is inserted into SQLite.
   - **Step 3 (Row second)**: We insert the metadata row into the `work_samples` SQLite table.
   - **Rollback on failure**: If the database insert throws an exception (e.g., constraint error, database lock), `SampleStorageService` catches the error, deletes the written file from disk immediately, and rethrows the error to the caller. No orphan file is left behind.

2. **Why Paths are Stored as RELATIVE Paths in SQLite**:
   - In mobile operating systems (especially Android and iOS), the absolute path to an application's internal files directory (e.g., `/data/user/0/com.homeledger.app/app_flutter/` or `/var/mobile/Containers/Data/Application/<UUID>/Documents/`) contains application package names or dynamically generated installation UUIDs.
   - If an absolute path like `/data/user/0/com.homeledger.app/app_flutter/samples/1/abc.jpg` were stored in SQLite:
     1. Restoring a database backup on a different device (or after an app re-install) would completely break all image links because the installation path prefix would differ.
     2. OS version upgrades or container migrations could invalidate hardcoded paths.
   - By storing only the relative path `samples/<childId>/<unique_id>.jpg` in SQLite, the app dynamically prepends the device's current `getApplicationDocumentsDirectory()` at runtime. Backups, restores, and cross-device migrations remain 100% resilient.

3. **Background Image Processing with `Isolate.run`**:
   - Camera and document scanner photos from modern smartphones frequently exceed 12 to 50 megapixels (e.g. 4000x3000 px). Decoding and downscaling such high-resolution images can take several hundred milliseconds to a full second of heavy CPU compute.
   - If image decoding and resizing ran on Flutter's main UI thread, animations would freeze, buttons would stutter, and Android might trigger an ANR (Application Not Responding) warning.
   - Using `Isolate.run(() => ImageProcessor.processImageBytes(...))`, Flutter spawns a separate worker isolate on a background CPU core. The main UI thread remains completely responsive at 60/120 fps while the image is decoded, oriented via EXIF, downscaled to $\le 1600$ px, and compressed to $\sim 80\%$ JPEG.
   - The original multi-megabyte image is discarded immediately and never written to permanent storage. Only the compact, resized JPEG ($\sim 150 - 400\text{ KB}$) is saved.

4. **Multi-Stage Capture Fallback Architecture**:
   - The primary capture mechanism uses the Google Play services ML Kit Document Scanner (`google_mlkit_document_scanner`), which provides automatic page edge detection, perspective transformation, shadow removal, and cropping.
   - However, some Android devices lack Google Play services (e.g., de-Googled devices, certain custom ROMs, or emulator images), or the Play services module might not be downloaded yet.
   - We designed `SampleCaptureService` using an injectable client architecture (`DocumentScannerClient` and `ImagePickerClient`):
     1. **Attempt 1**: Try ML Kit Document Scanner.
     2. **Attempt 2 (Fallback)**: If the scanner is unavailable or throws, catch the error, show a brief notice explaining that the camera is being used instead, and open the camera via `ImagePicker`.
     3. **Attempt 3 (Fallback)**: If the camera is unavailable or throws, fall back to the system photo gallery.
     4. If the user cancels at any stage, the process ends cleanly without falling back further.

5. **Why No Storage Permissions are Needed (and why CAMERA is the only permission)**:
   - Modern Android (API 29+) enforces **Scoped Storage**. Apps have unrestricted, private access to their own sandboxed directories (`context.getFilesDir()` / `context.getDataDir()`) without requesting `READ_EXTERNAL_STORAGE` or `WRITE_EXTERNAL_STORAGE`.
   - Work sample files are stored strictly inside the app's private documents directory (`getApplicationDocumentsDirectory()`), which is inaccessible to other apps and requires zero runtime permissions.
   - When picking images from the device gallery via `image_picker`, modern Android utilizes the system Photo Picker or `ACTION_GET_CONTENT`, where user selection delegates access through system intents without requiring broad storage permissions.
   - The only permission declared is `<uses-permission android:name="android.permission.CAMERA" />` in `AndroidManifest.xml`, which allows direct photo capture via `image_picker` on camera hardware.

6. **Automatic Background Orphan Cleanup**:
   - On app startup inside `AppStartupGate`, `runOrphanCleanup()` executes asynchronously in the background:
     - **Orphan Files**: Scans the `samples/` directory on disk. If any file exists that does not correspond to an active row in the `work_samples` SQLite table, it is safely deleted from disk to free storage space.
     - **Missing Files**: If a database row points to a file that was deleted (or failed to restore from backup), the row is **preserved** to maintain homeschooling record integrity. In the UI, the thumbnail and viewer detect the missing file and render a clean `"File missing from device"` placeholder card rather than crashing.

### What was built (File by File)

#### Core & Domain (`lib/core/` & `lib/domain/`)
- **`lib/core/formatters.dart`**: Added `formatDisplayDate(DateTime dt)` for user-friendly calendar display (e.g. `'Jan 15, 2027'`).
- **`lib/domain/image_processor.dart`**: Pure image manipulation module:
  - `processImageBytes(bytes)`: Decodes image, bakes EXIF orientation (`bakeOrientation`), resizes keeping aspect ratio so the longest side is at most 1600 px, and encodes to JPEG at 80% quality. Small images are not enlarged.
  - `processImageInBackground(bytes)`: Wraps `processImageBytes` in `Isolate.run` to guarantee the main thread never blocks.

#### Storage & Capture Services (`lib/services/`)
- **`lib/services/sample_storage_service.dart`**: Manages disk files and SQLite synchronization:
  - `saveSample(...)`: Generates unique filename `samples/<childId>/sample_<timestamp>_<uuid>.jpg`, writes processed bytes to disk, inserts database row via `SampleRepository`. If insert fails, rolls back and deletes the file.
  - `deleteSample(...)`: Atomically deletes row and disk file. If the file is already missing on disk, it still deletes the row.
  - `resolveAbsolutePath(relativePath)`: Prepend app documents directory to stored relative path.
  - `runOrphanCleanup()`: Startup cleaner that deletes unindexed files and tracks missing files.
- **`lib/services/sample_capture_service.dart`**: Fallback capture orchestrator:
  - Interfaces `DocumentScannerClient` and `ImagePickerClient` for clean testability and mocking.
  - `captureWorkSample()`: Implements Document Scanner $\to$ Camera $\to$ Gallery fallback logic and records the capture method used.

#### Data Layer Updates (`lib/data/`)
- **`lib/data/repositories/sample_repository.dart`**:
  - `watchForChildFiltered(childId, filter)`: Reactive stream querying samples for a child with optional subject filtering and date range filtering, ordered newest first (`createdAt DESC`).
  - `countForChild(childId)`: Fast count query for deletion confirmations.
  - `getAll()`: Query returning all work sample rows across all children for orphan cleanup.
- **`lib/data/providers.dart`**:
  - `sampleStorageServiceProvider`: Injects `SampleStorageService`.
  - `sampleCaptureServiceProvider`: Injects `SampleCaptureService`.
  - `workSamplesFilterProvider`: Tracks active filter state (subject ID, date range).
  - `childWorkSamplesProvider`: Watches filtered work samples for the selected child.

#### UI Screens (`lib/features/samples/`)
- **`lib/features/samples/sample_capture_screen.dart`**:
  - Renders method badge showing capture source (Document Scanner, Camera, or Photo Gallery).
  - Image preview, subject selector dropdown, date picker (default today, future dates blocked), optional title field (enforced max 60 characters).
  - Asynchronously processes image in background isolate and saves via `SampleStorageService`.
- **`lib/features/samples/sample_library_screen.dart`**:
  - Grid of sample thumbnails sorted newest first.
  - Subject filter chips and date range filter chip.
  - Broken file placeholder if file is missing from disk.
  - "Scan work" FloatingActionButton and AppBar action.
- **`lib/features/samples/sample_viewer_screen.dart`**:
  - Full-screen `InteractiveViewer` with pinch-to-zoom and pan.
  - Metadata overlay bar showing title, date, and subject.
  - Delete button with confirmation dialog.
- **`lib/features/home/home_screen.dart`**:
  - Activated "Samples" shortcut card on the home dashboard to navigate directly to `SampleLibraryScreen`.
- **`lib/app/app.dart`**:
  - Integrated `runOrphanCleanup()` in `AppStartupGate` to run automatically in the background on startup.

#### Automated Tests (`test/`)
- **`test/domain/image_processor_test.dart`**:
  - Landscape image (4000x3000) resized to 1600x1200 at 80% JPEG quality.
  - Portrait image (3000x4000) resized to 1200x1600.
  - Small image (800x600) is NOT enlarged.
  - Invalid bytes throw `FormatException`.
- **`test/services/sample_storage_service_test.dart`**:
  - Relative path storage verified (relative path saved in DB, resolvable to absolute path).
  - Delete removes both file from disk and row from database.
  - Delete with already missing file still deletes the database row cleanly.
  - Failed database row insert rolls back and deletes the physical file.
  - Orphan cleanup deletes unindexed files on disk and preserves rows with missing files.
- **`test/services/sample_capture_service_test.dart`**:
  - Scanner success path.
  - Scanner user cancellation.
  - Scanner throws/unavailable $\to$ fallback to camera.
  - Camera user cancellation.
  - Camera throws $\to$ fallback to gallery.
  - All sources throwing handled gracefully.
- **`test/features/samples_widget_test.dart`**:
  - Empty state renders cleanly when child has no work samples.
  - Thumbnails rendered in grid and sorted newest first.
  - Subject chip filter filters grid items.
  - Missing file on disk displays "File missing" placeholder card in grid.
  - Capture form displays method badge, enforces title limit, and saves successfully.
  - Full-screen viewer supports pinch zoom and confirms deletion before deleting file and row.
  - Full-screen viewer displays "File missing from device" message if image was removed.
  - HomeScreen "Samples" shortcut navigates to `SampleLibraryScreen`.

## Step 8: PDF portfolio export

In this step, we built the complete PDF portfolio export feature. The portfolio compiles attendance, subject hours, progress tracking, daily learning logs, and student work samples into an offline document. In this step, export is unlocked (the paywall comes in Step 10).

### Key Architectural Concepts (Explained for Students)

1. **Why the PDF is built in a background isolate (`Isolate.run`)**:
   - PDF document generation involves computing complex layouts, table cell pagination, font glyph mapping, and parsing image bytes. If this work ran on Flutter's main UI thread, it would freeze the screen for several seconds ("jank"), dropping 60fps frame rates and triggering Android "Application Not Responding" (ANR) warnings.
   - By fetching all data from the database on the main thread and passing plain Dart data objects (`PortfolioExportData`) across the isolate boundary to `buildPortfolioPdf` in `Isolate.run`, the UI thread remains completely responsive with a smooth spinning progress indicator.

2. **The Data Flow: From Database to PDF**:
   ```
   [SQLite Database (Drift)]
       │
       ├─► Child & Rule profile (RuleResolver)
       ├─► Aggregated subject minutes (LogRepository.minutesBySubject)
       ├─► Distinct days logged (LogRepository.distinctDaysLogged)
       ├─► Daily log entries sorted chronologically (LogRepository.getForChildDateRange)
       ├─► Work sample paths & metadata (SampleRepository.listForChild)
       └─► Optional parent name (SettingsRepository.getParentName)
       │
   [Main Isolate: ExportService.prepareExportData]
       │  • Executes ProgressCalculator.calculate(...) pure domain math
       │  • Loads bundled Noto Sans TrueType font assets
       │  • Compiles plain DTO: PortfolioExportData
       │
   [Isolate Boundary: Isolate.run()]
       │
   [Background Isolate: buildPortfolioPdf]
       │  • Page 1: Cover Page
       │  • Page 2: Hours & Progress Summary
       │  • Section 3: Daily Log Multi-Page Table (repeating headers)
       │  • Section 4: Work Samples (streaming image files one-at-a-time)
       │  • Footer: Legal disclaimer & Page X of Y on EVERY page
       │
   [Returns: Raw Uint8List PDF bytes]
       │
   [Main Isolate: File System & System Share Sheet]
       │  • Saves to cache/temp directory as homeledger-<child>-<start>-to-<end>.pdf
       └─► Opens Android Share Sheet via share_plus (Save, Print, or Email)
   ```

3. **Memory Safety: Streaming Images One-by-One**:
   - Modern phone cameras produce high-resolution pictures. Loading 50 full-sized sample images into memory simultaneously before generating the PDF would require hundreds of megabytes of RAM, risking an immediate Out-Of-Memory (OOM) crash.
   - We avoid this in two ways:
     1. In Step 7, work samples were already pre-resized on capture to a standard 1600x1200 JPEG.
     2. In `PortfolioExportData`, we pass only file path strings across the isolate boundary. The PDF builder reads and embeds images one at a time inside the sample loop (`File(sample.absoluteFilePath).readAsBytesSync()`). Only one image buffer resides in memory at any given instant.

4. **Bundled Open-License Fonts (Noto Sans)**:
   - Default PDF fonts (like Helvetica) lack Unicode support for accented characters (e.g. `ë`, `ñ`, `é`, `ü`) and throw exceptions or render question marks when a child or parent has an accented name (e.g. "Zoë Noël", "José Müller").
   - We bundle Google's `NotoSans-Regular.ttf` and `NotoSans-Bold.ttf` under the SIL Open Font License 1.1 in `assets/fonts/` and register them with package `pdf`. This ensures accurate, non-crashing typographical rendering.

5. **Footer & Neutral Tone Requirements**:
   - The PDF document never makes legal claims or statements such as "compliant", "approved", "guaranteed", "certified", or "accepted by".
   - Every single page includes the exact mandated footer:
     `'Created with Homeledger. Records tool, not legal advice. Based only on entries made by the parent.'` along with dynamic `'Page X of Y'` page numbering.

### What was built (File by File)

#### Database & Settings Migration (`lib/data/`)
- **`lib/data/db/app_database.dart`**: Bumped `schemaVersion = 3` and added migration step for version 3.
- **`drift_schemas/drift_schema_v3.json`**: Dumped official drift schema version 3 snapshot.
- **`lib/data/repositories/settings_repository.dart`**: Added `getParentName()`, `setParentName(String?)`, and `watchParentName()` to store and watch the optional parent name under settings key `'parent_name'`.
- **`lib/features/settings/settings_screen.dart`**: Added "Parent name (optional)" tile with an edit dialog.

#### Export Data Transfer Model (`lib/features/export/export_data_model.dart`)
- **`SubjectHoursSummary`**: Subject name, core flag, total minutes.
- **`LogItemSummary`**: Date (`YYYY-MM-DD`), subject name, minutes, and optional note.
- **`WorkSampleExportItem`**: Title, subject name, date, absolute file path, and `isMissing` flag.
- **`PortfolioProgressData`**: Required hours/days, minutes done, days logged, expected progress, and status label ('On pace' or 'Behind').
- **`PortfolioExportData`**: Complete root data packet bundling all metadata, child details, reporting period, fonts, summaries, and entries.

#### PDF Generation Engine (`lib/features/export/pdf_portfolio_builder.dart`)
- **`buildPortfolioPdf(PortfolioExportData data)`**: Pure PDF generation engine running inside a background isolate.
  - **Cover Page**: Title `'Homeschool Portfolio'`, child name, school year, reporting period, rule label (with source URL and date checked if present), date created, and optional parent name.
  - **Summary Section**: Progress summary cards with 'On pace' or 'Behind' wording; Hours by Subject table with totals in hours and minutes (`formatMinutes`). Shows `'No entries yet'` if empty.
  - **Daily Log Table**: `pw.TableHelper.fromTextArray` paginated across pages with `maxPages: 1000` and repeated table header on every page break.
  - **Work Samples Section**: Each sample on its own page with title, subject, date, and image scaled to fit (`pw.FittedBox`). If a file is missing from disk, renders a clean placeholder row: `[Image file could not be found: ...]`.
  - **Persistent Footer**: Exposes `kPdfFooterText` and renders on every page using `pw.MultiPage(footer: buildFooter)`.

#### Coordination Service (`lib/features/export/export_service.dart`)
- **`sanitizePdfFileName`**: Cleans child name and date boundaries into safe filename `homeledger-<child>-<start>-to-<end>.pdf`.
- **`PdfShareClient` & `SharePlusPdfShareClient`**: Clean abstraction over `share_plus` to open Android system share sheet.
- **`ExportService`**: Reads repositories on the main isolate, computes progress using `ProgressCalculator.calculate`, dispatches PDF generation to `Isolate.run`, saves bytes to temp cache, and opens the share sheet.

#### Export Options UI (`lib/features/export/export_options_screen.dart`)
- Student dropdown (for multiple children).
- Reporting period date picker (defaults to full school year).
- "Include work samples" switch toggle.
- "Create PDF" button showing in-button progress indicator (`CircularProgressIndicator` and `'Creating PDF...'`) while generation runs in the background.

#### Automated Tests (`test/`)
- **`test/features/export/forbidden_words_test.dart`**: Scans all source code in `lib/features/export/` to ensure zero occurrences of forbidden words (`compliant`, `approved`, `guaranteed`, `certified`, `accepted by`).
- **`test/features/export/file_name_sanitizer_test.dart`**: Tests filename sanitizing for special characters, spaces, accents, and boundary cases.
- **`test/features/export/export_data_model_test.dart`**: Tests data aggregation, inclusive boundary date queries, empty child handling, parent name presence, and missing sample detection.
- **`test/features/export/pdf_generation_test.dart`**: Tests pure PDF byte generation for empty child (`No entries yet`), child with entries, accented names with Noto Sans, missing file placeholders, 50-samples memory safety test in isolate, and 1,000-entry log pagination.
- **`test/features/export/export_options_screen_test.dart`**: Widget tests for empty child state, date range defaults, toggle switches, and progress indicator state transitions on "Create PDF".

## Step 9: Manual backup and restore

In this step, we built the manual backup and restore subsystem. Because Homeledger has no central server or cloud database, the phone is the single source of truth. If a phone is lost or damaged, a recent backup is the parent's only safety net. Conversely, restore is the most dangerous operation in the application because restoring an invalid, corrupted, or malicious file could wipe good homeschooling records. Therefore, backup and restore are built with strict validation, background isolates, path traversal security, and an atomic safe-swap mechanism with automatic rollback.

Backup and restore are part of the **FREE plan** and will never be locked behind a paywall.

### Plain-English Picture: The Safe-Swap Restore Order

Why does the restore process follow this exact multi-stage sequence?

```
[User selects ZIP via file_picker]
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Unpack to Isolated Temporary Folder                      │
│    • Never unzips over live data                            │
│    • Rejects zip bombs (> 2 GB zip or > 4 GB unpacked)      │
│    • Rejects path traversal (e.g. "../../etc/passwd")       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Deep Validation (Before touching live state)             │
│    • Verify manifest.json exists and parses                 │
│    • Verify homeledger.sqlite exists                        │
│    • Schema check: schemaVersion <= App schema (3)          │
│      (Refuse newer versions with exact update prompt)       │
│    • Read-only PRAGMA integrity_check on the database       │
│    • Verify sample images on disk (track missing files)     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Confirmation Dialog with Summary                         │
│    • Warn: "This replaces all data on this phone."          │
│    • Plain summary: Child, entry, and sample counts         │
│    • User explicitly approves or cancels                    │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Confirmed)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. ATOMIC SAFE-SWAP ORDER                                   │
│                                                             │
│    (a) Close live Drift SQLite connection                   │
│    (b) Move current database & samples to safety/ folder    │
│    (c) Move unzipped database & samples into live paths     │
│    (d) Re-open Drift SQLite connection                      │
│    (e) Run SQLite migrations if backup is an older schema   │
│                                                             │
│    ┌───────────────────┬───────────────────┐                │
│    │ IF SUCCESSFUL:    │ IF ANY ERROR:     │                │
│    │ Delete safety/    │ Restore safety/   │                │
│    │ folder permanently│ back to live paths│                │
│    │                   │ Reopen live DB    │                │
│    │                   │ Throw readable err│                │
│    └───────────────────┴───────────────────┘                │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Reactive UI Invalidation                                 │
│    • Invalidate Riverpod providers (DB, children, entries)  │
│    • Screens instantly re-render with restored state        │
└─────────────────────────────────────────────────────────────┘
```

#### Why each step exists:
1. **Unzip into a separate temporary directory first**:
   - If a zip is corrupted or truncated, the unzipper will fail halfway through. If we unzipped directly into live app directories, half the existing database or files would be overwritten and destroyed before the corruption was detected.
2. **Path traversal sanitization (`../../evil`)**:
   - Malicious or malformed zip archives can contain paths targeting parent directories. If unzipped naively, entries could overwrite critical app files or escape the app sandbox. Every zip entry path is checked to guarantee that its canonical destination lies strictly inside the target sandbox directory.
3. **Pre-flight integrity and schema checks**:
   - Opening SQLite with `PRAGMA integrity_check;` catches disk corruption, bit rot, or invalid non-SQLite files without endangering live application memory.
   - Refusing backups from newer app versions prevents crashes caused by unrecognized future database tables or columns.
4. **The `safety/` folder fallback**:
   - Renaming/moving directories is near-instantaneous on the filesystem. By closing the database and moving live files into a safety folder before moving new files in, we ensure that if anything fails (e.g. out-of-storage condition while copying samples, or a schema migration failure), the safety folder is moved right back into place. Live data is safely preserved.
5. **Provider invalidation**:
   - In Riverpod, cached database queries and streams must be refreshed (`ref.invalidate(...)`) so that all widgets immediately show the newly restored student profiles, daily logs, and work sample galleries.

---

### Key Architectural Concepts (Explained for Students)

1. **Why `file_picker` is needed**:
   - Android's Scoped Storage protects user privacy by isolating app storage. When a parent wants to restore a backup zip that was saved in Google Drive, emailed, downloaded, or copied onto the phone's SD card, Homeledger has no direct permission to browse the filesystem. `file_picker` launches Android's native Storage Access Framework (SAF) system picker, allowing the parent to select the file securely and returning a temporary readable file path to our app.

2. **Consistent Database Copying with `VACUUM INTO`**:
   - SQLite uses Write-Ahead Logging (WAL). In WAL mode, recent database writes sit in a `-wal` companion file and haven't yet been flushed into the main `.sqlite` file. Simply copying `homeledger.sqlite` with `File.copy()` would produce a "half-written" or corrupted copy missing recent changes.
   - We execute SQLite 3.27+'s native command: `VACUUM INTO 'target_copy.sqlite';`. This checkpoints all active WAL transactions and atomically writes a clean, independent, non-WAL SQLite database snapshot file.

3. **Background Isolate Archiving (`Isolate.run`)**:
   - Zipping and unzipping hundreds of megabytes of photos and SQLite data is CPU-heavy. Running compression on the main UI thread would freeze the app and cause frame drops.
   - We run `ZipFileEncoder` and `ZipDecoder` in background isolates via `Isolate.run()`. Inside the isolate, we use synchronous file addition (`addFileSync`, `addDirectorySync`, `closeSync`) to ensure all streams flush completely before the isolate terminates.

4. **Backup Archive File Layout**:
   ```
   homeledger-backup-2026-10-20-1430.zip
   ├── manifest.json
   ├── homeledger.sqlite
   └── samples/
       ├── 1/
       │   └── sample_1700000000000_uuid.jpg
       └── 2/
           └── sample_1700000001000_uuid.jpg
   ```

5. **`manifest.json` Specification**:
   ```json
   {
     "schemaVersion": 3,
     "appVersion": "1.0.0",
     "createdAt": "2026-10-20T14:30:00.000Z",
     "counts": {
       "children": 1,
       "entries": 42,
       "samples": 6
     }
   }
   ```

6. **Gentle Backup Reminder**:
   - If 30 days have elapsed since the last backup (or since the first student was created if no backup has ever been made), a gentle dismissible `BackupReminderCard` appears at the top of the Home dashboard. Dismissing records the date in settings and suppresses the reminder for another 30 days.

---

### What was built (File by File)

#### Core & Backup Engine (`lib/features/backup/`)
- **`lib/features/backup/backup_manifest.dart`**:
  - `BackupManifest` and `BackupCounts` models with `toMap()`, `fromMap()`, `toRawJson()`, and `fromRawJson()`.
- **`lib/features/backup/backup_exceptions.dart`**:
  - Specialized, user-readable exceptions: `BackupCorruptedException`, `BackupInvalidBackupException`, `BackupNewerVersionException`, `BackupIntegrityCheckFailedException`, `BackupSecurityException`, and `BackupTooLargeException`.
- **`lib/features/backup/backup_clients.dart`**:
  - `BackupShareClient` / `SharePlusBackupShareClient`: Wraps `SharePlus` to open the native share sheet.
  - `FilePickerClient` / `SystemFilePickerClient`: Wraps `FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip'])`.
- **`lib/features/backup/backup_service.dart`**:
  - `createBackup()`: Atomic SQLite snapshot via `VACUUM INTO`, collects metadata counts, writes `manifest.json`, archives in background isolate, and opens system share sheet.
  - `pickAndValidateBackup()`: File picker invocation and validation pipeline.
  - `validateBackup(File zipFile)`: Checks zip header, guards against path traversal and oversized archives, verifies manifest, executes read-only `PRAGMA integrity_check;`, checks sample files.
  - `performRestore(summary)`: Executes safe-swap transaction with rollback on failure.
- **`lib/features/backup/backup_reminder_card.dart`**:
  - Card widget with gentle message, "Back up now" button, and "Dismiss" button.

#### Data Layer Updates (`lib/data/`)
- **`lib/data/repositories/child_repository.dart`**: Added `countAll()` using SQL `COUNT(id)`.
- **`lib/data/repositories/log_repository.dart`**: Added `countAll()` using SQL `COUNT(id)`.
- **`lib/data/repositories/sample_repository.dart`**: Added `countAll()` using SQL `COUNT(id)`.
- **`lib/data/repositories/settings_repository.dart`**: Added methods for `last_backup_date` and `backup_reminder_dismissed_date`.
- **`lib/data/providers.dart`**: Injected `backupServiceProvider`, `backupShareClientProvider`, `filePickerClientProvider`, `lastBackupDateStreamProvider`, and `shouldShowBackupReminderProvider`.

#### UI Integration (`lib/features/settings/` & `lib/features/home/`)
- **`lib/features/settings/settings_screen.dart`**:
  - "Backup & restore" section (Free plan - never locked).
  - "Back up now" with last backup date display (`Last backup: <date>` or `Never`) and loading indicator.
  - "Restore from backup" with warning `"This replaces all data on this phone."`, pre-restore summary modal, and reactive provider invalidation.
- **`lib/features/home/home_screen.dart`**:
  - Integrated `BackupReminderCard` at top of Home view, conditionally rendered by `shouldShowBackupReminderProvider`.

#### Architecture Decisions (`docs/DECISIONS.md`)
- Added architectural note proposing optional password-based AES-256 backup encryption for future consideration.

#### Automated Tests (`test/features/backup/`)
- **`test/features/backup/forbidden_words_test.dart`**: Verifies 0 regulatory forbidden words in `lib/features/backup/`.
- **`test/features/backup/backup_service_test.dart`**:
  1. `backup then restore gives identical rows`: End-to-end round trip test verifying exact restoration of children, log entries, and work sample files.
  2. `manifest counts match`: Verifies child, log entry, and sample counts in `manifest.json`.
  3. `a zip without a manifest is rejected`: Rejects archive missing manifest.
  4. `a newer schemaVersion is refused with exact update message`: Rejects future schema with exact string `'This backup is from a newer version of Homeledger. Please update the app.'`.
  5. `a corrupted zip is rejected and live data is untouched`: Corrupted archive fails validation; live database untouched.
  6. `a path traversal zip is rejected`: Rejects zip containing `../../outside.txt` without writing files outside target folder.
  7. `a restore that fails midway puts the old data back`: Verifies atomic rollback from `safety/` folder when reopening restored database fails.
  8. `an older-schema backup is migrated upon restore`: Restores a v1 backup into v3 app and confirms migrations execute successfully.
- **`test/features/backup/backup_ui_test.dart`**:
  - Displays "Last backup: Never" initially.
  - Displays formatted date when a backup exists.
  - Confirmation dialog renders warning, summary stats, missing sample note, and handles cancel.
  - Backup reminder card renders on Home and dismisses cleanly.

---

## Step 10: Free vs Paid Plan, Feature Gating, Paywall Screen, and Release Hardening

In this step, we built the monetization and feature gating architecture around the fundamental promise that a parent's records belong to them and are never deleted or hidden upon expiration. We created the domain entitlement model, fake entitlement service, central feature policy, paywall screen, developer simulation tools, and completed comprehensive pre-release hardening audits.

### Key Architectural Concepts (Explained for Students)

#### 1. Why Billing is Fake (Decoupling Billing from Business Logic)
Integrating real billing SDKs (like Google Play Billing via `in_app_purchase`) introduces third-party network dependencies, store credentials, and platform lifecycles that cannot be tested offline. By abstracting entitlement state behind a clean interface (`EntitlementService`), the app defines what a subscription means in pure domain terms. When Google Play Console is configured in the future, only a real `GooglePlayEntitlementService` needs to be implemented—the UI, central policy, database, and feature locks remain 100% unchanged.

#### 2. The 7-Day Offline Grace Period
Parents may homeschool in remote areas or use devices without continuous internet access. If `paidUntil` expires while the device is offline, `isPaid(...)` checks if `now` is within `kEntitlementGraceDays` (7 days) of `lastVerifiedAt`. If so, access remains active to avoid punishing offline paying customers.

#### 3. Central Policy Gate (`canUse`)
A common architectural anti-pattern is scattering `if (plan == 'paid')` checks throughout UI screens. Homeledger forbids this. All gating logic flows through a single pure function: `canUse(Feature feature, EntitlementState state, DateTime now)`. Screens simply ask "Can this feature be used right now?" and receive `FeatureAccess.allowed` or `FeatureAccess.locked`.

#### 4. The Lapse Guarantee (Multi-Child Preservation)
If a parent subscribes to Homeledger Plus, adds two children, and later cancels or lapses their subscription:
- Neither child is deleted or hidden.
- The parent can switch between both children, view past logs, edit past entries, add new daily learning logs, and back up all data.
- Only paid actions (exporting PDF portfolios, scanning work samples, or creating a *third* child) are locked.

---

### What Was Built

#### 1. Core Constants (`lib/core/constants.dart`)
- **`kEntitlementGraceDays = 7;`**: Mandated duration during which offline expired subscriptions remain temporarily active.
- **`kYearlySubscriptionPriceText = r'US$39.99 per year';`**: Single source of truth for subscription pricing text across the UI.

#### 2. Domain Models (`lib/domain/`)
- **`lib/domain/entitlement.dart`**:
  - `enum EntitlementPlan { free, paid }`: Core subscription tiers.
  - `class EntitlementState`: Holds current plan, `paidUntil`, and `lastVerifiedAt`.
  - `bool isPaid(DateTime now, DateTime? paidUntil, DateTime? lastVerifiedAt, int graceDays)`: Pure function evaluating paid status with 7-day offline grace period.
- **`lib/domain/feature_policy.dart`**:
  - `enum Feature`: Defines `logging`, `progress`, `backup`, `restore`, `exportPdf`, `scanSample`, `viewSamples`, `secondChild`.
  - `enum FeatureAccess { allowed, locked }`: Access decision outcome.
  - `FeatureAccess canUse(Feature feature, EntitlementState entitlement, DateTime now)`: Central policy determining access for any feature. Free features (`logging`, `progress`, `backup`, `restore`, `viewSamples`) always return `allowed`.

#### 3. Services & Repositories (`lib/services/` & `lib/data/`)
- **`lib/services/entitlement_service.dart`**:
  - `EntitlementService`: Interface defining `current()`, `changes`, `purchaseYearly()`, and `restorePurchases()`.
  - `FakeEntitlementService`: Concrete implementation storing subscription state in the SQLite `entitlements` table. Provides simulation helpers: `setFree()`, `setPaidForOneYear()`, and `setPaidExpiredDaysAgo(days)`.
- **`lib/data/providers.dart`**:
  - `entitlementServiceProvider`: Injects the entitlement service instance.
  - `entitlementStateStreamProvider`: Reactively watches subscription changes.
  - `featureAccessProvider(Feature)`: Exposes current feature access (`allowed` vs `locked`) to the UI.

#### 4. UI Implementation (`lib/features/`)
- **`lib/features/paywall/paywall_screen.dart`**:
  - Clear list of benefits: PDF portfolios, work sample camera scanning, and multiple children.
  - Transparent price display: `'US$39.99 per year'`.
  - Mandated disclosures:
    - `"Renews automatically every year until cancelled. Cancel any time in Google Play."`
    - `"Your records always stay yours. If you stop subscribing, nothing is deleted."`
  - Action buttons: "Subscribe now" and "Restore purchase", which call `FakeEntitlementService`.
  - Placeholder links for Terms of Service and Privacy Policy that show friendly SnackBar placeholders without network access.
- **`lib/features/debug/debug_entitlement_screen.dart`**:
  - Protected by `kDebugMode` to ensure it is completely stripped / inaccessible in release builds.
  - Provides quick simulation buttons: Free Plan, Paid (1 Year), Expired 3 days ago (Grace Period), Expired 10 days ago (Lapsed).
- **`lib/features/home/home_screen.dart`**:
  - Export shortcut button displays a lock icon when locked and navigates to `PaywallScreen` upon tapping.
- **`lib/features/samples/sample_library_screen.dart`**:
  - Scan work FAB, App bar action, and empty state button show lock indicators and navigate to `PaywallScreen` when locked. Existing sample viewing remains completely free.
- **`lib/features/export/export_options_screen.dart`**:
  - Create PDF button reflects `(Plus)` marker and opens Paywall if locked.
- **`lib/features/settings/settings_screen.dart`**:
  - "Add child" displays `(Plus)` and opens Paywall when 1 or more children already exist on the free plan.
  - Includes developer options tile (gated strictly by `kDebugMode`).
- **`lib/features/children/add_child_screen.dart`**:
  - Validates `canUse(Feature.secondChild)` upon submission to prevent bypassing the gate.

---

### Hardening & Verification Audits

1. **Zero Network Activity**:
   - Grepped `lib/` for `http`, `dio`, `HttpClient`, `Socket`, `url_launcher`, analytics, and Firebase. Confirmed 0 matches.
2. **Android Cloud Backup Disabled**:
   - Confirmed `android:allowBackup="false"` in `android/app/src/main/AndroidManifest.xml`.
3. **Minimal Permissions**:
   - Release manifest requests strictly `android.permission.CAMERA` for the document scanner. No Internet, storage, or location permissions.
4. **No Forbidden Regulatory Words**:
   - Verified 0 occurrences of `'compliant'`, `'approved'`, `'guaranteed'`, or `'certified'` in user-facing code and assets.
5. **Accessibility Text Scaling (200%)**:
   - Automated widget tests verified clean rendering at 2.0x text scale without RenderFlex overflows on Home, Log, and Paywall views.
6. **Dark Mode & Empty States**:
   - Verified high-contrast dark theme rendering and clean 0-item empty states for Home, Log, Samples, and Settings.
7. **Second Child Data Isolation**:
   - Dedicated unit test confirmed logging time for Child A never mutates or affects Child B's totals, rule profile, or school year.

---

### Automated Test Suite (`test/`)
- **`test/domain/entitlement_test.dart`**: 11 unit tests covering active subscriptions, expiration within 7-day grace period, expiration past grace period, and boundary dates.
- **`test/domain/feature_policy_test.dart`**: 9 unit tests verifying access matrix across free, paid, grace period, and lapsed states.
- **`test/features/paywall/paywall_screen_test.dart`**: Widget tests verifying benefits, pricing constants, legal disclosures, subscribe/restore flows, and offline link placeholders.
- **`test/features/paywall/feature_locking_test.dart`**: End-to-end feature gating tests verifying Export, Scan, Add Child locks, and the multi-child lapse rule.
- **`test/features/children/second_child_isolation_test.dart`**: Data isolation test verifying zero cross-talk between children.
- **`test/features/audit_hardening_test.dart`**: 8 comprehensive audit tests verifying 200% text scaling, dark mode rendering, and empty states.

---

## Fix B: PDF Portfolio & Progress Accuracy and Language Hardening

In this fix, we resolved accuracy and wording bugs identified during a code audit of the PDF portfolio generator and student progress calculations.

### Summary of Changes

1. **PDF Progress Uses School-Year Totals (Task 1)**:
   - When parents export a custom reporting period (such as a single month or quarter), the progress section in the PDF now maintains the child's full school-year totals against their annual goal, matching the numbers shown on the Home dashboard.
   - The custom date range only filters the chronological activity log and work sample attachments.
   - Distinct section headers clarify `'Progress for school year <start> to <end>'` and `'Time log for <start> to <end>'`.

2. **Unified Core-Subject Helper (Task 2)**:
   - Extracted core subject evaluation into a pure domain helper: `coreSubjectsFor`, `isCoreSubject`, and `formatCoreStatus` in `lib/domain/core_subjects.dart`.
   - Used consistently across Home, ExportService, and PdfPortfolioBuilder, ensuring core subject definitions cannot drift.

3. **Removed Regulatory and Official Claim Words (Task 3)**:
   - Replaced "Official Record" in the PDF with "Homeschool Record".
   - Replaced "Verified" badges with "Prepared by parent using Homeledger" and "Last checked".
   - Consolidated forbidden regulatory terms (`official`, `verified`, `verify`, `approved`, `compliant`, `compliance`, `guaranteed`, `certified`, `accredited`) into a single constant `kForbiddenClaimWords` in `lib/core/constants.dart`.
   - Added automated tests verifying zero occurrences of forbidden claim words in the generated PDF strings while keeping the required parent disclaimer intact.

4. **Handling Dates Outside the School Year (Task 4)**:
   - Added `checkDateRangeSchoolYearOverlap` and `computeDateRangeSchoolYearNotice` in `lib/domain/export_date_notice.dart`.
   - If an export period is partly outside the school year, both the export screen and the PDF show:
     `'Part of this range is outside the school year (<start> to <end>). Progress is shown for the school year.'`
   - If the range is entirely outside the school year, the notice informs the parent:
     `'This range is outside the school year. The time log is empty for this range.'`
   - Parents remain free to log instructional hours outside the standard school year without errors or blocks.

5. **Distinct Rows for Hours and Days Requirements (Task 5)**:
   - Implemented `ProgressMetricRow` and `computeProgressMetricRows` in `lib/domain/progress_metric_row.dart`.
   - Both Home and the PDF render each active requirement on its own row:
     `'<done> of <required> hours'` and `'<done> of <required> days'` with its own status chip (`On pace`, `Behind`, or `Finished`).
   - Requirements that are zero or null are omitted.
   - Overall status follows the worst-of rule: `Behind` beats `On pace` beats `Finished`.

---

## Fix A: First-Run Seeding, Midnight Clock Rollover, and Child Deletion File Cleanup

In this fix, we addressed three critical and high-priority bugs uncovered during an offline usability and data lifecycle audit.

### 1. First Run Must Be Able to Log Time (Task 1)
- **What was wrong**: The default subjects (`Math`, `Reading`, `Writing`, `Science`, `History`, `Other`) were only seeded in `SubjectsScreen.initState`. When a new parent opened the app for the first time and completed the onboarding sequence (`Disclaimer` -> `Add Child` -> `Home` -> `Log time`), the log screen displayed "No subjects available." with no way to proceed without knowing to navigate into `Settings` -> `Subjects`.
- **Why tests missed it**: All existing test setups manually inserted subjects directly into the database before opening the log screen or dashboard, completely bypassing the real initial onboarding path.
- **What changed**:
  - Implemented `ensureDefaultSubjectsSeeded(settingsRepo)` in `SubjectRepository`: checks whether the `default_subjects_seeded` setting is absent and the `subjects` table is empty. If both are true, it seeds the 6 default subjects and records `default_subjects_seeded = 'true'`. If the table already has subjects, it marks the setting as seeded without duplicating subjects. If a parent intentionally deletes all subjects later, the flag prevents them from being re-seeded.
  - Added seeding execution to `AppStartupGate` in `lib/app/app.dart` so seeding occurs before navigation to the disclaimer, add child, or home screens.
  - Removed seeding logic from `SubjectsScreen.initState`.
  - Added an empty-state fallback to `LogScreen`: if subjects are ever empty, it shows `'You have no subjects yet. Add one to start logging.'` with an `'Add subject'` button (minimum 48 dp tap target) that navigates to `SubjectsScreen`.
  - Added unit and widget tests: `test/data/ensure_subjects_seeded_test.dart` and `test/features/first_run_subject_seeding_test.dart` (including an end-to-end first-run test without manual subject creation).

### 2. "Today" Must Follow the Real Date Across Midnight (Task 2)
- **What was wrong**: `clockProvider` was implemented as a simple Riverpod `Provider<DateTime>` that called `DateTime.now()` only once when the provider was first evaluated. Because Android often keeps the app process alive in the background for days, crossing midnight did not update the date. Home continued displaying yesterday's logged time under "Today", the logging screen defaulted to yesterday, and future date validation blocked logging for the actual current day. Furthermore, three service providers used `ref.watch(clockProvider)` inside callback closures.
- **Why tests missed it**: All tests injected a fixed mock time using `clockProvider.overrideWithValue(...)` and never simulated process longevity, daylight-saving transitions, or midnight crossings.
- **What changed**:
  - Maintained `clockProvider` as `Provider<DateTime>` to preserve compatibility with existing tests.
  - Created `ClockRefresher` (`lib/app/clock_refresher.dart`) wrapping the app with a `WidgetsBindingObserver`:
    - On `AppLifecycleState.resumed`, it compares the calendar date of `ref.read(clockProvider)` with `DateTime.now()` and calls `ref.invalidate(clockProvider)` if the day has changed.
    - Sets a `Timer` targeting the next local midnight plus 1 second, calling `ref.invalidate(clockProvider)` and scheduling the subsequent midnight timer.
  - Extracted the pure midnight calculation into `timeUntilNextMidnight(DateTime now)` with unit tests verifying calculations across standard days and daylight-saving transitions.
  - Changed closures in `exportServiceProvider`, `backupServiceProvider`, and `fakeEntitlementServiceProvider` from `ref.watch(clockProvider)` to `ref.read(clockProvider)`.
  - Added widget tests verifying that resuming the app on day D+1 resets "Today" on Home to 0 min, preserves "This week" totals, and permits logging on day D+1.

### 3. Deleting a Child Must Delete Its Physical Image Files (Task 3)
- **What was wrong**: When deleting a child, `SettingsScreen._confirmAndDeleteChild` called `File(path)` directly on the strings returned by `ChildRepository.deleteChildCascade`. In Step 7, work sample file storage was refactored to store relative paths (such as `samples/<childId>/sample_123_ab.jpg`). Calling `File(relativePath)` evaluated relative to the current working directory of the process rather than the app's documents directory. As a result, `file.existsSync()` was always `false`, the image files and the `samples/<childId>` folder remained on disk, and cleanup only occurred if an orphan sweep ran on a later app restart.
- **Why tests missed it**: `test/features/delete_child_widget_test.dart` populated test work sample rows using absolute file paths (`sampleFile.path`), hiding the relative path resolution failure.
- **What changed**:
  - Created `ChildDeletionService` in `lib/services/child_deletion_service.dart` with `Future<ChildDeletionResult> deleteChild(int childId)`. It executes `ChildRepository.deleteChildCascade(childId)`, resolves each returned relative path using `SampleStorageService.resolveFile()`, deletes existing files on disk, and removes the `samples/<childId>` directory recursively.
  - Registered `childDeletionServiceProvider` in `lib/data/providers.dart`.
  - Updated `SettingsScreen._confirmAndDeleteChild` to use `childDeletionServiceProvider.deleteChild(child.id)`.
  - Added unit tests in `test/services/child_deletion_service_test.dart`.
  - Rewrote `test/features/delete_child_widget_test.dart` to use `SampleStorageService` with a temporary documents directory, test with real relative paths on disk, verify immediate deletion of sample files and the child directory, verify resilience against missing files, and ensure files belonging to other children remain untouched.

---

## Fix C: Restore Resilience, Entitlement Protection, Subject Cascade Deletion, Temp File Cleanup, Edit Child Fallbacks, Clock Consistency, and Thumbnail Optimization

In this fix, we addressed data safety, robustness, memory optimization, and UI edge cases discovered during a comprehensive system audit.

### 1. Robust and Safe Database Restore (Task 1)
- **What was wrong**: During backup restore, the existing database was closed and swapped before verifying the backup archive. If the archive contained a corrupted database, unsupported schema, or encountered a filesystem error mid-swap, the live database could be destroyed or left in an inconsistent state, and Riverpod providers could point to stale or closed database handles.
- **What changed**:
  - Backup archives are unzipped into an isolated temporary folder first.
  - The restored database file is opened read-only and verified: runs `PRAGMA integrity_check`, validates the schema version is <= 3, and ensures all required tables exist before any modifications to live data occur.
  - Before swapping files, a safety copy of the current database and samples folder is created. If the swap fails, the safety copy is restored and an error message is reported: `'Restore failed. Your data on this phone was not changed.'`.
  - Every opened database handle is closed in a `finally` block exactly once.
  - `ref.invalidate(appDatabaseProvider)` is executed after every restore attempt, and the navigation stack is returned to the root route.
  - Temporary folders and safety backups are cleaned up in `finally`.

### 2. Retaining Device Entitlements Across Restores (Task 2)
- **What was wrong**: Entitlement values (`paidUntil`, `lastVerifiedAt`, `plan`) were stored directly in the database. Restoring an older backup or a backup from another phone would overwrite the current device's entitlement, downgrading paying parents or inadvertently upgrading unpaid installs.
- **What changed**:
  - The current device's entitlement state is read before the database swap.
  - After the restored database is swapped in, the device's entitlements are written back to the restored database within the safe restore transaction.
  - Restoring a backup made while free on a paid device preserves paid status; restoring a paid backup on a free device keeps it free.

### 3. Subject Deletion Counts Samples and Deletes Files (Task 3)
- **What was wrong**: The subject deletion confirmation dialog only counted time entries and omitted work samples. Furthermore, when subjects were deleted, sample image files on disk were not deleted.
- **What changed**:
  - The confirmation dialog in `SubjectsScreen` counts both time entries and work samples for the subject, presenting plain-language counts and informing the parent that both records and sample files will be deleted.
  - `deleteSubjectCascade` removes the database rows in a transaction and returns deleted sample file paths.
  - Physical sample files are resolved via `SampleStorageService.resolveFile` and deleted from disk, matching the child deletion safety pattern.

### 4. Backup Share Completion and Temp File Cleanup (Task 4)
- **What was wrong**: 'Last backup' was recorded immediately upon zip creation even if the user dismissed the Android share sheet. Temp backup zips and exported PDFs also accumulated indefinitely in the cache directory.
- **What changed**:
  - `createBackup()` only records the last backup timestamp when the share result is not dismissed.
  - Added `cleanupOldTempFiles()` in `lib/services/temp_file_cleanup.dart` to clean up `homeledger-backup-*.zip` and `*.pdf` files older than 24 hours.
  - Cleanup is executed at app startup (`AppStartupGate`), at the start of backup creation, and at the start of PDF export.

### 5. Edit Child Rule Fallback and Clock Provider Consistency (Task 5)
- **What was wrong**:
  - In `AddChildScreen`, if a child was saved with a rule ID that no longer exists in available profiles, the dropdown asserted or crashed.
  - Several screens and services directly invoked `DateTime.now()` rather than `ref.read(clockProvider)`.
  - The documentation claimed all date logic goes through `clockProvider`, which was not yet true.
- **What changed**:
  - In `AddChildScreen`, if the child's stored `ruleId` is not present in available profiles, it falls back to `'placeholder_example'` and displays `'Your saved rule is not available. Choose a rule.'`.
  - Replaced `DateTime.now()` in `add_child_screen.dart`, `export_options_screen.dart`, `backup_manifest.dart`, and `sample_storage_service.dart` with `clockProvider`.
  - Only `lib/app/clock_refresher.dart` (the real-time monitor) and `lib/data/providers.dart` (the provider definition) now call `DateTime.now()`.
  - Updated `docs/WALKTHROUGH.md` to accurately state that all date-dependent application logic reads the clock provider.

### 6. Scanner Cancel Resilience and Thumbnail Decoding (Task 6)
- **What was wrong**:
  - Grid thumbnails loaded full-resolution images into memory, wasting RAM when viewing 100+ samples.
- **What changed**:
  - Confirmed scanner and picker cancellation returns quietly without saving empty rows, leaving orphaned files, or displaying error messages.
  - Grid thumbnails now specify `cacheWidth = (tileWidth * devicePixelRatio).round()` using `LayoutBuilder`.
  - Full-screen sample viewer specifies `cacheWidth = 2048` to preserve sharpness while preventing runaway memory usage.

---

## Fix D: Pre-Release Polish, Disclosures, Consistency, and Audit

In this phase, we completed the owner's pre-release hardening items, unified visual appearance across all top-level destinations, added required privacy disclosures, added honest target captions, audited reachability, and compiled the launch checklist.

### 1. Privacy Policy Screen (Task 1)
- **What was wrong**:
  - Settings showed `'Privacy policy - Coming soon'`. Google Play requires a live, readable privacy policy disclosing offline handling, permissions, and data retention.
- **What changed**:
  - Created `lib/app/privacy_policy_text.dart` holding the canonical privacy policy text, version timestamp (`October 23, 2026`), contact email constant (`kPrivacyContactEmail = 'REPLACE_BEFORE_RELEASE'`), and explicit statements on zero analytics, local-only storage, camera usage, and backup exports.
  - Mirrored the exact text to `docs/PRIVACY_POLICY.md` for public hosting on the web.
  - Built `PrivacyPolicyScreen` in `lib/features/settings/privacy_policy_screen.dart` with clean, readable typography.
  - Updated `SettingsScreen` to open `PrivacyPolicyScreen` directly on tap (removed "Coming soon" and SnackBar).
  - Verified no forbidden regulatory claim words appear in the policy text.

### 2. Honest Requirement Labels on Progress and PDF (Task 2)
- **What was wrong**:
  - The Progress screen and PDF export displayed targets like `'Required 100 h'` without clarifying whether the target was a state rule, a placeholder, or a parent's custom goal.
- **What changed**:
  - Created `getRequirementCaption` in `lib/domain/requirement_caption.dart`.
  - When a child is using the placeholder profile, both the Progress screen (under the Overview card) and the PDF progress section display:
    `"Example target only. It is not your state's rule. Set your own in Edit child."`
  - When using a custom profile, both show:
    `"Your own target. Check your state's rules."`
  - When using a real state rule profile, no additional caption is shown.
  - Calculations, pace formulas, and data models remain unchanged.

### 3. Unified Scaffold Backgrounds Across Screens (Task 3)
- **What was wrong**:
  - The Log time screen had a grey background, while other screens used off-white, creating visual inconsistency when navigating tabs.
- **What changed**:
  - Explicitly configured `backgroundColor: theme.scaffoldBackgroundColor` on Scaffolds across `HomeScreen`, `LogScreen`, `ProgressScreen`, `SampleLibraryScreen`, `ExportOptionsScreen`, and `SettingsScreen`.
  - Verified `LogScreen` in loading, empty, and populated data states displays the unified theme scaffold background with no container wrapping.

### 4. Work Sample Details & Schema Audit (Task 4)
- **Audit finding**:
  - Inspected `WorkSamples` in `lib/data/db/app_database.dart` (schema version 3).
  - Columns present: `id`, `childId`, `subjectId`, `day`, `title`, `filePath`, `createdAt`.
  - The `note` column does NOT exist in the `WorkSamples` table.
  - In strict compliance with instructions (*"no schema changes; if a column is missing, STOP and report instead of changing the schema"*), the schema version was kept at 3 and no database changes were made. Task 4 is reported as blocked for notes.
  - Verified that `_SampleThumbnailCard` already displays `_subject.name` in the card footer when set, and PDF export already includes title, subject, and date.

### 5. Reachability Audit (Task 5)
- **Audit finding**:
  - Conducted a comprehensive audit of all features, data rules, and business rules from `docs/PROJECT_CONTEXT.md` mapping their navigation path from the Home screen.
  - Documented findings in `docs/REACHABILITY.md`.
  - **Key findings**:
    - There is no standalone "Upgrade" or "Subscription" row in `SettingsScreen`; the paywall is only reached contextually by attempting locked Plus actions.
    - "Restore purchase" does not exist in `SettingsScreen` or top-level navigation; it is only accessible inside `PaywallScreen`.

### 6. Pre-Release Checklist (Task 6)
- **What changed**:
  - Created `docs/RELEASE_CHECKLIST.md` tracking all required release tasks tagged with `[ ] (owner)` or `[ ] (engineer)`.
  - Covers hosted privacy URL, contact email, applicationId, app icon, versioning, release keystore signing, target SDK, Data Safety answers, content rating, store screenshots, Play Billing replacement notice, physical low-end device testing, Android 13/14+ testing, and the complete permissions audit table from Fix C.

