// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$emotionServiceHash() => r'16746dd008b4805e91a0be2550fa39f4cf356ab4';

/// See also [emotionService].
@ProviderFor(emotionService)
final emotionServiceProvider = Provider<EmotionService>.internal(
  emotionService,
  name: r'emotionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$emotionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EmotionServiceRef = ProviderRef<EmotionService>;
String _$emotionNotifierHash() => r'8d6b8f6bedb19014233bf1d8c3c3b73038541410';

/// See also [EmotionNotifier].
@ProviderFor(EmotionNotifier)
final emotionNotifierProvider = AutoDisposeAsyncNotifierProvider<
    EmotionNotifier, List<EmotionModel>>.internal(
  EmotionNotifier.new,
  name: r'emotionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$emotionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EmotionNotifier = AutoDisposeAsyncNotifier<List<EmotionModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
