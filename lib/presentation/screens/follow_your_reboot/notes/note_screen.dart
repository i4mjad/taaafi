import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:reboot_app_3/data/models/Note.dart';

import 'package:reboot_app_3/providers/notes/notes_providers.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

// ignore: must_be_immutable
class NoteScreen extends ConsumerWidget {
  NoteScreen({this.note, this.id});
  Note note;
  String id;

  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          appBar: noteAppBarWithCustomTitle(context, note.title, ref, note.id),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8),
              TextField(
                onTap: (() => FocusScope.of(context).unfocus()),
                controller: title..text = note.title,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).translate("title"),
                  // border: InputBorder,
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
                  onTap: (() => FocusScope.of(context).unfocus()),
                  controller: body..text = note.body,
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
              var _title = title?.text;
              var _body = body?.text; 
             var _id = note.id;

              var editedNote =
                  Note(body: _body, title: _title, timestamp: DateTime.now());
              editedNote.setId(_id);
              await ref
                  .read(noteViewModelProvider.notifier)
                  .updateNote(editedNote);
            },
            child: Icon(
              Iconsax.save_add,
              color: theme.primaryColor,
            ),
            backgroundColor: theme.cardColor,
          )),
    );
  }
}
