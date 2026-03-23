# Persistent Device ID & Ban Circumvention Hardening — Research

> **Date:** 2026-03-23
> **Scope:** `apps/mobile/` — Flutter (iOS + Android)
> **Goal:** Make device bans truly unbypassable from the same physical device

---

## Table of Contents

1. [Current State & Vulnerabilities](#1-current-state--vulnerabilities)
2. [Persistent Device ID — Platform Research](#2-persistent-device-id--platform-research)
3. [Recommended Solution](#3-recommended-solution)
4. [Implementation Plan](#4-implementation-plan)
5. [Backward Compatibility](#5-backward-compatibility)
6. [Crash Safety](#6-crash-safety)
7. [Admin Panel Changes](#7-admin-panel-changes)

---

## 1. Current State & Vulnerabilities

### How Device ID Works Today

| Platform | Identifier Used | Source |
|----------|----------------|--------|
| Android | `androidInfo.id` (Android ID) | `device_info_plus` |
| iOS | `identifierForVendor` (IDFV) | `device_info_plus` |

**Storage:** `SharedPreferences` with key `device_id`

### What Resets and When

| Scenario | Android ID | iOS IDFV | SharedPreferences |
|----------|-----------|----------|-------------------|
| App update (Play Store / App Store) | Survives | Survives | Survives |
| App uninstall + reinstall | Survives (same signing key) | **RESETS** (if no other apps from same vendor) | **CLEARED** |
| Factory reset | **RESETS** | **RESETS** | **CLEARED** |
| Rooted/jailbroken device | Can be spoofed | Can be spoofed | Can be cleared |
| Clear app data | Survives | Survives | **CLEARED** |

### Current Ban Enforcement Gaps

1. **`user_ban` doesn't block new accounts** — Tied to old UID; new account = new UID = bypass.
2. **`device_ban` requires manual device selection** — Admin must manually pick devices from a checkbox list. If they forget, `restrictedDevices` is empty and the ban has no effect.
3. **iOS IDFV resets on reinstall** — Uninstall the app, reinstall, get a new IDFV, bypass the device ban.
4. **SharedPreferences is volatile** — Clearing app data or reinstalling loses the cached device ID.
5. **No server-side enforcement** — No Firestore rules or Cloud Functions check bans. A modified client can bypass all checks.
6. **No email-based ban correlation** — Banned user signs up with a new email, no cross-reference exists.

---

## 2. Persistent Device ID — Platform Research

### Option A: `flutter_secure_storage` (iOS Keychain + Android EncryptedSharedPreferences)

**Package:** [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) (v9.2.4+)

| Platform | Backend | Persists After Reinstall? |
|----------|---------|--------------------------|
| iOS | **Keychain** (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | **YES** — Keychain items survive app deletion and reinstall by default |
| Android | **EncryptedSharedPreferences** (backed by Android Keystore) | **NO** — Cleared on uninstall on Android 6+ |

**iOS Keychain Behavior:**
- Keychain items are tied to the device, NOT the app
- They persist across app uninstall/reinstall as long as the Keychain entry uses the correct accessibility level
- `flutter_secure_storage` uses `kSecAttrAccessibleWhenUnlocked` by default, which persists after reinstall
- Can be configured with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for even stronger persistence (survives restores but not device migration — which is what we want)

**Android EncryptedSharedPreferences Behavior:**
- Backed by Android Keystore
- **Does NOT persist** across app uninstall on Android 6+ (API 23+)
- The Keystore keys are deleted when the app is uninstalled

**Verdict:** Great for iOS. Not sufficient alone for Android.

### Option B: Android ID (`Settings.Secure.ANDROID_ID`)

- Already used in current implementation via `device_info_plus`
- Persists until factory reset
- On Android 8+ (API 26+): Unique per app signing key + user combo, but stable across reinstalls with the same signing key
- Since our minSdk is 23 and our app always uses the same signing key, this is reliable
- **Cannot be spoofed without root access**

**Verdict:** Excellent for Android. Already in use — just needs to be stored more reliably.

### Option C: Android Backup API (Auto Backup)

- Android Auto Backup (API 23+) can persist SharedPreferences across reinstalls
- Requires `android:allowBackup="true"` in `AndroidManifest.xml` and proper backup rules
- **Unreliable** — Users can disable backup, not all devices support it, and restore timing is unpredictable
- The app might launch BEFORE backup data is restored

**Verdict:** Not reliable enough as a primary mechanism. Too many edge cases.

### Option D: Hardware Fingerprinting (Multiple Signals)

Combine multiple device signals into a composite fingerprint:
- Android ID / IDFV
- Device model + manufacturer
- Screen resolution
- System version
- Total RAM
- Available processors

**Verdict:** Useful as a secondary signal, but not as a primary ID. Different apps on the same device would get different fingerprints, and OS updates can change some values.

### Option E: Firebase Installation ID (`firebase_installations`)

- Unique per app install
- **Resets on reinstall** — by design
- Not useful for persistent tracking

**Verdict:** Not suitable.

---

## 3. Recommended Solution

### Dual-Layer Persistent Device ID

Use a **two-layer approach** that covers both platforms reliably:

| Layer | iOS | Android |
|-------|-----|---------|
| **Primary (persists across reinstall)** | Keychain via `flutter_secure_storage` | `Settings.Secure.ANDROID_ID` via `device_info_plus` (already available) |
| **Secondary (backup/migration)** | Firestore `bannedDevices` collection (server-side) | Firestore `bannedDevices` collection (server-side) |

### Why This Works

**iOS:**
- `flutter_secure_storage` writes to iOS Keychain
- Keychain persists across app uninstall + reinstall
- Even if user deletes the app and reinstalls, the Keychain entry with the persistent device ID is still there
- The ONLY way to clear it is a full device erase (factory reset)

**Android:**
- `Settings.Secure.ANDROID_ID` is stable across reinstalls (same signing key, which we always use)
- It's already what `device_info_plus` returns via `androidInfo.id`
- Persists until factory reset
- We store this in `flutter_secure_storage` as well for consistency, but the Android ID itself is the source of truth

### Server-Side Enforcement (Critical Addition)

Create a `bannedDevices` Firestore collection:

```
bannedDevices/{deviceId}
├── deviceId: string
├── bannedAt: timestamp
├── reason: string
├── banId: string (reference to bans collection)
├── isActive: boolean
└── metadata: map (device model, OS, etc.)
```

**On every app startup (before login screen):**
1. Get persistent device ID (Keychain / Android ID)
2. Check `bannedDevices/{deviceId}` in Firestore
3. If document exists and `isActive == true` → show banned screen immediately
4. No login required — device is blocked regardless of account

This eliminates the need for the user to be logged in for device ban enforcement.

---

## 4. Implementation Plan

### Step 1: Add `flutter_secure_storage` dependency

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.2.4
```

**Native requirements:**
- **Android:** minSdk 23 (already satisfied) — EncryptedSharedPreferences auto-enabled
- **iOS:** No additional configuration needed — Keychain access is automatic

### Step 2: Create `PersistentDeviceIdService`

```dart
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

class PersistentDeviceIdService {
  static const String _persistentIdKey = 'persistent_device_id';

  // flutter_secure_storage with platform-specific options
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // This ensures the Keychain item:
      // 1. Persists across app reinstall
      // 2. Does NOT transfer to new devices (iCloud restore)
      // 3. Is available after first device unlock
    ),
  );

  /// Get or create a persistent device ID.
  /// - iOS: Stored in Keychain (survives reinstall)
  /// - Android: Uses Android ID (survives reinstall, resets on factory reset)
  Future<String> getPersistentDeviceId() async {
    try {
      // Try to read existing persistent ID from secure storage
      final existingId = await _secureStorage.read(key: _persistentIdKey);
      if (existingId != null && existingId.isNotEmpty) {
        return existingId;
      }

      // Generate new persistent ID
      final newId = await _generatePersistentId();

      // Store it in secure storage
      await _secureStorage.write(key: _persistentIdKey, value: newId);

      return newId;
    } catch (e) {
      // CRASH SAFETY: If secure storage fails, fall back to device_info_plus
      // This ensures the app never crashes due to device ID retrieval
      return await _getFallbackDeviceId();
    }
  }

  Future<String> _generatePersistentId() async {
    if (Platform.isAndroid) {
      // On Android, use Android ID directly — it's already persistent
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      // On iOS, generate a UUID and store in Keychain
      // Keychain survives reinstall, so this UUID is permanent
      return const Uuid().v4();
    }
    return const Uuid().v4();
  }

  Future<String> _getFallbackDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? const Uuid().v4();
      }
    } catch (_) {}
    return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

### Step 3: Update App Startup Flow

The device ban check must happen **before the login screen**, not after:

```
App Launch
  └─> Get persistent device ID (Keychain / Android ID)
      └─> Query bannedDevices/{deviceId} in Firestore
          ├─> BANNED → Show banned screen (no login option)
          └─> NOT BANNED → Continue to normal app flow
              └─> Auth check → Login/Home screen
                  └─> Existing security checks (user_ban, feature_ban)
```

### Step 4: Create `bannedDevices` Firestore Collection

When an admin creates a `device_ban`:
1. Cloud Function (or admin panel) writes to `bannedDevices/{deviceId}` for EACH device ID in the user's `devicesIds` array
2. The mobile app checks this collection at startup — no login required
3. This makes device bans independent of user accounts

### Step 5: Auto-Populate `restrictedDevices` on Ban Creation

When creating any permanent ban from the admin panel:
- Automatically fetch the user's `devicesIds` from their user document
- Auto-populate `restrictedDevices` with ALL of those device IDs
- Also write entries to `bannedDevices` collection for server-side enforcement
- Remove the manual checkbox selection — it's error-prone

---

## 5. Backward Compatibility

### Migrating Existing Users (App Update)

When an existing user updates the app to the new version:

1. **First launch after update:**
   - `PersistentDeviceIdService.getPersistentDeviceId()` is called
   - No existing value in secure storage (first time using it)
   - Falls through to `_generatePersistentId()`
   - **Android:** Returns `androidInfo.id` — **same value as before** (backward compatible)
   - **iOS:** Generates a new UUID and stores in Keychain

2. **iOS migration concern:**
   - On iOS, the old device ID was `identifierForVendor` (IDFV)
   - The new persistent ID will be a different UUID stored in Keychain
   - **Migration step needed:** On first launch after update, read the OLD device ID from SharedPreferences, and if it exists:
     - Store it alongside the new persistent ID
     - Update the user's `devicesIds` in Firestore to include BOTH the old IDFV and the new persistent UUID
     - This ensures existing bans against the old IDFV still work

3. **Android — zero migration needed:**
   - The Android ID is the same identifier used before and after the update
   - Fully backward compatible

### Migration Code (iOS)

```dart
Future<void> migrateFromLegacyDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final legacyId = prefs.getString('device_id');
  final hasMigrated = prefs.getBool('device_id_migrated') ?? false;

  if (legacyId != null && !hasMigrated) {
    final newPersistentId = await getPersistentDeviceId();

    // If IDs are different (iOS case), register both
    if (legacyId != newPersistentId) {
      // Update Firestore to include both IDs
      // The legacy ID stays for existing ban lookups
      // The new persistent ID is added for future lookups
    }

    await prefs.setBool('device_id_migrated', true);
  }
}
```

### Existing Bans

- Existing `device_ban` documents in the `bans` collection will continue to work
- The new `bannedDevices` collection is additive — it doesn't replace the existing system
- Both systems are checked during startup (belt and suspenders approach)

---

## 6. Crash Safety

### Guiding Principle

> The app must NEVER crash due to device ID retrieval or ban checking. Every operation has a fallback.

### Error Handling Strategy

| Operation | Can Fail? | Fallback |
|-----------|-----------|----------|
| `flutter_secure_storage` read | Yes (Keystore corruption, first boot edge case) | Fall back to `device_info_plus` |
| `flutter_secure_storage` write | Yes (storage full, permission denied) | Silently continue — ID is still usable for this session |
| `device_info_plus` read | Yes (very rare) | Generate timestamp-based fallback ID |
| Firestore `bannedDevices` read | Yes (offline, permission denied) | Fall through to existing ban checks (which are also wrapped in try/catch) |
| Firestore network timeout | Yes | Allow app to continue — existing behavior (fail-open with warning) |

### Android-Specific Safety

- `EncryptedSharedPreferences` can throw `KeyStoreException` on some Samsung devices with Knox
- The `AndroidOptions(encryptedSharedPreferences: true)` setting is required for API 23+
- If Keystore is corrupted, the catch block falls back to `device_info_plus`
- This is a known issue with `flutter_secure_storage` — our fallback handles it

### iOS-Specific Safety

- Keychain access can fail if the device is locked and accessibility is set to `when_unlocked`
- Using `first_unlock_this_device` ensures Keychain is accessible after the first device unlock (which always happens before the app can launch)
- On first boot after iOS update, Keychain might be briefly unavailable — the fallback covers this

### Startup Flow Error Handling

```
getPersistentDeviceId()
  ├─> Try secure storage read
  │   ├─> Success → return ID
  │   └─> Failure → try device_info_plus
  │       ├─> Success → return platform ID
  │       └─> Failure → return timestamp fallback
  │
checkDeviceBan(deviceId)
  ├─> Try Firestore bannedDevices query
  │   ├─> Found + active → BLOCK (show banned screen)
  │   ├─> Not found → ALLOW (continue to app)
  │   └─> Error → ALLOW with warning (fail-open, log error)
```

---

## 7. Admin Panel Changes

### Auto-Populate Device IDs on Ban Creation

When an admin creates a ban in `BanManagementCard.tsx`:

1. **Remove manual device checkbox selection** for `device_ban` type
2. **Auto-include ALL user devices** in `restrictedDevices`
3. **Write to `bannedDevices` collection** for each device ID

```typescript
// When creating a device_ban:
const handleCreateBan = async () => {
  // Auto-populate restrictedDevices with ALL user devices
  const banData = {
    ...formData,
    restrictedDevices: userDevices, // Auto-include all devices
    deviceIds: userDevices,
  };

  // Write ban document
  await addDoc(bansCollection, banData);

  // ALSO write to bannedDevices collection for server-side enforcement
  for (const deviceId of userDevices) {
    await setDoc(doc(db, 'bannedDevices', deviceId), {
      deviceId,
      bannedAt: serverTimestamp(),
      reason: formData.reason,
      banId: newBanDoc.id,
      userId: userId,
      isActive: true,
    });
  }
};
```

### Firestore Security Rules Addition

```
match /bannedDevices/{deviceId} {
  // Anyone can READ (needed for pre-auth ban check)
  allow read: if true;
  // Only admin can write
  allow write: if request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

---

## Summary of Changes Required

| # | Change | Scope | Risk |
|---|--------|-------|------|
| 1 | Add `flutter_secure_storage` to `pubspec.yaml` | `apps/mobile/` | Low — well-maintained package, 99%+ pub.dev score |
| 2 | Create `PersistentDeviceIdService` | `apps/mobile/lib/core/services/` | Low — additive, no existing code modified |
| 3 | Update `DeviceTrackingService` to use persistent ID | `apps/mobile/lib/core/services/` | Medium — must maintain backward compat |
| 4 | Update `StartupSecurityService` to check `bannedDevices` pre-auth | `apps/mobile/lib/features/account/` | Medium — changes startup flow |
| 5 | iOS migration logic for legacy IDFV → Keychain UUID | `apps/mobile/lib/core/services/` | Low — one-time migration |
| 6 | Create `bannedDevices` Firestore collection | `functions/` or `apps/admin/` | Low — new collection, no data migration |
| 7 | Auto-populate `restrictedDevices` in admin ban creation | `apps/admin/` | Low — UI change only |
| 8 | Add Firestore rules for `bannedDevices` | `firestore.rules` | Low — additive rule |
| 9 | **WARNING: Native change** — `flutter_secure_storage` adds native dependencies | `android/` + `ios/` | **Shorebird cannot OTA this — requires full app store release** |

---

## Decision Matrix

| Approach | Survives Reinstall (iOS) | Survives Reinstall (Android) | Survives Factory Reset | Crash Safe | Store Compliant | Complexity |
|----------|-------------------------|----------------------------|----------------------|------------|-----------------|------------|
| Current (SharedPrefs + device_info) | No | Yes | No | Yes | Yes | Low |
| **Recommended (Keychain + Android ID + Firestore)** | **Yes** | **Yes** | **No** | **Yes** | **Yes** | **Medium** |
| Hardware fingerprinting | Partial | Partial | Partial | Yes | Risky | High |
| Firebase Installation ID | No | No | No | Yes | Yes | Low |
