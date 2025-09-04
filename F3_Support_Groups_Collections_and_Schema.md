# F3 – Support Groups (الزمالات) — Collections & Schema

**Version:** 1.0  
**Firestore model:** top‑level collections (no subcollections unless noted).  
**ID convention:** random IDs unless otherwise stated.  
**Timestamps:** Firestore `Timestamp` in UTC+0 (store), client renders by locale.  
**Identity:** use **Community Profile (CP)** IDs across group documents.

---

## A) Existing Collections (with required fields & planned additions)

### 1) `users` (existing)
Represents the account user (not the CP). **Source of truth for Plus**.

**Fields (existing as provided)**
- `uid` (string) — user id (primary key mirrored from auth)
- `displayName` (string)
- `email` (string)
- `gender` (string: `"male"|"female"`)
- `isPlusUser` (boolean) — **source of truth**
- `locale` (string: `"arabic"|"english"`, etc.)
- `platform` (string: `"ios"|"android"`, etc.)
- `messagingToken` (string) — FCM token (latest)
- `devicesIds` (array<string>) — device identifiers
- `dayOfBirth` (timestamp)
- `lastDeviceUpdate` (timestamp)
- `lastPlusCheck` (timestamp)
- `lastTokenUpdate` (timestamp)
- `role` (string) — e.g., `"founder"`, `"user"`
- `userFirstDate` (timestamp)

**Indexes (recommended)**
- `isPlusUser` (for admin dashboards)
- `messagingToken` (for device hygiene jobs)

---

### 2) `communityProfiles` (existing + **new fields**)
Represents the public/anonymous identity in community/groups.

