import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultLayoutSettings {
  final Map<String, bool> vaultElementsVisibility;
  final List<String> vaultElementsOrder;
  final Map<String, bool> cardsVisibility;
  final List<String> cardsOrder;
  final Map<String, bool> analyticsVisibility;
  final List<String> analyticsOrder;
  final bool helpMessageDismissed;

  VaultLayoutSettings({
    required this.vaultElementsVisibility,
    required this.vaultElementsOrder,
    required this.cardsVisibility,
    required this.cardsOrder,
    required this.analyticsVisibility,
    required this.analyticsOrder,
    required this.helpMessageDismissed,
  });

  VaultLayoutSettings copyWith({
    Map<String, bool>? vaultElementsVisibility,
    List<String>? vaultElementsOrder,
    Map<String, bool>? cardsVisibility,
    List<String>? cardsOrder,
    Map<String, bool>? analyticsVisibility,
    List<String>? analyticsOrder,
    bool? helpMessageDismissed,
  }) {
    return VaultLayoutSettings(
      vaultElementsVisibility:
          vaultElementsVisibility ?? this.vaultElementsVisibility,
      vaultElementsOrder: vaultElementsOrder ?? this.vaultElementsOrder,
      cardsVisibility: cardsVisibility ?? this.cardsVisibility,
      cardsOrder: cardsOrder ?? this.cardsOrder,
      analyticsVisibility: analyticsVisibility ?? this.analyticsVisibility,
      analyticsOrder: analyticsOrder ?? this.analyticsOrder,
      helpMessageDismissed: helpMessageDismissed ?? this.helpMessageDismissed,
    );
  }

  List<String> getOrderedVisibleVaultElements() {
    // Define locked elements that should always be shown
    final lockedElements = {
      'streakAverages',
      'heatMapCalendar',
      'triggerRadar',
      'riskClock',
      'moodCorrelation',
    };

    return vaultElementsOrder
        .where((element) =>
            // Always show locked elements (they'll be displayed as locked in UI)
            lockedElements.contains(element) ||
            // Show non-locked elements only if visible
            vaultElementsVisibility[element] == true)
        .toList();
  }

  List<String> getOrderedVisibleCards() {
    return cardsOrder
        .where((element) => cardsVisibility[element] == true)
        .toList();
  }

  List<String> getOrderedVisibleAnalytics() {
    return analyticsOrder
        .where((element) => analyticsVisibility[element] == true)
        .toList();
  }
}

final vaultLayoutProvider =
    StateNotifierProvider<VaultLayoutNotifier, VaultLayoutSettings>((ref) {
  return VaultLayoutNotifier();
});

class VaultLayoutNotifier extends StateNotifier<VaultLayoutSettings> {
  static const List<String> _defaultVaultElementsOrder = [
    'currentStreaks',
    'streakAverages',
    'statistics',
    'riskClock',
    'calendar',
    'heatMapCalendar',
    'triggerRadar',
    'moodCorrelation',
  ];

  static const List<String> _defaultCardsOrder = [
    'activities',
    'library',
    'diaries',
    'messagingGroups',
  ];

  static const List<String> _defaultAnalyticsOrder = [
    'streakAverages',
    'heatMapCalendar',
    'triggerRadar',
    'riskClock',
    'moodCorrelation',
  ];

  VaultLayoutNotifier()
      : super(VaultLayoutSettings(
          vaultElementsVisibility: {
            'currentStreaks': true,
            'statistics': true,
            'calendar': true,
            'streakAverages': true,
            'heatMapCalendar': true,
            'triggerRadar': true,
            'riskClock': true,
            'moodCorrelation': true,
          },
          vaultElementsOrder: _defaultVaultElementsOrder,
          cardsVisibility: {
            'activities': true,
            'library': true,
            'diaries': true,
            'messagingGroups': true,
          },
          cardsOrder: _defaultCardsOrder,
          analyticsVisibility: {
            'streakAverages': true,
            'heatMapCalendar': true,
            'triggerRadar': true,
            'riskClock': true,
            'moodCorrelation': true,
          },
          analyticsOrder: _defaultAnalyticsOrder,
          helpMessageDismissed: false,
        )) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load vault elements visibility
    final currentStreaks =
        prefs.getBool('vault_current_streaks_visible') ?? true;
    final statistics = prefs.getBool('vault_statistics_visible') ?? true;
    final calendar = prefs.getBool('vault_calendar_visible') ?? true;

    // Load cards visibility
    final activities = prefs.getBool('vault_card_activities_visible') ?? true;
    final library = prefs.getBool('vault_card_library_visible') ?? true;
    final diaries = prefs.getBool('vault_card_diaries_visible') ?? true;
    final messagingGroups =
        prefs.getBool('vault_card_messagingGroups_visible') ?? true;

