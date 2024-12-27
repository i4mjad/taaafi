import 'package:reboot_app_3/features/home/data/models/emotion_model.dart';
import 'package:reboot_app_3/features/home/data/repos/emotion_repository.dart';

/// A service that contains business logic or computation related to Emotions.
class EmotionService {
  final EmotionRepository _repository;

  EmotionService(this._repository);

  /// Creates a new emotion in Firestore.
  Future<void> createEmotion({
    required EmotionModel emotion,
  }) async {
    await _repository.createEmotion(emotion: emotion);
  }

  /// Creates multiple emotions in Firestore.
  Future<void> createMultipleEmotions({
    required List<EmotionModel> emotions,
  }) async {
    await _repository.createMultipleEmotions(emotions: emotions);
  }

  /// Reads all emotions for the user on a specific date.
  Future<List<EmotionModel>> readEmotionsByDate(DateTime date) async {
    return await _repository.readEmotionsByDate(date);
  }

  /// Updates an existing emotion.
  Future<void> updateEmotion({
    required EmotionModel emotion,
  }) async {
    await _repository.updateEmotion(emotion: emotion);
  }

  /// Deletes a single emotion by its ID.
  Future<void> deleteEmotion({
    required String emotionId,
  }) async {
    await _repository.deleteEmotion(emotionId: emotionId);
  }

  /// Deletes all emotions for the user.
  Future<void> deleteAllEmotions() async {
    await _repository.deleteAllEmotions();
  }
}
