# Adding a State Rule Profile

Use this checklist when researching and adding an official state homeschool requirement to Homeledger.

> **Crucial Rule**: Never copy from a blog. Use the state education department.

---

## Research Checklist

Before creating a state JSON file, verify every item from the official state statute or department of education website:

1. [ ] **Official Source Link**: Direct URL to the state department of education or legislative statute page.
2. [ ] **Number of Hours**: Total required instructional hours per school year (or `null` if the state does not specify hours).
3. [ ] **Number of Days**: Total required school days per school year (or `null` if the state does not specify days).
   *Note: At least one of hours or days must be positive.*
4. [ ] **Core Subjects**: List of mandatory subjects specified by the state (e.g. `["Reading", "Language Arts", "Mathematics", "Science", "Social Studies"]`), or empty `[]` if none mandated.
5. [ ] **Date Checked**: Record the verification date as `YYYY-MM-DD`.
6. [ ] **Statutory Citations / Notes**: Reference the exact legal section (e.g., "Section 167.042 RSMo").

---

## Technical Steps to Add the State

1. **Create the profile file**:
   Add a new JSON file under `assets/rules/<state_id>.json` (e.g. `assets/rules/missouri_standard.json`):
   ```json
   {
     "id": "<state_id>",
     "label": "<State Name> (Official Legal Description)",
     "requiredHours": 1000,
     "requiredDays": null,
     "coreSubjects": [
       "Reading",
       "Math",
       "Science"
     ],
     "sourceUrl": "https://dese.mo.gov/...",
     "lastChecked": "2026-10-19",
     "isCustom": false,
     "notes": "Section 167.042. Records tool, not legal advice."
   }
   ```

2. **Register in `assets/rules/index.json`**:
   Add the filename to the array:
   ```json
   [
     "placeholder_example.json",
     "<state_id>.json"
   ]
   ```

3. **Verify with tests**:
   Run the test suite to automatically validate your new JSON file:
   ```bash
   flutter test test/data/rule_profile_loader_test.dart
   ```

---

## Legal & Wording Boundaries

- **Never** write `"compliant"`, `"approved"`, or `"guaranteed"` in any notes, label, or UI text.
- Use: *"helps you keep the records your state asks for"*.
- Every legal note or disclaimer must say: *"Records tool, not legal advice."*
