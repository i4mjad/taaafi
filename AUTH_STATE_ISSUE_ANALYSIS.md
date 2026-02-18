# Authentication State Persistence Issue - Root Cause Analysis

**Date:** January 3, 2026  
**Issue:** Users repeatedly losing authentication state on app launch  
**Severity:** Critical - Significant user churn reported  
**Status:** Analysis Complete - Pending Fix Implementation

---

## Executive Summary

Users are reporting that they must re-enter their credentials on each app launch. Investigation reveals that **Firebase Auth state IS persisting correctly**, but the app's business logic incorrectly treats Firestore network failures as "user not registered", redirecting authenticated users to onboarding.

---

## Problem Statement

- A significant number of users report losing auth state on app launch
- Issue is intermittent and difficult to reproduce in development
- Active user count is declining due to user frustration
- Issue appears random but affects a "quite big number" of users

---

## Root Cause Analysis

### Primary Cause: Forced Server-Only Firestore Queries

The app uses `Source.server` for critical user document queries, which **forces network requests** and **bypasses the local cache**.

#### Affected Code Locations

**1. `lib/features/authentication/providers/user_document_provider.dart` (Lines 56-59)**

```dart
final doc = await _firestore
    .collection('users')
    .doc(uid)
    .get(GetOptions(source: Source.server));  // ❌ Forces server request
```

**Impact:** When network is unavailable or slow:
- Query throws an exception
- Exception is caught and returns `null`
- App interprets this as "user document doesn't exist"
- `AccountStatus` becomes `needCompleteRegistration`
- User is redirected to onboarding/registration screen

**2. `lib/features/authentication/data/repositories/auth_repository.dart` (Lines 39-49)**

```dart
Future<bool> isUserDocumentExist() async {
  try {
    final docRef = await _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .get(GetOptions(source: Source.server));  // ❌ Forces server request
    return docRef.exists;
  } catch (e, stackTrace) {
    ref.read(errorLoggerProvider).logException(e, stackTrace);
    return false;  // ❌ Network error = document doesn't exist
  }
}
```

**Impact:** Network failure returns `false`, making the app believe the user has no account.

---

### Secondary Cause: Silent Error Swallowing

Errors are caught and converted to `null` returns, making network errors indistinguishable from "no data exists".

**`lib/features/authentication/data/repositories/auth_repository.dart` (Lines 29-36)**

```dart
Future<User?> getLoggedInUser() async {
  try {
    await _auth.currentUser?.reload();  // Can fail on network issues
    return await _auth.currentUser;
  } catch (e, stackTrace) {
    ref.read(errorLoggerProvider).logException(e, stackTrace);
    return null;  // ❌ Any error = no user logged in
  }
}
```

**Impact:** If `reload()` fails due to network issues, the method returns `null`, implying no user is authenticated.

---

### Account Status Provider Logic

**`lib/features/authentication/providers/account_status_provider.dart` (Lines 44-47)**

```dart
// If no document exists, user needs to complete registration
if (doc == null) {
  print('⚠️ ACCOUNT STATUS: needCompleteRegistration (No document)');
  return AccountStatus.needCompleteRegistration;
}
```

This logic **cannot distinguish** between:
1. User document genuinely doesn't exist (new user)
2. Network failed and couldn't fetch the document (existing user)

Both cases receive `doc == null`, leading to incorrect registration prompts.

---

## Why Issue Is Intermittent

The issue manifests only under specific conditions:

| Condition | Likelihood | Users Affected |
|-----------|------------|----------------|
| Poor mobile data signal | High | Mobile users in low-coverage areas |
| Weak WiFi connection | Medium | Users on congested networks |
| App launch during network transition | Medium | Users switching between WiFi/cellular |
| Firebase regional latency | Low | Users far from Firebase servers |
| iOS Background App Refresh | Medium | iOS users with background refresh enabled |
| Airplane mode then reconnect | High | Travel users |
| Brief network hiccups | Common | All users occasionally |

