import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/account_bloc.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/blocs/user_bloc.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/screens/auth/new_user_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/providers/main_providers.dart';

class FollowYourRebootScreenAuthenticationWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authStateChangesProvider);

    return userAsyncValue.when(
      data: (User user) {
        if (user == null) return LoginScreen();
        return CustomBlocProvider(
          bloc: UserBloc(),
          child: UserDocWrapper(),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
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
