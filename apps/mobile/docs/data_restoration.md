## FollowUps Migration Logic (Admin Dashboard)

This document describes, in precise detail, how the follow-ups migration logic works in the Admin Dashboard component `MigrationManagementCard`.

Scope: Migrates legacy user relapse-related arrays into normalized Firestore `followUps` documents, and provides tools to analyze and fix duplicates.

Primary reference implementation: `src/app/[lang]/user-management/users/[uid]/MigrationManagementCard.tsx`


### Purpose

- **Normalize legacy arrays** (on the user profile) into a proper collection under `users/{userId}/followUps`.
- **Assess migration status** per category (relapses, masturbation-only, porn-only): totals, missing, duplicates, details.
- **Remediate** by creating missing docs and removing duplicate docs.


### Data Model

- Firestore path: `users/{userId}/followUps`
- Document shape (per follow-up):
  - `time: Timestamp`
  - `type: 'relapse' | 'pornOnly' | 'mastOnly'`

- Legacy data (on user document, denormalized arrays of date strings, format `YYYY-MM-DD`):
  - `userRelapses?: string[]`
  - `userMasturbatingWithoutWatching?: string[]`
  - `userWatchingWithoutMasturbating?: string[]`


### Inputs and Source of Truth

- Live data: `followUps` subcollection is streamed via `useCollection` (client SDK).
- Legacy arrays are read from the provided `user` prop.
- Migration status is computed by comparing dates in the legacy arrays vs. date-only values derived from the `followUps` documents.
- Only `followUps` whose date-part is present in the legacy arrays are considered for migration status calculations.


### Lifecycle and Data Flow

1. Subscribe to `users/{userId}/followUps` via `useCollection`.
2. On snapshot availability, build an in-memory list of follow-ups `{ id, time, type }`.
3. Extract legacy arrays from the `user` object.
4. Compute, per category, the list of migrated dates by:
   - Filtering follow-ups by `type`.
   - Converting `time` to date-only ISO `YYYY-MM-DD`.
   - Filtering to include only dates that also exist in the corresponding legacy array (critical detail).
5. Analyze duplicates and counts per category.
6. Assemble `migrationData` object for rendering and actions.
7. Update `lastUpdated` timestamp.


### Category Mapping

- UI categories map to follow-up `type` as follows:
  - `relapses` → `'relapse'`
  - `mastOnly` → `'mastOnly'`
  - `pornOnly` → `'pornOnly'`


### Duplicate Analysis (date-only)

For each category:

- Build an array of date strings `YYYY-MM-DD` for migrated entries (already filtered to legacy dates).
- Build `dateCount: Map<string, number>` of occurrences per date.
- Derive:
  - `duplicates: string[]` → dates with count > 1
  - `duplicateCount: number` → total extra entries = `totalEntries - uniqueEntries`
  - `duplicateDetails: Array<{ date, count, extras }>` where `extras = count - 1`
  - `totalEntries: number` → raw occurrences in migrated list
  - `uniqueEntries: number` → number of unique dates

Note: Duplicate detection is based on date-only equality, not document ID or timestamps beyond the date portion.


### Migration Status Object

For each category, the component builds:

```
relapses | mastOnly | pornOnly: {
  legacy: string[]                // original legacy dates
  migrated: string[]              // followUps dates (filtered to legacy)
  missing: string[]               // legacy dates not present in migrated unique dates
  duplicates: string[]            // dates occurring more than once among migrated
  duplicateCount: number          // total extras across all duplicate dates
  dateCount?: Map<string, number> // frequency map used for diagnostics
  duplicateDetails?: Array<{ date: string, count: number, extras: number }>
  totalEntries?: number
  uniqueEntries?: number
}
```

Global helpers (derived from `migrationData`):

- `getTotalMissingCount()` → sum of missing across categories.
- `getTotalFollowupsCount()` → sum of migrated counts across categories.
- `getTotalDuplicatesCount()` → sum of duplicateCount across categories.

Migration completeness condition:

- `isMigrationComplete = (totalMissing === 0) && hasLegacyData`
- `hasLegacyData = user.userRelapses || user.userMasturbatingWithoutWatching || user.userWatchingWithoutMasturbating`


### Actions

#### 1) Migrate Missing

Triggered per category when `missing.length > 0`.

Steps:

1. Determine the follow-up `type` using the mapping above.
2. Prepare batched writes (Firestore limit: 500 operations per batch).
3. For each date in `missing`:
   - Construct a Timestamp at midnight UTC: `new Date(`${date}T00:00:00.000Z`)`.
   - Create a new doc with fields `{ time, type }` at `users/{userId}/followUps`.
   - Use a local `dateTypeMap` to avoid inserting the same `(date, type)` twice within the current migration run.
4. Commit batches sequentially.

Important implementation details:

- The write uses auto-generated document IDs.
- The legacy arrays are date-only; times are normalized to midnight UTC to reflect that constraint.
- `missing` is computed against the set of existing migrated dates (already filtered to legacy dates), so duplications should not occur if the snapshot is stable.
- If concurrent writes occur between status computation and commit, a race-condition could still create one additional dup; the UI provides a duplicate removal tool to remediate.

