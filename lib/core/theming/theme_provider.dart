import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

final customThemeProvider = ChangeNotifierProvider<CustomTheme>((ref) {
  return CustomTheme();
});
