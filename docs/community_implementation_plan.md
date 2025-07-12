# Community Module – Implementation Plan (Revision C)

**Status: Draft** · Last updated: $(date)

---

## 1. Project Skeleton

```text
lib/features/community/
 ├─ data/
 │    ├─ models/
 │    ├─ repositories/
 │    └─ datasources/
 ├─ domain/
 │    ├─ services/
 │    └─ usecases/
 ├─ presentation/
 │    ├─ forum/
 │    ├─ groups/
 │    ├─ challenges/
 │    ├─ profile/
 │    ├─ widgets/
 │    └─ providers/
 └─ routing/
```

---

## 2. Firestore Collections & Fields

| Collection | Document ID | Important Fields | Sub-collections |
|------------|-------------|------------------|-----------------|
| **forumPosts** | `postId` | `authorCPId`, `title`, `body`, `category`, `isAnonymous`, `score`, `createdAt`, `updatedAt` | `comments`, `votes` |
| **forumPosts/{postId}/comments** | `commentId` | `authorCPId`, `body`, `parentFor`, `parentId`, `isAnonymous`, `score`, `createdAt` | `votes` |
| **forumPosts/{postId}/comments/{commentId}/votes** | `cpId` | `voterCPId`, `value` (-1／0／1), `createdAt` | — |
| **groups** | `groupId` | `name`, `description`, `memberCount`, `capacity`, `gender`, `createdAt` | `members`, `chatMessages`, `challenges` |
| **globalChallenges** | `chalId` | `name`, `start`, `end`, … | `tasks` |
| **communityProfiles** | `cpId` | `displayName`, `gender`, `avatarUrl`, `postAnonymouslyByDefault`, `referralCode` | — |
| **users** | `uid` | `referralCode` (set once) | — |

Composite indexes required:
* `forumPosts` ⇒ orderBy `score` desc, `createdAt` desc
* `forumPosts/comments` ⇒ orderBy `parentId`, `createdAt`
* `forumPosts/comments` (collectionGroup) ⇒ orderBy `score` desc (Top filter)

---

## 3. Data Models (Freezed examples)

```dart
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String authorCPId,
    required String title,
    required String body,
    required String category,
    required bool isAnonymous,
    required int score,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Post;

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Post(
        id: doc.id,
        authorCPId: doc.data()!["authorCPId"],
        title: doc.data()!["title"],
        body: doc.data()!["body"],
        category: doc.data()!["category"],
        isAnonymous: doc.data()!["isAnonymous"],
        score: doc.data()!["score"] ?? 0,
        createdAt: (doc.data()!["createdAt"] as Timestamp).toDate(),
        updatedAt: (doc.data()!["updatedAt"] as Timestamp?)?.toDate(),
      );
}
```

Additional models: `Comment`, `Vote`, `Group`, `GroupMember`, `ChatMessage`, `Challenge`, `ChallengeTask`, `CommunityProfile` (all follow same pattern).

---

## 4. Repository APIs (Forum excerpt)

```dart
class ForumRepository {
  final _posts = FirebaseFirestore.instance.collection('forumPosts');

  Future<String> createPost(PostFormData d) { … }
  Stream<List<Post>> watchPosts({PostFilter? filter});
  Stream<Post> watchPost(String id);

  Future<void> addComment({
    required String postId,
    required String body,
    String? parentFor,
    String? parentId,
    bool isAnonymous = false,
  }) {
    return _posts.doc(postId).collection('comments').add({
      'authorCPId': _currentCPId,
      'body': body,
      'parentFor': parentFor ?? 'post',
      'parentId': parentId ?? postId,
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'score': 0,
    });
  }

  Future<void> voteOnPost(String postId, int value) { … }
  Future<void> voteOnComment({
    required String postId,
    required String commentId,
    required int value,
  }) { … }
}
```

Similar repositories: `GroupsRepository`, `ChallengesRepository`, `ProfileRepository`.

---

## 5. Domain Services (Forum excerpt)

```dart
class ForumService {
  ForumService(this._repo);

  Future<void> publishPost(PostFormData data) {
    if (data.title.length < 5 || data.body.length < 10) {
      throw ForumValidationException();
    }
    return _repo.createPost(data);
  }

  Future<void> reply({
    required String postId,
    required String body,
    required String parentFor,
    required String parentId,
    required bool isAnonymous,
  }) => _repo.addComment(
        postId: postId,
        body: body,
        parentFor: parentFor,
        parentId: parentId,
        isAnonymous: isAnonymous,
      );

  Future<void> vote({
    required String postId,
    String? commentId,
    required int value,
  }) => commentId == null
      ? _repo.voteOnPost(postId, value)
      : _repo.voteOnComment(postId: postId, commentId: commentId, value: value);
}
```

---

## 6. Riverpod Providers

```dart
final forumRepositoryProvider = Provider((ref) => ForumRepository());
final forumServiceProvider = Provider((ref) => ForumService(ref.watch(forumRepositoryProvider)));

final postsProvider = StreamProvider.autoDispose<List<Post>>((ref) {
  final filter = ref.watch(postsFilterProvider);
  return ref.watch(forumRepositoryProvider).watchPosts(filter: filter);
});

final postDetailProvider = StreamProvider.family.autoDispose<Post, String>((ref, id) {
  return ref.watch(forumRepositoryProvider).watchPost(id);
});
```

Analogous for groups, challenges, profiles.

```dart
// NEW – checks if the current user already has a community profile
autoDisposeFutureProvider<bool> hasCommunityProfileProvider = FutureProvider<bool>((ref) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final doc = await FirebaseFirestore.instance.collection('communityProfiles').doc(uid).get();
  return doc.exists;
});
```

