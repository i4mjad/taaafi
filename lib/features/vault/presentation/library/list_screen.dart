import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_item_widget.dart';

//TODO: UPDATE THIS TO TAKE THE LIST ID INSTEAD OF THE TITLE
class ListScreen extends ConsumerWidget {
  const ListScreen(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Dummy data list
    final List<Map<String, String>> dummyData = [
      {
        "title": "عنوان المحتوى 1",
        "description": "مقطع مرئي • تصنيف المحتوى • المصدر 1"
      },
      {
        "title": "عنوان المحتوى 2",
        "description": "مقطع مرئي • تصنيف المحتوى • المصدر 2"
      },
      {
        "title": "عنوان المحتوى 3",
        "description": "مقطع مرئي • تصنيف المحتوى • المصدر 3"
      },
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: plainAppBar(context, ref, title, false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  WidgetsContainer(
                    backgroundColor: theme.backgroundColor,
                    borderSide: BorderSide(color: theme.grey[600]!, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(50, 50, 93, 0.25),
                        blurRadius: 5,
                        spreadRadius: -1,
                        offset: Offset(
                          0,
                          2,
                        ),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.3),
                        blurRadius: 3,
                        spreadRadius: -1,
                        offset: Offset(
                          0,
                          1,
                        ),
                      ),
                    ],
                    width: width,
                    child: Text(
                      'هذا توصيف للقائمة والفكرة منها وطبيعة المحتوى الموجود في هذه القائمة. مثال: قائمة كيف أبدأ تحتوي على بعض المصادر لمساعدة المتعافي للبدء في التعافي وكيف يدخل لهذا العالم. سيتم إضافة التوصيف عند إضافة القائمة.',
                      style: TextStyles.small.copyWith(
                        color: theme.grey[900],
                      ),
                    ),
                  ),
                  verticalSpace(Spacing.points16),
                  Text(
                    AppLocalizations.of(context).translate("list-content"),
                    style: TextStyles.h6.copyWith(
                      color: theme.grey[900],
                    ),
                  ),
                  verticalSpace(Spacing.points8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: dummyData.length,
                    separatorBuilder: (context, index) =>
                        verticalSpace(Spacing.points8),
                    itemBuilder: (context, index) {
                      final item = dummyData[index];
                      return ContentItem(
                        title: item["title"]!,
                        description: item["description"]!,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
