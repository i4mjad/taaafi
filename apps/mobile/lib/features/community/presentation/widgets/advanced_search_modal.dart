import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_dropdown.dart';
import 'package:reboot_app_3/core/shared_widgets/platform_date_picker.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class AdvancedSearchModal extends ConsumerStatefulWidget {
  const AdvancedSearchModal({super.key});

  @override
  ConsumerState<AdvancedSearchModal> createState() =>
      _AdvancedSearchModalState();
}

class _AdvancedSearchModalState extends ConsumerState<AdvancedSearchModal> {
  String? _selectedCategory;
  String _selectedSortBy = 'newest_first';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(postCategoriesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.search,
                color: theme.primary[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                localizations.translate('advanced_search'),
                style: TextStyles.h6.copyWith(
                  color: theme.grey[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  LucideIcons.x,
                  color: theme.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Category Filter
          _buildFilterSection(
            title: localizations.translate('filter_by_category'),
            child: categoriesAsync.when(
              data: (categories) {
                final items = [
                  PlatformDropdownItem<String?>(
                    value: null,
                    label: localizations.translate('community_all'),
                  ),
                  ...categories.map((category) => PlatformDropdownItem<String?>(
                        value: category.id,
                        label: category
                            .getDisplayName(localizations.locale.languageCode),
                      )),
                ];

                return PlatformDropdown<String?>(
                  value: _selectedCategory,
                  items: items,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  backgroundColor: theme.grey[50],
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                child: const CircularProgressIndicator(),
              ),
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  localizations.translate('error_loading_categories'),
                  style: TextStyles.body.copyWith(color: theme.error[600]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sort By Filter
          _buildFilterSection(
            title: localizations.translate('sort_by'),
            child: PlatformDropdown<String>(
              value: _selectedSortBy,
              items: [
                PlatformDropdownItem<String>(
                  value: 'newest_first',
                  label: localizations.translate('newest_first'),
                ),
                PlatformDropdownItem<String>(
                  value: 'oldest_first',
                  label: localizations.translate('oldest_first'),
                ),
                PlatformDropdownItem<String>(
                  value: 'most_liked',
                  label: localizations.translate('most_liked'),
                ),
                PlatformDropdownItem<String>(
                  value: 'most_commented',
                  label: localizations.translate('most_commented'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSortBy = value ?? 'newest_first';
                });
              },
              backgroundColor: theme.grey[50],
            ),
          ),

          const SizedBox(height: 20),

          // Date Range Filter
          _buildFilterSection(
            title: localizations.translate('filter_by_date'),
            child: Column(
              children: [
                PlatformDatePicker(
                  value: _startDate,
                  onChanged: (date) {
                    setState(() {
                      _startDate = date;
                      // Ensure end date is not before start date
                      if (_endDate != null &&
                          date != null &&
                          _endDate!.isBefore(date)) {
                        _endDate = null;
                      }
                    });
                  },
                  hint: localizations.translate('select_start_date'),
                  lastDate: _endDate ?? DateTime.now(),
                  dateFormatter: (date) =>
                      '${date.day}/${date.month}/${date.year}',
                ),
                verticalSpace(Spacing.points16),
                PlatformDatePicker(
                  value: _endDate,
                  onChanged: (date) {
                    setState(() {
                      _endDate = date;
                    });
                  },
                  hint: localizations.translate('select_end_date'),
                  firstDate: _startDate,
                  lastDate: DateTime.now(),
                  dateFormatter: (date) =>
                      '${date.day}/${date.month}/${date.year}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedSortBy = 'newest_first';
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: Text(
                    localizations.translate('clear_filters'),
                    style: TextStyles.body.copyWith(
                      color: theme.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters and close modal
                    Navigator.of(context).pop({
                      'category': _selectedCategory,
                      'sortBy': _selectedSortBy,
                      'startDate': _startDate,
                      'endDate': _endDate,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary[500],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    localizations.translate('apply_filters'),
                    style: TextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
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

  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    final theme = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.body.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
