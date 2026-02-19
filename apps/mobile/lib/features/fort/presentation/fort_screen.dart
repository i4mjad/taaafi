import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/fort/data/notifiers/fort_state_notifier.dart';
import 'package:reboot_app_3/features/fort/data/notifiers/usage_notifier.dart';
import 'package:reboot_app_3/features/fort/presentation/widgets/fort_hero_section.dart';
import 'package:reboot_app_3/features/fort/presentation/widgets/fort_permission_card.dart';
import 'package:reboot_app_3/features/fort/presentation/widgets/usage_summary_card.dart';

class FortScreen extends ConsumerWidget {
  const FortScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context);
    final fortAsync = ref.watch(fortStateNotifierProvider);
    final permissionAsync = ref.watch(usagePermissionProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(usageNotifierProvider);
            ref.invalidate(fortStateNotifierProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    t.translate('fort'),
                    style: TextStyles.screenHeadding.copyWith(
                      color: isDark ? theme.grey[100] : theme.grey[900],
                    ),
                  ),
                ),
              ),

              // Fort hero visualization
              SliverToBoxAdapter(
                child: fortAsync.when(
                  data: (fortState) => FortHeroSection(fortState: fortState),
                  loading: () => const FortHeroSection.loading(),
                  error: (_, __) => const FortHeroSection.loading(),
                ),
              ),

              SliverToBoxAdapter(child: verticalSpace(Spacing.points16)),

              // Usage permission check or usage data
              SliverToBoxAdapter(
                child: permissionAsync.when(
                  data: (hasPermission) {
                    if (!hasPermission) {
                      return const FortPermissionCard();
                    }
                    return const _UsageSection();
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const FortPermissionCard(),
                ),
              ),

              // Bottom padding
              SliverToBoxAdapter(child: verticalSpace(Spacing.points80)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageSection extends ConsumerWidget {
  const _UsageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(usageNotifierProvider);

    return usageAsync.when(
      data: (summary) => UsageSummaryCard(summary: summary),
      loading: () => const UsageSummaryCard.loading(),
      error: (_, __) => const UsageSummaryCard.loading(),
    );
  }
}
