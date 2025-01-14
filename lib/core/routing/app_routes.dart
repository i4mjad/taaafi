import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reboot_app_3/core/monitoring/analytics_facade.dart';
import 'package:reboot_app_3/core/monitoring/logger_navigator_observer.dart';
import 'package:reboot_app_3/core/routing/go_router_refresh_stream.dart';
import 'package:reboot_app_3/core/routing/loading_screen.dart';
import 'package:reboot_app_3/core/routing/navigator_keys.dart';
import 'package:reboot_app_3/core/routing/not_found_screen.dart';
import 'package:reboot_app_3/core/routing/route_names.dart';
import 'package:reboot_app_3/core/routing/scaffold_with_nested_navigation.dart';
import 'package:reboot_app_3/features/account/presentation/account_screen.dart';
import 'package:reboot_app_3/features/account/presentation/delete_account_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/complete_account_registeration.dart';
import 'package:reboot_app_3/features/authentication/presentation/confirm_user_details_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/forgot_password_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/login_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/signup_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/home/presentation/day_overview/day_overview_screen.dart';
import 'package:reboot_app_3/features/home/presentation/home/home_screen.dart';
import 'package:reboot_app_3/features/onboarding/presentation/onboarding_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activities_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activity_overview_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/add_activity_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/all_tasks_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/ongoing_activitiy_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/diaries/diaries_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/diaries/diary_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_lists_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_type_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/library_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/list_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/activities_notifications_settings_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/vault_settings_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'app_routes.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userDocumentState = ref.watch(userDocumentsNotifierProvider);
  final userDocumentNotifier = ref.read(userDocumentsNotifierProvider.notifier);

  return GoRouter(
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: false,
    observers: [
      GoRouterObserver(ref.read(analyticsFacadeProvider)),
      SentryNavigatorObserver(),
    ],
    refreshListenable: GoRouterRefreshStream(authStateChanges(ref)),
    redirect: (context, state) async {
      final isLoggedIn = authState.asData?.value != null;

      if (isLoggedIn) {
        // Fetch the user document state
        final isLoading = userDocumentState is AsyncLoading;
        final hasError = userDocumentState is AsyncError;
        final userDocument = userDocumentState.valueOrNull;

        // Always navigate to the loading screen if the document state is loading
        if (isLoading) {
          if (state.matchedLocation != '/loading') {
            return '/loading';
          }
          return null;
        }

        // If document is null or has errors, redirect to complete account registration
        if (userDocument == null || hasError) {
          if (state.matchedLocation != '/completeAccountRegisteration') {
            return '/completeAccountRegisteration';
          }
          return null;
        }

        // Check if the user document is legacy or new
        final isLegacy =
            userDocumentNotifier.isLegacyUserDocument(userDocument);
        final isNew = userDocumentNotifier.isNewUserDocument(userDocument);

        // Check for missing required data
        if (userDocumentNotifier.hasMissingData(userDocument)) {
          if (state.matchedLocation != '/completeAccountRegisteration') {
            return '/completeAccountRegisteration';
          }
          return null;
        }

        // Check for old document structure in the legacy document
        if (isLegacy && await userDocumentNotifier.hasOldStructure()) {
          if (state.matchedLocation != '/confirmProfileDetails') {
            return '/confirmProfileDetails';
          }
          return null;
        }

        // Allow navigation to other routes if the user has the new document structure
        if (isNew) {
          if (state.matchedLocation.startsWith('/onboarding') ||
              state.matchedLocation == '/loading') {
            return '/home';
          }
          return null; // No redirection if already on a valid route
        }
      } else {
        // Non-logged-in user trying to access protected routes
        final isAuthRoute = state.matchedLocation.startsWith('/onboarding');
        if (!isAuthRoute && state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        name: RouteNames.loading.name,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          name: RouteNames.loading.name,
          child: LoadingScreen(),
        ),
      ),
      GoRoute(
        name: RouteNames.onboarding.name,
        path: '/onboarding',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          name: RouteNames.onboarding.name,
          child: OnBoardingScreen(),
        ),
        routes: [
          GoRoute(
            path: 'login',
            name: RouteNames.login.name,
            pageBuilder: (context, state) => NoTransitionPage<void>(
              name: RouteNames.login.name,
              child: LogInScreen(),
            ),
            routes: [
              GoRoute(
                path: 'forgetPassword',
                name: RouteNames.forgotPassword.name,
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  name: RouteNames.forgotPassword.name,
                  child: ForgotPasswordScreen(),
                ),
              ),
              GoRoute(
                path: 'signup',
                name: RouteNames.signup.name,
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  name: RouteNames.signup.name,
                  child: SignUpScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/completeAccountRegisteration',
        name: RouteNames.completeAccountRegisteration.name,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          name: RouteNames.completeAccountRegisteration.name,
          child: CompleteAccountRegisterationScreen(),
        ),
      ),
      GoRoute(
        path: '/confirmProfileDetails',
        name: RouteNames.confirmUserDetails.name,
        pageBuilder: (context, state) => NoTransitionPage(
          name: RouteNames.confirmUserDetails.name,
          child: ConfirmUserDetailsScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          name: 'main',
          child: ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            observers: [
              GoRouterObserver(ref.read(analyticsFacadeProvider)),
            ],
            navigatorKey: shellNavigatorHomeKey,
            routes: [
              GoRoute(
                name: RouteNames.home.name,
                path: '/home',
                pageBuilder: (context, state) => MaterialPage(
                  name: RouteNames.home.name,
                  child: HomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: "dayOverview/:date",
                    name: RouteNames.dayOverview.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.dayOverview.name,
                      child: DayOverviewScreen(
                        date: DateTime.parse(state.pathParameters["date"]!),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorVaultKey,
            observers: [
              GoRouterObserver(ref.read(analyticsFacadeProvider)),
            ],
            routes: [
              GoRoute(
                name: RouteNames.vault.name,
                path: '/vault',
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  name: RouteNames.vault.name,
                  child: VaultScreen(),
                ),
                routes: [
                  GoRoute(
                    path: "activities",
                    name: RouteNames.activities.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.activities.name,
                      child: ActivitiesScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: "allTasks",
                        name: RouteNames.allTasks.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.allTasks.name,
                          child: AllTasksScreen(),
                        ),
                      ),
                      GoRoute(
                        path: "ongoingActivity/:id",
                        name: RouteNames.ongoingActivity.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.ongoingActivity.name,
                          child: OngoingActivitiyScreen(
                              state.pathParameters["id"]!),
                        ),
                      ),
                      GoRoute(
                        path: "addActivity",
                        name: RouteNames.addActivity.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.addActivity.name,
                          child: AddActivityScreen(),
                        ),
                        routes: [
                          GoRoute(
                            path: "activityOverview/:id",
                            name: RouteNames.activityOverview.name,
                            pageBuilder: (context, state) => MaterialPage(
                              name: RouteNames.activityOverview.name,
                              child: ActivityOverviewScreen(
                                  state.pathParameters["id"]!),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  GoRoute(
                    path: "diaries",
                    name: RouteNames.diaries.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.diaries.name,
                      child: DiariesScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: "diary/:id",
                        name: RouteNames.diary.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.diary.name,
                          child: DiaryScreen(
                            diaryId: state.pathParameters["id"]!,
                          ),
                        ),
                      )
                    ],
                  ),
                  GoRoute(
                    path: "library",
                    name: RouteNames.library.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.library.name,
                      child: LibraryScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: "list/:id",
                        name: RouteNames.libraryList.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.libraryList.name,
                          child: ListScreen(state.pathParameters["id"]!),
                        ),
                      ),
                      GoRoute(
                        path: "content",
                        name: RouteNames.contents.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.contents.name,
                          child: ContentScreen(),
                        ),
                      ),
                      GoRoute(
                        path: "lists",
                        name: RouteNames.contentLists.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.contentLists.name,
                          child: ContentListsScreen(),
                        ),
                      ),
                      GoRoute(
                        path: "contentType/:typeId/:typeName",
                        name: RouteNames.contentType.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.contentType.name,
                          child: ContentTypeScreen(
                            state.pathParameters["typeId"]!,
                            state.pathParameters["typeName"]!,
                          ),
                        ),
                      )
                    ],
                  ),
                  GoRoute(
                    path: "settings",
                    name: RouteNames.vaultSettings.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.vaultSettings.name,
                      child: VaultSettingsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: "activitiesNotifications",
                        name: RouteNames.activitiesNotifications.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.activitiesNotifications.name,
                          child: ActivitiesNotificationsSettingsScreen(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // StatefulShellBranch(
          //   navigatorKey: shellNavigatorFellowshipKey,
          //   routes: [
          //     GoRoute(
          //       name: RouteNames.ta3afiPlus.name,
          //       path: '/ta3afi-plus',
          //       pageBuilder: (context, state) => NoTransitionPage<void>(
          //         key: state.pageKey,
          //         name: state.name,
          //         child: TaaafiPlusScreen(),
          //       ),
          //       routes: [
          //         //! Add Pages
          //       ],
          //     ),
          //   ],
          // ),

          StatefulShellBranch(
            navigatorKey: shellNavigatorAccountKey,
            observers: [
              GoRouterObserver(ref.read(analyticsFacadeProvider)),
            ],
            routes: [
              GoRoute(
                path: '/account',
                name: RouteNames.account.name,
                pageBuilder: (context, state) => NoTransitionPage<void>(
                  name: RouteNames.account.name,
                  child: AccountScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'account-delete',
                    name: RouteNames.accountDelete.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.accountDelete.name,
                      child: DeleteAccountScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      name: state.name,
      child: NotFoundScreen(),
    ),
  );
}
