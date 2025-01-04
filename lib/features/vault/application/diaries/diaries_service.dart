import 'package:reboot_app_3/features/vault/data/diaries/diaries_repository.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';

class DiariesService {
  final DiariesRepository _repository;

  DiariesService(this._repository);

  Future<List<Diary>> getDiaries() async {
    return await _repository.getDiaries();
  }

  Future<void> addDiary(Diary diary) async {
    await _repository.addDiary(diary);
  }

  Future<void> updateDiary(String diaryId, Diary diary) async {
    await _repository.updateDiary(diaryId, diary);
  }

  Future<void> deleteDiary(String diaryId) async {
    await _repository.deleteDiary(diaryId);
  }

  Future<Diary?> getDiaryById(String diaryId) async {
    return await _repository.getDiaryById(diaryId);
  }

  Future<String> createEmptyDiary(Diary diary) async {
    return await _repository.createEmptyDiary(diary);
  }
}
