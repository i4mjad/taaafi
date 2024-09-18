import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/library/featured_list_item.dart';
import 'package:reboot_app_3/features/vault/data/library/latest_addition_item.dart';

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
                  FeaturedListsWidget()
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
    final items = [
      LatestAdditionItem(
        LucideIcons.playCircle,
        "كيف أتعامل مع الانتكاسة؟",
        "قناة واعي",
      ),
      LatestAdditionItem(
        LucideIcons.playCircle,
        "تمارين وتأملات التعافي",
        "محمد القطان",
      ),
      LatestAdditionItem(
        LucideIcons.text,
        "تمارين بعد الانتكاسة",
        "قناة واعي",
      ),
      LatestAdditionItem(
        LucideIcons.playCircle,
        "كيف أستفيد من منصة تعافي؟",
        "منصة تعافي",
      ),
      LatestAdditionItem(
        LucideIcons.playCircle,
        "مراجعة كتاب ممتلئ بالفراغ",
        "عماد رشاد عثمان",
      ),
      LatestAdditionItem(
        LucideIcons.playCircle,
        "كيف تبدأ؟ دليل التعافي",
        "قناة واعي",
      ),
    ];
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
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return LastAdditionItemWidget(items[index]);
          },
        ),
      ],
    );
  }
}

class LastAdditionItemWidget extends StatelessWidget {
  const LastAdditionItemWidget(this.latestAdditionItem, {super.key});
  final LatestAdditionItem latestAdditionItem;

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
              latestAdditionItem.icon,
              color: theme.grey[800],
            ),
          ),
        ),
        horizontalSpace(Spacing.points4),
        Expanded(
          // Ensures the text uses the available width without overflowing
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This handles long text with ellipsis and restricts it to one line
              Text(
                latestAdditionItem.primaryTitle,
                style: TextStyles.footnote.copyWith(
                  color: theme.grey[900],
                ),
                maxLines: 2, // Restrict to one line
                overflow: TextOverflow
                    .ellipsis, // Add ellipsis at the end of the text
              ),
              // verticalSpace(Spacing.points4),
              Spacer(),
              Text(
                latestAdditionItem.seconderyTitle,
                style: TextStyles.small.copyWith(
                  color: theme.grey[500],
                ),
                maxLines: 1, // Restrict to one line
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis for the subtitle
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FeaturedListsWidget extends ConsumerWidget {
  const FeaturedListsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final content = [
      FeaturedListItem(LucideIcons.planeLanding, "التعامل مع الانتكاسة"),
      FeaturedListItem(LucideIcons.planeTakeoff, "كيف أبدأ؟"),
      FeaturedListItem(LucideIcons.heart, "ما هو الأدمان؟"),
      FeaturedListItem(LucideIcons.airVent, "قائمة عوالم"),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).translate('featured-lists'),
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
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5 / 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: content.length,
          itemBuilder: (context, index) {
            return FeaturedListItemWidget(content[index]);
          },
        ),
      ],
    );
  }
}

class FeaturedListItemWidget extends StatelessWidget {
  const FeaturedListItemWidget(this.listItem, {super.key});

  final FeaturedListItem listItem;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return WidgetsContainer(
      padding: EdgeInsets.all(8),
      backgroundColor: theme.primary[50],
      borderSide: BorderSide(
        color: theme.primary[100]!,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(listItem.icon),
          horizontalSpace(Spacing.points4),
          Expanded(
            child: Text(
              listItem.listName,
              style: TextStyles.small.copyWith(
                color: theme.grey[900],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Spacer(),
          Icon(LucideIcons.arrowLeft, size: 16, color: theme.grey[500]),
        ],
      ),
    );
  }
}
