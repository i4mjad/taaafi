# Sprint 3: Chat Enhancements (2 weeks)

**Sprint Goal:** Add message management tools and improve chat experience

**Duration:** 2 weeks  
**Priority:** MEDIUM  
**Dependencies:** Sprint 1 & 2 completed

---

## Feature 3.1: Pin Messages

**User Story:** As a group admin, I want to pin important messages so that members can easily find key information.

### Technical Tasks

#### Backend Tasks

**Task 3.1.1: Update Message Model**
- **File:** `lib/features/groups/data/models/group_message_model.dart`
- **Actions:**
  1. Add `isPinned` field (boolean, default false)
  2. Add `pinnedAt` field (DateTime?, nullable)
  3. Add `pinnedBy` field (String?, cpId of admin who pinned)
  4. Update `fromFirestore` and `toFirestore`
- **Estimated Time:** 1 hour

**Task 3.1.2: Update Message Entity**
- **File:** `lib/features/groups/domain/entities/group_message_entity.dart`
- **Actions:**
  1. Add `isPinned` property
  2. Add `pinnedAt` property
  3. Add `pinnedBy` property
  4. Update `copyWith`
- **Estimated Time:** 30 minutes

**Task 3.1.3: Add Pin Methods to Repository**
- **File:** `lib/features/groups/data/repositories/group_chat_repository.dart`
- **Methods to Add:**
```dart
/// Pin a message (admin only, max 3 pinned)
Future<void> pinMessage({
  required String groupId,
  required String messageId,
  required String adminCpId,
});

/// Unpin a message
Future<void> unpinMessage({
  required String groupId,
  required String messageId,
  required String adminCpId,
});

/// Get pinned messages for group
Future<List<GroupMessageEntity>> getPinnedMessages(String groupId);
```
- **Estimated Time:** 2 hours

**Task 3.1.4: Implement Pin Logic**
- **File:** `lib/features/groups/data/repositories/group_chat_repository.dart` (implementation)
- **Actions:**
  1. Verify admin permissions
  2. Check max 3 pinned messages limit
  3. Update message document
  4. Set pinned timestamp and admin ID
- **Validations:**
  - Only admins can pin
  - Max 3 pinned messages per group
  - Cannot pin deleted/hidden messages
- **Estimated Time:** 3 hours

#### Frontend Tasks

**Task 3.1.5: Create Pinned Messages Provider**
- **File:** `lib/features/groups/providers/pinned_messages_provider.dart` (new file)
- **Providers:**
  1. `pinnedMessagesProvider(groupId)` - stream of pinned messages
  2. Pin/unpin action methods
- **Estimated Time:** 2 hours

**Task 3.1.6: Create Pinned Messages Banner**
- **File:** `lib/features/groups/presentation/widgets/pinned_messages_banner.dart` (new file)
- **UI:**
  1. Horizontal scrollable list at top of chat
  2. Each pinned message shows:
     - Message preview (50 chars)
     - Pin icon
     - Sender name
  3. Tap to scroll to message
  4. Long press (admin only) to unpin
  5. Auto-hide if no pinned messages
- **Styling:**
  - Distinct background color
  - Pin icon indicator
  - Smooth scroll animation
- **Estimated Time:** 4 hours

**Task 3.1.7: Add Pin Action to Message Menu**
- **File:** `lib/features/groups/presentation/screens/group_chat_screen.dart`
- **Actions:**
  1. Add "Pin Message" option to long-press menu (admin only)
  2. Add "Unpin Message" option for pinned messages
  3. Show limit warning if already 3 pinned
  4. Show success/error snackbar
- **Estimated Time:** 2 hours

**Task 3.1.8: Add Pin Indicator to Messages**
- **File:** Message bubble widget
- **Actions:**
  1. Add small pin icon on pinned messages
  2. Slightly different background color
- **Estimated Time:** 1 hour

#### Localization Tasks

**Task 3.1.9: Add Localization Keys**
- **Keys to Add:**
```json
{
  "pinned-messages": "Pinned Messages",
  "pin-message": "Pin Message",
  "unpin-message": "Unpin Message",
  "message-pinned": "Message pinned",
  "message-unpinned": "Message unpinned",
  "max-pinned-messages": "Maximum 3 messages can be pinned",
  "only-admins-can-pin": "Only admins can pin messages",
  "pinned-by": "Pinned by {name}",
  "tap-to-view": "Tap to view pinned message",
  "no-pinned-messages": "No pinned messages"
}
```
- **Estimated Time:** 30 minutes

