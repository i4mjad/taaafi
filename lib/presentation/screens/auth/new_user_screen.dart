import 'package:flutter/material.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

class NewUserScreen extends StatelessWidget {
  NewUserScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = CustomBlocProvider.of<AccountBloc>(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(right: 20.0, left: 20),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate("welcome"),
                    style: kDisplayStyle.copyWith(
                        color: theme.primaryColor, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              SizedBox(
                height: 48,
              ),
              Text(
                AppLocalizations.of(context).translate('start-your-journy'),
                style: kHeadlineStyle.copyWith(
                    fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                AppLocalizations.of(context).translate('start-your-journy-p'),
                style: kBodyStyle.copyWith(height: 1.2),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      var selectedDate = await getDateTime(context);
                      await bloc.createNewData(selectedDate);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => CustomBlocProvider(
                            child: UserWrapper(),
                            bloc: AccountBloc(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 80,
                      width: ((MediaQuery.of(context).size.width - 40) - 8) / 2,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.5)),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('specific-day'),
                          style: kTitleSeconderyStyle,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await bloc.createNewData(DateTime.now()).then((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                CustomBlocProvider(
                              child:
                                  FollowYourRebootScreenAuthenticationWrapper(),
                              bloc: AccountBloc(),
                            ),
                          ),
                        );
                      });
                    },
                    child: Container(
                      height: 80,
                      width: ((MediaQuery.of(context).size.width - 40) - 8) / 2,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12.5)),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).translate('today'),
                          style: kTitleSeconderyStyle.copyWith(
                              color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime> getDateTime(BuildContext context) async {
    return await showRoundedDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      borderRadius: 16,
      fontFamily: 'DINNextLTArabic',
      height: MediaQuery.of(context).size.height / 2.5,
      theme: ThemeData(
        primaryColor: lightPrimaryColor,
      ),
    );
  }
}
