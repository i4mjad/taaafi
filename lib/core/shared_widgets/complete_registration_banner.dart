import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';

/// Banner that asks the user to finish creating their account.
/// This is now a simple wrapper around AccountActionBanner for backwards compatibility.
class CompleteRegistrationBanner extends ConsumerWidget {
  const CompleteRegistrationBanner({
    this.isFullScreen = false,
    super.key,
  });

  final bool isFullScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AccountActionBanner(isFullScreen: isFullScreen);
  }
}
