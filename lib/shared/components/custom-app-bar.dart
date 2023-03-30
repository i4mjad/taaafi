import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/notes/notes_screen.dart';
import 'package:reboot_app_3/providers/notes/notes_providers.dart';

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

AppBar noteAppBarWithCustomTitle(
    BuildContext context, String title, WidgetRef ref, String id) {
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
    actions: [
      GestureDetector(
        onTap: () async {
          await ref.read(noteViewModelProvider.notifier).deleteNote(id);
          Navigator.pop(context);
        },
        child: Container(
          padding: EdgeInsets.only(right: 16, left: 16),
          child: Center(
              child: Icon(
            Iconsax.trash,
            color: Colors.red,
          )),
        ),
      ),
    ],
  );
}

void confirmDeleteDialog(
    ThemeData theme, BuildContext context, String id, WidgetRef ref) {
  showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: theme.scaffoldBackgroundColor,
          child: Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20, top: 8, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: MediaQuery.of(context).size.width / 5,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  AppLocalizations.of(context).translate("confirm-note-delete"),
                  style: kSubTitlesStyle.copyWith(color: theme.primaryColor),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(noteViewModelProvider.notifier)
                              .deleteNote(id);
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesScreen(),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          width:
                              (MediaQuery.of(context).size.width * 0.5) - (32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.5),
                            color: Colors.red,
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context).translate("delete"),
                              style: kSubTitlesStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 50,
                          width:
                              (MediaQuery.of(context).size.width * 0.5) - (32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.50),
                            color: theme.cardColor,
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context).translate("cancel"),
                              style: kSubTitlesStyle.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      });
}
