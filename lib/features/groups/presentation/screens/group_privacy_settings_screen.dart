import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_radio.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import '../../providers/group_privacy_settings_provider.dart';

class GroupPrivacySettingsScreen extends ConsumerWidget {
  const GroupPrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final privacyState = ref.watch(groupPrivacySettingsProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "privacy-settings", false, true),
      body: privacyState.when(
        loading: () => const Center(child: Spinner()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: theme.error[500]),
              verticalSpace(Spacing.points16),
              Text(
                'Error loading privacy settings',
                style: TextStyles.h5,
                textAlign: TextAlign.center,
              ),
              verticalSpace(Spacing.points8),
              Text(
                error.toString(),
                style: TextStyles.body.copyWith(
                  color: theme.error[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (state) =>
            _buildPrivacySettings(context, ref, state, theme, l10n),
      ),
    );
  }

  Widget _buildPrivacySettings(
    BuildContext context,
    WidgetRef ref,
    GroupPrivacyState state,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error display
            if (state.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.error[100]!.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.error[500]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: theme.error[500], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getLocalizedError(state.error!, l10n),
                        style: TextStyles.footnote.copyWith(
                          color: theme.error[600],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => ref
                          .read(groupPrivacySettingsProvider.notifier)
                          .clearError(),
                    ),
                  ],
                ),
              ),
            ],

            // User Anonymity Settings
            _buildUserAnonymitySection(context, ref, state, theme, l10n),

            // Admin Group Settings (only show if user is admin)
            if (state.isUserAdmin && state.group != null) ...[
              verticalSpace(Spacing.points32),
              _buildAdminGroupSettingsSection(context, ref, state, theme, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnonymitySection(
    BuildContext context,
    WidgetRef ref,
    GroupPrivacyState state,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('user-privacy-settings'),
          style: TextStyles.h5.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          l10n.translate('user-privacy-description'),
          style: TextStyles.footnote.copyWith(
            color: theme.grey[700],
          ),
        ),
        verticalSpace(Spacing.points16),

        // Show Identity Toggle (inverted for anonymity)
        WidgetsContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: PlatformSwitch(
            value: !(state.userProfile?.isAnonymous ??
                true), // Invert for "Show Identity"
            onChanged: state.isLoading
                ? null
                : (value) {
                    ref
                        .read(groupPrivacySettingsProvider.notifier)
                        .updateUserAnonymity(
                            !value); // Invert back for anonymity
                  },
            label: l10n.translate('show-identity'),
            subtitle: l10n.translate('show-identity-description'),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminGroupSettingsSection(
    BuildContext context,
    WidgetRef ref,
    GroupPrivacyState state,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final group = state.group!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: theme.primary[500], size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.translate('admin-group-settings'),
              style: TextStyles.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primary[500],
              ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        Text(
          l10n.translate('admin-group-settings-description'),
          style: TextStyles.footnote.copyWith(
            color: theme.grey[700],
          ),
        ),
        verticalSpace(Spacing.points16),

        // Group Visibility Setting
        WidgetsContainer(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: PlatformSwitch(
            value: group.visibility == 'public',
            onChanged: state.isLoading
                ? null
                : (value) {
                    final newVisibility = value ? 'public' : 'private';
                    ref
                        .read(groupPrivacySettingsProvider.notifier)
                        .updateGroupVisibility(newVisibility);
                  },
            label: l10n.translate('make-group-public'),
            subtitle: l10n.translate('make-group-public-description'),
          ),
        ),

        verticalSpace(Spacing.points16),

        // Join Method Setting
        _buildJoinMethodSelector(context, ref, state, theme, l10n),
      ],
    );
  }

  Widget _buildJoinMethodSelector(
    BuildContext context,
    WidgetRef ref,
    GroupPrivacyState state,
    CustomThemeData theme,
    AppLocalizations l10n,
  ) {
    final group = state.group!;

    return WidgetsContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('group-join-method'),
            style: TextStyles.h6.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          verticalSpace(Spacing.points8),
          Text(
            l10n.translate('group-join-method-description'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[700],
            ),
          ),
          verticalSpace(Spacing.points16),

          // Join method radio group
          PlatformRadioGroup<String>(
            value: group.joinMethod,
            onChanged: state.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      ref
                          .read(groupPrivacySettingsProvider.notifier)
                          .updateGroupJoinMethod(value);
                    }
                  },
            options: [
              PlatformRadioOption<String>(
                value: 'any',
                title: l10n.translate('join-method-any'),
                subtitle: group.visibility == 'public'
                    ? l10n.translate('join-method-any-description')
                    : l10n.translate('join-method-any-requires-public'),
              ),
              // TODO: Re-enable admin invite functionality later
              // PlatformRadioOption<String>(
              //   value: 'admin_only',
              //   title: l10n.translate('join-method-admin-only'),
              //   subtitle: l10n.translate('join-method-admin-only-description'),
              // ),
              PlatformRadioOption<String>(
                value: 'code_only',
                title: l10n.translate('join-method-code-only'),
                subtitle: l10n.translate('join-method-code-only-description'),
              ),
            ],
            enabled: !state.isLoading,
            activeColor: theme.primary[600],
          ),

          // Show join code if code_only is selected
          if (group.joinMethod == 'code_only' && group.joinCode != null) ...[
            verticalSpace(Spacing.points12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary[100]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primary[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('current-join-code'),
                    style: TextStyles.footnoteSelected.copyWith(
                      color: theme.primary[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.joinCode!,
                          style: TextStyles.h5.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () =>
                            _copyJoinCode(group.joinCode!, context, l10n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary[200],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.primary[400]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                color: theme.primary[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.translate('copy-code'),
                                style: TextStyles.footnote.copyWith(
                                  color: theme.primary[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper method to localize error messages
  String _getLocalizedError(String error, AppLocalizations l10n) {
    // Extract the localization key from the exception message
    String errorKey;
    if (error.startsWith('Exception: ')) {
      errorKey = error.substring('Exception: '.length);
    } else {
      errorKey = error;
    }

    // If it starts with 'error-', it's a localization key
    if (errorKey.startsWith('error-')) {
      return l10n.translate(errorKey);
    }

    // Otherwise, return the original error message
    return error;
  }

  /// Copy join code to clipboard
  void _copyJoinCode(
      String joinCode, BuildContext context, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: joinCode));
    getSuccessSnackBar(context, 'join-code-copied');
  }
}
