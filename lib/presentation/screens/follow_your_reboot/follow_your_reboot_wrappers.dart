
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/blocs/user_bloc.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/screens/auth/new_user_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';

class FollowYourRebootScreenAuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User firebaseUser = context.watch<User>();

    if (firebaseUser != null) {
      return CustomBlocProvider(
        bloc: UserBloc(),
        child: UserDocWrapper(),
      );
    }
    return LoginScreen();
  }
}

class UserDocWrapper extends StatelessWidget {
  const UserDocWrapper({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = CustomBlocProvider.of<UserBloc>(context);
    return StreamBuilder(
        stream: bloc.UserDoc(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          switch (snapshot.connectionState) {
          // Uncompleted State
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());

            default:
            // Completed with error
              var data = snapshot.data.data();

              if (data == null) {
                return CustomBlocProvider(
                  bloc: AccountBloc(),
                  child: NewUserSection(),
                );
              }
              return CustomBlocProvider(
                bloc: FollowYourRebootBloc(),
                child: FollowYourRebootScreen(),
              );
          }
        });
  }
}
