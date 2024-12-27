// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$emotionServiceHash() => r'2b6b7e5acb37033a3930c6de7e08126fea1fc3cd';

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
String _$emotionNotifierHash() => r'1d3aa55a0780f669018f413cae8a385edf92f234';

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
