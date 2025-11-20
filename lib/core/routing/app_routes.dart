import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:reboot_app_3/features/account/presentation/banned_screen.dart';
import 'package:reboot_app_3/features/account/presentation/delete_account_screen.dart';
import 'package:reboot_app_3/features/account/presentation/account_deletion_login_screen.dart';
import 'package:reboot_app_3/features/account/presentation/account_deletion_loading_screen.dart';
import 'package:reboot_app_3/features/account/presentation/user_profile_screen.dart';
import 'package:reboot_app_3/features/plus/presentation/taaafi_plus_features_list_screen.dart';
import 'package:reboot_app_3/features/plus/presentation/plus_features_guide_screen.dart';
import 'package:reboot_app_3/features/community/presentation/posts_list_screen.dart';
import 'package:reboot_app_3/features/community/presentation/categories_list_screen.dart';
import 'package:reboot_app_3/features/community/presentation/category_posts_screen.dart';
import 'package:reboot_app_3/features/community/data/models/post_category.dart';
import 'package:reboot_app_3/features/home/presentation/reports/user_reports_screen.dart';
import 'package:reboot_app_3/features/home/presentation/reports/report_conversation_screen.dart';
import 'package:reboot_app_3/features/notifications/presentation/notifications_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/complete_account_registeration.dart';
import 'package:reboot_app_3/features/authentication/presentation/confirm_user_details_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/confirm_user_email_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/forgot_password_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/login_screen.dart';
import 'package:reboot_app_3/features/authentication/presentation/signup_screen.dart';
import 'package:reboot_app_3/features/authentication/providers/user_document_provider.dart';
import 'package:reboot_app_3/features/authentication/data/repositories/auth_repository.dart';
import 'package:reboot_app_3/features/referral/presentation/screens/referral_code_input_screen.dart';

import 'package:reboot_app_3/features/community/presentation/community_onboarding_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/groups_onboarding_screen.dart';
import 'package:reboot_app_3/features/community/presentation/community_main_screen.dart';

import 'package:reboot_app_3/features/groups/presentation/screens/group_list_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/groups_exploration_screen.dart';

import 'package:reboot_app_3/features/community/presentation/forum/post_detail_screen.dart';
import 'package:reboot_app_3/features/community/presentation/forum/new_post_screen.dart';
import 'package:reboot_app_3/features/community/presentation/forum/reply_composer_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_chat_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_challenge_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/updates/all_updates_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/group_settings_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/challenges/create_challenge_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/challenges/edit_challenge_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/challenges/challenge_detail_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/challenges/challenge_history_screen.dart';
import 'package:reboot_app_3/features/groups/presentation/screens/challenges/challenge_leaderboard_screen.dart';
import 'package:reboot_app_3/features/community/presentation/challenges/global_challenge_list_screen.dart';
import 'package:reboot_app_3/features/community/presentation/profile/community_profile_settings_screen.dart';
import 'package:reboot_app_3/features/direct_messaging/presentation/screens/community_chats_screen.dart';
import 'package:reboot_app_3/features/direct_messaging/presentation/screens/direct_chat_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/day_overview/day_overview_screen.dart';
import 'package:reboot_app_3/features/home/presentation/home/home_screen.dart';
import 'package:reboot_app_3/features/onboarding/presentation/onboarding_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/activity_overview_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/add_activity_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/all_tasks_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/activities/ongoing_activitiy_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/diaries/diary_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_lists_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/content_type_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/library/list_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/activities_notifications_settings_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_settings/smart_alerts_settings_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/vault_screen.dart';
import 'package:reboot_app_3/features/vault/presentation/premium_analytics_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:reboot_app_3/features/authentication/data/models/user_document.dart';
import 'package:reboot_app_3/core/routing/route_security_service.dart';
import 'package:reboot_app_3/features/account/application/startup_security_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

part 'app_routes.g.dart';

