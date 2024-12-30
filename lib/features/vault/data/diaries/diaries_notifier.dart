import 'dart:async';
import 'package:reboot_app_3/features/vault/application/diaries/diaries_service.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_repository.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaries_notifier.g.dart';

@riverpod
class DiariesNotifier extends _$DiariesNotifier {
  DiariesService get service => ref.read(diariesServiceProvider);

  @override
  FutureOr<List<Diary>> build() async {
    final diaries = await service.getDiaries();
    return diaries;
  }

  Future<void> fetchDiaries() async {
    state = const AsyncValue.loading();
    try {
      final diaries = await service.getDiaries();
      state = AsyncValue.data(diaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDiary(Diary diary) async {
    state = const AsyncValue.loading();
    try {
      await service.addDiary(diary);
      final diaries = await service.getDiaries();
      state = AsyncValue.data(diaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDiary(String diaryId, Diary diary) async {
    state = const AsyncValue.loading();
    try {
      await service.updateDiary(diaryId, diary);
      final diaries = await service.getDiaries();
      state = AsyncValue.data(diaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    state = const AsyncValue.loading();
    try {
      await service.deleteDiary(diaryId);
      final diaries = await service.getDiaries();
      state = AsyncValue.data(diaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Diary>> searchDiaries(String query) async {
    final currentState = state.value ?? [];
    if (query.isEmpty) {
      return currentState;
    }

    final lowercaseQuery = query.toLowerCase();
    return currentState.where((diary) {
      return diary.title.toLowerCase().contains(lowercaseQuery) ||
          diary.plainText.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

@Riverpod(keepAlive: true)
DiariesService diariesService(DiariesServiceRef ref) {
  return DiariesService(FirebaseDiariesRepository());
}
