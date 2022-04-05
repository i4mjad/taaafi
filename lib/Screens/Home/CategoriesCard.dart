import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Screens/Ta3afiLiberary/Widgets/ContentPage.dart';
import 'package:reboot_app_3/Shared/Constants.dart';

import '../../Localization.dart';

class CategoriesCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width - 40,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.5),
          border:
              Border.all(width: 0.25, color: primaryColor.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context).translate('porn-addiction-recovery-p'),
            style: kSubTitlesSubsStyle.copyWith(
                color: primaryColor, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12, left: 12, top: 30, bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.message_edit,
                  color: primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.video,
                  color: primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.document,
                  color: primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.book,
                  color: primaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ContentScreen()));
                },
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.40,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("explore-content"),
                          style: kPageTitleStyle.copyWith(
                              fontSize: 14,
                              color: seconderyColor,
                              height: 1,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
              )
            ],
          )
        ],
      ),
    );
  }
}
