import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'revenue_cat_auth_sync_service.dart';
import '../data/services/revenue_cat_service.dart';

part 'revenue_cat_test_helper.g.dart';

/// Helper class for testing and debugging RevenueCat integration
class RevenueCatTestHelper {
  final RevenueCatService _revenueCatService;
  final RevenueCatAuthSyncService _authSyncService;

  RevenueCatTestHelper(this._revenueCatService, this._authSyncService);

  /// Test RevenueCat availability and provide diagnostic information
  Future<RevenueCatDiagnostics> diagnose() async {
    final diagnostics = RevenueCatDiagnostics();

    // Test basic availability
    try {
      diagnostics.isPluginAvailable = await _revenueCatService.isAvailable();
    } catch (e) {
      diagnostics.isPluginAvailable = false;
      diagnostics.availabilityError = e.toString();
    }

    // Test customer info retrieval
    if (diagnostics.isPluginAvailable) {
      try {
        final customerInfo = await _revenueCatService.getCustomerInfo();
        diagnostics.canGetCustomerInfo = true;
        diagnostics.currentUserId = customerInfo.originalAppUserId;
      } catch (e) {
        diagnostics.canGetCustomerInfo = false;
        diagnostics.customerInfoError = e.toString();
      }
    }

    // Test auth sync service
    try {
      final revenueCatUserId =
          await _authSyncService.getCurrentRevenueCatUserId();
      diagnostics.authSyncWorking = true;
      diagnostics.syncedUserId = revenueCatUserId;
    } catch (e) {
      diagnostics.authSyncWorking = false;
      diagnostics.authSyncError = e.toString();
    }

    return diagnostics;
  }

  /// Get a user-friendly status message
  Future<String> getStatusMessage() async {
    final diagnostics = await diagnose();

    if (!diagnostics.isPluginAvailable) {
      return '''
🔴 RevenueCat Status: NOT AVAILABLE
❌ Plugin not properly installed
💡 Solution: Try restarting the app or rebuilding with:
   flutter clean && flutter pub get && flutter run

Error: ${diagnostics.availabilityError ?? 'Unknown'}
''';
    }

    if (!diagnostics.canGetCustomerInfo) {
      return '''
🟡 RevenueCat Status: PARTIALLY WORKING
✅ Plugin installed
❌ Cannot retrieve customer info
💡 Check API keys and network connection

Error: ${diagnostics.customerInfoError ?? 'Unknown'}
''';
    }

    return '''
🟢 RevenueCat Status: WORKING
✅ Plugin installed and working
✅ Customer info accessible
✅ Auth sync: ${diagnostics.authSyncWorking ? 'Working' : 'Failed'}
👤 Current user: ${diagnostics.currentUserId ?? 'Anonymous'}
''';
  }
}

/// Diagnostic information about RevenueCat status
class RevenueCatDiagnostics {
  bool isPluginAvailable = false;
  bool canGetCustomerInfo = false;
  bool authSyncWorking = false;
  String? availabilityError;
  String? customerInfoError;
  String? authSyncError;
  String? currentUserId;
  String? syncedUserId;

  @override
  String toString() {
    return '''
RevenueCat Diagnostics:
- Plugin Available: $isPluginAvailable
- Customer Info: $canGetCustomerInfo
- Auth Sync: $authSyncWorking
- Current User: $currentUserId
- Synced User: $syncedUserId
- Errors: ${[
      availabilityError,
      customerInfoError,
      authSyncError
    ].where((e) => e != null).join(', ')}
''';
  }
}

@riverpod
RevenueCatTestHelper revenueCatTestHelper(Ref ref) {
  return RevenueCatTestHelper(
    ref.read(revenueCatServiceProvider),
    ref.read(revenueCatAuthSyncServiceProvider),
  );
}
