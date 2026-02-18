<!-- c18f3528-0d2a-4907-aec9-5ed7e741cc51 05bdb2b7-cdff-4f7e-916f-1dca3f1780ca -->
# Private Messaging (DMs) for Community

## Scope & Decisions
- DMs allowed between any Community Profiles (CP)
- Entry: From post author avatar → profile sheet with CTA to message (start or open)
- Blocking: one‑way; blocked user cannot start/send; conversation remains visible to blocker

## Data Model (Firestore)
- direct_conversations
  - id (auto)
  - participantCpIds: string[2]
  - lastMessage: string
  - lastActivityAt: Timestamp
  - unreadBy: map<{cpId: number}>
  - mutedBy: array<string cpId>
  - archivedBy: array<string cpId>
  - createdAt: Timestamp
  - createdByCpId: string
  - isDeletedFor: array<string cpId> (soft hide per participant)
- direct_messages
  - id (auto)
  - conversationId: string
  - senderCpId: string
  - body: string (1–5000)
  - replyToMessageId: string|null
  - quotedPreview: string|null
  - mentions: array<string cpId>
  - tokens: array<string>
  - isDeleted: boolean (default false)
  - isHidden: boolean (default false)
  - moderation: { status: 'pending'|'approved'|'blocked', reason?: string }
  - createdAt: Timestamp
- user_blocks
  - id: `${blockerCpId}_${blockedCpId}` (deterministic)
  - blockerUid: string
  - blockerCpId: string
  - blockedUid: string
  - blockedCpId: string
  - createdAt: Timestamp
  - reason?: string

## Security Rules (Firestore)
- Add DM rules alongside groups (current rules are deny‑all; this unblocks usage):
  - direct_conversations
    - read: request.auth != null && currentCPId() in resource.data.participantCpIds
    - create: request.auth != null &&
      currentCPId() in request.resource.data.participantCpIds &&
      size(request.resource.data.participantCpIds)==2 &&
      !isBlocked(otherCpId()) && !isBanned('direct_messaging')
    - update: only participants; restrict to own flags (mutedBy/archivedBy/isDeletedFor)
  - direct_messages
    - read: participant only (by conversation lookup or denormalized participantCpIds)
    - create: request.auth != null && isParticipant(conversationId) && !isBlocked(recipientCpId) && !isBanned('direct_messaging') && request.resource.data.senderCpId==currentCPId()
    - update/delete: sender only (or admin)
  - user_blocks
    - read: own docs where blockerUid == request.auth.uid
    - create/delete: request.auth != null; doc id must match `${currentCPId()}_*`
- Helper funcs: currentCPId(), isParticipant(), otherCpId(), isBanned(feature), isBlocked(targetCpId)

## Backend (Cloud Functions)
- sendDirectMessageNotification (trigger on direct_messages create)
  - Skip if isDeleted/isHidden/moderation.blocked
  - Resolve conversation, find recipient (other participant)
  - Respect user notification prefs (appNotificationsEnabled), account/profile deletion
  - Data payload: { type: 'dm', conversationId, senderCpId, route: '/community/chats/:conversationId' }
- checkDirectMessageQuota (callable)
  - e.g., 200 msgs/day per user total; return { allowed, remaining }
- Optional: autoModerateDirectMessage (content filter) → set moderation.status

## Admin Feature Flag/Ban Integration
- Create `features` doc: uniqueName: direct_messaging, category: communication, isBannable: true
- UI guard DM actions with shared `FeatureAccessGuard`/`SmartFeatureGuard` using `direct_messaging`

## Flutter Client – Data Layer
- New module: `lib/features/direct_messaging/`
  - domain/entities
    - DirectConversationEntity, DirectMessageEntity
  - data/models
    - DirectConversationModel, DirectMessageModel (with Firestore (de)serialization)
  - data/datasources
    - DirectMessagesFirestoreDataSource
      - watchMessages(conversationId): Stream<List<DirectMessageModel>> (real‑time, ascending by createdAt)
      - loadMessages(conversationId, pagination)
      - sendMessage(DirectMessageModel)
      - deleteMessage/hideMessage/updateLastActivity
    - ConversationsFirestoreDataSource
      - watchUserConversations(cpId): Stream<List<DirectConversationModel>> (order by lastActivityAt desc)
      - findOrCreateConversation(myCpId, otherCpId): deterministic 2‑party conversation
  - data/repositories
    - DirectChatRepository, ConversationsRepository
  - presentation/providers (Riverpod)
    - directChatMessagesProvider(conversationId)
    - directChatPaginatedProvider
    - conversationsProvider(currentCpId)
    - createOrOpenConversationProvider(otherCpId)
    - canAccessDirectChatProvider(conversationId): checks ban + block + participant status
    - isBlockedProvider(otherCpId) and didIBlockProvider/blockedMeProvider

