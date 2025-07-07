import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reboot_app_3/features/community/data/repositories/community_repository.dart';
import 'package:reboot_app_3/features/community/domain/services/community_service.dart';
import 'package:reboot_app_3/features/community/presentation/notifiers/community_notifier.dart';

part 'community_providers.g.dart';

/// Provider for the Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for SharedPreferences instance
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for the CommunityRepository
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CommunityRepository(firestore);
});

/// Provider for the CommunityService
final communityServiceProvider = FutureProvider<CommunityService>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final prefs = await SharedPreferences.getInstance();
  return CommunityService(repository, prefs);
});

/// Provider for the CommunityNotifier
@riverpod
CommunityNotifier communityNotifier(Ref ref) {
  return CommunityNotifier();
}

/// Provider for tracking if the user has shown interest
final hasShownInterestProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('community_interest_recorded') ?? false;
});
