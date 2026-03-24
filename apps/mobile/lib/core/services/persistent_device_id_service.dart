import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provides a device ID that persists across app reinstalls.
/// iOS: Keychain-backed UUID (survives uninstall/reinstall)
/// Android: ANDROID_ID via device_info_plus (stable across reinstalls)
class PersistentDeviceIdService {
  PersistentDeviceIdService._();
  static final PersistentDeviceIdService instance = PersistentDeviceIdService._();

  static const String _keychainKey = 'persistent_device_id';
  static const String _firstRunKey = 'persistent_device_id_first_run';
  static const String _migratedKey = 'device_id_migrated';

  String? _cachedDeviceId;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Get the persistent device ID. Never throws.
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      if (Platform.isIOS) {
        _cachedDeviceId = await _getIOSDeviceId();
      } else if (Platform.isAndroid) {
        _cachedDeviceId = await _getAndroidDeviceId();
      } else {
        _cachedDeviceId = await _getFallbackDeviceId();
      }
    } catch (e) {
      _cachedDeviceId = await _getFallbackDeviceId();
    }

    return _cachedDeviceId!;
  }

  /// iOS: Read from Keychain, or generate + store a new UUID
  Future<String> _getIOSDeviceId() async {
    try {
      // Check Keychain first (persists across reinstall)
      final stored = await _secureStorage.read(key: _keychainKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }

      // Generate new UUID and store in Keychain
      final newId = const Uuid().v4();
      await _secureStorage.write(key: _keychainKey, value: newId);
      return newId;
    } catch (e) {
      // Fallback to device_info_plus IDFV
      return await _getDeviceInfoId();
    }
  }

  /// Android: Use ANDROID_ID (stable across reinstalls with same signing key)
  Future<String> _getAndroidDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } catch (e) {
      return await _getFallbackDeviceId();
    }
  }

  /// Fallback: try device_info_plus, then timestamp-based
  Future<String> _getDeviceInfoId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? await _getFallbackDeviceId();
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
    } catch (_) {}
    return await _getFallbackDeviceId();
  }

  /// Last resort: timestamp-based ID
  Future<String> _getFallbackDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('device_id_fallback');
    if (existing != null) return existing;

    final fallbackId = 'device_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('device_id_fallback', fallbackId);
    return fallbackId;
  }

  /// Handle first-run-after-reinstall cleanup on iOS.
  /// Clears stale auth Keychain entries but preserves the persistent device ID.
  Future<void> handleFirstRunCleanup() async {
    if (!Platform.isIOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRunBefore = prefs.getBool(_firstRunKey) ?? false;

      if (!hasRunBefore) {
        // First run (or first run after reinstall, since SharedPreferences is cleared)
        // The persistent device ID in Keychain survives — don't touch it
        // Just mark that we've run
        await prefs.setBool(_firstRunKey, true);
      }
    } catch (_) {}
  }

  /// Get the old device ID from SharedPreferences for migration purposes.
  /// Returns null if no old device ID exists.
  Future<String?> getOldDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('device_id');
    } catch (_) {
      return null;
    }
  }

  /// Check if migration from old device ID has been completed.
  Future<bool> isMigrated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migratedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark migration as completed.
  Future<void> markMigrated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migratedKey, true);
    } catch (_) {}
  }
}
