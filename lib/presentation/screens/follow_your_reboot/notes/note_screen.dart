import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/data/models/Note.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

// ignore: must_be_immutable
class NoteScreen extends StatefulWidget {
  Note note;
  NoteScreen({this.note});

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
      title.text = widget.note.id;
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
                            height: 1.75),
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
                            confirmDeleteDialog();
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

                            await bloc.updateNote(
                                widget.note.id, _title, _body);

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

  void confirmDeleteDialog() {
    // set up the button
    Widget confirmButton = TextButton(
        child: Text(
          "حذف",
          style: kSubTitlesSubsStyle.copyWith(color: Colors.red, fontSize: 18),
        ),
        onPressed: () {
          // database
          //     .doc(user.uid)
          //     .collection("userNotes")
          //     .doc(this.widget.noteToEdit.id)
          //     .delete()
          //     .whenComplete(() => Navigator.pop(context));
        });

    Widget cancelButton = TextButton(
        child: Text(
          "إلغاء",
          style: kSubTitlesSubsStyle.copyWith(color: Colors.grey, fontSize: 18),
        ),
        onPressed: () {
          Navigator.pop(context);
        });

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        "هل أنت متأكد؟",
        style: kSubTitlesStyle.copyWith(color: lightPrimaryColor, fontSize: 14),
      ),
      content: Text("سيتم حذف المذكرة بشكل نهائي",
          style: kSubTitlesStyle.copyWith(color: Colors.black, fontSize: 14)),
      actions: [confirmButton, cancelButton],
    );

    // show the dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
