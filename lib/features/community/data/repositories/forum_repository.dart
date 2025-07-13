import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';

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
  final CollectionReference _postCategories =
      FirebaseFirestore.instance.collection('postCategories');

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
    try {
      return _postCategories
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PostCategory.fromFirestore(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
        }).toList();
      }).handleError((error) {
        throw Exception('Failed to watch post categories: $error');
      });
    } catch (e) {
      return Stream.error(Exception('Failed to setup categories stream: $e'));
    }
  }

  // =============================================================================
  // POST LISTING METHODS
  // =============================================================================

  /// Fetches posts with pagination
  Future<PostsPage> getPosts({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    String? category,
  }) async {
    try {
      Query query = _posts.orderBy('createdAt', descending: true);

      // Filter by category if provided
      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      // Apply pagination
      query = query.limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final posts = snapshot.docs.map((doc) {
        return Post.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

      return PostsPage(
        posts: posts,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: posts.length == limit,
      );
    } catch (e) {
      // Log the error and rethrow with more context
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Streams posts with real-time updates (for first page)
  Stream<List<Post>> watchPosts({
    int limit = 10,
    String? category,
  }) {
    try {
      Query query = _posts.orderBy('createdAt', descending: true);

      // Filter by category if provided
      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Post.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>);
        }).toList();
      }).handleError((error) {
        // Handle stream errors
        throw Exception('Failed to watch posts: $error');
      });
    } catch (e) {
      // Handle synchronous errors and return error stream
      return Stream.error(Exception('Failed to setup posts stream: $e'));
    }
  }

  // =============================================================================
  // POST DETAIL METHODS
  // =============================================================================

  /// Watch a specific post by ID
  Stream<Post?> watchPost(String postId) {
    // TODO: Replace with actual Firestore stream when ready
    // For now, return a mock post
    return Stream.fromFuture(Future.delayed(const Duration(milliseconds: 300))
        .then((_) => _getMockPost(postId)));
  }

  /// Watch comments for a specific post (top-level comments only)
  Stream<List<Comment>> watchComments(String postId) {
    // TODO: Replace with actual Firestore stream when ready
    // Real implementation would be:
    // return _comments
    //     .where('postId', isEqualTo: postId)
    //     .where('parentFor', isEqualTo: 'post')
    //     .orderBy('createdAt')
    //     .snapshots()
    //     .map((snapshot) => snapshot.docs
    //         .map((doc) => Comment.fromFirestore(doc))
    //         .toList());

    // For now, return mock comments
    return Stream.fromFuture(Future.delayed(const Duration(milliseconds: 300))
        .then((_) => _getMockComments(postId)));
  }

  /// Vote on a post
  Future<void> voteOnPost(String postId, int value) async {
    // TODO: Implement actual voting logic with Firestore
    // Real implementation would be:
    // return _posts.doc(postId).collection('votes').doc(_currentCPId).set({
    //   'voterCPId': _currentCPId,
    //   'value': value,
    //   'createdAt': FieldValue.serverTimestamp(),
    // });

    // For now, simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Vote on a comment
  Future<void> voteOnComment({
    required String commentId,
    required int value,
  }) async {
    // TODO: Implement actual voting logic with Firestore
    // Real implementation would be:
    // return _comments.doc(commentId).collection('votes').doc(_currentCPId).set({
    //   'voterCPId': _currentCPId,
    //   'value': value,
    //   'createdAt': FieldValue.serverTimestamp(),
    // });

    // For now, simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Add a comment to a post or reply to a comment
  Future<void> addComment({
    required String postId,
    required String body,
    String? parentFor,
    String? parentId,
  }) async {
    // TODO: Implement actual comment creation with Firestore
    // Real implementation would be:
    // final commentData = {
    //   'postId': postId,
    //   'authorCPId': _currentUserCPId,
    //   'body': body,
    //   'parentFor': parentFor ?? 'post',
    //   'parentId': parentId ?? postId,
    //   'score': 0,
    //   'createdAt': FieldValue.serverTimestamp(),
    //   'updatedAt': null,
    // };
    // await _comments.add(commentData);

    // For now, simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // =============================================================================
  // MOCK DATA METHODS
  // =============================================================================

  /// Mock post data for development
  Post? _getMockPost(String postId) {
    return Post(
      id: postId,
      authorCPId: 'user_123',
      title: 'The Claude Code leads just left for Cursor.',
      body:
          'so don\'t uninstall Cursor just yet...\n\nit\'s going to be on top again:',
      category: 'discussion',
      score: 57,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  /// Mock comments data for development
  List<Comment> _getMockComments(String postId) {
    return [
      Comment(
        id: 'comment_1',
        postId: postId,
        authorCPId: 'user_123',
        body:
            'The reason why Claude Code is so good is cuz of these leads.\n\nWhere they go, innovation follows.\n\nCC will likely slow down now. But as a low level...',
        score: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Comment(
        id: 'comment_2',
        postId: postId,
        authorCPId: 'user_456',
        body:
            'I agree! This is exactly what I was thinking. The talent that drives innovation is what makes the difference.',
        score: 8,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Comment(
        id: 'comment_3',
        postId: postId,
        authorCPId: 'user_789',
        body:
            'Interesting perspective. I wonder how this will affect the competitive landscape.',
        score: 3,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
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
        'score': 0,
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
}
