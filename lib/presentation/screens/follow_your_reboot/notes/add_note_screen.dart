import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/providers/notes/notes_providers.dart';

import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen>
    with AutomaticKeepAliveClientMixin<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // This line is necessary to call wantKeepAlive.

    final theme = Theme.of(context);
    return Scaffold(
      appBar: plainAppBar(context, "new-note"),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8),
          TextField(
            onTap: (() => FocusScope.of(context).unfocus()),
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
          Iconsax.save_2,
          color: theme.primaryColor,
        ),
        backgroundColor: theme.cardColor,
      ),
    );
  }
}
