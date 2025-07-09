import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/account/data/user_profile_notifier.dart';
import 'package:reboot_app_3/features/authentication/providers/user_provider.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/features/account/presentation/update_user_profile_modal_sheet.dart';
import 'package:reboot_app_3/features/account/data/models/ban.dart';
import 'package:reboot_app_3/features/account/data/models/warning.dart';
import 'package:reboot_app_3/features/account/providers/clean_ban_warning_providers.dart';
import 'package:reboot_app_3/features/account/utils/ban_display_formatter.dart';
import 'package:reboot_app_3/features/account/presentation/warning_detail_modal.dart';
import 'package:reboot_app_3/features/account/presentation/ban_detail_modal.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final currentUser = ref.watch(userNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'user-profile', false, true),
      body: userProfileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            AppLocalizations.of(context).translate('error-loading-profile'),
            style: TextStyles.body.copyWith(color: theme.error[600]),
          ),
        ),
        data: (userProfile) {
          if (userProfile == null) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('no-profile-data'),
                style: TextStyles.body.copyWith(color: theme.grey[600]),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Details Section
                  _buildProfileDetailsCard(
                      context, theme, userProfile, currentUser, locale),

                  verticalSpace(Spacing.points24),

                  // Warnings Section - now with dynamic header
                  _buildWarningsCard(context, theme, ref),

                  verticalSpace(Spacing.points24),

                  // Bans Section - now with dynamic header
                  _buildBansCard(context, theme, ref),

                  verticalSpace(Spacing.points24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    CustomThemeData theme,
    String titleKey,
    IconData icon,
    Color iconColor, {
    VoidCallback? onRefresh,
    bool isRefreshing = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        horizontalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate(titleKey),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
        ),
        const Spacer(),
        if (onRefresh != null)
          GestureDetector(
            onTap: isRefreshing ? null : onRefresh,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.grey[200]!,
                  width: 0.5,
                ),
              ),
              child: isRefreshing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.primary[600],
                      ),
                    )
                  : Icon(
                      LucideIcons.refreshCw,
                      size: 14,
                      color: theme.grey[600],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileDetailsCard(
    BuildContext context,
    CustomThemeData theme,
    userProfile,
    currentUser,
    locale,
  ) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color.fromRGBO(0, 0, 0, 0.08),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
      child: Column(
        children: [
          // Header with Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('profile-details'),
                style: TextStyles.h6.copyWith(color: theme.grey[900]),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    useSafeArea: true,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => UpdateUserProfileModalSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.primary[200]!,
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.edit,
                    size: 16,
                    color: theme.primary[700],
                  ),
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Profile Image and Basic Info
          Row(
            children: [
              Builder(
                builder: (context) {
                  final user = currentUser.hasValue ? currentUser.value : null;
                  final hasProfileImage =
                      user?.photoURL != null && user!.photoURL!.isNotEmpty;

                  return CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.primary[50],
                    backgroundImage:
                        hasProfileImage ? NetworkImage(user.photoURL!) : null,
                    child: hasProfileImage
                        ? null
                        : Icon(
                            LucideIcons.user,
                            color: theme.primary[900],
                            size: 28,
                          ),
                  );
                },
              ),
              horizontalSpace(Spacing.points16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile.displayName,
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      userProfile.email,
                      style: TextStyles.footnote.copyWith(
                        color: theme.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Detailed Information
          _buildDetailRow(
            context,
            theme,
            'age',
            '${userProfile.age} ${AppLocalizations.of(context).translate('years')}',
            LucideIcons.calendar,
          ),

          verticalSpace(Spacing.points12),

          _buildDetailRow(
            context,
            theme,
            'member-since',
            getDisplayDate(
                userProfile.userFirstDate, locale?.languageCode ?? 'en'),
            LucideIcons.userPlus,
          ),

          verticalSpace(Spacing.points12),

          _buildDetailRow(
            context,
            theme,
            'account-status',
            AppLocalizations.of(context).translate('active'),
            LucideIcons.checkCircle,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    CustomThemeData theme,
    String labelKey,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.grey[600],
          size: 16,
        ),
        horizontalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate(labelKey),
          style: TextStyles.small.copyWith(color: theme.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyles.small.copyWith(color: theme.grey[900]),
        ),
      ],
    );
  }

  Widget _buildWarningsCard(
      BuildContext context, CustomThemeData theme, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        final warningsAsync = ref.watch(currentUserWarningsProvider);
        final isRefreshing = warningsAsync.isRefreshing;

        return warningsAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                theme,
                'warnings',
                LucideIcons.alertTriangle,
                theme.primary[600]!,
                onRefresh: () {
                  HapticFeedback.lightImpact();
                  ref.invalidate(currentUserWarningsProvider);
                },
                isRefreshing: isRefreshing,
              ),
              verticalSpace(Spacing.points12),
              WidgetsContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.warn[300]!, width: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                theme,
                'warnings',
                LucideIcons.alertTriangle,
                theme.primary[600]!,
                onRefresh: () {
                  HapticFeedback.lightImpact();
                  ref.invalidate(currentUserWarningsProvider);
                },
                isRefreshing: isRefreshing,
              ),
              verticalSpace(Spacing.points12),
              WidgetsContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.error[300]!, width: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: Text('Error loading warnings'),
              ),
            ],
          ),
          data: (warnings) {
            final hasWarnings = warnings.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic section header based on warnings state
                _buildSectionHeader(
                  context,
                  theme,
                  hasWarnings ? 'active-warnings' : 'no-warnings',
                  hasWarnings
                      ? LucideIcons.alertTriangle
                      : LucideIcons.checkCircle,
                  hasWarnings ? theme.warn[600]! : theme.success[600]!,
                  onRefresh: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(currentUserWarningsProvider);
                  },
                  isRefreshing: isRefreshing,
                ),
                verticalSpace(Spacing.points12),

                if (hasWarnings) ...[
                  // Display warnings without container wrapper
                  ...warnings.take(3).map((warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.7,
                                minChildSize: 0.5,
                                maxChildSize: 0.95,
                                builder: (context, scrollController) =>
                                    WarningDetailModal(
                                  warning: warning,
                                ),
                              ),
                            );
                          },
                          child:
                              _buildWarningItem(context, theme, warning, ref),
                        ),
                      )),
                  if (warnings.length > 3) ...[
                    Text(
                      '+ ${warnings.length - 3} ${AppLocalizations.of(context).translate('more-warnings')}',
                      style: TextStyles.small.copyWith(
                        color: theme.warn[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ] else ...[
                  // No warnings - show description
                  Text(
                    AppLocalizations.of(context)
                        .translate('warnings-description'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWarningItem(BuildContext context, CustomThemeData theme,
      Warning warning, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.warn[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.warn[200]!, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSeverityColor(warning.severity, theme),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getSeverityText(warning.severity, context),
                  style: TextStyles.small.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                getDisplayDate(warning.issuedAt, locale?.languageCode ?? 'en'),
                style: TextStyles.small.copyWith(
                  color: theme.grey[600],
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points4),
          Text(
            warning.reason,
            style: TextStyles.footnote.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (warning.description != null) ...[
            verticalSpace(Spacing.points4),
            Text(
              warning.description!,
              style: TextStyles.small.copyWith(
                color: theme.grey[700],
              ),
            ),
          ],
          // Add subtle tap indicator
          verticalSpace(Spacing.points8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.of(context).translate('tap-for-details'),
                style: TextStyles.small.copyWith(
                  color: theme.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              horizontalSpace(Spacing.points4),
              Icon(
                locale?.languageCode == 'en'
                    ? LucideIcons.chevronRight
                    : LucideIcons.chevronLeft,
                size: 14,
                color: theme.grey[500],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(WarningSeverity severity, CustomThemeData theme) {
    switch (severity) {
      case WarningSeverity.low:
        return theme.primary[500]!;
      case WarningSeverity.medium:
        return theme.warn[500]!;
      case WarningSeverity.high:
        return theme.error[500]!;
      case WarningSeverity.critical:
        return theme.error[700]!;
    }
  }

  String _getSeverityText(WarningSeverity severity, BuildContext context) {
    switch (severity) {
      case WarningSeverity.low:
        return AppLocalizations.of(context).translate('low');
      case WarningSeverity.medium:
        return AppLocalizations.of(context).translate('medium');
      case WarningSeverity.high:
        return AppLocalizations.of(context).translate('high');
      case WarningSeverity.critical:
        return AppLocalizations.of(context).translate('critical');
    }
  }

  Widget _buildBansCard(
      BuildContext context, CustomThemeData theme, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        final bansAsync = ref.watch(currentUserBansProvider);
        final locale = ref.watch(localeNotifierProvider);
        final isRefreshing = bansAsync.isRefreshing;

        return bansAsync.when(
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                theme,
                'bans',
                LucideIcons.shield,
                theme.primary[600]!,
                onRefresh: () {
                  HapticFeedback.lightImpact();
                  ref.invalidate(currentUserBansProvider);
                },
                isRefreshing: isRefreshing,
              ),
              verticalSpace(Spacing.points12),
              WidgetsContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                theme,
                'bans',
                LucideIcons.shield,
                theme.primary[600]!,
                onRefresh: () {
                  HapticFeedback.lightImpact();
                  ref.invalidate(currentUserBansProvider);
                },
                isRefreshing: isRefreshing,
              ),
              verticalSpace(Spacing.points12),
              WidgetsContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.backgroundColor,
                borderSide: BorderSide(color: theme.error[300]!, width: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  AppLocalizations.of(context).translate('error-loading-bans'),
                  style: TextStyles.body.copyWith(color: theme.error[600]),
                ),
              ),
            ],
          ),
          data: (bans) {
            final hasBans = bans.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic section header based on bans state
                _buildSectionHeader(
                  context,
                  theme,
                  hasBans ? 'account-restricted' : 'account-in-good-standing',
                  hasBans ? LucideIcons.shieldOff : LucideIcons.shield,
                  hasBans ? theme.error[600]! : theme.success[600]!,
                  onRefresh: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(currentUserBansProvider);
                  },
                  isRefreshing: isRefreshing,
                ),
                verticalSpace(Spacing.points12),

                if (hasBans) ...[
                  // Display bans without container wrapper
                  ...bans.take(2).map((ban) => GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.7,
                              minChildSize: 0.5,
                              maxChildSize: 0.95,
                              builder: (context, scrollController) =>
                                  BanDetailModal(
                                ban: ban,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.error[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: theme.error[200]!, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ban.scope == BanScope.app_wide
                                          ? theme.error[600]
                                          : theme.warn[600],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ban.scope == BanScope.app_wide
                                          ? AppLocalizations.of(context)
                                              .translate('app-wide')
                                          : AppLocalizations.of(context)
                                              .translate('feature-specific'),
                                      style: TextStyles.small.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    BanDisplayFormatter.formatBanDuration(
                                        ban, context),
                                    style: TextStyles.small.copyWith(
                                      color: theme.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              verticalSpace(Spacing.points4),
                              Text(
                                ban.reason,
                                style: TextStyles.footnote.copyWith(
                                  color: theme.grey[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (ban.description != null) ...[
                                verticalSpace(Spacing.points4),
                                Text(
                                  ban.description!,
                                  style: TextStyles.small.copyWith(
                                    color: theme.grey[700],
                                  ),
                                ),
                              ],
                              // Add subtle tap indicator
                              verticalSpace(Spacing.points8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('tap-for-details'),
                                    style: TextStyles.small.copyWith(
                                      color: theme.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  horizontalSpace(Spacing.points4),
                                  Icon(
                                    locale?.languageCode == 'en'
                                        ? LucideIcons.chevronRight
                                        : LucideIcons.chevronLeft,
                                    size: 14,
                                    color: theme.grey[500],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (bans.length > 2) ...[
                    Text(
                      '+ ${bans.length - 2} ${AppLocalizations.of(context).translate('more-restrictions')}',
                      style: TextStyles.small.copyWith(
                        color: theme.error[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ] else ...[
                  // No bans - show description
                  Text(
                    AppLocalizations.of(context).translate('bans-description'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
