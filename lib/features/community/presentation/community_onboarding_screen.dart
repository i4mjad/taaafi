import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/avatar_picker.dart';

class CommunityOnboardingScreen extends ConsumerStatefulWidget {
  const CommunityOnboardingScreen({super.key});

  @override
  ConsumerState<CommunityOnboardingScreen> createState() =>
      _CommunityOnboardingScreenState();
}

class _CommunityOnboardingScreenState
    extends ConsumerState<CommunityOnboardingScreen> {
  final _displayNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  String? _selectedGender;
  bool _postAnonymouslyByDefault = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: appBar(context, ref, 'community-setup', false, true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              localizations.translate('welcome_to_community'),
              style: TextStyles.h4,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('complete_profile_setup'),
              style: TextStyles.body.copyWith(
                color: theme.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Avatar picker
            Text(
              localizations.translate('choose_avatar'),
              style: TextStyles.h6,
            ),
            const SizedBox(height: 16),
            const AvatarPicker(),

            const SizedBox(height: 32),

            // Display name
            Text(
              localizations.translate('community-display-name'),
              style: TextStyles.h6,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                hintText: localizations.translate('enter_display_name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Gender selection
            Text(
              localizations.translate('gender'),
              style: TextStyles.h6,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(localizations.translate('male')),
                    value: 'male',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text(localizations.translate('female')),
                    value: 'female',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Anonymous by default switch
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations
                        .translate('community-post-anonymously-by-default'),
                    style: TextStyles.body,
                  ),
                ),
                Switch(
                  value: _postAnonymouslyByDefault,
                  onChanged: (value) {
                    setState(() {
                      _postAnonymouslyByDefault = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Referral code (optional)
            Text(
              localizations.translate('referral_code_optional'),
              style: TextStyles.h6,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _referralCodeController,
              decoration: InputDecoration(
                hintText: localizations.translate('enter_referral_code'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Complete setup button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canComplete() ? _completeSetup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.translate('complete_setup'),
                  style: TextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canComplete() {
    return _displayNameController.text.trim().isNotEmpty &&
        _selectedGender != null;
  }

  Future<void> _completeSetup() async {
    // TODO: Implement community profile creation
    // For now, just navigate to the main community screen
    context.go('/community');
  }
}
