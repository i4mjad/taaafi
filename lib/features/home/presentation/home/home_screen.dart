import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/home/data/streak_notifier.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/calender_widget.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/follow_up_sheet.dart';
import 'package:reboot_app_3/features/home/presentation/home/widgets/statistics_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyRelapseVisible = 'statistics_relapse_visible';
const _keyPornOnlyVisible = 'statistics_porn_only_visible';
const _keyMastOnlyVisible = 'statistics_mast_only_visible';
const _keySlipUpVisible = 'statistics_slip_up_visible';

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

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final streaksState = ref.watch(streakNotifierProvider);
    final actions = [
      IconButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return HomeSettingsSheet();
            },
          );
        },
        icon: Icon(LucideIcons.settings, color: theme.primary[600]),
      ),
    ];
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, 'home', false, false, actions: actions),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Activities(),
            StatisticsWidget(),
            verticalSpace(Spacing.points16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CalenderWidget(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.primary[600],
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return FollowUpSheet(DateTime.now());
            },
          );
        },
        label: Text(
          AppLocalizations.of(context).translate("daily-follow-up"),
          style: TextStyles.caption.copyWith(color: theme.grey[50]),
        ),
        icon: Icon(LucideIcons.pencil, color: theme.grey[50]),
      ),
    );
  }
}

class Activities extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.goNamed(RouteNames.activities.name);
        },
        child: WidgetsContainer(
          padding: EdgeInsets.zero,
          backgroundColor: theme.primary[600],
          borderSide: BorderSide(color: theme.backgroundColor),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate("activities-home-headings"),
                            style: TextStyles.h6
                                .copyWith(color: theme.grey[50], fontSize: 14),
                          ),
                          verticalSpace(Spacing.points8),
                          Text(
                            AppLocalizations.of(context).translate(
                                "exercises-description-home-description"),
                            style: TextStyles.small
                                .copyWith(height: 1.25, color: theme.grey[50]),
                            softWrap: true,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    horizontalSpace(Spacing.points72),
                    Icon(LucideIcons.arrowLeft, color: theme.grey[50]),
                  ],
                ),
              ),
              Positioned(
                left: locale!.languageCode == 'ar' ? 40 : null,
                right: locale.languageCode == 'ar' ? null : 40,
                bottom: -20,
                child: Transform.rotate(
                  angle: 15 * 3.141592653589793 / 180,
                  child: Image.asset(
                    'asset/illustrations/app-icon.png',
                    height: 75,
                    width: 75,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeSettingsSheet extends ConsumerWidget {
  const HomeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = Localizations.localeOf(context);
    final visibilitySettings = ref.watch(statisticsVisibilityProvider);

    return Container(
      color: theme.backgroundColor,
      padding: EdgeInsets.all(16),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('home-settings'),
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
          Text(
            AppLocalizations.of(context).translate('statistics-visibility'),
            style: TextStyles.body.copyWith(color: theme.grey[600]),
          ),
          verticalSpace(Spacing.points4),
          Text(
            AppLocalizations.of(context)
                .translate('statistics-visibility-description'),
            style: TextStyles.footnote.copyWith(color: theme.grey[400]),
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'relapse',
                          !visibilitySettings['relapse']!,
                        );
                  },
                  text: "relapses",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['relapse']!,
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'pornOnly',
                          !visibilitySettings['pornOnly']!,
                        );
                  },
                  text: "porn",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['pornOnly']!,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points8),
          Row(
            children: [
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'mastOnly',
                          !visibilitySettings['mastOnly']!,
                        );
                  },
                  text: "mast",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['mastOnly']!,
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: SettingsOption(
                  onTap: () {
                    ref
                        .read(statisticsVisibilityProvider.notifier)
                        .toggleVisibility(
                          'slipUp',
                          !visibilitySettings['slipUp']!,
                        );
                  },
                  text: "slips",
                  icon: LucideIcons.eye,
                  type: "normal",
                  isChecked: visibilitySettings['slipUp']!,
                ),
              ),
            ],
          ),
          verticalSpace(Spacing.points16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(statisticsVisibilityProvider.notifier)
                        .savePreferences();
                    Navigator.pop(context);
                  },
                  child: WidgetsContainer(
                    backgroundColor: theme.primary[600],
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('save'),
                        style: TextStyles.h6.copyWith(color: theme.grey[50]),
                      ),
                    ),
                  ),
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[900]!, width: 0.5),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).translate('close'),
                        style:
                            TextStyles.h6.copyWith(color: theme.primary[900]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsOption extends StatelessWidget {
  const SettingsOption({
    required this.onTap,
    required this.text,
    required this.icon,
    required this.type,
    this.isChecked = false,
    super.key,
  });

  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final String type;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: WidgetsContainer(
        padding: EdgeInsets.all(4),
        backgroundColor: theme.backgroundColor,
        borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                activeColor: theme.primary[600],
                value: isChecked,
                onChanged: (value) => onTap(),
              ),
              Text(
                AppLocalizations.of(context).translate(text),
                style: TextStyles.body
                    .copyWith(color: _getIconAndTextColor(type, theme)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconAndTextColor(String type, CustomThemeData theme) {
    switch (type) {
      case 'error':
        return theme.error[600]!;
      case 'primary':
        return theme.primary[600]!;
      case 'warn':
        return theme.warn[600]!;
      case 'normal':
      default:
        return theme.grey[800]!;
    }
  }
}
