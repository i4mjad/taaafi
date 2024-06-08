import 'package:figma_squircle/figma_squircle.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/providers/followup/followup_providers.dart';
import 'package:reboot_app_3/providers/main_providers.dart';
import 'package:reboot_app_3/providers/user/user_providers.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class WelcomeWidget extends ConsumerWidget {
  const WelcomeWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authStateChangesProvider);

    return userAsyncValue.when(
      data: (User? user) {
        if (user == null) {
          return NotSignIn();
        } else {
          final userProfileProvider = ref
              .read(userViewModelStateNotifierProvider.notifier)
              .userDocumentStream;
          if (userProfileProvider != null) {
            return WelcomeContent();
          } else {
            return NotSignIn();
          }
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
  }
}

class NotSignIn extends StatelessWidget {
  const NotSignIn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('welcome'),
          style: textStyles.h6.copyWith(color: theme.primaryColor),
        ),
        SizedBox(
          height: 16,
        ),
        Container(
          height: 150,
          padding: EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width - 40,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12.5)),
          child: Center(
            child: Text(
              AppLocalizations.of(context).translate('not-login'),
              textAlign: TextAlign.center,
              style: kSubTitlesStyle.copyWith(
                  color: lightPrimaryColor,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  fontSize: 16),
            ),
          ),
        )
      ],
    );
  }
}

class WelcomeContent extends ConsumerWidget {
  const WelcomeContent({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpData = ref.watch(followupViewModelProvider.notifier);
    final theme = CustomThemeInherited.of(context);

    return FutureBuilder<DateTime>(
        future: followUpData.getFirstDate(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return (NotSignIn());
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('welcome'),
                  style: textStyles.h6.copyWith(color: theme.grey[900]),
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //TODO: consider extacting this to a reusable widget
                    Container(
                      width: MediaQuery.of(context).size.width * 0.27,
                      height: 150,
                      decoration: ShapeDecoration(
                        color: theme.grey[50],
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 15,
                            cornerSmoothing: 1,
                          ),
                          side: BorderSide(
                            color: theme.grey[100]!,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FutureBuilder(
                            future: followUpData.getRelapseStreak(),
                            initialData: 0,
                            builder: (BuildContext context,
                                AsyncSnapshot<int> streak) {
                              switch (streak.connectionState) {
                                // Uncompleted State
                                case ConnectionState.none:
                                case ConnectionState.waiting:
                                  return Center(
                                      child: CircularProgressIndicator());

                                default:
                                  // Completed with error
                                  if (streak.hasError)
                                    return Container(
                                      child: Center(
                                        child: Text(
                                          "0",
                                        ),
                                      ),
                                    );
                                  return Text(
                                    streak.data.toString(),
                                    style: kPageTitleStyle.copyWith(
                                      color: theme.primary,
                                      fontSize: 35,
                                    ),
                                  );
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0, left: 8),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('free-relapse-days'),
                              style: kSubTitlesStyle.copyWith(
                                  fontSize: 16,
                                  color: theme.primary[300],
                                  height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          height: 71,
                          width: MediaQuery.of(context).size.width * 0.60,
                          decoration: BoxDecoration(
                            color: theme.primary[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FutureBuilder(
                              future:
                                  followUpData.getRelapsesCountInLast30Days(),
                              initialData: "0",
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> sh) {
                                switch (sh.connectionState) {
                                  // Uncompleted State
                                  case ConnectionState.none:
                                  case ConnectionState.waiting:
                                    return Center(
                                        child: CircularProgressIndicator());

                                  default:
                                    // Completed with error
                                    if (sh.hasError)
                                      return Container(
                                        child: Center(
                                          child: Text(
                                            AppLocalizations.of(context)
                                                    .translate(
                                                        "relapses-30-days") +
                                                "0",
                                          ),
                                        ),
                                      );
                                    return Text(
                                      AppLocalizations.of(context)
                                              .translate("relapses-30-days") +
                                          (sh.data as String),
                                      textAlign: TextAlign.center,
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 13,
                                          color: theme.primary[100]),
                                    );
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          height: 71,
                          width: MediaQuery.of(context).size.width * 0.60,
                          decoration: BoxDecoration(
                            color: theme.primary[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FutureBuilder(
                              future: followUpData.getTotalDaysWithoutRelapse(),
                              initialData: "0",
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> sh) {
                                switch (sh.connectionState) {
                                  // Uncompleted State
                                  case ConnectionState.none:
                                  case ConnectionState.waiting:
                                    return Center(
                                        child: CircularProgressIndicator());

                                  default:
                                    // Completed with error
                                    if (sh.hasError)
                                      return Container(
                                        child: Center(
                                          child: Text(
                                            AppLocalizations.of(context)
                                                    .translate(
                                                        'free-days-from-start') +
                                                "0",
                                          ),
                                        ),
                                      );
                                    return Text(
                                      AppLocalizations.of(context).translate(
                                              'free-days-from-start') +
                                          (sh.data as String),
                                      textAlign: TextAlign.center,
                                      style: kSubTitlesStyle.copyWith(
                                          color: theme.primary[100],
                                          fontSize: 13),
                                    );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            );
          }
        });
  }
}
