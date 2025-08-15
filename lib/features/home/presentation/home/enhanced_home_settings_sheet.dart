import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/presentation/home/home_layout_provider.dart';

class EnhancedHomeSettingsSheet extends ConsumerStatefulWidget {
  const EnhancedHomeSettingsSheet({super.key});

  @override
  _EnhancedHomeSettingsSheetState createState() =>
      _EnhancedHomeSettingsSheetState();
}

class _EnhancedHomeSettingsSheetState
    extends ConsumerState<EnhancedHomeSettingsSheet> {
  late List<String> _orderedElements;

  final Map<String, IconData> _elementIcons = {
    'quickAccess': LucideIcons.layoutGrid,
    'currentStreaks': LucideIcons.timer,
    'statistics': LucideIcons.barChart2,
    'calendar': LucideIcons.calendar,
  };

  final Map<String, String> _elementTitleKeys = {
    'quickAccess': 'quick-access',
    'currentStreaks': 'current-streaks',
    'statistics': 'statistics',
    'calendar': 'calendar',
  };

  final Map<String, String> _elementDescriptionKeys = {
    'quickAccess': 'quick-access-description',
    'currentStreaks': 'current-streaks-description',
    'statistics': 'statistics-description',
    'calendar': 'calendar-description',
  };

  @override
  void initState() {
    super.initState();
    final homeLayoutSettings = ref.read(homeLayoutProvider);
    _orderedElements = List.from(homeLayoutSettings.order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final homeLayoutSettings = ref.watch(homeLayoutProvider);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('home-layout-settings'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  LucideIcons.xCircle,
                  color: theme.grey[900],
                ),
              )
            ],
          ),
          verticalSpace(Spacing.points16),

          // Instructions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('drag-to-reorder'),
                      style: TextStyles.body.copyWith(color: theme.grey[600]),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      AppLocalizations.of(context)
                          .translate('tap-to-toggle-visibility'),
                      style:
                          TextStyles.footnote.copyWith(color: theme.grey[400]),
                    ),
                  ],
                ),
              ),
              horizontalSpace(Spacing.points8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(homeLayoutProvider.notifier).resetToDefaultOrder();
                  // Update local state to reflect the reset
                  setState(() {
                    _orderedElements = List.from([
                      'quickAccess',
                      'currentStreaks',
                      'statistics',
                      'calendar'
                    ]);
                  });
                },
                child: WidgetsContainer(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: theme.backgroundColor,
                  borderSide: BorderSide(color: theme.primary[600]!, width: 1),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.rotateCcw,
                        size: 14,
                        color: theme.primary[600],
                      ),
                      horizontalSpace(Spacing.points4),
                      Text(
                        AppLocalizations.of(context).translate('reset-order'),
                        style: TextStyles.small.copyWith(
                          color: theme.primary[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),

          // Reorderable list
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              itemCount: _orderedElements.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                setState(() {
                  final item = _orderedElements.removeAt(oldIndex);
                  _orderedElements.insert(newIndex, item);
                });
                ref
                    .read(homeLayoutProvider.notifier)
                    .reorderElements(_orderedElements);
              },
              itemBuilder: (context, index) {
                final element = _orderedElements[index];
                final isVisible =
                    homeLayoutSettings.visibility[element] ?? false;

                return Container(
                  key: ValueKey(element),
                  margin: EdgeInsets.only(bottom: 8),
                  child: IntrinsicHeight(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(homeLayoutProvider.notifier).toggleVisibility(
                              element,
                              !isVisible,
                            );
                      },
                      child: WidgetsContainer(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor:
                            isVisible ? theme.success[50] : theme.grey[50],
                        borderSide: BorderSide(
                          color: isVisible
                              ? theme.success[600]!
                              : theme.grey[200]!,
                          width: 1,
                        ),
                        child: Row(
                          children: [
                            // Drag handle
                            Container(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                LucideIcons.gripVertical,
                                size: 16,
                                color: theme.grey[400],
                              ),
                            ),
                            horizontalSpace(Spacing.points8),

                            // Element content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _elementIcons[element]!,
                                        size: 16,
                                        color: isVisible
                                            ? theme.success[600]
                                            : theme.grey[600],
                                      ),
                                      horizontalSpace(Spacing.points8),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .translate(
                                                  _elementTitleKeys[element]!),
                                          style: TextStyles.caption.copyWith(
                                            color: isVisible
                                                ? theme.success[600]
                                                : theme.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  verticalSpace(Spacing.points8),
                                  Text(
                                    AppLocalizations.of(context).translate(
                                        _elementDescriptionKeys[element]!),
                                    style: TextStyles.small.copyWith(
                                      color: isVisible
                                          ? theme.success[400]
                                          : theme.grey[400],
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Visibility indicator
                            Icon(
                              isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                              size: 16,
                              color: isVisible
                                  ? theme.success[600]
                                  : theme.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          verticalSpace(Spacing.points16),

          // Close button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            child: WidgetsContainer(
              backgroundColor: theme.primary[600],
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('close'),
                  style: TextStyles.h6.copyWith(color: theme.grey[50]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
