import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/core/theming/app-themes.dart';
import 'package:reboot_app_3/data/models/Note.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/notes/add_note_screen.dart';
import 'package:reboot_app_3/providers/notes/notes_providers.dart';

import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'note_screen.dart';

class NotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20, top: 20),
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: NotesListView())],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNoteScreen(),
            ),
          );
        },
        backgroundColor: theme.primary[600],
        child: Center(
          child: Icon(
            Iconsax.add_square,
            size: 30,
            color: theme.backgroundColor,
          ),
        ),
      ),
    );
  }
}

class NotesListView extends ConsumerWidget {
  NotesListView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteViewModelProvider) as List<Note>;

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListView.separated(
        itemCount: notes.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteScreen(notes[index], notes[index].id),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10.5),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                    child: Center(
                      child: Icon(Iconsax.book),
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Flexible(
                    child: Text(
                      notes[index].title,
                      style: kSubTitlesStyle.copyWith(
                          color: theme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(height: 16);
        },
      ),
    );
  }
}
