import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'library', false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  WidgetsContainer(
                    backgroundColor: theme.primary[50],
                    padding: EdgeInsets.all(8),
                    borderSide: BorderSide(color: theme.primary[100]!),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.search,
                          color: theme.grey[500],
                        ),
                        horizontalSpace(Spacing.points12),
                        Text(
                          AppLocalizations.of(context)
                              .translate('library-search-placeholder'),
                          style: TextStyles.caption.copyWith(
                            color: theme.grey[500],
                          ),
                        )
                      ],
                    ),
                  ),
                  verticalSpace(Spacing.points16),
                  LatestAdditionsWidget(),
                  verticalSpace(Spacing.points16),
                  Text("قوائم من اختيارنا",
                      style: TextStyles.h6.copyWith(color: theme.grey[900]))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LatestAdditionsWidget extends ConsumerWidget {
  const LatestAdditionsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).translate('latest-additions'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
              ),
            ),
            Text(
              AppLocalizations.of(context).translate('show-all'),
              style: TextStyles.caption.copyWith(
                color: theme.grey[500],
              ),
            )
          ],
        ),
        verticalSpace(Spacing.points8),
        SizedBox(
          height: 200,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two columns
              childAspectRatio: 3 / 1, // Adjust height/width ratio
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),

            itemCount: 6, // Number of items
            itemBuilder: (context, index) {
              return LastAdditionItem();
            },
          ),
        ),
      ],
    );
  }
}

class LastAdditionItem extends StatelessWidget {
  const LastAdditionItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetsContainer(
          backgroundColor: theme.primary[50],
          borderSide: BorderSide(color: theme.primary[100]!, width: 0.25),
          child: Center(
            child: Icon(
              LucideIcons.playCircle,
              color: theme.grey[800],
            ),
          ),
        ),
        horizontalSpace(Spacing.points4),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("عنوان رئيسي",
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                ),
                overflow: TextOverflow.ellipsis),
            verticalSpace(Spacing.points4),
            Text(
              "عنوان فرعي",
              style: TextStyles.small.copyWith(
                color: theme.grey[500],
              ),
            ),
          ],
        )
      ],
    );
  }
}
