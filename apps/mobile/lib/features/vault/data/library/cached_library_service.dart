import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/cursor_content.dart';
import 'models/cursor_content_list.dart';
import 'models/cursor_content_type.dart';
import 'library_service.dart';

class CachedLibraryService {
  final LibraryService _libraryService;

  // In-memory cache
  static DateTime? _lastFetchTime;
  static ({
    List<CursorContent> latestContent,
    List<CursorContentList> featuredLists,
    List<CursorContentType> contentTypes,
  })? _cachedData;

  // Cache duration - 30 minutes for in-memory, 24 hours for persistent cache
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const Duration _persistentCacheExpiry = Duration(hours: 24);

  // SharedPreferences keys
  static const String _keyLatestContent = 'library_latest_content';
  static const String _keyFeaturedLists = 'library_featured_lists';
  static const String _keyContentTypes = 'library_content_types';
  static const String _keyLastUpdate = 'library_last_update';

  CachedLibraryService(this._libraryService);

  /// Gets library data with caching strategy:
  /// 1. Try in-memory cache first (30 min expiry)
  /// 2. Try SharedPreferences cache (24 hour expiry)
  /// 3. Fetch from remote and cache the result
  /// 4. On error, return cached data if available
  Future<
      ({
        List<CursorContent> latestContent,
        List<CursorContentList> featuredLists,
        List<CursorContentType> contentTypes,
      })> getLibraryData() async {
    try {
      // Check in-memory cache first
      if (_isInMemoryCacheValid()) {
        print('LibraryCache: Using in-memory cache');
        return _cachedData!;
      }

      // Check persistent cache
      final cachedData = await _getPersistentCache();
      if (cachedData != null) {
        print('LibraryCache: Using persistent cache');
        _cachedData = cachedData;
        _lastFetchTime = DateTime.now();
        return cachedData;
      }

      // Fetch fresh data
      print('LibraryCache: Fetching fresh data');
      final freshData = await _fetchFreshData();

      // Cache the fresh data
      await _cacheData(freshData);
      _cachedData = freshData;
      _lastFetchTime = DateTime.now();

      return freshData;
    } catch (e) {
      print('LibraryCache: Error fetching data: $e');

      // On error, try to return any available cached data
      if (_cachedData != null) {
        print('LibraryCache: Returning stale in-memory cache due to error');
        return _cachedData!;
      }

      final cachedData = await _getPersistentCache(ignoreExpiry: true);
      if (cachedData != null) {
        print('LibraryCache: Returning stale persistent cache due to error');
        return cachedData;
      }

      rethrow;
    }
  }

  /// Force refresh data from remote
  Future<
      ({
        List<CursorContent> latestContent,
        List<CursorContentList> featuredLists,
        List<CursorContentType> contentTypes,
      })> refreshData() async {
    print('LibraryCache: Force refreshing data');
    clearInMemoryCache();

    final freshData = await _fetchFreshData();
    await _cacheData(freshData);
    _cachedData = freshData;
    _lastFetchTime = DateTime.now();

    return freshData;
  }

  /// Clear all caches
  Future<void> clearCache() async {
    clearInMemoryCache();
    await _clearPersistentCache();
  }

  /// Clear only in-memory cache
  void clearInMemoryCache() {
    _cachedData = null;
    _lastFetchTime = null;
  }

  /// Check if in-memory cache is valid
  bool _isInMemoryCacheValid() {
    return _cachedData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry;
  }

  /// Fetch fresh data from remote service
  Future<
      ({
        List<CursorContent> latestContent,
        List<CursorContentList> featuredLists,
        List<CursorContentType> contentTypes,
      })> _fetchFreshData() async {
    final results = await Future.wait([
      _libraryService.getLatestContent(),
      _libraryService.getFeaturedLists(),
      _libraryService.getContentTypes(),
    ]);

    final latestContent = results[0] as List<CursorContent>;
    final featuredLists = results[1] as List<CursorContentList>;
    final contentTypes = results[2] as List<CursorContentType>;

    return (
      latestContent: latestContent,
      featuredLists: featuredLists,
      contentTypes: contentTypes,
    );
  }

