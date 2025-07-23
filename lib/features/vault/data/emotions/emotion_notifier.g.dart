// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotion_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$emotionServiceHash() => r'284de5da99343cdd44267d72042ddec2232a01b1';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EmotionServiceRef = ProviderRef<EmotionService>;
String _$emotionNotifierHash() => r'7a6d2f6e6a50fd08c4c9a3136d7b77ec1a180921';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
