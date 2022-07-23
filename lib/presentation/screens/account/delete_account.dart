import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class DeleteAccountSheet {
  static void openConfirmDeleteAccountMessage(
      BuildContext context, AccountBloc bloc) {
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
                  onTap: () async {
                    final db = FirebaseFirestore.instance;
                    final user = FirebaseAuth.instance.currentUser;
                    String uid = user.uid;

                    await db.collection("users").doc(uid).delete().then((_) {
                      context
                          .read<GoogleAuthenticationService>()
                          .deleteAccount();
                      Navigator.pop(context);
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

  static void openDeleteAccountMessage(BuildContext context, AccountBloc bloc) {
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
                            .translate('delete-my-account'),
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
                          .translate('delete-my-account-p'),
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
                  height: 12,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SignInWithAppleButton(onPressed: () async {
                      final appleIdCredential =
                          await SignInWithApple.getAppleIDCredential(
                        scopes: [
                          AppleIDAuthorizationScopes.email,
                          AppleIDAuthorizationScopes.fullName
                        ],
                      );
                      final oAuthProvider = OAuthProvider('apple.com');
                      final credential = oAuthProvider.credential(
                        idToken: appleIdCredential.identityToken,
                        accessToken: appleIdCredential.authorizationCode,
                      );

                      await FirebaseAuth.instance.currentUser
                          .reauthenticateWithCredential(credential)
                          .then((value) {
                        Navigator.pop(context);
                        openConfirmDeleteAccountMessage(context, bloc);
                      });
                    }),
                    SizedBox(
                      height: 8,
                    ),
                    GestureDetector(
                      onTap: () {
                        context
                            .read<GoogleAuthenticationService>()
                            .reauthenticateWithsignInWithGoogle()
                            .then((value) {
                          Navigator.pop(context);
                          openConfirmDeleteAccountMessage(context, bloc);
                        });
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blueAccent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Sign In With Google',
                              style: kSubTitlesStyle.copyWith(
                                  fontWeight: FontWeight.w400,
                                  height: 1,
                                  fontSize: 20,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                ),
              ]));
        });
  }
}
