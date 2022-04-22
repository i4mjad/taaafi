import 'dart:core';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:reboot_app_3/presentation/Screens/auth/login_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';

class DeleteAccountSheet {
  static void openDeleteAccountMessage(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
              padding:
              EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.1,
                      decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(50)),
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50)),
                      child: Center(
                        child: Icon(
                          Iconsax.trash,
                          color: Colors.red,
                        ),
                      ),
                    )
                  ],
                ),
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('confirm-account-delete'),
                            style: kPageTitleStyle.copyWith(
                                fontSize: 24, color: Colors.red),
                          ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('confirm-account-delete-p'),
                          textAlign: TextAlign.center,
                          style: kSubTitlesStyle.copyWith(
                              fontSize: 17,
                              color: Colors.black.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                              height: 1.5),
                        ))
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                GestureDetector(
                  onTap: () {
                    context.read<GoogleAuthenticationService>()
                        .deleteAccount()
                        .then((value) {
                      Navigator.pop(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()));
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12.5)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            AppLocalizations.of(context)
                                .translate("delete-account-button"),
                            style: kSubTitlesStyle.copyWith(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500))
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
              ]));
        });
  }
}