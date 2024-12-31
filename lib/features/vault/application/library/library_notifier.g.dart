// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$libraryServiceHash() => r'bf78100b25129a202b38d294afa01e0c4a848e3d';

/// See also [libraryService].
@ProviderFor(libraryService)
final libraryServiceProvider = AutoDisposeProvider<LibraryService>.internal(
  libraryService,
  name: r'libraryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$libraryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LibraryServiceRef = AutoDisposeProviderRef<LibraryService>;
String _$libraryRepositoryHash() => r'23e5b59af4d5f57dd51d3d1002b480b360f6a5cd';

/// See also [libraryRepository].
@ProviderFor(libraryRepository)
final libraryRepositoryProvider =
    AutoDisposeProvider<LibraryRepository>.internal(
  libraryRepository,
  name: r'libraryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$libraryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LibraryRepositoryRef = AutoDisposeProviderRef<LibraryRepository>;
String _$libraryNotifierHash() => r'299a67bf0281e5ad67177a82236d8cf1f4f8c9c3';

/// See also [LibraryNotifier].
@ProviderFor(LibraryNotifier)
final libraryNotifierProvider = AutoDisposeAsyncNotifierProvider<
    LibraryNotifier,
    ({
      List<CursorContent> latestContent,
      List<CursorContentList> featuredLists,
      List<CursorContentType> contentTypes
    })>.internal(
  LibraryNotifier.new,
  name: r'libraryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$libraryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LibraryNotifier = AutoDisposeAsyncNotifier<
    ({
      List<CursorContent> latestContent,
      List<CursorContentList> featuredLists,
      List<CursorContentType> contentTypes
    })>;
String _$contentListNotifierHash() =>
    r'a122deecf6a707629563a16ebb41fd599aee9063';

/// See also [ContentListNotifier].
@ProviderFor(ContentListNotifier)
final contentListNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ContentListNotifier, List<CursorContent>>.internal(
  ContentListNotifier.new,
  name: r'contentListNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contentListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ContentListNotifier = AutoDisposeAsyncNotifier<List<CursorContent>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
