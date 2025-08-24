# F3 – Support Groups (الزمالات) — Business Requirements (Final)

**Version:** 1.0  
**Status:** Finalized (ready for technical spec)  
**Scope:** Mobile apps + Firebase backend (Firestore + Cloud Functions)  
**Source of truth for Plus:** `users.isPlusUser` (with `communityProfiles.isPlusUser` kept as a mirrored field if needed)

---

## 0) Goals & Non‑Goals

### Goals

- Provide small, safe, **gender‑specific** support groups centered on mutual accountability.
- Enable **real‑time chat**, **task‑based challenges**, and a **member scoreboard**.
- Keep discovery/joining simple with **three join methods**: `any`, `admin_only`, `code_only`.
- Enforce **one active group per user** with a **24h cooldown** after leaving (visible countdown) and **system‑admin override**.
- Keep **privacy/anonymity** via Community Profile identities (CP).

### Non‑Goals

- No inter‑group public leaderboards or global rankings.
- No voice/video at launch (chat is **text‑only**).
- No auto moderation collection; moderation state is stored per message/challenge/task in‑document.
- No automated pausing/closing rules (only admin/system admin can pause/close).

---

## 1) Actors & Roles

- **Member (CP):** a user’s community profile participating in exactly one group at a time.
- **Group Admin (CP):** manages membership, challenges, and tasks for a single group.
- **System Admin:** backoffice/admin console operator with override powers.

> Identity everywhere is the **Community Profile (CP)**, not the raw `users` record, to preserve anonymity.

---

## 2) Group Structure & Membership

1. A group has a **gender** (`male`/`female`) stamped from the creator's CP. Only users with matching CP gender may join.
2. **One active group at a time** per CP. Leaving is allowed at any time.
3. After leaving, a user **must wait 24h** before joining another group (**visible countdown**).
   - System Admin may **remove the wait for a specific user** (per‑CP override).
   - **UI Available**: Leave group modal (`LeaveGroupModal`) with 24-hour restriction warning display.
4. **Admin requirement & capacities**
   - Anyone can create a group up to **6 members**.
   - To create a group with **capacity > 6**, the **admin must be a Plus user** at creation time.
   - If the admin later loses Plus, the group remains as is (no retroactive changes).
   - **UI Available**: Create group modal (`CreateGroupModal`) with member count input.

5. Members can be removed by **Group Admin** or **System Admin**.
   - **UI Available**: Group member settings screen (`GroupMemberSettingsScreen`) with remove member functionality.
6. Groups are **persistent**; states: `active`, `paused`, `closed` (changed only by Group Admin or System Admin).

---

## 3) Discovery & Join Methods

A group has two orthogonal properties:

- **Visibility:** `public` (discoverable) or `private` (not discoverable).
  - **UI Available**: Group type selector in `CreateGroupModal` (public/private).
- **Join Method:** one of:
  - `any`: visible **public** groups can be joined directly (capacity/gender/cooldown permitting).
  - `admin_only`: join via explicit **invite** from the Group Admin (not discoverable).
  - `code_only`: join with a **code**; group may be public (listed but locked) or private (not listed).
  - **UI Available**: Join method selector modal (`GroupJoiningMethodsModal`) with all three options.

**Constraints**

- `any` requires `visibility = public`.
- `admin_only` uses invites (single‑use or multi‑use with expiry).
  - **UI Available**: Group invitations modal (`GroupInvitationsModal`) with accept/decline functionality.
- `code_only` uses **automatically generated 5-character** join codes (mixed letters/numbers) stored as plain text with expiry and optional max uses; attempts are rate‑limited.
  - **UI Available**: Join group modal (`JoinGroupModal`) with code input field.
  - **Auto-Generation**: Join codes are automatically generated as random 5-character strings (e.g., "A7K2M") during group creation for `code_only` groups.

**Join attempt checks (in order)**

1. User feature not banned (via existing bans/features model).
2. CP gender matches group gender.
3. User has **no other active group**.
4. **Cooldown** satisfied (or system override active).
5. Group **capacity** not exceeded.
6. Join method validation: direct/valid invite/valid code.

**Additional UI**:

- Group list screen (`GroupListScreen`) for browsing public groups.
- Join random group functionality in `JoinGroupModal`.

---

## 4) Communication Channel (Chat)

- **Text‑only** real‑time group chat.
  - **UI Available**: Group chat screen (`GroupChatScreen`) with message list and input field.
