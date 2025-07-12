import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/community_profile.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_with_anonymity.dart';

class EditCommunityProfileModal extends ConsumerStatefulWidget {
  final CommunityProfile profile;

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
  late bool _postAnonymouslyByDefault;
  late String _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.profile.displayName);
    _postAnonymouslyByDefault = widget.profile.postAnonymouslyByDefault;
    _selectedGender = widget.profile.gender;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
                              AvatarWithAnonymity(
                                cpId: widget.profile.id,
                                isAnonymous: _postAnonymouslyByDefault,
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
                              if (_postAnonymouslyByDefault) ...[
                                const SizedBox(height: 4),
                                Text(
                                  localizations.translate(
                                      'community-anonymous-mode-enabled'),
                                  style: TextStyles.tiny.copyWith(
                                    color: theme.warn[600],
                                  ),
                                ),
                              ],
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
                          hint: localizations.translate('enter_display_name'),
                          prefixIcon: LucideIcons.user,
                          inputType: TextInputType.text,
                          enabled: !_postAnonymouslyByDefault,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return localizations.translate('field-required');
                            }
                            return null;
                          },
                        ),
                        if (_postAnonymouslyByDefault) ...[
                          const SizedBox(height: 8),
                          _buildInfoBox(
                            localizations.translate(
                                'community-anonymous-mode-description'),
                            theme,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Gender Selection
                        _buildSectionTitle(
                          localizations.translate('gender'),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        _buildGenderSelector(theme, localizations),

                        const SizedBox(height: 24),

                        // Anonymous Mode Toggle
                        _buildSectionTitle(
                          localizations.translate('community-anonymous-mode'),
                          theme,
                        ),
                        const SizedBox(height: 8),
                        WidgetsContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      localizations.translate(
                                          'community-post-anonymously-by-default'),
                                      style: TextStyles.body.copyWith(
                                        color: theme.grey[900],
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _postAnonymouslyByDefault,
                                    onChanged: (value) {
                                      setState(() {
                                        _postAnonymouslyByDefault = value;
                                      });
                                    },
                                    activeColor: theme.primary[500],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.translate(
                                    'community-anonymous-mode-description'),
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
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
            LucideIcons.info,
            size: 16,
            color: theme.warn[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyles.caption.copyWith(
                color: theme.warn[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(
      CustomThemeData theme, AppLocalizations localizations) {
    return Row(
      children: [
        _buildGenderOption('male', localizations.translate('male'), theme),
        const SizedBox(width: 12),
        _buildGenderOption('female', localizations.translate('female'), theme),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label, CustomThemeData theme) {
    final isSelected = _selectedGender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary[50] : theme.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? theme.primary[300]! : theme.grey[200]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyles.body.copyWith(
                color: isSelected ? theme.primary[700] : theme.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.trim().isEmpty &&
        !_postAnonymouslyByDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('field-required'),
          ),
          backgroundColor: AppTheme.of(context).error[500],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement actual profile update logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .translate('community-profile-updated'),
            ),
            backgroundColor: AppTheme.of(context).success[500],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .translate('community-profile-update-failed'),
            ),
            backgroundColor: AppTheme.of(context).error[500],
          ),
        );
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
