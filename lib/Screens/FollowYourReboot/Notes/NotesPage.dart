import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:reboot_app_3/screens/FollowYourReboot/Notes/AddNoteScreen.dart';
import 'package:reboot_app_3/screens/FollowYourReboot/FollowYourRebootScreen.dart';

import 'package:reboot_app_3/Localization.dart';

import 'package:reboot_app_3/Services/Constants.dart';
import 'EditNotePage.dart';

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
                                    CupertinoIcons.xmark,
                                    size: 20,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddNoteScreen()));
                                },
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: primaryColor,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.plus,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 2 - .0),
                            child: Text(
                              AppLocalizations.of(context).translate('dairies'),
                              style: kPageTitleStyle,
                            ),
                          ),
                          //searchbar
                          //content-list
                          Expanded(
                            child: Container(
                                width: MediaQuery.of(context).size.width - 40,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: StreamBuilder(
                                    stream: database
                                        .doc(user.uid)
                                        .collection("userNotes")
                                        .snapshots(),
                                    builder: (context,
                                        AsyncSnapshot<QuerySnapshot> snapshot) {
                                      return GridView.builder(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  crossAxisSpacing: 5,
                                                  mainAxisSpacing: 5),
                                          itemCount: snapshot.hasData
                                              ? snapshot.data.size
                                              : 0,
                                          itemBuilder: (_, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) => NoteScreen(
                                                            noteToEdit: snapshot
                                                                .data
                                                                .docs[index])));
                                              },
                                              child: Container(
                                                  //margin: EdgeInsets.only(top:20, bottom: 20, left: 0, right: 0),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.30,
                                                  height: 150,
                                                  decoration: BoxDecoration(
                                                    color: mainGrayColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.5),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 20,
                                                            left: 20,
                                                            top: 20,
                                                            bottom: 20),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          (snapshot.data
                                                                      .docs[index]
                                                                      .data()
                                                                  as Map)["title"]
                                                              .toString(),
                                                          style: kSubTitlesSubsStyle
                                                              .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      primaryColor,
                                                                  fontSize: 16),
                                                        ),
                                                        Text(
                                                          (snapshot.data.docs[index]
                                                                              .data()
                                                                          as Map)[
                                                                      "timestamp"] !=
                                                                  null
                                                              ? DateTime.parse((snapshot
                                                                          .data
                                                                          .docs[
                                                                              index]
                                                                          .data() as Map)["timestamp"]
                                                                      .toDate()
                                                                      .toString())
                                                                  .toString()
                                                                  .substring(0, 16)
                                                              : "",
                                                          style: kSubTitlesSubsStyle
                                                              .copyWith(
                                                                  color: Colors
                                                                          .grey[
                                                                      500],
                                                                  fontSize: 16),
                                                        )
                                                      ],
                                                    ),
                                                  )),
                                            );
                                          });
                                    },
                                  ),
                                )),
                          )
                        ])))));
  }
}
