import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reboot_app_3/Services/Constants.dart';
import 'package:reboot_app_3/Localization.dart';
import 'package:reboot_app_3/screens/FollowYourReboot/Notes/NotesPage.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

    void getSelectedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    

    String _languageCode = await prefs.getString("languageCode");
    setState(() {
      lang = _languageCode;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {});
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
                                    lang != "ar" ? CupertinoIcons.arrow_left : CupertinoIcons.arrow_right,
                                    size: 20,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  var _title = title?.text;
                                  var _body = body?.text;

                                  if (_title != null && _body != null) {
                                    database
                                        .doc(user.uid)
                                        .collection("userNotes")
                                        .doc()
                                        .set({
                                      'title': _title.toString(),
                                      "body": _body.toString(),
                                      "timestamp": DateTime.now(),
                                    }, SetOptions(merge: true)).then((_) {
                                      print(
                                          "success! note has been added to cloud firestore");
                                    });
                                  }

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => NotesScreen()));
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
                          Padding(
                            padding: EdgeInsets.only(top: 20.0),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate("new-note"),
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
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  CupertinoIcons.pen,
                                  color: primaryColor,
                                ),
                                border: InputBorder.none,
                                hintText: "العنوان",
                                hintStyle: kSearchTextStyle.copyWith(
                                    fontFamily: "DINNextLTArabic",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
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
                                    maxLines: null,
                                    expands: true,
                                    decoration: InputDecoration(
                                        hintText: "النص",
                                        hintStyle: kSubTitlesSubsStyle.copyWith(
                                          fontSize: 14,
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
}
