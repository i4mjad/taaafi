import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/home/application/emotion_service.dart';
import 'package:reboot_app_3/features/home/data/models/emotion_model.dart';
import 'package:reboot_app_3/features/home/data/repos/emotion_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emotion_notifier.g.dart';

@riverpod
class EmotionNotifier extends _$EmotionNotifier {
  late final EmotionService _service;

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

  Future<List<EmotionModel>> getEmotionsByDate(DateTime date) async {
    return await _service.readEmotionsByDate(date);
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

  Future<void> deleteEmotion(String emotionId) async {
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Stream<List<EmotionModel>> watchEmotionsByDate(DateTime date) {
    return _service.watchEmotionsByDate(date);
  }
}

@Riverpod(keepAlive: true)
EmotionService emotionService(EmotionServiceRef ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final repository = EmotionRepository(firestore, auth);
  return EmotionService(repository);
}
