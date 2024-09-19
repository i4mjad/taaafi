import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/library/content_type_item.dart';
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
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate("library"),
          style: TextStyles.screenHeadding.copyWith(
            color: theme.grey[900],
            height: 1,
          ),
        ),
        backgroundColor: theme.backgroundColor,
        surfaceTintColor: theme.backgroundColor,
        centerTitle: false,
        shadowColor: theme.grey[100],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 16),
            child: Icon(LucideIcons.bookmark, color: theme.grey[900]),
          )
        ],
        leadingWidth: 16,
        automaticallyImplyLeading: true,
      ),
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
                  _searchWidget(theme, context),
                  verticalSpace(Spacing.points16),
                  LatestAdditionsWidget(),
                  verticalSpace(Spacing.points16),
                  FeaturedListsWidget(),
                  verticalSpace(Spacing.points16),
                  ContentTypesWidget()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchWidget(CustomThemeData theme, BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.content.name);
      },
      child: WidgetsContainer(
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
    );
  }
}

class ContentTypesWidget extends StatelessWidget {
  const ContentTypesWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final content = [
      ContentTypeItem(LucideIcons.book, "Article"),
      ContentTypeItem(LucideIcons.video, "Video"),
      ContentTypeItem(LucideIcons.paperclip, "Book"),
      ContentTypeItem(LucideIcons.pencil, "Blog"),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('content-type'),
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
          ),
        ),
        verticalSpace(Spacing.points8),
        Builder(builder: (BuildContext context) {
          final hasData = true;
          if (hasData) {
            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1 / 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: content.length,
              itemBuilder: (context, index) {
                return ContentTypeWidget(content[index]);
              },
            );
            // ignore: dead_code
          } else {
            return Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('no-data'),
                    style: TextStyles.caption.copyWith(
                      color: theme.grey[900],
                    ),
                  )
                ],
              ),
            );
          }
        }),
      ],
    );
  }
}

class ContentTypeWidget extends StatelessWidget {
  const ContentTypeWidget(
    this.contentTypeItem, {
    super.key,
  });

  final ContentTypeItem contentTypeItem;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        context.goNamed(
          RouteNames.contentType.name,
          pathParameters: {
            'name': contentTypeItem.contentTypeNameTranslationKey.toString()
          },
        );
      },
      child: WidgetsContainer(
        cornerSmoothing: 0.6,
        backgroundColor: theme.primary[50],
        borderSide: BorderSide(
          color: theme.primary[100]!,
        ),
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(contentTypeItem.icon, color: theme.grey[900]),
            verticalSpace(Spacing.points8),
            Text(
              AppLocalizations.of(context)
                  .translate(contentTypeItem.contentTypeNameTranslationKey),
              textAlign: TextAlign.center,
              style: TextStyles.caption.copyWith(
                color: theme.primary[900],
                height: 1,
              ),
            ),
          ],
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
            GestureDetector(
              onTap: () {
                context.goNamed(RouteNames.content.name);
              },
              child: Text(
                AppLocalizations.of(context).translate('show-all'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                ),
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
            GestureDetector(
              onTap: () {
                context.goNamed(RouteNames.content.name);
              },
              child: Text(
                AppLocalizations.of(context).translate('show-all'),
                style: TextStyles.caption.copyWith(
                  color: theme.grey[500],
                ),
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
    return GestureDetector(
      onTap: () {
        print(listItem.listName);
        context.go('/vault/library/list/${listItem.listName}');
      },
      child: WidgetsContainer(
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
            Icon(
              LucideIcons.arrowLeft,
              size: 16,
              color: theme.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
