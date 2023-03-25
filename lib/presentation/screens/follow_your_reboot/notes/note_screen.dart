import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/Note.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/notes/notes_screen.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

// ignore: must_be_immutable
class NoteScreen extends StatefulWidget {
  NoteScreen({this.note, this.id});
  Note note;
  String id;

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();

  @override
  void initState() {
    super.initState();

    setState(() {
      title.text = widget.note.title;
      body.text = widget.note.body;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: appBarWithCustomTitle(context, widget.note.title),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 20.0, left: 20, top: 20),
            child: Container(
              width: MediaQuery.of(context).size.width - 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 40,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      color: theme.cardColor,
                      border: Border.all(color: theme.primaryColor, width: 0.5),
                    ),
                    child: TextField(
                      onTap: (() => FocusScope.of(context).unfocus()),
                      controller: title,
                      style: kSubTitlesStyle.copyWith(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          color: theme.primaryColor),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          CupertinoIcons.pen,
                          color: theme.primaryColor,
                        ),
                        border: InputBorder.none,
                        hintText: "Title",
                        hintStyle: kSubTitlesSubsStyle.copyWith(
                          fontSize: 18,
                          color: theme.primaryColor,
                          height: 1.75,
                        ),
                        contentPadding: EdgeInsets.only(left: 12, right: 12),
                      ),
                    ),
                  ),
                  //content-list
                  SizedBox(
                    height: 8,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width - 40,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        color: theme.cardColor,
                        border:
                            Border.all(color: theme.primaryColor, width: 0.5)),
                    child: TextField(
                      onTap: (() => FocusScope.of(context).unfocus()),
                      controller: body,
                      style: kSubTitlesStyle.copyWith(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                          color: theme.primaryColor),
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                          hintText: "Body",
                          hintStyle: kSubTitlesSubsStyle.copyWith(
                            fontSize: 20,
                          ),
                          contentPadding: EdgeInsets.only(
                              left: 12, right: 12, top: 12, bottom: 12),
                          border: InputBorder.none),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            confirmDeleteDialog(
                                bloc, theme, context, widget.note.noteId);
                          },
                          child: Container(
                            height: 50,
                            width: (MediaQuery.of(context).size.width * 0.5) -
                                (32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.5),
                              color: Colors.red,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate("delete"),
                                style: kSubTitlesStyle.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            var _title = title?.text;
                            var _body = body?.text;
                            var _id = widget.note.noteId;

                            await bloc.updateNote(_id, _title, _body);

                            HapticFeedback.lightImpact();
                            FocusScope.of(context).unfocus();
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 50,
                            width: (MediaQuery.of(context).size.width * 0.5) -
                                (32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.50),
                              color: theme.cardColor,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context).translate("save"),
                                style: kSubTitlesStyle.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w500),
                              ),
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
        ),
      ),
    );
  }

  void confirmDeleteDialog(FollowYourRebootBloc bloc, ThemeData theme,
      BuildContext context, String id) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding:
                  EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width / 5,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    AppLocalizations.of(context)
                        .translate("confirm-note-delete"),
                    style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await bloc.deleteNote(id);
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomBlocProvider(
                                  bloc: FollowYourRebootBloc(),
                                  child: NotesScreen(),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 50,
                            width: (MediaQuery.of(context).size.width * 0.5) -
                                (32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.5),
                              color: Colors.red,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate("delete"),
                                style: kSubTitlesStyle.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 50,
                            width: (MediaQuery.of(context).size.width * 0.5) -
                                (32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.50),
                              color: theme.cardColor,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)
                                    .translate("cancel"),
                                style: kSubTitlesStyle.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}
