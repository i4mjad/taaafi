import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/helpers/date_display_formater.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/shared_widgets/custom_textfield.dart';
import 'package:reboot_app_3/core/shared_widgets/snackbar.dart';
import 'package:reboot_app_3/core/shared_widgets/spinner.dart';
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
                      CustomTextField(
                        controller: searchController,
                        prefixIcon: LucideIcons.search,
                        inputType: TextInputType.text,
                        width: width - 32,
                        validator: (value) => null,
                      ),
                      // horizontalSpace(Spacing.points24),
                      // Icon(LucideIcons.slidersHorizontal)
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
                          child: Spinner(),
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

class DiaryWidget extends ConsumerStatefulWidget {
  const DiaryWidget({super.key, required this.diary, required this.index});
  final Diary diary;
  final int index;

  @override
  ConsumerState<DiaryWidget> createState() => _DiaryWidgetState();
}

class _DiaryWidgetState extends ConsumerState<DiaryWidget> {
  bool isSlided = false;

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    final theme = AppTheme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate("confirm-note-delete"),
          style: TextStyles.footnote.copyWith(color: theme.error[700]),
        ),
        content: Text(
          AppLocalizations.of(context).translate("delete-diary-warning"),
          style: TextStyles.small.copyWith(color: theme.grey[700], height: 2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context).translate("cancel"),
              style: TextStyles.small.copyWith(color: theme.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context).translate("delete"),
              style: TextStyles.small.copyWith(color: theme.error[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locale = ref.watch(localeNotifierProvider);
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Stack(
        children: [
          // Right side delete button (for Arabic)
          if (locale?.languageCode == 'ar')
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  final result = await _showDeleteConfirmationDialog(context);
                  if (result == true) {
                    try {
                      await ref
                          .read(diariesNotifierProvider.notifier)
                          .deleteDiary(widget.diary.id);
                    } catch (e) {
                      if (context.mounted) {
                        getErrorSnackBar(context, "error-deleting-diary");
                      }
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 12),
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(12),
                    backgroundColor: theme.error[50],
                    borderRadius: BorderRadius.circular(10.5),
                    borderSide:
                        BorderSide(color: theme.error[100]!, width: 0.25),
                    child: Icon(
                      LucideIcons.trash2,
                      color: theme.error[700],
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          // Left side delete button (for English)
          if (locale?.languageCode == 'en')
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: () async {
                  final result = await _showDeleteConfirmationDialog(context);
                  if (result == true) {
                    try {
                      await ref
                          .read(diariesNotifierProvider.notifier)
                          .deleteDiary(widget.diary.id);
                    } catch (e) {
                      if (context.mounted) {
                        getErrorSnackBar(context, "error-deleting-diary");
                      }
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  child: WidgetsContainer(
                    padding: EdgeInsets.all(12),
                    backgroundColor: theme.error[50],
                    borderRadius: BorderRadius.circular(10.5),
                    borderSide:
                        BorderSide(color: theme.error[100]!, width: 0.25),
                    child: Icon(
                      LucideIcons.trash2,
                      color: theme.error[700],
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            transform: Matrix4.translationValues(
                isSlided ? (locale?.languageCode == 'ar' ? -100 : 100) : 0,
                0,
                0),
            child: GestureDetector(
              onTap: () => context.goNamed(RouteNames.diary.name,
                  pathParameters: {'id': widget.diary.id}),
              onHorizontalDragUpdate: (details) {
                if (locale.languageCode == 'ar') {
                  // For Arabic: slide left (negative delta)
                  if (details.primaryDelta! < 0) {
                    setState(() {
                      isSlided = true;
                    });
                  }
                } else {
                  // For English: slide right (positive delta)
                  if (details.primaryDelta! > 0) {
                    setState(() {
                      isSlided = true;
                    });
                  }
                }
              },
              onHorizontalDragEnd: (details) {
                if (locale.languageCode == 'ar') {
                  // For Arabic: reset on right swipe (positive velocity)
                  if (details.primaryVelocity! > 0) {
                    setState(() {
                      isSlided = false;
                    });
                  }
                } else {
                  // For English: reset on left swipe (negative velocity)
                  if (details.primaryVelocity! < 0) {
                    setState(() {
                      isSlided = false;
                    });
                  }
                }
              },
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
                      widget.index.toString(),
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
                            children: [
                              Text(widget.diary.title,
                                  style: TextStyles.footnote),
                              horizontalSpace(Spacing.points8),
                              widget.diary.linkedTasks.isNotEmpty
                                  ? Wrap(
                                      children: widget.diary.linkedTasks
                                          .map((task) => Text(
                                                task.task.name,
                                                style: TextStyles.small,
                                              ))
                                          .toList(),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                          verticalSpace(Spacing.points8),
                          Text(
                            getDisplayDateTime(
                                widget.diary.date, locale!.languageCode),
                            style: TextStyles.caption
                                .copyWith(color: theme.grey[700]),
                          ),
                          verticalSpace(Spacing.points8),
                          Text(
                            widget.diary.plainText,
                            style: TextStyles.small
                                .copyWith(color: theme.grey[700]),
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
          ),
        ],
      ),
    );
  }
}
