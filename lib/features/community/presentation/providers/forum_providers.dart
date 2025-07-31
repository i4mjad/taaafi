import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/account/providers/ban_warning_providers.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'dart:math' as math;

/// Helper method to get community profile ID from user UID
Future<String?> _getCommunityProfileIdFromUserUID(
    FirebaseFirestore firestore, String userUID) async {
  try {
    final snapshot = await firestore
        .collection('communityProfiles')
        .where('userUID', isEqualTo: userUID)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.id;
  } catch (e) {
    print('ERROR: Failed to get community profile ID for user $userUID: $e');
    return null;
  }
}

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
  print('   User Gender: ${userGender ?? "NULL (profile not loaded/missing)"}');
  print('   Should Apply Filter: $shouldApplyFilter');
  if (userGender == null && shouldApplyFilter) {
    print(
        '   ⚠️  WARNING: Filtering enabled but user gender is null - will show all posts');
  }
  print(
      '   Rule: ${shouldApplyFilter ? "FILTERING ENABLED (same-gender + admins)" : "FILTERING DISABLED (all users)"}');
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
    // - News posts (global announcements)
    // - Challenge posts (community-wide events)
    // Note: Pinned posts ARE gender-filtered, but admin pinned posts are visible to all

    if (category != null) {
      switch (category!.toLowerCase()) {
        case 'news':
        case 'challenges':
          return false;
        default:
          return true;
      }
    }

    // Default to applying gender filter for all posts including pinned
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
  final firestore = ref.watch(firestoreProvider);
  final genderValidator = ref.watch(genderInteractionValidatorProvider);
  final banWarningFacade = ref.watch(banWarningFacadeProvider);
  return ForumService(repository, validationService, auth, firestore,
      genderValidator, banWarningFacade);
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

  // Handle different AsyncValue states more safely
  String? userGender;

  if (currentProfile.hasValue) {
    userGender = currentProfile.value?.gender;
  } else if (currentProfile.isLoading) {
    userGender = null;
  } else if (currentProfile.hasError) {
    userGender = null;
  }

  // Debug logging to verify gender filtering
  _debugGenderFiltering(
    'postsProvider',
    category: category,
    isPinned: null,
    userGender: userGender,
    shouldApplyFilter: shouldFilter,
  );

  await for (final posts in repository.watchPosts(
    limit: 10,
    category: category,
    userGender: userGender,
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

  String? userGender;
  if (currentProfile.hasValue) {
    userGender = currentProfile.value?.gender;
  } else {
    userGender = null;
  }

  await for (final posts in repository.watchPosts(
    limit: params.limit,
    category: params.category,
    isPinned: params.isPinned,
    userGender: userGender,
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

  // Handle different AsyncValue states more safely
  String? userGender;

  if (currentProfile.hasValue) {
    // Profile has loaded successfully
    userGender = currentProfile.value?.gender;
    print('🎯 MainScreenPostsProvider: Profile loaded, gender: $userGender');
  } else if (currentProfile.isLoading) {
    // Profile is still loading, use null gender
    userGender = null;
    print(
        '🎯 MainScreenPostsProvider: Profile still loading, will use null gender');
  } else if (currentProfile.hasError) {
    // Profile has error, use null gender
    userGender = null;
    print('🎯 MainScreenPostsProvider: Profile error: ${currentProfile.error}');
  }

  print(
      '🎯 MainScreenPostsProvider: Starting watchPosts with category: $category, userGender: $userGender, shouldFilter: $shouldFilter');

  await for (final posts in repository.watchPosts(
    limit: 50,
    category: category,
    userGender: userGender,
    applyGenderFilter: shouldFilter,
  )) {
    print(
        '🎯 MainScreenPostsProvider: Received ${posts.length} posts from repository');

    // Filter out optimistically deleted posts
    final filteredPosts = <Post>[];

    for (final post in posts) {
      final optimisticState = ref.read(optimisticPostStateProvider(post.id));
      if (!optimisticState.isDeleted) {
        filteredPosts.add(post);
      }
    }

    print(
        '🎯 MainScreenPostsProvider: After filtering deleted posts: ${filteredPosts.length} posts');

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

// Profile Tab Pagination Providers
final userPostsPaginationProvider = StateNotifierProvider.family<
    UserPostsPaginationNotifier,
    UserPostsPaginationState,
    String>((ref, userCPId) {
  final repository = ref.watch(forumRepositoryProvider);
  return UserPostsPaginationNotifier(repository, userCPId, ref);
});

final userCommentsPaginationProvider = StateNotifierProvider.family<
    UserCommentsPaginationNotifier,
    UserCommentsPaginationState,
    String>((ref, userCPId) {
  final repository = ref.watch(forumRepositoryProvider);
  return UserCommentsPaginationNotifier(repository, userCPId, ref);
});

final userLikedPostsPaginationProvider = StateNotifierProvider.family<
    UserLikedItemsPaginationNotifier,
    UserLikedItemsPaginationState,
    String>((ref, userCPId) {
  final repository = ref.watch(forumRepositoryProvider);
  return UserLikedItemsPaginationNotifier(repository, userCPId, ref, 'post');
});

final userLikedCommentsPaginationProvider = StateNotifierProvider.family<
    UserLikedItemsPaginationNotifier,
    UserLikedItemsPaginationState,
    String>((ref, userCPId) {
  final repository = ref.watch(forumRepositoryProvider);
  return UserLikedItemsPaginationNotifier(repository, userCPId, ref, 'comment');
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
final userInteractionProvider = FutureProvider.family.autoDispose<
    Interaction?,
    ({
      String targetType,
      String targetId,
      String userCPId
    })>((ref, params) async {
  final repository = ref.watch(forumRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);

  // Get community profile ID: use provided userCPId or get from user mapping
  String? userCPId;
  if (params.userCPId.isNotEmpty) {
    userCPId = params.userCPId;
  } else if (auth.currentUser != null) {
    userCPId = await _getCommunityProfileIdFromUserUID(
        firestore, auth.currentUser!.uid);
  }

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
    ({
      String targetType,
      String targetId,
      String userCPId
    })>((ref, params) async* {
  final repository = ref.watch(forumRepositoryProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);

  // Get community profile ID: use provided userCPId or get from user mapping
  String? userCPId;
  if (params.userCPId.isNotEmpty) {
    userCPId = params.userCPId;
  } else if (auth.currentUser != null) {
    userCPId = await _getCommunityProfileIdFromUserUID(
        firestore, auth.currentUser!.uid);
  }

  if (userCPId == null) {
    yield null;
    return;
  }

  yield* repository.watchUserInteraction(
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

  /// Helper method to get current user's community profile with proper error handling
  Future<CommunityProfileEntity?> _getCurrentUserProfile() async {
    try {
      final profileAsync = _ref.read(currentCommunityProfileProvider);

      return await profileAsync.when(
        data: (profile) async => profile,
        loading: () async {
          // Wait a bit for the profile to load
          await Future.delayed(Duration(milliseconds: 100));
          final retryAsync = _ref.read(currentCommunityProfileProvider);
          return retryAsync.maybeWhen(
            data: (profile) => profile,
            orElse: () => null,
          );
        },
        error: (_, __) async => null,
      );
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  /// Loads the first page of posts with mandatory gender filtering
  Future<void> loadPosts({String? category, bool? isPinned}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current user's gender for mandatory filtering
      final currentProfile = await _getCurrentUserProfile();

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
      final currentProfile = await _getCurrentUserProfile();

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

/// Notifier for user posts pagination
class UserPostsPaginationNotifier
    extends StateNotifier<UserPostsPaginationState> {
  final ForumRepository _repository;
  final String _userCPId;

  UserPostsPaginationNotifier(this._repository, this._userCPId, Ref ref)
      : super(UserPostsPaginationState.initial());

  Future<void> loadPosts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _repository.getUserPosts(
        userCPId: _userCPId,
        limit: 10,
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

  Future<void> loadMorePosts() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final page = await _repository.getUserPosts(
        userCPId: _userCPId,
        limit: 10,
        lastDocument: state.lastDocument,
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

  Future<void> refresh() async {
    state = UserPostsPaginationState.initial();
    await loadPosts();
  }

  void reset() {
    state = UserPostsPaginationState.initial();
  }
}

/// Notifier for user comments pagination
class UserCommentsPaginationNotifier
    extends StateNotifier<UserCommentsPaginationState> {
  final ForumRepository _repository;
  final String _userCPId;

  UserCommentsPaginationNotifier(this._repository, this._userCPId, Ref ref)
      : super(UserCommentsPaginationState.initial());

  Future<void> loadComments() async {
    if (state.isLoading) return;

    print(
        '📝 [DEBUG] UserCommentsPaginationNotifier.loadComments - Starting for userCPId: $_userCPId');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _repository.getUserComments(
        userCPId: _userCPId,
        limit: 10,
      );

      print(
          '📝 [DEBUG] UserCommentsPaginationNotifier.loadComments - Received ${page.comments.length} comments');

      state = state.copyWith(
        comments: page.comments,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
      );

      print(
          '📝 [DEBUG] UserCommentsPaginationNotifier.loadComments - State updated successfully');
    } catch (e) {
      print(
          '📝 [ERROR] UserCommentsPaginationNotifier.loadComments - Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreComments() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final page = await _repository.getUserComments(
        userCPId: _userCPId,
        limit: 10,
        lastDocument: state.lastDocument,
      );

      state = state.copyWith(
        comments: [...state.comments, ...page.comments],
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = UserCommentsPaginationState.initial();
    await loadComments();
  }

  void reset() {
    state = UserCommentsPaginationState.initial();
  }
}

/// Notifier for user liked items pagination
class UserLikedItemsPaginationNotifier
    extends StateNotifier<UserLikedItemsPaginationState> {
  final ForumRepository _repository;
  final String _userCPId;
  final String _itemType; // 'post' or 'comment'

  UserLikedItemsPaginationNotifier(
      this._repository, this._userCPId, Ref ref, this._itemType)
      : super(UserLikedItemsPaginationState.initial());

  Future<void> loadLikedItems() async {
    if (state.isLoading) return;

    print(
        '❤️📝 [DEBUG] UserLikedItemsPaginationNotifier.loadLikedItems - Starting for userCPId: $_userCPId, itemType: $_itemType');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = _itemType == 'post'
          ? await _repository.getUserLikedPosts(
              userCPId: _userCPId,
              limit: 10,
            )
          : await _repository.getUserLikedComments(
              userCPId: _userCPId,
              limit: 10,
            );

      print(
          '❤️📝 [DEBUG] UserLikedItemsPaginationNotifier.loadLikedItems - Received ${page.items.length} ${_itemType}s');

      state = state.copyWith(
        items: page.items,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
      );

      print(
          '❤️📝 [DEBUG] UserLikedItemsPaginationNotifier.loadLikedItems - State updated successfully');
    } catch (e) {
      print(
          '❤️📝 [ERROR] UserLikedItemsPaginationNotifier.loadLikedItems - Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMoreLikedItems() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final page = _itemType == 'post'
          ? await _repository.getUserLikedPosts(
              userCPId: _userCPId,
              limit: 10,
              lastDocument: state.lastDocument,
            )
          : await _repository.getUserLikedComments(
              userCPId: _userCPId,
              limit: 10,
              lastDocument: state.lastDocument,
            );

      state = state.copyWith(
        items: [...state.items, ...page.items],
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = UserLikedItemsPaginationState.initial();
    await loadLikedItems();
  }

  void reset() {
    state = UserLikedItemsPaginationState.initial();
  }
}

/// State for user posts pagination
class UserPostsPaginationState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final dynamic lastDocument;

  UserPostsPaginationState({
    required this.posts,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.lastDocument,
  });

  factory UserPostsPaginationState.initial() {
    return UserPostsPaginationState(
      posts: [],
      isLoading: false,
      hasMore: true,
    );
  }

  UserPostsPaginationState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    dynamic lastDocument,
  }) {
    return UserPostsPaginationState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

/// State for user comments pagination
class UserCommentsPaginationState {
  final List<Comment> comments;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final dynamic lastDocument;

  UserCommentsPaginationState({
    required this.comments,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.lastDocument,
  });

  factory UserCommentsPaginationState.initial() {
    return UserCommentsPaginationState(
      comments: [],
      isLoading: false,
      hasMore: true,
    );
  }

  UserCommentsPaginationState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? hasMore,
    String? error,
    dynamic lastDocument,
  }) {
    return UserCommentsPaginationState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

/// State for user liked items pagination
class UserLikedItemsPaginationState {
  final List<dynamic> items; // Can be List<Post> or List<Comment>
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final dynamic lastDocument;

  UserLikedItemsPaginationState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.lastDocument,
  });

  factory UserLikedItemsPaginationState.initial() {
    return UserLikedItemsPaginationState(
      items: [],
      isLoading: false,
      hasMore: true,
    );
  }

  UserLikedItemsPaginationState copyWith({
    List<dynamic>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    dynamic lastDocument,
  }) {
    return UserLikedItemsPaginationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
