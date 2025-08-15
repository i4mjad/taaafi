
# Flutter UI Scaffold – Community & Engagement (Revision C)

This guide details **every screen and major component** for the Community module, reflecting the July 2025 requirements (forumPosts, nested comments & votes, referralCode, sub‑collections, global challenge tasks/progress).

---

## 1 Route Map

| Path | Screen Widget | Purpose |
|------|---------------|---------|
| `/community/forum` | **ForumHomeScreen** | Category chips + list of latest/top posts |
| `/community/forum/post/:postId` | **PostDetailScreen** | Full post, nested comments & votes |
| `/community/forum/new` | **NewPostScreen** | Compose a new post |
| `/community/forum/post/:postId/comment/:commentId/reply` | **ReplyComposer** | Inline reply to post/comment |
| `/community/groups` | **GroupListScreen** | Discover & join support groups |
| `/community/groups/:groupId` | **GroupDetailScreen** | Tabs: Overview · Members · Challenges · Chat |
| `/community/groups/:groupId/chat` | **GroupChatScreen** | Real‑time text chat |
| `/community/groups/:groupId/challenge/:challengeId` | **GroupChallengeScreen** | Tasks list + scoreboard |
| `/community/challenges` | **GlobalChallengeListScreen** | Monthly global challenges |
| `/community/profile` | **CommunityProfileSettingsScreen** | Edit community persona & referral code |

---

## 2 Screen Blueprints

### 2.1 ForumHomeScreen
```
Scaffold
 ├─ AppBar  | Title 'Community Forum'
 ├─ CategoryChips (HorizontalList)  // from forumCategories
 ├─ SegmentedControl  // All · For Men · For Women
 ├─ TabBar (Latest | Top 7d)
 ├─ Expanded ListView.builder
 │    └─ PostCard  // see component
 └─ FloatingActionButton  // ➜ NewPostScreen
```
*Provider graph*: `categoriesProvider`, `postsProvider(filter)`.

### 2.2 PostDetailScreen
```
Scaffold
 ├─ PostHeader (title, author, timestamp, category)
 ├─ PostBody  // Markdown
 ├─ VoteBar (VoteButton, score)
 ├─ Divider
 ├─ Expanded CommentList
 │    └─ CommentTile (supports nesting depth 1)
 └─ ReplyComposer (bottom‑sheet)
```
*Key interactions*: Vote on post, vote on comment, reply (creates comment with `parentFor = comment`).

### 2.3 NewPostScreen
```
Form
 ├─ TextField title
 ├─ TextField body (multiline, 4–12 lines)
 ├─ Dropdown category
 ├─ SwitchListTile 'Post anonymously'
 └─ ElevatedButton 'Publish'
```
Validation: title ≥ 5 chars, body ≥ 10. On submit → `forumPosts.add()`.

### 2.4 ReplyComposer (modal bottom sheet)
* TextField (autofocus)  
* Row: Anonymous switch, Send icon  
* Hidden params: `parentFor`, `parentId`.

### 2.5 GroupListScreen
* `ListView` of **GroupCard** (name, members/ capacity, gender badge).  
* “+ Create Group” FAB (admin flow).

### 2.6 GroupDetailScreen
```
DefaultTabController
 ├─ TabBar (Overview · Members · Challenges · Chat)
 └─ TabBarView
      • OverviewTab → description + Join/Leave
      • MembersTab → MemberChip(grid)
      • ChallengesTab → GroupChallengeList
      • ChatTab (shortcut) → pushes GroupChatScreen
```

### 2.7 GroupChatScreen
```
Scaffold
 ├─ AppBar 'Group Chat'
 ├─ Expanded ListView (messages)
 │    └─ MessageBubble
 └─ ChatComposer  // Text field + send
```
Soft-limit 100 messages/day enforced via Cloud Function.

### 2.8 GroupChallengeScreen
* Header: challenge name, dates, description.  
* `ListView` of **TaskTile** (checkbox + frequency badge + points).  
* Progress bar + leaderboard (points).

### 2.9 GlobalChallengeListScreen
* `CarouselSlider` of active challenges.  
* Each card → opens **GlobalChallengeDetailScreen** (same layout as group).

### 2.10 CommunityProfileSettingsScreen
```
Form
 ├─ AvatarPicker
 ├─ TextField displayName
 ├─ Dropdown gender
 ├─ SwitchListTile 'Post anonymously by default'
 ├─ TextField referralCode (enabled once)
 ├─ Divider 'Active bans / warnings'
 └─ ListTile per restriction (if any)
```
Update flows: display fields → `communityProfiles`, referral code → `users`.

---

## 3 Shared Components

| Widget | Description |
|--------|-------------|
| **PostCard** | Card with title, excerpt, score, comment count, anonymity avatar. |
| **CommentTile** | ListTile with nesting indent; vote buttons; reply icon. |
| **VoteButton** | Stateful icon ±; grabs current user vote. |
| **AvatarWithAnonymity** | Shows real avatar or generic silhouette. |
| **MemberChip** | CircleAvatar + name (anonymised if member opted). |
| **TaskTile** | Checkbox, task name, frequency pill, point badge. |
| **ProgressBar** | Animated `LinearProgressIndicator` with daily % goal. |

All components live under `lib/community/widgets/`.

---

## 4 State Management

* **Riverpod** + **Firestore** streams.  
* Each screen has a scoped provider for its list/ detail queries to keep rebuild range tight.  
* `postVotesProvider(postId)` and `commentVotesProvider(postId, commentId)` stream sub‑collection snapshots.  
* Ban enforcement: `activeBansProvider` read once at sign‑in; UI hides disabled features.

---

*This scaffold gives devs a ready blueprint for every page and widget per latest requirements.* 
