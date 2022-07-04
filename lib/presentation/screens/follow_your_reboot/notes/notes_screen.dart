import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/Note.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'note_screen.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final database = FirebaseFirestore.instance.collection('users');

  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: notesAppBar(context, "dairies"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20, top: 20),
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomBlocProvider(
                  child: NotesListView(),
                  bloc: FollowYourRebootBloc(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotesListView extends StatelessWidget {
  NotesListView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    return StreamBuilder(
      stream: bloc.getNotes(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        switch (snapshot.connectionState) {
          // Uncompleted State
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(child: CircularProgressIndicator());
            break;
          default:
            // Completed with error
            if (snapshot.hasError || !snapshot.hasData) {
              return Container(
                child: Center(
                  child: Text(
                    snapshot.error.toString(),
                  ),
                ),
              );
            }

            var notesList = snapshot.data.docs
                .map((e) => Note.fromMap(e.data(), e.id))
                .toList();
            return Expanded(
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemCount: notesList.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomBlocProvider(
                            bloc: FollowYourRebootBloc(),
                            child: NoteScreen(
                                note: notesList[index],
                                id: notesList[index].noteId),
                          ),
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
                              notesList[index].title,
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
      },
    );
  }
}
