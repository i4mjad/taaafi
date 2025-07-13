import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/data/repositories/forum_repository.dart';
import 'package:reboot_app_3/features/community/domain/services/forum_service.dart';
import 'package:reboot_app_3/features/community/domain/services/post_validation_service.dart';
import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

// Forum Repository Provider
final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository();
});

// Post Validation Service Provider
final postValidationServiceProvider = Provider<PostValidationService>((ref) {
  return PostValidationService();
});

// Firebase Auth Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Forum Service Provider
final forumServiceProvider = Provider<ForumService>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  final validationService = ref.watch(postValidationServiceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return ForumService(repository, validationService, auth);
});

// Post Categories Provider
final postCategoriesProvider = StreamProvider<List<PostCategory>>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchPostCategories();
});

// Posts Provider (with lazy loading support)
final postsProvider =
    StreamProvider.family<List<Post>, String?>((ref, category) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchPosts(limit: 10, category: category);
});

// Posts Pagination Provider
final postsPaginationProvider =
    StateNotifierProvider<PostsPaginationNotifier, PostsPaginationState>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostsPaginationNotifier(repository);
});

// Selected Category Provider for new post screen
final selectedCategoryProvider = StateProvider<PostCategory?>((ref) {
  // Default to "general" category
  return const PostCategory(
    id: 'general',
    name: 'General',
    nameAr: 'عام',
    iconName: 'chat',
    colorHex: '#6B7280',
    isActive: true,
    sortOrder: 7,
  );
});

// Post Content Provider for new post screen
final postContentProvider = StateProvider<String>((ref) {
  return '';
});

// Anonymous Post Provider for new post screen
final anonymousPostProvider = StateProvider<bool>((ref) {
  return false;
});

// Attachment URLs Provider for future implementation
final attachmentUrlsProvider = StateProvider<List<String>>((ref) {
  return [];
});

// Post Creation Provider
final postCreationProvider =
    StateNotifierProvider<PostCreationNotifier, AsyncValue<String?>>((ref) {
  final forumService = ref.watch(forumServiceProvider);
  return PostCreationNotifier(forumService);
});

// =============================================================================
// POST DETAIL PROVIDERS
// =============================================================================

/// Provider for a specific post detail
final postDetailProvider =
    StreamProvider.family.autoDispose<Post?, String>((ref, postId) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchPost(postId);
});

/// Provider for post comments (top-level comments only)
final postCommentsProvider =
    StreamProvider.family.autoDispose<List<Comment>, String>((ref, postId) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchComments(postId);
});

/// Provider for post voting state
final postVoteProvider =
    StateNotifierProvider.family<PostVoteNotifier, AsyncValue<void>, String>(
        (ref, postId) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostVoteNotifier(repository, postId);
});

/// Provider for comment voting state
final commentVoteProvider =
    StateNotifierProvider.family<CommentVoteNotifier, AsyncValue<void>, String>(
        (ref, commentId) {
  final repository = ref.watch(forumRepositoryProvider);
  return CommentVoteNotifier(repository, commentId);
});

/// Provider for adding comments
final addCommentProvider =
    StateNotifierProvider.family<AddCommentNotifier, AsyncValue<void>, String>(
        (ref, postId) {
  final repository = ref.watch(forumRepositoryProvider);
  return AddCommentNotifier(repository, postId);
});

/// Provider for reply state management
final replyStateProvider =
    StateNotifierProvider<ReplyStateNotifier, ReplyState>((ref) {
  return ReplyStateNotifier();
});

// =============================================================================
// NOTIFIER CLASSES
// =============================================================================

/// State for reply functionality
class ReplyState {
  final String? replyToCommentId;
  final String? replyToUsername;
  final bool isReplying;

  const ReplyState({
    this.replyToCommentId,
    this.replyToUsername,
    this.isReplying = false,
  });

  ReplyState copyWith({
    String? replyToCommentId,
    String? replyToUsername,
    bool? isReplying,
  }) {
    return ReplyState(
      replyToCommentId: replyToCommentId ?? this.replyToCommentId,
      replyToUsername: replyToUsername ?? this.replyToUsername,
      isReplying: isReplying ?? this.isReplying,
    );
  }
}

/// Notifier for reply state management
class ReplyStateNotifier extends StateNotifier<ReplyState> {
  ReplyStateNotifier() : super(const ReplyState());

  void startReply(String commentId, String username) {
    state = state.copyWith(
      replyToCommentId: commentId,
      replyToUsername: username,
      isReplying: true,
    );
  }

  void cancelReply() {
    state = const ReplyState();
  }
}

/// Notifier for post voting
class PostVoteNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _postId;

  PostVoteNotifier(this._repository, this._postId)
      : super(const AsyncValue.data(null));

  Future<void> vote(int value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.voteOnPost(_postId, value);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Notifier for comment voting
class CommentVoteNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _commentId;

  CommentVoteNotifier(this._repository, this._commentId)
      : super(const AsyncValue.data(null));

  Future<void> vote(int value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.voteOnComment(commentId: _commentId, value: value);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Notifier for adding comments
class AddCommentNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _postId;

  AddCommentNotifier(this._repository, this._postId)
      : super(const AsyncValue.data(null));

  Future<void> addComment({
    required String body,
    String? parentFor,
    String? parentId,
    bool isAnonymous = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addComment(
        postId: _postId,
        body: body,
        parentFor: parentFor,
        parentId: parentId,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Notifier for post creation using ForumService
class PostCreationNotifier extends StateNotifier<AsyncValue<String?>> {
  final ForumService _forumService;

  PostCreationNotifier(this._forumService) : super(const AsyncValue.data(null));

  /// Creates a new post using the forum service
  Future<void> createPost(
      PostFormData postData, AppLocalizations localizations) async {
    state = const AsyncValue.loading();
    try {
      final postId = await _forumService.createPost(postData, localizations);
      state = AsyncValue.data(postId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Resets the state to initial
  void reset() {
    state = const AsyncValue.data(null);
  }
}

// =============================================================================
// POSTS PAGINATION STATE AND NOTIFIER
// =============================================================================

/// State for posts pagination
class PostsPaginationState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot? lastDocument;

  const PostsPaginationState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocument,
  });

  PostsPaginationState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    DocumentSnapshot? lastDocument,
  }) {
    return PostsPaginationState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

/// Notifier for posts pagination
class PostsPaginationNotifier extends StateNotifier<PostsPaginationState> {
  final ForumRepository _repository;

  PostsPaginationNotifier(this._repository)
      : super(const PostsPaginationState());

  /// Loads the first page of posts
  Future<void> loadPosts({String? category}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final postsPage = await _repository.getPosts(
        limit: 10,
        category: category,
      );

      state = state.copyWith(
        posts: postsPage.posts,
        isLoading: false,
        hasMore: postsPage.hasMore,
        lastDocument: postsPage.lastDocument,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Loads more posts for pagination
  Future<void> loadMorePosts({String? category}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final postsPage = await _repository.getPosts(
        limit: 10,
        lastDocument: state.lastDocument,
        category: category,
      );

      state = state.copyWith(
        posts: [...state.posts, ...postsPage.posts],
        isLoading: false,
        hasMore: postsPage.hasMore,
        lastDocument: postsPage.lastDocument,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Refreshes the posts list
  Future<void> refresh({String? category}) async {
    state = const PostsPaginationState();
    await loadPosts(category: category);
  }
}
