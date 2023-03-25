import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/main.dart';
import 'package:reboot_app_3/providers/main_providers.dart';

import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLanguageWidget {
  static void changeLanguage(BuildContext context) async {
    final theme = Theme.of(context);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: theme.scaffoldBackgroundColor,
          child: Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                ),
                SizedBox(
                  height: 16,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate("night-mode"),
                      style: kSubTitlesStyle.copyWith(color: theme.hintColor),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          border: Border.all(
                              color: theme.primaryColor, width: 0.25),
                          borderRadius: BorderRadius.circular(10.5)),
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
                                          ? AppLocalizations.of(context)
                                              .translate('off')
                                          : AppLocalizations.of(context)
                                              .translate('on'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17,
                                          color: theme.primaryColor)),
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
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
                ),
                SizedBox(
                  height: 16,
                ),
                Container(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border:
                          Border.all(color: theme.primaryColor, width: 0.25),
                      borderRadius: BorderRadius.circular(10.5)),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: 4, bottom: 8, right: 16, left: 16),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();

                            await prefs.setString('languageCode', 'ar');
                            final enLocale =
                                Locale(prefs.getString("languageCode"), '');
                            await MyApp.setLocale(context, enLocale);
                            getSnackBar(context, "changed-to-ar");

                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Text(
                                  "ع",
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
                                    "العربية",
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
                      ),
                      Divider(
                        color: theme.primaryColor,
                        thickness: 0.25,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 8, bottom: 4, right: 16, left: 16),
                        child: GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();

                            await prefs.setString('languageCode', 'en');
                            final enLocale =
                                Locale(prefs.getString("languageCode"), '');
                            await MyApp.setLocale(context, enLocale);
                            getSnackBar(context, "changed-to-en");

                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 12, right: 12),
                                child: Text(
                                  "E",
                                  style: kSubTitlesStyle.copyWith(
                                      color: theme.primaryColor),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text("English",
                                      style: kSubTitlesStyle.copyWith(
                                        fontSize: 17,
                                        color: theme.primaryColor,
                                      )),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
