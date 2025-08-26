import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textarea.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/role_chip.dart';
import 'package:reboot_app_3/features/shared/data/notifiers/user_reports_notifier.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Group-specific profile modal that shows user info within a group context
class GroupChatProfileModal extends ConsumerStatefulWidget {
  final String communityProfileId;
  final String groupId;
  final String displayName;
  final bool isAnonymous;
  final bool isPlusUser;

  const GroupChatProfileModal({
    super.key,
    required this.communityProfileId,
    required this.groupId,
    required this.displayName,
    required this.isAnonymous,
    required this.isPlusUser,
  });

  @override
  ConsumerState<GroupChatProfileModal> createState() =>
      _GroupChatProfileModalState();
}

class _GroupChatProfileModalState extends ConsumerState<GroupChatProfileModal> {
  bool _showReportForm = false;
  final TextEditingController _reportController = TextEditingController();
  bool _isSubmittingReport = false;

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  /// Helper function to localize special display name constants
  String _getLocalizedDisplayName(
      String displayName, AppLocalizations localizations) {
    switch (displayName) {
      case 'DELETED_USER':
        return localizations.translate('community-deleted-user');
      case 'ANONYMOUS_USER':
        return localizations.translate('community-anonymous');
      default:
        return displayName;
    }
  }

  /// Helper function to localize gender values
  String _getLocalizedGender(String gender, AppLocalizations localizations) {
    switch (gender.toLowerCase()) {
      case 'male':
        return localizations.translate('male');
      case 'female':
        return localizations.translate('female');
      default:
        return gender;
    }
  }

