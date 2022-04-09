import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Shared/Constants.dart';

import '../../../Localization.dart';

class UserProfileCard extends StatelessWidget {

  UserProfileCard({
    Key key,
  }) : super(key: key);

  final User user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black12)),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Iconsax.personalcard,
                  size: 40,
                  color: primaryColor,
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    this.user.displayName != null
                        ? this.user.displayName
                        : "",
                    style: kPageTitleStyle.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                      this.user.email != null
                          ? this.user.email
                          : "",
                      style: kSubTitlesSubsStyle.copyWith(
                          color: Colors.grey)),
                  SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('registered-since'),
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor),
                          ),
                          Text(
                            this.user.metadata.creationTime != null
                                ? this
                                .user
                                .metadata
                                .creationTime
                                .toString()
                                .substring(0, 10)
                                : '',
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('last-signin'),
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor),
                          ),
                          Text(
                            user.metadata.lastSignInTime != null
                                ? user.metadata.lastSignInTime
                                .toString()
                                .substring(0, 10)
                                : '',
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('signin-provider'),
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor),
                          ),
                          Text(
                            user.providerData[0].providerId ==
                                "google.com"
                                ? "Google"
                                : "Apple",
                            style: kSubTitlesSubsStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ));
  }
}