**Existing fields**
- `userUID` (string) — FK → `users.uid`
- `displayName` (string)
- `avatarUrl` (string|null)
- `gender` (string: `"male"|"female"`)
- `role` (string: `"user"|"moderator"|...)`
- `isAnonymous` (boolean)
- `isDeleted` (boolean)
- `isPlusUser` (boolean) — **mirror** from `users.isPlusUser` (optional, denormalized)
- `shareRelapseStreaks` (boolean)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

**New fields**
- `handle` (string, unique, immutable) — CP mention handle (see constraints below)
  - **UI Status**: ❌ No handle creation or display UI
- `handleLower` (string, unique) — lowercased for lookups
  - **UI Status**: ❌ Not implemented
- `nextJoinAllowedAt` (timestamp) — cooldown enforcement
  - **UI Status**: ⚠️ Warning shown in leave modal but no countdown timer
- `rejoinCooldownOverrideUntil` (timestamp|null) — override window for system admin
  - **UI Status**: ❌ No system admin override UI

**Handle constraints**
- Regex (conceptual): `^[\p{L}\p{Nd}_]{3,20}$` (Arabic/Latin letters, digits, underscore)
- Case‑insensitive uniqueness enforced via `reserved_handles` (see H).

**Indexes**
- composite: `(handleLower asc)`
- `(userUID asc)`

---

### 3) `usersReports` (existing)
Used for reporting content/users; will extend to group domain.

**Fields (existing sample + interpretation)**
- `uid` (string) — reporter user UID (FK → `users.uid`)
- `initialMessage` (string)
- `messagesCount` (number)
- `status` (string: `"open"|"closed"|"in_review"`)
- `time` (timestamp) — createdAt
- `lastUpdated` (timestamp)

- `relatedContent` (map):
  - `type` (string) — extend to include:
    - `"user"`, `"post"`, **`"group_message"`, `"group_member"`, `"group_challenge"`, `"group_task"`**
  - `contentId` (string) — ID of the target
  - (optional) `title` (string) — if applicable

- `reportTypeId` (string) — FK to a report types catalog (if present)

**Indexes**
- `(status asc, lastUpdated desc)`
- `(relatedContent.type asc, time desc)`

---

### 4) `warnings` (existing)
Policy warnings issued to users.

**Fields (existing)**
- `userId` (string) — FK → `users.uid`
- `type` (string) — e.g., `"inappropriate_behavior"`
- `severity` (string: `"low"|"medium"|"high"`)
- `description` (string)
- `reason` (string)
- `issuedBy` (string) — admin UID/CP or system UID
- `issuedAt` (timestamp)
- `isActive` (boolean)
- `reportId` (string|null)

- `relatedContent` (map):
  - `type` (string) — e.g., `"post"`, **also allow: `"group_message"`, `"group_member"`, `"group_challenge"`, `"group_task"`**
  - `id` (string)
  - `title` (string)

**Indexes**
- `(userId asc, isActive desc, issuedAt desc)`

---

### 5) `bans` (existing)
App‑wide or feature‑level bans.

**Fields (existing + recommendation)**
- `userId` (string) — FK → `users.uid`
- `type` (string: `"user_ban"`)
- `scope` (string: `"app_wide"` or `"feature_only"`)
- `restrictedFeatures` (**array<string>|null**) — include `"groups"` to block group feature
- `severity` (string: `"temporary"|"permanent"`)
- `reason` (string)
- `description` (string)
- `deviceIds` (array<string>)
- `isActive` (boolean)
- `issuedBy` (string)
- `issuedAt` (timestamp)
- `expiresAt` (timestamp|null)
- `relatedContent` (null|map)

**Indexes**
- `(userId asc, isActive desc, expiresAt asc)`

---

### 6) `features` (existing)
Catalog of features for bans/flags.

**Fields (existing)**
- `uniqueName` (string, e.g., `"post_creation"`)
- `nameEn` / `nameAr` (string)
- `descriptionEn` / `descriptionAr` (string)
- `category` (string, e.g., `"core"`)
- `iconName` (string)
- `isActive` (boolean)
- `isBannable` (boolean)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

> Add (optional) a record: `uniqueName = "groups"` to unify ban logic.

---

### 7) `comments` (existing)
Forum comments (no mentions currently).

**Fields (existing)**
- `authorCPId` (string) — FK → `communityProfiles`
- `body` (string)
- `parentFor` (string: `"post"|"comment"`)
- `parentId` (string)
- `postId` (string)
- `likeCount` (number)
- `dislikeCount` (number)
- `score` (number)
- `isDeleted` (boolean)
- `isHidden` (boolean)
- `createdAt` (timestamp)
- `updatedAt` (timestamp|null)

**Note:** No changes required for groups.

---

## B) New Collections for Groups

### 1) `groups`
**Purpose:** group container.

**Fields**
- `name` (string, 1–60)
  - **UI Status**: ✅ Input field in CreateGroupModal
- `description` (string, 0–500; optional)
  - **UI Status**: ✅ Input field in CreateGroupModal
- `gender` (string: `"male"|"female"`) — stamped from creator CP
  - **UI Status**: ⚠️ Stored but no gender filtering UI visible
- `memberCapacity` (number; **default 6**; may be set >6 only if creator is Plus at creation)
  - **UI Status**: ✅ Input in CreateGroupModal but no capacity display in group
- `adminCpId` (string) — FK → `communityProfiles`
  - **UI Status**: ⚠️ Used but no admin indicators in UI
- `createdByCpId` (string) — FK → `communityProfiles`
- `visibility` (string: `"public"|"private"`)
  - **UI Status**: ✅ Selector in CreateGroupModal
- `joinMethod` (string: `"any"|"admin_only"|"code_only"`)
  - **UI Status**: ✅ Full selector in GroupJoiningMethodsModal
- `joinCode` (string|null) — plain text automatically generated 5-character join code (for `code_only`)
  - **UI Status**: ✅ Automatic generation with success modal display
- `joinCodeExpiresAt` (timestamp|null)
  - **UI Status**: ❌ No expiry settings UI
- `joinCodeMaxUses` (number|null)
  - **UI Status**: ❌ No usage limit UI
- `joinCodeUseCount` (number, default 0)
- `isActive` (boolean, default true)
- `isPaused` (boolean, default false)
  - **UI Status**: ❌ No pause functionality UI
- `pauseReason` (string|null)
  - **UI Status**: ❌ Not implemented
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

**Constraints**
- If `joinMethod = "any"`, then `visibility` **must** be `"public"`.
- `memberCapacity > 6` → creation allowed **only** if `users.isPlusUser = true` for `createdByCpId.userUID` at the time of creation.

**Indexes**
- `(visibility asc, joinMethod asc, createdAt desc)` — discovery
- `(gender asc, isActive desc)`
- `(adminCpId asc)`

---

### 2) `group_memberships`
**Purpose:** membership + scoreboard.

**Doc ID:** `${groupId}_${cpId}` (or random with compound unique index)

**Fields**
- `groupId` (string) — FK → `groups`
- `cpId` (string) — FK → `communityProfiles`
- `role` (string: `"admin"|"member"`)
  - **UI Status**: ❌ No role differentiation in UI
- `isActive` (boolean, default true)
- `joinedAt` (timestamp)
- `leftAt` (timestamp|null)
  - **UI Status**: ✅ Leave functionality implemented

- **Scoreboard (denormalized)**
  - `pointsTotal` (number, default 0)
    - **UI Status**: ✅ Displayed in leaderboard

**Indexes**
- `(groupId asc, isActive desc, pointsTotal desc)`
- `(cpId asc, isActive desc)`

**Constraints**
- Exactly **one active membership** per `cpId` across all groups (enforced in code/transaction).

---

### 3) `group_messages`
**Purpose:** chat messages (text‑only).

**Fields**
- `groupId` (string) — FK → `groups`
- `senderCpId` (string) — FK → `communityProfiles`
- `body` (string, 1–5000)
  - **UI Status**: ✅ Full chat UI with input
- `replyToMessageId` (string|null)
  - **UI Status**: ✅ Swipe to reply implemented
- `quotedPreview` (string|null) — small excerpt
  - **UI Status**: ✅ Reply preview shown
- `mentions` (array<string> cpIds) — resolved from `@handle`
  - **UI Status**: ❌ No @mention system
- `mentionHandles` (array<string>) — for rendering (optional)
  - **UI Status**: ❌ Not implemented
- `tokens` (array<string>) — tokenized terms for search (Arabic‑aware)
  - **UI Status**: ❌ No search UI
- `isDeleted` (boolean, default false)
- `isHidden` (boolean, default false)
- `moderation` (map) — `{ status: "pending"|"approved"|"blocked", reason?: string }`
  - **UI Status**: ❌ No moderation UI
- `createdAt` (timestamp)

**Additional UI Features**:
- Voice messages (no schema support)
- Message reactions (no schema support)

**Indexes**
- `(groupId asc, createdAt desc)`
- `(groupId asc, tokens array-contains)` — Firestore permits array-contains; multi-word merged client‑side.

---

### 4) `group_challenges`
**Purpose:** challenge headers per group.

**Fields**
- `groupId` (string) — FK → `groups`
- `title` (string, 1–80)
  - **UI Status**: ✅ Displayed in challenges screen
- `description` (string, 0–500)
  - **UI Status**: ✅ Displayed with progress
- `startAt` (timestamp)
- `endAt` (timestamp)
- `createdByCpId` (string) — FK → `communityProfiles`
- `isActive` (boolean, default true)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

**UI Gap**: ❌ No admin UI to create challenges

**Indexes**
- `(groupId asc, isActive desc, startAt desc)`

---

### 5) `challenge_tasks`
**Purpose:** tasks within a challenge.

**Fields**
- `challengeId` (string) — FK → `group_challenges`
- `title` (string, 1–80)
  - **UI Status**: ✅ Displayed in task list
- `description` (string, 0–500)
  - **UI Status**: ✅ Shown as subtitle
- `points` (number; allowed: **1,5,10,25,50**)
  - **UI Status**: ✅ Points displayed correctly
- `requireApproval` (boolean, default false)
  - **UI Status**: ❌ No approval workflow UI
- `isActive` (boolean, default true)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)

