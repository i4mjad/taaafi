import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultLayoutSettings {
  final Map<String, bool> homeElementsVisibility;
  final List<String> homeElementsOrder;
  final Map<String, bool> cardsVisibility;
  final List<String> cardsOrder;
  final bool helpMessageDismissed;

  VaultLayoutSettings({
    required this.homeElementsVisibility,
    required this.homeElementsOrder,
    required this.cardsVisibility,
    required this.cardsOrder,
    required this.helpMessageDismissed,
  });

  VaultLayoutSettings copyWith({
    Map<String, bool>? homeElementsVisibility,
    List<String>? homeElementsOrder,
    Map<String, bool>? cardsVisibility,
    List<String>? cardsOrder,
    bool? helpMessageDismissed,
  }) {
    return VaultLayoutSettings(
      homeElementsVisibility:
          homeElementsVisibility ?? this.homeElementsVisibility,
      homeElementsOrder: homeElementsOrder ?? this.homeElementsOrder,
      cardsVisibility: cardsVisibility ?? this.cardsVisibility,
      cardsOrder: cardsOrder ?? this.cardsOrder,
      helpMessageDismissed: helpMessageDismissed ?? this.helpMessageDismissed,
    );
  }

  List<String> getOrderedVisibleHomeElements() {
    return homeElementsOrder
        .where((element) => homeElementsVisibility[element] == true)
        .toList();
  }

  List<String> getOrderedVisibleCards() {
    return cardsOrder
        .where((element) => cardsVisibility[element] == true)
        .toList();
  }
}

final vaultLayoutProvider =
    StateNotifierProvider<VaultLayoutNotifier, VaultLayoutSettings>((ref) {
  return VaultLayoutNotifier();
});

class VaultLayoutNotifier extends StateNotifier<VaultLayoutSettings> {
  static const List<String> _defaultHomeElementsOrder = [
    'currentStreaks',
    'statistics',
    'calendar',
  ];

  static const List<String> _defaultCardsOrder = [
    'activities',
    'library',
    'diaries',
    'notifications',
    'settings',
  ];

  VaultLayoutNotifier()
      : super(VaultLayoutSettings(
          homeElementsVisibility: {
            'currentStreaks': true,
            'statistics': true,
            'calendar': true,
          },
          homeElementsOrder: _defaultHomeElementsOrder,
          cardsVisibility: {
            'activities': true,
            'library': true,
            'diaries': true,
            'notifications': true,
            'settings': true,
          },
          cardsOrder: _defaultCardsOrder,
          helpMessageDismissed: false,
        )) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load home elements visibility
    final currentStreaks =
        prefs.getBool('vault_current_streaks_visible') ?? true;
    final statistics = prefs.getBool('vault_statistics_visible') ?? true;
    final calendar = prefs.getBool('vault_calendar_visible') ?? true;

    // Load cards visibility
    final activities = prefs.getBool('vault_card_activities_visible') ?? true;
    final library = prefs.getBool('vault_card_library_visible') ?? true;
    final diaries = prefs.getBool('vault_card_diaries_visible') ?? true;
    final notifications =
        prefs.getBool('vault_card_notifications_visible') ?? true;
    final settings = prefs.getBool('vault_card_settings_visible') ?? true;

    // Load orders
    final homeElementsOrderString =
        prefs.getStringList('vault_home_elements_order') ??
            _defaultHomeElementsOrder;
    final cardsOrderString =
        prefs.getStringList('vault_cards_order') ?? _defaultCardsOrder;

    // Load help message dismissed state
    final helpDismissed =
        prefs.getBool('vault_help_message_dismissed') ?? false;

    state = VaultLayoutSettings(
      homeElementsVisibility: {
        'currentStreaks': currentStreaks,
        'statistics': statistics,
        'calendar': calendar,
      },
      homeElementsOrder: homeElementsOrderString,
      cardsVisibility: {
        'activities': activities,
        'library': library,
        'diaries': diaries,
        'notifications': notifications,
        'settings': settings,
      },
      cardsOrder: cardsOrderString,
      helpMessageDismissed: helpDismissed,
    );
  }

  Future<void> toggleHomeElementVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vault_${key}_visible', value);

    state = state.copyWith(
      homeElementsVisibility: {
        ...state.homeElementsVisibility,
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

  Future<void> reorderHomeElements(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vault_home_elements_order', newOrder);

    state = state.copyWith(homeElementsOrder: newOrder);
  }

  Future<void> reorderCards(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vault_cards_order', newOrder);

    state = state.copyWith(cardsOrder: newOrder);
  }

  Future<void> dismissHelpMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vault_help_message_dismissed', true);

    state = state.copyWith(helpMessageDismissed: true);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'vault_home_elements_order', _defaultHomeElementsOrder);
    await prefs.setStringList('vault_cards_order', _defaultCardsOrder);

    state = state.copyWith(
      homeElementsOrder: _defaultHomeElementsOrder,
      cardsOrder: _defaultCardsOrder,
    );
  }
}
