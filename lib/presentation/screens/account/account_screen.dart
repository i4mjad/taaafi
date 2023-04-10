import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/account/delete_account.dart';
import 'package:reboot_app_3/providers/main_providers.dart';
import 'package:reboot_app_3/providers/user/user_providers.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/widgets/new_user_widgets.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/services/notification_service.dart';

class AccountScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: plainAppBar(context, "account"),
        body: Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16),
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserProfileCard(),
                  SizedBox(
                    height: 32,
                  ),
                  Text(AppLocalizations.of(context).translate('app-settings'),
                      style:
                          kSubTitlesStyle.copyWith(color: theme.primaryColor)),
                  SizedBox(
                    height: 16,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.5)),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              NotificationService.scheduleDailyNotification(
                                  context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(left: 12, right: 12),
                                      child: Icon(
                                        Iconsax.message_notif,
                                        size: 24,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                        AppLocalizations.of(context).translate(
                                            'daily-notification-time'),
                                        style: kSubTitlesStyle.copyWith(
                                            fontSize: 17,
                                            height: 1.25,
                                            color: theme.hintColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ChangeLanguageWidget.changeLanguage(context);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8.0, top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.only(left: 12, right: 12),
                                      child: Icon(
                                        Iconsax.screenmirroring,
                                        size: 26,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)
                                          .translate('ui-settings'),
                                      style: kSubTitlesStyle.copyWith(
                                          fontSize: 17,
                                          height: 1.25,
                                          color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              resetUserDialog(context, ref);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 12, right: 12),
                                  child: Icon(
                                    Iconsax.refresh_circle,
                                    size: 26,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                        AppLocalizations.of(context)
                                            .translate('delete-my-data'),
                                        style: kSubTitlesStyle.copyWith(
                                            fontSize: 17,
                                            color: theme.hintColor)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.mediumImpact();

                              await ref
                                  .watch(googleAuthenticationServiceProvider)
                                  .signOut();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 12, right: 12),
                                  child: Icon(
                                    Iconsax.user_remove,
                                    size: 28,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                        AppLocalizations.of(context)
                                            .translate('log-out'),
                                        style: kSubTitlesStyle.copyWith(
                                            fontSize: 17,
                                            color: theme.hintColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          color: theme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              DeleteAccountSheet.openDeleteAccountMessage(
                                  context, ref);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 12, right: 12),
                                  child: Icon(
                                    Iconsax.trash,
                                    size: 28,
                                    color: Colors.red,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                        AppLocalizations.of(context)
                                            .translate('delete-my-account'),
                                        style: kSubTitlesStyle.copyWith(
                                            fontSize: 17, color: Colors.red)),
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
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  resetUserDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter bsState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: MediaQuery.of(context).size.width,
            color: theme.scaffoldBackgroundColor,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: theme.primaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Iconsax.calendar_tick,
                    color: theme.primaryColor,
                    size: 32,
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context)
                      .translate('delete-user-dialog-title'),
                  style: kHeadlineStyle.copyWith(
                      fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context)
                      .translate("delete-user-dialog-content"),
                  style: kBodyStyle.copyWith(height: 1.2),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        var selectedDate = await getDateTime(context);
                        if (selectedDate == null) return;
                        await ref
                            .watch(userViewModelProvider.notifier)
                            .createNewData(selectedDate);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 80,
                        width: (MediaQuery.of(context).size.width - 40),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5)),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate("specific-day"),
                            style: kTitleSeconderyStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
      },
    );
  }
}

class UserProfileCard extends ConsumerWidget {
  UserProfileCard({Key key, String lang}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    var userProfile =
        ref.watch(userViewModelProvider.notifier).getUserProfile();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(500),
              ),
              child: Icon(
                Iconsax.user,
                size: 56,
                color: theme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  userProfile.displayName,
                  style: kTitlePrimeryStyle.copyWith(
                      color: theme.hintColor, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  userProfile.email.toUpperCase() ?? "",
                  style: kCaptionStyle.copyWith(
                    color: theme.hintColor.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class AccountScreenScreenAuthenticationWrapper extends ConsumerWidget {
  const AccountScreenScreenAuthenticationWrapper({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsyncValue = ref.watch(userDocStreamProvider);

    return userDocAsyncValue.when(
      data: (DocumentSnapshot userDoc) {
        if (userDoc == null || !userDoc.exists) {
          return LoginScreen();
        } else {
          return CustomBlocProvider(
            bloc: AccountBloc(),
            child: AccountScreen(),
          );
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
  }
}
