import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class AvatarPicker extends ConsumerStatefulWidget {
  final Function(String?)? onAvatarSelected;

  const AvatarPicker({
    super.key,
    this.onAvatarSelected,
  });

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  String? _selectedAvatar;

  final List<IconData> _avatarIcons = [
    LucideIcons.user,
    LucideIcons.userCheck,
    LucideIcons.userCircle,
    LucideIcons.smile,
    LucideIcons.star,
    LucideIcons.heart,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _avatarIcons.length,
        itemBuilder: (context, index) {
          final icon = _avatarIcons[index];
          final isSelected = _selectedAvatar == icon.toString();

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedAvatar = icon.toString();
              });
              widget.onAvatarSelected?.call(_selectedAvatar);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.primary[100] : theme.grey[100],
                border: Border.all(
                  color: isSelected ? theme.primary[500]! : theme.grey[300]!,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? theme.primary[600] : theme.grey[600],
              ),
            ),
          );
        },
      ),
    );
  }
}
