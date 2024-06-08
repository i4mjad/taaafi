import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/data/models/Enums.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/screens/auth/new_user_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/providers/followup/followup_providers.dart';
import 'package:reboot_app_3/providers/main_providers.dart';
import 'package:reboot_app_3/providers/user/user_providers.dart';

import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/helpers/date_methods.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class FollowYourRebootScreenAuthenticationWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authStateChangesProvider);

    return userAsyncValue.when(
      data: (User? user) {
        // Updated to User? to reflect nullable user
        if (user == null) return LoginScreen();
        return UserDocWrapper();
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
  }
}

class UserDocWrapper extends ConsumerWidget {
  const UserDocWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsyncValue = ref.watch(userDocStreamProvider);

    return userDocAsyncValue.when(
      data: (DocumentSnapshot? userDoc) {
        if (userDoc == null || !userDoc.exists) {
          return NewUserSection();
        } else {
          var userData = userDoc.data() as Map<String, dynamic>?;

          if (userData == null) {
            return Center(child: NotificationActivationScreen());
          }

          final gender = userData["gender"];
          final dayOfBirth = userData["dayOfBirth"];
          final locale = userData["locale"];

          if (gender == null || dayOfBirth == null || locale == null) {
            return Center(child: NotificationActivationScreen());
          }

          if (gender is String && dayOfBirth is Timestamp && locale is String) {
            return FollowYourRebootScreen();
          } else {
            return Center(child: NotificationActivationScreen());
          }
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
  }
}

class NotificationActivationScreen extends ConsumerStatefulWidget {
  const NotificationActivationScreen({
    key,
  }) : super(key: key);

  @override
  ConsumerState<NotificationActivationScreen> createState() =>
      _NotificationActivationScreenState();
}

class _NotificationActivationScreenState
    extends ConsumerState<NotificationActivationScreen> {
  Gender _selectedGender = Gender.male;
  DateTime _selectedDate = DateTime.now();
  Language _selectedLocale = Language.arabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
          child: Padding(
            padding:
                EdgeInsets.only(top: 18.0, bottom: 18.0, right: 32, left: 32),
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
                    Iconsax.user,
                    color: theme.primaryColor,
                    size: 32,
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context)
                      .translate('followup-notifications'),
                  style: kHeadlineStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: theme.primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Iconsax.heart,
                        color: theme.primaryColor,
                        size: 32 / 1.5,
                      ),
                    ),
                    SizedBox(
                      width: 10.5,
                    ),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate("followup-notifications-p"),
                        style: kSubTitlesStyle.copyWith(
                          color: theme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("date-of-birth"),
                          style: kSubTitlesStyle.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    GestureDetector(
                      onTap: () async {
                        var dateTime = await getDateOfBirth(context);

                        if (dateTime != null && dateTime.year < 2010) {
                          setState(() {
                            _selectedDate = dateTime;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        width: MediaQuery.of(context).size.width - 40,
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.5),
                            color: theme.cardColor),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Iconsax.calendar),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              DateFormat.yMd().format(_selectedDate),
                              style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).translate("gender"),
                          style: kSubTitlesStyle.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: SegmentedButton(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            theme.primaryColor,
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            theme.cardColor,
                          ),
                        ),
                        selectedIcon: Icon(
                          Icons.done,
                          color: theme.primaryColor,
                        ),
                        onSelectionChanged: (p0) {
                          setState(() {
                            _selectedGender = p0.first as Gender;
                          });
                        },
                        segments: <ButtonSegment<Gender>>[
                          ButtonSegment<Gender>(
                            value: Gender.male,
                            label: Text(
                              AppLocalizations.of(context).translate("male"),
                              style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ButtonSegment<Gender>(
                            value: Gender.femele,
                            label: Text(
                              AppLocalizations.of(context).translate("female"),
                              style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          )
                        ],
                        selected: <Gender>{_selectedGender},
                        showSelectedIcon: true,
                        emptySelectionAllowed: false,
                        multiSelectionEnabled: false,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("preferred-language"),
                          style: kSubTitlesStyle.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: SegmentedButton(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          foregroundColor: MaterialStateProperty.all(
                            theme.primaryColor,
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            theme.cardColor,
                          ),
                        ),
                        selectedIcon: Icon(
                          Icons.done,
                          color: theme.primaryColor,
                        ),
                        onSelectionChanged: (p0) {
                          setState(() {
                            _selectedLocale = p0.first as Language;
                          });
                        },
                        segments: <ButtonSegment<Language>>[
                          ButtonSegment<Language>(
                            value: Language.arabic,
                            label: Text(
                              'العربية',
                              style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          ButtonSegment<Language>(
                            value: Language.english,
                            label: Text(
                              'English',
                              style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          )
                        ],
                        selected: <Language>{_selectedLocale},
                        showSelectedIcon: true,
                        emptySelectionAllowed: false,
                        multiSelectionEnabled: false,
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("data-are-secured"),
                          style: kSubTitlesStyle.copyWith(
                            color: theme.indicatorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    await ref
                        .watch(userViewModelStateNotifierProvider.notifier)
                        .updateUserData(
                          _selectedGender.name,
                          _selectedLocale.name,
                          _selectedDate,
                        );

                    await ref
                        .watch(followupViewModelProvider.notifier)
                        .registerPromizeUser(
                          _selectedGender.name,
                          _selectedLocale.name,
                          _selectedDate,
                        );

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) =>
                    //         FollowYourRebootScreenAuthenticationWrapper(),
                    //   ),
                    // );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.focusColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: .25,
                          blurRadius: 7,
                          offset: Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate("activate"),
                          style: kTitleSeconderyStyle.copyWith(
                            //TODO: this was changed due to the depreacted color, do not forget to change to the new themeing
                            // color: theme.selectedRowColor,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
