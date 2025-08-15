import 'package:android_intent_plus/android_intent.dart';

Future<void> openUsageAccessSettings() async {
  final intent =
      const AndroidIntent(action: 'android.settings.USAGE_ACCESS_SETTINGS');
  await intent.launch();
}
