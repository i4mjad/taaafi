import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

//TODO: to be updated after the migeration from old account screen
//! RENAME THIS
class UpdatedAccountScreen extends ConsumerWidget {
  const UpdatedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = CustomThemeInherited.of(context);
    return Scaffold(
      appBar: appBar(context, ref, 'account'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              padding: EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: theme.primary[50],
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 15,
                    cornerSmoothing: 1,
                  ),
                  side: BorderSide(
                    color: theme.primary[100]!,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 67,
                    width: 67,
                    decoration: BoxDecoration(
                      color: theme.grey[50],
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(width: 1, color: theme.grey[100]!),
                    ),
                    child: Icon(LucideIcons.user),
                  ),
                  horizontalSpace(Spacing.points16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "أمجد خلفان",
                        style: TextStyles.h6.copyWith(color: theme.grey[900]),
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        "akalsulimani@gmail.com",
                        style:
                            TextStyles.caption.copyWith(color: theme.grey[600]),
                      ),
                      verticalSpace(Spacing.points4),
                      Text(
                        " ذكر " +
                            "•" +
                            " 26 سنة " +
                            "•" +
                            " مسجل منذ أغسطس  2022 ",
                        style:
                            TextStyles.caption.copyWith(color: theme.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            verticalSpace(Spacing.points24),
            Text(
              'إعدادات التطبيق',
              style: TextStyles.h6,
            ),
            verticalSpace(Spacing.points8),
          ],
        ),
      ),
    );
  }
}
