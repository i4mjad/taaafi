import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/follow_up_service.dart';
import 'package:reboot_app_3/features/shared/models/follow_up.dart';
import 'package:reboot_app_3/features/home/data/repos/follow_up_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_up_notifier.g.dart';

@riverpod
class FollowUpNotifier extends _$FollowUpNotifier {
  FollowUpService get service => ref.read(followUpServiceProvider);

  @override
  FutureOr<List<FollowUpModel>> build() async {
    final followUps = await service.getFollowUps();
    return followUps;
  }

  Future<void> createFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await service.createFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFollowUp(FollowUpModel followUp) async {
    state = const AsyncValue.loading();
    try {
      await service.updateFollowUp(followUp: followUp);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFollowUp(String followUpId) async {
    state = const AsyncValue.loading();
    try {
      await service.deleteFollowUp(followUpId: followUpId);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAllFollowUps() async {
    state = const AsyncValue.loading();
    try {
      await service.deleteAllFollowUps();
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createMultipleFollowUps(List<FollowUpModel> followUps) async {
    state = const AsyncValue.loading();
    try {
      await service.createMultipleFollowUps(followUps: followUps);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<FollowUpModel>> getFollowUpsByDate(DateTime date) async {
    return await service.getFollowUpsByDate(date);
  }

  Stream<List<FollowUpModel>> watchFollowUpsByDate(DateTime date) {
    return service.getFollowUpsByDateStream(date);
  }
}

@Riverpod(keepAlive: true)
FollowUpService followUpService(FollowUpServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = FollowUpRepository(firestore);
  return FollowUpService(repository);
}
