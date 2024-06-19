import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/authentication/repositories/auth_repository.dart';

class LogInScreen extends ConsumerWidget {
  const LogInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final theme = CustomThemeInherited.of(context);
    return Container(
      color: theme.backgroundColor,
      height: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          children: [
            verticalSpace(Spacing.points80),
            Text(
              AppLocalizations.of(context).translate('login'),
              style: TextStyles.h2.copyWith(color: theme.primary[600]),
            ),
            verticalSpace(Spacing.points24),
            WidgetsContainer(
              backgroundColor: theme.primary[600],
              width: MediaQuery.of(context).size.width - (16 + 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('login'),
                    style: TextStyles.footnoteSelected
                        .copyWith(color: theme.grey[50]),
                  ),
                ],
              ),
              padding: EdgeInsets.only(top: 16, bottom: 16),
            )
          ],
        ),
      ),
    );
  }
}
