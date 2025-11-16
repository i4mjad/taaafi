import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/repositories/updates_repository.dart';
import '../domain/entities/group_update_entity.dart';
import '../domain/entities/update_comment_entity.dart';
import '../domain/services/updates_service.dart';
import '../domain/services/followup_integration_service.dart';
import '../domain/services/update_preset_templates.dart';
import '../data/repositories/updates_repository_impl.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_repository.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

part 'updates_providers.g.dart';

// ==================== REPOSITORY PROVIDERS ====================

/// Firestore instance provider
@riverpod
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Updates repository provider
@riverpod
UpdatesRepository updatesRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return UpdatesRepositoryImpl(firestore);
}

// ==================== SERVICE PROVIDERS ====================

/// Followup repository provider (for groups feature)
@riverpod
FollowUpRepository followUpRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return FollowUpRepository(firestore, ref);
}

/// Followup integration service provider
@riverpod
FollowupIntegrationService followupIntegrationService(Ref ref) {
  final followupRepo = ref.watch(followUpRepositoryProvider);
  return FollowupIntegrationService(followupRepo);
}

/// Updates service provider
@riverpod
UpdatesService updatesService(Ref ref) {
  final repository = ref.watch(updatesRepositoryProvider);
  final followupService = ref.watch(followupIntegrationServiceProvider);
  return UpdatesService(repository, followupService);
}

// ==================== UPDATE QUERY PROVIDERS ====================

/// Stream of all updates for a group
@riverpod
Stream<List<GroupUpdateEntity>> groupUpdates(
  Ref ref,
  String groupId,
) {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getGroupUpdates(groupId);
}

/// Get recent updates with pagination
@riverpod
Future<List<GroupUpdateEntity>> recentUpdates(
  Ref ref,
  String groupId, {
  int limit = 20,
  DateTime? before,
}) async {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getRecentUpdates(groupId, limit: limit, before: before);
}

/// Get update by ID
@riverpod
Future<GroupUpdateEntity?> updateById(
  Ref ref,
  String updateId,
) async {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getUpdateById(updateId);
}

/// Stream of latest N updates for group (for real-time feed)
@riverpod
Stream<List<GroupUpdateEntity>> latestUpdates(
  Ref ref,
  String groupId, {
  int limit = 5,
}) {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getLatestUpdates(groupId, limit: limit);
}

/// Get user updates in a group
@riverpod
Future<List<GroupUpdateEntity>> userUpdates(
  Ref ref,
  String groupId,
  String cpId, {
  int limit = 20,
}) async {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getUserUpdates(groupId, cpId, limit: limit);
}

/// Get updates by type
@riverpod
Future<List<GroupUpdateEntity>> updatesByType(
  Ref ref,
  String groupId,
  UpdateType type, {
  int limit = 20,
}) async {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getUpdatesByType(groupId, type, limit: limit);
}

/// Get pinned updates for a group
@riverpod
Future<List<GroupUpdateEntity>> pinnedUpdates(
  Ref ref,
  String groupId,
) async {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getPinnedUpdates(groupId);
}

// ==================== COMMENT PROVIDERS ====================

/// Stream of comments for an update
@riverpod
Stream<List<UpdateCommentEntity>> updateComments(
  Ref ref,
  String updateId,
) {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getUpdateComments(updateId);
}

/// Get comment count for an update
@riverpod
Future<int> commentCount(
  Ref ref,
  String updateId,
) async {
  final repository = ref.watch(updatesRepositoryProvider);
  return repository.getCommentCount(updateId);
}

// ==================== PRESET TEMPLATES PROVIDER ====================

/// Get all preset templates
@riverpod
List<UpdatePresetTemplate> presetTemplates(Ref ref) {
  return UpdatePresetTemplates.getAllPresets();
}

/// Get presets by category
@riverpod
List<UpdatePresetTemplate> presetsByCategory(
  Ref ref,
  PresetCategory category,
) {
  return UpdatePresetTemplates.getPresetsByCategory(category);
}

/// Get all preset categories
@riverpod
List<PresetCategory> presetCategories(Ref ref) {
  return UpdatePresetTemplates.getAllCategories();
}

// ==================== SUGGESTIONS PROVIDER ====================

/// Get suggested updates for current user in a group
@riverpod
Future<List<UpdateSuggestion>> updateSuggestions(
  Ref ref,
  String groupId,
) async {
  final service = ref.watch(updatesServiceProvider);
  final currentProfile = await ref.read(currentCommunityProfileProvider.future);
  
  if (currentProfile == null) {
    return [];
  }

  return service.getSuggestedUpdates(currentProfile.id, groupId);
}

// ==================== ACTION CONTROLLERS ====================

/// Controller for posting updates
@riverpod
class PostUpdateController extends _$PostUpdateController {
  @override
  bool build() => false; // false = not loading

  Future<PostUpdateResult> postUpdate({
    required String groupId,
    required UpdateType type,
    required String title,
    required String content,
    String? linkedFollowupId,
    String? linkedChallengeId,
    bool isAnonymous = false,
  }) async {
    state = true; // loading

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        return PostUpdateResult.failure('User profile not found');
      }