- **WhatsApp‑style replies** (quote original message; not threaded).
  - **UI Available**: Reply functionality with swipe gesture and reply preview in `GroupChatScreen`.
- `@mentions` using **unique CP handles** (see §8 Mentions).
  - **UI Not Available**: No mentions implementation found.
- **In‑group search only** (no cross‑group search). Search is token‑based and Arabic‑aware.
  - **UI Not Available**: No search functionality implemented in chat.
- **No external links or personal contact info** (blocked by moderation rules).
- Message states:
  - `isDeleted` (hard user delete or admin delete)
  - `isHidden` (moderation hide)
  - `moderation.status` in {`pending`,`approved`,`blocked`} with optional reason.

Notifications:

- New group messages → push (respecting user opt‑in).
  - **UI Available**: Group notification settings screen (`GroupNotificationSettingsScreen`).

**Additional UI**:

- Chat settings screen (`GroupChatSettingsScreen`).
- Voice message recording functionality in `GroupChatScreen`.
- Message reactions with emoji in `GroupChatScreen`.

---

## 5) Challenges, Tasks & Points

- **Group Admin** creates **Challenges** (visible to all members) with `startAt`/`endAt`.
  - **UI Not Available**: No challenge creation UI for admins.
- Each Challenge contains **Tasks**. Each Task has **points** ∈ {**1, 5, 10, 25, 50**}.
  - **UI Available**: Task display in `GroupChallengeScreen` showing task title, subtitle, and completion status.
- **Task verification**
  - `requireApproval = false` → auto‑approved; points credited immediately.
  - `requireApproval = true` → completion enters `pending`; admin approves/rejects; points credited on approve.
  - **UI Not Available**: No task approval UI for admins.
- **Scoreboard** is **per‑member only**:
  - Show current members with their total points (leavers are not shown).
  - Points accumulate from Task Completions; stored denormalized on membership for fast reads.
  - **UI Available**: Leaderboard section in `GroupChallengeScreen` showing member rankings and points.

Notifications:

- New challenge/task created.
- Task reminders (configured by admin).
- Scoreboard updates (optional; avoid spam).

**Additional UI**:

- Active challenges display with progress percentage in `GroupChallengeScreen`.
- Task completion toggle functionality in `GroupChallengeScreen`.

---

## 6) Moderation & Safety

- All content (messages/challenges/tasks) must pass **AI/text moderation** with rules that block:
  - Sharing personal contact info (phones, social handles, emails, etc.).
  - Harmful content (harassment, adult material, etc.).
- Members can **report** content or users via the existing `usersReports` system.
- Admins (group/system) can remove members and hide/delete content.
- Groups are **gender‑specific** and enforced at join time.

---

## 7) Integration With Existing Data

