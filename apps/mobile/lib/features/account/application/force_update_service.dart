import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:reboot_app_3/features/account/data/models/force_update_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'force_update_service.g.dart';

/// Result of a force update check
class ForceUpdateResult {
  final ForceUpdateStatus status;
  final String? storeLink;
  final Map<String, String>? title;
  final Map<String, String>? message;
  final int dismissCooldownHours;
  final String? minimumVersion;

  const ForceUpdateResult._({
    required this.status,
    this.storeLink,
    this.title,
    this.message,
    this.dismissCooldownHours = 24,
    this.minimumVersion,
  });

  factory ForceUpdateResult.noUpdate() =>
      const ForceUpdateResult._(status: ForceUpdateStatus.noUpdate);

  factory ForceUpdateResult.forced({
    required String storeLink,
    required Map<String, String> title,
    required Map<String, String> message,
    required String minimumVersion,
  }) =>
      ForceUpdateResult._(
        status: ForceUpdateStatus.forcedUpdate,
        storeLink: storeLink,
        title: title,
        message: message,
        minimumVersion: minimumVersion,
      );

  factory ForceUpdateResult.optional({
    required String storeLink,
    required Map<String, String> title,
    required Map<String, String> message,
    required int dismissCooldownHours,
    required String minimumVersion,
  }) =>
      ForceUpdateResult._(
        status: ForceUpdateStatus.optionalUpdate,
        storeLink: storeLink,
        title: title,
        message: message,
        dismissCooldownHours: dismissCooldownHours,
        minimumVersion: minimumVersion,
      );

  bool get isForcedUpdate => status == ForceUpdateStatus.forcedUpdate;
  bool get isOptionalUpdate => status == ForceUpdateStatus.optionalUpdate;
  bool get needsUpdate => status != ForceUpdateStatus.noUpdate;
}

enum ForceUpdateStatus {
  noUpdate,
  optionalUpdate,
  forcedUpdate,
}

/// Service that checks Firestore for force update configuration
class ForceUpdateService {
  final FirebaseFirestore _firestore;

  ForceUpdateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ForceUpdateResult> checkForUpdate() async {
    try {
      final doc = await _fetchConfig();
      if (doc == null || !doc.exists) return ForceUpdateResult.noUpdate();

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return ForceUpdateResult.noUpdate();

      // Get platform-specific config
      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final platformData = data[platformKey] as Map<String, dynamic>?;
      if (platformData == null) return ForceUpdateResult.noUpdate();

      final config = ForceUpdateConfig.fromMap(platformData);
      if (!config.enabled) return ForceUpdateResult.noUpdate();

      // Get installed app version
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version; // e.g. "5.5.3"

      // Compare versions
      if (!isVersionOutdated(installedVersion, config.minimumVersion)) {
        return ForceUpdateResult.noUpdate();
      }

      // Update is needed — determine enforcement level
      if (config.isCurrentlyForced) {
        return ForceUpdateResult.forced(
          storeLink: config.storeLink,
          title: config.title,
          message: config.message,
          minimumVersion: config.minimumVersion,
        );
      }

      return ForceUpdateResult.optional(
        storeLink: config.storeLink,
        title: config.title,
        message: config.message,
        dismissCooldownHours: config.dismissCooldownHours,
        minimumVersion: config.minimumVersion,
      );
    } catch (e) {
      // FAIL OPEN: if we can't check, allow app usage
      debugPrint('Force update check failed: $e');
      return ForceUpdateResult.noUpdate();
    }
  }

  /// Fetch config with timeout, fallback to cache
  Future<DocumentSnapshot?> _fetchConfig() async {
    try {
      return await _firestore
          .doc('appConfig/forceUpdate')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return _firestore
            .doc('appConfig/forceUpdate')
            .get(const GetOptions(source: Source.cache));
      });
    } catch (e) {
      // Try cache as last resort
      try {
        return await _firestore
            .doc('appConfig/forceUpdate')
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        return null;
      }
    }
  }
}

/// Returns true if installed version is older than minimum version
bool isVersionOutdated(String installed, String minimum) {
  final iParts = installed.split('.').map(int.tryParse).toList();
  final mParts = minimum.split('.').map(int.tryParse).toList();
  for (var i = 0; i < 3; i++) {
    final iv = i < iParts.length ? (iParts[i] ?? 0) : 0;
    final mv = i < mParts.length ? (mParts[i] ?? 0) : 0;
    if (iv < mv) return true;
    if (iv > mv) return false;
  }
  return false;
}

@Riverpod(keepAlive: true)
Future<ForceUpdateResult> forceUpdateCheck(Ref ref) async {
  final service = ForceUpdateService();
  return service.checkForUpdate();
}
