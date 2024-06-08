// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:reboot_app_3/data/models/Note.dart';

import 'package:reboot_app_3/providers/notes/notes_providers.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization.dart';

class NoteScreen extends ConsumerStatefulWidget {
  NoteScreen(this.note, this.id);
  var note;
  var id;

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> {
  TextEditingController _titleController = new TextEditingController();
  TextEditingController _bodyController = new TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title ?? '');
    _bodyController = TextEditingController(text: widget.note.body ?? '');

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
    final theme = Theme.of(context);

    return GestureDetector(
      child: Scaffold(
        appBar: noteAppBarWithCustomTitle(
            context, widget.note.title, ref, widget.note.id),
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
                controller: _bodyController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
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
              // Update the note
              final title = _titleController.text;
              final body = _bodyController.text;
              final id = widget.note.id;

              final editedNote = Note(
                body: body,
                title: title,
                timestamp: DateTime.now(),
              );
              editedNote.setId(id);
              await ref
                  .read(noteViewModelProvider.notifier)
                  .updateNote(editedNote);
            }
          },
          child: Icon(
            !_isKeyboardVisible ? Iconsax.save_2 : Iconsax.arrow_down,
            color: theme.primaryColor,
          ),
          backgroundColor: theme.cardColor,
        ),
      ),
    );
  }
}
