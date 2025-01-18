import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

AppBar appBar(BuildContext context, WidgetRef ref, String? titleTranslationKey,
    bool showLocaleChangeIcon, bool automaticallyImplyLeading,
    {List<Widget>? actions}) {
  final theme = AppTheme.of(context);
  final canPop = Navigator.of(context).canPop();
  final showBackButton = canPop && automaticallyImplyLeading;

  return AppBar(
    title: Text(
      titleTranslationKey != null
          ? AppLocalizations.of(context).translate(titleTranslationKey)
          : '',
      style: TextStyles.screenHeadding.copyWith(
        color: theme.grey[900],
        height: 1,
      ),
    ),
    backgroundColor: theme.backgroundColor,
    surfaceTintColor: theme.backgroundColor,
    centerTitle: false,
    shadowColor: theme.grey[100],
    actions: loadedActions(ref, showLocaleChangeIcon, actions),
    leading: showBackButton
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => Navigator.of(context).pop(),
          )
        : null,
    titleSpacing: showBackButton ? -12 : 16,
    automaticallyImplyLeading: false,
  );
}

AppBar plainAppBar(BuildContext context, WidgetRef ref, String? title,
    bool showLocaleChangeIcon, bool automaticallyImplyLeading,
    {List<Widget>? actions}) {
  final theme = AppTheme.of(context);
  final canPop = Navigator.of(context).canPop();
  final showBackButton = canPop && automaticallyImplyLeading;

  return AppBar(
    title: Text(
      title != null ? title : '',
      style: TextStyles.screenHeadding.copyWith(
        color: theme.grey[900],
        height: 1,
      ),
    ),
    backgroundColor: theme.backgroundColor,
    surfaceTintColor: theme.backgroundColor,
    centerTitle: false,
    shadowColor: theme.grey[100],
    actions: loadedActions(ref, showLocaleChangeIcon, actions),
    leading: showBackButton
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => Navigator.of(context).pop(),
          )
        : null,
    titleSpacing: showBackButton ? -12 : 16,
    automaticallyImplyLeading: false,
  );
}

List<Widget> loadedActions(
    WidgetRef ref, bool showLocaleChangeIcon, List<Widget>? actions) {
  if (showLocaleChangeIcon) {
    actions?.add(
      GestureDetector(
        onTap: () {
          ref.watch(localeNotifierProvider.notifier).toggleLocale();
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Icon(
            LucideIcons.languages,
          ),
        ),
      ),
    );
  }
  return actions ?? [];
}
