

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

//TODO The logic of reseting account data needed to be reviewed since the plan is to change the logic of FollowYourReboot
class ResetAccountSheet {

  static void showResetSheet(BuildContext context) async {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                          color: primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50)),
                      child: Center(
                        child: Icon(
                          Iconsax.refresh_circle,
                          color: primaryColor,
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
                                .translate('delete-my-data'),
                            style: kPageTitleStyle.copyWith(
                                fontSize: 24, color: primaryColor),
                          ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('delete-my-data-p'),
                          textAlign: TextAlign.center,
                          style: kSubTitlesSubsStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('delete-my-data-warning'),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ))
                    ],
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Beginning from last relapse
                    GestureDetector(
                      onTap: () async {
                        //start from last relapse
                        _selectDate(context);
                        //Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('start-from-specific-date'),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    //New Beginning
                    GestureDetector(
                      onTap: () async {
                        deleteUserData(DateTime.now(), context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('new-begining'),
                            style: kSubTitlesStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        });
  }

 static _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked.isBefore(DateTime.now())) {
      deleteUserData(picked, context);
    }
  }

  static void deleteUserData(DateTime date, BuildContext context) async {

    final FirebaseAuth auth = FirebaseAuth.instance;
    User user = auth.currentUser;
    FirebaseFirestore database = FirebaseFirestore.instance;
    // set up the button
    Widget yesButton = TextButton(
      child: Text(
        AppLocalizations.of(context)
            .translate('delete-user-dialog-confirm-button'),
        style: kSubTitlesStyle.copyWith(
            color: Colors.deepOrangeAccent, fontSize: 18),
      ),
      onPressed: () {
        database
            .collection("users")
            .doc(user.uid)
            .update({"resetedDate": date, "email": user.email});

        Navigator.pop(context);
      },
    );

    Widget noButton = TextButton(
      child: Text(
        AppLocalizations.of(context)
            .translate('delete-user-dialog-back-button'),
        style: kSubTitlesStyle.copyWith(color: Colors.grey, fontSize: 18),
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('delete-user-dialog-title'),
        style: kSubTitlesStyle.copyWith(color: primaryColor, fontSize: 20),
      ),
      content: Text(
          AppLocalizations.of(context).translate('delete-user-dialog-content'),
          style: kSubTitlesStyle.copyWith(color: Colors.black, fontSize: 20)),
      actions: [
        yesButton,
        noButton,
      ],
    );

    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
