import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/core/shared_widgets/container.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/core/theming/custom_theme_data.dart';
import 'package:reboot_app_3/core/theming/font_weights.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/core/theming/text_styles.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary.dart';
import 'package:reboot_app_3/features/vault/data/diaries/diary_notifier.dart';
import 'package:reboot_app_3/features/vault/presentation/diaries/diary_settings_sheet.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key, required this.diaryId});

  final String diaryId;

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;
  bool _isInitialized = false;
  bool _isSettingsSheetOpen = false;

  void _initializeEditor(Diary diary) {
    Document doc;
    if (diary.formattedContent != null) {
      try {
        var operations = diary.formattedContent!;

        // Create a new Delta and add each operation
        final delta = Delta();
        for (final op in operations) {
          if (op['insert'] != null) {
            if (op['attributes'] != null) {
              delta.insert(op['insert'], op['attributes']);
            } else {
              delta.insert(op['insert']);
            }
          }
        }

        doc = Document.fromDelta(delta);
      } catch (e) {
        doc = Document()..insert(0, diary.plainText);
      }
    } else {
      doc = Document()..insert(0, diary.plainText);
    }

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final diaryAsync = ref.watch(diaryNotifierProvider(widget.diaryId));

    return diaryAsync.when(
      data: (diary) {
        if (diary == null) {
          return Scaffold(
            body: Center(
              child: Text('Diary not found'),
            ),
          );
        }

        // Initialize only once when diary is first loaded
        if (!_isInitialized) {
          _initializeEditor(diary);
          _isInitialized = true;
        }

        return Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: _appBar(diary, theme),
            body: SafeArea(
              child: AbsorbPointer(
                absorbing: _isSettingsSheetOpen,
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
                                  AppLocalizations.of(context)
                                          .translate('linked-activities') +
                                      ": ",
                                  style: TextStyles.h6,
                                ),
                                horizontalSpace(Spacing.points4),
                                Flexible(
                                  child: Wrap(
                                    spacing: 4,
                                    children: diary.linkedTasks.map((activity) {
                                      return WidgetsContainer(
                                        borderRadius: BorderRadius.circular(6),
                                        padding:
                                            EdgeInsets.fromLTRB(8, 2, 8, 2),
                                        child: Text(
                                          activity.task.name,
                                          style: TextStyles.tiny
                                              .copyWith(color: theme.grey[900]),
                                        ),
                                        backgroundColor: theme.backgroundColor,
                                        borderSide: BorderSide(
                                            color: theme.grey[600]!,
                                            width: 0.5),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom:
                                      64), // Adjust this value according to your control's height
                              child: QuillEditor.basic(
                                controller: _controller,
                                focusNode: _focusNode,
                                scrollController: ScrollController(),
                                configurations: QuillEditorConfigurations(
                                  autoFocus: false,
                                  onTapOutside: (event, focusNode) {
                                    //! this is commented to test why it is causing the focus is always gained when tapping outside
                                    // _controller.updateSelection(
                                    //   TextSelection.collapsed(
                                    //       offset:
                                    //           _controller.selection.baseOffset),
                                    //   ChangeSource.local,
                                    // );

                                    // Collapsing the selection:
                                    _controller.updateSelection(
                                      const TextSelection.collapsed(
                                          offset: 0), // or 0
                                      ChangeSource.local,
                                    );
                                    // Or if you want to simply unfocus:
                                    focusNode.unfocus();
                                  },
                                  customStyles: DefaultStyles(
                                    paragraph: DefaultTextBlockStyle(
                                      TextStyles.body
                                          .copyWith(color: theme.grey[900]),
                                      HorizontalSpacing(0, 0),
                                      VerticalSpacing(0, 0),
                                      VerticalSpacing(0, 0),
                                      BoxDecoration(),
                                    ),
                                    h4: DefaultTextBlockStyle(
                                      TextStyles.h4
                                          .copyWith(color: theme.grey[900]),
                                      HorizontalSpacing(0, 0),
                                      VerticalSpacing(0, 0),
                                      VerticalSpacing(0, 0),
                                      BoxDecoration(),
                                    ),
                                    lists: DefaultListBlockStyle(
                                      TextStyles.body
                                          .copyWith(color: theme.grey[900]),
                                      HorizontalSpacing(0, 0),
                                      VerticalSpacing(0, 0),
                                      VerticalSpacing(0, 0),
                                      BoxDecoration(),
                                      null,
                                    ),
                                    bold: TextStyles.body.copyWith(
                                      fontWeight: FontWeightHelper.semiBold,
                                      color: theme.grey[900],
                                    ),
                                    italic: TextStyles.body.copyWith(
                                      fontWeight: FontWeightHelper.semiBold,
                                      fontStyle: FontStyle.italic,
                                      color: theme.grey[900],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  if (_isKeyboardVisible) ...[
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        _focusNode.unfocus();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          boxShadow: Shadows.mainShadows,
                                          color: theme.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          border: Border.all(
                                            color: theme.grey[600]!,
                                            width: 0.125,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.keyboard,
                                          size: 16,
                                          color: theme.grey[900],
                                        ),
                                      ),
                                    ),
                                    horizontalSpace(Spacing.points8),
                                  ],
                                  Expanded(
                                    child: WidgetsContainer(
                                      backgroundColor: theme.backgroundColor,
                                      boxShadow: Shadows.mainShadows,
                                      borderSide: BorderSide(
                                          color: theme.grey[600]!,
                                          width: 0.125),
                                      borderRadius: BorderRadius.circular(10.5),
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  if (!_focusNode.hasFocus) {
                                                    _focusNode.requestFocus();
                                                  }
                                                  // Toggle heading style
                                                  final isHeading = _controller
                                                      .getSelectionStyle()
                                                      .attributes
                                                      .containsKey('h4');
                                                  _controller.formatSelection(
                                                    isHeading
                                                        ? Attribute
                                                            .fromKeyValue(
                                                                Attribute
                                                                    .h4.key,
                                                                null)
                                                        : Attribute.h4,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
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
                                                  if (!_focusNode.hasFocus) {
                                                    _focusNode.requestFocus();
                                                  }
                                                  final isBold = _controller
                                                      .getSelectionStyle()
                                                      .attributes
                                                      .containsKey('bold');
                                                  _controller.formatSelection(
                                                      isBold
                                                          ? Attribute
                                                              .fromKeyValue(
                                                                  Attribute
                                                                      .bold.key,
                                                                  null)
                                                          : Attribute.bold);
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate('bold'),
                                                      style:
                                                          TextStyles.smallBold),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  if (!_focusNode.hasFocus) {
                                                    _focusNode.requestFocus();
                                                  }
                                                  final isItalic = _controller
                                                      .getSelectionStyle()
                                                      .attributes
                                                      .containsKey('italic');
                                                  _controller.formatSelection(
                                                      isItalic
                                                          ? Attribute
                                                              .fromKeyValue(
                                                                  Attribute
                                                                      .italic
                                                                      .key,
                                                                  null)
                                                          : Attribute.italic);
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate('italic'),
                                                      style: TextStyles.small),
                                                ),
                                              ),
                                              // Adding Quote
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  if (!_focusNode.hasFocus) {
                                                    _focusNode.requestFocus();
                                                  }
                                                  final isQuote = _controller
                                                      .getSelectionStyle()
                                                      .attributes
                                                      .containsKey(
                                                          'blockquote');
                                                  _controller.formatSelection(
                                                    isQuote
                                                        ? Attribute
                                                            .fromKeyValue(
                                                                Attribute
                                                                    .blockQuote
                                                                    .key,
                                                                null)
                                                        : Attribute.blockQuote,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate('quote'),
                                                      style: TextStyles.small),
                                                ),
                                              ),
                                              // Adding List (unordered)
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.mediumImpact();
                                                  if (!_focusNode.hasFocus) {
                                                    _focusNode.requestFocus();
                                                  }
                                                  final isList = _controller
                                                      .getSelectionStyle()
                                                      .attributes
                                                      .containsKey('list');
                                                  _controller.formatSelection(
                                                    isList
                                                        ? Attribute
                                                            .fromKeyValue(
                                                                Attribute
                                                                    .ol.key,
                                                                null)
                                                        : Attribute.ol,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate('list'),
                                                      style: TextStyles.small),
                                                ),
                                              ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              HapticFeedback.heavyImpact();
                                              await _saveDiary(diary);
                                            },
                                            child: WidgetsContainer(
                                              backgroundColor:
                                                  theme.backgroundColor,
                                              borderSide: BorderSide(
                                                  color: theme.grey[300]!,
                                                  width: 0.25),
                                              boxShadow: Shadows.mainShadows,
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                LucideIcons.save,
                                                size: 16,
                                                color: theme.grey[900],
                                              ),
                                            ),
                                          )

                                          // Save button
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
                    ],
                  ),
                ),
              ),
            ));
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  AppBar _appBar(Diary diary, CustomThemeData theme) {
    return AppBar(
      title: Text(
        diary.title == ""
            ? AppLocalizations.of(context).translate('new-diary')
            : diary.title,
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
        GestureDetector(
          onTap: () async {
            setState(() => _isSettingsSheetOpen = true);
            // todo : experiment with this

            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              useSafeArea: true,
              builder: (BuildContext context) {
                return DiarySettingsSheet(diary);
              },
            );
            setState(() => _isSettingsSheetOpen = false);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 16),
            child: Icon(LucideIcons.settings),
          ),
        ),
      ],
    );
  }

  Future<void> _saveDiary(Diary diary) async {
    final plainText = _controller.document.toPlainText();
    final delta = _controller.document.toDelta();
    final deltaJson = delta.toJson();

    await ref.read(diaryNotifierProvider(widget.diaryId).notifier).updateDiary(
          widget.diaryId,
          Diary(
            widget.diaryId,
            diary.title,
            plainText,
            diary.date,
            formattedContent: deltaJson,
            updatedAt: DateTime.now(),
          ),
        );
  }
}