    // Load analytics visibility (now part of vault elements, use same key format)
    final streakAverages =
        prefs.getBool('vault_streakAverages_visible') ?? true;
    final heatMapCalendar =
        prefs.getBool('vault_heatMapCalendar_visible') ?? true;
    final triggerRadar = prefs.getBool('vault_triggerRadar_visible') ?? true;
    final riskClock = prefs.getBool('vault_riskClock_visible') ?? true;
    final moodCorrelation =
        prefs.getBool('vault_moodCorrelation_visible') ?? true;

    // Load orders
    final vaultElementsOrderString =
        prefs.getStringList('vault_vault_elements_order') ??
            _defaultVaultElementsOrder;

    // Check if stored cards order needs migration (add messagingGroups if missing)
    final storedCardsOrder = prefs.getStringList('vault_cards_order');
    final cardsOrderString = (storedCardsOrder == null ||
            !storedCardsOrder.contains('messagingGroups'))
        ? _defaultCardsOrder // Use default if no stored order or missing messagingGroups
        : storedCardsOrder;

    final analyticsOrderString =
        prefs.getStringList('vault_analytics_order') ?? _defaultAnalyticsOrder;

    // Load help message dismissed state
    final helpDismissed =
        prefs.getBool('vault_help_message_dismissed') ?? false;

    // Simple merge: Start with stored order, then add any missing elements from defaults
    final finalVaultElementsOrder = List<String>.from(vaultElementsOrderString);
    for (final element in _defaultVaultElementsOrder) {
      if (!finalVaultElementsOrder.contains(element)) {
        finalVaultElementsOrder.add(element);
      }
    }

    // Same merge logic for cards order to ensure new cards are added to existing users
    final finalCardsOrder = List<String>.from(cardsOrderString);
    for (final card in _defaultCardsOrder) {
      if (!finalCardsOrder.contains(card)) {
        finalCardsOrder.add(card);
      }
    }

    state = VaultLayoutSettings(
      vaultElementsVisibility: {
        'currentStreaks': currentStreaks,
        'statistics': statistics,
        'calendar': calendar,
        // Add analytics elements to vault elements visibility
        'streakAverages': streakAverages,
        'heatMapCalendar': heatMapCalendar,
        'triggerRadar': triggerRadar,
        'riskClock': riskClock,
        'moodCorrelation': moodCorrelation,
      },
      vaultElementsOrder: finalVaultElementsOrder,
      cardsVisibility: {
        'activities': activities,
        'library': library,
        'diaries': diaries,
        'messagingGroups': messagingGroups,
      },
      cardsOrder: finalCardsOrder,
      analyticsVisibility: {
        'streakAverages': streakAverages,
        'heatMapCalendar': heatMapCalendar,
        'triggerRadar': triggerRadar,
        'riskClock': riskClock,
        'moodCorrelation': moodCorrelation,
      },
      analyticsOrder: analyticsOrderString,
      helpMessageDismissed: helpDismissed,
    );
  }

  Future<void> toggleVaultElementVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vault_${key}_visible', value);

    state = state.copyWith(
      vaultElementsVisibility: {
        ...state.vaultElementsVisibility,
        key: value,
      },
    );
  }

  Future<void> toggleCardVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vault_card_${key}_visible', value);

    state = state.copyWith(
      cardsVisibility: {
        ...state.cardsVisibility,
        key: value,
      },
    );
  }

  Future<void> toggleAnalyticsVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vault_analytics_${key}_visible', value);

    state = state.copyWith(
      analyticsVisibility: {
        ...state.analyticsVisibility,
        key: value,
      },
    );
  }

  Future<void> reorderVaultElements(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vault_vault_elements_order', newOrder);

    state = state.copyWith(vaultElementsOrder: newOrder);
  }

  Future<void> reorderCards(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vault_cards_order', newOrder);

    state = state.copyWith(cardsOrder: newOrder);
  }

  Future<void> reorderAnalytics(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vault_analytics_order', newOrder);

    state = state.copyWith(analyticsOrder: newOrder);
  }

  Future<void> dismissHelpMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vault_help_message_dismissed', true);

    state = state.copyWith(helpMessageDismissed: true);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'vault_vault_elements_order', _defaultVaultElementsOrder);
    await prefs.setStringList('vault_cards_order', _defaultCardsOrder);
    await prefs.setStringList('vault_analytics_order', _defaultAnalyticsOrder);

    state = state.copyWith(
      vaultElementsOrder: _defaultVaultElementsOrder,
      cardsOrder: _defaultCardsOrder,
      analyticsOrder: _defaultAnalyticsOrder,
    );
  }
}