---

## 7. Routing Integration (GoRouter)

```dart
GoRoute(
  name: RouteNames.community.name,
  path: '/community',
  // NEW: redirect to onboarding if user lacks a community profile
  redirect: (context, state) {
    final hasProfile = context.read(hasCommunityProfileProvider).maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );
    if (!hasProfile) return '/community/onboarding';
    return null;
  },
  pageBuilder: (_, __) => NoTransitionPage(child: ForumHomeScreen()),
  routes: [
    // NEW onboarding route
    GoRoute(path: 'onboarding', builder: (_, __) => CommunityOnboardingScreen()),
    GoRoute(path: 'forum', builder: (_, __) => ForumHomeScreen(), routes: [
      GoRoute(path: 'post/:postId', builder: (c, s) => PostDetailScreen(postId: s.pathParameters['postId']!)),
      GoRoute(path: 'new', builder: (_, __) => NewPostScreen()),
      GoRoute(path: 'post/:postId/comment/:commentId/reply', builder: (c, s) => ReplyComposer(postId: s.pathParameters['postId']!, parentId: s.pathParameters['commentId']!)),
    ]),
    GoRoute(path: 'groups', builder: (_, __) => GroupListScreen(), routes: [ … ]),
    GoRoute(path: 'challenges', builder: (_, __) => GlobalChallengeListScreen()),
    GoRoute(path: 'profile', builder: (_, __) => CommunityProfileSettingsScreen()),
  ],
),
```

---

## 8. UI Widgets & Screens

* **ForumHomeScreen** – posts list, category chips, segmented filter, FAB.
* **PostDetailScreen** – header, body, `VoteBar`, comment list, `ReplyComposer`.
* **Shared Widgets** – `PostCard`, `CommentTile`, `VoteButton`, `AvatarWithAnonymity`, `MemberChip`, `TaskTile`, `ProgressBar`.
* **GroupListScreen**, **GroupDetailScreen** (tabs), **GroupChatScreen**, **GroupChallengeScreen**.
* **GlobalChallengeListScreen**, **CommunityProfileSettingsScreen**.
* **CommunityOnboardingScreen** – one-time setup: AvatarPicker · displayName · gender · anonymous-by-default switch · (optional) referral code input.

Reuse `WidgetsContainer`, `TextStyles`, `AppTheme`, `FeatureAccessGuard`.

---

## 9. Groups Module (summary)
* Collections: `groups`, sub-collections `members`, `chatMessages`, `challenges`.
* Providers: `groupsProvider`, `groupDetailProvider`.
* Join/Leave via `GroupsService`.

---

## 10. GroupChat Module
* Path: `groups/:groupId/chatMessages`.
* Cloud Function `checkGroupChatQuota` limits 100 messages/day.
* `GroupChatService.sendMessage` → callable + Firestore add.

---

## 11. Challenges (Global & Group)
* Collections per spec `globalChallenges` and `groups/:id/challenges`.
* `ChallengesRepository` & providers for lists and progress.

---

## 12. Community Profile & Referral Code
* Collection `communityProfiles`.
* Referral code saved **once** under `users/{uid}`.
* Service throws `ReferralAlreadySetException` on second attempt.

---

## 13. Access Control & Bans
* Reuse `activeBansProvider`.
* Actions wrapped in `BanGuard` (postCreate, commentCreate, vote, chat, groupJoin).

---

## 14. Remote Config Flags
* `community_enabled`, `global_challenges_enabled`, `group_chat_enabled`.

---

## 15. Firestore Security Rules (snippet)

```rules
match /forumPosts/{postId} {
  allow read: if true;
  allow create: if request.auth != null && !isBanned('postCreate');
  allow update, delete: if resource.data.authorCPId == currentCPId;
  match /comments/{commentId} { … }
  match /votes/{voteId} { … }
}
match /groups/{groupId}/chatMessages/{msgId} {
  allow create: if isMember(groupId) && !overQuota() && !isBanned('chat');
}
```

---

## 16. Utilities from `core`
* Theming / TextStyles – `core/theming`.
* Localization – `core/localization`.
* Network – `dio_provider.dart`.
* Analytics – `analytics_facade.dart`.
* Helpers – `helpers/date_display_formatter.dart`, `FeatureAccessGuard`, `snackbar.dart`.

---

## 17. Analytics & Monitoring

| Event | Params |
|-------|--------|
| `community_post_create` | `category`, `anonymous` |
| `community_comment_add` | `depth` |
| `community_vote` | `target`, `value` |
| `community_chat_message` | `groupId` |

Errors captured via Sentry in services.

---

## 18. Testing Matrix

* **Unit** – validation, vote idempotency, repository emulator tests.
* **Widget** – golden tests for `PostCard`, `CommentTile`.
* **Integration** – create post, vote transaction, quotas via CF emulator.

---

## 19. Continuous Delivery & Feature Toggle

1. Ship behind Remote Config `community_enabled = false`.
2. QA on dev Firebase project.
3. Gradual rollout 5 % → 25 % → 100 %.

---

## 20. Timeline (Remaining Work)

| Task | Est. |
|------|------|
| Groups + Chat | 2 d |
| Challenges module | 1 d |
| Profile & referral | 0.5 d |
| Rules & CFs | 0.5 d |
| Localization & polish | 0.5 d |
| Tests & CI updates | 1 d |
| QA & rollout | 1 d |
| **Total** | **6 d** |

---

> **Note:** This plan assumes prior completion of the Forum (Posts & Comments) basics outlined earlier. 