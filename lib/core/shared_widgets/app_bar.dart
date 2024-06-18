import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

//TODO: An issue appeared when the app bar has back button, keep this in mind when testing
AppBar appBar(BuildContext context, WidgetRef ref, String titleTranslationKey) {
  final theme = CustomThemeInherited.of(context);
  return AppBar(
    title: Text(
      AppLocalizations.of(context).translate(titleTranslationKey),
      style: TextStyles.screenHeadding.copyWith(
        color: theme.grey[900],
      ),
    ),
    backgroundColor: theme.backgroundColor,
    centerTitle: false,
    shadowColor: theme.grey[100],
  );
}
