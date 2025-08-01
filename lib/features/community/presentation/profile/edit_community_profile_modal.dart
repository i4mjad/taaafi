import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_radio.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/premium_blur_overlay.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';
import 'package:reboot_app_3/features/plus/data/repositories/subscription_repository.dart';
import 'package:reboot_app_3/features/vault/data/follow_up/follow_up_notifier.dart';
import 'package:reboot_app_3/features/community/domain/services/community_service.dart';

class EditCommunityProfileModal extends ConsumerStatefulWidget {
  final CommunityProfileEntity profile;

  const EditCommunityProfileModal({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<EditCommunityProfileModal> createState() =>
      _EditCommunityProfileModalState();
}

class _EditCommunityProfileModalState
    extends ConsumerState<EditCommunityProfileModal> {
  late TextEditingController _displayNameController;
  late bool _isAnonymous;
  late String _selectedGender;
  late bool _shareRelapseStreaks;
  bool _isLoading = false;
  String _imageOption = 'none'; // 'default', 'none'
  String? _currentUserImageUrl;
  bool _isLoadingImage = true;
  int? _currentStreakDays;
  bool _isLoadingStreak = false;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.profile.displayName);
    _isAnonymous = widget.profile.isAnonymous;
    _selectedGender = widget.profile.gender;
    _shareRelapseStreaks = widget.profile.shareRelapseStreaks ?? false;

    // Set initial image option based on current profile
    _imageOption = widget.profile.avatarUrl != null ? 'default' : 'none';

    _loadCurrentUserImage();
    _loadRelapseStreak();

    // Add listener to update button state when text changes
    _displayNameController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update the button state
      });
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserImage() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoadingImage = false;
        });
        return;
      }

      final photoURL = currentUser.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        setState(() {
          _currentUserImageUrl = photoURL;
          _isLoadingImage = false;
        });
      } else {
        setState(() {
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _loadRelapseStreak() async {
    setState(() {
      _isLoadingStreak = true;
    });

    try {
      // Get follow-up service to calculate streak
      final followUpService = ref.read(followUpServiceProvider);
      final streakDays = await followUpService.calculateDaysWithoutRelapse();

      setState(() {
        _currentStreakDays = streakDays;
        _isLoadingStreak = false;
      });
    } catch (e) {
      setState(() {
        _currentStreakDays = null;
        _isLoadingStreak = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);
    final isPlusUser = ref.watch(hasActiveSubscriptionProvider);

    // Check if user has Plus subscription
    final hasActiveSubscription = subscriptionAsync.maybeWhen(
      data: (subscription) =>
          subscription.status == SubscriptionStatus.plus &&
          subscription.isActive,
      orElse: () => false,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                        color: theme.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.translate('community-edit-profile'),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary[500],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: Spinner(
                                  strokeWidth: 2,
                                  valueColor: Colors.white,
                                ),
                              )
                            : Text(
                                localizations
                                    .translate('community-save-changes'),
                                style: TextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture Preview Section
                        const SizedBox(width: 16),
                        WidgetsContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.success[50],
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: theme.success[200]!, width: 1),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  // Show preview based on selected image option
                                  if (_imageOption == 'default' &&
                                      _currentUserImageUrl != null &&
                                      !_isAnonymous)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: theme.primary[300]!,
                                            width: 2),
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          _currentUserImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return AvatarWithAnonymity(
                                              cpId: widget.profile.id,
                                              isAnonymous: _isAnonymous,
                                              isPlusUser: isPlusUser,
                                              size: 40,
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  else
                                    AvatarWithAnonymity(
                                      cpId: widget.profile.id,
                                      isAnonymous: _isAnonymous,
                                      isPlusUser: isPlusUser,
                                      size: 40,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PlatformSwitch(
                                  value: _isAnonymous,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _isAnonymous = value;
                                          });
                                        },
                                  label: localizations.translate(
                                      'community-post-anonymously-by-default'),
                                  subtitle: localizations.translate(
                                      'community-anonymous-mode-description'),
                                  activeColor: theme.success[500],
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        // 1. Display Name (First and most important)
                        _buildSectionTitle(
                          localizations.translate('community-display-name'),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _displayNameController,
                          prefixIcon: LucideIcons.user,
                          inputType: TextInputType.text,
                          enabled: !_isAnonymous,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return localizations.translate('field-required');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // 2. Profile Image Selection
                        if (_isLoadingImage)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Spinner(),
                            ),
                          )
                        else
                          PlatformRadioGroup<String>(
                            title: localizations
                                .translate('community-profile-picture'),
                            value: _imageOption,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _imageOption = value!;
                                    });
                                  },
                            activeColor: theme.primary[600],
                            options: [
                              PlatformRadioOption<String>(
                                value: 'default',
                                title: localizations.translate('default-image'),
                                subtitle: _currentUserImageUrl != null
                                    ? localizations
                                        .translate('use-account-profile-image')
                                    : localizations.translate(
                                        'no-profile-image-available'),
                              ),
                              PlatformRadioOption<String>(
                                value: 'none',
                                title: localizations.translate('without-image'),
                                subtitle: localizations
                                    .translate('use-anonymous-avatar'),
                              ),
                            ],
                          ),

                        verticalSpace(Spacing.points16),
                        // 4. Plus Features Section (Premium features at the end)
                        _buildPlusFeatureSection(context, theme, localizations),

                        // 5. Danger Zone Section
                        _buildDangerZoneSection(context, theme, localizations),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, CustomThemeData theme) {
    return Text(
      title,
      style: TextStyles.h6.copyWith(
        color: theme.grey[900],
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoBox(String text, CustomThemeData theme,
      {bool isPlus = false, bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlus
            ? const Color(0xFFFEBA01).withValues(alpha: 0.1)
            : isWarning
                ? theme.warn[50]
                : theme.primary[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPlus
              ? const Color(0xFFFEBA01)
              : isWarning
                  ? theme.warn[200]!
                  : theme.primary[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPlus
                ? LucideIcons.crown
                : isWarning
                    ? LucideIcons.shieldAlert
                    : LucideIcons.info,
            size: 20,
            color: isPlus
                ? const Color(0xFFFEBA01)
                : isWarning
                    ? theme.warn[600]
                    : theme.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyles.caption.copyWith(
                color: isPlus
                    ? theme.grey[700]
                    : isWarning
                        ? theme.warn[700]
                        : theme.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context, CustomThemeData theme,
      AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Danger Zone Title
        Row(
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 20,
              color: theme.error[600],
            ),
            const SizedBox(width: 8),
            Text(
              localizations.translate('community-delete-profile'),
              style: TextStyles.h6.copyWith(
                color: theme.error[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Description
        Text(
          localizations.translate('community-delete-profile-description'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // Warning
        WidgetsContainer(
          padding: const EdgeInsets.all(12),
          backgroundColor: theme.error[50],
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.error[200]!,
            width: 1,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 16,
                color: theme.error[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.translate('community-delete-profile-warning'),
                  style: TextStyles.caption.copyWith(
                    color: theme.error[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Delete Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _showDeleteConfirmationDialog(
                    context, theme, localizations),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('community-delete-profile-button'),
                  style: TextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context,
      CustomThemeData theme, AppLocalizations localizations) {
    final TextEditingController confirmationController =
        TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    size: 24,
                    color: theme.error[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.translate('community-delete-profile'),
                      style: TextStyles.h5.copyWith(
                        color: theme.error[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations
                        .translate('community-delete-profile-description'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WidgetsContainer(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: theme.error[50],
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.error[200]!,
                      width: 1,
                    ),
                    child: Text(
                      localizations
                          .translate('community-delete-profile-warning'),
                      style: TextStyles.caption.copyWith(
                        color: theme.error[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('community-delete-profile-confirm'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmationController,
                    decoration: InputDecoration(
                      hintText: localizations
                          .translate('community-delete-profile-confirmation'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.error[500]!,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        canDelete = value.trim().toUpperCase() ==
                            localizations
                                .translate(
                                    'community-delete-profile-confirmation')
                                .toUpperCase();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(localizations
                            .translate('community-delete-profile-cancelled')),
                        backgroundColor: theme.success[600],
                      ),
                    );
                  },
                  child: Text(
                    localizations.translate('community-cancel'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: canDelete
                      ? () {
                          Navigator.of(dialogContext).pop();
                          _deleteProfile(context, localizations);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.error[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    localizations.translate('community-delete-profile-button'),
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProfile(
      BuildContext context, AppLocalizations localizations) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StreamBuilder<DeletionProgress>(
          stream: ref.read(communityServiceProvider).deleteProfile(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AlertDialog(
                title:
                    Text(localizations.translate('community-deletion-failed')),
                content: Text(snapshot.error.toString()),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go('/community/onboarding');
                    },
                    child: Text(localizations.translate('community-cancel')),
                  ),
                ],
              );
            }

            if (snapshot.hasData) {
              final progress = snapshot.data!;
              final isCompleted =
                  progress.step == DeletionStep.cleaningUpMappings &&
                      progress.completedItems == progress.totalItems;

              if (isCompleted) {
                // Auto-close after completion
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations
                          .translate('community-deletion-completed')),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh profile cache
                  ref.refresh(currentCommunityProfileProvider);
                  ref.refresh(hasCommunityProfileProvider);

                  // Navigate to community onboarding since user no longer has a profile
                  context.go('/community/onboarding');
                });
              }

              return AlertDialog(
                title: Text(
                    localizations.translate('community-deletion-progress')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress.percentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text(_getStepMessage(progress.step, localizations)),
                    if (progress.totalItems > 0) ...[
                      const SizedBox(height: 8),
                      Text('${progress.completedItems}/${progress.totalItems}'),
                    ],
                  ],
                ),
              );
            }

            return AlertDialog(
              title:
                  Text(localizations.translate('community-deletion-progress')),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing deletion...'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getStepMessage(DeletionStep step, AppLocalizations localizations) {
    switch (step) {
      case DeletionStep.deletingPosts:
        return localizations.translate('community-deletion-step-1');
      case DeletionStep.deletingComments:
        return localizations.translate('community-deletion-step-2');
      case DeletionStep.deletingInteractions:
        return localizations.translate('community-deletion-step-3');
      case DeletionStep.removingProfileData:
        return localizations.translate('community-deletion-step-4');
      case DeletionStep.cleaningUpMappings:
        return localizations.translate('community-deletion-step-5');
    }
  }

  Widget _buildPlusFeatureSection(BuildContext context, CustomThemeData theme,
      AppLocalizations localizations) {
    final themeController = ref.watch(customThemeProvider);
    final isDarkTheme = themeController.darkTheme;
    final subscriptionAsync = ref.watch(subscriptionNotifierProvider);
    final hasActiveSubscription = subscriptionAsync.maybeWhen(
      data: (subscription) =>
          subscription.status == SubscriptionStatus.plus &&
          subscription.isActive,
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plus Features Title with Premium Styling
        Row(
          children: [
            Icon(
              LucideIcons.car,
              color: const Color(0xFFFEBA01),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localizations.translate('share-progress'),
                style: TextStyles.h6.copyWith(
                  color: const Color(0xFFFEBA01),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          localizations.translate('plus-community-perks-guide-desc'),
          style: TextStyles.caption.copyWith(
            color: theme.grey[600],
          ),
        ),
        const SizedBox(height: 20),

        // Content with Premium Blur Overlay
        if (hasActiveSubscription)
          _buildStreakSharingContent(context, theme, localizations)
        else
          PremiumBlurOverlay(
            content: _buildStreakSharingContent(context, theme, localizations),
            isDarkTheme: isDarkTheme,
            constraints: const BoxConstraints(
              minHeight: 200,
              maxHeight: 300,
            ),
            margin: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildStreakSharingContent(BuildContext context, CustomThemeData theme,
      AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Streak Display
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.trophy,
                    size: 16,
                    color: const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('current-streak'),
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.grey[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoadingStreak)
                Text(
                  localizations.translate('loading'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                )
              else if (_currentStreakDays != null)
                Text(
                  localizations
                      .translate('days-streak')
                      .replaceAll('{days}', _currentStreakDays.toString()),
                  style: TextStyles.h6.copyWith(
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  localizations.translate('no-streak-data'),
                  style: TextStyles.caption.copyWith(
                    color: theme.grey[600],
                  ),
                ),
            ],
          ),
        ),

        // Streak Sharing Toggle
        PlatformSwitch(
          value: _shareRelapseStreaks,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _shareRelapseStreaks = value;
                  });
                },
          label: localizations.translate('allow-sharing-progress'),
          subtitle: localizations.translate('share-streak-description'),
          activeColor: const Color(0xFFFEBA01),
        ),

        // Add sync button if streak sharing is enabled but no data
        if (_shareRelapseStreaks && _currentStreakDays == null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isLoading ? null : _syncStreakData,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEBA01).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFEBA01).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.refreshCw,
                    size: 16,
                    color: const Color(0xFFFEBA01),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('sync-streak-data'),
                    style: TextStyles.body.copyWith(
                      color: const Color(0xFFFEBA01),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.trim().isEmpty && !_isAnonymous) {
      getErrorSnackBar(context, "field-required");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updateNotifier = ref.read(communityProfileUpdateProvider.notifier);

      // Determine avatar URL based on image option
      String? avatarUrl;
      if (_imageOption == 'default' && _currentUserImageUrl != null) {
        avatarUrl = _currentUserImageUrl;
      } else {
        avatarUrl = null; // No image
      }

      await updateNotifier.updateProfile(
        displayName: _displayNameController.text.trim(),
        gender: _selectedGender,
        isAnonymous: _isAnonymous,
        avatarUrl: avatarUrl,
        shareRelapseStreaks: _shareRelapseStreaks,
      );

      if (mounted) {
        Navigator.of(context).pop();
        getSuccessSnackBar(context, "community-profile-updated");
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, "community-profile-update-failed");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncStreakData() async {
    setState(() {
      _isLoadingStreak = true;
    });

    try {
      final followUpService = ref.read(followUpServiceProvider);
      final streakDays = await followUpService.calculateDaysWithoutRelapse();

      setState(() {
        _currentStreakDays = streakDays;
        _isLoadingStreak = false;
      });

      if (mounted) {
        getSuccessSnackBar(context, "streak-data-synced");
      }
    } catch (e) {
      if (mounted) {
        getErrorSnackBar(context, "streak-data-sync-failed");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStreak = false;
        });
      }
    }
  }
}
