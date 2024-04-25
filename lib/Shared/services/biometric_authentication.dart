import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as local_auth_error;
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthentication extends StatefulWidget {
  const BiometricAuthentication({Key? key}) : super(key: key);

  @override
  State<BiometricAuthentication> createState() =>
      _BiometricAuthenticationState();
}

class _BiometricAuthenticationState extends State<BiometricAuthentication> {
  final _localAuthentication = LocalAuthentication();
  bool _isUserAuthorized = false;

  Future<void> authenticateUser() async {
    bool isAuthorized = false;
    try {
      isAuthorized = await _localAuthentication.authenticate(
          localizedReason: "Please authenticate to see account balance",
          options: AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: false,
          ));
    } on PlatformException catch (exception) {
      if (exception.code == local_auth_error.notAvailable ||
          exception.code == local_auth_error.passcodeNotSet ||
          exception.code == local_auth_error.notEnrolled) {
        // Handle this exception here.
      }
    }

    if (!mounted) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isAppLockEnabled", isAuthorized);
    setState(() {
      _isUserAuthorized = prefs.getBool("isAppLockEnabled") as bool;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithCustomTitle(context, "welcome"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _isUserAuthorized
                ? const Text("Authentication successful!!!")
                : TextButton(
                    onPressed: authenticateUser,
                    child: const Text(
                      "Authorize now",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.lightBlueAccent),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