## Flutter Client – UI
- Tabs in Community main
  - Update `lib/features/community/presentation/community_main_screen.dart` to include a top TabBar/Segmented control: `Groups` | `Chats`
  - Reuse `app_bar.dart` and `custom_segmented_button.dart` from shared widgets
- Chats Tab (conversation list)
  - New screen: `CommunityChatsScreen`
    - List of conversations (avatar, displayName, lastMessage, timestamp, unread badge)
    - Pull‑to‑refresh; lazy pagination
    - Use `container.dart` for list tiles/cards; `spinner.dart` for loading
- Conversation Screen
  - `DirectChatScreen` reusing group chat input/list patterns
  - Message list (stream provider), input with `custom_textfield.dart` + send button
  - Quote/reply support mirroring groups; show moderation state
  - Use `snackbar.dart` for errors and block/ban feedback
- Profile Sheet Entry (from posts)
  - On avatar tap in forum post/comment → show `ActionModal` (`core/shared_widgets/action_modal.dart`)
    - Content: CP avatar/name/handle, shared actions
    - CTA buttons:
      - Message (FeatureAccessGuard: `direct_messaging`) → createOrOpenConversation(otherCpId) then navigate to chat
      - View Profile
    - If either direction of block detected → disable/replace CTA with localized message

## Localization (i18n)
- Add keys in `lib/i18n/en_translations.dart` and `lib/i18n/ar_translations.dart`:
  - community-chats: "Chats" | "المحادثات"
  - start-conversation: "Message" | "مراسلة"
  - open-conversation: "Open chat" | "فتح المحادثة"
  - conversation-muted: "Muted" | "مكتوم"
  - you-blocked-this-user: "You blocked this user" | "لقد قمت بحظر هذا المستخدم"
  - user-has-blocked-you: "This user has blocked you" | "قام هذا المستخدم بحظرك"
  - cannot-message-user-blocked: "You can’t send messages to this user" | "لا يمكنك مراسلة هذا المستخدم"
  - direct-messaging-restricted: "Direct messaging is restricted" | "المراسلة الخاصة مقيدة"
  - message-sent: "Message sent" | "تم إرسال الرسالة"
  - new-message: "New message" | "رسالة جديدة"

## Shared Widgets usage
- app_bar.dart → consistent community header
- custom_segmented_button.dart → Groups/Chats segmentation
- action_modal.dart → profile bottom sheet actions (Message CTA)
- container.dart → conversation list items containers
- custom_textfield.dart → chat composer
- snackbar.dart → ban/block/moderation feedback
- spinner.dart → loading states

## Routing
- Add routes:
  - /community/chats → `CommunityChatsScreen`
  - /community/chats/:conversationId → `DirectChatScreen`
- Deep link target in notifications: /community/chats/:conversationId

## Blocking – Client Enforcement
- Before creating/sending:
  - Check `user_blocks` both directions: if blockedMe → disable send; if I blocked → allow viewing, prevent outbound send unless unblock
- In chat UI:
  - Show informational banner if blocked; offer Unblock action for blocker

## Indexes
- direct_conversations: (participantCpIds array-contains, lastActivityAt desc)
- direct_messages: (conversationId asc, createdAt desc)

## Analytics (optional)
- community_dm_open, community_dm_send, community_dm_block, community_dm_unblock

## Rollout Checklist
1) Add `direct_messaging` feature document (features collection)
2) Deploy Firestore rules and composite indexes
3) Deploy Cloud Functions (DM notifications, optional quota)
4) Add i18n keys (EN/AR)
5) Release client with tabs + profile sheet CTA


### To-dos

- [ ] Create Firestore collections for DMs and user_blocks with indexes
- [ ] Implement Firestore rules for DMs and blocks; add helpers
- [ ] Add features entry: direct_messaging (communication, bannable)
- [ ] Implement DM notification function and optional quota callable
- [ ] Add DM entities/models/datasources/repositories (watch/send/delete)
- [ ] Add Riverpod providers for conversations, messages, access, blocks
- [ ] Add Groups/Chats tabs to Community main using shared widgets
- [ ] Build CommunityChatsScreen with conversation list and unread state
- [ ] Build DirectChatScreen with composer, reply, moderation
- [ ] Add ActionModal sheet with Message CTA from post avatars
- [ ] Implement block/unblock flows and client checks
- [ ] Add EN/AR translations for new DM strings
- [ ] Register routes and deep links for chats and conversation
- [ ] Instrument DM events (open, send, block, unblock)