#### Testing Tasks

**Task 3.1.10: Unit Tests**
- **Test Cases:**
  1. Admin can pin message
  2. Non-admin cannot pin
  3. Max 3 pinned enforced
  4. Pinned messages retrieved correctly
  5. Unpin works
- **Estimated Time:** 3 hours

**Task 3.1.11: Manual Testing Checklist**
- [ ] Admin can pin messages
- [ ] Non-admin cannot pin
- [ ] Max 3 pinned enforced
- [ ] Pinned banner displays correctly
- [ ] Tap to scroll works
- [ ] Long press to unpin works
- [ ] Pin indicator shows on message
- [ ] Success/error messages display
- **Estimated Time:** 1 hour

### Deliverables

- [ ] Pin/unpin functionality working
- [ ] Pinned messages banner complete
- [ ] Admin-only permissions enforced
- [ ] Max 3 limit working
- [ ] All tests passing

---

## Feature 3.2: Message Reactions

**User Story:** As a group member, I want to react to messages with emojis so that I can respond quickly without sending a message.

### Technical Tasks

#### Backend Tasks

**Task 3.2.1: Update Message Model**
- **File:** `lib/features/groups/data/models/group_message_model.dart`
- **Actions:**
  1. Add `reactions` field: `Map<String, List<String>>` (emoji -> [cpIds])
  2. Update `fromFirestore` and `toFirestore`
- **Example Structure:**
```dart
{
  "👍": ["cpId1", "cpId2"],
  "❤️": ["cpId1", "cpId3"],
  "😂": ["cpId2"]
}
```
- **Estimated Time:** 1 hour

**Task 3.2.2: Update Message Entity**
- **File:** `lib/features/groups/domain/entities/group_message_entity.dart`
- **Actions:**
  1. Add `reactions` property
  2. Add helper methods:
     - `getReactionCount(String emoji)`
     - `hasUserReacted(String cpId, String emoji)`
     - `getTotalReactions()`
  3. Update `copyWith`
- **Estimated Time:** 1 hour

**Task 3.2.3: Add Reaction Methods**
- **File:** `lib/features/groups/data/repositories/group_chat_repository.dart`
- **Methods:**
```dart
/// Add reaction to message (or remove if already reacted)
Future<void> toggleReaction({
  required String groupId,
  required String messageId,
  required String cpId,
  required String emoji,
});
```
- **Logic:**
  - If user already reacted with this emoji, remove it
  - If user didn't react, add it
  - Use Firestore array operations (arrayUnion/arrayRemove)
- **Estimated Time:** 3 hours

#### Frontend Tasks

**Task 3.2.4: Create Reactions Widget**
- **File:** `lib/features/groups/presentation/widgets/message_reactions_widget.dart` (new file)
- **UI:**
  1. Horizontal list of reaction bubbles below message
  2. Each bubble shows: emoji + count
  3. Highlighted if current user reacted
  4. Tap to toggle reaction
  5. Long press to see who reacted
- **Styling:**
  - Pill-shaped bubbles
  - Different color if user reacted
  - Smooth animations
- **Estimated Time:** 4 hours

**Task 3.2.5: Create Reaction Picker**
- **File:** `lib/features/groups/presentation/widgets/reaction_picker_widget.dart` (new file)
- **UI:**
  1. Bottom sheet with emoji picker
  2. Default reactions: 👍 ❤️ 😂 🎉 👏 🔥 ✅ 👎
  3. Tap emoji to react
  4. Auto-close after selection
- **Estimated Time:** 3 hours

**Task 3.2.6: Add Reaction Action**
- **File:** `lib/features/groups/presentation/screens/group_chat_screen.dart`
- **Actions:**
  1. Add reaction button to message menu
  2. Show reaction picker bottom sheet
  3. Handle reaction toggle
  4. Update UI optimistically
- **Estimated Time:** 2 hours

**Task 3.2.7: Create Reaction Details Modal**
- **File:** `lib/features/groups/presentation/widgets/reaction_details_modal.dart` (new file)
- **UI:**
  1. Show when long-pressing reaction bubble
  2. List of users who reacted with that emoji
  3. User avatars and names
- **Estimated Time:** 2 hours

#### Localization Tasks

**Task 3.2.8: Add Localization Keys**
- **Keys to Add:**
```json
{
  "add-reaction": "Add Reaction",
  "reactions": "Reactions",
  "reacted-with": "{count} reacted with {emoji}",
  "you-reacted": "You reacted",
  "and-others": "and {count} others",
  "pick-reaction": "Pick a reaction",
  "remove-reaction": "Tap again to remove"
}
```
- **Estimated Time:** 30 minutes

