import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:reboot_app_3/Shared/Constants.dart';

class CommunityRegister extends StatefulWidget {
  @override
  _CommunityRegisterState createState() => _CommunityRegisterState();
}

class _CommunityRegisterState extends State<CommunityRegister> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        color: primaryColor,
        child: Text('helllllllllllllop'),
      ),
    );
  }
}
