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
  String get _currentUserCPId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
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
      return snapshot.docs
          .map((doc) =>
              Post.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .where((post) => !post
              .isDeleted) // This will handle missing fields thanks to default value
          .toList();
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
      if (visibleProfileIds.isEmpty) {
        yield [];
        continue;
      }

      // Batch queries for large profile ID lists
      const int batchSize = 10;
      final List<Stream<List<Post>>> streamBatches = [];

      for (int i = 0; i < visibleProfileIds.length; i += batchSize) {
        final batch = visibleProfileIds.skip(i).take(batchSize).toList();

        Query query = _posts
            .where('authorCPId', whereIn: batch)
            .orderBy('createdAt', descending: true);

        if (category != null && category.isNotEmpty) {
          query = query.where('category', isEqualTo: category);
        }

        if (isPinned != null) {
          query = query.where('isPinned', isEqualTo: isPinned);
        }

        query = query.limit(limit);

        final batchStream = query.snapshots().map((snapshot) {
          return snapshot.docs
              .map((doc) => Post.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>))
              .where((post) => !post.isDeleted)
              .toList();
        });

        streamBatches.add(batchStream);
      }

      // For single batch, yield directly
      if (streamBatches.length == 1) {
        yield* streamBatches.first;
      } else {
        // For multiple batches, combine them
        yield* _combinePostStreams(streamBatches, limit);
      }
    }
  }

  /// Combine multiple post streams and maintain sort order
  Stream<List<Post>> _combinePostStreams(
      List<Stream<List<Post>>> streams, int limit) async* {
    final controller = StreamController<List<Post>>();
    final List<List<Post>> latestResults = List.filled(streams.length, []);
    final List<StreamSubscription> subscriptions = [];

    void updateResults() {
      // Combine all results
      final allPosts = <Post>[];
      for (final posts in latestResults) {
        allPosts.addAll(posts);
      }

      // Sort and limit
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(allPosts.take(limit).toList());
    }

    // Subscribe to all streams
    for (int i = 0; i < streams.length; i++) {
      final subscription = streams[i].listen((posts) {
        latestResults[i] = posts;
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
        'authorCPId': _currentUserCPId,
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
      final userId = userCPId ?? _currentUserCPId;
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
    final userId = userCPId ?? _currentUserCPId;
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
      final userId = _currentUserCPId;
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
      final userId = _currentUserCPId;
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
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      final List<Post> posts = snapshot.docs.map((doc) {
        return Post.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

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
      Query query = _comments
          .where('authorCPId', isEqualTo: userCPId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      final List<Comment> comments = snapshot.docs.map((doc) {
        return Comment.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

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
      Query query = _interactions
          .where('userCPId', isEqualTo: userCPId)
          .where('targetType', isEqualTo: 'post')
          .where('type', isEqualTo: 'like')
          .where('value', isEqualTo: 1)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      final List<Interaction> interactions = snapshot.docs.map((doc) {
        return Interaction.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

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
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();
      final List<Interaction> interactions = snapshot.docs.map((doc) {
        return Interaction.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

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
}
