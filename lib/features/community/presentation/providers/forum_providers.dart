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
import 'package:reboot_app_3/features/community/application/gender_filtering_service.dart';
import 'package:reboot_app_3/features/community/application/gender_interaction_validator.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'dart:math' as math;

/// Debug helper to log gender filtering status
void _debugGenderFiltering(
  String providerName, {
  required String? category,
  required bool? isPinned,
  required String? userGender,
  required bool shouldApplyFilter,
}) {
  print('🔍 Gender Filtering Debug - $providerName:');
  print('   Category: $category');
  print('   Is Pinned: $isPinned');
  print('   User Gender: $userGender');
  print('   Should Apply Filter: $shouldApplyFilter');
  print(
      '   Rule: ${shouldApplyFilter ? "FILTERING ENABLED" : "FILTERING DISABLED"}');
}

/// Helper class for managing post filter parameters
class PostFilterParams {
  final int limit;
  final String? category;
  final bool? isPinned;

  const PostFilterParams({
    this.limit = 10,
    this.category,
    this.isPinned,
  });

  /// Determines if gender filtering should be applied based on content type
  bool get shouldApplyGenderFilter {
    // Don't apply gender filtering to:
    // - Pinned posts
    // - News posts
    // - Challenge posts
    if (isPinned == true) return false;

    if (category != null) {
      switch (category!.toLowerCase()) {
        case 'news':
        case 'challenges':
        case 'pinned':
          return false;
        default:
          return true;
      }
    }

    // Default to applying gender filter for regular posts
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostFilterParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          category == other.category &&
          isPinned == other.isPinned;

  @override
  int get hashCode => limit.hashCode ^ category.hashCode ^ isPinned.hashCode;
}

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
  final genderValidator = ref.watch(genderInteractionValidatorProvider);
  return ForumService(repository, validationService, auth, genderValidator);
});

// Gender Filtering Service Provider
final genderFilteringServiceProvider = Provider<GenderFilteringService>((ref) {
  return GenderFilteringService();
});

// Gender Interaction Validator Provider
final genderInteractionValidatorProvider =
    Provider<GenderInteractionValidator>((ref) {
  final genderFilteringService = ref.watch(genderFilteringServiceProvider);
  return GenderInteractionValidator(genderFilteringService);
});

// Post Categories Provider
final postCategoriesProvider = StreamProvider<List<PostCategory>>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return repository.watchPostCategories();
});

// Posts Provider (with lazy loading support and mandatory gender filtering)
final postsProvider =
    StreamProvider.family<List<Post>, String?>((ref, category) async* {
  final repository = ref.watch(forumRepositoryProvider);
  final currentProfile = ref.watch(currentCommunityProfileProvider);

  // Create filter params to determine if gender filtering should be applied
  final filterParams = PostFilterParams(category: category);
  final shouldFilter = filterParams.shouldApplyGenderFilter;

  // Debug logging to verify gender filtering
  _debugGenderFiltering(
    'postsProvider',
    category: category,
    isPinned: null,
    userGender: currentProfile.value?.gender,
    shouldApplyFilter: shouldFilter,
  );

  await for (final posts in repository.watchPosts(
    limit: 10,
    category: category,
    userGender: currentProfile.value?.gender,
    applyGenderFilter: shouldFilter,
  )) {
    yield posts;
  }
});

// Gender-aware posts provider
final genderFilteredPostsProvider =
    StreamProvider.family<List<Post>, PostFilterParams>((ref, params) async* {
  final repository = ref.watch(forumRepositoryProvider);
  final currentProfile = ref.watch(currentCommunityProfileProvider);

  await for (final posts in repository.watchPosts(
    limit: params.limit,
    category: params.category,
    isPinned: params.isPinned,
    userGender: currentProfile.value?.gender,
    applyGenderFilter: params.shouldApplyGenderFilter,
  )) {
    yield posts;
  }
});

// Main Screen Posts Provider (limited to 50 posts with optimistic deletion filtering)
final mainScreenPostsProvider =
    StreamProvider.family<List<Post>, String?>((ref, category) async* {
  final repository = ref.watch(forumRepositoryProvider);
  final currentProfile = ref.watch(currentCommunityProfileProvider);

  // Create filter params to determine if gender filtering should be applied
  final filterParams = PostFilterParams(category: category);
  final shouldFilter = filterParams.shouldApplyGenderFilter;

  await for (final posts in repository.watchPosts(
    limit: 50,
    category: category,
    userGender: currentProfile.value?.gender,
    applyGenderFilter: shouldFilter,
  )) {
    // Filter out optimistically deleted posts
    final filteredPosts = <Post>[];

    for (final post in posts) {
      final optimisticState = ref.read(optimisticPostStateProvider(post.id));
      if (!optimisticState.isDeleted) {
        filteredPosts.add(post);
      }
    }

    yield filteredPosts;
  }
});

