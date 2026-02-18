import 'models/cursor_content.dart';
import 'models/cursor_content_list.dart';
import 'models/cursor_content_type.dart';
import 'library_repository.dart';

class LibraryService {
  final LibraryRepository _repository;

  LibraryService(this._repository);

  /// Gets the latest 6 content items
  Future<List<CursorContent>> getLatestContent() async {
    try {
      return await _repository.getLatestContent();
    } catch (e) {
      // Use predefined snackbars to show error messages

      rethrow;
    }
  }

  /// Gets all featured lists
  Future<List<CursorContentList>> getFeaturedLists() async {
    try {
      return await _repository.getFeaturedLists();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets all content lists
  Future<List<CursorContentList>> getAllLists() async {
    try {
      return await _repository.getAllLists();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets details of a specific list
  Future<CursorContentList> getListDetails(String listId) async {
    try {
      return await _repository.getListDetails(listId);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets all content types
  Future<List<CursorContentType>> getContentTypes() async {
    try {
      return await _repository.getAllContentTypes();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets a content type by ID
  Future<CursorContentType> getContentTypeById(String typeId) async {
    try {
      return await _repository.getContentTypeById(typeId);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets content for a specific type
  Future<List<CursorContent>> getContentByType(String typeId) async {
    try {
      return await _repository.getContentByType(typeId);
    } catch (e) {
      rethrow;
    }
  }

  /// Searches for content and lists
  Future<(List<CursorContent>, List<CursorContentList>)> search(
      String query) async {
    try {
      return await _repository.search(query);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CursorContent>> getPaginatedContent({
    required int limit,
    CursorContent? lastDocument,
  }) async {
    try {
      return await _repository.getPaginatedContent(
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<(List<CursorContent>, List<CursorContentList>)> searchPaginated(
    String query, {
    required int limit,
    CursorContent? lastDocument,
  }) async {
    try {
      return await _repository.searchPaginated(
        query,
        limit: limit,
        lastDocument: lastDocument,
      );
    } catch (e) {
      rethrow;
    }
  }
}
