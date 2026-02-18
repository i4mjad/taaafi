import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

enum ChatTextSize {
  small(0),
  medium(1),
  large(2);

  const ChatTextSize(this.value);

  final int value;

  TextStyle get textStyle {
    switch (this) {
      case ChatTextSize.small:
        return TextStyles.small; // 12px
      case ChatTextSize.medium:
        return TextStyles.caption; // 13px
      case ChatTextSize.large:
        return TextStyles.footnote; // 14px
    }
  }

  double get fontSize => textStyle.fontSize!;

  static ChatTextSize fromIndex(int index) {
    switch (index) {
      case 0:
        return ChatTextSize.small;
      case 1:
        return ChatTextSize.medium;
      case 2:
        return ChatTextSize.large;
      default:
        return ChatTextSize.medium; // Default
    }
  }
}

class ChatTextSizeNotifier extends StateNotifier<ChatTextSize> {
  ChatTextSizeNotifier() : super(ChatTextSize.medium) {
    _loadSelectedTextSize();
  }

  static const String _key = "chat_text_size";

  Future<void> _loadSelectedTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 1; // Default to medium (index 1)
    state = ChatTextSize.fromIndex(index);
  }

  Future<void> setTextSize(ChatTextSize textSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, textSize.value);
    state = textSize;
  }
}

final chatTextSizeProvider =
    StateNotifierProvider<ChatTextSizeNotifier, ChatTextSize>((ref) {
  return ChatTextSizeNotifier();
});