**UI Gaps**: 
- ❌ No admin UI to create tasks
- ❌ No approval UI for pending completions

**Indexes**
- `(challengeId asc, isActive desc)`

---

### 6) `task_completions`
**Purpose:** member completes a task → points.

**Fields**
- `groupId` (string) — FK → `groups`
- `challengeId` (string) — FK → `group_challenges`
- `taskId` (string) — FK → `challenge_tasks`
- `cpId` (string) — FK → `communityProfiles`
- `completedAt` (timestamp)
- `status` (string: `"auto_approved"|"pending"|"approved"|"rejected"`)
  - **UI Status**: ⚠️ Completion toggle exists but no approval UI
- `approvedByCpId` (string|null)
  - **UI Status**: ❌ No approval workflow

**Transaction logic**
- On create:
  - If task `requireApproval = false` → set `status = "auto_approved"` and **increment** `group_memberships.pointsTotal`.
  - If `true` → `status = "pending"` (no increment).
- On approve:
  - Transition `pending → approved` and **increment** `group_memberships.pointsTotal` exactly once.
- On reject:
  - `pending → rejected` (no increment).

**Indexes**
- `(groupId asc, cpId asc, completedAt desc)`
- `(challengeId asc, cpId asc)`

---

### 7) `group_invites` (only for `admin_only`)
**Purpose:** invitation flow for private, admin‑only groups.

