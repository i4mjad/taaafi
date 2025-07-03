import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

                  // Warnings Section
                  _buildSectionHeader(
                    context,
                    theme,
                    'warnings',
                    LucideIcons.alertTriangle,
                  ),
                  verticalSpace(Spacing.points12),
                  _buildWarningsCard(context, theme),

                  verticalSpace(Spacing.points24),

                  // Bans Section
                  _buildSectionHeader(
                    context,
                    theme,
                    'bans',
                    LucideIcons.shield,
                  ),
                  verticalSpace(Spacing.points12),
                  _buildBansCard(context, theme),

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
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.primary[600],
          size: 20,
        ),
        horizontalSpace(Spacing.points8),
        Text(
          AppLocalizations.of(context).translate(titleKey),
          style: TextStyles.h6.copyWith(color: theme.grey[900]),
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

  Widget _buildWarningsCard(BuildContext context, CustomThemeData theme) {
    return WidgetsContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: theme.backgroundColor,
      borderSide: BorderSide(color: theme.warn[300]!, width: 0.5),
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
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: theme.warn[600],
                size: 20,
              ),
              horizontalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context).translate('no-warnings'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[900],
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate('warnings-description'),
            style: TextStyles.footnote.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBansCard(BuildContext context, CustomThemeData theme) {
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
          Row(
            children: [
              Icon(
                LucideIcons.shield,
                color: theme.success[600],
                size: 20,
              ),
              horizontalSpace(Spacing.points8),
              Text(
                AppLocalizations.of(context)
                    .translate('account-in-good-standing'),
                style: TextStyles.body.copyWith(color: theme.grey[900]),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Text(
            AppLocalizations.of(context).translate('bans-description'),
            style: TextStyles.caption.copyWith(
              color: theme.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
