import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_card.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/post_filter_segment.dart';
import 'package:reboot_app_3/features/account/presentation/widgets/feature_access_guard.dart';

class ForumHomeScreen extends ConsumerStatefulWidget {
  const ForumHomeScreen({super.key});

  @override
  ConsumerState<ForumHomeScreen> createState() => _ForumHomeScreenState();
}

class _ForumHomeScreenState extends ConsumerState<ForumHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: appBar(context, ref, 'forum', false, true),
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // Category Filter Chips

          // const CategoryChips(),

          // Post Filter Segment
          const PostFilterSegment(),

          // Posts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10, // Placeholder count
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCard(
                    postId: 'post_$index',
                    onTap: () {
                      context.goNamed(RouteNames.postDetail.name,
                          pathParameters: {'postId': 'post_$index'});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: CommunityPostGuard(
        onAccessGranted: () {
          context.goNamed(RouteNames.newPost.name);
        },
        child: FloatingActionButton(
          onPressed: null, // Handled by CommunityPostGuard
          backgroundColor: theme.primary[500],
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }
}