// Posts Pagination Provider
final postsPaginationProvider =
    StateNotifierProvider<PostsPaginationNotifier, PostsPaginationState>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostsPaginationNotifier(repository, ref);
});

// Pinned Posts Provider
final pinnedPostsPaginationProvider =
    StateNotifierProvider<PostsPaginationNotifier, PostsPaginationState>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostsPaginationNotifier(repository, ref);
});

// News Posts Provider
final newsPostsPaginationProvider =
    StateNotifierProvider<PostsPaginationNotifier, PostsPaginationState>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostsPaginationNotifier(repository, ref);
});

// Selected Category Provider for new post screen
final selectedCategoryProvider = StateProvider<PostCategory?>((ref) {
  // Default to null - will be set to general category from Firestore when loaded
  return null;
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

/// Provider for optimistic post state (immediate count updates)
final optimisticPostStateProvider = StateNotifierProvider.family<
    OptimisticPostStateNotifier, OptimisticPostState, String>((ref, postId) {
  // Get the initial state from the actual post
  final initialPost = ref.watch(postDetailProvider(postId)).value;

  return OptimisticPostStateNotifier(
    OptimisticPostState(
      postId: postId,
      likeCount: initialPost?.likeCount ?? 0,
      dislikeCount: initialPost?.dislikeCount ?? 0,
    ),
  );
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

/// Provider for optimistic user interactions (immediate UI feedback)
final optimisticUserInteractionProvider = StateNotifierProvider.family<
    OptimisticUserInteractionNotifier,
    Interaction?,
    ({String targetType, String targetId, String userCPId})>((ref, params) {
  // Get the initial state from the actual provider
  final initialState = ref.watch(userInteractionProvider(params)).value;

  return OptimisticUserInteractionNotifier(initialState);
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
  return PostInteractionNotifier(repository, postId, ref);
});

/// Provider for comment interactions
final commentInteractionProvider = StateNotifierProvider.family<
    CommentInteractionNotifier, AsyncValue<void>, String>((ref, commentId) {
  final repository = ref.watch(forumRepositoryProvider);
  return CommentInteractionNotifier(repository, commentId, ref);
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

/// Notifier for optimistic user interactions
class OptimisticUserInteractionNotifier extends StateNotifier<Interaction?> {
  OptimisticUserInteractionNotifier(Interaction? initialState)
      : super(initialState);

  void updateOptimistically(int newValue) {
    // Immediately update UI state
    if (newValue == 0) {
      state = null;
    } else {
      state = Interaction(
        id: state?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        targetType: state?.targetType ?? 'post',
        targetId: state?.targetId ?? '',
        userCPId: state?.userCPId ?? '',
        type: 'like',
        value: newValue,
        createdAt: DateTime.now(),
      );
    }
  }

  void revertOptimistic(Interaction? originalState) {
    // Revert to original state if needed
    state = originalState;
  }

  void confirmOptimistic(Interaction? confirmedState) {
    // Confirm the optimistic state with real data
    state = confirmedState;
  }
}

/// State for optimistic post updates
class OptimisticPostState {
  final String postId;
  final int likeCount;
  final int dislikeCount;
  final bool isDeleted;

  const OptimisticPostState({
    required this.postId,
    required this.likeCount,
    required this.dislikeCount,
    this.isDeleted = false,
  });

  OptimisticPostState copyWith({
    int? likeCount,
    int? dislikeCount,
    bool? isDeleted,
  }) {
    return OptimisticPostState(
      postId: postId,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Notifier for optimistic post state
class OptimisticPostStateNotifier extends StateNotifier<OptimisticPostState> {
  OptimisticPostStateNotifier(OptimisticPostState initialState)
      : super(initialState);

  void updateOptimisticCounts(int oldValue, int newValue) {
    int newLikeCount = state.likeCount;
    int newDislikeCount = state.dislikeCount;

    // Remove old interaction impact
    if (oldValue == 1) {
      newLikeCount = math.max(0, newLikeCount - 1);
    } else if (oldValue == -1) {
      newDislikeCount = math.max(0, newDislikeCount - 1);
    }

    // Add new interaction impact
    if (newValue == 1) {
      newLikeCount = newLikeCount + 1;
    } else if (newValue == -1) {
      newDislikeCount = newDislikeCount + 1;
    }

    state = state.copyWith(
      likeCount: newLikeCount,
      dislikeCount: newDislikeCount,
    );
  }

  void revertOptimisticCounts(int likeCount, int dislikeCount) {
    // Revert to original counts
    state = state.copyWith(
      likeCount: likeCount,
      dislikeCount: dislikeCount,
    );
  }

  void confirmOptimisticCounts(int likeCount, int dislikeCount) {
    // Confirm the optimistic counts with real data
    state = state.copyWith(
      likeCount: likeCount,
      dislikeCount: dislikeCount,
    );
  }

  void markAsDeleted() {
    // Mark post as deleted optimistically for immediate UI feedback
    state = state.copyWith(isDeleted: true);
  }

  void revertDeletion() {
    // Revert deletion if operation failed
    state = state.copyWith(isDeleted: false);
  }
}

/// Notifier for post interactions
class PostInteractionNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _postId;
  final Ref _ref;

  PostInteractionNotifier(this._repository, this._postId, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> interact(int value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.interactWithPost(postId: _postId, value: value);
      state = const AsyncValue.data(null);

      // Only invalidate specific user interaction cache to refresh real state
      _ref.invalidate(userInteractionProvider);

      // Refresh post detail and confirm optimistic counts with real data
      _ref.invalidate(postDetailProvider(_postId));

      // Get updated post to confirm optimistic counts
      final updatedPostAsync = _ref.read(postDetailProvider(_postId));
      updatedPostAsync.whenData((updatedPost) {
        if (updatedPost != null) {
          // Confirm optimistic counts with real counts
          _ref
              .read(optimisticPostStateProvider(_postId).notifier)
              .confirmOptimisticCounts(
                  updatedPost.likeCount, updatedPost.dislikeCount);
        }
      });

      // Don't invalidate post lists to prevent disappearing posts
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      // If interaction failed (likely due to ban), optimistic changes will be reverted
      // by the CommunityInteractionGuard's _revertOptimisticChanges method
    }
  }
}

/// Notifier for comment interactions
class CommentInteractionNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumRepository _repository;
  final String _commentId;
  final Ref _ref;

  CommentInteractionNotifier(this._repository, this._commentId, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> interact(int value) async {
    state = const AsyncValue.loading();
    try {
      await _repository.interactWithComment(
          commentId: _commentId, value: value);
      state = const AsyncValue.data(null);

      // Invalidate user interaction cache to refresh UI
      _ref.invalidate(userInteractionProvider);
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
  final Ref _ref;

  PostsPaginationNotifier(this._repository, this._ref)
      : super(PostsPaginationState.initial());

  /// Loads the first page of posts with mandatory gender filtering
  Future<void> loadPosts({String? category, bool? isPinned}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user's gender for mandatory filtering
      final currentProfile = _ref.read(currentCommunityProfileProvider).value;

      // Determine if gender filtering should be applied based on content type
      final filterParams =
          PostFilterParams(category: category, isPinned: isPinned);
      final shouldApplyGenderFilter = filterParams.shouldApplyGenderFilter;

      // Debug logging to verify gender filtering
      _debugGenderFiltering(
        'PostsPaginationNotifier.loadPosts',
        category: category,
        isPinned: isPinned,
        userGender: currentProfile?.gender,
        shouldApplyFilter: shouldApplyGenderFilter,
      );

      final page = await _repository.getPosts(
        limit: 10,
        category: category,
        isPinned: isPinned,
        userGender: currentProfile?.gender,
        applyGenderFilter: shouldApplyGenderFilter,
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

  /// Loads more posts for pagination with mandatory gender filtering
  Future<void> loadMorePosts({String? category, bool? isPinned}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      // Get current user's gender for mandatory filtering
      final currentProfile = _ref.read(currentCommunityProfileProvider).value;

      // Determine if gender filtering should be applied based on content type
      final filterParams =
          PostFilterParams(category: category, isPinned: isPinned);
      final shouldApplyGenderFilter = filterParams.shouldApplyGenderFilter;

      // Debug logging to verify gender filtering
      _debugGenderFiltering(
        'PostsPaginationNotifier.loadMorePosts',
        category: category,
        isPinned: isPinned,
        userGender: currentProfile?.gender,
        shouldApplyFilter: shouldApplyGenderFilter,
      );

      final page = await _repository.getPosts(
        limit: 10,
        lastDocument: state.lastDocument,
        category: category,
        isPinned: isPinned,
        userGender: currentProfile?.gender,
        applyGenderFilter: shouldApplyGenderFilter,
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
  Future<void> refresh({String? category, bool? isPinned}) async {
    state = PostsPaginationState.initial();
    await loadPosts(category: category, isPinned: isPinned);
  }

  /// Loads the next page of posts (new method name)
  Future<void> loadNextPage({String? category, bool? isPinned}) async {
    return loadMorePosts(category: category, isPinned: isPinned);
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
