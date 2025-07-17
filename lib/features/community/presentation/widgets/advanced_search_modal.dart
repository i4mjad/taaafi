import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';

class AdvancedSearchModal extends ConsumerStatefulWidget {
  const AdvancedSearchModal({super.key});

  @override
  ConsumerState<AdvancedSearchModal> createState() =>
      _AdvancedSearchModalState();
}

class _AdvancedSearchModalState extends ConsumerState<AdvancedSearchModal> {
  String _selectedCategory = '';
  String _selectedSortBy = 'newest_first';
  String _authorName = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

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
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: theme.grey[50],
              borderSide: BorderSide(color: theme.grey[200]!),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  hint: Text(
                    localizations.translate('select_category'),
                    style: TextStyles.body.copyWith(color: theme.grey[600]),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(localizations.translate('community_all')),
                    ),
                    DropdownMenuItem(
                      value: 'general',
                      child: Text(localizations.translate('community_general')),
                    ),
                    DropdownMenuItem(
                      value: 'questions',
                      child:
                          Text(localizations.translate('community_questions')),
                    ),
                    DropdownMenuItem(
                      value: 'tips',
                      child: Text(localizations.translate('community_tips')),
                    ),
                    DropdownMenuItem(
                      value: 'support',
                      child: Text(localizations.translate('community_support')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? '';
                    });
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sort By Filter
          _buildFilterSection(
            title: localizations.translate('sort_by'),
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: theme.grey[50],
              borderSide: BorderSide(color: theme.grey[200]!),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSortBy,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'newest_first',
                      child: Text(localizations.translate('newest_first')),
                    ),
                    DropdownMenuItem(
                      value: 'oldest_first',
                      child: Text(localizations.translate('oldest_first')),
                    ),
                    DropdownMenuItem(
                      value: 'most_liked',
                      child: Text(localizations.translate('most_liked')),
                    ),
                    DropdownMenuItem(
                      value: 'most_commented',
                      child: Text(localizations.translate('most_commented')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSortBy = value ?? 'newest_first';
                    });
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Author Filter
          _buildFilterSection(
            title: localizations.translate('filter_by_author'),
            child: WidgetsContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: theme.grey[50],
              borderSide: BorderSide(color: theme.grey[200]!),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _authorName = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: localizations.translate('author_name'),
                  hintStyle: TextStyles.body.copyWith(color: theme.grey[600]),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    LucideIcons.user,
                    color: theme.grey[500],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Date Range Filter
          _buildFilterSection(
            title: localizations.translate('filter_by_date'),
            child: Column(
              children: [
                WidgetsContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: theme.grey[50],
                  borderSide: BorderSide(color: theme.grey[200]!),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: theme.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _startDate == null
                              ? localizations.translate('select_start_date')
                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                          style: TextStyles.body.copyWith(
                            color: _startDate == null
                                ? theme.grey[600]
                                : theme.grey[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                WidgetsContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: theme.grey[50],
                  borderSide: BorderSide(color: theme.grey[200]!),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        color: theme.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _endDate == null
                              ? localizations.translate('select_end_date')
                              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          style: TextStyles.body.copyWith(
                            color: _endDate == null
                                ? theme.grey[600]
                                : theme.grey[900],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      _selectedCategory = '';
                      _selectedSortBy = 'newest_first';
                      _authorName = '';
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
                    // TODO: Apply filters and close modal
                    Navigator.of(context).pop({
                      'category': _selectedCategory,
                      'sortBy': _selectedSortBy,
                      'author': _authorName,
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
