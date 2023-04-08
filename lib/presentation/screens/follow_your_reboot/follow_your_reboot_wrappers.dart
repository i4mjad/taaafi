import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/bloc_provider.dart';
import 'package:reboot_app_3/presentation/blocs/follow_your_reboot_bloc.dart';
import 'package:reboot_app_3/presentation/screens/auth/login_screen.dart';
import 'package:reboot_app_3/presentation/screens/auth/new_user_screen.dart';
import 'package:reboot_app_3/presentation/screens/follow_your_reboot/follow_your_reboot_screen.dart';
import 'package:reboot_app_3/providers/main_providers.dart';
import 'package:reboot_app_3/providers/user/user_providers.dart';

class FollowYourRebootScreenAuthenticationWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(authStateChangesProvider);

    return userAsyncValue.when(
      data: (User user) {
        if (user == null) return LoginScreen();
        return UserDocWrapper();
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
  }
}

class UserDocWrapper extends ConsumerWidget {
  const UserDocWrapper({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsyncValue = ref.watch(userDocStreamProvider);

    return userDocAsyncValue.when(
      data: (DocumentSnapshot userDoc) {
        if (userDoc == null || !userDoc.exists) {
          return NewUserSection();
        } else {
          return CustomBlocProvider(
            bloc: FollowYourRebootBloc(),
            child: FollowYourRebootScreen(),
          );
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('An error occurred: $error'),
    );
  }
}

