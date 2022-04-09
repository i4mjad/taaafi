import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:reboot_app_3/Screens/FollowYourReboot/FollowYourRebootScreen.dart';
import 'package:reboot_app_3/Shared/Constants.dart';
import 'package:reboot_app_3/Shared/Localization.dart';

class FollowYouRebootHero extends StatelessWidget {
  const FollowYouRebootHero({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    FollowYourRebootScreenAuthenticationWrapper()));
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: MediaQuery.of(context).size.width - 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: primaryColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Lottie.asset(
                'asset/illustrations/home-anumation.json',
                width: MediaQuery.of(context).size.width - 40,
                height: MediaQuery.of(context).size.width - 40,
                repeat: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('follow-your-reboot-p'),
                    style: kSubTitlesSubsStyle.copyWith(
                        color: Colors.white, fontSize: 14),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width:
                          MediaQuery.of(context).size.width /
                              2,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius:
                              BorderRadius.circular(12.5)),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate(
                                    'follow-your-reboot'),
                                style: kPageTitleStyle.copyWith(
                                    fontSize: 18,
                                    color: seconderyColor,
                                    height: 1,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ))
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
