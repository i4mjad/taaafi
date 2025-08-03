import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/features/community/presentation/widgets/plus_badge_widget.dart';

class AvatarWithAnonymity extends ConsumerWidget {
  final String cpId;
  final bool isAnonymous;
  final double size;
  final String? avatarUrl;
  final bool isPlusUser;

  const AvatarWithAnonymity({
    super.key,
    required this.cpId,
    required this.isAnonymous,
    required this.isPlusUser,
    this.size = 40,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    print(
        'DEBUG: AvatarWithAnonymity - cpId: $cpId, isAnonymous: $isAnonymous, avatarUrl: $avatarUrl, isPlusUser: $isPlusUser');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isPlusUser
            ? Border.all(
                color: plusColor,
                width: 2.5,
              )
            : null,
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
                  child: Container(
                    margin: isPlusUser
                        ? const EdgeInsets.all(2.5)
                        : EdgeInsets.zero,
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        width: size - (isPlusUser ? 5 : 0),
                        height: size - (isPlusUser ? 5 : 0),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to default avatar if image fails to load
                          print(
                              'DEBUG: AvatarWithAnonymity - Image load error for cpId: $cpId, avatarUrl: $avatarUrl, error: $error');
                          return Container(
                            color: theme.primary[100],
                            child: Icon(
                              LucideIcons.user,
                              size: (size - (isPlusUser ? 5 : 0)) * 0.6,
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
                                width: (size - (isPlusUser ? 5 : 0)) * 0.4,
                                height: (size - (isPlusUser ? 5 : 0)) * 0.4,
                                child: Spinner(
                                  strokeWidth: 2,
                                  valueColor: theme.primary[600],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              : Container(
                  margin:
                      isPlusUser ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
                  child: ClipOval(
                    child: Container(
                      width: size - (isPlusUser ? 5 : 0),
                      height: size - (isPlusUser ? 5 : 0),
                      color: theme.primary[100],
                      child: Icon(
                        LucideIcons.user,
                        size: (size - (isPlusUser ? 5 : 0)) * 0.6,
                        color: theme.primary[600],
                      ),
                    ),
                  ),
                ),
    );
  }
}
