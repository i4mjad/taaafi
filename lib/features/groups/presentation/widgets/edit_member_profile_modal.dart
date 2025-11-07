import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/domain/entities/community_profile_entity.dart';

/// Edit member profile modal
/// Sprint 4 - Feature 4.1: Enhanced Member Profiles
class EditMemberProfileModal extends ConsumerStatefulWidget {
  final CommunityProfileEntity profile;
  final Function(String bio, List<String> interests) onSave;

  const EditMemberProfileModal({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  ConsumerState<EditMemberProfileModal> createState() =>
      _EditMemberProfileModalState();
}

class _EditMemberProfileModalState
    extends ConsumerState<EditMemberProfileModal> {
  late TextEditingController _bioController;
  late Set<String> _selectedInterests;
  bool _isSaving = false;

  // Available interest tags
  static const List<String> availableInterests = [
    'fitness',
    'wellness',
    'faith',
    'study',
    'support',
    'goals',
    'habits',
    'mindfulness',
    'recovery',
    'motivation',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.profile.groupBio ?? '');
    _selectedInterests = Set<String>.from(widget.profile.interests);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final bio = _bioController.text.trim();

    // Validate bio length
    if (bio.length > 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bio exceeds 200 character limit')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(bio, _selectedInterests.toList());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final charCount = _bioController.text.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  l10n.translate('edit-group-profile'),
                  style: TextStyles.h5.copyWith(
                    color: theme.grey[900],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: theme.grey[700],
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.grey[200]),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio section
                  Text(
                    l10n.translate('group-bio'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      hintText: l10n.translate('bio-placeholder'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.tint[600]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                    maxLength: 200,
                    onChanged: (_) => setState(() {}),
                    style: TextStyles.body.copyWith(color: theme.grey[900]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$charCount/200',
                        style: TextStyles.caption.copyWith(
                          color: charCount > 200
                              ? theme.error[600]
                              : theme.grey[500],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Interests section
                  Text(
                    l10n.translate('interests'),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('select-interests'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Interest chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return GestureDetector(
                        onTap: () => _toggleInterest(interest),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.tint[600]
                                : theme.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? theme.tint[600]!
                                  : theme.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.translate('interest-$interest'),
                            style: TextStyles.footnote.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : theme.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.tint[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: theme.grey[300],
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.backgroundColor,
                            ),
                          ),
                        )
                      : Text(
                          l10n.translate('save-profile'),
                          style: TextStyles.h6,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show edit profile modal
void showEditProfileModal({
  required BuildContext context,
  required CommunityProfileEntity profile,
  required Function(String bio, List<String> interests) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => EditMemberProfileModal(
      profile: profile,
      onSave: onSave,
    ),
  );
}

