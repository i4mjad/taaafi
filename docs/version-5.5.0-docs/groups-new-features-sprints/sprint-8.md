# Sprint 8: Onboarding & Polish (1 week)

**Sprint Goal:** Implement onboarding experience and final polish

**Duration:** 1 week  
**Priority:** LOW-MEDIUM  
**Dependencies:** All previous sprints (1-7) completed

---

## Feature 8.1: Group Onboarding

**User Story:** As a new group member, I want a guided onboarding so that I understand how to use the group effectively.

### Technical Tasks

#### Backend Tasks

**Task 8.1.1: Extend Group Schema for Onboarding**
- **Collection:** `groups`
- **New Fields to Add:**
```dart
{
  welcomeMessage: string?,        // Custom welcome message (max 500 chars)
  groupRules: string?,           // Group rules text (max 1000 chars)
  requireRulesAcknowledgment: boolean // Default false
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Backend Developer

**Task 8.1.2: Extend Membership Schema**
- **Collection:** `group_memberships`
- **New Fields to Add:**
```dart
{
  acknowledgedRulesAt: timestamp?, // When member accepted rules
  hasPostedIntroduction: boolean   // Default false
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Backend Developer

**Task 8.1.3: Create Onboarding Service**
- **File:** `lib/features/groups/domain/services/group_onboarding_service.dart` (new file)
- **Methods:**
```dart
// Welcome message management
Future<void> setWelcomeMessage(String groupId, String message);
Future<String?> getWelcomeMessage(String groupId);

// Rules management
Future<void> setGroupRules(String groupId, String rules, bool requireAcknowledgment);
Future<String?> getGroupRules(String groupId);

// Member onboarding
Future<void> acknowledgeRules(String groupId, String cpId);
Future<bool> hasAcknowledgedRules(String groupId, String cpId);
Future<void> markIntroductionPosted(String groupId, String cpId);

// Onboarding status
Future<OnboardingStatus> getOnboardingStatus(String groupId, String cpId);
```
- **Estimated Time:** 4 hours
- **Assignee:** Backend Developer

**Task 8.1.4: Add Repository Methods**
- **File:** `lib/features/groups/domain/repositories/groups_repository.dart`
- **Methods to Add:**
```dart
/// Update welcome message (admin only)
Future<void> updateWelcomeMessage({
  required String groupId,
  required String adminCpId,
  String? message,
});

/// Update group rules (admin only)
Future<void> updateGroupRules({
  required String groupId,
  required String adminCpId,
  String? rules,
  bool requireAcknowledgment = false,
});

/// Acknowledge rules
Future<void> acknowledgeRules(String groupId, String cpId);
```
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 8.1.5: Implement Repository Methods**
- **File:** `lib/features/groups/data/repositories/groups_repository_impl.dart`
- **Actions:**
  1. Verify admin permissions
  2. Validate message/rules length
  3. Update group document
  4. Update membership document for acknowledgment
- **Estimated Time:** 3 hours
- **Assignee:** Backend Developer

#### Frontend Tasks

**Task 8.1.6: Create Welcome Screen**
- **File:** `lib/features/groups/presentation/screens/onboarding/group_welcome_screen.dart` (new file)
- **UI:**
  1. **Header:**
     - Group avatar/icon
     - Group name
     - "Welcome!" title
  2. **Welcome Message:**
     - Admin's custom message
     - Default: "Welcome to {groupName}!"
  3. **Group Rules Section** (if rules exist):
     - Rules text
     - Scrollable if long
     - "I acknowledge and agree" checkbox (if required)
  4. **Quick Tour:**
     - "What you can do here" section
     - Chat, Challenges, Updates icons
  5. **Introduction Prompt:**
     - "Introduce yourself!" section
     - Quick intro button
     - "Skip for now" button
  6. **Get Started Button:**
     - Disabled if rules not acknowledged (when required)
     - Navigate to group screen
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 8.1.7: Create Introduction Prompt Modal**
- **File:** `lib/features/groups/presentation/widgets/onboarding/introduction_prompt_modal.dart` (new file)
- **UI:**
  1. Title: "Introduce yourself to the group!"
  2. Template suggestions (chips):
     - "Hi! I'm looking forward to being part of this group."
     - "Hello! I joined to work on..."
     - "Hi everyone! Excited to support each other!"
  3. Text area for custom introduction
  4. Character counter (500 max)
  5. Post button
  6. Skip button
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 8.1.8: Create Welcome Message Settings Screen**
- **File:** `lib/features/groups/presentation/screens/onboarding/welcome_message_settings_screen.dart` (new file)
- **UI (Admin Only):**
  1. App bar: "Welcome Message"
  2. Text area for welcome message
  3. Character counter (500 max)
  4. Preview section
  5. Save button
  6. "Use default" button
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 8.1.9: Create Group Rules Settings Screen**
- **File:** `lib/features/groups/presentation/screens/onboarding/group_rules_settings_screen.dart` (new file)
- **UI (Admin Only):**
  1. App bar: "Group Rules"
  2. Text area for rules
  3. Character counter (1000 max)
  4. Toggle: "Require members to acknowledge rules"
  5. Preview section
  6. Save button
  7. Clear button
- **Member View:**
  1. Display rules (read-only)
  2. Show acknowledged date
  3. "View Rules" from settings
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 8.1.10: Integrate Onboarding Flow**
- **File:** `lib/features/groups/presentation/screens/group_screen.dart`
- **Actions:**
  1. Check if user has completed onboarding
  2. If not, show welcome screen (modal)
  3. Track onboarding completion
  4. Navigate to group screen after completion
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

**Task 8.1.11: Add to Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Welcome Message" card (admin section)
  2. Add "Group Rules" card (admin section)
  3. Add "View Rules" for members
  4. Navigate to respective settings screens
- **Estimated Time:** 1 hour
- **Assignee:** Frontend Developer

#### Localization

**Task 8.1.12: Add Localization Keys**
- **Files:** 
  - `lib/i18n/en_translations.dart`
  - `lib/i18n/ar_translations.dart`
- **Keys:**
```json
{
  "welcome-to-group": "Welcome to {groupName}!",
  "group-welcome": "Welcome",
  "welcome-message": "Welcome Message",
  "set-welcome-message": "Set Welcome Message",
  "welcome-message-placeholder": "Welcome new members with a custom message...",
  "default-welcome-message": "Welcome! We're glad to have you here.",
  "use-default-welcome": "Use Default Message",
  
  "group-rules": "Group Rules",
  "set-group-rules": "Set Group Rules",
  "edit-group-rules": "Edit Group Rules",
  "view-rules": "View Rules",
  "rules-placeholder": "Set clear rules for your group...",
  "no-rules-set": "No rules have been set for this group",
  "require-rules-acknowledgment": "Require members to acknowledge rules",
  "acknowledge-rules": "I acknowledge and agree to follow the group rules",
  "rules-required": "You must acknowledge the rules to continue",
  "rules-acknowledged": "Rules acknowledged on {date}",
  "rules-updated": "Group rules updated",
  "members-will-be-notified": "Members will be notified of rule updates",
  
  "introduce-yourself": "Introduce Yourself",
  "introduction-prompt": "Say hello to the group!",
  "introduction-placeholder": "Hi everyone! I'm...",
  "introduction-templates": "Quick Templates",
  "template-short-intro": "Hi! I'm looking forward to being part of this group.",
  "template-goals": "Hello! I joined to work on...",
  "template-support": "Hi everyone! Excited to support each other!",
  "post-introduction": "Post Introduction",
  "skip-introduction": "Skip for now",
  "introduction-posted": "Introduction posted!",
  
  "get-started": "Get Started",
  "what-you-can-do": "What you can do here",
  "onboarding-chat": "Chat with members",
  "onboarding-challenges": "Join challenges",
  "onboarding-updates": "Share updates",
  "welcome-message-saved": "Welcome message saved",
  "rules-saved": "Group rules saved"
}
```
- **Estimated Time:** 1 hour
- **Assignee:** Developer + Translator

#### Testing

**Task 8.1.13: Manual Testing Checklist**
- [ ] Welcome screen shows on join
- [ ] Welcome message displays correctly
- [ ] Rules acknowledgment required (if set)
- [ ] Introduction prompt appears
- [ ] Can skip introduction
- [ ] Intro posts to chat correctly
- [ ] Admin can edit welcome message
- [ ] Admin can edit rules
- [ ] Changes save correctly
- [ ] Onboarding completes properly
- **Estimated Time:** 1 hour
- **Assignee:** QA Engineer

### Deliverables - Part 1 (Days 1-3)

- [ ] Welcome system complete
- [ ] Rules system functional
- [ ] Introduction prompt working
- [ ] Admin configuration screens
- [ ] Onboarding flow smooth
- [ ] Tests passing

---

## Feature 8.2: Scheduled Messages & Polls

**User Story:** As an admin, I want to schedule messages and create polls so that I can manage communication better.

### Technical Tasks

#### Scheduled Messages

**Task 8.2.1: Create Scheduled Messages Schema**
- **Collection:** `scheduled_messages`
- **Document Structure:**
```dart
{
  id: string,
  groupId: string,
  authorCpId: string,
  body: string,              // Max 5000 chars
  scheduledFor: timestamp,
  status: 'pending' | 'sent' | 'cancelled',
  sentAt: timestamp?,
  createdAt: timestamp
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Backend Developer

**Task 8.2.2: Create Scheduled Messages Repository**
- **File:** `lib/features/groups/domain/repositories/scheduled_messages_repository.dart` (new file)
- **Methods:**
```dart
Future<String> scheduleMessage(ScheduledMessageEntity message);
Future<void> cancelScheduledMessage(String messageId);
Future<List<ScheduledMessageEntity>> getScheduledMessages(String groupId);
Future<void> sendScheduledMessage(String messageId);
```
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 8.2.3: Implement Repository**
- **File:** `lib/features/groups/data/repositories/scheduled_messages_repository_impl.dart` (new file)
- **Implement all methods**
- **Estimated Time:** 3 hours
- **Assignee:** Backend Developer

**Task 8.2.4: Create Schedule Message UI**
- **File:** `lib/features/groups/presentation/widgets/scheduled_messages/schedule_message_modal.dart` (new file)
- **UI:**
  1. Message text area
  2. Date picker
  3. Time picker
  4. Preview
  5. Schedule button
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 8.2.5: Add to Chat Screen**
- **File:** `lib/features/groups/presentation/screens/group_chat_screen.dart`
- **Actions:**
  1. Add schedule button to compose area (admin only)
  2. Show scheduled messages list
  3. Allow canceling scheduled messages
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

**Task 8.2.6: Create Cloud Function for Sending**
- **File:** Cloud Function
- **Function:** Check every 5 minutes for pending scheduled messages
- **Process:**
  1. Query `scheduled_messages` where `status = 'pending'` and `scheduledFor <= now`
  2. Send each message to group chat
  3. Update status to 'sent'
- **Estimated Time:** 3 hours
- **Assignee:** Backend Developer

#### Polls System

**Task 8.2.7: Create Polls Schema**
- **Collection:** `polls`
- **Document Structure:**
```dart
{
  id: string,
  groupId: string,
  authorCpId: string,
  question: string,          // Max 200 chars
  options: array<{
    id: string,
    text: string,            // Max 100 chars
    votes: array<string>     // cpIds who voted
  }>,
  duration: int,             // Hours
  expiresAt: timestamp,
  status: 'active' | 'ended',
  allowMultipleVotes: boolean,
  isAnonymous: boolean,
  createdAt: timestamp
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Backend Developer

**Task 8.2.8: Create Polls Repository**
- **File:** `lib/features/groups/domain/repositories/polls_repository.dart` (new file)
- **Methods:**
```dart
Future<String> createPoll(PollEntity poll);
Future<void> vote(String pollId, String cpId, String optionId);
Future<void> unvote(String pollId, String cpId, String optionId);
Stream<PollEntity> getPoll(String pollId);
Future<void> endPoll(String pollId);
```
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 8.2.9: Implement Repository**
- **File:** `lib/features/groups/data/repositories/polls_repository_impl.dart` (new file)
- **Implement all methods with validation**
- **Estimated Time:** 3 hours
- **Assignee:** Backend Developer

**Task 8.2.10: Create Poll Creation UI**
- **File:** `lib/features/groups/presentation/widgets/polls/create_poll_modal.dart` (new file)
- **UI:**
  1. Question field
  2. Option fields (2-10 options)
  3. Add option button
  4. Duration selector (1h, 3h, 6h, 12h, 1d, 3d, 7d)
  5. Settings:
     - Allow multiple votes toggle
     - Anonymous voting toggle
  6. Create button
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 8.2.11: Create Poll Display Widget**
- **File:** `lib/features/groups/presentation/widgets/polls/poll_widget.dart` (new file)
- **UI:**
  1. Question
  2. Options as tappable cards
  3. Vote counts / percentages
  4. Visual bar showing vote distribution
  5. "Voted" indicator on selected options
  6. Time remaining countdown
  7. Total votes
  8. "Poll ended" state
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 8.2.12: Integrate Polls into Chat**
- **File:** `lib/features/groups/presentation/screens/group_chat_screen.dart`
- **Actions:**
  1. Add poll button to compose area (admin only)
  2. Display polls in chat messages
  3. Handle voting interactions
  4. Real-time updates
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

#### Localization

**Task 8.2.13: Add Localization Keys**
- **Keys:**
```json
{
  "schedule-message": "Schedule Message",
  "scheduled-messages": "Scheduled Messages",
  "schedule-for": "Schedule for",
  "select-date-time": "Select Date and Time",
  "message-scheduled": "Message scheduled for {time}",
  "cancel-scheduled-message": "Cancel Scheduled Message",
  "confirm-cancel-schedule": "Are you sure you want to cancel this scheduled message?",
  "scheduled-message-cancelled": "Scheduled message cancelled",
  
  "create-poll": "Create Poll",
  "poll-question": "Poll Question",
  "poll-options": "Poll Options",
  "add-option": "Add Option",
  "remove-option": "Remove Option",
  "poll-duration": "Poll Duration",
  "duration-1h": "1 hour",
  "duration-3h": "3 hours",
  "duration-6h": "6 hours",
  "duration-12h": "12 hours",
  "duration-1d": "1 day",
  "duration-3d": "3 days",
  "duration-7d": "7 days",
  "allow-multiple-votes": "Allow Multiple Votes",
  "anonymous-voting": "Anonymous Voting",
  "create-poll-button": "Create Poll",
  "vote": "Vote",
  "votes": "votes",
  "voted": "Voted",
  "poll-ended": "Poll Ended",
  "poll-results": "Results",
  "you-voted": "You voted for:",
  "poll-closes-in": "Closes in {time}",
  "total-votes": "{count} total votes",
  "poll-created": "Poll created",
  "vote-recorded": "Vote recorded",
  "vote-changed": "Vote changed",
  "min-two-options": "Poll must have at least 2 options",
  "max-ten-options": "Poll can have maximum 10 options",
  "poll-question-required": "Poll question is required",
  "option-required": "All options must have text"
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Developer + Translator

#### Testing

**Task 8.2.14: Manual Testing Checklist**
- [ ] Can schedule messages
- [ ] Messages send at correct time
- [ ] Can cancel scheduled messages
- [ ] Can create polls
- [ ] Can vote on polls
- [ ] Cannot vote twice (single vote mode)
- [ ] Can change vote (multiple vote mode)
- [ ] Results display correctly
- [ ] Poll expires correctly
- [ ] Real-time updates work
- **Estimated Time:** 1 hour
- **Assignee:** QA Engineer

### Deliverables - Part 2 (Days 3-4)

- [ ] Scheduled messages working
- [ ] Polls functional
- [ ] Admin controls working
- [ ] UI polished
- [ ] Tests passing

---

## Feature 8.3: Final Polish & Bug Fixes

### Technical Tasks

**Task 8.3.1: Performance Optimization**
- **Actions:**
  1. Optimize query performance across all features
  2. Add caching for frequently accessed data
  3. Lazy load images in feeds
  4. Optimize animations (60fps target)
  5. Reduce bundle size where possible
  6. Profile and fix memory leaks
- **Estimated Time:** 6 hours
- **Assignee:** Performance Engineer

**Task 8.3.2: Accessibility Review**
- **Actions:**
  1. Add semantic labels to all buttons
  2. Test screen readers (iOS VoiceOver, Android TalkBack)
  3. Improve contrast ratios (WCAG AA minimum)
  4. Add keyboard navigation support where applicable
  5. Test with large text sizes
  6. Ensure all interactive elements are tappable (44x44 minimum)
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 8.3.3: Bug Fixes**
- **Actions:**
  1. Fix any bugs found in testing
  2. Address edge cases
  3. Improve error messages
  4. Fix UI inconsistencies
  5. Resolve performance issues
- **Estimated Time:** 6 hours
- **Assignee:** Development Team

**Task 8.3.4: Documentation**
- **Actions:**
  1. Update API documentation
  2. Create user guides for new features
  3. Add inline code comments where needed
  4. Update README with new features
  5. Document Cloud Functions
  6. Create admin guide for new features
- **Estimated Time:** 4 hours
- **Assignee:** Documentation Lead

### Deliverables - Part 3 (Days 4-5)

- [ ] Performance optimized
- [ ] Accessibility improved
- [ ] All bugs fixed
- [ ] Documentation complete
- [ ] Ready for release

---

## Sprint 8 Summary

**Total Estimated Time:** 5 working days (1 week)

**Sprint Deliverables:**
- [ ] Onboarding experience complete
- [ ] Scheduled messages working
- [ ] Polls functional
- [ ] Performance optimized
- [ ] Accessibility improved
- [ ] All bugs fixed
- [ ] Ready for production

**Sprint Review Checklist:**
- [ ] Demo onboarding flow
- [ ] Demo scheduled messages
- [ ] Demo polls
- [ ] Review performance improvements
- [ ] Review accessibility features
- [ ] Final QA approval

---

## Firestore Schema Changes

**Collections Modified:**
1. ✅ `groups` - Added `welcomeMessage`, `groupRules`, `requireRulesAcknowledgment`
2. ✅ `group_memberships` - Added `acknowledgedRulesAt`, `hasPostedIntroduction`

**New Collections Created:**
1. ✅ `scheduled_messages` - Message scheduling
2. ✅ `polls` - Polling system

**Indexes Required:**
```json
{
  "indexes": [
    {
      "collectionGroup": "scheduled_messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "scheduledFor", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "polls",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Cloud Functions Required

**Function: Scheduled Message Sender**
- **Name:** `sendScheduledMessages`
- **Schedule:** Every 5 minutes
- **Process:**
  1. Query pending scheduled messages where `scheduledFor <= now`
  2. Send each message to group chat
  3. Update status to 'sent'

**Function: Poll Expiration Handler**
- **Name:** `handlePollExpiration`
- **Schedule:** Every hour
- **Process:**
  1. Query active polls where `expiresAt <= now`
  2. Change status to 'ended'
  3. Send notification to group

---

## Performance Targets

**Loading Times:**
- Dashboard load: < 2s
- Feed load: < 1.5s
- Chart render: < 1s
- Poll creation: < 500ms

**Animation:**
- All animations: 60fps
- Smooth scrolling in feeds
- No jank on interactions

**Memory:**
- App memory usage: < 150MB
- No memory leaks
- Efficient image caching

---

## Accessibility Checklist

- [ ] All buttons have semantic labels
- [ ] Screen readers work correctly
- [ ] Contrast ratios meet WCAG AA
- [ ] Interactive elements ≥ 44x44 dp
- [ ] Text scales properly
- [ ] Focus indicators visible
- [ ] Error messages announced
- [ ] Loading states announced

---

## Pre-Release Checklist

- [ ] All features tested on iOS
- [ ] All features tested on Android
- [ ] Performance acceptable
- [ ] Accessibility reviewed
- [ ] Localization complete (EN + AR)
- [ ] Security reviewed
- [ ] Cloud Functions deployed
- [ ] Firestore indexes created
- [ ] Security rules updated
- [ ] Analytics instrumentation added
- [ ] Error tracking set up
- [ ] Documentation complete
- [ ] Stakeholder approval obtained

---

**Sprint 8 Status:** 📋 READY TO START

**Dependencies:** All sprints (1-7) completed, ready for production deployment

