import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';
import 'package:reboot_app_3/features/community/application/gender_filtering_service.dart';

/// Container for paginated posts data
class PostsPage {
  final List<Post> posts;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PostsPage({
    required this.posts,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Container for paginated comments data
class CommentsPage {
  final List<Comment> comments;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const CommentsPage({
    required this.comments,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Container for paginated liked items data (posts or comments)
class LikedItemsPage {
  final List<dynamic> items; // Can be List<Post> or List<Comment>
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const LikedItemsPage({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}

class ForumRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _posts =
      FirebaseFirestore.instance.collection('forumPosts');
  final CollectionReference _comments =
      FirebaseFirestore.instance.collection('comments');
  final CollectionReference _interactions =
      FirebaseFirestore.instance.collection('interactions');
  final CollectionReference _postCategories =
      FirebaseFirestore.instance.collection('postCategories');
  final GenderFilteringService _genderFilteringService =
      GenderFilteringService();

  /// Get current user's community profile ID
  Future<String> get _currentUserCPId async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('communityProfiles')
          .where('userUID', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('No community profile found for user');
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      // Double-check that the profile is not deleted
      if (data['isDeleted'] == true) {
        throw Exception('No active community profile found for user');
      }

      return doc.id; // Return the document ID which is the community profile ID
    } catch (e) {
      if (e.toString().contains('No community profile found') ||
          e.toString().contains('No active community profile found')) {
        rethrow;
      }
      throw Exception('Failed to get community profile: ${e.toString()}');
    }
  }

  /// Get post categories from Firestore
  Future<List<PostCategory>> getPostCategories() async {
    try {
      final QuerySnapshot snapshot = await _postCategories
          .where('isForAdminOnly', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map((doc) {
        return PostCategory.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch post categories: $e');
    }
  }

  /// Stream of post categories from Firestore
  Stream<List<PostCategory>> watchPostCategories() {
    try {
      return _postCategories
          .where('isForAdminOnly', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                return PostCategory.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                );
              }).toList());
    } catch (e) {
      throw Exception('Failed to fetch post categories: $e');
    }
  }

  /// Get ALL post categories (including admin-only) for display purposes
  Future<List<PostCategory>> getAllPostCategories() async {
    try {
      final QuerySnapshot snapshot = await _postCategories
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map((doc) {
        return PostCategory.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch all post categories: $e');
    }
  }

  /// Stream of ALL post categories (including admin-only) for display purposes
  Stream<List<PostCategory>> watchAllPostCategories() {
    try {
      return _postCategories
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                return PostCategory.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                );
              }).toList());
    } catch (e) {
      throw Exception('Failed to fetch all post categories: $e');
    }
  }

  /// Get posts with pagination and optional gender filtering
  Future<PostsPage> getPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? category,
    bool? isPinned,
    String? userGender,
    bool applyGenderFilter = false,
  }) async {
    if (applyGenderFilter && userGender != null) {
      return await _getGenderFilteredPosts(
        limit: limit,
        lastDocument: lastDocument,
        category: category,
        isPinned: isPinned,
        userGender: userGender,
      );
    } else {
      return await _getUnfilteredPosts(
        limit: limit,
        lastDocument: lastDocument,
        category: category,
        isPinned: isPinned,
      );
    }
  }

  /// Search posts with advanced filtering options
  Future<PostsPage> searchPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? category,
    String sortBy = 'newest_first',
    DateTime? startDate,
    DateTime? endDate,
    String? userGender,
    bool applyGenderFilter = false,
  }) async {
    if (applyGenderFilter && userGender != null) {
      return await _searchGenderFilteredPosts(
        limit: limit,
        lastDocument: lastDocument,
        searchQuery: searchQuery,
        category: category,
        sortBy: sortBy,
        startDate: startDate,
        endDate: endDate,
        userGender: userGender,
      );
    } else {
      return await _searchUnfilteredPosts(
        limit: limit,
        lastDocument: lastDocument,
        searchQuery: searchQuery,
        category: category,
        sortBy: sortBy,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// Get posts without gender filtering (for pinned, news, challenges)
  Future<PostsPage> _getUnfilteredPosts({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? category,
    bool? isPinned,
  }) async {
    try {
      Query query = _posts
          .where('isDeleted',
              isEqualTo: false) // Filter deleted posts at source
          .orderBy('createdAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();

      // Convert to Post objects - no need for client-side filtering since we filtered at source
      final posts = snapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      final result = PostsPage(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );

      return result;
    } catch (e) {
      print('🔥 ERROR: Failed to fetch unfiltered posts: $e');
      print(
          '🔗 If this is an index error, check the link in the error message above for Firestore index requirements');
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get posts with gender filtering applied AFTER fetching
  /// This is much more efficient than batching through 666 profiles
  Future<PostsPage> _getGenderFilteredPosts({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? category,
    bool? isPinned,
    required String userGender,
  }) async {
    try {
      // Get allowed community profile IDs (same gender + admins + founders)
      final visibleProfileIds = await _genderFilteringService
          .getVisibleCommunityProfileIds(userGender);

      if (visibleProfileIds.isEmpty) {
        return const PostsPage(posts: [], hasMore: false);
      }

      // NEW EFFICIENT APPROACH: Get posts first, then filter by gender
      // This avoids the need for 67 separate queries!
      Query query = _posts
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Get more posts than needed to account for filtering
      // This ensures we get enough posts after gender filtering
      final multiplier =
          10; // Optimized to ensure admin/founder posts are found
      query = query.limit(limit * multiplier);

      final QuerySnapshot snapshot = await query.get();

      // Convert visible profile IDs to Set for O(1) lookup
      final visibleProfileSet = visibleProfileIds.toSet();

      // Filter posts by visible profile IDs
      final filteredPosts = <Post>[];
      DocumentSnapshot? lastValidDoc;

      for (final doc in snapshot.docs) {
        final post =
            Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        if (visibleProfileSet.contains(post.authorCPId)) {
          filteredPosts.add(post);
          lastValidDoc = doc;
          if (filteredPosts.length >= limit) {
            break;
          }
        }
      }

      // Determine if there are more posts
      final hasMore = filteredPosts.length == limit &&
          snapshot.docs.length == limit * multiplier;

      return PostsPage(
        posts: filteredPosts,
        lastDocument: lastValidDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      print('🔥 ERROR: Failed to fetch gender-filtered posts: $e');
      print(
          '🔗 If this is an index error, check the link in the error message above for Firestore index requirements');
      throw Exception('Failed to fetch gender-filtered posts: $e');
    }
  }

  /// Stream of posts from Firestore with optional gender filtering
  Stream<List<Post>> watchPosts({
    int limit = 10,
    String? category,
    bool? isPinned,
    String? userGender,
    bool applyGenderFilter = false,
  }) async* {
    if (applyGenderFilter && userGender != null) {
      yield* _watchGenderFilteredPosts(
        limit: limit,
        category: category,
        isPinned: isPinned,
        userGender: userGender,
      );
    } else {
      yield* _watchUnfilteredPosts(
        limit: limit,
        category: category,
        isPinned: isPinned,
      );
    }
  }

  /// Stream unfiltered posts
  Stream<List<Post>> _watchUnfilteredPosts({
    required int limit,
    String? category,
    bool? isPinned,
  }) {
    Query query = _posts
        .where('isDeleted', isEqualTo: false) // Filter deleted posts at source
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (isPinned != null) {
      query = query.where('isPinned', isEqualTo: isPinned);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      // Convert to Post objects - no client-side filtering needed
      final posts = snapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      return posts;
    });
  }

  /// Stream gender-filtered posts
  Stream<List<Post>> _watchGenderFilteredPosts({
    required int limit,
    String? category,
    bool? isPinned,
    required String userGender,
  }) async* {
    // Get visible profile IDs and watch for changes
    await for (final visibleProfileIds in _genderFilteringService
        .watchVisibleCommunityProfileIds(userGender)) {
      List<Post> genderFilteredPosts = [];

      if (visibleProfileIds.isNotEmpty) {
        // Try to get posts from valid profiles first
        genderFilteredPosts = await _getPostsFromProfiles(
            visibleProfileIds, limit, category, isPinned);
      }

      // If no posts found from valid profiles, try orphaned posts as fallback
      if (genderFilteredPosts.isEmpty) {
        try {
          final orphanedPosts =
              await _getOrphanedPosts(limit, category, isPinned);

          // For now, just return orphaned posts as fallback
          yield orphanedPosts;
        } catch (e) {
          // If orphaned posts check fails (e.g., permission issues), return empty list
          yield <Post>[];
        }
      } else {
        yield genderFilteredPosts;
      }
    }
  }

  /// Get posts from specific profile IDs
  Future<List<Post>> _getPostsFromProfiles(List<String> profileIds, int limit,
      String? category, bool? isPinned) async {
    try {
      final List<Post> allPosts = [];
      const int batchSize = 10;

      for (int i = 0; i < profileIds.length; i += batchSize) {
        final batch = profileIds.skip(i).take(batchSize).toList();

        Query query = _posts
            .where('authorCPId', whereIn: batch)
            .orderBy('createdAt', descending: true);

        if (category != null && category.isNotEmpty) {
          query = query.where('category', isEqualTo: category);
        }

        if (isPinned != null) {
          query = query.where('isPinned', isEqualTo: isPinned);
        }

        final snapshot = await query.limit(limit).get();

        final batchPosts = snapshot.docs
            .map((doc) => Post.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .where((post) => !post.isDeleted)
            .toList();

        allPosts.addAll(batchPosts);
      }

      // Sort by creation date and limit
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allPosts.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Combine multiple post streams and maintain sort order

  /// Get a single post by ID
  Future<Post?> getPost(String postId) async {
    try {
      final doc = await _posts.doc(postId).get();
      if (doc.exists) {
        return Post.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Search posts without gender filtering
  Future<PostsPage> _searchUnfilteredPosts({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? category,
    String sortBy = 'newest_first',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _posts;

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Apply date range filters
      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        // Add one day to endDate to include posts from the entire end date
        final endOfDay =
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      // Apply sorting
      switch (sortBy) {
        case 'oldest_first':
          query = query.orderBy('createdAt', descending: false);
          break;
        case 'most_liked':
          query = query.orderBy('likeCount', descending: true);
          break;
        case 'most_commented':
          // Note: We don't have a comment count field, so we'll fall back to score
          query = query.orderBy('score', descending: true);
          break;
        case 'newest_first':
        default:
          query = query.orderBy('createdAt', descending: true);
          break;
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();

      // Get all posts first
      List<Post> posts = snapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((post) => !post.isDeleted)
          .toList();

      // Apply text search filter if provided (client-side filtering)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        posts = posts.where((post) {
          return post.title.toLowerCase().contains(lowercaseQuery) ||
              post.body.toLowerCase().contains(lowercaseQuery);
        }).toList();
      }

      return PostsPage(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      print('🔥 ERROR: Failed to search posts: $e');
      print(
          '🔗 If this is an index error, check the link in the error message above for Firestore index requirements');
      throw Exception('Failed to search posts: $e');
    }
  }

  /// Search posts with gender filtering
  Future<PostsPage> _searchGenderFilteredPosts({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? category,
    String sortBy = 'newest_first',
    DateTime? startDate,
    DateTime? endDate,
    required String userGender,
  }) async {
    try {
      // Get visible profile IDs for gender filtering
      final visibleProfileIds = await _genderFilteringService
          .getVisibleCommunityProfileIds(userGender);

      if (visibleProfileIds.isEmpty) {
        return PostsPage(posts: [], lastDocument: null, hasMore: false);
      }

      // Split into batches due to Firestore 'whereIn' limit of 10
      final List<Post> allPosts = [];
      const int batchSize = 10;

      for (int i = 0; i < visibleProfileIds.length; i += batchSize) {
        final batch = visibleProfileIds.skip(i).take(batchSize).toList();

        Query query = _posts.where('authorCPId', whereIn: batch);

        // Apply category filter
        if (category != null && category.isNotEmpty) {
          query = query.where('category', isEqualTo: category);
        }

        // Apply date range filters
        if (startDate != null) {
          query = query.where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        if (endDate != null) {
          final endOfDay =
              DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
          query = query.where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
        }

        // Apply sorting
        switch (sortBy) {
          case 'oldest_first':
            query = query.orderBy('createdAt', descending: false);
            break;
          case 'most_liked':
            query = query.orderBy('likeCount', descending: true);
            break;
          case 'most_commented':
            query = query.orderBy('score', descending: true);
            break;
          case 'newest_first':
          default:
            query = query.orderBy('createdAt', descending: true);
            break;
        }

        final snapshot = await query
            .limit(limit * 2)
            .get(); // Get more to account for filtering

        final batchPosts = snapshot.docs
            .map((doc) => Post.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .where((post) => !post.isDeleted)
            .toList();

        allPosts.addAll(batchPosts);
      }

      // Apply text search filter if provided
      List<Post> filteredPosts = allPosts;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        filteredPosts = allPosts.where((post) {
          return post.title.toLowerCase().contains(lowercaseQuery) ||
              post.body.toLowerCase().contains(lowercaseQuery);
        }).toList();
      }

      // Sort and limit results
      switch (sortBy) {
        case 'oldest_first':
          filteredPosts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'most_liked':
          filteredPosts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
          break;
        case 'most_commented':
          filteredPosts.sort((a, b) => b.score.compareTo(a.score));
          break;
        case 'newest_first':
        default:
          filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      final limitedPosts = filteredPosts.take(limit).toList();

      return PostsPage(
        posts: limitedPosts,
        lastDocument:
            null, // For simplicity, pagination not supported with complex filtering
        hasMore: filteredPosts.length > limit,
      );
    } catch (e) {
      print('🔥 ERROR: Failed to search gender-filtered posts: $e');
      print(
          '🔗 If this is an index error, check the link in the error message above for Firestore index requirements');
      throw Exception('Failed to search gender-filtered posts: $e');
    }
  }

  /// Stream of a single post
  Stream<Post?> watchPost(String postId) {
    final user = FirebaseAuth.instance.currentUser;

    return _posts.doc(postId).snapshots().map((doc) {
      if (doc.exists) {
        return Post.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    });
  }

  /// Get comments for a post with optional gender filtering
  Future<List<Comment>> getComments(
    String postId, {
    String? userGender,
    bool applyGenderFilter = false,
  }) async {
    try {
      if (applyGenderFilter && userGender != null) {
        return await _getGenderFilteredComments(postId, userGender);
      } else {
        return await _getUnfilteredComments(postId);
      }
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<List<Comment>> _getUnfilteredComments(String postId) async {
    final QuerySnapshot snapshot = await _comments
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt')
        .get();

    return snapshot.docs
        .map((doc) => Comment.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .where((comment) => !comment.isDeleted)
        .toList();
  }

  Future<List<Comment>> _getGenderFilteredComments(
      String postId, String userGender) async {
    final visibleProfileIds =
        await _genderFilteringService.getVisibleCommunityProfileIds(userGender);

    if (visibleProfileIds.isEmpty) {
      return [];
    }

    // Batch comments queries
    const int batchSize = 10;
    final List<Comment> allComments = [];

    for (int i = 0; i < visibleProfileIds.length; i += batchSize) {
      final batch = visibleProfileIds.skip(i).take(batchSize).toList();

      final QuerySnapshot snapshot = await _comments
          .where('postId', isEqualTo: postId)
          .where('authorCPId', whereIn: batch)
          .orderBy('createdAt')
          .get();

      final batchComments = snapshot.docs
          .map((doc) => Comment.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((comment) => !comment.isDeleted)
          .toList();

      allComments.addAll(batchComments);
    }

    // Sort by creation date
    allComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return allComments;
  }

  /// Stream of comments for a post with optional gender filtering
  Stream<List<Comment>> watchComments(
    String postId, {
    String? userGender,
    bool applyGenderFilter = false,
  }) async* {
    if (applyGenderFilter && userGender != null) {
      yield* _watchGenderFilteredComments(postId, userGender);
    } else {
      yield* _watchUnfilteredComments(postId);
    }
  }

  Stream<List<Comment>> _watchUnfilteredComments(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .where((comment) => !comment.isDeleted)
            .toList());
  }

  /// Stream gender-filtered comments for a post
  Stream<List<Comment>> _watchGenderFilteredComments(
      String postId, String userGender) async* {
    await for (final visibleProfileIds in _genderFilteringService
        .watchVisibleCommunityProfileIds(userGender)) {
      if (visibleProfileIds.isEmpty) {
        yield [];
        continue;
      }

      // For comments, we can use a simpler approach since they're typically fewer in number
      const int batchSize = 10;
      final List<Stream<List<Comment>>> streamBatches = [];

      for (int i = 0; i < visibleProfileIds.length; i += batchSize) {
        final batch = visibleProfileIds.skip(i).take(batchSize).toList();

        final batchStream = _comments
            .where('postId', isEqualTo: postId)
            .where('authorCPId', whereIn: batch)
            .orderBy('createdAt')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => Comment.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>))
                .where((comment) => !comment.isDeleted)
                .toList());

        streamBatches.add(batchStream);
      }

      // For single batch, yield directly
      if (streamBatches.length == 1) {
        yield* streamBatches.first;
      } else {
        // For multiple batches, combine them
        yield* _combineCommentStreams(streamBatches);
      }
    }
  }

  /// Combine multiple comment streams and maintain sort order
  Stream<List<Comment>> _combineCommentStreams(
      List<Stream<List<Comment>>> streams) async* {
    final controller = StreamController<List<Comment>>();
    final List<List<Comment>> latestResults = List.filled(streams.length, []);
    final List<StreamSubscription> subscriptions = [];

    void updateResults() {
      // Combine all results
      final allComments = <Comment>[];
      for (final comments in latestResults) {
        allComments.addAll(comments);
      }

      // Sort by creation date
      allComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      controller.add(allComments);
    }

    // Subscribe to all streams
    for (int i = 0; i < streams.length; i++) {
      final subscription = streams[i].listen((comments) {
        latestResults[i] = comments;
        updateResults();
      });
      subscriptions.add(subscription);
    }

    yield* controller.stream;

    // Clean up subscriptions when done
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await controller.close();
  }

  /// Add a comment to a post or reply to a comment
  Future<void> addComment({
    required String postId,
    required String body,
    String? parentFor,
    String? parentId,
  }) async {
    try {
      final commentData = {
        'postId': postId,
        'authorCPId': await _currentUserCPId,
        'body': body,
        'parentFor': parentFor ?? 'post',
        'parentId': parentId ?? postId,
        'isDeleted': false,
        'isHidden': false,
        'score': 0,
        'likeCount': 0,
        'dislikeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };

      await _comments.add(commentData);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Creates a new post in Firestore
  Future<String> createPost({
    required String authorCPId,
    required String title,
    required String content,
    String? categoryId,
    List<String>? attachmentUrls,
  }) async {
    try {
      final now = DateTime.now();

      // Create post document data
      final postData = {
        'authorCPId': authorCPId,
        'title': title,
        'body': content,
        'category': categoryId ?? 'general',
        'isPinned': false,
        'isDeleted': false,
        'isCommentingAllowed': true,
        'isHidden': false,
        'score': 0,
        'likeCount': 0,
        'dislikeCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': null,
        // Note: attachmentUrls not implemented yet
      };

      // Add to Firestore and get the document reference
      final docRef = await _posts.add(postData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // =============================================================================
  // INTERACTION METHODS
  // =============================================================================

  /// Get a user's interaction with a specific target
  Future<Interaction?> getUserInteraction({
    required String targetType,
    required String targetId,
    String? userCPId,
  }) async {
    try {
      final userId = userCPId ?? await _currentUserCPId;

      final query = await _interactions
          .where('userCPId', isEqualTo: userId)
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Interaction.fromFirestore(
            query.docs.first as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user interaction: $e');
    }
  }

  /// Stream of user's interaction with a specific target
  Stream<Interaction?> watchUserInteraction({
    required String targetType,
    required String targetId,
    String? userCPId,
  }) {
    return Stream.fromFuture(_getWatchUserInteractionStream(
      targetType: targetType,
      targetId: targetId,
      userCPId: userCPId,
    )).asyncExpand((stream) => stream);
  }

  /// Helper method to get the stream after resolving user ID
  Future<Stream<Interaction?>> _getWatchUserInteractionStream({
    required String targetType,
    required String targetId,
    String? userCPId,
  }) async {
    final userId = userCPId ?? await _currentUserCPId;

    return _interactions
        .where('userCPId', isEqualTo: userId)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Interaction.fromFirestore(
            snapshot.docs.first as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    });
  }

  /// Stream of all interactions for a target
  Stream<List<Interaction>> watchTargetInteractions({
    required String targetType,
    required String targetId,
  }) {
    return _interactions
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Interaction.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Interact with a post (like/dislike)
  Future<void> interactWithPost({
    required String postId,
    required int value, // 1 for like, -1 for dislike, 0 for neutral
  }) async {
    try {
      final userId = await _currentUserCPId;

      // First, query for existing interaction outside transaction
      final existingInteractionQuery = await _interactions
          .where('userCPId', isEqualTo: userId)
          .where('targetType', isEqualTo: 'post')
          .where('targetId', isEqualTo: postId)
          .limit(1)
          .get();

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(_posts.doc(postId));

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentPost = Post.fromFirestore(
            postDoc as DocumentSnapshot<Map<String, dynamic>>);
        int likeCountChange = 0;
        int dislikeCountChange = 0;

        if (existingInteractionQuery.docs.isNotEmpty) {
          // User has an existing interaction
          final existingDoc = existingInteractionQuery.docs.first;
          // Re-read the interaction document within the transaction to ensure consistency
          final interactionDoc =
              await transaction.get(_interactions.doc(existingDoc.id));

          if (interactionDoc.exists) {
            final currentInteraction = Interaction.fromFirestore(
                interactionDoc as DocumentSnapshot<Map<String, dynamic>>);
            final oldValue = currentInteraction.value;

            // Calculate count changes
            if (oldValue == 1) likeCountChange = -1;
            if (oldValue == -1) dislikeCountChange = -1;
            if (value == 1) likeCountChange += 1;
            if (value == -1) dislikeCountChange += 1;

            if (value == 0) {
              // Remove interaction
              transaction.delete(_interactions.doc(existingDoc.id));
            } else {
              // Update interaction
              final updatedInteraction = currentInteraction.updateValue(value);
              transaction.set(_interactions.doc(existingDoc.id),
                  updatedInteraction.toFirestore());
            }
          } else {
            // Document was deleted between query and transaction, treat as new interaction
            if (value == 1) likeCountChange = 1;
            if (value == -1) dislikeCountChange = 1;

            if (value != 0) {
              final newInteraction = Interaction.create(
                targetType: 'post',
                targetId: postId,
                userCPId: userId,
                type: 'like',
                value: value,
              );
              // Use auto-generated document ID
              transaction.set(
                  _interactions.doc(), newInteraction.toFirestore());
            }
          }
        } else {
          // New interaction
          if (value == 1) likeCountChange = 1;
          if (value == -1) dislikeCountChange = 1;

          if (value != 0) {
            final newInteraction = Interaction.create(
              targetType: 'post',
              targetId: postId,
              userCPId: userId,
              type: 'like',
              value: value,
            );
            // Use auto-generated document ID
            transaction.set(_interactions.doc(), newInteraction.toFirestore());
          }
        }

        // Update post counts
        final newLikeCount = currentPost.likeCount + likeCountChange;
        final newDislikeCount = currentPost.dislikeCount + dislikeCountChange;
        final newScore = newLikeCount - newDislikeCount;

        transaction.update(_posts.doc(postId), {
          'likeCount': newLikeCount,
          'dislikeCount': newDislikeCount,
          'score': newScore,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to interact with post: $e');
    }
  }

  /// Interact with a comment (like/dislike)
  Future<void> interactWithComment({
    required String commentId,
    required int value, // 1 for like, -1 for dislike, 0 for neutral
  }) async {
    try {
      final userId = await _currentUserCPId;

      // First, query for existing interaction outside transaction
      final existingInteractionQuery = await _interactions
          .where('userCPId', isEqualTo: userId)
          .where('targetType', isEqualTo: 'comment')
          .where('targetId', isEqualTo: commentId)
          .limit(1)
          .get();

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(_comments.doc(commentId));

        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final currentComment = Comment.fromFirestore(
            commentDoc as DocumentSnapshot<Map<String, dynamic>>);
        int likeCountChange = 0;
        int dislikeCountChange = 0;

        if (existingInteractionQuery.docs.isNotEmpty) {
          // User has an existing interaction
          final existingDoc = existingInteractionQuery.docs.first;
          // Re-read the interaction document within the transaction to ensure consistency
          final interactionDoc =
              await transaction.get(_interactions.doc(existingDoc.id));

          if (interactionDoc.exists) {
            final currentInteraction = Interaction.fromFirestore(
                interactionDoc as DocumentSnapshot<Map<String, dynamic>>);
            final oldValue = currentInteraction.value;

            // Calculate count changes
            if (oldValue == 1) likeCountChange = -1;
            if (oldValue == -1) dislikeCountChange = -1;
            if (value == 1) likeCountChange += 1;
            if (value == -1) dislikeCountChange += 1;

            if (value == 0) {
              // Remove interaction
              transaction.delete(_interactions.doc(existingDoc.id));
            } else {
              // Update interaction
              final updatedInteraction = currentInteraction.updateValue(value);
              transaction.set(_interactions.doc(existingDoc.id),
                  updatedInteraction.toFirestore());
            }
          } else {
            // Document was deleted between query and transaction, treat as new interaction
            if (value == 1) likeCountChange = 1;
            if (value == -1) dislikeCountChange = 1;

            if (value != 0) {
              final newInteraction = Interaction.create(
                targetType: 'comment',
                targetId: commentId,
                userCPId: userId,
                type: 'like',
                value: value,
              );
              // Use auto-generated document ID
              transaction.set(
                  _interactions.doc(), newInteraction.toFirestore());
            }
          }
        } else {
          // New interaction
          if (value == 1) likeCountChange = 1;
          if (value == -1) dislikeCountChange = 1;

          if (value != 0) {
            final newInteraction = Interaction.create(
              targetType: 'comment',
              targetId: commentId,
              userCPId: userId,
              type: 'like',
              value: value,
            );
            // Use auto-generated document ID
            transaction.set(_interactions.doc(), newInteraction.toFirestore());
          }
        }

        // Update comment counts
        final newLikeCount = currentComment.likeCount + likeCountChange;
        final newDislikeCount =
            currentComment.dislikeCount + dislikeCountChange;
        final newScore = newLikeCount - newDislikeCount;

        transaction.update(_comments.doc(commentId), {
          'likeCount': newLikeCount,
          'dislikeCount': newDislikeCount,
          'score': newScore,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to interact with comment: $e');
    }
  }

  /// Legacy method for backward compatibility
  @deprecated
  Future<void> voteOnPost(String postId, int value) async {
    return interactWithPost(postId: postId, value: value);
  }

  /// Legacy method for backward compatibility
  @deprecated
  Future<void> voteOnComment({
    required String commentId,
    required int value,
  }) async {
    return interactWithComment(commentId: commentId, value: value);
  }

  /// Soft delete a post by setting isDeleted to true
  Future<void> deletePost(String postId) async {
    try {
      await _posts.doc(postId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Soft delete a comment by setting isDeleted to true
  Future<void> deleteComment(String commentId) async {
    try {
      await _comments.doc(commentId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Toggle commenting on a post
  Future<void> togglePostCommenting({
    required String postId,
    required bool isCommentingAllowed,
  }) async {
    try {
      await _posts.doc(postId).update({
        'isCommentingAllowed': isCommentingAllowed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle post commenting: $e');
    }
  }

  /// Get posts created by a specific user with pagination
  Future<PostsPage> getUserPosts({
    required String userCPId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _posts
          .where('authorCPId', isEqualTo: userCPId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      final List<Post> posts = snapshot.docs
          .map((doc) {
            return Post.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
          })
          .where((post) => !post.isDeleted)
          .toList(); // Filter out deleted posts

      return PostsPage(
        posts: posts,
        lastDocument: posts.isNotEmpty ? snapshot.docs.last : null,
        hasMore: posts.length == limit,
      );
    } catch (e) {
      print('🔥 ERROR: Failed to fetch user posts: $e');
      print(
          '🔗 If this is an index error, check the link in the error message above for Firestore index requirements');
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  /// Get comments created by a specific user with pagination
  Future<CommentsPage> getUserComments({
    required String userCPId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _comments
          .where('authorCPId', isEqualTo: userCPId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();

      final List<Comment> comments = snapshot.docs
          .map((doc) {
            final comment = Comment.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
            return comment;
          })
          .where((comment) => !comment.isDeleted)
          .toList(); // Filter out deleted comments

      return CommentsPage(
        comments: comments,
        lastDocument: comments.isNotEmpty ? snapshot.docs.last : null,
        hasMore: comments.length == limit,
      );
    } catch (e) {
      print('🔥 ERROR: Failed to fetch user comments: $e');
      print(
          '🔗 If this is an index error, check the link in the error message above for Firestore index requirements');
      throw Exception('Failed to fetch user comments: $e');
    }
  }

  /// Get posts liked by a specific user with pagination
  Future<LikedItemsPage> getUserLikedPosts({
    required String userCPId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _interactions
          .where('userCPId', isEqualTo: userCPId)
          .where('targetType', isEqualTo: 'post')
          .where('type', isEqualTo: 'like')
          .where('value', isEqualTo: 1)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();

      final List<Interaction> interactions = snapshot.docs
          .map((doc) {
            final interaction = Interaction.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
            return interaction;
          })
          .where((interaction) => !interaction.isDeleted)
          .toList(); // Filter out deleted interactions

      // Get the actual posts for these interactions
      final List<Post> posts = [];

      for (final interaction in interactions) {
        try {
          final postDoc = await _posts.doc(interaction.targetId).get();
          if (postDoc.exists) {
            final post = Post.fromFirestore(
                postDoc as DocumentSnapshot<Map<String, dynamic>>);
            if (!post.isDeleted) {
              posts.add(post);
            }
          }
        } catch (e) {
          // Skip posts that can't be loaded
          continue;
        }
      }

      return LikedItemsPage(
        items: posts,
        lastDocument: interactions.isNotEmpty ? snapshot.docs.last : null,
        hasMore: interactions.length == limit,
      );
    } catch (e) {
      throw Exception('Failed to fetch user liked posts: $e');
    }
  }

  /// Get comments liked by a specific user with pagination
  Future<LikedItemsPage> getUserLikedComments({
    required String userCPId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _interactions
          .where('userCPId', isEqualTo: userCPId)
          .where('targetType', isEqualTo: 'comment')
          .where('type', isEqualTo: 'like')
          .where('value', isEqualTo: 1)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();

      final List<Interaction> interactions = snapshot.docs
          .map((doc) {
            final interaction = Interaction.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
            return interaction;
          })
          .where((interaction) => !interaction.isDeleted)
          .toList(); // Filter out deleted interactions

      // Get the actual comments for these interactions
      final List<Comment> comments = [];

      for (final interaction in interactions) {
        try {
          final commentDoc = await _comments.doc(interaction.targetId).get();
          if (commentDoc.exists) {
            final comment = Comment.fromFirestore(
                commentDoc as DocumentSnapshot<Map<String, dynamic>>);
            if (!comment.isDeleted) {
              comments.add(comment);
            }
          }
        } catch (e) {
          // Skip comments that can't be loaded
          continue;
        }
      }

      return LikedItemsPage(
        items: comments,
        lastDocument: interactions.isNotEmpty ? snapshot.docs.last : null,
        hasMore: interactions.length == limit,
      );
    } catch (e) {
      throw Exception('Failed to fetch user liked comments: $e');
    }
  }

  /// Get orphaned posts (posts with authorCPId that doesn't exist in communityProfiles)
  /// This is a fallback method to handle data integrity issues gracefully
  Future<List<Post>> _getOrphanedPosts(
      int limit, String? category, bool? isPinned) async {
    try {
      // Get all posts first
      Query query = _posts.orderBy('createdAt', descending: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (isPinned != null) {
        query = query.where('isPinned', isEqualTo: isPinned);
      }

      final postsSnapshot =
          await query.limit(50).get(); // Get more posts to check

      final allPosts = postsSnapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((post) => !post.isDeleted)
          .toList();

      // Check which posts have non-existent authorCPId
      final orphanedPosts = <Post>[];

      for (final post in allPosts) {
        try {
          final profileExists = await _firestore
              .collection('communityProfiles')
              .doc(post.authorCPId)
              .get()
              .then((doc) => doc.exists);

          if (!profileExists) {
            orphanedPosts.add(post);
          }

          if (orphanedPosts.length >= limit) break;
        } catch (profileCheckError) {
          // Skip this post if we can't check the profile (permission issues)
          continue;
        }
      }

      return orphanedPosts;
    } catch (e) {
      // If permission denied or other errors, return empty list instead of crashing
      if (e.toString().contains('permission-denied')) {
        // Permission denied - likely new profile timing issue, returning empty list
      }
      return [];
    }
  }
}
