import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import '../../providers/group_privacy_settings_provider.dart';

class GroupPrivacySettingsScreen extends ConsumerWidget {
  const GroupPrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final privacyState = ref.watch(groupPrivacySettingsProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor[50],
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
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              verticalSpace(Spacing.points8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                color: theme.error[100]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.error[500]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: theme.error[500], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        verticalSpace(Spacing.points8),
        Text(
          l10n.translate('user-privacy-description'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primary[500],
                  ),
            ),
          ],
        ),
        verticalSpace(Spacing.points8),
        Text(
          l10n.translate('admin-group-settings-description'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          verticalSpace(Spacing.points8),
          Text(
            l10n.translate('group-join-method-description'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.grey[700],
                ),
          ),
          verticalSpace(Spacing.points12),

          // Join method radio options
          _buildJoinMethodOption(
            context: context,
            ref: ref,
            state: state,
            theme: theme,
            l10n: l10n,
            value: 'any',
            title: l10n.translate('join-method-any'),
            subtitle: l10n.translate('join-method-any-description'),
            enabled:
                group.visibility == 'public', // Only enabled for public groups
          ),

          _buildJoinMethodOption(
            context: context,
            ref: ref,
            state: state,
            theme: theme,
            l10n: l10n,
            value: 'admin_only',
            title: l10n.translate('join-method-admin-only'),
            subtitle: l10n.translate('join-method-admin-only-description'),
            enabled: true,
          ),

          _buildJoinMethodOption(
            context: context,
            ref: ref,
            state: state,
            theme: theme,
            l10n: l10n,
            value: 'code_only',
            title: l10n.translate('join-method-code-only'),
            subtitle: l10n.translate('join-method-code-only-description'),
            enabled: true,
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: theme.primary[600],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.joinCode!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinMethodOption({
    required BuildContext context,
    required WidgetRef ref,
    required GroupPrivacyState state,
    required CustomThemeData theme,
    required AppLocalizations l10n,
    required String value,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    final isSelected = state.group!.joinMethod == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: (enabled && !state.isLoading && !isSelected)
            ? () {
                ref
                    .read(groupPrivacySettingsProvider.notifier)
                    .updateGroupJoinMethod(value);
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primary[100]!.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.primary[500]!
                  : (enabled
                      ? theme.grey[300]!
                      : theme.grey[300]!.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: state.group!.joinMethod,
                onChanged: (enabled && !state.isLoading)
                    ? (newValue) {
                        if (newValue != null) {
                          ref
                              .read(groupPrivacySettingsProvider.notifier)
                              .updateGroupJoinMethod(newValue);
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: enabled ? theme.grey[900] : theme.grey[600],
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? theme.grey[700]
                                : theme.grey[600]?.withOpacity(0.6),
                          ),
                    ),
                    if (!enabled && value == 'any') ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('join-method-any-requires-public'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.warn[600],
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
