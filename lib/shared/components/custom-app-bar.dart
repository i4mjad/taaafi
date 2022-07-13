import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/notes/add_note_screen.dart';
import 'package:reboot_app_3/shared/components/change_locale_bottomsheet.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';
import 'package:reboot_app_3/shared/localization/localization.dart';

AppBar appBarWithSettings(BuildContext context, String titleId) {
  final theme = Theme.of(context);
  return AppBar(
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
    ),
    iconTheme: IconThemeData(
      color: theme.primaryColor,
    ),
    actions: [
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ChangeLanguageWidget.changeLanguage(context);
        },
        child: Container(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Center(
              child: Icon(
            Iconsax.setting,
            color: theme.primaryColor,
          )),
        ),
      ),
    ],
  );
}

AppBar notesAppBar(BuildContext context, String titleId) {
  final theme = Theme.of(context);
  return AppBar(
    backgroundColor: theme.scaffoldBackgroundColor,
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle.copyWith(
        color: theme.primaryColor,
      ),
    ),
    iconTheme: IconThemeData(
      color: theme.primaryColor,
    ),
    actions: [
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomBlocProvider(
                bloc: FollowYourRebootBloc(),
                child: AddNoteScreen(),
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Icon(
            Iconsax.element_plus,
            color: theme.primaryColor,
          ),
        ),
      )
    ],
  );
}

AppBar plainAppBar(BuildContext context, String titleId) {
  final theme = Theme.of(context);
  return AppBar(
    backgroundColor: theme.scaffoldBackgroundColor,
    elevation: 0,
    centerTitle: true,
    title: Text(
      AppLocalizations.of(context).translate(titleId),
      style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
    ),
    iconTheme: IconThemeData(
      color: theme.primaryColor,
    ),
  );
}

AppBar appBarWithCustomTitle(BuildContext context, String title) {
  final theme = Theme.of(context);
  return AppBar(
    backgroundColor: theme.bottomAppBarColor,
    elevation: 0,
    centerTitle: true,
    title: Text(
      title,
      style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
    ),
    iconTheme: IconThemeData(
      color: theme.primaryColor,
    ),
  );
}

AppBar appBarWithStreamBuilder(BuildContext context, Stream userStream) {
  final theme = Theme.of(context);
  return AppBar(
    backgroundColor: theme.bottomAppBarColor,
    elevation: 0,
    centerTitle: true,
    title: StreamBuilder(
      stream: userStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Text(
              "",
              style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
            );
            break;
          default:
            if (snapshot.data == false) {
              return Text(
                AppLocalizations.of(context).translate('welcome'),
                style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
              );
            }
            return Text(
              AppLocalizations.of(context).translate('follow-your-reboot'),
              style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
            );
            
        }
      },
    ),
    // title: Text(
    //   title,
    //   style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
    // ),
    iconTheme: IconThemeData(
      color: theme.primaryColor,
    ),
  );
}
