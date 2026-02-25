// private navigators

import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeShell');
final shellNavigatorVaultKey =
    GlobalKey<NavigatorState>(debugLabel: 'vaultShell');
final shellNavigatorFellowshipKey =
    GlobalKey<NavigatorState>(debugLabel: 'fellowshipShell');
final shellNavigatorGroupsKey =
    GlobalKey<NavigatorState>(debugLabel: 'groupsShell');
final shellNavigatorAccountKey =
    GlobalKey<NavigatorState>(debugLabel: 'accountShell');
