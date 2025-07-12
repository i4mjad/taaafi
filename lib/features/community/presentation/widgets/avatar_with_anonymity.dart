import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class AvatarWithAnonymity extends ConsumerWidget {
  final String cpId;
  final bool isAnonymous;
  final double size;

  const AvatarWithAnonymity({
    super.key,
    required this.cpId,
    required this.isAnonymous,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAnonymous ? theme.grey[400] : theme.primary[100],
      ),
      child: isAnonymous
          ? Icon(
              LucideIcons.user,
              size: size * 0.6,
              color: theme.grey[600],
            )
          : ClipOval(
              child: Container(
                color: theme.primary[100],
                child: Icon(
                  LucideIcons.user,
                  size: size * 0.6,
                  color: theme.primary[600],
                ),
              ),
            ),
    );
  }
}
