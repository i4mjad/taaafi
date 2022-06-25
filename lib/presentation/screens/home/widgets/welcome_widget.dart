import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User firebaseUser = context.watch<User>();
    if (firebaseUser == null) {
      return NotSignIn();
    }
    return CustomBlocProvider(
        bloc: FollowYourRebootBloc(), child: WelcomeContent());
  }
}

class NotSignIn extends StatelessWidget {
  const NotSignIn({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('welcome'),
          style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
        ),
        SizedBox(
          height: 8,
        ),
        Container(
          height: 150,
          padding: EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width - 40,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black,
                width: 0.25,
              ),
              borderRadius: BorderRadius.circular(12.5)),
          child: Center(
            child: Text(
              AppLocalizations.of(context).translate('not-login'),
              textAlign: TextAlign.center,
              style: kSubTitlesStyle.copyWith(
                  color: lightPrimaryColor,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  fontSize: 16),
            ),
          ),
        )
      ],
    );
  }
}

class WelcomeContent extends StatelessWidget {
  const WelcomeContent({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<FollowYourRebootBloc>(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('welcome'),
          style: kSubTitlesStyle.copyWith(color: theme.hintColor),
        ),
        SizedBox(
          height: 8,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.27,
              height: 150,
              decoration: BoxDecoration(
                  color: theme.focusColor,
                  border: Border.all(
                    width: 0.25,
                    color: theme.primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FutureBuilder(
                    future: bloc.getRelapseStreak(),
                    initialData: 0,
                    builder: (BuildContext context, AsyncSnapshot<int> streak) {
                      return Text(
                        streak.data.toString(),
                        style: kPageTitleStyle.copyWith(
                          color: Colors.white,
                          fontSize: 35,
                        ),
                      );
                    },
                  ),
                  Text(
                    AppLocalizations.of(context).translate('free-relapse-days'),
                    style: kSubTitlesStyle.copyWith(
                        fontSize: 16, color: Colors.white, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Spacer(),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  height: 71,
                  width: MediaQuery.of(context).size.width * 0.60,
                  decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(width: 0.25, color: theme.primaryColor)),
                  child: Center(
                    child: FutureBuilder(
                      future: bloc.getRelapsesCountInLast30Days(),
                      initialData: "0",
                      builder:
                          (BuildContext context, AsyncSnapshot<String> sh) {
                        return Text(
                          AppLocalizations.of(context)
                                  .translate("relapses-30-days") +
                              sh.data,
                          style: kSubTitlesStyle.copyWith(
                              fontSize: 13, color: theme.hintColor),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 8,
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  height: 71,
                  width: MediaQuery.of(context).size.width * 0.60,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(width: 0.25, color: theme.primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FutureBuilder(
                      future: bloc.getTotalDaysWithoutRelapse(),
                      initialData: "0",
                      builder:
                          (BuildContext context, AsyncSnapshot<String> sh) {
                        return Text(
                          AppLocalizations.of(context)
                                  .translate('free-days-from-start') +
                              sh.data,
                          style: kSubTitlesStyle.copyWith(
                              color: theme.hintColor, fontSize: 13),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }
}
