import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/shared/services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    Key key,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.only(top: 100.0, left: 20.0, right: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(40),
                    decoration: BoxDecoration(
                        color: lightPrimaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(150)),
                    child: Icon(
                      Iconsax.user,
                      color: lightPrimaryColor,
                      size: 72,
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('login'),
                        style: kPageTitleStyle.copyWith(
                            fontSize: 32, color: lightPrimaryColor),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            child: Text(
                          AppLocalizations.of(context)
                              .translate("login-button-p"),
                          style: kSubTitlesSubsStyle.copyWith(
                              color: Colors.black45,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ))
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width - 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SignInWithAppleButton(onPressed: () async {
                    final appleIdCredential =
                        await SignInWithApple.getAppleIDCredential(scopes: [
                      AppleIDAuthorizationScopes.email,
                      AppleIDAuthorizationScopes.fullName
                    ]);
                    final oAuthProvider = OAuthProvider('apple.com');
                    final credential = oAuthProvider.credential(
                      idToken: appleIdCredential.identityToken,
                      accessToken: appleIdCredential.authorizationCode,
                    );
                    await FirebaseAuth.instance
                        .signInWithCredential(credential)
                        .then((value) {});
                  }),
                  SizedBox(
                    height: 8,
                  ),
                  GestureDetector(
                    onTap: () {
                      context
                          .read<GoogleAuthenticationService>()
                          .signInWithGoogle();
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
            ),
          ],
        ),
      ),
    ));
  }
}
