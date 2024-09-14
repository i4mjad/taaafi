import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/font_weights.dart';
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
  late QuillController _controller;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(text: "التحدي الأول: البداية الجديدة في التعافي");

    _controller = QuillController(
      document: Document()
        ..insert(0,
            "استمتعت بيوم مريح على الشاطئ مع الأصدقاء. قضينا الوقت في السباحة والاستمتاع بأشعة الشمس."),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final themeNotifier = ref.watch(customThemeProvider.notifier);

    final Diary diary = Diary(
      _titleController.text,
      _controller.document.toPlainText(),
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
                    // Quill Editor
                    QuillEditor.basic(
                      controller: _controller,
                      configurations: QuillEditorConfigurations(
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            TextStyles.body,
                            HorizontalSpacing(0, 0),
                            VerticalSpacing(0, 0),
                            VerticalSpacing(0, 0),
                            BoxDecoration(),
                          ),
                          h4: DefaultTextBlockStyle(
                            TextStyles.h4,
                            HorizontalSpacing(0, 0),
                            VerticalSpacing(0, 0),
                            VerticalSpacing(0, 0),
                            BoxDecoration(),
                          ),
                          lists: DefaultListBlockStyle(
                              TextStyles.body,
                              HorizontalSpacing(0, 0),
                              VerticalSpacing(0, 0),
                              VerticalSpacing(0, 0),
                              BoxDecoration(),
                              null),
                          bold: TextStyles.body.copyWith(
                            fontWeight: FontWeightHelper.semiBold,
                          ),
                          italic: TextStyles.body.copyWith(
                            fontWeight: FontWeightHelper.semiBold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
                            color: const Color(0xff323247).withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 64,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xff323247).withOpacity(0.06),
                            spreadRadius: 0,
                            blurRadius: 128,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        borderSide:
                            BorderSide(color: theme.grey[200]!, width: 1),
                        borderRadius: BorderRadius.circular(10.5),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    // Toggle heading style
                                    final isHeading = _controller
                                        .getSelectionStyle()
                                        .attributes
                                        .containsKey('h4');
                                    _controller.formatSelection(
                                      isHeading
                                          ? Attribute.fromKeyValue(
                                              Attribute.h4.key, null)
                                          : Attribute.h4,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .translate('heading'),
                                      style: TextStyles.small,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    final isBold = _controller
                                        .getSelectionStyle()
                                        .attributes
                                        .containsKey('bold');
                                    _controller.formatSelection(isBold
                                        ? Attribute.fromKeyValue(
                                            Attribute.bold.key, null)
                                        : Attribute.bold);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('bold'),
                                        style: TextStyles.smallBold),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    final isItalic = _controller
                                        .getSelectionStyle()
                                        .attributes
                                        .containsKey('italic');
                                    _controller.formatSelection(isItalic
                                        ? Attribute.fromKeyValue(
                                            Attribute.italic.key, null)
                                        : Attribute.italic);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('italic'),
                                        style: TextStyles.small),
                                  ),
                                ),
                                // Adding Quote
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    final isQuote = _controller
                                        .getSelectionStyle()
                                        .attributes
                                        .containsKey('blockquote');
                                    _controller.formatSelection(
                                      isQuote
                                          ? Attribute.fromKeyValue(
                                              Attribute.blockQuote.key, null)
                                          : Attribute.blockQuote,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .translate('quote'),
                                        style: TextStyles.small),
                                  ),
                                ),
                                // Adding List (unordered)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    final isList = _controller
                                        .getSelectionStyle()
                                        .attributes
                                        .containsKey('list');
                                    _controller.formatSelection(isList
                                        ? Attribute.fromKeyValue(
                                            Attribute.ol.key, null)
                                        : Attribute.ol);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
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
                                  color:
                                      const Color(0xff323247).withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 64,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color:
                                      const Color(0xff323247).withOpacity(0.06),
                                  spreadRadius: 0,
                                  blurRadius: 128,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              padding: const EdgeInsets.all(8),
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
          height: 1.2,
        ),
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
      backgroundColor: theme.backgroundColor,
      surfaceTintColor: theme.backgroundColor,
      centerTitle: false,
      shadowColor: theme.grey[100],
      leadingWidth: 16,
      automaticallyImplyLeading: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16),
          child: Icon(LucideIcons.settings),
        ),
      ],
    );
  }
}
