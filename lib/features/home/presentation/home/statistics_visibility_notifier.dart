import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  final SharedPreferences _prefs;

  StatisticsVisibilityNotifier(this._prefs)
      : super({
          'relapse': true,
          'pornOnly': true,
          'mastOnly': true,
          'slipUp': true,
        }) {
    _loadPreferences();
  }

  void _loadPreferences() {
    state = {
      'relapse': _prefs.getBool(_keyRelapseVisible) ?? true,
      'pornOnly': _prefs.getBool(_keyPornOnlyVisible) ?? true,
      'mastOnly': _prefs.getBool(_keyMastOnlyVisible) ?? true,
      'slipUp': _prefs.getBool(_keySlipUpVisible) ?? true,
    };
  }

  Future<void> toggleVisibility(String key, bool value) async {
    state = {...state, key: value};
  }

  Future<void> savePreferences() async {
    await _prefs.setBool(_keyRelapseVisible, state['relapse']!);
    await _prefs.setBool(_keyPornOnlyVisible, state['pornOnly']!);
    await _prefs.setBool(_keyMastOnlyVisible, state['mastOnly']!);
    await _prefs.setBool(_keySlipUpVisible, state['slipUp']!);
  }
}

const _keyRelapseVisible = 'statistics_relapse_visible';
const _keyPornOnlyVisible = 'statistics_porn_only_visible';
const _keyMastOnlyVisible = 'statistics_mast_only_visible';
const _keySlipUpVisible = 'statistics_slip_up_visible';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final statisticsVisibilityProvider =
    StateNotifierProvider<StatisticsVisibilityNotifier, Map<String, bool>>(
        (ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value!;
  return StatisticsVisibilityNotifier(prefs);
});
