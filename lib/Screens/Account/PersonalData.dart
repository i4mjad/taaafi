import 'package:flutter/material.dart';
import 'package:reboot_app_3/Localization.dart';

class PersonalData extends StatefulWidget {
  @override
  _PersonalDataState createState() => _PersonalDataState();
}

class _PersonalDataState extends State<PersonalData> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(AppLocalizations.of(context).translate("account")),
    );
  }
}
