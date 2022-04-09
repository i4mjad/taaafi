import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/Shared/Localization.dart';
import 'package:reboot_app_3/Shared/Constants.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: seconderyColor,
            body: Padding(
              padding: EdgeInsets.fromLTRB(20, 80,20,0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(28, 12, 28, 12),
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.5)
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate("soon").toUpperCase(),
                        style: kSubTitlesStyle.copyWith(
                            color: primaryColor,
                            fontSize: 16,
                            height: 1
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration : BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [primaryColor, accentColor]),
                          borderRadius: BorderRadius.circular(50)
                      ),
                      child: Icon(
                        Iconsax.people,
                        color: Colors.white,
                      ),
                      
                    ),
                      Text(
                        AppLocalizations.of(context).translate("ta3afi-community"),
                        style: kPageTitleStyle.copyWith(
                          fontSize: 32,
                          color: primaryColor,
                          fontWeight: FontWeight.w700
                        ),
                      ),
                    SizedBox(height: 12,),
                    Container(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                              child: Text(
                                AppLocalizations.of(context).translate("ta3afi-community-p"),
                                style: kSubTitlesStyle.copyWith(
                                    color: Colors.black45,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ))
                        ],
                      ),
                    ),
                    SizedBox(height: 60,),
                    InkWell(
                      onTap: () => launch('mailto:ta3afiapp@gmail.com'),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(28, 12, 28, 12),
                        decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10.5)
                        ),
                        child: Text(
                          AppLocalizations.of(context).translate("share-suggestion"),
                          style: kSubTitlesStyle.copyWith(
                              color: accentColor,
                              fontSize: 12,
                              height: 1
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),


                  ]
                ),
              ),
            ),
      )
    );
  }
}
