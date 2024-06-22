import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class OnBoardingScreen extends ConsumerWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        null,
        true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                            color: theme.primary[50],
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: theme.primary[100]!, width: 1.5)),
                        child: Icon(
                          LucideIcons.heart,
                          size: 42,
                        ),
                      ),
                      verticalSpace(Spacing.points28),
                      Text(
                        AppLocalizations.of(context)
                            .translate('taaafi-platform'),
                        style: TextStyles.h2.copyWith(
                          color: theme.primary[600],
                        ),
                      ),
                      verticalSpace(Spacing.points28),
                      OnboardingSection(
                        icon: LucideIcons.users,
                        title: 'تابع تعافيك',
                        description:
                            'تعرف على التجارب المختلفة وشارك تجربتك مع مجموعة من المتعافين لتبادل الخبرات واكتشاف التحديات في رحلة التعافي',
                      ),
                      verticalSpace(Spacing.points32),
                      OnboardingSection(
                          icon: LucideIcons.lock,
                          title: 'الخزنة',
                          description:
                              'يمكنك مشاركة رحلة تعافيك والتحديات التي تواجهها بسرية تامة بدون إظهار هويتك'),
                      verticalSpace(Spacing.points32),
                      OnboardingSection(
                        icon: LucideIcons.trophy,
                        title: 'الزمالة',
                        description:
                            'تحدَ زملائك في رحلة التعافي لتحقيق مراحل متقدمة في رحلة التعافي',
                      ),
                      verticalSpace(Spacing.points32),
                      OnboardingSection(
                        icon: LucideIcons.fileStack,
                        title: 'تابع تحديثات زملائك',
                        description:
                            'تابع تحديثات من قبل زملائك في الزمالة وساعدهم واستفد من خبراتهم في التعافي',
                      ),
                      verticalSpace(Spacing.points24),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(RouteNames.login.name),
                child: WidgetsContainer(
                  backgroundColor: theme.primary[600],
                  width: MediaQuery.of(context).size.width - 64,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate('login'),
                      style: TextStyles.footnoteSelected.copyWith(
                        color: theme.grey[50],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingSection extends ConsumerWidget {
  const OnboardingSection(
      {super.key,
      required this.icon,
      required this.title,
      required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Container(
      padding: EdgeInsets.only(right: 32, left: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.primary[600],
            weight: 100,
          ),
          horizontalSpace(Spacing.points16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.h5.copyWith(
                    color: theme.primary[600],
                  ),
                ),
                verticalSpace(Spacing.points8),
                // Second text
                Text(
                  description,
                  style: TextStyles.footnote.copyWith(
                    color: theme.grey[700],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
