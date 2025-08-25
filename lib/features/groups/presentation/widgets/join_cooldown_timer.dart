import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/features/groups/application/groups_controller.dart';
import 'package:reboot_app_3/features/community/presentation/providers/community_providers_new.dart';

class JoinCooldownTimer extends ConsumerStatefulWidget {
  const JoinCooldownTimer({super.key});

  @override
  ConsumerState<JoinCooldownTimer> createState() => _JoinCooldownTimerState();
}

class _JoinCooldownTimerState extends ConsumerState<JoinCooldownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _updateRemainingTime() async {
    final profileAsync = ref.read(currentCommunityProfileProvider);
    final profile = await profileAsync.when(
      data: (profile) async => profile,
      loading: () async => null,
      error: (_, __) async => null,
    );

    if (profile == null) return;

    final nextJoinTime =
        await ref.read(nextJoinAllowedAtProvider(profile.id).future);

    if (nextJoinTime == null) {
      // No cooldown, stop timer
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
      return;
    }

    final now = DateTime.now();
    if (now.isAfter(nextJoinTime)) {
      // Cooldown expired, stop timer
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _remainingTime = Duration.zero;
        });
        // Invalidate providers to refresh UI
        ref.invalidate(canJoinGroupProvider(profile.id));
        ref.invalidate(nextJoinAllowedAtProvider(profile.id));
      }
      return;
    }

    final remaining = nextJoinTime.difference(now);
    if (mounted) {
      setState(() {
        _remainingTime = remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    final profileAsync = ref.watch(currentCommunityProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final canJoinAsync = ref.watch(canJoinGroupProvider(profile.id));
        final nextJoinAsync = ref.watch(nextJoinAllowedAtProvider(profile.id));

        return canJoinAsync.when(
          data: (canJoin) {
            if (canJoin) return const SizedBox.shrink();

            return nextJoinAsync.when(
              data: (nextJoinTime) {
                if (nextJoinTime == null) return const SizedBox.shrink();

                final now = DateTime.now();
                if (now.isAfter(nextJoinTime)) return const SizedBox.shrink();

                return _buildCooldownCard(theme, l10n);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCooldownCard(CustomThemeData theme, AppLocalizations l10n) {
    if (_remainingTime <= Duration.zero) {
      return const SizedBox.shrink();
    }

    return WidgetsContainer(
      backgroundColor: theme.warn[50],
      borderSide: BorderSide(
        color: theme.warn[200]!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.all(Spacing.points16.value),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Spacing.points8.value),
                decoration: BoxDecoration(
                  color: theme.warn[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: theme.warn[600],
                ),
              ),
              horizontalSpace(Spacing.points12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('join-cooldown-active'),
                      style: TextStyles.body.copyWith(
                        color: theme.warn[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      l10n.translate('join-cooldown-description'),
                      style: TextStyles.caption.copyWith(
                        color: theme.warn[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          verticalSpace(Spacing.points16),

          // Countdown Timer
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Spacing.points12.value),
            decoration: BoxDecoration(
              color: theme.warn[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.warn[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n.translate('time-remaining'),
                  style: TextStyles.caption.copyWith(
                    color: theme.warn[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                verticalSpace(Spacing.points8),
                Text(
                  _formatDuration(_remainingTime, l10n),
                  style: TextStyles.h4.copyWith(
                    color: theme.warn[800],
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          verticalSpace(Spacing.points12),

          // Info text
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 14,
                color: theme.warn[600],
              ),
              horizontalSpace(Spacing.points4),
              Expanded(
                child: Text(
                  l10n.translate('join-cooldown-info'),
                  style: TextStyles.caption.copyWith(
                    color: theme.warn[700],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration, AppLocalizations l10n) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      final minutes = duration.inMinutes % 60;

      if (days > 1) {
        return l10n
            .translate('countdown-days-hours-minutes')
            .replaceAll('{days}', days.toString())
            .replaceAll('{hours}', hours.toString().padLeft(2, '0'))
            .replaceAll('{minutes}', minutes.toString().padLeft(2, '0'));
      } else {
        return l10n
            .translate('countdown-day-hours-minutes')
            .replaceAll('{hours}', hours.toString().padLeft(2, '0'))
            .replaceAll('{minutes}', minutes.toString().padLeft(2, '0'));
      }
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;

      return l10n
          .translate('countdown-hours-minutes-seconds')
          .replaceAll('{hours}', hours.toString().padLeft(2, '0'))
          .replaceAll('{minutes}', minutes.toString().padLeft(2, '0'))
          .replaceAll('{seconds}', seconds.toString().padLeft(2, '0'));
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;

      return l10n
          .translate('countdown-minutes-seconds')
          .replaceAll('{minutes}', minutes.toString().padLeft(2, '0'))
          .replaceAll('{seconds}', seconds.toString().padLeft(2, '0'));
    }
  }
}
