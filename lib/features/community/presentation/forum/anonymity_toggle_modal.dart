import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

class AnonymityToggleModal extends ConsumerStatefulWidget {
  final CommunityProfileEntity profile;
  final bool currentAnonymousState;
  final Function(bool)? onToggleComplete;

  const AnonymityToggleModal({
    super.key,
    required this.profile,
    required this.currentAnonymousState,
    this.onToggleComplete,
  });

  @override
  ConsumerState<AnonymityToggleModal> createState() =>
      _AnonymityToggleModalState();
}

class _AnonymityToggleModalState extends ConsumerState<AnonymityToggleModal> {
  late bool _isAnonymous;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isAnonymous = widget.currentAnonymousState;
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
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
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
                        localizations.translate('community-anonymous-mode'),
                        style: TextStyles.h6.copyWith(
                          color: theme.grey[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
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
                        // Profile Preview
                        Center(
                          child: Column(
                            children: [
                              _buildProfileAvatar(theme),
                              const SizedBox(height: 12),
                              Text(
                                _isAnonymous
                                    ? localizations
                                        .translate('community-anonymous')
                                    : widget.profile.displayName,
                                style: TextStyles.h6.copyWith(
                                  color: theme.grey[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isAnonymous
                                    ? localizations.translate(
                                        'community-anonymous-mode-enabled')
                                    : localizations.translate(
                                        'community-anonymous-mode-disabled'),
                                style: TextStyles.caption.copyWith(
                                  color: theme.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Anonymous Mode Toggle
                        WidgetsContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor:
                              _isAnonymous ? theme.primary[50] : theme.grey[50],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isAnonymous
                                        ? LucideIcons.shieldCheck
                                        : LucideIcons.shield,
                                    size: 26,
                                    color: _isAnonymous
                                        ? theme.primary[600]
                                        : theme.grey[600],
                                  ),
                                  horizontalSpace(Spacing.points12),
                                  Expanded(
                                    child: Text(
                                      localizations.translate(
                                          'community-post-anonymously-by-default'),
                                      style: TextStyles.body.copyWith(
                                        color: _isAnonymous
                                            ? theme.primary[900]
                                            : theme.grey[900],
                                        fontWeight: FontWeight.w600,
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
                              const SizedBox(height: 12),
                              Text(
                                localizations.translate(
                                    'community-anonymous-mode-description'),
                                style: TextStyles.caption.copyWith(
                                  color: _isAnonymous
                                      ? theme.primary[700]
                                      : theme.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Information box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primary[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.primary[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 20,
                                color: theme.primary[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localizations
                                      .translate('anonymous-mode-reassurance'),
                                  style: TextStyles.caption.copyWith(
                                    color: theme.primary[700],
                                    height: 1.3,
                                  ),
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

  Widget _buildProfileAvatar(dynamic theme) {
    final user = FirebaseAuth.instance.currentUser;
    final userImageUrl = user?.photoURL;

    if (_isAnonymous) {
      // When anonymous, show generic anonymous avatar (no real image)
      return CircleAvatar(
        radius: 40,
        backgroundColor: theme.primary[100],
        child: Icon(
          Icons.person_outline,
          size: 40,
          color: theme.primary[700],
        ),
      );
    } else {
      // When not anonymous, show the actual Firebase user's image or community profile
      return CircleAvatar(
        radius: 40,
        backgroundColor: theme.primary[100],
        backgroundImage: userImageUrl != null
            ? NetworkImage(userImageUrl)
            : (widget.profile.avatarUrl != null
                ? NetworkImage(widget.profile.avatarUrl!)
                : null),
        child: userImageUrl == null && widget.profile.avatarUrl == null
            ? Text(
                widget.profile.displayName.isNotEmpty
                    ? widget.profile.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.primary[700],
                ),
              )
            : null,
      );
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updateNotifier = ref.read(communityProfileUpdateProvider.notifier);

      await updateNotifier.updateProfile(
        displayName: widget.profile.displayName,
        gender: widget.profile.gender,
        isAnonymous: _isAnonymous,
        avatarUrl: widget.profile.avatarUrl,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onToggleComplete?.call(_isAnonymous);
        getSuccessSnackBar(
            context,
            _isAnonymous
                ? "community-anonymous-mode-enabled"
                : "community-anonymous-mode-disabled");
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
