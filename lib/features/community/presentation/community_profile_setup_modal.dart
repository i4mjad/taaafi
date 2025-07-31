import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';
import 'package:reboot_app_3/features/plus/data/notifiers/subscription_notifier.dart';

class CommunityProfileSetupModal extends ConsumerStatefulWidget {
  const CommunityProfileSetupModal({super.key});

  @override
  ConsumerState<CommunityProfileSetupModal> createState() =>
      _CommunityProfileSetupModalState();
}

class _CommunityProfileSetupModalState
    extends ConsumerState<CommunityProfileSetupModal> {
  final _displayNameController = TextEditingController();
  String? _selectedGender;
  bool _isAnonymous = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _showGenderSelection = true;
  bool _isLoadingUserData = true;
  String _imageOption = 'none'; // 'default', 'custom', 'none'
  String? _currentUserImageUrl;

  @override
  void initState() {
    super.initState();
    _checkUserGender();
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

  Future<void> _checkUserGender() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoadingUserData = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final gender = data?['gender'] as String?;

        if (gender != null && (gender == 'male' || gender == 'female')) {
          setState(() {
            _selectedGender = gender;
            _showGenderSelection = false;
            _isLoadingUserData = false;
          });
          return;
        }
      }

      setState(() {
        _showGenderSelection = true;
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _showGenderSelection = true;
        _isLoadingUserData = false;
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.translate('community-setup'),
                    style: TextStyles.h4,
                  ),
                  IconButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                localizations.translate('complete-profile-setup'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),

              const SizedBox(height: 24),

              if (_isLoadingUserData)
                const Center(
                  child: Spinner(),
                )
              else ...[
                // Display name
                CustomTextField(
                  controller: _displayNameController,
                  hint: localizations.translate('community-display-name'),
                  prefixIcon: LucideIcons.user,
                  inputType: TextInputType.text,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations
                          .translate('name-should-not-be-empty');
                    }
                    if (value.trim().length < 2) {
                      return localizations.translate('name-too-short');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Gender selection (conditional)
                if (_showGenderSelection) ...[
                  Text(
                    localizations.translate('gender'),
                    style: TextStyles.h6,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(
                            localizations.translate('male'),
                            style: TextStyles.body,
                          ),
                          value: 'male',
                          groupValue: _selectedGender,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text(
                            localizations.translate('female'),
                            style: TextStyles.body,
                          ),
                          value: 'female',
                          groupValue: _selectedGender,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  // Warning message
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
                          LucideIcons.alertTriangle,
                          size: 16,
                          color: theme.warn[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localizations.translate('gender-selection-warning'),
                            style: TextStyles.caption.copyWith(
                              color: theme.warn[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Register as Anonymous switch
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.translate('register-as-anonymous'),
                        style: TextStyles.body,
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      activeColor: theme.success[500],
                      inactiveTrackColor: theme.grey[200],
                      inactiveThumbColor: theme.grey[900],
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _isAnonymous = value;
                              });
                            },
                    ),
                  ],
                ),
                if (_isAnonymous) ...[
                  const SizedBox(height: 8),
                  WidgetsContainer(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: theme.success[50],
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.success[200]!),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 24,
                          color: theme.success[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localizations
                                .translate('anonymous-mode-reassurance'),
                            style: TextStyles.caption.copyWith(
                              height: 1.5,
                              color: theme.success[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Profile image selection
                Text(
                  localizations.translate('community-profile-picture'),
                  style: TextStyles.h6,
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        localizations.translate('default-image'),
                        style: TextStyles.footnote.copyWith(height: 1.4),
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
                        style: TextStyles.footnote.copyWith(height: 1.4),
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
                      padding: EdgeInsets.all(16),
                      backgroundColor: theme.primary[50],
                      borderRadius: BorderRadius.circular(10.5),
                      borderSide:
                          BorderSide(color: theme.primary[200]!, width: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              localizations
                                  .translate('will-use-following-image'),
                              style: TextStyles.caption.copyWith(height: 1.4),
                            ),
                          ),
                          horizontalSpace(Spacing.points24),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: theme.primary[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                _currentUserImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
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
                              localizations
                                  .translate('no-profile-image-available'),
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
                verticalSpace(Spacing.points16),
                // Complete setup / Go to Community button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSuccess
                        ? _goToCommunity
                        : (_canComplete() && !_isLoading)
                            ? _completeSetup
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isSuccess ? theme.success[500] : theme.primary[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Spinner(
                              strokeWidth: 2,
                              valueColor: Colors.white,
                            ),
                          )
                        : _isSuccess
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.translate('go-to-community'),
                                    style: TextStyles.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                localizations.translate('complete-setup'),
                                style: TextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrentUserImage() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final photoURL = currentUser.photoURL;
      if (photoURL != null && photoURL.isNotEmpty) {
        setState(() {
          _currentUserImageUrl = photoURL;
        });
      }
    } catch (e) {
      // Silently handle error - user might not have an image
    }
  }

  bool _canComplete() {
    return _displayNameController.text.trim().isNotEmpty &&
        _selectedGender != null;
  }

  Future<void> _completeSetup() async {
    if (!_canComplete()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final createProfileNotifier =
          ref.read(communityProfileCreationProvider.notifier);

      // Check current subscription status
      final hasActiveSubscriptionStatus =
          ref.read(hasActiveSubscriptionProvider);

      await createProfileNotifier.createProfile(
        displayName: _displayNameController.text.trim(),
        gender: _selectedGender!,
        isAnonymous: _isAnonymous,
        avatarUrl: null, // No image upload for now
        isPlusUser: hasActiveSubscriptionStatus,
      );

      if (mounted) {
        // Invalidate the hasCommunityProfile provider to refresh the cache
        ref.refresh(hasCommunityProfileProvider);

        // Notify the community screen state that onboarding is completed
        ref.read(communityScreenStateProvider.notifier).onboardingCompleted();

        // Set success state
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        getErrorSnackBar(context, 'community-profile-creation-failed');
      }
    }
  }

  void _goToCommunity() {
    // Close modal
    Navigator.of(context).pop();

    // Navigate to community main screen
    context.goNamed(RouteNames.community.name);
  }
}
