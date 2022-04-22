import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';

// ignore: must_be_immutable
class NoteScreen extends StatefulWidget {
  DocumentSnapshot noteToEdit;
  NoteScreen({this.noteToEdit});

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();

  CollectionReference database = FirebaseFirestore.instance.collection("users");
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    setState(() {
      title.text = (widget.noteToEdit.data() as Map)['title'].toString();
      body.text = (widget.noteToEdit.data() as Map)['body'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.only(right: 20.0, left: 20),
                child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: mainGrayColor,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.arrow_left,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      confirmDeleteDialog();
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.deepOrange,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.delete,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 12,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      var _title = title?.text;
                                      var _body = body?.text;

                                      if (_title != null && _body != null) {
                                        database
                                            .doc(user.uid)
                                            .collection("userNotes")
                                            .doc(this.widget.noteToEdit.id)
                                            .update({
                                          'title': _title.toString(),
                                          "body": _body.toString(),
                                        });

                                        FocusScope.of(context).unfocus();
                                      }
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: primaryColor,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.floppy_disk,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 40.0),
                            child: Text(
                              (this.widget.noteToEdit.data() as Map)["title"],
                              style: kPageTitleStyle,
                            ),
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width - 40,
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              color: mainGrayColor,
                            ),
                            child: TextField(
                              controller: title,
                              style: kSubTitlesStyle.copyWith(
                                  fontSize: 14,
                                  height: 1,
                                  fontWeight: FontWeight.w400),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  CupertinoIcons.pen,
                                  color: primaryColor,
                                ),
                                border: InputBorder.none,
                                hintText: "Title",
                                hintStyle: kSubTitlesSubsStyle.copyWith(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    height: 1.75),
                                contentPadding:
                                    EdgeInsets.only(left: 12, right: 12),
                              ),
                            ),
                          ),
                          //content-list
                          SizedBox(
                            height: 8,
                          ),
                          Expanded(
                              child: Container(
                                  width: MediaQuery.of(context).size.width - 40,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12.0)),
                                    color: mainGrayColor,
                                  ),
                                  child: TextField(
                                    controller: body,
                                    style: kSubTitlesStyle.copyWith(
                                        fontSize: 14,
                                        height: 1.3,
                                        fontWeight: FontWeight.w400),
                                    maxLines: null,
                                    expands: true,
                                    decoration: InputDecoration(
                                        hintText: "Body",
                                        hintStyle: kSubTitlesSubsStyle.copyWith(
                                          fontSize: 20,
                                        ),
                                        contentPadding: EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            top: 12,
                                            bottom: 12),
                                        border: InputBorder.none),
                                  )))
                        ])))));
  }

  void confirmDeleteDialog() {
    // set up the button
    Widget confirmButton = TextButton(
        child: Text(
          "حذف",
          style: kSubTitlesSubsStyle.copyWith(color: Colors.red, fontSize: 18),
        ),
        onPressed: () {
          database
              .doc(user.uid)
              .collection("userNotes")
              .doc(this.widget.noteToEdit.id)
              .delete()
              .whenComplete(() => Navigator.pop(context));
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
        style: kSubTitlesStyle.copyWith(color: primaryColor, fontSize: 14),
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
