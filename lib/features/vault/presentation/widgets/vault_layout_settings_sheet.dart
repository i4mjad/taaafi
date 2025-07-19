import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_layout_provider.dart';

class VaultLayoutSettingsSheet extends ConsumerStatefulWidget {
  const VaultLayoutSettingsSheet({super.key});

  @override
  _VaultLayoutSettingsSheetState createState() =>
      _VaultLayoutSettingsSheetState();
}

class _VaultLayoutSettingsSheetState
    extends ConsumerState<VaultLayoutSettingsSheet> {
  late List<String> _orderedHomeElements;
  late List<String> _orderedCards;

  final Map<String, IconData> _homeElementIcons = {
    'todayTasks': LucideIcons.clipboardCheck,
    'currentStreaks': LucideIcons.timer,
    'statistics': LucideIcons.barChart2,
    'calendar': LucideIcons.calendar,
  };

  final Map<String, String> _homeElementTitleKeys = {
    'todayTasks': 'today-tasks',
    'currentStreaks': 'current-streaks',
    'statistics': 'statistics',
    'calendar': 'calendar',
  };

  final Map<String, String> _homeElementDescriptionKeys = {
    'todayTasks':
        'activities-description', // Using existing activities description
    'currentStreaks': 'current-streaks-description',
    'statistics': 'statistics-description',
    'calendar': 'calendar-description',
  };

  final Map<String, IconData> _cardIcons = {
    'activities': LucideIcons.clipboardCheck,
    'library': LucideIcons.lamp,
    'diaries': LucideIcons.pencil,
    'notifications': LucideIcons.bell,
    'settings': LucideIcons.settings,
  };

  final Map<String, String> _cardTitleKeys = {
    'activities': 'activities',
    'library': 'library',
    'diaries': 'diaries',
    'notifications': 'notifications',
    'settings': 'settings',
  };

  final Map<String, String> _cardDescriptionKeys = {
    'activities': 'activities-description',
    'library': 'library-description',
    'diaries': 'diaries-description',
    'notifications':
        'no-notifications-description', // Using existing notification description
    'settings':
        'home-layout-description', // Using existing layout settings description
  };

  Map<String, Map<String, Color>> _getCardThemeColors(CustomThemeData theme) {
    return {
      'activities': {
        'icon': theme.primary[500]!,
        'background': theme.primary[50]!,
      },
      'library': {
        'icon': theme.secondary[500]!,
        'background': theme.secondary[50]!,
      },
      'diaries': {
        'icon': theme.tint[500]!,
        'background': theme.tint[50]!,
      },
      'notifications': {
        'icon': theme.warn[500]!,
        'background': theme.warn[50]!,
      },
      'settings': {
        'icon': theme.grey[500]!,
        'background': theme.grey[50]!,
      },
    };
  }

  @override
  void initState() {
    super.initState();
    final vaultLayoutSettings = ref.read(vaultLayoutProvider);
    _orderedHomeElements = List.from(vaultLayoutSettings.homeElementsOrder);
    _orderedCards = List.from(vaultLayoutSettings.cardsOrder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final vaultLayoutSettings = ref.watch(vaultLayoutProvider);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('home-layout-settings'),
                      style: TextStyles.h5.copyWith(color: theme.grey[900]),
                    ),
                  ),
                  horizontalSpace(Spacing.points8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(vaultLayoutProvider.notifier).resetToDefaults();
                      setState(() {
                        _orderedHomeElements = List.from([
                          'todayTasks',
                          'currentStreaks',
                          'statistics',
                          'calendar'
                        ]);
                        _orderedCards = List.from([
                          'activities',
                          'library',
                          'diaries',
                          'notifications',
                          'settings'
                        ]);
                      });
                    },
                    child: WidgetsContainer(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: theme.backgroundColor,
                      borderSide:
                          BorderSide(color: theme.primary[600]!, width: 1),
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
                            AppLocalizations.of(context)
                                .translate('reset-order'),
                            style: TextStyles.small.copyWith(
                              color: theme.primary[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  horizontalSpace(Spacing.points8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: theme.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            verticalSpace(Spacing.points16),

            // Combined sections
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Access Cards Section
                    Text(
                      AppLocalizations.of(context).translate('quick-access'),
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    verticalSpace(Spacing.points8),
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
                    verticalSpace(Spacing.points16),

                    // Quick Access Cards Horizontal List
                    _buildHorizontalCardsReorderList(
                        theme, vaultLayoutSettings),

                    // Home Elements Section
                    Text(
                      AppLocalizations.of(context)
                          .translate('home-elements-visibility'),
                      style: TextStyles.h6.copyWith(color: theme.grey[900]),
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      AppLocalizations.of(context)
                          .translate('home-elements-visibility-description'),
                      style:
                          TextStyles.caption.copyWith(color: theme.grey[600]),
                    ),
                    verticalSpace(Spacing.points8),
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
                    verticalSpace(Spacing.points16),

                    // Home Elements List
                    ..._buildHomeElementsItems(theme, vaultLayoutSettings),

                    verticalSpace(Spacing.points32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHomeElementsItems(
      CustomThemeData theme, VaultLayoutSettings settings) {
    return List.generate(_orderedHomeElements.length, (index) {
      final element = _orderedHomeElements[index];
      final isVisible = settings.homeElementsVisibility[element] ?? false;

      return Container(
        key: ValueKey(element),
        margin: EdgeInsets.only(bottom: 8),
        child: IntrinsicHeight(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(vaultLayoutProvider.notifier)
                  .toggleHomeElementVisibility(element, !isVisible);
            },
            child: WidgetsContainer(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: isVisible ? theme.success[50] : theme.grey[50],
              borderSide: BorderSide(
                color: isVisible ? theme.success[600]! : theme.grey[200]!,
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
                              _homeElementIcons[element],
                              size: 16,
                              color: isVisible
                                  ? theme.success[600]
                                  : theme.grey[600],
                            ),
                            horizontalSpace(Spacing.points8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate(_homeElementTitleKeys[element]!),
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
                          AppLocalizations.of(context)
                              .translate(_homeElementDescriptionKeys[element]!),
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
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHorizontalCardsReorderList(
      CustomThemeData theme, VaultLayoutSettings settings) {
    final cardThemeColors = _getCardThemeColors(theme);

    return SizedBox(
      height: 100,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _orderedCards.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          setState(() {
            final item = _orderedCards.removeAt(oldIndex);
            _orderedCards.insert(newIndex, item);
          });
          ref.read(vaultLayoutProvider.notifier).reorderCards(_orderedCards);
        },
        itemBuilder: (context, index) {
          final card = _orderedCards[index];
          final isVisible = settings.cardsVisibility[card] ?? false;
          final cardColors = cardThemeColors[card]!;
          final iconColor = cardColors['icon']!;
          final backgroundColor = cardColors['background']!;

          return Container(
            key: ValueKey(card),
            margin: EdgeInsets.only(right: 8),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(vaultLayoutProvider.notifier)
                        .toggleCardVisibility(card, !isVisible);
                  },
                  child: WidgetsContainer(
                    width: 70,
                    height: 70,
                    padding: EdgeInsets.all(8),
                    backgroundColor:
                        isVisible ? backgroundColor : theme.grey[100],
                    borderSide: BorderSide(
                      color: isVisible
                          ? iconColor.withOpacity(0.3)
                          : theme.grey[200]!,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isVisible
                        ? [
                            BoxShadow(
                              color: iconColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isVisible
                                ? iconColor.withOpacity(0.1)
                                : theme.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _cardIcons[card],
                            size: 18,
                            color: isVisible ? iconColor : theme.grey[400],
                          ),
                        ),
                        verticalSpace(Spacing.points4),
                        Text(
                          AppLocalizations.of(context)
                              .translate(_cardTitleKeys[card]!),
                          style: TextStyles.small.copyWith(
                            color:
                                isVisible ? theme.grey[900] : theme.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                verticalSpace(Spacing.points8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeElementsList(
      CustomThemeData theme, VaultLayoutSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('drag-to-reorder'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context).translate('tap-to-toggle-visibility'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points16),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _orderedHomeElements.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                setState(() {
                  final item = _orderedHomeElements.removeAt(oldIndex);
                  _orderedHomeElements.insert(newIndex, item);
                });
                ref
                    .read(vaultLayoutProvider.notifier)
                    .reorderHomeElements(_orderedHomeElements);
              },
              itemBuilder: (context, index) {
                final element = _orderedHomeElements[index];
                final isVisible =
                    settings.homeElementsVisibility[element] ?? false;

                return Container(
                  key: ValueKey(element),
                  margin: EdgeInsets.only(bottom: 8),
                  child: IntrinsicHeight(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(vaultLayoutProvider.notifier)
                            .toggleHomeElementVisibility(element, !isVisible);
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
                                        _homeElementIcons[element],
                                        size: 16,
                                        color: isVisible
                                            ? theme.success[600]
                                            : theme.grey[600],
                                      ),
                                      horizontalSpace(Spacing.points8),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .translate(_homeElementTitleKeys[
                                                  element]!),
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
                                        _homeElementDescriptionKeys[element]!),
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

                            horizontalSpace(Spacing.points8),
                            // Visibility toggle
                            Icon(
                              isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                              size: 18,
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
        ],
      ),
    );
  }
}
