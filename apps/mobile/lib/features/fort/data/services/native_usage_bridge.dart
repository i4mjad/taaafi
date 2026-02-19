import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/fort/domain/models/usage_summary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'native_usage_bridge.g.dart';

/// Unified bridge for native usage data on iOS and Android.
///
/// Android: Uses existing `analytics.usage` MethodChannel with UsageStatsManager.
/// iOS: Uses `com.taaafi.fort` MethodChannel with Screen Time API (FamilyControls).
class NativeUsageBridge {
  static const _androidChannel = MethodChannel('analytics.usage');
  static const _iosChannel = MethodChannel('com.taaafi.fort');

  /// Check if the app has permission to read usage data.
  Future<bool> checkUsagePermission() async {
    try {
      if (Platform.isAndroid) {
        final result =
            await _androidChannel.invokeMethod<bool>('android_checkUsageAccess');
        return result ?? false;
      } else if (Platform.isIOS) {
        final result =
            await _iosChannel.invokeMethod<bool>('ios_checkFamilyControlsAuth');
        return result ?? false;
      }
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Request permission to read usage data (opens system settings on Android,
  /// triggers FamilyControls auth on iOS).
  Future<bool> requestUsagePermission() async {
    try {
      if (Platform.isAndroid) {
        await _androidChannel.invokeMethod<bool>('android_requestUsageAccess');
        // Android opens settings — user must come back, so we re-check
        return checkUsagePermission();
      } else if (Platform.isIOS) {
        final result = await _iosChannel
            .invokeMethod<bool>('ios_requestFamilyControlsAuth');
        return result ?? false;
      }
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Get today's usage data from the native platform.
  Future<UsageSummary> getTodayUsage() async {
    try {
      if (Platform.isAndroid) {
        return _getAndroidUsage();
      } else if (Platform.isIOS) {
        return _getIosUsage();
      }
      return UsageSummary.empty(DateTime.now());
    } on PlatformException {
      return UsageSummary.empty(DateTime.now());
    }
  }

  Future<UsageSummary> _getAndroidUsage() async {
    final rawJson =
        await _androidChannel.invokeMethod<String>('android_getSnapshot');
    if (rawJson == null) return UsageSummary.empty(DateTime.now());

    final data = jsonDecode(rawJson) as Map<String, dynamic>;
    final apps = data['apps'] as List<dynamic>? ?? [];
    final pickups = (data['pickups'] as num?)?.toInt() ?? 0;

    // Aggregate apps into categories
    final categoryMinutes = <UsageCategoryType, int>{};
    for (final app in apps) {
      final pkg = app['pkg'] as String? ?? '';
      final minutes = (app['minutes'] as num?)?.toInt() ?? 0;
      final category = _categorizePackage(pkg);
      categoryMinutes[category] =
          (categoryMinutes[category] ?? 0) + minutes;
    }

    final categories = categoryMinutes.entries
        .map((e) => UsageCategory(type: e.key, minutes: e.value))
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    final totalMinutes =
        categories.fold<int>(0, (sum, c) => sum + c.minutes);

    return UsageSummary(
      date: DateTime.now(),
      categories: categories,
      totalScreenTimeMinutes: totalMinutes,
      pickups: pickups,
    );
  }

  Future<UsageSummary> _getIosUsage() async {
    try {
      final rawJson =
          await _iosChannel.invokeMethod<String>('ios_getUsageReport');
      if (rawJson == null) return UsageSummary.empty(DateTime.now());

      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      return UsageSummary.fromJson(data);
    } on PlatformException {
      return UsageSummary.empty(DateTime.now());
    }
  }

  /// Map an Android package name to a usage category.
  static UsageCategoryType _categorizePackage(String packageName) {
    final pkg = packageName.toLowerCase();

    // Social media
    if (_matchesAny(pkg, [
      'instagram', 'facebook', 'twitter', 'tiktok', 'snapchat',
      'reddit', 'linkedin', 'pinterest', 'tumblr', 'threads',
      'com.zhiliaoapp.musically', // TikTok
    ])) return UsageCategoryType.socialMedia;

    // Entertainment
    if (_matchesAny(pkg, [
      'youtube', 'netflix', 'spotify', 'twitch', 'hulu',
      'disney', 'hbo', 'vimeo', 'deezer', 'anghami',
      'video', 'music', 'media', 'player',
    ])) return UsageCategoryType.entertainment;

    // Games
    if (_matchesAny(pkg, [
      'game', 'games', 'gaming', 'supercell', 'rovio',
      'king.com', 'gameloft', 'ea.game', 'com.kiloo',
    ])) return UsageCategoryType.games;

    // Communication
    if (_matchesAny(pkg, [
      'whatsapp', 'telegram', 'signal', 'messenger', 'viber',
      'wechat', 'line', 'kakaotalk', 'discord', 'slack',
      'com.google.android.apps.messaging', 'sms', 'dialer', 'phone',
    ])) return UsageCategoryType.communication;

    // Productivity
    if (_matchesAny(pkg, [
      'docs', 'sheets', 'slides', 'drive', 'notion', 'todoist',
      'trello', 'asana', 'evernote', 'onenote', 'office',
      'calendar', 'calculator', 'clock', 'files',
    ])) return UsageCategoryType.productivity;

    // Education
    if (_matchesAny(pkg, [
      'duolingo', 'coursera', 'udemy', 'khan', 'quizlet',
      'learn', 'education', 'school', 'university',
    ])) return UsageCategoryType.education;

    // Health
    if (_matchesAny(pkg, [
      'health', 'fitness', 'workout', 'meditation', 'calm',
      'headspace', 'strava', 'fitbit', 'myfitnesspal',
    ])) return UsageCategoryType.health;

    // News
    if (_matchesAny(pkg, [
      'news', 'bbc', 'cnn', 'aljazeera', 'reuters',
      'guardian', 'nytimes', 'flipboard',
    ])) return UsageCategoryType.news;

    return UsageCategoryType.other;
  }

  static bool _matchesAny(String pkg, List<String> keywords) {
    return keywords.any((kw) => pkg.contains(kw));
  }
}

@Riverpod(keepAlive: true)
NativeUsageBridge nativeUsageBridge(Ref ref) {
  return NativeUsageBridge();
}
