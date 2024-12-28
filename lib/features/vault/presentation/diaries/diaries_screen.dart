import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/app_bar.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diaries_notifier.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';

class DiariesScreen extends ConsumerStatefulWidget {
  const DiariesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DiariesScreenState();
}

class _DiariesScreenState extends ConsumerState<DiariesScreen> {
  final searchController = TextEditingController();
  List<Diary> filteredDiaries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diariesNotifierProvider.notifier).fetchDiaries();
    });
    searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final diariesNotifier = ref.read(diariesNotifierProvider.notifier);
    filteredDiaries =
        await diariesNotifier.searchDiaries(searchController.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: appBar(context, ref, "diaries", false, true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: CustomTextField(
                          controller: searchController,
                          prefixIcon: LucideIcons.search,
                          inputType: TextInputType.text,
                          width: width * 0.75,
                          validator: (value) => null,
                        ),
                      ),
                      horizontalSpace(Spacing.points24),
                      Icon(LucideIcons.slidersHorizontal)
                    ],
                  ),
                  verticalSpace(Spacing.points16),
                  ref.watch(diariesNotifierProvider).when(
                        data: (diaries) {
                          final displayDiaries = searchController.text.isEmpty
                              ? diaries
                              : filteredDiaries;

                          if (diaries.isEmpty) {
                            return Center(
                              child: Text("No diary entries yet"),
                            );
                          } else if (displayDiaries.isEmpty &&
                              searchController.text.isNotEmpty) {
                            return Center(
                              child:
                                  Text("There is no data matching your search"),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              return DiaryWidget(
                                diary: displayDiaries[index],
                                index: index + 1,
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    verticalSpace(Spacing.points8),
                            itemCount: displayDiaries.length,
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Error: ${error.toString()}'),
                        ),
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

class DiaryWidget extends ConsumerWidget {
  const DiaryWidget({super.key, required this.diary, required this.index});
  final Diary diary;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: GestureDetector(
        onTap: () => context.go("/vault/diaries/diary/${diary.id}"),
        child: WidgetsContainer(
          padding: EdgeInsets.all(12),
          backgroundColor: theme.backgroundColor,
          borderSide: BorderSide(color: theme.grey[600]!, width: 0.25),
          borderRadius: BorderRadius.circular(10.5),
          boxShadow: Shadows.mainShadows,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                index.toString(),
                style: TextStyles.footnoteSelected.copyWith(
                  color: theme.grey[900],
                ),
              ),
              horizontalSpace(Spacing.points8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [Text(diary.title, style: TextStyles.footnote)],
                    ),
                    verticalSpace(Spacing.points4),
                    Text(
                      getDisplayDateTime(diary.date, locale!.languageCode),
                      style:
                          TextStyles.caption.copyWith(color: theme.grey[700]),
                    ),
                    Text(
                      diary.plainText,
                      style: TextStyles.small.copyWith(color: theme.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                color: theme.grey[300],
              )
            ],
          ),
        ),
      ),
    );
  }
}
