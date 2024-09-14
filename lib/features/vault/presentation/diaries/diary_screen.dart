import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/core/theming/theme_provider.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key, required this.diaryId});

  final String diaryId;

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late TextEditingController _bodyController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(
      text:
          "استمتعت بيوم مريح على الشاطئ مع الأصدقاء. قضينا الوقت في السباحة والاستمتاع بأشعة الشمس. كانت هذه فرصة مثالية للابتعاد عن ضغوط العمل والاسترخاء التام.",
    );
    _titleController =
        TextEditingController(text: "التحدي الأول: البداية الجديدة في التعافي");
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _applyMarkdown(String markdownSymbol, {bool wrapWithSpace = false}) {
    final selection = _bodyController.selection;

    if (!selection.isValid) return;

    final text = _bodyController.text;
    final selectedText = text.substring(selection.start, selection.end);

    final wrappedText = wrapWithSpace
        ? "$markdownSymbol $selectedText $markdownSymbol"
        : "$markdownSymbol$selectedText$markdownSymbol";

    final newText =
        text.replaceRange(selection.start, selection.end, wrappedText);

    _bodyController.text = newText;
    _bodyController.selection =
        TextSelection.collapsed(offset: selection.start + wrappedText.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final themeNotifier = ref.watch(customThemeProvider.notifier);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final Diary diary = Diary(
      _titleController.text,
      _bodyController.text,
      DateTime.now(),
      [
        "تمرين",
        "عمل",
      ],
    );

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _appBar(diary, theme),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('activities'),
                          style: TextStyles.h6,
                        ),
                        horizontalSpace(Spacing.points12),
                        Flexible(
                          child: Wrap(
                            spacing: 4,
                            children: diary.linkedActivites.map((activity) {
                              return WidgetsContainer(
                                borderRadius: BorderRadius.circular(8),
                                padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                                child: Text(
                                  activity,
                                  style: TextStyles.tiny
                                      .copyWith(color: theme.secondary[900]),
                                ),
                                backgroundColor: theme.secondary[100],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.plusSquare),
                ],
              ),
              Divider(),
              Expanded(
                child: Stack(
                  children: [
                    TextField(
                      controller: _bodyController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: TextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Edit your diary...',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: WidgetsContainer(
                        backgroundColor: theme.primary[50],
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xff323247).withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 64,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Color(0xff323247).withOpacity(0.06),
                            spreadRadius: 0,
                            blurRadius: 128,
                            offset: Offset(0, 8),
                          ),
                        ],
                        borderSide:
                            BorderSide(color: theme.grey[200]!, width: 1),
                        borderRadius: BorderRadius.circular(10.5),
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _applyMarkdown('# '),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate('heading'),
                                      style: TextStyles.small,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _applyMarkdown('**'),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('bold'),
                                        style: TextStyles.smallBold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _applyMarkdown('*'),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('italic'),
                                        style: TextStyles.small),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _applyMarkdown('> '),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('quote'),
                                        style: TextStyles.small),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _applyMarkdown('- '),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('list'),
                                        style: TextStyles.small),
                                  ),
                                ),
                              ],
                            ),
                            WidgetsContainer(
                              backgroundColor: theme.primary[50],
                              borderSide: BorderSide(
                                color: theme.grey[100]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xff323247).withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 64,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Color(0xff323247).withOpacity(0.06),
                                  spreadRadius: 0,
                                  blurRadius: 128,
                                  offset: Offset(0, 8),
                                ),
                              ],
                              padding: EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.save,
                                    color: theme.grey[600],
                                  ),
                                  horizontalSpace(Spacing.points4),
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('save'),
                                    style: TextStyles.smallBold.copyWith(
                                      color: theme.grey[700],
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(Diary diary, CustomThemeData theme) {
    return AppBar(
      title: Text(
        diary.title,
        style: TextStyles.h5.copyWith(
          color: theme.grey[900],
          height: 1.2, // Adjust line height if necessary
        ),
        maxLines: 2, // Allow up to 2 lines for wrapping
        softWrap: true, // Enable wrapping
        overflow: TextOverflow.visible, // Allow text to flow to the next line
      ),
      backgroundColor: theme.backgroundColor,
      surfaceTintColor: theme.backgroundColor,
      centerTitle: false,
      shadowColor: theme.grey[100],
      leadingWidth: 16,
      automaticallyImplyLeading: true,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Icon(LucideIcons.settings),
        ),
      ],
    );
  }
}
