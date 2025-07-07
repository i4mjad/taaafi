// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$libraryServiceHash() => r'636f85e8605ad2ca84ece3c3d61141141d106c23';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LibraryServiceRef = AutoDisposeProviderRef<LibraryService>;
String _$libraryRepositoryHash() => r'8b4acbeba8d0e25621d8453b09dd650fe877f98f';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LibraryRepositoryRef = AutoDisposeProviderRef<LibraryRepository>;
String _$libraryNotifierHash() => r'ab85ccefc38ec64850ab32cf86e6929b28b30af4';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
