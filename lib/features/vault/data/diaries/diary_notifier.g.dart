// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diariesServiceHash() => r'e8e29332a823cff24c81a6756a4a011cf27d3acc';

/// See also [diariesService].
@ProviderFor(diariesService)
final diariesServiceProvider = AutoDisposeProvider<DiariesService>.internal(
  diariesService,
  name: r'diariesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diariesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DiariesServiceRef = AutoDisposeProviderRef<DiariesService>;
String _$diaryNotifierHash() => r'f6e4104991ee6b0de8dd53badeea36f4a50fe22e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$DiaryNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Diary?> {
  late final String diaryId;

  FutureOr<Diary?> build(
    String diaryId,
  );
}

/// See also [DiaryNotifier].
@ProviderFor(DiaryNotifier)
const diaryNotifierProvider = DiaryNotifierFamily();

/// See also [DiaryNotifier].
class DiaryNotifierFamily extends Family<AsyncValue<Diary?>> {
  /// See also [DiaryNotifier].
  const DiaryNotifierFamily();

  /// See also [DiaryNotifier].
  DiaryNotifierProvider call(
    String diaryId,
  ) {
    return DiaryNotifierProvider(
      diaryId,
    );
  }

  @override
  DiaryNotifierProvider getProviderOverride(
    covariant DiaryNotifierProvider provider,
  ) {
    return call(
      provider.diaryId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'diaryNotifierProvider';
}

/// See also [DiaryNotifier].
class DiaryNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<DiaryNotifier, Diary?> {
  /// See also [DiaryNotifier].
  DiaryNotifierProvider(
    String diaryId,
  ) : this._internal(
          () => DiaryNotifier()..diaryId = diaryId,
          from: diaryNotifierProvider,
          name: r'diaryNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$diaryNotifierHash,
          dependencies: DiaryNotifierFamily._dependencies,
          allTransitiveDependencies:
              DiaryNotifierFamily._allTransitiveDependencies,
          diaryId: diaryId,
        );

  DiaryNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.diaryId,
  }) : super.internal();

  final String diaryId;

  @override
  FutureOr<Diary?> runNotifierBuild(
    covariant DiaryNotifier notifier,
  ) {
    return notifier.build(
      diaryId,
    );
  }

  @override
  Override overrideWith(DiaryNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: DiaryNotifierProvider._internal(
        () => create()..diaryId = diaryId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        diaryId: diaryId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<DiaryNotifier, Diary?>
      createElement() {
    return _DiaryNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryNotifierProvider && other.diaryId == diaryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, diaryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DiaryNotifierRef on AutoDisposeAsyncNotifierProviderRef<Diary?> {
  /// The parameter `diaryId` of this provider.
  String get diaryId;
}

class _DiaryNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DiaryNotifier, Diary?>
    with DiaryNotifierRef {
  _DiaryNotifierProviderElement(super.provider);

  @override
  String get diaryId => (origin as DiaryNotifierProvider).diaryId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