#### Testing Tasks

**Task 3.2.9: Unit Tests**
- **Test Cases:**
  1. Add reaction works
  2. Remove reaction works
  3. Toggle logic correct
  4. Counts accurate
  5. User list correct
- **Estimated Time:** 3 hours

**Task 3.2.10: Manual Testing Checklist**
- [ ] Reaction picker appears
- [ ] Reactions display correctly
- [ ] Toggle reaction works
- [ ] Counts accurate
- [ ] Highlight when user reacted
- [ ] Long press shows details
- [ ] Animations smooth
- [ ] Real-time updates work
- **Estimated Time:** 1 hour

### Deliverables

- [ ] Reactions fully functional
- [ ] Picker working
- [ ] Details modal complete
- [ ] Real-time updates working
- [ ] All tests passing

---

## Feature 3.3: Search Chat History

**User Story:** As a group member, I want to search chat history so that I can find specific messages quickly.

### Technical Tasks

#### Backend Tasks

**Task 3.3.1: Add Search Method**
- **File:** `lib/features/groups/data/repositories/group_chat_repository.dart`
- **Method:**
```dart
/// Search messages by keyword
Future<List<GroupMessageEntity>> searchMessages({
  required String groupId,
  required String query,
  int limit = 50,
});
```
- **Implementation:**
  - Use Firestore where clause on `body` field
  - Case-insensitive search
  - Limit results for performance
  - Order by relevance/date
- **Note:** Firestore has limited text search. May need to use client-side filtering or add Algolia later.
- **Estimated Time:** 4 hours

#### Frontend Tasks

**Task 3.3.2: Create Search Provider**
- **File:** `lib/features/groups/providers/chat_search_provider.dart` (new file)
- **Providers:**
  1. `chatSearchProvider(groupId, query)` - search results
  2. Search state management
- **Estimated Time:** 2 hours

**Task 3.3.3: Add Search Bar to Chat**
- **File:** `lib/features/groups/presentation/screens/group_chat_screen.dart`
- **UI:**
  1. Add search icon to app bar
  2. Expand to search field when tapped
  3. Show search results as you type (debounced)
  4. Clear button
  5. Close search mode
- **Estimated Time:** 3 hours

**Task 3.3.4: Create Search Results List**
- **File:** `lib/features/groups/presentation/widgets/chat_search_results.dart` (new file)
- **UI:**
  1. List of matching messages
  2. Highlight matching text
  3. Show sender and timestamp
  4. Tap to jump to message in chat
  5. Show "No results" state
- **Estimated Time:** 3 hours

**Task 3.3.5: Implement Jump to Message**
- **Actions:**
  1. When tapping search result, close search
  2. Scroll to message in chat
  3. Briefly highlight the message
- **Estimated Time:** 2 hours

#### Localization Tasks

**Task 3.3.6: Add Localization Keys**
- **Keys to Add:**
```json
{
  "search-messages": "Search Messages",
  "search-placeholder": "Search in conversation...",
  "search-results": "Search Results",
  "no-results-found": "No messages found",
  "search-in-progress": "Searching...",
  "clear-search": "Clear Search",
  "found-messages": "Found {count} messages"
}
```
- **Estimated Time:** 30 minutes

#### Testing Tasks

**Task 3.3.7: Unit Tests**
- **Test Cases:**
  1. Search returns correct results
  2. Case-insensitive works
  3. No results handled
  4. Limit enforced
- **Estimated Time:** 2 hours

**Task 3.3.8: Manual Testing Checklist**
- [ ] Search icon appears
- [ ] Search field expands
- [ ] Results appear as typing
- [ ] Debouncing works
- [ ] Highlight correct
- [ ] Jump to message works
- [ ] Clear button works
- [ ] Close search works
- [ ] No results state shows
- **Estimated Time:** 1 hour

### Deliverables

- [ ] Search functionality working
- [ ] Results display correctly
- [ ] Jump to message works
- [ ] Performance acceptable
- [ ] All tests passing

---

## Sprint 3 Summary

**Total Estimated Time:** 10 working days (2 weeks)

**Sprint Deliverables:**
- [ ] Message pinning functional (max 3)
- [ ] Reactions working on all messages
- [ ] Search chat history implemented
- [ ] All UI polished
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo pin messages
- [ ] Demo reactions
- [ ] Demo search
- [ ] Show real-time updates
- [ ] Review performance
- [ ] Review test coverage

