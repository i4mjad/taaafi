import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_segmented_button.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_screen.dart';
import 'community_chats_screen.dart';

/// Tabbed screen that shows Groups and Chats tabs
/// Note: This screen is displayed by GroupsMainScreen when user is in a group.
/// Status changes are handled by the parent GroupsMainScreen reactively.
class GroupsChatsTabbedScreen extends ConsumerStatefulWidget {
  const GroupsChatsTabbedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GroupsChatsTabbedScreen> createState() =>
      _GroupsChatsTabbedScreenState();
}

class _GroupsChatsTabbedScreenState
    extends ConsumerState<GroupsChatsTabbedScreen> {
  late SegmentedButtonOption _selectedOption;
  late List<SegmentedButtonOption> _options;

  @override
  void initState() {
    super.initState();
    _options = [
      SegmentedButtonOption(value: 'groups', translationKey: 'groups'),
      SegmentedButtonOption(value: 'chats', translationKey: 'community-chats'),
    ];
    _selectedOption = _options[0];
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final selectedIndex = _options.indexOf(_selectedOption);

    return GroupScreen();
  }
}