**Fields**
- `groupId` (string) — FK → `groups`
- `cpId` (string) — invitee
- `createdByCpId` (string) — inviter (admin)
- `status` (string: `"pending"|"accepted"|"revoked"|"expired"`)
  - **UI Status**: ✅ Accept/decline in GroupInvitationsModal
- `createdAt` (timestamp)
  - **UI Status**: ✅ Shows time ago (hours/days)
- `expiresAt` (timestamp|null)
- `resolvedAt` (timestamp|null)

**UI Gap**: ❌ No admin UI to send invitations

**Indexes**
- `(cpId asc, status asc, createdAt desc)`
- `(groupId asc, status asc, createdAt desc)`

---

## C) Reserved Handles (for mentions)

### 8) `reserved_handles`
**Purpose:** guarantee uniqueness and atomic reservation of `communityProfiles.handle`.

**Doc ID:** `handleLower`

**Fields**
- `handleLower` (string) — same as doc id
- `createdAt` (timestamp)
- `createdByUid` (string) — `users.uid`

**Flow**
- Cloud Function validates, creates `reserved_handles/handleLower`, then writes `communityProfiles.handle`+`handleLower`.

**Indexes**
- None required beyond document id lookups.

---

## D) Optional (Future/Scale)

### 9) `device_tokens` (optional)
Multi‑device token tracking for reliable push delivery and rotation.

**Fields**
- `token` (string) — doc id may equal token
- `userUid` (string)
- `platform` (string)
- `locale` (string)
- `isActive` (boolean)
- `lastSeenAt` (timestamp)

**Note:** Not required at launch because `users.messagingToken` exists.

---

## E) Security Rules (High Level Outline)

- **Read `groups`**: 
  - `public` groups readable for discovery; `private` groups readable only by members/admins/system admin.
- **Write `groups`**:
  - Create: any CP can create if `memberCapacity <= 6`; if `> 6`, then creator’s `users.isPlusUser = true` at request time.
  - Update state (`isPaused`,`isActive`): only Group Admin or System Admin.
  - Update `memberCapacity`: Group Admin; if setting to `> 6`, require creator/admin is Plus _at the moment of update_.

- **Membership reads/writes**:
  - A CP can read/write their own membership; admins can manage all memberships in their group.
  - Enforce **single active membership** per CP globally (transaction + server validation).

- **Messages**:
  - Read: only active members of the group (and system admins).
  - Create: sender must be active member.
  - Hide/Delete: Group Admin or System Admin.

- **Challenges/Tasks**:
  - Only Group Admin can create/update.
  - Members can create `task_completions` for themselves only.
  - Approvals by Group Admin.

- **Cooldown**:
  - Join path must check `communityProfiles.nextJoinAllowedAt` unless `rejoinCooldownOverrideUntil > now`.

- **Join codes**:
  - Verification in a callable/HTTP function (hash compare; enforce expiry/usage; rate limit per CP/device/IP).

---

## F) Composite Indexes (Summary)

- `group_messages`: `(groupId asc, createdAt desc)`
- `group_memberships`: `(groupId asc, isActive desc, pointsTotal desc)`
- `task_completions`: `(groupId asc, cpId asc, completedAt desc)`, `(challengeId asc, cpId asc)`
- `groups`: `(visibility asc, joinMethod asc, createdAt desc)`, `(gender asc, isActive desc)`
- `usersReports`: `(relatedContent.type asc, time desc)`

---

## G) Data Integrity (Transactions & Hooks)

- **Join transaction**: verify capacity, single active membership, cooldown, and method (invite/code) atomically.
- **Leave flow**: set membership `isActive=false`, stamp `leftAt`, and set CP’s `nextJoinAllowedAt = now + 24h` (unless override window already active).
- **Points update**: wrap completion + membership increment in a transaction; idempotency on approval.
- **Admin downgrade (non‑blocking)**: if admin loses Plus post‑creation, no action; rule applies only at creation or when raising capacity above 6.

