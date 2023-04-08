import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/widgets/new_user_widgets.dart';
import 'package:reboot_app_3/providers/user/user_providers.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class NewUserSection extends ConsumerWidget {
  NewUserSection({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.calendar_tick,
                color: theme.primaryColor,
                size: 56,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                AppLocalizations.of(context).translate('start-your-journy'),
                style: kDisplayStyle.copyWith(
                    fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('start-your-journy-p'),
                        style: kBodyStyle.copyWith(
                            fontSize: 24,
                            color: theme.primaryColor.withAlpha(128)),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 24,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      var selectedDate = await getDateTime(context);
                      if (selectedDate == null) {
                        return;
                      } else {
                        await ref
                            .watch(userViewModelProvider.notifier)
                            .createNewData(selectedDate);
                      }
                    },
                    child: Container(
                      height: 60,
                      width: MediaQuery.of(context).size.width - 40,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.5)),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('specific-day'),
                          style: kTitleSeconderyStyle,
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
}
