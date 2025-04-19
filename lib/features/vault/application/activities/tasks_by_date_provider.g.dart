// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_by_date_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tasksByDateRangeHash() => r'8dcf1de6de5e4c461c640f777579469614cfd03d';

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

/// See also [tasksByDateRange].
@ProviderFor(tasksByDateRange)
const tasksByDateRangeProvider = TasksByDateRangeFamily();

/// See also [tasksByDateRange].
class TasksByDateRangeFamily
    extends Family<AsyncValue<List<OngoingActivityTask>>> {
  /// See also [tasksByDateRange].
  const TasksByDateRangeFamily();

  /// See also [tasksByDateRange].
  TasksByDateRangeProvider call(
    DateTime startDate,
    DateTime endDate,
  ) {
    return TasksByDateRangeProvider(
      startDate,
      endDate,
    );
  }

  @override
  TasksByDateRangeProvider getProviderOverride(
    covariant TasksByDateRangeProvider provider,
  ) {
    return call(
      provider.startDate,
      provider.endDate,
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
  String? get name => r'tasksByDateRangeProvider';
}

/// See also [tasksByDateRange].
class TasksByDateRangeProvider
    extends AutoDisposeFutureProvider<List<OngoingActivityTask>> {
  /// See also [tasksByDateRange].
  TasksByDateRangeProvider(
    DateTime startDate,
    DateTime endDate,
  ) : this._internal(
          (ref) => tasksByDateRange(
            ref as TasksByDateRangeRef,
            startDate,
            endDate,
          ),
          from: tasksByDateRangeProvider,
          name: r'tasksByDateRangeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tasksByDateRangeHash,
          dependencies: TasksByDateRangeFamily._dependencies,
          allTransitiveDependencies:
              TasksByDateRangeFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
        );

  TasksByDateRangeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final DateTime startDate;
  final DateTime endDate;

  @override
  Override overrideWith(
    FutureOr<List<OngoingActivityTask>> Function(TasksByDateRangeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TasksByDateRangeProvider._internal(
        (ref) => create(ref as TasksByDateRangeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<OngoingActivityTask>> createElement() {
    return _TasksByDateRangeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TasksByDateRangeProvider &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TasksByDateRangeRef
    on AutoDisposeFutureProviderRef<List<OngoingActivityTask>> {
  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;
}

class _TasksByDateRangeProviderElement
    extends AutoDisposeFutureProviderElement<List<OngoingActivityTask>>
    with TasksByDateRangeRef {
  _TasksByDateRangeProviderElement(super.provider);

  @override
  DateTime get startDate => (origin as TasksByDateRangeProvider).startDate;
  @override
  DateTime get endDate => (origin as TasksByDateRangeProvider).endDate;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
