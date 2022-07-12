import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
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
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: plainAppBar(context, "new-note"),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  Container(
                    width: MediaQuery.of(context).size.width - 40,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      color: theme.cardColor,
                    ),
                    child: TextField(
                      onTap: () => FocusScope.of(context).unfocus(),
                      keyboardType: TextInputType.text,
                      controller: title,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          CupertinoIcons.pen,
                          color: theme.primaryColor,
                        ),
                        border: InputBorder.none,
                        hintText:
                            AppLocalizations.of(context).translate('title'),
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
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      color: theme.cardColor,
                    ),
                    child: TextField(
                      onTap: () => FocusScope.of(context).unfocus(),
                      controller: body,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context).translate("body"),
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
                    onTap: () async {
                      var _title = title?.text;
                      var _body = body?.text;
                      await bloc.addNote(_title, _body);

                      HapticFeedback.mediumImpact();

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NotesScreen()));
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
                          AppLocalizations.of(context).translate('save'),
                          style: kSubTitlesStyle.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
