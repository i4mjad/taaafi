import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/network/connectivity_provider.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

/// A widget that displays a banner when the network connection is lost.
class OfflineIndicator extends ConsumerStatefulWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  ConsumerState<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends ConsumerState<OfflineIndicator> {
  bool _isChecking = false; // Only state needed is for cosmetic refresh
  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Cosmetic refresh action: shows spinner for a fixed time
  void _startCosmeticRefreshCheck() {
    if (!mounted || _isChecking) return;
    if (kDebugMode) {
      print(
          '[_OfflineIndicator] Starting cosmetic refresh check (spinner for 2s)...');
    }
    setState(() {
      _isChecking = true;
    });
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isChecking) {
        if (kDebugMode) {
          print('[_OfflineIndicator] Cosmetic refresh timer finished.');
        }
        setState(() {
          _isChecking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    // Listen to AsyncValue<bool> changes just to reset spinner if needed
    ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) {
      if (_isChecking && next is! AsyncLoading) {
        _refreshTimer?.cancel();
        if (mounted && _isChecking) {
          if (kDebugMode) {
            print(
                '[_OfflineIndicator] Network status updated during cosmetic check. Resetting spinner.');
          }
          setState(() => _isChecking = false);
        }
      }
      // Remove online/offline transition logic from listener
    });

    // Watch the AsyncValue<bool>
    final networkStatus = ref.watch(networkStatusProvider);

    // Determine current online status, default to false if loading/error
    final isCurrentlyOnline =
        networkStatus.maybeWhen(data: (d) => d, orElse: () => false);

    // Determine which banner to show
    if (!isCurrentlyOnline) {
      // Show offline banner
      return _buildBanner(
        context,
        AppLocalizations.of(context).translate('you-are-offline'),
        theme.error[600]!,
        Icons.wifi_off,
        isLoading: _isChecking, // Use local checking state for spinner
        onRefresh: _isChecking ? null : _startCosmeticRefreshCheck,
      );
    } else {
      // Show nothing if online (or loading/error)
      return const SizedBox.shrink();
    }
  }

  Widget _buildBanner(
    BuildContext context,
    String text,
    Color color,
    IconData icon, {
    VoidCallback? onRefresh,
    bool isLoading = false,
  }) {
    final theme = AppTheme.of(context);
    return Material(
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyles.caption.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : (onRefresh != null)
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.refreshCcwDot,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: AppLocalizations.of(context)
                              .translate('refresh_status'),
                          onPressed: onRefresh,
                        )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
