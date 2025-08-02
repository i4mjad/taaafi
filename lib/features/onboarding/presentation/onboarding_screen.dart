import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class OnBoardingScreen extends ConsumerStatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  ConsumerState<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends ConsumerState<OnBoardingScreen> {
  int currentStep = 0;

  void _goToSignIn() {
    HapticFeedback.lightImpact();
    ref.read(analyticsFacadeProvider).trackOnboardingStart();
    context.goNamed(RouteNames.login.name);
  }

  String _getStepTitle(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return AppLocalizations.of(context).translate('vault-short-title');
      case 1:
        return AppLocalizations.of(context).translate('exercises-short-title');
      case 2:
        return AppLocalizations.of(context).translate('lists-short-title');
      case 3:
        return AppLocalizations.of(context).translate('reminders-short-title');
      default:
        return '';
    }
  }

  IconData _getStepIcon(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return LucideIcons.lock;
      case 1:
        return LucideIcons.dumbbell;
      case 2:
        return LucideIcons.listChecks;
      case 3:
        return LucideIcons.bell;
      default:
        return LucideIcons.circle;
    }
  }

  String _getStepFullTitle(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return AppLocalizations.of(context).translate('vault-title');
      case 1:
        return AppLocalizations.of(context).translate('exercises-title');
      case 2:
        return AppLocalizations.of(context).translate('lists-title');
      case 3:
        return AppLocalizations.of(context).translate('reminders-title');
      default:
        return '';
    }
  }

  String _getStepDescription(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return AppLocalizations.of(context).translate('vault-description');
      case 1:
        return AppLocalizations.of(context).translate('exercises-description');
      case 2:
        return AppLocalizations.of(context).translate('lists-description');
      case 3:
        return AppLocalizations.of(context).translate('reminders-description');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            const SizedBox(width: 16), // 16px from edge
            Image.asset(
              'asset/illustrations/app-logo.png',
              height: 42,
              width: 42,
            ),
            const SizedBox(width: 8), // 16px between icon and text
            Text(
              AppLocalizations.of(context).translate('taaafi-platform'),
              style: TextStyles.screenHeadding.copyWith(
                color: theme.primary[600],
              ),
            ),
          ],
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0, // Remove default spacing since we're controlling it
        actions: [
          GestureDetector(
            onTap: () {
              ref.read(localeNotifierProvider.notifier).toggleLocale();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 16),
              child: Icon(
                LucideIcons.languages,
                color: theme.primary[600],
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content container with figma squircle - now full screen
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12.0),
                decoration: ShapeDecoration(
                  color: theme.grey[50],
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 24,
                      cornerSmoothing: 1,
                    ),
                    side: BorderSide(
                      color: theme.grey[600]!,
                      width: 0.25,
                    ),
                  ),
                  shadows: Shadows.mainShadows,
                ),
                child: Column(
                  children: [
                    // Horizontal stepper indicator only
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        textDirection:
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                        children: List.generate(4, (index) {
                          // Always use normal order, Row textDirection handles RTL
                          final stepIndex = index;
                          final isActive = currentStep >= stepIndex;
                          final isCompleted = currentStep > stepIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                currentStep = stepIndex;
                              });
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? theme.primary[600]
                                        : isActive
                                            ? theme.primary[600]
                                            : theme.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${stepIndex + 1}',
                                      style: TextStyles.small.copyWith(
                                        color: isActive
                                            ? theme.grey[50]
                                            : theme.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                verticalSpace(Spacing.points8),
                                Text(
                                  _getStepTitle(stepIndex),
                                  style: TextStyles.small.copyWith(
                                    color: isActive
                                        ? theme.primary[600]
                                        : theme.grey[600],
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    Divider(color: theme.primary[200], thickness: 1),

                    // Step content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _getStepIcon(currentStep),
                              color: theme.primary[600],
                              size: 64,
                            ),
                            verticalSpace(Spacing.points20),
                            Text(
                              _getStepFullTitle(currentStep),
                              style: TextStyles.h4.copyWith(
                                color: theme.primary[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            verticalSpace(Spacing.points16),
                            Text(
                              _getStepDescription(currentStep),
                              style: TextStyles.body.copyWith(
                                color: theme.grey[700],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            Spacer(),

                            // Step navigation buttons
                            Row(
                              children: [
                                if (currentStep > 0) ...[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          currentStep--;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: ShapeDecoration(
                                          color: Colors.transparent,
                                          shape: SmoothRectangleBorder(
                                            borderRadius: SmoothBorderRadius(
                                              cornerRadius: 12,
                                              cornerSmoothing: 1,
                                            ),
                                            side: BorderSide(
                                              color: theme.primary[600]!,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            AppLocalizations.of(context)
                                                .translate('back'),
                                            style: TextStyles.small.copyWith(
                                              color: theme.primary[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  horizontalSpace(Spacing.points12),
                                ],
                                Expanded(
                                  child: GestureDetector(
                                    onTap: currentStep < 3
                                        ? () {
                                            setState(() {
                                              currentStep++;
                                            });
                                          }
                                        : _goToSignIn,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: ShapeDecoration(
                                        color: theme.primary[600],
                                        shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius(
                                            cornerRadius: 12,
                                            cornerSmoothing: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          currentStep < 3
                                              ? AppLocalizations.of(context)
                                                  .translate('next')
                                              : AppLocalizations.of(context)
                                                  .translate('login'),
                                          style: TextStyles.small.copyWith(
                                            color: theme.grey[50],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // // Always visible sign in button
            // Padding(
            //   padding: const EdgeInsets.all(12.0),
            //   child: GestureDetector(
            //     onTap: _goToSignIn,
            //     child: Container(
            //       width: MediaQuery.of(context).size.width - 24,
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //       decoration: ShapeDecoration(
            //         color: theme.primary[600],
            //         shape: SmoothRectangleBorder(
            //           borderRadius: SmoothBorderRadius(
            //             cornerRadius: 16,
            //             cornerSmoothing: 1,
            //           ),
            //         ),
            //         shadows: [
            //           BoxShadow(
            //             color: theme.primary[400]!.withValues(alpha: 0.6),
            //             blurRadius: 12,
            //             offset: const Offset(0, 4),
            //           ),
            //         ],
            //       ),
            //       child: Center(
            //         child: Text(
            //           AppLocalizations.of(context).translate('login'),
            //           style: TextStyles.footnoteSelected.copyWith(
            //             color: theme.grey[50],
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
