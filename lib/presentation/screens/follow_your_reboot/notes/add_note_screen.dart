import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';

import 'notes_screen.dart';

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();

  CollectionReference database = FirebaseFirestore.instance.collection("users");
  final user = FirebaseAuth.instance.currentUser;
  String lang;

  @override
  void initState() {
    super.initState();
    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: plainAppBar(context, "new-note"),
      body: Padding(
        padding: const EdgeInsets.only(right: 20.0, left: 20),
        child: Container(
          width: MediaQuery.of(context).size.width - 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
              ),
              Container(
                width: MediaQuery.of(context).size.width - 40,
                height: 45,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    color: theme.cardColor,
                    border: Border.all(color: theme.primaryColor, width: 0.5)),
                child: TextField(
                  controller: title,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      CupertinoIcons.pen,
                      color: theme.primaryColor,
                    ),
                    border: InputBorder.none,
                    hintText: "العنوان",
                    hintStyle: kSearchTextStyle.copyWith(
                        fontFamily: "DINNextLTArabic",
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
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
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    color: theme.cardColor,
                    border: Border.all(color: theme.primaryColor, width: 0.5)),
                child: TextField(
                  controller: body,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                      hintText: "النص",
                      hintStyle: kSubTitlesSubsStyle.copyWith(
                          fontSize: 14, color: theme.primaryColor),
                      contentPadding: EdgeInsets.only(
                          left: 12, right: 12, top: 12, bottom: 12),
                      border: InputBorder.none),
                ),
              ),
              SizedBox(
                height: 8,
              ),
              GestureDetector(
                onTap: () {
                  var _title = title?.text;
                  var _body = body?.text;

                  if (_title != null && _body != null) {
                    database.doc(user.uid).collection("userNotes").doc().set({
                      'title': _title.toString(),
                      "body": _body.toString(),
                      "timestamp": DateTime.now(),
                    }, SetOptions(merge: true));
                  }
                  HapticFeedback.mediumImpact();

                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => NotesScreen()));
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width - 40,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12.5),
                  ),
                  child: Center(
                    child: Text(
                      "حفظ",
                      style: kSubTitlesStyle.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