  /// Cache data to SharedPreferences
  Future<void> _cacheData(
      ({
        List<CursorContent> latestContent,
        List<CursorContentList> featuredLists,
        List<CursorContentType> contentTypes,
      }) data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setString(_keyLatestContent,
            jsonEncode(data.latestContent.map((e) => e.toJson()).toList())),
        prefs.setString(_keyFeaturedLists,
            jsonEncode(data.featuredLists.map((e) => e.toJson()).toList())),
        prefs.setString(_keyContentTypes,
            jsonEncode(data.contentTypes.map((e) => e.toJson()).toList())),
        prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch),
      ]);

      print('LibraryCache: Data cached to SharedPreferences');
    } catch (e) {
      print('LibraryCache: Failed to cache data: $e');
      // Don't rethrow - caching failure shouldn't break the app
    }
  }

  /// Get cached data from SharedPreferences
  Future<
      ({
        List<CursorContent> latestContent,
        List<CursorContentList> featuredLists,
        List<CursorContentType> contentTypes,
      })?> _getPersistentCache({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastUpdateTimestamp = prefs.getInt(_keyLastUpdate);
      if (lastUpdateTimestamp == null) return null;

      final lastUpdate =
          DateTime.fromMillisecondsSinceEpoch(lastUpdateTimestamp);
      final cacheAge = DateTime.now().difference(lastUpdate);

      // Check if cache is expired (unless we're ignoring expiry)
      if (!ignoreExpiry && cacheAge > _persistentCacheExpiry) {
        print(
            'LibraryCache: Persistent cache expired (${cacheAge.inHours} hours old)');
        return null;
      }

      final latestContentJson = prefs.getString(_keyLatestContent);
      final featuredListsJson = prefs.getString(_keyFeaturedLists);
      final contentTypesJson = prefs.getString(_keyContentTypes);

      if (latestContentJson == null ||
          featuredListsJson == null ||
          contentTypesJson == null) {
        return null;
      }

      final latestContent = (jsonDecode(latestContentJson) as List)
          .map((e) => CursorContent.fromJson(e))
          .toList();
      final featuredLists = (jsonDecode(featuredListsJson) as List)
          .map((e) => CursorContentList.fromJson(e))
          .toList();
      final contentTypes = (jsonDecode(contentTypesJson) as List)
          .map((e) => CursorContentType.fromJson(e))
          .toList();

      print(
          'LibraryCache: Retrieved persistent cache (${cacheAge.inMinutes} minutes old)');

      return (
        latestContent: latestContent,
        featuredLists: featuredLists,
        contentTypes: contentTypes,
      );
    } catch (e) {
      print('LibraryCache: Failed to retrieve persistent cache: $e');
      return null;
    }
  }

  /// Clear persistent cache
  Future<void> _clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_keyLatestContent),
        prefs.remove(_keyFeaturedLists),
        prefs.remove(_keyContentTypes),
        prefs.remove(_keyLastUpdate),
      ]);
      print('LibraryCache: Persistent cache cleared');
    } catch (e) {
      print('LibraryCache: Failed to clear persistent cache: $e');
    }
  }

  // Delegate other methods to the original service
  Future<List<CursorContent>> getContentByType(String typeId) async {
    return await _libraryService.getContentByType(typeId);
  }

  Future<CursorContentType> getContentTypeById(String typeId) async {
    return await _libraryService.getContentTypeById(typeId);
  }

  Future<List<CursorContentList>> getAllLists() async {
    return await _libraryService.getAllLists();
  }

  Future<CursorContentList> getListDetails(String listId) async {
    return await _libraryService.getListDetails(listId);
  }

  Future<(List<CursorContent>, List<CursorContentList>)> search(
      String query) async {
    return await _libraryService.search(query);
  }

  Future<List<CursorContent>> getPaginatedContent({
    required int limit,
    CursorContent? lastDocument,
  }) async {
    return await _libraryService.getPaginatedContent(
      limit: limit,
      lastDocument: lastDocument,
    );
  }

  Future<(List<CursorContent>, List<CursorContentList>)> searchPaginated(
    String query, {
    required int limit,
    CursorContent? lastDocument,
  }) async {
    return await _libraryService.searchPaginated(
      query,
      limit: limit,
      lastDocument: lastDocument,
    );
  }
}
