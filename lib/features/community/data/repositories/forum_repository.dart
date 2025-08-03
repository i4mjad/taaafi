import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';
import 'package:reboot_app_3/features/community/application/gender_filtering_service.dart';
import 'dart:math';

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
          .where('isDeleted', isNotEqualTo: true)
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

  /// Get posts without gender filtering (for pinned, news, challenges)
  Future<PostsPage> _getUnfilteredPosts({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? category,
    bool? isPinned,
  }) async {
    try {
      Query query = _posts.orderBy('createdAt', descending: true);

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

      // Filter out deleted posts in code since some posts might not have the field
      final posts = snapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((post) => !post
              .isDeleted) // This will handle missing fields thanks to default value
          .toList();

      return PostsPage(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get posts with gender filtering applied at source
  Future<PostsPage> _getGenderFilteredPosts({
    required int limit,
    DocumentSnapshot? lastDocument,
    String? category,
    bool? isPinned,
    required String userGender,
  }) async {
    try {
      // Get allowed community profile IDs (same gender + admins)
      final visibleProfileIds = await _genderFilteringService
          .getVisibleCommunityProfileIds(userGender);

      if (visibleProfileIds.isEmpty) {
        return const PostsPage(posts: [], hasMore: false);
      }

      // Firestore whereIn has a limit of 10, so we need to batch queries if more than 10 IDs
      const int batchSize = 10;
      final List<Post> allPosts = [];
      DocumentSnapshot? globalLastDoc = lastDocument;
      int remainingLimit = limit;

      for (int i = 0;
          i < visibleProfileIds.length && remainingLimit > 0;
          i += batchSize) {
        final batch = visibleProfileIds.skip(i).take(batchSize).toList();

        final batchResult = await _executeGenderFilteredQuery(
          authorCPIds: batch,
          limit: remainingLimit,
          lastDocument: globalLastDoc,
          category: category,
          isPinned: isPinned,
        );

        allPosts.addAll(batchResult.posts);
        remainingLimit -= batchResult.posts.length;

        // Update last document for pagination
        if (batchResult.lastDocument != null) {
          globalLastDoc = batchResult.lastDocument;
        }

        // If this batch returned fewer posts than requested, we've reached the end
        if (batchResult.posts.length <
            (remainingLimit + batchResult.posts.length) /
                (i ~/ batchSize + 1)) {
          break;
        }
      }

      // Sort all posts by creation date (since they came from different batches)
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Take only the requested limit
      final limitedPosts = allPosts.take(limit).toList();

      return PostsPage(
        posts: limitedPosts,
        lastDocument: globalLastDoc,
        hasMore:
            allPosts.length >= limit && visibleProfileIds.length > batchSize,
      );
    } catch (e) {
      throw Exception('Failed to fetch gender-filtered posts: $e');
    }
  }

  /// Execute a single batched gender-filtered query
  Future<PostsPage> _executeGenderFilteredQuery({
    required List<String> authorCPIds,
    required int limit,
    DocumentSnapshot? lastDocument,
    String? category,
    bool? isPinned,
  }) async {
    Query query = _posts
        .where('authorCPId', whereIn: authorCPIds)
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

    final posts = snapshot.docs
        .map((doc) =>
            Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .where((post) => !post.isDeleted)
        .toList();

    return PostsPage(
      posts: posts,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
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
    Query query = _posts.orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (isPinned != null) {
      query = query.where('isPinned', isEqualTo: isPinned);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      // Filter out deleted posts in code since some posts might not have the field
      final posts = snapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((post) => !post
              .isDeleted) // This will handle missing fields thanks to default value
          .toList();

      print(
          '🔍 ForumRepository: _watchUnfilteredPosts returning ${posts.length} posts');
      for (final post in posts) {
        print(
            '🔍 ForumRepository: Post ID: ${post.id}, authorCPId: ${post.authorCPId}, content: ${post.body.substring(0, min(50, post.body.length))}...');

        // Check the author's profile gender
        _checkAuthorGender(post.authorCPId);
      }

      return posts;
    });
  }

  /// Debug method to check an author's gender
  Future<void> _checkAuthorGender(String authorCPId) async {
    try {
      final doc = await _firestore
          .collection('communityProfiles')
          .doc(authorCPId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final gender = data['gender'] ?? 'unknown';
        final isDeleted = data['isDeleted'] ?? false;
        print(
            '🔍 ForumRepository: Author $authorCPId - gender: $gender, isDeleted: $isDeleted');
      } else {
        print('🔍 ForumRepository: Author $authorCPId - profile not found!');
      }
    } catch (e) {
      print('🔍 ForumRepository: Error checking author $authorCPId: $e');
    }
  }

  /// Stream gender-filtered posts
  Stream<List<Post>> _watchGenderFilteredPosts({
    required int limit,
    String? category,
    bool? isPinned,
    required String userGender,
  }) async* {
    print(
        '🔍 ForumRepository: Starting _watchGenderFilteredPosts for gender: $userGender');

    // Get visible profile IDs and watch for changes
    await for (final visibleProfileIds in _genderFilteringService
        .watchVisibleCommunityProfileIds(userGender)) {
      print(
          '🔍 ForumRepository: Received ${visibleProfileIds.length} visible profile IDs: $visibleProfileIds');

      List<Post> genderFilteredPosts = [];

      if (visibleProfileIds.isNotEmpty) {
        // Try to get posts from valid profiles first
        genderFilteredPosts = await _getPostsFromProfiles(
            visibleProfileIds, limit, category, isPinned);
        print(
            '🔍 ForumRepository: Found ${genderFilteredPosts.length} posts from valid profiles');
      }

      // If no posts found from valid profiles, try orphaned posts as fallback
      if (genderFilteredPosts.isEmpty) {
        print(
            '🔍 ForumRepository: No posts from valid profiles, checking for orphaned posts as fallback');

        final orphanedPosts =
            await _getOrphanedPosts(limit, category, isPinned);
        print(
            '🔍 ForumRepository: Found ${orphanedPosts.length} orphaned posts as fallback');

        // For now, just return orphaned posts as fallback
        yield orphanedPosts;
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
        print('🔍 ForumRepository: Querying posts for profile batch: $batch');

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

        print('🔍 ForumRepository: Batch returned ${batchPosts.length} posts');
        allPosts.addAll(batchPosts);
      }

      // Sort by creation date and limit
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allPosts.take(limit).toList();
    } catch (e) {
      print('🔍 ForumRepository: Error getting posts from profiles: $e');
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

  /// Stream of a single post
  Stream<Post?> watchPost(String postId) {
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

    return snapshot.docs.map((doc) {
      return Comment.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }).toList();
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

      final batchComments = snapshot.docs.map((doc) {
        return Comment.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

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
    print('💾 [ForumRepository] createPost started');
    print('📝 [ForumRepository] Parameters received:');
    print('   - authorCPId: $authorCPId');
    print('   - title: "$title" (${title.length} chars)');
    print(
        '   - content: "${content.substring(0, content.length > 100 ? 100 : content.length)}${content.length > 100 ? '...' : ''}" (${content.length} chars)');
    print('   - categoryId: $categoryId');
    print('   - attachmentUrls: $attachmentUrls');

    try {
      final now = DateTime.now();
      print('⏰ [ForumRepository] Timestamp created: $now');

      // Create post document data
      final postData = {
        'authorCPId': authorCPId,
        'title': title,
        'body': content,
        'category': categoryId ?? 'general',
        'isPinned': false,
        'isDeleted': false,
        'isCommentingAllowed': true,
        'score': 0,
        'likeCount': 0,
        'dislikeCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': null,
        // Note: attachmentUrls not implemented yet
      };

      print('📄 [ForumRepository] Firestore document data prepared:');
      print('   - authorCPId: ${postData['authorCPId']}');
      print('   - title: ${postData['title']}');
      print('   - body length: ${(postData['body'] as String).length}');
      print('   - category: ${postData['category']}');
      print('   - isPinned: ${postData['isPinned']}');
      print('   - isDeleted: ${postData['isDeleted']}');
      print('   - isCommentingAllowed: ${postData['isCommentingAllowed']}');
      print('   - score: ${postData['score']}');
      print('   - likeCount: ${postData['likeCount']}');
      print('   - dislikeCount: ${postData['dislikeCount']}');
      print('   - createdAt: ${postData['createdAt']}');

      // Add to Firestore and get the document reference
      print('🔄 [ForumRepository] Adding document to Firestore...');
      final docRef = await _posts.add(postData);
      print('✅ [ForumRepository] Document added successfully');
      print('🆔 [ForumRepository] Generated document ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      print('❌ [ForumRepository] Error creating post: $e');
      print('❌ [ForumRepository] Error type: ${e.runtimeType}');
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
      final docId = Interaction.generateDocumentId(
        userCPId: userId,
        targetType: targetType,
        targetId: targetId,
      );

      final doc = await _interactions.doc(docId).get();
      if (doc.exists) {
        return Interaction.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
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
    final docId = Interaction.generateDocumentId(
      userCPId: userId,
      targetType: targetType,
      targetId: targetId,
    );

    return _interactions.doc(docId).snapshots().map((doc) {
      if (doc.exists) {
        return Interaction.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
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
      final docId = Interaction.generateDocumentId(
        userCPId: userId,
        targetType: 'post',
        targetId: postId,
      );

      await _firestore.runTransaction((transaction) async {
        // Get current interaction if exists
        final interactionDoc = await transaction.get(_interactions.doc(docId));
        final postDoc = await transaction.get(_posts.doc(postId));

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final currentPost = Post.fromFirestore(
            postDoc as DocumentSnapshot<Map<String, dynamic>>);
        int likeCountChange = 0;
        int dislikeCountChange = 0;

        if (interactionDoc.exists) {
          // User has an existing interaction
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
            transaction.delete(_interactions.doc(docId));
          } else {
            // Update interaction
            final updatedInteraction = currentInteraction.updateValue(value);
            transaction.set(
                _interactions.doc(docId), updatedInteraction.toFirestore());
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
            transaction.set(
                _interactions.doc(docId), newInteraction.toFirestore());
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
      final docId = Interaction.generateDocumentId(
        userCPId: userId,
        targetType: 'comment',
        targetId: commentId,
      );

      await _firestore.runTransaction((transaction) async {
        // Get current interaction if exists
        final interactionDoc = await transaction.get(_interactions.doc(docId));
        final commentDoc = await transaction.get(_comments.doc(commentId));

        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final currentComment = Comment.fromFirestore(
            commentDoc as DocumentSnapshot<Map<String, dynamic>>);
        int likeCountChange = 0;
        int dislikeCountChange = 0;

        if (interactionDoc.exists) {
          // User has an existing interaction
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
            transaction.delete(_interactions.doc(docId));
          } else {
            // Update interaction
            final updatedInteraction = currentInteraction.updateValue(value);
            transaction.set(
                _interactions.doc(docId), updatedInteraction.toFirestore());
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
            transaction.set(
                _interactions.doc(docId), newInteraction.toFirestore());
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
      print(
          '🔍 [DEBUG] getUserComments - Starting fetch for userCPId: $userCPId, limit: $limit');

      Query query = _comments
          .where('authorCPId', isEqualTo: userCPId)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        print('🔍 [DEBUG] getUserComments - Using lastDocument for pagination');
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      print(
          '🔍 [DEBUG] getUserComments - Query executed, found ${snapshot.docs.length} documents');

      final List<Comment> comments = snapshot.docs
          .map((doc) {
            final comment = Comment.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
            print(
                '🔍 [DEBUG] getUserComments - Comment: ${comment.id}, body: ${comment.body.length > 50 ? comment.body.substring(0, 50) + "..." : comment.body}');
            return comment;
          })
          .where((comment) => !comment.isDeleted)
          .toList(); // Filter out deleted comments

      print(
          '🔍 [DEBUG] getUserComments - Processed ${comments.length} comments, hasMore: ${comments.length == limit}');

      return CommentsPage(
        comments: comments,
        lastDocument: comments.isNotEmpty ? snapshot.docs.last : null,
        hasMore: comments.length == limit,
      );
    } catch (e) {
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
      print(
          '❤️ [DEBUG] getUserLikedPosts - Starting fetch for userCPId: $userCPId, limit: $limit');

      Query query = _interactions
          .where('userCPId', isEqualTo: userCPId)
          .where('targetType', isEqualTo: 'post')
          .where('type', isEqualTo: 'like')
          .where('value', isEqualTo: 1)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        print(
            '❤️ [DEBUG] getUserLikedPosts - Using lastDocument for pagination');
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      print(
          '❤️ [DEBUG] getUserLikedPosts - Query executed, found ${snapshot.docs.length} interactions');

      final List<Interaction> interactions = snapshot.docs
          .map((doc) {
            final interaction = Interaction.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
            print(
                '❤️ [DEBUG] getUserLikedPosts - Interaction: ${interaction.id}, targetId: ${interaction.targetId}, value: ${interaction.value}');
            return interaction;
          })
          .where((interaction) => !interaction.isDeleted)
          .toList(); // Filter out deleted interactions

      // Get the actual posts for these interactions
      final List<Post> posts = [];
      print(
          '❤️ [DEBUG] getUserLikedPosts - Fetching ${interactions.length} posts from interactions');

      for (final interaction in interactions) {
        try {
          final postDoc = await _posts.doc(interaction.targetId).get();
          if (postDoc.exists) {
            final post = Post.fromFirestore(
                postDoc as DocumentSnapshot<Map<String, dynamic>>);
            if (!post.isDeleted) {
              posts.add(post);
              print(
                  '❤️ [DEBUG] getUserLikedPosts - Added post: ${post.id}, title: ${post.title.length > 30 ? post.title.substring(0, 30) + "..." : post.title}');
            } else {
              print(
                  '❤️ [DEBUG] getUserLikedPosts - Skipped deleted post: ${post.id}');
            }
          } else {
            print(
                '❤️ [DEBUG] getUserLikedPosts - Post not found: ${interaction.targetId}');
          }
        } catch (e) {
          print(
              '❤️ [ERROR] getUserLikedPosts - Failed to load post ${interaction.targetId}: $e');
          // Skip posts that can't be loaded
          continue;
        }
      }

      print(
          '❤️ [DEBUG] getUserLikedPosts - Final result: ${posts.length} posts, hasMore: ${interactions.length == limit}');

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
      print(
          '💬❤️ [DEBUG] getUserLikedComments - Starting fetch for userCPId: $userCPId, limit: $limit');

      Query query = _interactions
          .where('userCPId', isEqualTo: userCPId)
          .where('targetType', isEqualTo: 'comment')
          .where('type', isEqualTo: 'like')
          .where('value', isEqualTo: 1)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
        print(
            '💬❤️ [DEBUG] getUserLikedComments - Using lastDocument for pagination');
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      print(
          '💬❤️ [DEBUG] getUserLikedComments - Query executed, found ${snapshot.docs.length} interactions');

      final List<Interaction> interactions = snapshot.docs
          .map((doc) {
            final interaction = Interaction.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>);
            print(
                '💬❤️ [DEBUG] getUserLikedComments - Interaction: ${interaction.id}, targetId: ${interaction.targetId}, value: ${interaction.value}');
            return interaction;
          })
          .where((interaction) => !interaction.isDeleted)
          .toList(); // Filter out deleted interactions

      // Get the actual comments for these interactions
      final List<Comment> comments = [];
      print(
          '💬❤️ [DEBUG] getUserLikedComments - Fetching ${interactions.length} comments from interactions');

      for (final interaction in interactions) {
        try {
          final commentDoc = await _comments.doc(interaction.targetId).get();
          if (commentDoc.exists) {
            final comment = Comment.fromFirestore(
                commentDoc as DocumentSnapshot<Map<String, dynamic>>);
            if (!comment.isDeleted) {
              comments.add(comment);
              print(
                  '💬❤️ [DEBUG] getUserLikedComments - Added comment: ${comment.id}, body: ${comment.body.length > 30 ? comment.body.substring(0, 30) + "..." : comment.body}');
            } else {
              print(
                  '💬❤️ [DEBUG] getUserLikedComments - Skipped deleted comment: ${comment.id}');
            }
          } else {
            print(
                '💬❤️ [DEBUG] getUserLikedComments - Comment not found: ${interaction.targetId}');
          }
        } catch (e) {
          print(
              '💬❤️ [ERROR] getUserLikedComments - Failed to load comment ${interaction.targetId}: $e');
          // Skip comments that can't be loaded
          continue;
        }
      }

      print(
          '💬❤️ [DEBUG] getUserLikedComments - Final result: ${comments.length} comments, hasMore: ${interactions.length == limit}');

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
      print('🔍 ForumRepository: Checking for orphaned posts...');

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
        final profileExists = await _firestore
            .collection('communityProfiles')
            .doc(post.authorCPId)
            .get()
            .then((doc) => doc.exists);

        if (!profileExists) {
          orphanedPosts.add(post);
          print(
              '🔍 ForumRepository: Found orphaned post: ${post.id} by ${post.authorCPId}');
        }

        if (orphanedPosts.length >= limit) break;
      }

      return orphanedPosts;
    } catch (e) {
      print('🔍 ForumRepository: Error getting orphaned posts: $e');
      return [];
    }
  }
}
