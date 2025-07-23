import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultLayoutSettings {
  final Map<String, bool> vaultElementsVisibility;
  final List<String> vaultElementsOrder;
  final Map<String, bool> cardsVisibility;
  final List<String> cardsOrder;
  final bool helpMessageDismissed;

  VaultLayoutSettings({
    required this.vaultElementsVisibility,
    required this.vaultElementsOrder,
    required this.cardsVisibility,
    required this.cardsOrder,
    required this.helpMessageDismissed,
  });

  VaultLayoutSettings copyWith({
    Map<String, bool>? vaultElementsVisibility,
    List<String>? vaultElementsOrder,
    Map<String, bool>? cardsVisibility,
    List<String>? cardsOrder,
    bool? helpMessageDismissed,
  }) {
    return VaultLayoutSettings(
      vaultElementsVisibility:
          vaultElementsVisibility ?? this.vaultElementsVisibility,
      vaultElementsOrder: vaultElementsOrder ?? this.vaultElementsOrder,
      cardsVisibility: cardsVisibility ?? this.cardsVisibility,
      cardsOrder: cardsOrder ?? this.cardsOrder,
      helpMessageDismissed: helpMessageDismissed ?? this.helpMessageDismissed,
    );
  }

  List<String> getOrderedVisibleVaultElements() {
    return vaultElementsOrder
        .where((element) => vaultElementsVisibility[element] == true)
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
  static const List<String> _defaultVaultElementsOrder = [
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
          vaultElementsVisibility: {
            'currentStreaks': true,
            'statistics': true,
            'calendar': true,
          },
          vaultElementsOrder: _defaultVaultElementsOrder,
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

    // Load vault elements visibility
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
    final vaultElementsOrderString =
        prefs.getStringList('vault_vault_elements_order') ??
            _defaultVaultElementsOrder;
    final cardsOrderString =
        prefs.getStringList('vault_cards_order') ?? _defaultCardsOrder;

    // Load help message dismissed state
    final helpDismissed =
        prefs.getBool('vault_help_message_dismissed') ?? false;

    state = VaultLayoutSettings(
      vaultElementsVisibility: {
        'currentStreaks': currentStreaks,
        'statistics': statistics,
        'calendar': calendar,
      },
      vaultElementsOrder: vaultElementsOrderString,
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

    state = state.copyWith(
      vaultElementsOrder: _defaultVaultElementsOrder,
      cardsOrder: _defaultCardsOrder,
    );
  }
}
