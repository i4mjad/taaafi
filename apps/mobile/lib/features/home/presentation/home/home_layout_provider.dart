import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeLayoutSettings {
  final Map<String, bool> visibility;
  final List<String> order;
  final bool helpMessageDismissed;

  HomeLayoutSettings({
    required this.visibility,
    required this.order,
    required this.helpMessageDismissed,
  });

  HomeLayoutSettings copyWith({
    Map<String, bool>? visibility,
    List<String>? order,
    bool? helpMessageDismissed,
  }) {
    return HomeLayoutSettings(
      visibility: visibility ?? this.visibility,
      order: order ?? this.order,
      helpMessageDismissed: helpMessageDismissed ?? this.helpMessageDismissed,
    );
  }

  // Helper method to get ordered visible elements
  List<String> getOrderedVisibleElements() {
    return order.where((element) => visibility[element] == true).toList();
  }
}

final homeLayoutProvider =
    StateNotifierProvider<HomeLayoutNotifier, HomeLayoutSettings>((ref) {
  return HomeLayoutNotifier();
});

class HomeLayoutNotifier extends StateNotifier<HomeLayoutSettings> {
  static const List<String> _defaultOrder = [
    'quickAccess',
    'currentStreaks',
    'statistics',
    'calendar',
  ];

  HomeLayoutNotifier()
      : super(HomeLayoutSettings(
          visibility: {
            'quickAccess': true,
            'statistics': true,
            'calendar': true,
            'currentStreaks': true,
          },
          order: _defaultOrder,
          helpMessageDismissed: false,
        )) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load visibility settings
    final quickAccess = prefs.getBool('home_quick_access_visible') ?? true;
    final statistics = prefs.getBool('home_statistics_visible') ?? true;
    final calendar = prefs.getBool('home_calendar_visible') ?? true;
    final currentStreaks =
        prefs.getBool('home_current_streaks_visible') ?? true;

    // Load order settings
    final orderString =
        prefs.getStringList('home_elements_order') ?? _defaultOrder;

    // Load help message dismissed state
    final helpDismissed = prefs.getBool('home_help_message_dismissed') ?? false;

    state = HomeLayoutSettings(
      visibility: {
        'quickAccess': quickAccess,
        'statistics': statistics,
        'calendar': calendar,
        'currentStreaks': currentStreaks,
      },
      order: orderString,
      helpMessageDismissed: helpDismissed,
    );
  }

  Future<void> toggleVisibility(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_${key}_visible', value);

    state = state.copyWith(
      visibility: {
        ...state.visibility,
        key: value,
      },
    );
  }

  Future<void> reorderElements(List<String> newOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('home_elements_order', newOrder);

    state = state.copyWith(order: newOrder);
  }

  Future<void> dismissHelpMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_help_message_dismissed', true);

    state = state.copyWith(helpMessageDismissed: true);
  }

  Future<void> resetToDefaultOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('home_elements_order', _defaultOrder);

    state = state.copyWith(order: _defaultOrder);
  }

  // Helper method to get ordered visible elements
  List<String> getOrderedVisibleElements() {
    return state.order
        .where((element) => state.visibility[element] == true)
        .toList();
  }
}
