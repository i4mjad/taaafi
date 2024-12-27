import 'package:reboot_app_3/features/home/data/repos/emotion_repository.dart';
import 'package:reboot_app_3/features/home/data/models/emotion_model.dart';

class EmotionService {
  final EmotionRepository _repository;

  EmotionService(this._repository);

  Future<List<EmotionModel>> readEmotionsByDate(DateTime date) async {
    return await _repository.readEmotionsByDate(date);
  }

  Future<void> createEmotion({required EmotionModel emotion}) async {
    await _repository.createEmotion(emotion);
  }

  Future<void> updateEmotion({required EmotionModel emotion}) async {
    await _repository.updateEmotion(emotion);
  }

  Future<void> deleteEmotion({required String emotionId}) async {
    await _repository.deleteEmotion(emotionId);
  }

  Future<void> deleteAllEmotions() async {
    await _repository.deleteAllEmotions();
  }

  Future<void> createMultipleEmotions(
      {required List<EmotionModel> emotions}) async {
    await _repository.createMultipleEmotions(emotions);
  }

  Stream<List<EmotionModel>> watchEmotionsByDate(DateTime date) {
    return _repository.watchEmotionsByDate(date);
  }
}
