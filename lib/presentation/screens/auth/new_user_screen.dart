import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/data/models/Enums.dart';

import 'package:reboot_app_3/providers/user/user_providers.dart';

import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/helpers/date_methods.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class NewUserSection extends ConsumerStatefulWidget {
  NewUserSection({Key key}) : super(key: key);

  @override
  NewUserSectionState createState() => NewUserSectionState();
}

class NewUserSectionState extends ConsumerState<NewUserSection> {
  Gender _selectedGender = Gender.male;
  DateTime _selectedDateOfBirth = DateTime.now();
  DateTime _selectedStartingDate = DateTime.now();
  Language _selectedLocale = Language.arabic;

  @override
  Widget build(BuildContext contexts) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 16,
              ),
              Text(
                AppLocalizations.of(context).translate('welcome'),
                style: kDisplayStyle.copyWith(
                    fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              SizedBox(
                height: 24,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                          print(dateTime);
                          if (dateTime != null) {
                            setState(() {
                              _selectedDateOfBirth = dateTime;
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
                                DateFormat.yMd().format(_selectedDateOfBirth),
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
                              _selectedGender = p0.first;
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
                                AppLocalizations.of(context)
                                    .translate("female"),
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
                              _selectedLocale = p0.first;
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
                        height: 8,
                      ),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate("specific-day"),
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
                          var dateTime = await getStartingDate(context);

                          if (dateTime != null) {
                            setState(() {
                              _selectedStartingDate = dateTime;
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
                                DateFormat.yMd().format(_selectedStartingDate),
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
                          Text.rich(
                            TextSpan(
                              text: "ستبدأ العد من ",
                              style: kSubTitlesSubsStyle.copyWith(
                                color: theme.primaryColor.withOpacity(0.7),
                              ),
                              children: <InlineSpan>[
                                TextSpan(
                                  text:
                                      _getIntervalOfDays(_selectedStartingDate),
                                  style: kSubTitlesSubsStyle.copyWith(
                                    color: theme.primaryColor.withOpacity(0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: " يوم/أيام",
                                  style: kSubTitlesSubsStyle.copyWith(
                                    color: theme.primaryColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          .watch(userViewModelProvider.notifier)
                          .createNewData(
                            _selectedStartingDate,
                            gender: _selectedGender.name,
                            locale: _selectedLocale.name,
                          );
                    },
                    child: Container(
                      height: 60,
                      width: MediaQuery.of(context).size.width - 40,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('start-your-journy'),
                          style: kTitleSeconderyStyle.copyWith(
                              color: theme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _getIntervalOfDays(DateTime selectedStartingDate) {
    final date2 = DateTime.now();
    final difference = date2.difference(selectedStartingDate).inDays;
    return difference.toString();
  }
}
