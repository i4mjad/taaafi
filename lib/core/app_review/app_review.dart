import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/utils/url_launcher_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_review.g.dart';

@riverpod
InAppReview inAppReview(InAppReviewRef ref) {
  return InAppReview.instance;
}

class InAppRatingService {
  const InAppRatingService(this.ref);
  final Ref ref;

  // * Used to show the prompt
  InAppReview get _inAppReview => ref.read(inAppReviewProvider);

  /// Requests a review if certain conditions are met
  Future<void> requestReview(BuildContext context) async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      if (Platform.isIOS) {
        await _inAppReview.openStoreListing(
          appStoreId: '6450408345',
        );
      } else {
        await ref.read(urlLauncherProvider).launch(Uri.parse(
            'https://play.google.com/store/apps/details?id=com.amjadkhalfan.reboot_app_3&hl=ar'));
      }
    }
  }
}

@riverpod
InAppRatingService inAppRatingService(InAppRatingServiceRef ref) {
  return InAppRatingService(ref);
}
