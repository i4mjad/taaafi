import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reboot_app_3/data/models/ExploreContent.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class ExploreWidget extends StatelessWidget {
  const ExploreWidget({
    Key key,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).translate("explore"), style: kSubTitlesStyle,),
        SizedBox(height: 8,),
        Row(
          children: [
            Builder(
                builder: (BuildContext context) {
                  return Expanded(
                    child: Container(
                      height: 150,
                      child: Column(
                        children: [
                          Expanded(child: Builder(builder: (context) {
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder:(BuildContext context, int index) {
                                return GestureDetector(
                                  onTap: (){
                                    HapticFeedback.heavyImpact();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    width: MediaQuery.of(context).size.width - 150,
                                    height: 125,
                                    decoration: BoxDecoration(
                                      color: FAKE_EXPLORE_CONTENT[index].bgColor,
                                      border: Border.all(color: primaryColor, width: 0.25),
                                      borderRadius: BorderRadius.circular(12.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                            FAKE_EXPLORE_CONTENT[index].title,
                                          style: kSubTitlesStyle.copyWith(
                                            color: FAKE_EXPLORE_CONTENT[index].txtColor
                                          ),
                                        )
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