      final result = await service.postUpdate(
        groupId: groupId,
        authorCpId: currentProfile.id,
        type: type,
        title: title,
        content: content,
        linkedFollowupId: linkedFollowupId,
        linkedChallengeId: linkedChallengeId,
        isAnonymous: isAnonymous,
      );

      return result;
    } finally {
      state = false; // not loading
    }
  }

  Future<PostUpdateResult> postFromPreset({
    required String groupId,
    required String presetId,
    String? additionalContent,
    bool isAnonymous = false,
  }) async {
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        return PostUpdateResult.failure('User profile not found');
      }

      return await service.createUpdateFromPreset(
        groupId: groupId,
        authorCpId: currentProfile.id,
        presetId: presetId,
        additionalContent: additionalContent,
        isAnonymous: isAnonymous,
      );
    } finally {
      state = false;
    }
  }

  Future<PostUpdateResult> postFromFollowup({
    required String groupId,
    required String followupId,
    bool isAnonymous = false,
  }) async {
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        return PostUpdateResult.failure('User profile not found');
      }

      // TODO: Get the followup by ID
      // For now, this would need the actual followup model
      // You'll need to implement this based on your followup service
      
      return PostUpdateResult.failure('Followup integration pending');
    } finally {
      state = false;
    }
  }
}

/// Controller for posting comments
@riverpod
class PostCommentController extends _$PostCommentController {
  @override
  bool build() => false;

  Future<void> postComment({
    required String updateId,
    required String content,
    bool isAnonymous = false,
  }) async {
    state = true;
    try {
      final repository = ref.read(updatesRepositoryProvider);
      final currentProfile = await ref.read(currentCommunityProfileProvider.future);
      
      if (currentProfile == null) {
        throw Exception('Not authenticated');
      }

      // Get the update to find groupId
      final update = await repository.getUpdateById(updateId);
      if (update == null) {
        throw Exception('Update not found');
      }

      await repository.addComment(
        UpdateCommentEntity(
          id: '', // Will be generated by Firestore
          updateId: updateId,
          groupId: update.groupId,
          authorCpId: currentProfile.id,
          content: content,
          isAnonymous: isAnonymous,
          isHidden: false,
          reactions: {},
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      state = false;
    }
  }
}

/// Controller for deleting comments
@riverpod
class DeleteCommentController extends _$DeleteCommentController {
  @override
  bool build() => false;

  Future<void> deleteComment({required String commentId}) async {
    state = true;
    try {
      final repository = ref.read(updatesRepositoryProvider);
      final currentProfile = await ref.read(currentCommunityProfileProvider.future);
      
      if (currentProfile == null) {
        throw Exception('Not authenticated');
      }
      
      await repository.deleteComment(commentId, currentProfile.id);
    } finally {
      state = false;
    }
  }
}

/// Controller for update reactions
@riverpod
class UpdateReactionsController extends _$UpdateReactionsController {
  @override
  bool build() => false;

  Future<void> toggleReaction({
    required String updateId,
    required String emoji,
  }) async {
    if (state) return; // Already processing
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      await service.reactToUpdate(updateId, currentProfile.id, emoji);
    } finally {
      state = false;
    }
  }
}

/// Controller for comments
@riverpod
class CommentsController extends _$CommentsController {
  @override
  bool build() => false;

  Future<String?> addComment({
    required String updateId,
    required String groupId,
    required String content,
    bool isAnonymous = false,
  }) async {
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      return await service.commentOnUpdate(
        updateId: updateId,
        groupId: groupId,
        authorCpId: currentProfile.id,
        content: content,
        isAnonymous: isAnonymous,
      );
    } finally {
      state = false;
    }
  }

  Future<void> deleteComment({
    required String commentId,
    required String updateId,
    required bool isAdmin,
  }) async {
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      await service.deleteComment(
        commentId: commentId,
        updateId: updateId,
        cpId: currentProfile.id,
        isAdmin: isAdmin,
      );
    } finally {
      state = false;
    }
  }
}

/// Controller for comment reactions
@riverpod
class CommentReactionsController extends _$CommentReactionsController {
  @override
  bool build() => false;

  Future<void> toggleReaction({
    required String commentId,
    required String emoji,
  }) async {
    if (state) return;
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      await service.reactToComment(commentId, currentProfile.id, emoji);
    } finally {
      state = false;
    }
  }
}

/// Controller for update management (edit/delete)
@riverpod
class UpdateManagementController extends _$UpdateManagementController {
  @override
  bool build() => false;

  Future<void> deleteUpdate({
    required String updateId,
    required bool isAdmin,
  }) async {
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      await service.deleteUpdate(updateId, currentProfile.id, isAdmin);
    } finally {
      state = false;
    }
  }

  Future<void> editUpdate({
    required String updateId,
    String? newTitle,
    String? newContent,
  }) async {
    state = true;

    try {
      final service = ref.read(updatesServiceProvider);
      final currentProfile =
          await ref.read(currentCommunityProfileProvider.future);

      if (currentProfile == null) {
        throw Exception('User profile not found');
      }

      await service.editUpdate(
        updateId: updateId,
        cpId: currentProfile.id,
        newTitle: newTitle,
        newContent: newContent,
      );
    } finally {
      state = false;
    }
  }
}

