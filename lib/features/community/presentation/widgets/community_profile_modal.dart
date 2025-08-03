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
import 'package:reboot_app_3/features/community/domain/entities/profile_statistics.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/shared/data/notifiers/user_reports_notifier.dart';
import 'package:intl/intl.dart';

class CommunityProfileModal extends ConsumerStatefulWidget {
  final String communityProfileId;
  final String displayName;
  final String? avatarUrl;
  final bool isAnonymous;
  final bool isPlusUser;

  const CommunityProfileModal({
    super.key,
    required this.communityProfileId,
    required this.displayName,
    required this.avatarUrl,
    required this.isAnonymous,
    required this.isPlusUser,
  });

  @override
  ConsumerState<CommunityProfileModal> createState() =>
      _CommunityProfileModalState();
}

class _CommunityProfileModalState extends ConsumerState<CommunityProfileModal> {
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
        // Extract the localization key from the exception message
        String errorKey = 'error-reporting-user';
        if (e.toString().contains('Exception: ')) {
          final extractedKey = e.toString().replaceFirst('Exception: ', '');
          // Check if it's one of our known error keys
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

              // Statistics Section
              FutureBuilder<ProfileStatistics>(
                future: ref
                    .read(communityServiceProvider)
                    .getProfileStatistics(widget.communityProfileId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingStatistics(context);
                  } else if (snapshot.hasError) {
                    return _buildErrorStatistics(context);
                  } else if (snapshot.hasData) {
                    return _buildStatistics(context, snapshot.data!);
                  } else {
                    return _buildErrorStatistics(context);
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
                    if (profile.isPlusUser == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primary[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: theme.primary[300]!,
                            width: 0.5,
                          ),
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      verticalSpace(Spacing.points8),
                    ],
                    Text(
                      '${localizations.translate('member-since')} ${_formatDate(profile.createdAt, localizations.locale.languageCode)}',
                      style: TextStyles.caption.copyWith(
                        color: theme.grey[600],
                      ),
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

  Widget _buildStatistics(BuildContext context, ProfileStatistics stats) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('user-statistics'),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        verticalSpace(Spacing.points12),
        WidgetsContainer(
          padding: const EdgeInsets.all(16),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(color: theme.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              _buildStatItem(
                context,
                LucideIcons.messageSquare,
                localizations.translate('total-posts'),
                stats.postCount.toString(),
              ),
              verticalSpace(Spacing.points12),
              _buildStatItem(
                context,
                LucideIcons.messageCircle,
                localizations.translate('total-comments'),
                stats.commentCount.toString(),
              ),
              verticalSpace(Spacing.points12),
              _buildStatItem(
                context,
                LucideIcons.heart,
                localizations.translate('total-interactions'),
                stats.interactionCount.toString(),
              ),
              verticalSpace(Spacing.points12),
              _buildStatItem(
                context,
                LucideIcons.thumbsUp,
                localizations.translate('interactions-received'),
                stats.receivedInteractionCount.toString(),
              ),
              verticalSpace(Spacing.points12),
              _buildStatItem(
                context,
                LucideIcons.calendar,
                localizations.translate('active-days'),
                stats.activeDays.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String label, String value) {
    final theme = AppTheme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.primary[600],
        ),
        horizontalSpace(Spacing.points12),
        Expanded(
          child: Text(
            label,
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyles.body.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatistics(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('user-statistics'),
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

  Widget _buildErrorStatistics(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('user-statistics'),
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
                  localizations.translate('error_loading_stats'),
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
