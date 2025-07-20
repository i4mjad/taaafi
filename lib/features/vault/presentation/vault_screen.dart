import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activities_screen.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/current_streaks_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calendar_section.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/shorebird_update_widget.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_layout_provider.dart';
import 'package:reboot_app_3/features/vault/presentation/widgets/vault_layout_settings_sheet.dart';
import 'package:reboot_app_3/features/authentication/providers/account_status_provider.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/core/shared_widgets/complete_registration_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_details_banner.dart';
import 'package:reboot_app_3/core/shared_widgets/confirm_email_banner.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final accountStatus = ref.watch(accountStatusProvider);
    final showMainContent = accountStatus == AccountStatus.ok;
    final userDocAsync = ref.watch(userDocumentsNotifierProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'vault',
        false,
        false,
        actions: showMainContent
            ? [
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const VaultLayoutSettingsSheet(),
                    );
                  },
                  icon: Icon(LucideIcons.settings),
                )
              ]
            : null,
      ),
      body: userDocAsync.when(
        loading: () => const Center(child: Spinner()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (_) {
          switch (accountStatus) {
            case AccountStatus.loading:
              return Center(child: Spinner());
            case AccountStatus.needCompleteRegistration:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CompleteRegistrationBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needConfirmDetails:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmDetailsBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.needEmailVerification:
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ConfirmEmailBanner(isFullScreen: true),
                ),
              );
            case AccountStatus.ok:
              return _buildMainContent(context, theme);
          }
        },
      ),
      floatingActionButton: showMainContent
          ? FloatingActionButton.extended(
              backgroundColor: theme.primary[600],
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return FollowUpSheet(DateTime.now());
                  },
                );
              },
              label: Text(
                AppLocalizations.of(context).translate("daily-follow-up"),
                style: TextStyles.caption.copyWith(color: theme.grey[50]),
              ),
              icon: Icon(LucideIcons.pencil, color: theme.grey[50]),
            )
          : null,
    );
  }

  Widget _buildMainContent(BuildContext context, CustomThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final vaultLayoutSettings = ref.watch(vaultLayoutProvider);

        final orderedHomeElements =
            vaultLayoutSettings.getOrderedVisibleHomeElements();
        final orderedCards = vaultLayoutSettings.getOrderedVisibleCards();

        final homeElementsMap = <String, Widget>{
          'todayTasks': _buildTodayTasksSection(),
          'currentStreaks': const CurrentStreaksSection(),
          'statistics': const StatisticsSection(),
          'calendar': const CalendarSection(),
        };

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shorebird update widget
              const ShorebirdUpdateWidget(),
              verticalSpace(Spacing.points16),

              // Horizontal Scrollable Cards
              _buildHorizontalCards(context, theme, orderedCards),
              verticalSpace(Spacing.points16),

              // Render ordered home elements
              ...orderedHomeElements
                  .expand((element) => [
                        homeElementsMap[element] ?? SizedBox.shrink(),
                        verticalSpace(Spacing.points16),
                      ])
                  .toList()
                ..removeLast(), // Remove the last spacing

              verticalSpace(Spacing.points32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TodayTasksWidget(),
    );
  }

  Widget _buildHorizontalCards(
      BuildContext context, CustomThemeData theme, List<String> orderedCards) {
    final cardData = {
      'activities': {
        'icon': LucideIcons.clipboardCheck,
        'color': theme.primary[500]!,
        'backgroundColor': theme.primary[50]!,
        'route': () => context.goNamed(RouteNames.activities.name),
      },
      'library': {
        'icon': LucideIcons.lamp,
        'color': theme.secondary[500]!,
        'backgroundColor': theme.secondary[50]!,
        'route': () => context.goNamed(RouteNames.library.name),
      },
      'diaries': {
        'icon': LucideIcons.pencil,
        'color': theme.tint[500]!,
        'backgroundColor': theme.tint[50]!,
        'route': () => context.goNamed(RouteNames.diaries.name),
      },
      'notifications': {
        'icon': LucideIcons.bell,
        'color': theme.warn[500]!,
        'backgroundColor': theme.warn[50]!,
        'route': () => context.goNamed(RouteNames.notifications.name),
      },
      'settings': {
        'icon': LucideIcons.settings,
        'color': theme.grey[500]!,
        'backgroundColor': theme.grey[50]!,
        'route': () => context.goNamed(RouteNames.vaultSettings.name),
      },
    };

    return SizedBox(
      height: 80,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        children: orderedCards
            .expand((card) => [
                  _buildHorizontalCard(
                    context,
                    theme,
                    cardData[card]!['icon'] as IconData,
                    card,
                    cardData[card]!['color'] as Color,
                    cardData[card]!['backgroundColor'] as Color,
                    cardData[card]!['route'] as VoidCallback,
                  ),
                  if (card != orderedCards.last)
                    horizontalSpace(Spacing.points8),
                ])
            .toList(),
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    CustomThemeData theme,
    IconData icon,
    String textKey,
    Color iconColor,
    Color backgroundColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: WidgetsContainer(
        width: 70,
        height: 70,
        padding: EdgeInsets.all(8),
        backgroundColor: backgroundColor,
        borderSide:
            BorderSide(color: iconColor.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            verticalSpace(Spacing.points4),
            Text(
              AppLocalizations.of(context).translate(textKey),
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
