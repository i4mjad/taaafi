import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/components/snackbar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/viewmodels/followup_viewmodel.dart';

changeDateEvent(String date, BuildContext context,
    FollowUpViewModel followUpViewModel) async {
  final trimedDate = date.trim();
  final theme = Theme.of(context);
  showModalBottomSheet(
      backgroundColor: theme.scaffoldBackgroundColor,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(50)),
                  )
                ],
              ),
              SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trimedDate,
                    style: kPageTitleStyle.copyWith(
                        fontSize: 26, color: theme.primaryColor),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addSuccess(date);
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      getSnackBar(context, "free-day-recorded");
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😍",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("free-day"),
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addRelapse(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "relapse-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😒",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("relapse"),
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addWatchOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "pornonly-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😥",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("porn-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      followUpViewModel.addMastOnly(date);
                      HapticFeedback.mediumImpact();
                      getSnackBar(context, "mastonly-recorded");
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4 - 24,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12.5),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.25),
                          width: 0.25,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😪",
                            style: TextStyle(fontSize: 22),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            AppLocalizations.of(context).translate("mast-only"),
                            textAlign: TextAlign.center,
                            style: kSubTitlesStyle.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 18,
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.primaryColor, width: 0.25),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).translate("cancel"),
                      style: kSubTitlesStyle.copyWith(
                        color: theme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      });
}



outOfRangeAlert(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 12,
              ),
              CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.2),
                child: Icon(
                  Iconsax.warning_2,
                  color: Colors.red,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                AppLocalizations.of(context).translate("out-of-range"),
                style:
                kPageTitleStyle.copyWith(color: Colors.red, fontSize: 24),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                AppLocalizations.of(context).translate('out-of-range-p'),
                style: kSubTitlesStyle.copyWith(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.normal,
                    fontSize: 18),
              ),
              SizedBox(
                height: 30,
              )
            ],
          ),
        );
      });
}
