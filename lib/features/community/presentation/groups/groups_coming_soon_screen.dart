import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class GroupsComingSoonScreen extends ConsumerStatefulWidget {
  const GroupsComingSoonScreen({super.key});

  @override
  ConsumerState<GroupsComingSoonScreen> createState() =>
      _GroupsComingSoonScreenState();
}

class _GroupsComingSoonScreenState
    extends ConsumerState<GroupsComingSoonScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: appBar(context, ref, 'fellowship', false, false),
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bell Icon
              Icon(
                LucideIcons.bell,
                size: 80,
                color: theme.grey[800],
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                localizations.translate('groups_coming_soon_title'),
                style: TextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                localizations.translate('groups_coming_soon_description'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Features List
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(
                      icon: LucideIcons.users,
                      title: localizations
                          .translate('groups_feature_support_groups'),
                      description: localizations
                          .translate('groups_feature_support_groups_desc'),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: LucideIcons.messageCircle,
                      title:
                          localizations.translate('groups_feature_group_chat'),
                      description: localizations
                          .translate('groups_feature_group_chat_desc'),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: LucideIcons.target,
                      title: localizations
                          .translate('groups_feature_group_challenges'),
                      description: localizations
                          .translate('groups_feature_group_challenges_desc'),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: LucideIcons.calendar,
                      title: localizations
                          .translate('groups_feature_group_events'),
                      description: localizations
                          .translate('groups_feature_group_events_desc'),
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Footer note
              Text(
                localizations.translate('groups_working_hard_message'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required dynamic theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primary[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.primary[600],
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
                  color: theme.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyles.caption.copyWith(
                  color: theme.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
