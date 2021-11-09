
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Localization.dart';
import 'package:reboot_app_3/Services/Constants.dart';

class UserCommunityProfile extends StatefulWidget {
  const UserCommunityProfile({key}) : super(key: key);

  @override
  _UserCommunityProfileState createState() => _UserCommunityProfileState();
}

class _UserCommunityProfileState extends State<UserCommunityProfile> {


  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseFirestore database = FirebaseFirestore.instance;

  User user = FirebaseAuth.instance.currentUser;

  int segmentedControlValue = 0;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.only(top: 100.0, left: 20.0, right: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                      ),
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(context).translate('my-profile'),
                  style: kPageTitleStyle.copyWith(height: 1),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Container(
                width: MediaQuery.of(context).size.width - 40,
                height: MediaQuery.of(context).size.height * 0.175,
                decoration: BoxDecoration(
                    color: mainGrayColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black12)),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.personalcard,
                        size: 75,
                        color: primaryColor,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            this.user.displayName != null
                                ? this.user.displayName
                                : "",
                            style: kPageTitleStyle.copyWith(
                              fontSize: 22,
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "23",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Posts",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "232",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Likes",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "1.5K",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Likes",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ])
                        ],
                      ),
                    ],
                  ),
                )),
            SizedBox(
              height: 12,
            ),
            Text(AppLocalizations.of(context).translate('community'),
                style: kSubTitlesStyle),
            SizedBox(
              height: 12,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    width: (MediaQuery.of(context).size.width - 40) * 0.475,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        border: Border.all(width: 0.25, color: Colors.grey)),
                    child: Center(
                      child: Text(
                          AppLocalizations.of(context).translate('my-posts'),
                          style: kSubTitlesSubsStyle.copyWith(
                              fontSize: 14, color: primaryColor, height: 1)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    print("");
                  },
                  child: Container(
                    height: 40,
                    width: (MediaQuery.of(context).size.width - 40) * 0.475,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        border: Border.all(width: 0.25, color: Colors.grey)),
                    child: Center(
                      child: Text(
                          AppLocalizations.of(context).translate('my-likes'),
                          style: kSubTitlesSubsStyle.copyWith(
                              fontSize: 14, color: primaryColor, height: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
