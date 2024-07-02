import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/providers/notes/notes_providers.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen>
    with AutomaticKeepAliveClientMixin<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // This line is necessary to call wantKeepAlive.

    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8),
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).translate("title"),
              hintStyle: kSubTitlesStyle.copyWith(
                color: theme.primaryColor,
                height: 1.75,
              ),
              contentPadding: EdgeInsets.only(left: 12, right: 12),
            ),
            style: kSubTitlesStyle.copyWith(
              color: theme.primaryColor,
              height: 1.75,
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              controller: _bodyController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).translate("body"),
                border: InputBorder.none,
                hintStyle: kSubTitlesSubsStyle.copyWith(
                  fontSize: 18,
                  color: theme.primaryColor,
                  height: 1.75,
                ),
                contentPadding: EdgeInsets.only(left: 12, right: 12),
              ),
              maxLines: null,
              style: kSubTitlesSubsStyle.copyWith(
                fontSize: 18,
                color: theme.primaryColor,
                height: 1.25,
              ),
              expands: true,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isKeyboardVisible) {
            // Dismiss the keyboard
            FocusScope.of(context).unfocus();
          } else {
            // Save the note
            final title = _titleController.text;
            final body = _bodyController.text;

            await ref.read(noteViewModelProvider.notifier).addNote(
                  title: title,
                  body: body,
                );

            Navigator.pop(context);
          }
        },
        child: Icon(
          !_isKeyboardVisible ? Iconsax.save_2 : Iconsax.arrow_down,
          color: theme.primaryColor,
        ),
        backgroundColor: theme.cardColor,
      ),
    );
  }
}
