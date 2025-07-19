import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';

class AvatarWithAnonymity extends ConsumerWidget {
  final String cpId;
  final bool isAnonymous;
  final double size;
  final String? avatarUrl;

  const AvatarWithAnonymity({
    super.key,
    required this.cpId,
    required this.isAnonymous,
    this.size = 40,
    this.avatarUrl,
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
          : avatarUrl != null && avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to default avatar if image fails to load
                      return Container(
                        color: theme.primary[100],
                        child: Icon(
                          LucideIcons.user,
                          size: size * 0.6,
                          color: theme.primary[600],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: theme.primary[100],
                        child: Center(
                          child: SizedBox(
                            width: size * 0.4,
                            height: size * 0.4,
                            child: Spinner(
                              strokeWidth: 2,
                              valueColor: theme.primary[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
