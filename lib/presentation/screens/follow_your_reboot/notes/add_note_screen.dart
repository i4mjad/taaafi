import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/providers/notes/notes_providers.dart';

import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class AddNoteScreen extends ConsumerWidget {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: plainAppBar(context, "new-note"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8),
          TextField(
            controller: _titleController,
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
            
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = _titleController.text;
          final body = _bodyController.text;

          await ref.read(noteViewModelProvider.notifier).addNote(
                title: title,
                body: body,
              );

          Navigator.pop(context);
        },
        child: Icon(
          Iconsax.save_add,
          color: theme.primaryColor,
        ),
        backgroundColor: theme.cardColor,
      ),
    );
  }
}
