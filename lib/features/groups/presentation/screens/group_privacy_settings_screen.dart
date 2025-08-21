import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_switch.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';

class GroupPrivacySettingsScreen extends ConsumerStatefulWidget {
  const GroupPrivacySettingsScreen({super.key});

  @override
  ConsumerState<GroupPrivacySettingsScreen> createState() =>
      _GroupPrivacySettingsScreenState();
}

class _GroupPrivacySettingsScreenState
    extends ConsumerState<GroupPrivacySettingsScreen> {
  bool _showIdentity = true;
  bool _makeMessagesPublic = true;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "privacy-settings", false, true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Show Identity
            WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: PlatformSwitch(
                value: _showIdentity,
                onChanged: (value) {
                  setState(() {
                    _showIdentity = value;
                  });
                },
                label: l10n.translate('show-identity'),
                subtitle: l10n.translate('show-identity-description'),
              ),
            ),

            verticalSpace(Spacing.points16),

            // Make Messages Public/Private
            WidgetsContainer(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: PlatformSwitch(
                value: _makeMessagesPublic,
                onChanged: (value) {
                  setState(() {
                    _makeMessagesPublic = value;
                  });
                },
                label: l10n.translate('make-messages-public'),
                subtitle: l10n.translate('make-messages-public-description'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
