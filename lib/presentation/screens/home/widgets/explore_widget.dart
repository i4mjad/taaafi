import 'package:flutter/material.dart';
import 'package:reboot_app_3/data/models/WelcomeContent.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).translate('explore'),
              style: kSubTitlesStyle,
            ),
            Text(
              "تصفح الكل",
              style:
                  kSubTitlesStyle.copyWith(fontSize: 12, color: primaryColor),
            )
          ],
        ),
        SizedBox(
          height: 8,
        ),
        Row(
          children: [
            Builder(builder: (BuildContext context) {
              return Expanded(
                child: Container(
                  height: 150,
                  child: Column(
                    children: [
                      Expanded(child: Builder(builder: (context) {
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              padding: EdgeInsets.all(16),
                              width: MediaQuery.of(context).size.width * 0.35,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: primaryColor, width: 0.25),
                                  borderRadius: BorderRadius.circular(12.5)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: primaryColor,
                                    child: FAKE_CONTENT[index].icon,
                                  ),
                                  Spacer(),
                                  Container(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Flexible(
                                            child: Text(
                                                FAKE_CONTENT[index].title,
                                                style: kSubTitlesSubsStyle
                                                    .copyWith(
                                                        color: primaryColor,
                                                        fontWeight:
                                                            FontWeight.w500)))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return SizedBox(width: 16);
                          },
                        );
                      })),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
