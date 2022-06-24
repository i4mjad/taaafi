import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/home/widgets/explore_widget.dart';
import 'package:reboot_app_3/presentation/screens/home/widgets/welcome_widget.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';
import 'package:reboot_app_3/presentation/Screens/ta3afi_liberary/widgets/content_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithSettings(context, "home"),
      body: Padding(
        padding: EdgeInsets.only(left: 20.0, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TobBar(),
              SizedBox(
                height: 16,
              ),
              WelcomeWidget(),
              SizedBox(
                height: 16,
              ),
              ExploreWidget(),
              SizedBox(
                height: 16,
              ),
              Ta3afiLiberaryWidget(),
              SizedBox(
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Ta3afiLiberaryWidget extends StatelessWidget {
  const Ta3afiLiberaryWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).translate('nofap-content'),
          style: kSubTitlesStyle,
        ),
        SizedBox(
          height: 8,
        ),
        Ta3afiLiberaryCard(),
      ],
    );
  }
}

class Ta3afiLiberaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width - 40,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.5),
          border: Border.all(
              width: 0.25, color: lightPrimaryColor.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context).translate('porn-addiction-recovery-p'),
            style: kSubTitlesSubsStyle.copyWith(
                color: lightPrimaryColor, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12, left: 12, top: 30, bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.message_edit,
                  color: lightPrimaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.video,
                  color: lightPrimaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.document,
                  color: lightPrimaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.book,
                  color: lightPrimaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ContentScreen()));
                },
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.40,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: lightPrimaryColor,
                        borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("explore-content"),
                          style: kPageTitleStyle.copyWith(
                              fontSize: 14,
                              color: seconderyColor,
                              height: 1,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )),
              )
            ],
          )
        ],
      ),
    );
  }
}