Error handling and UX:

- Errors are logged with `console.error`. No toast is shown by default (placeholders exist in code for future toasts).
- A loading state (`migrating`) disables buttons during the operation.


#### 2) Remove Duplicates

Triggered per category when `duplicateCount > 0`.

Steps:

1. Determine the follow-up `type` using the mapping above.
2. For each duplicate date (date string) in the category:
   - Query all docs of that `type` in `users/{userId}/followUps`.
   - Client-filter the query results to documents whose `time` date-part equals the duplicate date.
   - If more than one document matches, keep the first and delete the rest in a batch.
3. Repeat for each duplicate date.

Important implementation details:

- Deletion “keeps the first” document without deterministic ordering guarantees; the specific survivor document is not controlled.
- The query filters by `type` at the server and by exact date string on the client.
- A separate batch is committed per duplicate date.

Error handling and UX:

- Errors are logged with `console.error`. No toast is shown by default.
- A loading state (`removingDuplicates`) disables buttons during the operation.


### UI/UX Behavior Notes

- Summary metrics show total migrated, total missing, and total duplicates across categories.
- A toggle reveals per-category details with statistics and the two actions above.
- The “Refresh” button only updates the `lastUpdated` timestamp in the UI; it does not force a re-fetch by itself. Live data updates arrive via the Firestore subscription.
- If no legacy arrays exist for the user, the card renders a specialized empty state and hides actions.


### Timezone and Date Handling

- Legacy arrays store date-only strings (no timezones). The migration writes `Timestamp` values at midnight UTC for those dates.
- All comparisons are performed on the date-part of timestamps using ISO `YYYY-MM-DD` generated from `toISOString()`.
- If follow-up documents were created with non-UTC midnight times or outside UTC, the date-only extraction still normalizes via ISO output and comparison.


### Performance Characteristics and Limits

- Write batching adheres to Firestore limits (max 500 ops per batch).
- Duplicate removal runs one query per duplicate date per category, then filters on the client. This is acceptable for small duplicate counts; for very large datasets, consider optimizing by querying once per category and grouping in memory.


### Idempotency

- The migration is effectively idempotent with respect to legacy arrays:
  - Missing is computed against unique migrated dates that overlap legacy arrays.
  - Re-running “Migrate Missing” after a successful run should produce zero additional writes.
- Duplicate removal can be re-run; after a successful pass, duplicate counts drop to zero.


### Known Caveats and Edge Cases

- Extra follow-ups that do not correspond to dates in legacy arrays are ignored for migration status and duplicate analysis.
- The “keep first” deletion strategy is arbitrary and does not preserve a particular timestamp.
- A race between computing `missing`/`duplicates` and performing writes could produce transient inconsistencies; subsequent renders should self-correct via the subscription, and the duplicate removal tool can remediate any leftover issues.
- Errors are only logged. If admin feedback is required, integrate toasts where placeholders exist in code.


### Extending to New Follow-Up Types

To add a new follow-up type:

1. Introduce a new legacy array on the user profile (if applicable).
2. Update the type union in `FollowUp` and all places mapping UI categories to follow-up `type`.
3. Extend the status computation to include the new category (filtering, duplicate analysis, and `migrationData` assembly).
4. Add a new UI section and actions using the same patterns.


### Validation Checklist

- Verify that “Total Followups” equals the sum of per-category migrated counts (filtered to legacy dates).
- Verify “Missing Entries” is the sum of per-category missing counts.
- Verify “Duplicate Entries” is the sum of per-category duplicate extras.
- After “Migrate Missing”, ensure missing counts go to zero for categories fully covered by legacy.
- After “Remove Duplicates”, ensure duplicate counts go to zero for those categories.
- Confirm created documents have `time` at midnight UTC and the correct `type`.


### Internationalization

All visible strings use i18n keys under `modules.userManagement.migrationManagement.*` so the UI is fully localized. This document intentionally uses English for operational clarity.


### Pseudocode Summary

```pseudo
read legacy arrays from user
subscribe to users/{userId}/followUps

onSnapshot:
  for each category in [relapse, mastOnly, pornOnly]:
    migratedDates = followUps
      .filter(f.type == category)
      .map(dateOnly(f.time))
      .filter(date in legacyArrayForCategory)

    analyze duplicates over migratedDates → duplicates, duplicateCount, details, totals

    missing = legacyArrayForCategory - unique(migratedDates)

render migrationData and actions

on Migrate Missing(category):
  for each date in missing:
    write { time: midnightUTC(date), type: category } (batched ≤ 500)

on Remove Duplicates(category):
  for each duplicateDate:
    query all docs where type == category
    keep first with dateOnly == duplicateDate; delete rest (batch)
```


### Ownership and Contact

- Component owner: Admin Dashboard team.
- Code location: `src/app/[lang]/user-management/users/[uid]/MigrationManagementCard.tsx`
- Firestore: Client SDK write access assumed for admins per security rules.

