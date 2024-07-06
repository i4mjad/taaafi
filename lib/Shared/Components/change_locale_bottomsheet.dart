import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLanguageWidget {
  static void changeLanguage(BuildContext context) async {
    final theme = Theme.of(context);
    final prefs = await SharedPreferences.getInstance();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) => Container(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildDivider(context, theme),
                  SizedBox(height: 16),
                  _buildNightModeSwitcher(context, theme),
                  SizedBox(height: 16),
                  _buildChangeLanguageHeader(context, theme),
                  SizedBox(height: 16),
                  _buildLanguageSelection(context, theme, prefs, ref),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildDivider(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 5,
          width: MediaQuery.of(context).size.width / 5,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(30),
          ),
        )
      ],
    );
  }

  static Widget _buildNightModeSwitcher(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate("night-mode"),
          style: kSubTitlesStyle.copyWith(color: theme.hintColor),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border.all(color: theme.primaryColor, width: 0.25),
            borderRadius: BorderRadius.circular(10.5),
          ),
          child: Consumer(builder: (context, ref, child) {
            final customTheme = ref.watch(customThemeProvider);
            return GestureDetector(
              onTap: () async {
                customTheme.toggleTheme();
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12, right: 12),
                    child: Icon(
                      CupertinoIcons.moon,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        theme.brightness == Brightness.dark
                            ? AppLocalizations.of(context).translate('off')
                            : AppLocalizations.of(context).translate('on'),
                        style: kSubTitlesStyle.copyWith(
                          fontSize: 17,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  static Widget _buildChangeLanguageHeader(
      BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate("change-lang"),
          style: kPageTitleStyle.copyWith(
            fontSize: 22,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }

  static Widget _buildLanguageSelection(BuildContext context, ThemeData theme,
      SharedPreferences prefs, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(color: theme.primaryColor, width: 0.25),
        borderRadius: BorderRadius.circular(10.5),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
              context, ref, theme, prefs, 'ar', "ع", "العربية"),
          Divider(color: theme.primaryColor, thickness: 0.25),
          _buildLanguageOption(
              context, ref, theme, prefs, 'en', "E", "English"),
        ],
      ),
    );
  }

  static Widget _buildLanguageOption(
      BuildContext context,
      WidgetRef ref,
      ThemeData theme,
      SharedPreferences prefs,
      String languageCode,
      String languageCodeText,
      String languageText) {
    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 8, right: 16, left: 16),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await prefs.setString('languageCode', languageCode);
          final enLocale = Locale(languageCode, '');
          ref.watch(localeNotifierProvider.notifier).setLocale(enLocale);
          getSnackBar(context, "changed-to-$languageCode");
          Navigator.pop(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 12, right: 12),
              child: Text(
                languageCodeText,
                style: kSubTitlesStyle.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  languageText,
                  style: kSubTitlesStyle.copyWith(
                    fontSize: 17,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
