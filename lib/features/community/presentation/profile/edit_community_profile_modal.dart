import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

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
  bool _isLoading = false;
  String _imageOption = 'none'; // 'default', 'none'
  String? _currentUserImageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.profile.displayName);
    _isAnonymous = widget.profile.isAnonymous;
    _selectedGender = widget.profile.gender;

    // Set initial image option based on current profile
    _imageOption = widget.profile.avatarUrl != null ? 'default' : 'none';

    _loadCurrentUserImage();

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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

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
                        // Profile Picture Section
                        Center(
                          child: Column(
                            children: [
                              // Show preview based on selected image option
                              if (_imageOption == 'default' &&
                                  _currentUserImageUrl != null &&
                                  !_isAnonymous)
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: theme.primary[300]!, width: 2),
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
                                          size: 80,
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                AvatarWithAnonymity(
                                  cpId: widget.profile.id,
                                  isAnonymous: _isAnonymous,
                                  size: 80,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                localizations
                                    .translate('community-profile-picture'),
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Profile Image Selection
                        _buildSectionTitle(
                          localizations.translate('community-profile-picture'),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingImage)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Spinner(),
                            ),
                          )
                        else
                          Column(
                            children: [
                              RadioListTile<String>(
                                title: Text(
                                  localizations.translate('default-image'),
                                  style:
                                      TextStyles.footnote.copyWith(height: 1.4),
                                ),
                                value: 'default',
                                groupValue: _imageOption,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _imageOption = value!;
                                        });
                                      },
                              ),
                              RadioListTile<String>(
                                title: Text(
                                  localizations.translate('without-image'),
                                  style:
                                      TextStyles.footnote.copyWith(height: 1.4),
                                ),
                                value: 'none',
                                groupValue: _imageOption,
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _imageOption = value!;
                                        });
                                      },
                              ),
                            ],
                          ),

                        if (_imageOption == 'default') ...[
                          const SizedBox(height: 8),
                          if (_currentUserImageUrl != null) ...[
                            WidgetsContainer(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: theme.primary[50],
                              borderRadius: BorderRadius.circular(10.5),
                              borderSide: BorderSide(
                                  color: theme.primary[200]!, width: 1),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      localizations.translate(
                                          'will-use-following-image'),
                                      style: TextStyles.caption
                                          .copyWith(height: 1.4),
                                    ),
                                  ),
                                  horizontalSpace(Spacing.points24),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                          color: theme.primary[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        _currentUserImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: theme.grey[200],
                                            child: Icon(
                                              LucideIcons.user,
                                              color: theme.grey[600],
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.warn[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.warn[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.info,
                                    size: 20,
                                    color: theme.warn[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      localizations.translate(
                                          'no-profile-image-available'),
                                      style: TextStyles.caption.copyWith(
                                        color: theme.warn[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 24),

                        // Anonymous Mode Toggle
                        _buildSectionTitle(
                          localizations.translate('community-anonymous-mode'),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        WidgetsContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.primary[50],
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.shieldCheck,
                                    size: 26,
                                    color: theme.primary[600],
                                  ),
                                  horizontalSpace(Spacing.points8),
                                  Expanded(
                                    child: Text(
                                      localizations.translate(
                                          'community-post-anonymously-by-default'),
                                      style: TextStyles.body.copyWith(
                                        color: theme.primary[900],
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _isAnonymous,
                                    onChanged: (value) {
                                      setState(() {
                                        _isAnonymous = value;
                                      });
                                    },
                                    activeColor: theme.primary[500],
                                  ),
                                ],
                              ),
                              Text(
                                localizations.translate(
                                    'community-anonymous-mode-description'),
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Display Name
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
                        if (_isAnonymous) ...[
                          const SizedBox(height: 8),
                          _buildInfoBox(
                            localizations.translate(
                                'community-anonymous-mode-description'),
                            theme,
                          ),
                        ],
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

  Widget _buildInfoBox(String text, CustomThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.warn[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.warn[200]!),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.shieldAlert,
            size: 26,
            color: theme.warn[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyles.caption.copyWith(
                color: theme.warn[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
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
}