**Why developers can't reproduce:** Development typically occurs on stable, high-speed connections where Firestore queries always succeed.

---

## Technical Flow When Issue Occurs

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER LAUNCHES APP                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Firebase Auth Check: FirebaseAuth.instance.currentUser          │
│  Result: ✅ User IS authenticated (persisted in Keychain/SP)     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Firestore Query: Get user document (Source.server)             │
│  Network Status: ❌ Unavailable / Slow / Timeout                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Exception Caught → Returns null                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  AccountStatus Provider: doc == null                             │
│  Result: AccountStatus.needCompleteRegistration                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Router Redirect: User sent to /onboarding                       │
│  User Experience: "I was logged out!"                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Firebase Auth Persistence Reality

Firebase Auth on mobile platforms **automatically persists** authentication state:

| Platform | Storage Location | Persistence |
|----------|-----------------|-------------|
| iOS | Keychain | Survives app restart, reinstall* |
| Android | EncryptedSharedPreferences | Survives app restart |

*iOS Keychain may be cleared on device reset or in some edge cases.

**The authentication IS persisting correctly.** The issue is in the app's business logic layer, not Firebase Auth.

---

## Recommended Fixes

### Fix 1: Use Cache-First Strategy for User Document

```dart
Future<UserDocument?> getUserDocument(String uid) async {
  try {
    // Try cache first for instant response
    DocumentSnapshot<Map<String, dynamic>>? doc;
    
    try {
      doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(GetOptions(source: Source.cache));
      
      if (doc.exists) {
        // Return cached data immediately, refresh in background
        _refreshFromServer(uid);  // Fire and forget
        return UserDocument.fromFirestore(doc);
      }
    } catch (cacheError) {
      // Cache miss, try server
    }
    
    // Cache miss or empty, try server
    doc = await _firestore
        .collection('users')
        .doc(uid)
        .get(GetOptions(source: Source.server));
    
    if (!doc.exists) return null;
    return UserDocument.fromFirestore(doc);
    
  } catch (e, stackTrace) {
    // CRITICAL: Don't return null on network errors
    // Rethrow or return a specific error state
    ref.read(errorLoggerProvider).logException(e, stackTrace);
    rethrow;  // Let caller handle the error appropriately
  }
}
```

### Fix 2: Distinguish Network Errors from Missing Data

Create a result type that distinguishes between states:

```dart
sealed class UserDocumentResult {}
class UserDocumentSuccess extends UserDocumentResult {
  final UserDocument document;
  UserDocumentSuccess(this.document);
}
class UserDocumentNotFound extends UserDocumentResult {}
class UserDocumentNetworkError extends UserDocumentResult {
  final String error;
  UserDocumentNetworkError(this.error);
}
```

### Fix 3: Update Account Status Logic

```dart
// Handle network errors differently from missing documents
if (docResult is UserDocumentNetworkError) {
  // Show "network error" state, not "please register"
  return AccountStatus.networkError;
}
if (docResult is UserDocumentNotFound) {
  return AccountStatus.needCompleteRegistration;
}
```

### Fix 4: Add Retry Logic with Exponential Backoff

For critical auth-related queries, implement retry logic to handle transient network failures.

### Fix 5: Use Default Firestore Get (Cache + Server)

The simplest fix is to remove `Source.server` entirely:

```dart
// Before
.get(GetOptions(source: Source.server))

// After - uses cache + server by default
.get()
```

This allows Firestore to:
1. Return cached data immediately if available
2. Sync with server in background
3. Only fail if both cache and server are unavailable

---

## Verification Steps

After implementing fixes:

1. **Test in Airplane Mode:**
   - Launch app with no network
   - Authenticated user should NOT see registration screen
   - Should see appropriate "offline" indicator

2. **Test with Network Throttling:**
   - Use Charles Proxy or similar to simulate slow network
   - App should remain functional with cached data

3. **Test Cache Behavior:**
   - Log in with good network
   - Kill app, disable network, relaunch
   - User document should load from cache