@riverpod
GoRouter goRouter(Ref<GoRouter> ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userDocumentState = ref.watch(userDocumentsNotifierProvider);
  final userDocumentNotifier = ref.read(userDocumentsNotifierProvider.notifier);
  final routeSecurityService = ref.read(routeSecurityServiceProvider);

  // Build a merged stream to trigger router refreshes whenever auth state OR
  // user-document state changes.
  final refreshController = StreamController<void>(sync: true);

  // Listen to auth state stream
  final authSubscription = authStateChanges(ref).listen((_) {
    if (!refreshController.isClosed) refreshController.add(null);
  });

  // Listen to user-document provider updates
  ref.listen<AsyncValue<UserDocument?>>(userDocumentsNotifierProvider,
      (prev, next) {
    if (!refreshController.isClosed) refreshController.add(null);
  });

  // Ensure we clean up subscriptions
  ref.onDispose(() {
    authSubscription.cancel();
    refreshController.close();
  });

  return GoRouter(
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: false,
    observers: [
      GoRouterObserver(ref.read(analyticsFacadeProvider)),
    ],
    refreshListenable: GoRouterRefreshStream(refreshController.stream),
    redirect: (context, state) async {
      // Use the RouteSecurityService to handle both authentication and security checks
      // This provides comprehensive protection against device bans, user bans, etc.
      try {
        final redirectPath = await routeSecurityService.getRedirectPath(state);
        return redirectPath;
      } catch (e) {
        print('ERROR: RouteSecurityService failed: $e');
        // Simple fallback - let RouteSecurityService handle all logic
        // If it fails, we'll just allow the navigation to proceed
        // This prevents infinite redirect loops while still providing basic protection
        return null;
      }
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
        path: '/banned',
        name: RouteNames.banned.name,
        pageBuilder: (context, state) {
          // Get the security result from the route security service
          final securityCheckResult =
              routeSecurityService.getLastSecurityResult();

          SecurityStartupResult result;

          if (securityCheckResult != null) {
            // Convert the SecurityCheckResult to SecurityStartupResult
            result = routeSecurityService
                .convertToStartupResult(securityCheckResult);
          } else {
            // Fallback if no security result is available
            result = SecurityStartupResult.userBanned(
              message:
                  'Your account has been restricted from accessing the application.',
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            );
          }

          return NoTransitionPage<void>(
            name: RouteNames.banned.name,
            child: AppBannedWidget(securityResult: result),
          );
        },
      ),
      // Account deletion login screen - accessible to unauthenticated users
      GoRoute(
        path: '/account-deletion-login',
        name: RouteNames.accountDeletionLogin.name,
        pageBuilder: (context, state) => MaterialPage(
          name: RouteNames.accountDeletionLogin.name,
          child: AccountDeletionLoginScreen(),
        ),
      ),
      // Account deletion loading screen - accessible to unauthenticated users
      GoRoute(
        path: '/account-deletion-loading',
        name: RouteNames.accountDeletionLoading.name,
        pageBuilder: (context, state) => MaterialPage(
          name: RouteNames.accountDeletionLoading.name,
          child: AccountDeletionLoadingScreen(),
        ),
      ),
      // Onboarding routes: Non authenticated users
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
            pageBuilder: (context, state) => MaterialPage(
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
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => NoTransitionPage(
          name: 'main',
          child: ScaffoldWithNestedNavigation(navigationShell: navigationShell),
        ),
        branches: [
          // * Home
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
                    path: 'completeAccountRegisteration',
                    name: RouteNames.completeAccountRegisteration.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.completeAccountRegisteration.name,
                      child: CompleteAccountRegisterationScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'confirmProfileDetails',
                    name: RouteNames.confirmUserDetails.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.confirmUserDetails.name,
                      child: ConfirmUserDetailsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'confirmUserEmail',
                    name: RouteNames.confirmUserEmail.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.confirmUserEmail.name,
                      child: ConfirmUserEmailScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'referralCodeInput',
                    name: RouteNames.referralCodeInput.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.referralCodeInput.name,
                      child: ReferralCodeInputScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.notifications.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.notifications.name,
                      child: NotificationsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // * Vault
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
                    path: "dayOverview/:date",
                    name: RouteNames.dayOverview.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.dayOverview.name,
                      child: DayOverviewScreen(
                        date: DateTime.parse(state.pathParameters["date"]!),
                      ),
                    ),
                  ),
                  // Activities routes (moved from activities screen)
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
                      child:
                          OngoingActivitiyScreen(state.pathParameters["id"]!),
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
                  ),
                  // Diaries routes (moved from diaries screen)
                  GoRoute(
                    path: "diary/:id",
                    name: RouteNames.diary.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.diary.name,
                      child: DiaryScreen(
                        diaryId: state.pathParameters["id"]!,
                      ),
                    ),
                  ),
                  // Library routes (moved from library screen)
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
                    path: "contentType/:typeId",
                    name: RouteNames.contentType.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.contentType.name,
                      child: ContentTypeScreen(
                        state.pathParameters["typeId"]!,
                      ),
                    ),
                  ),
                  // Settings routes (moved from vault settings screen)
                  GoRoute(
                    path: "activitiesNotifications",
                    name: RouteNames.activitiesNotifications.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.activitiesNotifications.name,
                      child: ActivitiesNotificationsSettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: "smartAlertsSettings",
                    name: RouteNames.smartAlertsSettings.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.smartAlertsSettings.name,
                      child: SmartAlertsSettingsScreen(),
                    ),
                  ),
                  // Other vault routes
                  GoRoute(
                    path: "premiumAnalytics",
                    name: RouteNames.premiumAnalytics.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.premiumAnalytics.name,
                      child: PremiumAnalyticsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // * Community
          StatefulShellBranch(
            navigatorKey: shellNavigatorFellowshipKey,
            routes: [
              GoRoute(
                name: RouteNames.community.name,
                path: '/community',
                pageBuilder: (context, state) {
                  // Get initial tab from query parameters
                  final initialTab = state.uri.queryParameters['tab'];
                  return NoTransitionPage<void>(
                    key: state.pageKey,
                    name: state.name,
                    child: CommunityMainScreen(initialTab: initialTab),
                  );
                },
                routes: [
                  // NEW onboarding route
                  GoRoute(
                    path: 'onboarding',
                    name: RouteNames.communityOnboarding.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.communityOnboarding.name,
                      child: CommunityOnboardingScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'allPosts',
                    name: RouteNames.allPosts.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.allPosts.name,
                      child: PostsListScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'categories',
                    name: RouteNames.categoriesList.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.categoriesList.name,
                      child: CategoriesListScreen(),
                    ),
                  ),
                  GoRoute(
                    path:
                        'category/:categoryId/:categoryName/:categoryNameAr/:categoryIcon/:categoryColor',
                    name: RouteNames.categoryPosts.name,
                    pageBuilder: (context, state) {
                      // Parse the category from the path parameters
                      final categoryId = state.pathParameters['categoryId']!;
                      final categoryName = Uri.decodeComponent(
                          state.pathParameters['categoryName']!);
                      final categoryNameAr = Uri.decodeComponent(
                          state.pathParameters['categoryNameAr']!);
                      final categoryIcon =
                          state.pathParameters['categoryIcon']!;
                      final categoryColor =
                          state.pathParameters['categoryColor']!;

                      // Create PostCategory object
                      final category = PostCategory(
                        id: categoryId,
                        name: categoryName,
                        nameAr: categoryNameAr,
                        iconName: categoryIcon,
                        colorHex: categoryColor,
                        isActive: true,
                        sortOrder: 0, // Default sort order
                      );

                      return MaterialPage<void>(
                        name: RouteNames.categoryPosts.name,
                        child: CategoryPostsScreen(category: category),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'post/:postId',
                    name: RouteNames.postDetail.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.postDetail.name,
                      child: PostDetailScreen(
                          postId: state.pathParameters['postId']!),
                    ),
                  ),
                  GoRoute(
                    path: 'new',
                    name: RouteNames.newPost.name,
                    pageBuilder: (context, state) {
                      // Get initial category ID from query parameters
                      final initialCategoryId =
                          state.uri.queryParameters['categoryId'];
                      return MaterialPage<void>(
                        name: RouteNames.newPost.name,
                        child:
                            NewPostScreen(initialCategoryId: initialCategoryId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'post/:postId/comment/:commentId/reply',
                    name: RouteNames.replyComposer.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.replyComposer.name,
                      child: ReplyComposerScreen(
                        postId: state.pathParameters['postId']!,
                        parentId: state.pathParameters['commentId']!,
                      ),
                    ),
                  ),

                  GoRoute(
                    path: 'challenges',
                    name: RouteNames.globalChallengeList.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.globalChallengeList.name,
                      child: GlobalChallengeListScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'profile',
                    name: RouteNames.communityProfile.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.communityProfile.name,
                      child: CommunityProfileSettingsScreen(),
                    ),
                  ),
                  // Direct Messaging routes
                  GoRoute(
                    path: 'chats',
                    name: RouteNames.communityChats.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.communityChats.name,
                      child: CommunityChatsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'chats/:conversationId',
                    name: RouteNames.directChat.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.directChat.name,
                      child: DirectChatScreen(
                        conversationId: state.pathParameters['conversationId']!,
                      ),
                    ),
                  ),
                  // Groups routes - nested under community
                  // Redirect old /groups route to /community
                  GoRoute(
                    path: 'groups',
                    name: RouteNames.groups.name,
                    redirect: (context, state) => '/community',
                  ),
                  GoRoute(
                    path: 'groups/onboarding',
                    name: RouteNames.groupsOnboarding.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupsOnboarding.name,
                      child: GroupsOnboardingScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/list',
                    name: RouteNames.groupList.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupList.name,
                      child: GroupListScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/explore',
                    name: RouteNames.groupExploration.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupExploration.name,
                      child: const GroupsExplorationScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId',
                    name: RouteNames.groupDetail.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupDetail.name,
                      child: GroupDetailScreen(
                          groupId: state.pathParameters['groupId']!),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/chat',
                    name: RouteNames.groupChat.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupChat.name,
                      child: GroupChatScreen(
                          groupId: state.pathParameters['groupId']!),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/challenge',
                    name: RouteNames.groupChallenge.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupChallenge.name,
                      child: GroupChallengeScreen(
                          groupId: state.pathParameters['groupId']!),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/updates',
                    name: RouteNames.groupUpdates.name,
                    pageBuilder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return MaterialPage<void>(
                        name: RouteNames.groupUpdates.name,
                        child: AllUpdatesScreen(groupId: groupId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'groups/:groupId/settings',
                    name: RouteNames.groupSettings.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupSettings.name,
                      child: const GroupSettingsScreen(),
                    ),
                  ),
                  // Challenge routes
                  GoRoute(
                    path: 'groups/:groupId/challenges',
                    name: RouteNames.groupChallenges.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.groupChallenges.name,
                      child: GroupChallengeScreen(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/challenges/create',
                    name: RouteNames.createChallenge.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.createChallenge.name,
                      child: CreateChallengeScreen(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/challenges/:challengeId/edit',
                    name: RouteNames.editChallenge.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.editChallenge.name,
                      child: EditChallengeScreen(
                        groupId: state.pathParameters['groupId']!,
                        challengeId: state.pathParameters['challengeId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/challenges/:challengeId/history',
                    name: RouteNames.challengeHistory.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.challengeHistory.name,
                      child: ChallengeHistoryScreen(
                        groupId: state.pathParameters['groupId']!,
                        challengeId: state.pathParameters['challengeId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/challenges/:challengeId',
                    name: RouteNames.challengeDetail.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.challengeDetail.name,
                      child: ChallengeDetailScreen(
                        groupId: state.pathParameters['groupId']!,
                        challengeId: state.pathParameters['challengeId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'groups/:groupId/challenges/:challengeId/leaderboard',
                    name: RouteNames.challengeLeaderboard.name,
                    pageBuilder: (context, state) => MaterialPage<void>(
                      name: RouteNames.challengeLeaderboard.name,
                      child: ChallengeLeaderboardScreen(
                        groupId: state.pathParameters['groupId']!,
                        challengeId: state.pathParameters['challengeId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // * Account
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
                    path: 'profile',
                    name: RouteNames.userProfile.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.userProfile.name,
                      child: UserProfileScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'ta3afi-plus',
                    name: RouteNames.ta3afiPlus.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.ta3afiPlus.name,
                      child: TaaafiPlusSubscriptionScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'plus-features-guide',
                    name: RouteNames.plusFeaturesGuide.name,
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final fromPurchase = extra?['fromPurchase'] ?? false;

                      return MaterialPage(
                        name: RouteNames.plusFeaturesGuide.name,
                        child:
                            PlusFeaturesGuideScreen(fromPurchase: fromPurchase),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'account-delete',
                    name: RouteNames.accountDelete.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.accountDelete.name,
                      child: DeleteAccountScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'reports',
                    name: RouteNames.userReports.name,
                    pageBuilder: (context, state) => MaterialPage(
                      name: RouteNames.userReports.name,
                      child: UserReportsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'conversation/:reportId',
                        name: RouteNames.reportConversation.name,
                        pageBuilder: (context, state) => MaterialPage(
                          name: RouteNames.reportConversation.name,
                          child: ReportConversationScreen(
                            reportId: state.pathParameters['reportId']!,
                          ),
                        ),
                      ),
                    ],
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
