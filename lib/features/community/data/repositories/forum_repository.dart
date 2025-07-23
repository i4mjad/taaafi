import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';

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

  /// Get posts with pagination
  Future<PostsPage> getPosts({
    int limit = 10,
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

  /// Stream of posts from Firestore
  Stream<List<Post>> watchPosts({
    int limit = 10,
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

  /// Get comments for a post
  Future<List<Comment>> getComments(String postId) async {
    try {
      final QuerySnapshot snapshot = await _comments
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs.map((doc) {
        return Comment.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Stream of comments for a post
  Stream<List<Comment>> watchComments(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
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
}
