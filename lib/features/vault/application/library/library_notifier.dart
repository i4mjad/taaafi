import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/features/vault/data/library/library_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/library/library_service.dart';
import '../../data/library/cached_library_service.dart';
import '../../data/library/models/cursor_content.dart';
import '../../data/library/models/cursor_content_list.dart';
import '../../data/library/models/cursor_content_type.dart';

part 'library_notifier.g.dart';

@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  CachedLibraryService get _service => ref.read(cachedLibraryServiceProvider);

  @override
  FutureOr<
      ({
        List<CursorContent> latestContent,
        List<CursorContentList> featuredLists,
        List<CursorContentType> contentTypes,
      })> build() async {
    // Use cached service to get library data
    return await _service.getLibraryData();
  }

  /// Force refresh the library data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.refreshData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload() async {
    await _service.clearCache();
    ref.invalidateSelf();
  }

  /// Fetches content for a specific type
  Future<List<CursorContent>> getContentByType(String typeId) async {
    return await _service.getContentByType(typeId);
  }

  /// Fetches a content type by ID
  Future<CursorContentType> getContentTypeById(String typeId) async {
    return await _service.getContentTypeById(typeId);
  }

  /// Fetches all content lists
  Future<List<CursorContentList>> getAllLists() async {
    return await _service.getAllLists();
  }

  /// Fetches details of a specific list
  Future<CursorContentList> getListDetails(String listId) async {
    return await _service.getListDetails(listId);
  }

  /// Performs a search across content and lists
  Future<(List<CursorContent>, List<CursorContentList>)> search(
      String query) async {
    try {
      return await _service.search(query);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

@riverpod
LibraryService libraryService(Ref ref) {
  return LibraryService(ref.watch(libraryRepositoryProvider));
}

@riverpod
CachedLibraryService cachedLibraryService(Ref ref) {
  return CachedLibraryService(ref.watch(libraryServiceProvider));
}

@riverpod
LibraryRepository libraryRepository(Ref ref) {
  return LibraryRepository(FirebaseFirestore.instance, ref);
}

@riverpod
class ContentListNotifier extends _$ContentListNotifier {
  LibraryService get _service => ref.read(libraryServiceProvider);

  @override
  FutureOr<List<CursorContent>> build() async {
    return [];
  }

  Future<List<CursorContent>> getPaginatedContent({
    required int limit,
    CursorContent? lastDocument,
  }) async {
    try {
      return await _service.getPaginatedContent(
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<(List<CursorContent>, List<CursorContentList>)> searchPaginated(
    String query, {
    required int limit,
    CursorContent? lastDocument,
  }) async {
    try {
      return await _service.searchPaginated(
        query,
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
