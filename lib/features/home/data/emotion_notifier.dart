import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/home/application/emotion_service.dart';
import 'package:reboot_app_3/features/home/data/models/emotion_model.dart';

import 'package:reboot_app_3/features/home/data/repos/emotion_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emotion_notifier.g.dart';

@riverpod
class EmotionNotifier extends _$EmotionNotifier {
  late final EmotionService _service;

  @override
  @override
  FutureOr<List<EmotionModel>> build() async {
    final date = DateTime.now(); // or any default date
    _service = ref.read(emotionServiceProvider);
    return await _service.readEmotionsByDate(date);
  }

  Future<void> createEmotion(EmotionModel emotion) async {
    state = const AsyncValue.loading();
    try {
      await _service.createEmotion(emotion: emotion);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> getEmotionsByDate(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      var emotions = await _service.readEmotionsByDate(date);
      state = AsyncValue.data(emotions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEmotion(EmotionModel emotion) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateEmotion(emotion: emotion);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEmotion(String emotionId, DateTime date) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteEmotion(emotionId: emotionId);
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAllEmotions(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteAllEmotions();
      state = AsyncValue.data(await build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createMultipleEmotions(List<EmotionModel> emotions) async {
    state = const AsyncValue.loading();
    try {
      await _service.createMultipleEmotions(emotions: emotions);
      state = AsyncValue.data(await build());

      // Refresh other notifiers
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@Riverpod(keepAlive: true)
EmotionService emotionService(EmotionServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final repository = EmotionRepository(firestore);
  return EmotionService(repository);
}
