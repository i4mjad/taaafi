import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/shared_widgets/account_action_banner.dart';

/// Banner that asks the user to review and confirm missing profile details.
/// This is now a simple wrapper around AccountActionBanner for backwards compatibility.
class ConfirmDetailsBanner extends ConsumerWidget {
  const ConfirmDetailsBanner({
    this.isFullScreen = false,
    super.key,
  });

  final bool isFullScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AccountActionBanner(isFullScreen: isFullScreen);
  }
}
