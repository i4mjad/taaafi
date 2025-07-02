// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_reports_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reportMessagesHash() => r'43edab30fabbcc991bd4cabf00b2fb45be6e7073';

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

/// Provider for report messages
///
/// Copied from [reportMessages].
@ProviderFor(reportMessages)
const reportMessagesProvider = ReportMessagesFamily();

/// Provider for report messages
///
/// Copied from [reportMessages].
class ReportMessagesFamily extends Family<AsyncValue<List<ReportMessage>>> {
  /// Provider for report messages
  ///
  /// Copied from [reportMessages].
  const ReportMessagesFamily();

  /// Provider for report messages
  ///
  /// Copied from [reportMessages].
  ReportMessagesProvider call(
    String reportId,
  ) {
    return ReportMessagesProvider(
      reportId,
    );
  }

  @override
  ReportMessagesProvider getProviderOverride(
    covariant ReportMessagesProvider provider,
  ) {
    return call(
      provider.reportId,
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
  String? get name => r'reportMessagesProvider';
}

/// Provider for report messages
///
/// Copied from [reportMessages].
class ReportMessagesProvider
    extends AutoDisposeFutureProvider<List<ReportMessage>> {
  /// Provider for report messages
  ///
  /// Copied from [reportMessages].
  ReportMessagesProvider(
    String reportId,
  ) : this._internal(
          (ref) => reportMessages(
            ref as ReportMessagesRef,
            reportId,
          ),
          from: reportMessagesProvider,
          name: r'reportMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reportMessagesHash,
          dependencies: ReportMessagesFamily._dependencies,
          allTransitiveDependencies:
              ReportMessagesFamily._allTransitiveDependencies,
          reportId: reportId,
        );

  ReportMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.reportId,
  }) : super.internal();

  final String reportId;

  @override
  Override overrideWith(
    FutureOr<List<ReportMessage>> Function(ReportMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReportMessagesProvider._internal(
        (ref) => create(ref as ReportMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        reportId: reportId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ReportMessage>> createElement() {
    return _ReportMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportMessagesProvider && other.reportId == reportId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, reportId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ReportMessagesRef on AutoDisposeFutureProviderRef<List<ReportMessage>> {
  /// The parameter `reportId` of this provider.
  String get reportId;
}

class _ReportMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<ReportMessage>>
    with ReportMessagesRef {
  _ReportMessagesProviderElement(super.provider);

  @override
  String get reportId => (origin as ReportMessagesProvider).reportId;
}

String _$userReportsServiceHash() =>
    r'd14f1fe55f092af31a036688ebc3b7dd84ed080c';

/// Provider for UserReportsService
///
/// Copied from [userReportsService].
@ProviderFor(userReportsService)
final userReportsServiceProvider =
    AutoDisposeProvider<UserReportsService>.internal(
  userReportsService,
  name: r'userReportsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userReportsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserReportsServiceRef = AutoDisposeProviderRef<UserReportsService>;
String _$userReportsRepositoryHash() =>
    r'f6964b5c42ea0026030bb10b43ea7027fabccb74';

/// Provider for UserReportsRepository
///
/// Copied from [userReportsRepository].
@ProviderFor(userReportsRepository)
final userReportsRepositoryProvider =
    AutoDisposeProvider<UserReportsRepository>.internal(
  userReportsRepository,
  name: r'userReportsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userReportsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserReportsRepositoryRef
    = AutoDisposeProviderRef<UserReportsRepository>;
String _$userReportsStreamHash() => r'9a219f1f5d2c050fec3efed78f07880ff0e6b4ae';

/// Provider for watching user reports stream
///
/// Copied from [userReportsStream].
@ProviderFor(userReportsStream)
final userReportsStreamProvider =
    AutoDisposeStreamProvider<List<UserReport>>.internal(
  userReportsStream,
  name: r'userReportsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userReportsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserReportsStreamRef = AutoDisposeStreamProviderRef<List<UserReport>>;
String _$reportMessagesStreamHash() =>
    r'c2cd73390d74513d9b5896fc737b263b55b52752';

/// Provider for watching report messages stream
///
/// Copied from [reportMessagesStream].
@ProviderFor(reportMessagesStream)
const reportMessagesStreamProvider = ReportMessagesStreamFamily();

/// Provider for watching report messages stream
///
/// Copied from [reportMessagesStream].
class ReportMessagesStreamFamily
    extends Family<AsyncValue<List<ReportMessage>>> {
  /// Provider for watching report messages stream
  ///
  /// Copied from [reportMessagesStream].
  const ReportMessagesStreamFamily();

  /// Provider for watching report messages stream
  ///
  /// Copied from [reportMessagesStream].
  ReportMessagesStreamProvider call(
    String reportId,
  ) {
    return ReportMessagesStreamProvider(
      reportId,
    );
  }

  @override
  ReportMessagesStreamProvider getProviderOverride(
    covariant ReportMessagesStreamProvider provider,
  ) {
    return call(
      provider.reportId,
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
  String? get name => r'reportMessagesStreamProvider';
}

/// Provider for watching report messages stream
///
/// Copied from [reportMessagesStream].
class ReportMessagesStreamProvider
    extends AutoDisposeStreamProvider<List<ReportMessage>> {
  /// Provider for watching report messages stream
  ///
  /// Copied from [reportMessagesStream].
  ReportMessagesStreamProvider(
    String reportId,
  ) : this._internal(
          (ref) => reportMessagesStream(
            ref as ReportMessagesStreamRef,
            reportId,
          ),
          from: reportMessagesStreamProvider,
          name: r'reportMessagesStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reportMessagesStreamHash,
          dependencies: ReportMessagesStreamFamily._dependencies,
          allTransitiveDependencies:
              ReportMessagesStreamFamily._allTransitiveDependencies,
          reportId: reportId,
        );

  ReportMessagesStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.reportId,
  }) : super.internal();

  final String reportId;

  @override
  Override overrideWith(
    Stream<List<ReportMessage>> Function(ReportMessagesStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReportMessagesStreamProvider._internal(
        (ref) => create(ref as ReportMessagesStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        reportId: reportId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ReportMessage>> createElement() {
    return _ReportMessagesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportMessagesStreamProvider && other.reportId == reportId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, reportId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ReportMessagesStreamRef
    on AutoDisposeStreamProviderRef<List<ReportMessage>> {
  /// The parameter `reportId` of this provider.
  String get reportId;
}

class _ReportMessagesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ReportMessage>>
    with ReportMessagesStreamRef {
  _ReportMessagesStreamProviderElement(super.provider);

  @override
  String get reportId => (origin as ReportMessagesStreamProvider).reportId;
}

String _$shouldShowReportButtonHash() =>
    r'd653f7612bd18e558ea0e774318f942c363bd4dc';

/// Provider for checking if report button should be shown
///
/// Copied from [shouldShowReportButton].
@ProviderFor(shouldShowReportButton)
final shouldShowReportButtonProvider = AutoDisposeFutureProvider<bool>.internal(
  shouldShowReportButton,
  name: r'shouldShowReportButtonProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shouldShowReportButtonHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ShouldShowReportButtonRef = AutoDisposeFutureProviderRef<bool>;
String _$userReportsNotifierHash() =>
    r'347e2fd9345c99d8e1ff1305f4da00db9aa58c04';

/// See also [UserReportsNotifier].
@ProviderFor(UserReportsNotifier)
final userReportsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    UserReportsNotifier, List<UserReport>>.internal(
  UserReportsNotifier.new,
  name: r'userReportsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userReportsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserReportsNotifier = AutoDisposeAsyncNotifier<List<UserReport>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
