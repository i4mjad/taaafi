import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/data_restoration/data_restoration_notifier.dart';
import 'package:reboot_app_3/features/vault/data/data_restoration/migration_data_model.dart';

/// Modal bottom sheet for data restoration process
class DataRestorationModal extends ConsumerStatefulWidget {
  const DataRestorationModal({super.key});

  @override
  ConsumerState<DataRestorationModal> createState() =>
      _DataRestorationModalState();
}

class _DataRestorationModalState extends ConsumerState<DataRestorationModal> {
  @override
  void initState() {
    super.initState();
    // Start analysis when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dataRestorationNotifierProvider.notifier)
          .analyzeMigrationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final state = ref.watch(dataRestorationNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: theme.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(theme),

          // Content
          Flexible(
            child: _buildContent(theme, state),
          ),

          // Bottom padding for safe area
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(CustomThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.database,
              color: theme.primary[600],
              size: 20,
            ),
          ),
          horizontalSpace(Spacing.points12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .translate('data-restoration-title'),
                  style: TextStyles.h4.copyWith(
                    color: theme.grey[900],
                    fontWeight: FontWeight.w700,
                  ),
                ),
                verticalSpace(Spacing.points4),
                Text(
                  AppLocalizations.of(context)
                      .translate('data-restoration-subtitle'),
                  style: TextStyles.small.copyWith(
                    color: theme.grey[600],
                  ),
                ),
              ],
            ),
          ),
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
    );
  }

  Widget _buildContent(CustomThemeData theme, DataRestorationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          verticalSpace(Spacing.points20),

          // Description
          Text(
            AppLocalizations.of(context)
                .translate('data-restoration-description'),
            style: TextStyles.body.copyWith(
              color: theme.grey[700],
              height: 1.5,
            ),
          ),

          verticalSpace(Spacing.points24),

          // Status content
          _buildStatusContent(theme, state),
        ],
      ),
    );
  }

  Widget _buildStatusContent(
      CustomThemeData theme, DataRestorationState state) {
    switch (state.status) {
      case MigrationStatus.checking:
        return _buildCheckingContent(theme);
      case MigrationStatus.noIssues:
        return _buildNoIssuesContent(theme, state);
      case MigrationStatus.issuesFound:
        return _buildIssuesFoundContent(theme, state);
      case MigrationStatus.migrating:
      case MigrationStatus.removingDuplicates:
        return _buildProcessingContent(theme, state);
      case MigrationStatus.success:
        return _buildSuccessContent(theme, state);
      case MigrationStatus.error:
        return _buildErrorContent(theme, state);
    }
  }

  Widget _buildCheckingContent(CustomThemeData theme) {
    return Column(
      children: [
        const Spinner(strokeWidth: 4),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate('data-restoration-checking'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNoIssuesContent(
      CustomThemeData theme, DataRestorationState state) {
    return Column(
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            color: Color(0xFF22C55E),
            size: 48,
          ),
        ),

        verticalSpace(Spacing.points20),

        Text(
          AppLocalizations.of(context).translate('data-restoration-no-issues'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        verticalSpace(Spacing.points8),

        Text(
          AppLocalizations.of(context)
              .translate('data-restoration-no-issues-description'),
          style: TextStyles.body.copyWith(
            color: theme.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        if (state.migrationData != null) ...[
          verticalSpace(Spacing.points20),
          _buildMigrationSummary(theme, state.migrationData!),
        ],

        verticalSpace(Spacing.points24),

        // Close button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('data-restoration-close'),
              style: TextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesFoundContent(
      CustomThemeData theme, DataRestorationState state) {
    final migrationData = state.migrationData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning icon and title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                color: Color(0xFFFF6B6B),
                size: 32,
              ),
            ),
            horizontalSpace(Spacing.points16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .translate('data-restoration-issues-found'),
                    style: TextStyles.h5.copyWith(
                      color: theme.grey[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)
                        .translate('data-restoration-issues-description'),
                    style: TextStyles.small.copyWith(
                      color: theme.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        verticalSpace(Spacing.points24),

        // Migration summary
        _buildMigrationSummary(theme, migrationData),

        verticalSpace(Spacing.points20),

        // Category details
        _buildCategoryDetails(theme, migrationData),

        verticalSpace(Spacing.points24),

        // Action buttons
        _buildActionButtons(theme, migrationData),
      ],
    );
  }

  Widget _buildProcessingContent(
      CustomThemeData theme, DataRestorationState state) {
    final isRemoving = state.status == MigrationStatus.removingDuplicates;

    return Column(
      children: [
        const Spinner(strokeWidth: 4),
        verticalSpace(Spacing.points16),
        Text(
          AppLocalizations.of(context).translate(isRemoving
              ? 'data-restoration-removing-duplicates'
              : 'data-restoration-migrating'),
          style: TextStyles.body.copyWith(
            color: theme.grey[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (state.progress > 0) ...[
          verticalSpace(Spacing.points16),
          LinearProgressIndicator(
            value: state.progress / 100,
            backgroundColor: theme.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary[600]!),
          ),
          verticalSpace(Spacing.points8),
          Text(
            '${state.progress.toStringAsFixed(0)}%',
            style: TextStyles.small.copyWith(color: theme.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessContent(
      CustomThemeData theme, DataRestorationState state) {
    return Column(
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            color: Color(0xFF22C55E),
            size: 48,
          ),
        ),

        verticalSpace(Spacing.points20),

        Text(
          AppLocalizations.of(context).translate('data-restoration-success'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        if (state.migrationData != null) ...[
          verticalSpace(Spacing.points20),
          _buildMigrationSummary(theme, state.migrationData!),
        ],

        verticalSpace(Spacing.points24),

        // Close button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('data-restoration-close'),
              style: TextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(CustomThemeData theme, DataRestorationState state) {
    return Column(
      children: [
        // Error icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            LucideIcons.xCircle,
            color: Color(0xFFEF4444),
            size: 48,
          ),
        ),

        verticalSpace(Spacing.points20),

        Text(
          AppLocalizations.of(context).translate('data-restoration-error'),
          style: TextStyles.h5.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        if (state.errorMessage != null) ...[
          verticalSpace(Spacing.points8),
          Text(
            state.errorMessage!,
            style: TextStyles.small.copyWith(
              color: theme.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],

        verticalSpace(Spacing.points24),

        // Retry button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                ref.read(dataRestorationNotifierProvider.notifier).retry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).translate('data-restoration-retry'),
              style: TextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMigrationSummary(
      CustomThemeData theme, MigrationData migrationData) {
    return WidgetsContainer(
      backgroundColor: theme.grey[50],
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .translate('data-restoration-migration-summary'),
            style: TextStyles.body.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          verticalSpace(Spacing.points8),
          _buildSummaryRow(
            theme,
            AppLocalizations.of(context)
                .translate('data-restoration-total-followups'),
            '${migrationData.getTotalFollowupsCount()}',
            LucideIcons.calendar,
          ),
          if (migrationData.getTotalMissingCount() > 0)
            _buildSummaryRow(
              theme,
              AppLocalizations.of(context)
                  .translate('data-restoration-missing-entries'),
              '${migrationData.getTotalMissingCount()}',
              LucideIcons.alertTriangle,
              color: const Color(0xFFFF6B6B),
            ),
          if (migrationData.getTotalDuplicatesCount() > 0)
            _buildSummaryRow(
              theme,
              AppLocalizations.of(context)
                  .translate('data-restoration-duplicate-entries'),
              '${migrationData.getTotalDuplicatesCount()}',
              LucideIcons.copy,
              color: const Color(0xFFF97316),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    CustomThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? theme.grey[600],
          ),
          horizontalSpace(Spacing.points8),
          Expanded(
            child: Text(
              label,
              style: TextStyles.small.copyWith(
                color: theme.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyles.small.copyWith(
              color: color ?? theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetails(
      CustomThemeData theme, MigrationData migrationData) {
    final categories = [
      ('relapses', migrationData.relapses),
      ('mastOnly', migrationData.mastOnly),
      ('pornOnly', migrationData.pornOnly),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)
              .translate('data-restoration-category-details'),
          style: TextStyles.body.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        verticalSpace(Spacing.points12),
        ...categories.map(
          (category) => _buildCategoryRow(theme, category.$1, category.$2),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
      CustomThemeData theme, String category, CategoryMigrationStatus status) {
    if (!status.hasIssues) return const SizedBox.shrink();

    final notifier = ref.read(dataRestorationNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)
                .translate('data-restoration-$category'),
            style: TextStyles.small.copyWith(
              color: theme.grey[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          if (status.missing.isNotEmpty) ...[
            verticalSpace(Spacing.points4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .translate('data-restoration-missing-count')
                      .replaceAll('{count}', '${status.missing.length}'),
                  style: TextStyles.small.copyWith(color: theme.grey[600]),
                ),
                TextButton(
                  onPressed: () => notifier.migrateMissingDataForCategory(
                    category: category,
                    missingDates: status.missing,
                  ),
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('data-restoration-migrate'),
                    style: TextStyles.small.copyWith(
                      color: theme.primary[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status.duplicates.isNotEmpty) ...[
            verticalSpace(Spacing.points4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .translate('data-restoration-duplicate-count')
                      .replaceAll('{count}', '${status.duplicateCount}'),
                  style: TextStyles.small.copyWith(color: theme.grey[600]),
                ),
                TextButton(
                  onPressed: () => notifier.removeDuplicatesForCategory(
                    category: category,
                    duplicateDates: status.duplicates,
                  ),
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('data-restoration-remove-duplicates'),
                    style: TextStyles.small.copyWith(
                      color: const Color(0xFFF97316),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      CustomThemeData theme, MigrationData migrationData) {
    final notifier = ref.read(dataRestorationNotifierProvider.notifier);

    return Column(
      children: [
        // Restore all missing data button
        if (migrationData.getTotalMissingCount() > 0)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => notifier.performCompleteMigration(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)
                    .translate('data-restoration-migrate'),
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Remove all duplicates button
        if (migrationData.getTotalDuplicatesCount() > 0) ...[
          if (migrationData.getTotalMissingCount() > 0)
            verticalSpace(Spacing.points12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => notifier.removeAllDuplicates(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
                side: const BorderSide(color: Color(0xFFF97316)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)
                    .translate('data-restoration-remove-duplicates'),
                style: TextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
