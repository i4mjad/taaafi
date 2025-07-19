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
import 'package:reboot_app_3/core/utils/icon_mapper.dart';
import 'package:reboot_app_3/core/utils/localization_helper.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:reboot_app_3/features/vault/application/library/library_notifier.dart';
import 'package:reboot_app_3/features/vault/data/library/models/cursor_content.dart';
import 'package:reboot_app_3/features/vault/data/library/models/cursor_content_list.dart';
import 'package:reboot_app_3/features/vault/data/library/models/cursor_content_type.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final libraryNotifier = ref.watch(libraryNotifierProvider);
    return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: appBar(context, ref, "library", false, true),
        body: libraryNotifier.when(
          data: (library) => SafeArea(
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
                      LatestAdditionsWidget(library.latestContent),
                      verticalSpace(Spacing.points16),
                      FeaturedListsWidget(library.featuredLists),
                      verticalSpace(Spacing.points16),
                      ContentTypesWidget(library.contentTypes)
                    ],
                  ),
                ),
              ),
            ),
          ),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          loading: () => Center(child: Spinner()),
        ));
  }

  Widget _searchWidget(CustomThemeData theme, BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.goNamed(RouteNames.contents.name);
      },
      child: WidgetsContainer(
        backgroundColor: theme.backgroundColor,
        padding: EdgeInsets.all(8),
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 5,
            spreadRadius: 0,
            offset: Offset(
              0,
              0,
            ),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 1,
            spreadRadius: 0,
            offset: Offset(
              0,
              0,
            ),
          ),
        ],
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
  const ContentTypesWidget(
    this.content, {
    super.key,
  });

  final List<CursorContentType> content;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

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

  final CursorContentType contentTypeItem;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        context.goNamed(
          RouteNames.contentType.name,
          pathParameters: {
            'typeId': contentTypeItem.id,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: WidgetsContainer(
          cornerSmoothing: 0.6,
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
          padding: EdgeInsets.all(8),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 5,
              spreadRadius: 0,
              offset: Offset(
                0,
                0,
              ),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 1,
              spreadRadius: 0,
              offset: Offset(
                0,
                0,
              ),
            ),
          ],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(IconMapper.getIconFromString(contentTypeItem.iconName),
                  color: theme.primary[700]),
              verticalSpace(Spacing.points8),
              Text(
                LocalizationHelper.getLocalizedName(
                    context, contentTypeItem.name, contentTypeItem.nameAr),
                textAlign: TextAlign.center,
                style: TextStyles.caption.copyWith(
                  color: theme.grey[900],
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LatestAdditionsWidget extends ConsumerWidget {
  const LatestAdditionsWidget(
    this.latestContent, {
    super.key,
  });

  final List<CursorContent> latestContent;

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
            GestureDetector(
              onTap: () {
                context.goNamed(RouteNames.contents.name);
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
          itemCount: latestContent.length,
          itemBuilder: (context, index) {
            return LastAdditionItemWidget(latestContent[index]);
          },
        ),
      ],
    );
  }
}

class LastAdditionItemWidget extends ConsumerWidget {
  const LastAdditionItemWidget(this.contentItem, {super.key});
  final CursorContent contentItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        ref.read(urlLauncherProvider).launch(
              Uri.parse(contentItem.link),
              mode: LaunchMode.externalApplication,
            );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetsContainer(
            backgroundColor: theme.backgroundColor,
            borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: 5,
                spreadRadius: 0,
                offset: Offset(
                  0,
                  0,
                ),
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.1),
                blurRadius: 1,
                spreadRadius: 0,
                offset: Offset(
                  0,
                  0,
                ),
              ),
            ],
            child: Center(
              child: Icon(
                IconMapper.getIconFromString(contentItem.type.iconName),
                color: theme.primary[700],
              ),
            ),
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            // Ensures the text uses the available width without overflowing
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // This handles long text with ellipsis and restricts it to one line
                Text(
                  contentItem.name,

                  style: TextStyles.footnote
                      .copyWith(color: theme.grey[800], height: 1.2),

                  maxLines: 2, // Restrict to one line
                  overflow: TextOverflow
                      .ellipsis, // Add ellipsis at the end of the text
                ),
                Spacer(),
                Text(
                  LocalizationHelper.getLocalizedName(context,
                      contentItem.owner.name, contentItem.owner.nameAr),
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
      ),
    );
  }
}

class FeaturedListsWidget extends ConsumerWidget {
  const FeaturedListsWidget(
    this.featuredLists, {
    super.key,
  });

  final List<CursorContentList> featuredLists;

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
              AppLocalizations.of(context).translate('featured-lists'),
              style: TextStyles.h6.copyWith(
                color: theme.grey[900],
              ),
            ),
            GestureDetector(
              onTap: () {
                context.goNamed(RouteNames.contentLists.name);
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
          itemCount: featuredLists.length,
          itemBuilder: (context, index) {
            return FeaturedListItemWidget(featuredLists[index]);
          },
        ),
      ],
    );
  }
}

class FeaturedListItemWidget extends StatelessWidget {
  const FeaturedListItemWidget(this.listItem, {super.key});

  final CursorContentList listItem;
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        context.goNamed(RouteNames.libraryList.name, pathParameters: {
          "id": listItem.id,
        });
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(8),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 5,
            spreadRadius: 0,
            offset: Offset(
              0,
              0,
            ),
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 1,
            spreadRadius: 0,
            offset: Offset(
              0,
              0,
            ),
          ),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              IconMapper.getIconFromString(listItem.iconName),
              color: theme.primary[700],
            ),
            horizontalSpace(Spacing.points4),
            Expanded(
              child: Text(
                LocalizationHelper.getLocalizedName(
                    context, listItem.name, listItem.nameAr),
                style: TextStyles.small.copyWith(
                  color: theme.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
