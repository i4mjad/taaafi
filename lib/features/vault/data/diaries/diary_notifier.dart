import 'package:reboot_app_3/features/vault/application/diaries/diaries_service.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_notifier.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_repository.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_notifier.g.dart';

@riverpod
class DiaryNotifier extends _$DiaryNotifier {
  @override
  FutureOr<Diary?> build(String diaryId) async {
    return _fetchDiary(diaryId);
  }

  Future<Diary?> _fetchDiary(String diaryId) async {
    try {
      return await ref.read(diariesServiceProvider).getDiaryById(diaryId);
    } catch (e) {
      throw Exception('Failed to fetch diary: $e');
    }
  }

  Future<void> updateDiary(String diaryId, Diary diary) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(diariesServiceProvider).updateDiary(diaryId, diary);

      // After successful update, refresh the diary data
      final updatedDiary = await _fetchDiary(diaryId);
      await ref.read(diariesNotifierProvider.notifier).updateDiariesState();
      state = AsyncValue.data(updatedDiary);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    try {
      await ref.read(diariesServiceProvider).deleteDiary(diaryId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for the DiariesService
@riverpod
DiariesService diariesService(DiariesServiceRef ref) {
  return DiariesService(FirebaseDiariesRepository(ref: ref));
}
