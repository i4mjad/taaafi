import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/community/presentation/providers/forum_providers.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final localizations = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(postCategoriesProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(
        context,
        ref,
        'community_categories',
        false,
        true,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          // Filter out any categories with missing required data
          final validCategories = categories.where((category) {
            return category.id.isNotEmpty &&
                category.name.isNotEmpty &&
                category.isActive;
          }).toList();

          if (validCategories.isEmpty) {
            return Center(
              child: Text(
                localizations.translate('no_categories_found'),
                style: TextStyles.body.copyWith(
                  color: theme.grey[600],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: validCategories.length,
              itemBuilder: (context, index) {
                final category = validCategories[index];
                return _buildCategoryCard(
                    context, category, localizations, theme);
              },
            ),
          );
        },
        loading: () => const Center(child: Spinner()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.translate('error_loading_categories'),
                style: TextStyles.body.copyWith(
                  color: theme.error[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(postCategoriesProvider);
                },
                child: Text(localizations.translate('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, PostCategory category,
      AppLocalizations localizations, dynamic theme) {
    final categoryColor = category.color;
    final categoryIcon = category.icon;
    final displayName = _getSafeCategoryName(category, localizations);

    return GestureDetector(
      onTap: () {
        // Navigate to category posts screen
        final categoryId = Uri.encodeComponent(category.id);
        final categoryName = Uri.encodeComponent(category.name);
        final categoryNameAr = Uri.encodeComponent(category.nameAr);
        final categoryIconName = Uri.encodeComponent(category.iconName);
        final categoryColorHex = Uri.encodeComponent(category.colorHex);

        context.pushNamed(
          RouteNames.categoryPosts.name,
          pathParameters: {
            'categoryId': categoryId,
            'categoryName': categoryName,
            'categoryNameAr': categoryNameAr,
            'categoryIcon': categoryIconName,
            'categoryColor': categoryColorHex,
          },
        );
      },
      child: WidgetsContainer(
        backgroundColor: categoryColor.withValues(alpha: 0.1),
        borderSide: BorderSide(
          color: categoryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        cornerSmoothing: 0.8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIcon,
              size: 28,
              color: categoryColor,
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: TextStyles.body.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getSafeCategoryName(
      PostCategory category, AppLocalizations localizations) {
    try {
      // Check if locale is Arabic and use nameAr, otherwise use name
      final isArabic = localizations.locale.languageCode == 'ar';

      if (isArabic && category.nameAr.isNotEmpty) {
        return category.nameAr;
      } else if (category.name.isNotEmpty) {
        return category.name;
      } else {
        // Fallback to ID if both names are empty
        return category.id;
      }
    } catch (e) {
      // Ultimate fallback - return category ID
      return category.id.isNotEmpty ? category.id : 'Unknown';
    }
  }
}
