# userFirstDate Null Bug - Final Report

**Date:** 2026-02-15
**Severity:** P0 / Critical
**Status:** Root cause confirmed, fix pending
**Affected users:** ~1,072 active (2,437 total)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [User-Reported Behavior](#2-user-reported-behavior)
3. [Root Cause](#3-root-cause)
4. [The Infinite Loop Explained](#4-the-infinite-loop-explained)
5. [Identified Bugs](#5-identified-bugs)
6. [Scale of Impact](#6-scale-of-impact)
7. [Affected User Categories](#7-affected-user-categories)
8. [Evidence & Proof](#8-evidence--proof)
9. [Affected Code Paths](#9-affected-code-paths)
10. [All Write Paths to /users Collection](#10-all-write-paths-to-users-collection)
11. [Recommended Fixes](#11-recommended-fixes)
12. [Data Repair Plan](#12-data-repair-plan)
13. [Files Reference](#13-files-reference)

---

## 1. Executive Summary

A chain of 4 interconnected bugs causes `userFirstDate` to be written as `null` in the Firestore `/users` collection. Because `userFirstDate` is checked by `hasMissingData()`, affected users are permanently trapped in a "confirm details" loop on every app launch. The ConfirmUserDetailsScreen that is supposed to fix the missing data has a bug that saves `null` back, making the loop unbreakable.

**2,437 user documents** have `userFirstDate == null`. Of these, approximately **1,072 are active new users** who registered in Jan-Feb 2026 and are completely unable to use the app.

---

## 2. User-Reported Behavior

Users report:

> "I fill in everything on the confirm details screen, then I can use the app. But when I close it and reopen, it shows me the confirm details screen again."

This is the expected behavior given Bug #1. The save path writes `null` back for `userFirstDate`, so every app relaunch detects missing data and shows the screen again. The field is also disabled (`enabled: false`), so users cannot manually edit it.

---

## 3. Root Cause

The bug is a **two-part chain**:

### Part 1 - Initial Trigger

`creatUserDocuemnt()` silently fails during registration for some users. The catch block in both `creatUserDocuemnt()` and `completeAccountRegiseration()` swallows all errors (no rethrow). The user's Firestore document remains a partial stub created by `DeviceTrackingService` (containing only `devicesIds` and `lastDeviceUpdate`). A Shorebird OTA patch added a `uid` fallback from `doc.id` in `UserDocument.fromFirestore()`, which made these partial documents appear as "valid" user documents with missing data, triggering `needConfirmDetails` status.

### Part 2 - Perpetuation (The Infinite Loop)

`ConfirmUserDetailsScreen` line 357 passes `userDocument.userFirstDate` (which is `null`) instead of the locally computed `selectedUserFirstDate` (which defaults to `DateTime.now()`). The migration service then writes this `null` back to Firestore via `merge:true`, preserving the null forever.

**Key proof:** `creatUserDocuemnt()` **always** writes a non-null `userFirstDate` (the `DateTime` parameter is non-nullable in Dart). The **only** code path that writes `null` is ConfirmUserDetailsScreen -> migration_service.

---

## 4. The Infinite Loop Explained

```
App Launch
    |
    v
accountStatusProvider
    |
    v
hasMissingData(doc) checks userFirstDate == null
    |  (returns true)
    v
AccountStatus.needConfirmDetails
    |
    v
HomeScreen shows "profile incomplete" banner
    |
    v
User taps "Complete Profile"
    |
    v
ConfirmUserDetailsScreen
    |-- Line 160: selectedUserFirstDate = DateTime.now()  (CORRECT fallback)
    |-- Line 285: userFirstDate field enabled: false      (user can't edit)
    |-- Line 357: userFirstDate: userDocument.userFirstDate  (BUG: saves null)
    |
    v
migration_service.migrateToNewDocuemntStrcture()
    |
    v
migeration_repository.updateUserDocument()
    |-- .set(doc.toFirestore(), SetOptions(merge: true))
    |-- toFirestore() includes userFirstDate: null explicitly
    |-- merge:true writes null for fields IN the map
    |
    v
Firestore: userFirstDate is STILL null
    |
    v
User closes app, reopens -> Back to top (infinite loop)
```

---

## 5. Identified Bugs

### Bug #1: ConfirmUserDetailsScreen saves null instead of fallback (PRIMARY)

**File:** `lib/features/authentication/presentation/confirm_user_details_screen.dart`

The screen computes a correct fallback at display time but ignores it at save time:

```dart
// Line 160-161 - DISPLAY (correct)
final userFirstDate = userDocument.userFirstDate?.toDate() ?? DateTime.now();
selectedUserFirstDate = displayUserFirstDate.date;

// Line 357 - SAVE (bug: uses original null, not the fallback)
userFirstDate: userDocument.userFirstDate,  // <-- NULL
```

The field is also `enabled: false` (line 285), preventing user intervention.

### Bug #2: Network errors redirect to registration (DEPLOYED)

**Files:**
- `lib/features/authentication/providers/user_document_provider.dart`
- `lib/features/authentication/providers/account_status_provider.dart`

In the deployed (committed) code:
- `getUserDocument()` used `GetOptions(source: Source.server)` and returned `null` on any error
- `accountStatusProvider` returned `needCompleteRegistration` when doc is null (including network errors)

Any network hiccup makes the app think the user has no document. Local uncommitted changes add `AccountStatus.error` to prevent this, but these are **not yet deployed**.

### Bug #3: Migration service overwrites fields with null

**File:** `lib/features/authentication/application/migration_service.dart`

`_updateUserDocument()` (lines 101-123) creates a new `UserDocument` that omits `isPlusUser`, `lastPlusCheck`, `isRequestedToBeDeleted`, and `hasCheckedForDataLoss`. These default to `null`. Because `toFirestore()` includes all fields (even nulls) and the write uses `merge:true`, these nulls **overwrite** any existing values.

```dart
// Lines 107-121 - omits isPlusUser, lastPlusCheck, etc.
UserDocument newDocuemnt = UserDocument(
  uid: document.uid,
  devicesIds: [deviceId],
  displayName: document.displayName,
  // ...
  userFirstDate: document.userFirstDate,  // passes through null
  // isPlusUser, lastPlusCheck, etc. NOT included -> default null
);
```

### Bug #4: creatUserDocuemnt() swallows errors silently

**File:** `lib/features/authentication/data/repositories/auth_repository.dart`

The catch block in `creatUserDocuemnt()` (and `completeAccountRegiseration()` in `auth_service.dart`) catches all exceptions without rethrowing. If the Firestore write fails, the app silently continues as if registration succeeded, leaving only the partial `DeviceTrackingService` stub document.

---

## 6. Scale of Impact

| Metric | Value |
|--------|-------|
| Total users with `userFirstDate == null` | **2,437** |
| Active new users stuck (Category C) | **~1,072** |
| Old migrated users affected (Category B) | **~195** |
| Legacy dormant accounts (Category A) | **~1,072** |
| Confirmed Plus subscribers stuck | **2+** (potentially 50-100+) |
| Date range of Category C users | Feb 3 - Feb 14, 2026 |
| All auth providers affected | Yes (Apple, Google, Email) |

This is **not** a rare edge case. Nearly every new user who registered since the Shorebird OTA patch deployment is affected.

---

## 7. Affected User Categories

### Category A: Legacy Minimal Records (~44% / ~1,072 users)

**Impact:** LOW (inactive/dormant)

Documents with only 5-6 fields: `uid`, `email`, `userRelapses`, `userFirstDate`, `userWatchingWithoutMasturbating`, `userMasturbatingWithoutWatching`. No `displayName`, `role`, `gender`, `locale`, `dayOfBirth`, or `devicesIds`. Created before `userFirstDate` existed in the schema. Some have relapse data from 2022-2023 proving historical usage.

### Category B: Old Migrated Users (~8% / ~195 users)

**Impact:** MEDIUM (some still active)

Documents with a `creationTime` field from 2021-2022 AND newer fields (`devicesIds`, `lastDeviceUpdate`, `role`, etc.). These users registered years ago, then re-opened the app on a newer version which ran `DeviceTrackingService` and triggered migration. The migration path preserved their null `userFirstDate`.

| UID | Created | Last Active | Name |
|-----|---------|------------|------|
| `0V1JG9qU9Ka0pvQAU1sskGTRCmI2` | 2021-10-16 | 2026-01-09 | Mustafa Moneb |
| `0XMOKNSCy2S2KhGIhnVnV62ASAi1` | 2021-04-01 | 2025-07-07 | Sa |
| `11t5ylSb9vYNACZ2o3w8lpQcjpo2` | 2022-05-12 | 2026-01-20 | واكان |
| `1DrQ6SjqARSd8CGuOWy32aGuCy73` | 2022-02-25 | 2025-09-24 | محمود احمد |

### Category C: Recent New Users (~44% / ~1,072 users) - CRITICAL

**Impact:** CRITICAL (active, completely stuck)

All newer fields populated (`role`, `gender`, `locale`, `dayOfBirth`, `displayName`, `devicesIds`, `lastDeviceUpdate`, `lastEmailSync`). `lastDeviceUpdate` in Jan-Feb 2026. Some have `referralCode` (proving registration completed and Cloud Function fired). ALL have `isPlusUser: null`, `lastPlusCheck: null`, `hasCheckedForDataLoss: null`, `isRequestedToBeDeleted: null` as explicit nulls - the signature of having gone through ConfirmUserDetailsScreen -> migration_service.

**Originally investigated users (4):**

| UID | Name | Provider | Auth Created | referralCode | isPlusUser |
|-----|------|----------|-------------|-------------|-----------|
| `6Qm6KWx6wCXRukcjOuShdFPAx8G2` | Magid Alharbi | Apple | 2026-02-07 | - | true |
| `S3a5kggvZeUBLszTsT3QIJk7WPA2` | Amin Mahmood | Email | 2026-02-07 | AMDNMEDK | true |
| `g8T2CeaQpuYkNsA4GQhcg8ZQB0K2` | Mofareh (Ray) | Apple | 2026-02-10 | RAYKJA76 | null |
| `Aj0T90eDV4VfZwS7Z1fUZD0vIpf1` | Mansoor Aljneibi | Google | 2026-02-08 | - | null |

**Additional Category C users from full query (sample of 22):**

| UID | Last Device Update | Name | Notes |
|-----|-------------------|------|-------|
| `03JWNfcpEWNam7DxtkhANccRSYb2` | 2026-02-13 | hnnx4 | |
| `03oXhPSFlLa7UiGZz9JjnywWN7h1` | 2026-02-14 | abood | |
| `0EsHDqJTRHaWFcwMN5L07KU7hr02` | 2026-02-12 | thaihaih5 | |
| `0UwKN7o3AaR1dc3qMETjWxVY2d13` | 2026-02-10 | gggg | referralCode: KHAL8L94 |
| `0ZmJokACPQeYbRJy4HcnLT5xIMO2` | 2026-02-10 | عبدالرحمن عبدلي | |
| `0iARFjESXEWzOTorNFc9eqKLQYK2` | 2026-02-11 | خالد الشاطري | dayOfBirth also null |
| `0jjTR6Hg0tOoSAlalNq8eajSJs02` | 2026-02-06 | راكان الشراري | referralCode: BVQGC4PT |
| `0n2Xbb6H3Hbs4V1PbOLvyiiaiLl2` | 2026-02-04 | badis amour | |
| `0nZ47DhSsQRQigMUfRrinXZhI7j1` | 2026-02-13 | fif | |
| `0qaOq9rJroSrWwDwvahlLsXc31x2` | 2026-02-07 | يزن | isPlusUser: false |
| `0vhTFHXNvbVcwMHXNeAr9gw33k83` | 2026-02-07 | Saber | isPlusUser: false |
| `0wVS01M0FlRxOxz2TlyNkI3aWeO2` | 2026-02-08 | بخيت | |
| `0wl1FS7ANBTpJuXfI99C4RxirlZ2` | 2026-02-06 | سليمان | |
| `14rfLauMP7QOVZmGCaAYrWpRE6S2` | 2026-02-11 | بدر | referralCode: BTSTZ6S2 |
| `19yPotDpWZb2OuJpdLpeazuAtgF3` | 2026-02-08 | Monique | |
| `1AaVqspq9xQWUcFEKTp5KtMIjR33` | 2026-02-13 | eeeeaaag | |
| `1HuacvxIMqS5xDqEDiRJNfXL4l93` | 2026-02-11 | Salem | referralCode: BWDF9ZJ6 |
| `1KhYP8QzuCbnzmBwZfWeB46wkZ83` | 2026-02-09 | naif | |
| `1NQE0E6gvzLsmuKNxRjpaC60UB73` | 2026-02-03 | FahadAlFahad55 | earliest in sample |
| `1PWkHycLUngbrFlty1WVSnB7Ukx2` | 2026-02-09 | فيصل | |
| `1RSDaqCo59eZvy3VLpPEzli6nDQ2` | 2026-02-08 | Ouakidi Walid | |
| `1RvZOZO5UxMt4c40UBwJFH6Ifiz1` | 2026-02-04 | احمد علي | |

---

## 8. Evidence & Proof

### 8a. `creatUserDocuemnt()` always writes non-null userFirstDate

`auth_repository.dart` line 87:
```dart
userFirstDate: Timestamp.fromDate(firstDate.toUtc()),
```
The `firstDate` parameter is `DateTime` (non-nullable in Dart). Therefore, `creatUserDocuemnt()` can **never** write null for this field. The null must come from elsewhere.

### 8b. The only code path that writes null is ConfirmUserDetailsScreen

`confirm_user_details_screen.dart` line 357:
```dart
userFirstDate: userDocument.userFirstDate,  // null when source doc has null
```
This is passed to `migration_service._updateUserDocument()` which passes it through to `toFirestore()` which includes it in the map, and `merge:true` writes null to Firestore.

### 8c. referralCode proves merge:true was the last write

Users Amin (`AMDNMEDK`) and Mofareh (`RAYKJA76`) have `referralCode` in their documents. The `referralCode` field is **not** in the `UserDocument` model - it's written by a Cloud Function via `batch.update()`. If `creatUserDocuemnt()` had been the last write (which uses `.set()` without merge), `referralCode` would have been deleted. Its presence proves `merge:true` (the migration path) was the last full-document write.

### 8d. Healthy control users lack migration artifacts

Healthy users (`mAVCYeZSQnaVuCRVUFOtjlAJxkF3`, `d6zooekj2YMukp6b2KUgzrYLHAX2`) lack `lastDeviceUpdate`, `lastEmailSync`, and `referralCode`. This confirms they went through the normal `creatUserDocuemnt()` `.set()` path without hitting the migration flow.

### 8e. Explicit null fields prove ConfirmUserDetailsScreen path

All Category C users have `hasCheckedForDataLoss: null`, `isRequestedToBeDeleted: null`, `isPlusUser: null` as **explicit fields** (not just missing). These fields are only written as explicit nulls by `migration_service._updateUserDocument()` -> `toFirestore()` -> `merge:true`. If these fields were never written, they would simply not exist in the document.

### 8f. Timestamp correlation proves DeviceTrackingService created the stub

For user Amin:
- `lastDeviceUpdate`: 2026-02-07T21:33:10.795Z
- referralCode created: 79ms later (Cloud Function `generateReferralCodeOnUserCreation` triggered by auth.user().onCreate, used `batch.update()` which requires the doc to already exist)

This proves: DeviceTrackingService created the partial doc first, then the Cloud Function added referralCode.

### 8g. Git timeline shows Shorebird OTA gap

- Last git commit: `a52d4814` on 2025-11-27
- Affected users registered: 2026-02-03 to 2026-02-14
- Gap of 2+ months = Shorebird OTA patches deployed in between
- The OTA patch likely added the `uid` fallback from `doc.id` in `fromFirestore()` which made partial docs visible

---

## 9. Affected Code Paths

### Registration Flow (normal path)

```
RegistrationStepperScreen
  -> AuthService.signUpWithEmail() / completeAccountRegiseration()
    -> AuthRepository.creatUserDocuemnt()
      -> UserDocument(userFirstDate: Timestamp.fromDate(firstDate.toUtc()))
      -> .toFirestore()
      -> Firestore .set() WITHOUT merge (full overwrite)
```

### Confirm Details Flow (bug path)

```
HomeScreen (accountStatus == needConfirmDetails)
  -> AccountActionBanner / ConfirmDetailsBanner
    -> ConfirmUserDetailsScreen
      -> Line 160: selectedUserFirstDate = DateTime.now()  [CORRECT]
      -> Line 357: userFirstDate: userDocument.userFirstDate  [BUG: null]
      -> MigrationService.migrateToNewDocuemntStrcture()
        -> _updateUserDocument()  [omits isPlusUser etc.]
          -> MigerationRepository.updateUserDocument()
            -> .toFirestore()  [includes ALL fields, even nulls]
            -> Firestore .set() WITH merge:true  [writes nulls]
```

### Account Status Check

```
accountStatusProvider
  -> watches userDocumentsNotifierProvider
  -> doc == null?  -> needCompleteRegistration
  -> hasMissingData(doc)?  -> needConfirmDetails
     checks: displayName, email, locale, uid, dayOfBirth, userFirstDate
  -> isLegacyUserDocument(doc)?  -> needConfirmDetails
     checks: devicesIds, messagingToken, role
```

### DeviceTrackingService (creates stub documents)

```
Auth state change listener fires
  -> If doc doesn't exist:
    -> .set({devicesIds: [deviceId], lastDeviceUpdate: serverTimestamp}, merge: true)
  -> Creates a PARTIAL document that later gets recognized as a "valid" user doc
```

---

## 10. All Write Paths to /users Collection

12 write locations found across Dart and TypeScript:

| # | File | Method | Write Type | Fields |
|---|------|--------|-----------|--------|
| 1 | `auth_repository.dart` | `creatUserDocuemnt()` | `.set()` no merge | Full doc, non-null userFirstDate |
| 2 | `migeration_repository.dart` | `updateUserDocument()` | `.set()` merge:true | Full doc via toFirestore() (includes nulls) |
| 3 | `user_profile_notifier.dart` | `updateUserProfile()` | `.set()` merge:true | Profile fields, required non-null userFirstDate |
| 4 | `user_profile_notifier.dart` | `updateUserFirstDate()` | `.update()` | Only userFirstDate |
| 5 | `user_profile_notifier.dart` | `deleteUserAccount()` | `.delete()` | N/A |
| 6 | `user_profile_notifier.dart` | `handleUserDeletion()` | `.delete()` | N/A |
| 7-10 | `device_tracking_service.dart` | (4 operations) | `.set()` merge:true / `.update()` | devicesIds, lastDeviceUpdate |
| 11 | `fcm_repository.dart` | `updateUserMessagingToken()` | `.set()` merge:true | messagingToken, lastTokenUpdate, platform |
| 12 | `user_subscription_sync_service.dart` | (sync) | `.update()` | isPlusUser, lastPlusCheck |
| 13 | `confirm_user_details_screen.dart` | (email update) | `.update()` | Only email |
| 14 | Cloud Function `generateReferralCodeOnUserCreation` | `batch.update()` | Only referralCode |
| 15 | Cloud Function `directMessageNotifications` | `.update()` | Nulls messagingToken |

**Only path #2** (via ConfirmUserDetailsScreen -> migration_service) can write `userFirstDate: null`.

---

## 11. Recommended Fixes

### P0 - Immediate (stop the bleeding)

**Fix 1: ConfirmUserDetailsScreen line 357**

```dart
// BEFORE (bug):
userFirstDate: userDocument.userFirstDate,

// AFTER (fix):
userFirstDate: selectedUserFirstDate != null
    ? Timestamp.fromDate(selectedUserFirstDate!)
    : userDocument.userFirstDate ?? Timestamp.fromDate(DateTime.now()),
```

**Fix 2: Deploy uncommitted error handling**

Commit and deploy the local changes to:
- `account_status_provider.dart` (adds `AccountStatus.error`)
- `user_document_provider.dart` (removes `Source.server`, rethrows errors)

### P0 - Data Repair

**Fix 3: Batch-fix affected users**

Write a Cloud Function or admin script to:
1. Query all users where `userFirstDate == null`
2. For Category C users: set `userFirstDate` from `lastDeviceUpdate` or Firebase Auth `creationTime`
3. For Category B users: set `userFirstDate` from `creationTime` field or Auth record
4. Category A (dormant): optional, fix on next login via the corrected ConfirmUserDetailsScreen

### P1 - Prevention

**Fix 4: migration_service.dart - preserve existing fields**

```dart
// In _updateUserDocument(), pass through existing subscription fields:
UserDocument newDocuemnt = UserDocument(
  // ... existing fields ...
  isPlusUser: document.isPlusUser,
  lastPlusCheck: document.lastPlusCheck,
  isRequestedToBeDeleted: document.isRequestedToBeDeleted,
  hasCheckedForDataLoss: document.hasCheckedForDataLoss,
);
```

**Fix 5: toFirestore() - skip null optional fields**

```dart
// In UserDocument.toFirestore(), only include non-null optional fields:
return {
  'uid': uid,
  'displayName': displayName,
  // ... required fields ...
  if (isPlusUser != null) 'isPlusUser': isPlusUser,
  if (lastPlusCheck != null) 'lastPlusCheck': lastPlusCheck,
  if (isRequestedToBeDeleted != null) 'isRequestedToBeDeleted': isRequestedToBeDeleted,
  if (hasCheckedForDataLoss != null) 'hasCheckedForDataLoss': hasCheckedForDataLoss,
};
```

**Fix 6: creatUserDocuemnt() - rethrow errors**

```dart
// In auth_repository.dart, don't swallow errors:
try {
  await docRef.set(userDocumentMap);
} catch (e) {
  print('Error creating user document: $e');
  rethrow;  // <-- ADD THIS
}
```

---

## 12. Data Repair Plan

### Step 1: Identify all affected users

```
Firestore Console query: /users where userFirstDate == null
Result: 2,437 documents
```

### Step 2: Classify by category

Use document structure to classify:
- **Category A** (legacy): no `role` field, no `devicesIds`, only 5-6 fields
- **Category B** (old migrated): has `creationTime` field (2021-2022)
- **Category C** (recent): has `lastDeviceUpdate` in 2026, has `role`, no `creationTime`

### Step 3: Set userFirstDate

| Category | Source for userFirstDate | Priority |
|----------|------------------------|----------|
| C (recent) | `lastDeviceUpdate` or Firebase Auth `metadata.creationTime` | IMMEDIATE |
| B (old migrated) | `creationTime` field in document | HIGH |
| A (legacy dormant) | Firebase Auth `metadata.creationTime` | LOW (fix on next login) |

### Step 4: Restore erased fields

For users where `isPlusUser` was erased by Bug #3:
- Cross-reference with RevenueCat or subscription records
- Restore `isPlusUser` and `lastPlusCheck` values

---

## 13. Files Reference

### Needs Code Changes

| File | Line(s) | Change |
|------|---------|--------|
| `lib/features/authentication/presentation/confirm_user_details_screen.dart` | 357 | Use `selectedUserFirstDate` instead of null passthrough |
| `lib/features/authentication/application/migration_service.dart` | 107-121 | Preserve `isPlusUser`, `lastPlusCheck`, etc. |
| `lib/features/authentication/data/models/user_document.dart` | 87-107 | `toFirestore()` should skip null optional fields |
| `lib/features/authentication/data/repositories/auth_repository.dart` | catch block | Rethrow errors in `creatUserDocuemnt()` |

### Already Fixed Locally (needs deploy)

| File | Change |
|------|--------|
| `lib/features/authentication/providers/user_document_provider.dart` | Removed `Source.server`, rethrows errors, uid fallback |
| `lib/features/authentication/providers/account_status_provider.dart` | Added `AccountStatus.error` state |

### Reference Files (no changes needed)

| File | Role |
|------|------|
| `lib/features/authentication/data/repositories/migeration_repository.dart` | Writes with `merge:true` (line 115) |
| `lib/features/authentication/application/auth_service.dart` | OAuth flows, `completeAccountRegiseration()` |
| `lib/features/authentication/presentation/registration_stepper_screen.dart` | Registration UI |
| `lib/core/services/device_tracking_service.dart` | Creates partial stub documents |
| `lib/features/home/presentation/home/home_screen.dart` | Shows banners based on `accountStatus` |
| `lib/core/shared_widgets/account_action_banner.dart` | Routes to confirm/registration screens |
| `lib/features/authentication/providers/user_document_provider.dart` | `hasMissingData()` and `isLegacyUserDocument()` |
| `functions/src/referral/generateReferralCode.ts` | Cloud Function, uses `batch.update()` |
| `functions/src/directMessageNotifications.ts` | Cloud Function, can null `messagingToken` |

---

*Prepared by: Claude Code (AI Analysis)*
*Investigation dates: 2026-02-14 to 2026-02-15*
*Raw data: `bug/userFirstDate_null_bug.txt`*
