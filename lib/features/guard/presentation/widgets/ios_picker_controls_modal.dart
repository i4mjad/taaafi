import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/ios_focus_providers.dart';
import '../../data/guard_usage_repository.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theming/text_styles.dart';
import '../../../../core/theming/app-themes.dart';
import '../../../../core/shared_widgets/snackbar.dart';

class IosPickerControlsModal extends ConsumerWidget {
  const IosPickerControlsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final auth = ref.watch(iosAuthStatusProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              localizations.translate('focus_controls'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          auth.maybeWhen(
            data: (ok) => Column(
              children: [
                // Select Apps and Sites Option
                _buildOption(
                  context,
                  theme,
                  localizations,
                  icon: Icons.playlist_add_check,
                  title: localizations.translate('select_apps_and_sites'),
                  subtitle: localizations.translate('choose_apps_to_monitor'),
                  isEnabled: ok,
                  onTap: ok
                      ? () async {
                          Navigator.of(context).pop();
                          await iosPresentPicker();
                        }
                      : null,
                ),

                const SizedBox(height: 8),

                // Start Monitoring Option
                _buildOption(
                  context,
                  theme,
                  localizations,
                  icon: LucideIcons.play,
                  title: localizations.translate('start_monitoring'),
                  subtitle: localizations.translate('begin_usage_tracking'),
                  isEnabled: ok,
                  onTap: ok
                      ? () async {
                          Navigator.of(context).pop();
                          await iosStartMonitoring();
                          getSuccessSnackBar(
                              context, "hourly_monitoring_started");
                        }
                      : null,
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    dynamic theme,
    AppLocalizations localizations, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isEnabled ? theme.grey[50] : theme.grey[25],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled ? theme.primary[100] : theme.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isEnabled ? theme.primary[600] : theme.grey[400],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? theme.grey[900] : theme.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyles.caption.copyWith(
                      color: isEnabled ? theme.grey[600] : theme.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (!isEnabled)
              Icon(
                LucideIcons.lock,
                size: 16,
                color: theme.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
