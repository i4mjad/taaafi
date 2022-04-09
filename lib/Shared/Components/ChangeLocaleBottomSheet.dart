import 'package:flutter/material.dart';
import 'package:reboot_app_3/Shared/Constants.dart';
import 'package:reboot_app_3/main.dart';
import 'package:shared_preferences/shared_preferences.dart';


   void changeLanguage(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width / 3,
                      color: Colors.black12,
                    )
                  ],
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Choose a Language",
                      style: kPageTitleStyle.copyWith(fontSize: 22),
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "اختر اللغة المناسبة لك",
                      style: kPageTitleStyle.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //Arabic
                    GestureDetector(
                      onTap: () async {
                        await prefs.setString('languageCode', 'ar');
                        final arLocale =
                        Locale(prefs.getString("languageCode"), '');
                        MyApp.setLocale(context, arLocale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: primaryColor)),
                        child: Center(
                          child: Text(
                            "العربية",
                            style: kSubTitlesStyle.copyWith(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    //English
                    GestureDetector(
                      onTap: () async {
                        await prefs.setString('languageCode', 'en');
                        final enLocale =
                        Locale(prefs.getString("languageCode"), '');
                        MyApp.setLocale(context, enLocale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2.5,
                        height: 100,
                        decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.5),
                            border: Border.all(color: primaryColor)),
                        child: Center(
                          child: Text(
                            "ِEnglish",
                            style: kSubTitlesStyle.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        });
  }