---

## Flutter Mobile App Implementation

This section documents the Flutter mobile app implementation that provides end-users with data restoration capabilities, mirroring the admin dashboard logic but with a mobile-optimized UX.

### Overview

The Flutter implementation provides a self-service data restoration feature for users who may have lost follow-up data during app updates. The feature is presented as an elegant button that appears for eligible users and opens a comprehensive modal for data analysis and restoration.

### Architecture

The implementation follows the app's established architecture pattern: **Repository → Service → Notifier → UI**

#### Data Models (`lib/features/vault/data/data_restoration/migration_data_model.dart`)

The Flutter implementation uses the same data structures as the admin dashboard:

- **CategoryMigrationStatus**: Represents migration status for a specific category (relapses, mastOnly, pornOnly)
- **MigrationData**: Overall migration data containing all three categories with helper methods for aggregated counts
- **MigrationStatus Enum**: UI state management (checking, noIssues, issuesFound, migrating, etc.)

#### Repository Layer (`lib/features/vault/data/data_restoration/data_restoration_repository.dart`)

Handles all Firestore operations and implements the core migration logic identically to the admin dashboard:

##### Migration Logic Implementation:
1. **Category Analysis**: Filters follow-ups by type, converts timestamps to ISO date strings, only includes dates in legacy arrays
2. **Missing Data Detection**: Compares unique migrated dates against legacy arrays
3. **Duplicate Analysis**: Identifies dates with count > 1, calculates total extra entries
4. **Batched Writing**: Processes missing dates in batches of 500 (Firestore limit)
5. **Duplicate Removal**: Queries by type, keeps first document, deletes rest

##### Key Methods:
- `analyzeMigrationStatus()` - Performs comprehensive migration analysis
- `createMissingFollowUps()` - Creates missing follow-ups in batches
- `removeDuplicatesForDate()` - Removes duplicates for specific date/type
- `shouldShowDataRestorationButton()` - Determines user eligibility
- `markAsCheckedForDataLoss()` - Updates user document flag

#### Service Layer (`lib/features/vault/data/data_restoration/data_restoration_service.dart`)

Contains business logic and orchestration:
- Category mapping (relapses → 'relapse', mastOnly → 'mastOnly', pornOnly → 'pornOnly')
- Complete migration workflows
- Progress calculation and status summaries

#### State Management (`lib/features/vault/data/data_restoration/data_restoration_notifier.dart`)

Riverpod-based state management with reactive UI updates and comprehensive error handling.

### UI Components

#### DataRestorationButton
An elegant warning-styled button with gradient background that appears for eligible users.

#### DataRestorationModal  
Comprehensive modal bottom sheet with multiple states:
- **Checking State**: Loading spinner during analysis
- **No Issues State**: Success confirmation with migration summary
- **Issues Found State**: Detailed breakdown with action buttons  
- **Processing States**: Progress indicators during operations
- **Success State**: Completion confirmation
- **Error State**: Error handling with retry options

### User Eligibility & Integration

#### Eligibility Criteria:
1. **Account Age**: User created before February 15, 2025
2. **Not Previously Checked**: `hasCheckedForDataLoss` field is false/null
3. **Legacy Data Present**: User has legacy arrays in their document

#### Integration Points:
- **Vault Screen**: Added after Shorebird update widget for maximum visibility
- **Statistics Section**: Added at bottom for alternative access point

#### User Document Enhancement:
Added `hasCheckedForDataLoss: bool?` field to UserDocument model to prevent repeated button displays.

### Localization & UX

#### Full Internationalization:
Complete English and Arabic translations for all UI text with 20+ localization keys.

#### Error Handling & Performance:
- Graceful error handling with retry options
- Loading states and progress indicators
- Batched operations respecting Firestore limits
- Reactive state management for minimal re-renders

### Technical Implementation

#### Code Organization:
```
lib/features/vault/data/data_restoration/
├── migration_data_model.dart           # Data models and enums
├── data_restoration_repository.dart    # Firestore operations layer
├── data_restoration_service.dart       # Business logic layer
└── data_restoration_notifier.dart      # State management layer

lib/features/vault/presentation/widgets/data_restoration/
├── data_restoration_button.dart        # Warning button component  
└── data_restoration_modal.dart         # Comprehensive modal UI
```

#### Key Features:
- **Self-Service**: User-managed vs admin-managed operations
- **Mobile-Optimized**: Touch interface with modal design
- **Progressive Disclosure**: Simple button reveals detailed interface as needed
- **Idempotent Operations**: Safe to retry, prevents duplicate creation
- **Security**: User-scoped operations with proper authentication

### Validation & Testing

The implementation includes comprehensive validation:
- Total follow-ups match sum of per-category counts
- Missing entries calculation accuracy
- Duplicate count verification  
- Proper timestamp handling (midnight UTC)
- Button eligibility logic
- All UI states and error scenarios
- Localization functionality

This implementation provides users with a self-service data restoration tool that maintains the same rigorous migration logic as the admin dashboard while delivering an intuitive, mobile-optimized user experience.