---

## H) Sample Validation (Pseudoregex)

- `groups.name`: `^.{1,60}$`
- `groups.description`: `^.{0,500}$`
- `communityProfiles.handle`: `^[\p{L}\p{Nd}_]{3,20}$`
- `challenge_tasks.points`: `^(1|5|10|25|50)$`

---

## I) Minimal Cloud Functions (Overview)

1. **Create/Update Group (capacity guard)**: reject `memberCapacity > 6` if creator/admin is not Plus (check `users.isPlusUser` via `communityProfiles.userUID`).
2. **Join Code Generation**: automatically generate secure 5-character codes (A-Z, 0-9) for `code_only` groups during creation.
3. **Join With Code**: verify plain text code match, expiry, and usage increments; apply rate limit.
4. **Handle Reservation**: reserve `handleLower`, then write `communityProfiles.handle` and `handleLower`.
5. **Task Completion Approval**: idempotent approval updates points exactly once (transaction).
6. **Cooldown Enforcement**: on leave, set `nextJoinAllowedAt = now + 24h`; system admin UI can set `rejoinCooldownOverrideUntil`.

---

## J) Migration Notes

- Backfill `communityProfiles.handle` for existing CPs with suggested slugs (confirm once).
- Optionally add a `features` record `("groups")` for ban/allow UI consistency.
- No changes required to `comments`, `usersReports` storage format—only **new `relatedContent.type` values** are added.

---

## K) UI Implementation Gaps Summary

### Critical Missing UI Components
1. **Admin Tools**
   - No challenge/task creation interface
   - No task approval workflow for `requireApproval`
   - No invitation sending UI for admin_only groups
   - ✅ **Join code generation** - Automatic generation with success modal (COMPLETED)
   - No group pause/close functionality

2. **Core Features**
   - No handle creation/display system
   - No @mentions implementation
   - No search functionality despite token support
   - No moderation tools for messages

3. **Display Gaps**
   - No admin/member role indicators
   - No capacity limits display
   - No countdown timer for cooldown (only warning)
   - No gender-based filtering visible

### UI Features Without Schema Support
1. **Voice Messages** - Recording UI exists but no storage fields
2. **Message Reactions** - Emoji UI but no reaction storage
3. **Hide Identity Toggle** - UI option but no persistence field

### Recommendations
- Prioritize admin tools for content creation and management
- Implement handle system for mentions
- Add search UI to utilize tokenization
- Consider schema updates for voice messages and reactions

## L) Recently Implemented: Join Code Generation System ✅

### 🔐 **Automatic Join Code Generation**

**Implementation Status**: ✅ **FULLY COMPLETED**

#### **Features Implemented**

1. **Automatic Generation**: System generates secure 5-character join codes for `code_only` groups
2. **Format**: Random combinations of uppercase letters (A-Z) and numbers (0-9)
3. **Examples**: "A7K2M", "X9B4C", "L5P8Q"
4. **Storage**: Plain text codes stored for easy admin access and sharing
5. **User Experience**: Beautiful success modal with copy functionality and persistent access

#### **Technical Implementation**

```dart
// JoinCodeGenerator utility
class JoinCodeGenerator {
  static String generate() {
    // Generates 5-character codes: A-Z, 0-9
    return "A7K2M"; // Example output
  }
}

// Automatic generation in repository
if (joinMethod == 'code_only') {
  generatedJoinCode = JoinCodeGenerator.generate();
  // Store as plain text for easy access
}
```

#### **UI Components Added**

1. **GroupCreatedSuccessModal**: Displays generated join code with copy functionality
2. **Group Overview Card**: Shows join code persistently for admins with copy button
3. **Copy Functionality**: One-tap copying with success feedback
4. **Responsive Design**: Works on all device sizes with proper spacing

#### **User Flow**

1. User creates group with `joinMethod = 'code_only'`
2. System automatically generates 5-character join code
3. Success modal displays the code with copy button for easy sharing
4. User can copy the code and share it with others
5. Code is stored as plain text for easy future access

#### **Security Features**

- **Plain Text Storage**: Codes stored directly for easy admin access and sharing
- **Persistent Access**: Admins can always view and share their group's join code
- **Simplified User Experience**: No complex security warnings or temporary access
- **Proper Validation**: Format validation and duplicate prevention

