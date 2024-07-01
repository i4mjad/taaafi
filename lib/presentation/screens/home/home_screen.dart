import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/core/theming/spacing.dart';
import 'package:reboot_app_3/presentation/screens/home/widgets/welcome_widget.dart';
import 'package:reboot_app_3/shared/components/custom-app-bar.dart';
import 'package:reboot_app_3/core/localization/localization.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/core/localization/localization_services.dart';
import 'package:reboot_app_3/shared/services/app_review_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  var lang;
  final RatingService _ratingService = RatingService();

  @override
  void initState() {
    super.initState();

    LocaleService.getSelectedLocale().then((value) {
      setState(() {
        lang = value;
      });
    });

    Timer(const Duration(seconds: 2), () {
      _ratingService.isSecondTimeOpen().then((secondOpen) {
        if (secondOpen) {
          _ratingService.showRating();
        }
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
              SizedBox(
                height: 24,
              ),
              WelcomeWidget(),

              verticalSpace(Spacing.points32),
              // CustomBlocProvider(
              //   bloc: ContentBloc(),
              //   child: ExploreWidget(),
              // ),

              Ta3afiLiberaryWidget(),
              SizedBox(
                height: 24,
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).translate('nofap-content'),
          style: kSubTitlesStyle.copyWith(color: theme.hintColor),
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
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20),
      width: MediaQuery.of(context).size.width - 40,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context).translate('porn-addiction-recovery-p'),
            style: kSubTitlesSubsStyle.copyWith(
                color: theme.primaryColor, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: EdgeInsets.only(right: 12, left: 12, top: 30, bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.message_edit,
                  color: theme.primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.video,
                  color: theme.primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.document,
                  color: theme.primaryColor,
                  size: 28,
                ),
                Icon(
                  Iconsax.book,
                  color: theme.primaryColor,
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
                  // Navigator.push(context,
                  //     MaterialPageRoute(builder: (context) => ContentScreen()));
                  context.go('/home/content');
                },
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.40,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate("explore-content"),
                          style: kPageTitleStyle.copyWith(
                              fontSize: 14,
                              color: theme.scaffoldBackgroundColor,
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
