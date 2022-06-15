import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/data/models/WelcomeContent.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).translate('welcome'),style: kSubTitlesStyle,),
        SizedBox(height: 8,),
        Row(
          children: [
            Builder(
                builder: (BuildContext context) {
                  return Expanded(
                    child: Container(
                      height: 200,
                      child: Column(
                        children: [
                          Expanded(child: Builder(builder: (context) {
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder:(BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: (){
                                    HapticFeedback.lightImpact();

                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    width: MediaQuery.of(context).size.width * 0.35,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: primaryColor, width: 0.25),
                                        borderRadius: BorderRadius.circular(12.5)
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: primaryColor,
                                              child: FAKE_CONTENT[index].icon,
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                borderRadius: BorderRadius.circular(10.5),
                                              ),
                                              child: Text(
                                                  FAKE_CONTENT[index].subtitle,
                                                  style: kSubTitlesSubsStyle.copyWith(
                                                      color: Colors.white
                                                  )
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        Container(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                  child: Text(
                                                      FAKE_CONTENT[index].title,
                                                      style: kSubTitlesStyle.copyWith(
                                                          height: 1.2)
                                                  )
                                              )
                                            ],
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                );
                              }, separatorBuilder: (BuildContext context, int index) {
                              return SizedBox(width: 16);
                            },);
                          })),
                        ],
                      ),
                    ),
                  );
                }
            ),

          ],
        ),
      ],
    );
  }
}