4. **Monitor Production:**
   - Add analytics for `AccountStatus.needCompleteRegistration` events
   - Track if user was actually authenticated when this occurs

---

## Impact Assessment

| Metric | Current State | Expected After Fix |
|--------|--------------|-------------------|
| Auth state loss reports | High | Near zero |
| User churn from frustration | Significant | Minimal |
| App usability offline | Poor | Good |
| User trust | Declining | Restored |

---

## Files Requiring Changes

1. `lib/features/authentication/providers/user_document_provider.dart`
2. `lib/features/authentication/data/repositories/auth_repository.dart`
3. `lib/features/authentication/providers/account_status_provider.dart`
4. Consider adding: `lib/core/network/connectivity_service.dart`

---

## Conclusion

The root cause is **not a Firebase Auth persistence issue** but rather **aggressive server-only Firestore queries** combined with **error handling that treats network failures as missing data**. The fix involves implementing cache-first strategies and proper error state handling to distinguish between "user doesn't exist" and "couldn't reach server".

---

**Prepared by:** AI Code Analysis  
**Review requested from:** Development Team  
**Priority:** High - User-facing issue causing churn

---

## Independent Code Review (Codebase Validation)

**Reviewer Outcome:** The core problem is **not Firebase Auth persistence**, but **app logic treating “Firestore read failed” as “user is not registered / has no user document.”** This causes authenticated users to be blocked by “complete registration / confirm details” UX, which is easily perceived as “I got logged out.”

### What your analysis got right (verified in code)
- The user-document read in `lib/features/authentication/providers/user_document_provider.dart` is forced to the network via `GetOptions(source: Source.server)` and returns `null` on *any* exception.
- `lib/features/authentication/data/repositories/auth_repository.dart` implements `isUserDocumentExist()` using `Source.server` and returns `false` on *any* exception.
- `lib/features/authentication/providers/account_status_provider.dart` maps `doc == null` to `AccountStatus.needCompleteRegistration`, so “network failure” becomes “needs registration.”
- Firestore offline persistence is explicitly enabled in `lib/main.dart`, so bypassing cache with `Source.server` is particularly harmful.

### Corrections / inaccuracies in the writeup
- **Router redirect to `/onboarding` for authenticated users is not currently what happens.** The GoRouter redirect path comes from `RouteSecurityService`, which only checks device/user bans and whether `FirebaseAuth.currentUser` is null; it does **not** use `AccountStatus` or the user document. The “blocked” experience is implemented inside screens like `HomeScreen` / `VaultScreen` by showing full-screen banners when `AccountStatus != ok`.
- The `AuthRepository.getLoggedInUser()` + `currentUser.reload()` swallow pattern exists, but **it is not referenced by the current auth-state providers** (`UserNotifier` uses `authStateChanges()` and `_auth.currentUser` directly). So it’s a risky pattern, but likely not the main driver of this issue today.

### Additional findings (not covered in the writeup)
- **User document “uid” field requirement can falsely look like “no document.”** `UserDocument.fromFirestore()` reads `uid` only from the document field (it does not fall back to `doc.id`), and `UserDocumentsNotifier.getUserDocument()` returns `null` if `userDocument.uid == null`. Any legacy user docs missing the `uid` field will be treated as non-existent even when the Firestore document exists (this would be persistent, not intermittent).
- **Login flow can incorrectly sign users out on network failure.** In `AuthService.signInWithEmail()`, if `isUserDocumentExist()` returns `false` it signs the user out and shows a “different provider” error. Because `isUserDocumentExist()` returns `false` on exceptions (including network), this can misfire during login on poor connections.

### My root-cause conclusion
The primary root cause is **state conflation**: the app collapses multiple distinct states into a single `null/false` (“document missing”), then drives UX from that. With `Source.server`, normal mobile network instability becomes a frequent trigger.

**Reviewed by:** GPT-5.2 (Cursor AI Coding Agent)  
**Date:** January 3, 2026