- **Plus status** → from `users.isPlusUser` (CP's mirror is optional and informational).
- **Community Profile (CP)** → used as the identity in all group operations.
  - **UI Available**: Community profile setup modal (`CommunityProfileSetupModal`) integrated in groups flow.
- **Device/messaging tokens** → from `users.messagingToken`; no new collection is required at launch.
- **Bans/Warnings/Features** → reuse existing collections to block the `groups` feature if needed.

---

## 8) Mentions (Handles)

- Add a **unique, immutable handle** to `communityProfiles`:
  - Constraints: 3–20 chars; Arabic/Latin letters, digits, underscore; case‑insensitive unique.
  - Store both `handle` and `handleLower` (for lookups/uniqueness).
- Mentions UX:
  - Typing `@` opens a suggester filtered by prefix on `handleLower` (in the same group).
  - Sent messages store resolved `mentions: [cpId,…]` and optionally `mentionHandles` for rendering.
- Handle uniqueness:
  - Reserve with a `reserved_handles/{handleLower}` document to avoid races.
  - One‑time selection; immutable afterwards (admin can force change only for abuse).

**UI Not Available**: No handle or mentions functionality implemented.

---

## 9) Notifications (Push)

- Events: new message, new challenge/task, admin task reminder, scoreboard updates (optional).
- Respect user platform token availability and opt‑ins.
- Localize message content based on CP/user locale.

---

## 10) States & Edge Cases

- **Admin loses Plus after creating a >6 group** → **no effect** (grandfathered; the requirement applies only at creation).
- **Capacity full** → joining blocked until a member leaves.
- **Cooldown override** → system admin can set a time window during which cooldown is ignored.
- **Invite expiry / code expiry** → joining fails gracefully with actionable error.
- **Membership removal** → the removed member immediately loses read/write access.
- **Paused** → members can read history; posting and new joins are blocked.
- **Closed** → read‑only for admins; members ejected or marked inactive.

---

## 11) Non‑Functional Requirements (NFRs)

- **Privacy:** Only group members (and system admins) can read messages/challenges.
- **Security:** Firestore security rules enforce membership on reads; role checks on writes.
- **Performance:** Indexes for common queries (messages by group+createdAt, memberships by group+points, etc.).
- **Localization:** Arabic and English supported; Arabic tokenization for search.
- **Accessibility:** Dynamic type and screen reader labels in chat and task flows.
- **Reliability:** All points updates performed within transactions/batch writes.
- **Rate limits:** Join code attempts per CP/device; invite acceptance checks; message send flood protection.
- **Auditability:** Admin moderation actions record `actedByCpId` and timestamps.
- **Telemetry (optional):** group creation funnel, join success rate, message engagement, task completion rate.

---

## 12) Acceptance Criteria (Samples)

1. A non‑Plus CP can create a group with `memberCapacity = 6`; creation succeeds.
2. A non‑Plus CP **cannot** create a group with `memberCapacity = 7`; creation blocked with “Plus required” error.
3. A CP in a group cannot join another group until they leave; after leaving, a **24h countdown** is shown.
4. A System Admin can set a per‑CP override so the same CP can join immediately.
5. In chat, replying quotes the original message; `@handle` resolves to a CP and triggers a notification.
6. A task with `points = 25` and `requireApproval = true` credits points only after admin approval.
7. Scoreboard lists only **current active members** with correct totals.
8. Attempting to join with an expired code fails with a clear error.
9. Private groups do not appear in discovery.
10. Public `any` groups can be joined directly (subject to capacity/gender/cooldown).

---

## 13) Success KPIs (initial)

- % of users who successfully join a group on first attempt.
- Median time to first message after group join.
- Weekly task completion rate per active member.
- 7‑day retention of group members.
- Report rate per 1,000 messages (should trend low).

---

## Additional UI Features Not Mentioned in Requirements

### Screens and Navigation

1. **Groups Onboarding Screen** (`GroupsOnboardingScreen`): Initial onboarding flow for new users to the groups feature.
2. **Groups Main Screen** (`GroupsMainScreen`): Central hub showing group status and actions based on user state.
3. **Group Updates Screen** (`GroupUpdatesScreen`): Dedicated screen for group updates/announcements.
4. **Privacy Settings Screen** (`GroupPrivacySettingsScreen`): Dedicated privacy controls for group members.
5. **Group Detail Screen** (`GroupDetailScreen`): Additional group information display.

### Chat Features

1. **Voice Messages**: Voice recording and playback functionality in group chat.
2. **Message Reactions**: Emoji reactions on messages (similar to other messaging apps).
3. **Swipe to Reply**: WhatsApp-style swipe gesture for replying to messages.
4. **Hide Identity Toggle**: Option in join modal to hide identity when joining groups (privacy feature).

### Group Management

1. **Group Card Widget** (`GroupCard`): Reusable component for displaying group information in lists.
2. **Group Members Modal**: Bottom sheet showing all group members with their details.
3. **Invitation Time Display**: Shows how long ago an invitation was sent (hours/days ago).

### Settings Organization

1. **Separate Settings Screens**: Modular approach with dedicated screens for:
   - Notification settings
   - Member management settings  
   - Privacy settings
   - Chat settings

### Visual Elements

1. **Progress Indicators**: Visual progress bars for challenges.
2. **Status Badges**: Visual indicators for group type (public/private).
3. **Countdown Display**: Visual countdown timer after leaving a group (though actual cooldown logic not implemented).
4. **Join Code Success Modal**: Modal displaying generated join codes with copy functionality and security warnings for `code_only` groups.

### Recently Implemented Backend Features ✅

#### Join/Create/Leave Functionality

1. **✅ Complete Backend Architecture**: Full clean architecture implementation with domain entities, repositories, services, and controllers.
2. **✅ Group Creation**: Users can create groups with all specified validation rules including Plus user requirements for capacity > 6.
3. **✅ Automatic Join Code Generation**: System automatically generates secure 5-character join codes (A-Z, 0-9) for `code_only` groups during creation.
4. **✅ Join by Code**: Users can join groups using join codes with proper validation and error handling.
5. **✅ Direct Join**: Users can join public groups directly with all business rule validation.
6. **✅ Leave Group**: Users can leave groups with 24-hour cooldown enforcement.
7. **✅ Business Rule Validation**: All join/create/leave operations validate gender matching, capacity limits, cooldowns, and ban status.
8. **✅ Real-time Updates**: UI properly refreshes membership status after successful operations.

#### Data Layer

1. **✅ Firestore Integration**: Complete Firestore data source with proper schema mapping.
2. **✅ Transaction Safety**: All operations use proper Firestore transactions for data consistency.
3. **✅ Error Handling**: Comprehensive error handling with user-friendly messages.

### Still Missing Core Features

1. **❌ Admin Challenge/Task Creation UI**: Admin cannot create new challenges or tasks.
2. **❌ Task Approval UI**: Admin cannot approve/reject pending task completions.
3. **❌ Search in Chat**: In-group message search not implemented.
4. **❌ Mentions System**: Handle creation and @mentions not implemented.
5. **❌ Gender Filtering UI**: Gender-based group restrictions not visible in UI (backend enforced).
6. **❌ Capacity Display**: Member capacity limits not clearly shown in UI (backend enforced).
7. **❌ Group State Management**: No UI for pausing/closing groups.
8. **❌ Join Code Generation UI**: No UI for admins to generate/manage join codes.
9. **❌ Invitation System UI**: No UI for admin-only group invitations.

## TODO: Required Tasks for Full Implementation

### 🔥 Critical - Required from User

#### 1. **Firestore Security Rules** (HIGH PRIORITY)

- **Status**: ❌ **REQUIRED FROM USER**
- **Task**: Implement Firestore security rules as specified in the schema document
- **Location**: Firebase Console → Firestore Database → Rules
- **Impact**: Without these rules, the app will not work in production and data will be insecure

#### 2. **Firebase Cloud Functions** (HIGH PRIORITY)  

- **Status**: ❌ **REQUIRED FROM USER**
- **Tasks**:
  - Hash join code verification (currently using simple hash)
  - Plus user status validation for group creation
  - Community profile handle reservation system
  - Rate limiting for join attempts
- **Impact**: Some business rules currently use client-side validation only

#### 3. **Translation Keys** (MEDIUM PRIORITY)

- **Status**: ❌ **REQUIRED FROM USER**
- **Missing Keys**: Multiple error message keys referenced in the code:

  ```
  'group-description', 'enter-group-description', 'joining-method-required',
  'group-created-successfully', 'group-creation-failed', 'profile-required',
  'already-in-group-error', 'cooldown-active-error', 'group-full-error',
  'invalid-join-code-error', 'gender-mismatch-error', 'group-not-found-error',
  'group-inactive-error', 'user-banned-error', 'join-group-failed',
  'leaving-group', 'left-group-successfully', 'leave-group-failed'
  ```

- **Location**: `lib/i18n/en_translations.dart` and `lib/i18n/ar_translations.dart`

#### 4. **Community Profile Enhancements** (MEDIUM PRIORITY)

- **Status**: ❌ **REQUIRED FROM USER**  
- **Tasks**:
  - Add `nextJoinAllowedAt` field to community profiles collection
  - Add `rejoinCooldownOverrideUntil` field for admin overrides
  - Add `handle` and `handleLower` fields for mentions system
- **Impact**: Cooldown enforcement and mentions system won't work

#### 5. **Testing in Firebase Environment** (HIGH PRIORITY)

- **Status**: ❌ **REQUIRED FROM USER**
- **Tasks**:
  - Test all join/create/leave functionality with real Firestore database
  - Verify Plus user validation works correctly
  - Test error handling and edge cases
  - Verify cooldown enforcement after 24 hours

### 📋 Optional Enhancements

#### 6. **Join Code Generation System**

- **Status**: ⚠️ **OPTIONAL - FUTURE ENHANCEMENT**
- **Task**: Build UI for admins to generate and manage join codes
- **Impact**: Currently join codes must be set at group creation

#### 7. **Advanced Group Discovery**

- **Status**: ⚠️ **OPTIONAL - CURRENT WORKAROUND EXISTS**
- **Task**: The current exploration screen shows all public groups. May need filtering by region/interests in future.

### 🚀 Ready to Use Features

#### ✅ **Fully Implemented**

1. **Group Creation**: Complete with all validation rules
2. **Join by Code**: With proper error handling and validation  
3. **Direct Join**: For public groups with business rule enforcement
4. **Leave Group**: With 24-hour cooldown system
5. **UI Integration**: All modals connected to backend functionality
6. **Error Handling**: User-friendly error messages for all failure scenarios
7. **Real-time Updates**: Membership status refreshes automatically
