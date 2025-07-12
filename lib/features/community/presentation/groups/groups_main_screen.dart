import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/community_section_card.dart';

class GroupsMainScreen extends ConsumerStatefulWidget {
  const GroupsMainScreen({super.key});

  @override
  ConsumerState<GroupsMainScreen> createState() => _GroupsMainScreenState();
}

class _GroupsMainScreenState extends ConsumerState<GroupsMainScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: appBar(context, ref, 'groups', false, false),
      backgroundColor: theme.backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Page Header
          Text(
            localizations.translate('groups'),
            style: TextStyles.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with others on the same journey',
            style: TextStyles.body.copyWith(
              color: theme.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Groups List
          CommunitySectionCard(
            icon: LucideIcons.users,
            title: localizations.translate('community-support'),
            description: 'Join support groups with others on the same journey',
            memberCount: '1.2k members',
            onTap: () {
              context.push('/groups/list');
            },
          ),
          const SizedBox(height: 16),
          CommunitySectionCard(
            icon: LucideIcons.brain,
            title: localizations.translate('community-discussions'),
            description: 'Open discussions about recovery and wellness',
            memberCount: '856 members',
            onTap: () {
              context.push('/groups/list');
            },
          ),
          const SizedBox(height: 16),
          CommunitySectionCard(
            icon: LucideIcons.lightbulb,
            title: localizations.translate('community-tips'),
            description: 'Share and discover helpful tips and strategies',
            memberCount: '2.1k members',
            onTap: () {
              context.push('/groups/list');
            },
          ),
          const SizedBox(height: 16),
          CommunitySectionCard(
            icon: LucideIcons.heart,
            title: 'Recovery Partners',
            description: 'Find accountability partners for your journey',
            memberCount: '423 members',
            onTap: () {
              context.push('/groups/list');
            },
          ),
          const SizedBox(height: 16),
          CommunitySectionCard(
            icon: LucideIcons.bookOpen,
            title: 'Study Groups',
            description: 'Join groups focused on learning and growth',
            memberCount: '267 members',
            onTap: () {
              context.push('/groups/list');
            },
          ),
        ],
      ),
    );
  }
}