  String? _validateReportMessage(String? value) {
    final localization = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return localization.translate('field-required');
    }
    if (value.length > 1500) {
      return localization.translate('character-limit-exceeded');
    }
    return null;
  }

  /// Get Firebase Auth user creation date by UID
  Future<DateTime?> _getFirebaseAuthCreationDate(String userUID) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUID)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('userFirstDate')) {
          final timestamp = data['userFirstDate'] as Timestamp?;
          return timestamp?.toDate();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is still a member of this group
  Future<bool> _isStillGroupMember() async {
    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('group_memberships')
          .where('groupId', isEqualTo: widget.groupId)
          .where('cpId', isEqualTo: widget.communityProfileId)
          .where('isActive', isEqualTo: true)
          .get();

      // Debug logging
      print(
          'DEBUG: Checking membership for cpId: ${widget.communityProfileId}, groupId: ${widget.groupId}');
      print('DEBUG: Found ${membersSnapshot.docs.length} active memberships');

      return membersSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('DEBUG: Error checking group membership: $e');
      return false;
    }
  }

  /// Get count of messages by this user in this group
  Future<int> _getGroupMessageCount() async {
    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('group_messages')
          .where('groupId', isEqualTo: widget.groupId)
          .where('senderCpId', isEqualTo: widget.communityProfileId)
          .where('isDeleted', isEqualTo: false)
          .where('isHidden', isEqualTo: false)
          .get();

      return messagesSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if role should show member since date (only for member and user roles)
  bool _shouldShowMemberSinceDate(String role) {
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'member' || normalizedRole == 'user';
  }

  Future<void> _submitReport() async {
    if (_validateReportMessage(_reportController.text) != null) {
      return;
    }

    setState(() {
      _isSubmittingReport = true;
    });

    try {
      final reportsNotifier = ref.read(userReportsNotifierProvider.notifier);
      await reportsNotifier.submitUserReport(
        communityProfileId: widget.communityProfileId,
        userMessage: _reportController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        getSuccessSnackBar(context, 'user-reported');
      }
    } catch (e) {
      if (mounted) {
        String errorKey = 'error-reporting-user';
        if (e.toString().contains('Exception: ')) {
          final extractedKey = e.toString().replaceFirst('Exception: ', '');
          if ([
            'max-active-reports-reached',
            'message-cannot-be-empty',
            'message-exceeds-character-limit'
          ].contains(extractedKey)) {
            errorKey = extractedKey;
          }
        }
        getErrorSnackBar(context, errorKey);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final profileAsync =
        ref.watch(communityProfileByIdProvider(widget.communityProfileId));

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizations.translate('view-profile'),
                      style: TextStyles.h5.copyWith(color: theme.grey[900]),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      LucideIcons.x,
                      size: 24,
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),

              verticalSpace(Spacing.points24),

              // Profile Info Section
              profileAsync.when(
                data: (profile) => _buildProfileInfo(context, profile),
                loading: () => _buildLoadingProfileInfo(context),
                error: (error, stack) => _buildErrorProfileInfo(context),
              ),

              verticalSpace(Spacing.points24),

              // Group Membership & Messages Section
              FutureBuilder<Map<String, dynamic>>(
                future: _getGroupSpecificInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingGroupInfo(context);
                  } else if (snapshot.hasError) {
                    return _buildErrorGroupInfo(context);
                  } else if (snapshot.hasData) {
                    return _buildGroupInfo(context, snapshot.data!);
                  } else {
                    return _buildErrorGroupInfo(context);
                  }
                },
              ),

              verticalSpace(Spacing.points24),

              // Report User Section
              if (!_showReportForm) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReportForm = true;
                    });
                  },
                  child: WidgetsContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: theme.error[50],
                    borderSide: BorderSide(color: theme.error[300]!, width: 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.flag,
                          size: 20,
                          color: theme.error[600],
                        ),
                        horizontalSpace(Spacing.points12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('report-user'),
                                style: TextStyles.body.copyWith(
                                  color: theme.error[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              verticalSpace(Spacing.points4),
                              Text(
                                localizations.translate('report-user-subtitle'),
                                style: TextStyles.caption.copyWith(
                                  color: theme.error[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          localizations.locale.languageCode == 'ar'
                              ? LucideIcons.chevronLeft
                              : LucideIcons.chevronRight,
                          size: 16,
                          color: theme.error[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Report Form
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.translate('report-user'),
                          style:
                              TextStyles.h6.copyWith(color: theme.error[700]),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReportForm = false;
                              _reportController.clear();
                            });
                          },
                          child: Icon(
                            LucideIcons.x,
                            size: 20,
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ),

                    verticalSpace(Spacing.points16),

                    CustomTextArea(
                      controller: _reportController,
                      hint: localizations.translate('report-user-placeholder'),
                      prefixIcon: LucideIcons.messageCircle,
                      validator: _validateReportMessage,
                      enabled: !_isSubmittingReport,
                      height: 120,
                    ),

                    verticalSpace(Spacing.points16),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmittingReport ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.error[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSubmittingReport
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: Spinner(),
                              )
                            : Icon(LucideIcons.flag, size: 20),
                        label: Text(
                          localizations.translate('report-user'),
                          style: TextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get group-specific information (membership status and message count)
  Future<Map<String, dynamic>> _getGroupSpecificInfo() async {
    final futures = await Future.wait([
      _isStillGroupMember(),
      _getGroupMessageCount(),
    ]);

    return {
      'isStillMember': futures[0] as bool,
      'messageCount': futures[1] as int,
    };
  }

  Widget _buildProfileInfo(
      BuildContext context, CommunityProfileEntity? profile) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    if (profile == null) {
      return _buildErrorProfileInfo(context);
    }

    // Get the display name following the same pipeline logic as post headers
    final pipelineResult = profile.getDisplayNameWithPipeline();
    final displayName = _getLocalizedDisplayName(pipelineResult, localizations);
    final avatarUrl = profile.isAnonymous ? null : profile.avatarUrl;

    return WidgetsContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.grey[300]!, width: 1),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: theme.grey[200]!.withValues(alpha: 0.5),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            children: [
              AvatarWithAnonymity(
                isDeleted: profile.isDeleted,
                cpId: profile.id,
                isAnonymous: profile.isAnonymous,
                isPlusUser: profile.isPlusUser ?? false,
                size: 64,
                avatarUrl: avatarUrl,
              ),
              horizontalSpace(Spacing.points16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyles.h6.copyWith(
                        color: theme.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Row(
                      children: [
                        if (profile.isPlusUser == true) ...[
                          WidgetsContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            backgroundColor: theme.primary[100],
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: theme.primary[300]!,
                              width: 1,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: theme.primary[600],
                                ),
                                horizontalSpace(Spacing.points4),
                                Text(
                                  localizations.translate('plus-member'),
                                  style: TextStyles.small.copyWith(
                                    color: theme.primary[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          horizontalSpace(Spacing.points8),
                        ],
                        RoleChip(role: profile.role),
                      ],
                    ),
                    verticalSpace(Spacing.points8),
                    // Only show member since date for member and user roles
                    if (_shouldShowMemberSinceDate(profile.role)) ...[
                      FutureBuilder<DateTime?>(
                        future: _getFirebaseAuthCreationDate(profile.userUID),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: theme.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          } else if (snapshot.hasData &&
                              snapshot.data != null) {
                            return Text(
                              '${localizations.translate('member-since')} ${_formatDate(snapshot.data!, localizations.locale.languageCode)}',
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                              ),
                            );
                          } else {
                            // Fallback to profile creation date if Firebase auth date is not available
                            return Text(
                              '${localizations.translate('member-since')} ${_formatDate(profile.createdAt, localizations.locale.languageCode)}',
                              style: TextStyles.caption.copyWith(
                                color: theme.grey[600],
                              ),
                            );
                          }
                        },
                      ),
                      verticalSpace(Spacing.points4),
                    ],
                    Row(
                      children: [
                        Icon(
                          profile.gender.toLowerCase() == 'male'
                              ? LucideIcons.user
                              : LucideIcons.userCheck,
                          size: 14,
                          color: theme.grey[600],
                        ),
                        horizontalSpace(Spacing.points4),
                        Text(
                          _getLocalizedGender(profile.gender, localizations),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, Map<String, dynamic> groupInfo) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final isStillMember = groupInfo['isStillMember'] as bool;
    final messageCount = groupInfo['messageCount'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('group-activity'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points12),
        WidgetsContainer(
          padding: const EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(
            color: isStillMember ? theme.grey[300]! : theme.error[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Membership status
              Row(
                children: [
                  Icon(
                    isStillMember ? LucideIcons.userCheck : LucideIcons.userX,
                    size: 20,
                    color:
                        isStillMember ? theme.success[600] : theme.error[600],
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      isStillMember
                          ? localizations.translate('current-group-member')
                          : localizations.translate('no-longer-group-member'),
                      style: TextStyles.body.copyWith(
                        color:
                            isStillMember ? theme.grey[700] : theme.error[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              verticalSpace(Spacing.points12),

              // Message count
              Row(
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 20,
                    color: theme.primary[600],
                  ),
                  horizontalSpace(Spacing.points12),
                  Expanded(
                    child: Text(
                      localizations.translate('messages-in-group'),
                      style: TextStyles.body.copyWith(
                        color: theme.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    messageCount.toString(),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingProfileInfo(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.grey[300]!, width: 1),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Center(child: Spinner()),
          ),
          horizontalSpace(Spacing.points16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                verticalSpace(Spacing.points8),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGroupInfo(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('group-activity'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points12),
        WidgetsContainer(
          padding: const EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(color: theme.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Spinner(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorProfileInfo(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    return WidgetsContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: theme.error[50],
      borderSide: BorderSide(color: theme.error[300]!, width: 1),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 24,
            color: theme.error[600],
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Text(
              localizations.translate('community-profile-error'),
              style: TextStyles.body.copyWith(
                color: theme.error[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorGroupInfo(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('group-activity'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points12),
        WidgetsContainer(
          padding: const EdgeInsets.all(16),
          backgroundColor: theme.error[50],
          borderSide: BorderSide(color: theme.error[300]!, width: 1),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 20,
                color: theme.error[600],
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Text(
                  localizations.translate('error-loading-group-info'),
                  style: TextStyles.body.copyWith(
                    color: theme.error[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, String languageCode) {
    try {
      return DateFormat('MMM yyyy', languageCode == 'ar' ? 'ar' : 'en')
          .format(date);
    } catch (e) {
      return DateFormat('MMM yyyy', 'en').format(date);
    }
  }
}
