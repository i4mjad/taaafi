import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/data/models/post.dart';
import 'package:reboot_app_3/features/community/data/models/comment.dart';
import 'package:reboot_app_3/features/community/data/models/interaction.dart';
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
// INTERACTION PROVIDERS
// =============================================================================

/// Provider for user's interaction with a specific target
final userInteractionProvider = FutureProvider.family.autoDispose<Interaction?,
    ({String targetType, String targetId, String userCPId})>((ref, params) {
  final repository = ref.watch(forumRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);

  // Use current user's UID if userCPId is empty
  final userCPId =
      params.userCPId.isEmpty ? auth.currentUser?.uid : params.userCPId;

  if (userCPId == null) {
    return Future.value(null);
  }

  return repository.getUserInteraction(
    targetType: params.targetType,
    targetId: params.targetId,
    userCPId: userCPId,
  );
});

/// Provider for streaming user's interaction with a specific target
final userInteractionStreamProvider = StreamProvider.family.autoDispose<
    Interaction?,
    ({String targetType, String targetId, String userCPId})>((ref, params) {
  final repository = ref.watch(forumRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);

  // Use current user's UID if userCPId is empty
  final userCPId =
      params.userCPId.isEmpty ? auth.currentUser?.uid : params.userCPId;

  if (userCPId == null) {
    return Stream.value(null);
  }

  return repository.watchUserInteraction(
    targetType: params.targetType,
    targetId: params.targetId,
    userCPId: userCPId,
  );
});

/// Provider for post interactions
final postInteractionProvider = StateNotifierProvider.family<
    PostInteractionNotifier, AsyncValue<void>, String>((ref, postId) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostInteractionNotifier(repository, postId);
});

/// Provider for comment interactions
final commentInteractionProvider = StateNotifierProvider.family<
    CommentInteractionNotifier, AsyncValue<void>, String>((ref, commentId) {
  final repository = ref.watch(forumRepositoryProvider);
  return CommentInteractionNotifier(repository, commentId);
});

/// Provider for all interactions on a target
final targetInteractionsProvider = StreamProvider.family
    .autoDispose<List<Interaction>, ({String targetType, String targetId})>(
        (ref, params) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchTargetInteractions(
    targetType: params.targetType,
    targetId: params.targetId,
  );
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

  void startReply({
    required String commentId,
    required String username,
  }) {
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

/// Notifier for post interactions
class PostInteractionNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _postId;

  PostInteractionNotifier(this._repository, this._postId)
      : super(const AsyncValue.data(null));

  Future<void> interact(int value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.interactWithPost(postId: _postId, value: value);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Notifier for comment interactions
class CommentInteractionNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _commentId;

  CommentInteractionNotifier(this._repository, this._commentId)
      : super(const AsyncValue.data(null));

  Future<void> interact(int value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.interactWithComment(
          commentId: _commentId, value: value);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// =============================================================================
// LEGACY NOTIFIERS (for backward compatibility)
// =============================================================================

/// Legacy notifier for post voting
@deprecated
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Legacy notifier for comment voting
@deprecated
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Notifier for post creation
class PostCreationNotifier extends StateNotifier<AsyncValue<String?>> {
  final ForumService _forumService;

  PostCreationNotifier(this._forumService) : super(const AsyncValue.data(null));

  Future<void> createPost(
      PostFormData postData, AppLocalizations localizations) async {
    state = const AsyncValue.loading();
    try {
      final postId = await _forumService.createPost(postData, localizations);
      state = AsyncValue.data(postId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Notifier for posts pagination
class PostsPaginationNotifier extends StateNotifier<PostsPaginationState> {
  final ForumRepository _repository;

  PostsPaginationNotifier(this._repository)
      : super(PostsPaginationState.initial());

  /// Loads the first page of posts
  Future<void> loadPosts({String? category}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _repository.getPosts(
        limit: 10,
        category: category,
      );

      state = state.copyWith(
        posts: page.posts,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Loads more posts for pagination
  Future<void> loadMorePosts({String? category}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final page = await _repository.getPosts(
        limit: 10,
        lastDocument: state.lastDocument,
        category: category,
      );

      state = state.copyWith(
        posts: [...state.posts, ...page.posts],
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refreshes the posts list
  Future<void> refresh({String? category}) async {
    state = PostsPaginationState.initial();
    await loadPosts(category: category);
  }

  /// Loads the next page of posts (new method name)
  Future<void> loadNextPage({String? category}) async {
    return loadMorePosts(category: category);
  }

  void reset() {
    state = PostsPaginationState.initial();
  }
}

/// State for posts pagination
class PostsPaginationState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final dynamic lastDocument;

  PostsPaginationState({
    required this.posts,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.lastDocument,
  });

  factory PostsPaginationState.initial() {
    return PostsPaginationState(
      posts: [],
      isLoading: false,
      hasMore: true,
    );
  }

  PostsPaginationState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    dynamic lastDocument,
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
