import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

//TODO: An issue appeared when the app bar has back button, keep this in mind when testing
AppBar appBar(BuildContext context, WidgetRef ref, String? titleTranslationKey,
    bool showLocaleChangeIcon) {
  final theme = CustomThemeInherited.of(context);
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
    actions: loadedActions(ref, showLocaleChangeIcon),
    leadingWidth: 16,
    automaticallyImplyLeading: true,
  );
}

List<Widget> loadedActions(WidgetRef ref, bool showLocaleChangeIcon) {
  List<Widget> widgets = [];
  if (showLocaleChangeIcon) {
    widgets.add(
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
  return widgets;
}



//TODO: check this later
// class MyAppBar extends ConsumerWidget implements PreferredSizeWidget {
//   const MyAppBar({super.key});

//   @override
//   Widget build(BuildContext context,WidgetRef ref) {
//     return Padding(
//       padding: EdgeInsets.only(left: 10,right:10),//adjust the padding as you want
//       child: appBar(), //or row/any widget
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }