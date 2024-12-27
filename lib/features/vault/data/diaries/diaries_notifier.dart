import 'dart:async';
import 'package:reboot_app_3/features/vault/application/diaries/diaries_service.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_repository.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diaries_notifier.g.dart';

@riverpod
class DiariesNotifier extends _$DiariesNotifier {
  late final DiariesService _service;

  @override
  FutureOr<List<Diary>> build() async {
    _service = ref.read(diariesServiceProvider);
    final diaries = await _service.getDiaries();
    return diaries;
  }

  Future<void> fetchDiaries() async {
    state = const AsyncValue.loading();
    try {
      final diaries = await _service.getDiaries();
      state = AsyncValue.data(diaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDiary(Diary diary) async {
    state = const AsyncValue.loading();
    try {
      await _service.addDiary(diary);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDiary(String diaryId, Diary diary) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateDiary(diaryId, diary);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteDiary(diaryId);
      state = AsyncValue.data(await build());
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
