import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post_form_data.dart';

/// Modal that explains all the validation rules for creating a new post
///
/// This modal provides clear information about character limits, word counts,
/// and other validation requirements to help users create successful posts.
class ValidationInfoModal extends StatelessWidget {
  /// Callback when the modal is dismissed
  final VoidCallback onDismiss;

  const ValidationInfoModal({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          _buildHeader(theme, localizations),
          verticalSpace(Spacing.points8),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction

                  _buildIntroduction(theme, localizations),

                  verticalSpace(Spacing.points8),

                  // Title requirements
                  _buildTitleRequirements(theme, localizations),

                  verticalSpace(Spacing.points8),

                  // Content requirements
                  _buildContentRequirements(theme, localizations),

                  verticalSpace(Spacing.points8),

                  // Additional guidelines
                  _buildAdditionalGuidelines(theme, localizations),

                  verticalSpace(Spacing.points8),

                  // Dismiss button
                  _buildDismissButton(theme, localizations),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header with title and close button
  Widget _buildHeader(CustomThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              size: 20,
              color: theme.primary[600],
            ),
          ),

          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              localizations.translate('post_validation_guidelines'),
              style: TextStyles.h5.copyWith(
                color: theme.grey[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Close button
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              color: theme.grey[600],
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the introduction text
  Widget _buildIntroduction(
      CustomThemeData theme, AppLocalizations localizations) {
    return Text(
      localizations.translate('post_validation_intro'),
      style: TextStyles.body.copyWith(
        color: theme.grey[700],
        height: 1.5,
      ),
    );
  }

  /// Builds title requirements section
  Widget _buildTitleRequirements(
      CustomThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          localizations,
          Icons.title,
          localizations.translate('post_title_requirements'),
        ),
        verticalSpace(Spacing.points4),
        _buildRequirementsList(theme, localizations, [
          localizations
              .translate('title_length_requirement')
              .replaceAll(
                  '{min}', '${PostFormValidationConstants.minTitleLength}')
              .replaceAll(
                  '{max}', '${PostFormValidationConstants.maxTitleLength}'),
          localizations.translate('title_descriptive_requirement'),
          localizations.translate('title_appropriate_requirement'),
        ]),
      ],
    );
  }

  /// Builds content requirements section
  Widget _buildContentRequirements(
      CustomThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          localizations,
          Icons.article,
          localizations.translate('post_content_requirements'),
        ),
        verticalSpace(Spacing.points4),
        _buildRequirementsList(theme, localizations, [
          localizations
              .translate('content_length_requirement')
              .replaceAll(
                  '{min}', '${PostFormValidationConstants.minContentLength}')
              .replaceAll(
                  '{max}', '${PostFormValidationConstants.maxContentLength}'),
          localizations
              .translate('content_word_count_requirement')
              .replaceAll(
                  '{min}', '${PostFormValidationConstants.minContentWordCount}')
              .replaceAll('{max}',
                  '${PostFormValidationConstants.maxContentWordCount}'),
          localizations.translate('content_meaningful_requirement'),
          localizations.translate('content_appropriate_requirement'),
        ]),
      ],
    );
  }

  /// Builds additional guidelines section
  Widget _buildAdditionalGuidelines(
      CustomThemeData theme, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          theme,
          localizations,
          Icons.lightbulb_outline,
          localizations.translate('additional_guidelines'),
        ),
        verticalSpace(Spacing.points4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: theme.primary[50],
            shape: SmoothRectangleBorder(
              side: BorderSide(color: theme.primary[200]!),
              borderRadius: SmoothBorderRadius(
                cornerRadius: 12,
                cornerSmoothing: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_objects,
                    size: 18,
                    color: theme.primary[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    localizations.translate('helpful_tips'),
                    style: TextStyles.footnote.copyWith(
                      color: theme.primary[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              verticalSpace(Spacing.points4),
              _buildTipsList(theme, localizations, [
                localizations.translate('tip_choose_appropriate_category'),
                localizations.translate('tip_be_respectful_supportive'),
                localizations.translate('tip_avoid_spam_duplicate'),
                localizations.translate('tip_use_clear_language'),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a section header with icon and title
  Widget _buildSectionHeader(
    CustomThemeData theme,
    AppLocalizations localizations,
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyles.h6.copyWith(
            color: theme.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds a list of requirements with bullet points
  Widget _buildRequirementsList(
    CustomThemeData theme,
    AppLocalizations localizations,
    List<String> requirements,
  ) {
    return Column(
      children: requirements
          .map((requirement) => _buildRequirementItem(theme, requirement))
          .toList(),
    );
  }

  /// Builds a single requirement item
  Widget _buildRequirementItem(CustomThemeData theme, String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: theme.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              requirement,
              style: TextStyles.caption.copyWith(
                color: theme.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a list of tips with bullet points
  Widget _buildTipsList(
    CustomThemeData theme,
    AppLocalizations localizations,
    List<String> tips,
  ) {
    return Column(
      children: tips.map((tip) => _buildTipItem(theme, tip)).toList(),
    );
  }

  /// Builds a single tip item
  Widget _buildTipItem(CustomThemeData theme, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: theme.primary[500],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyles.caption.copyWith(
                color: theme.primary[700],
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dismiss button
  Widget _buildDismissButton(
      CustomThemeData theme, AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onDismiss,
        style: TextButton.styleFrom(
          backgroundColor: theme.primary[500],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          localizations.translate('got_it'),
          style: TextStyles.footnote.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
