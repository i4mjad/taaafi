# Sprint 6: Shared Updates Feed (2 weeks)

**Sprint Goal:** Build updates feed integrated with user's followup system

**Duration:** 2 weeks  
**Priority:** HIGH  
**Dependencies:** Sprint 5 completed, User followup system exists

---

## Feature 6.1: Updates Infrastructure

**User Story:** As a group member, I want to share my progress updates so that I can stay accountable and receive support.

### Technical Tasks

#### Backend - Database Schema

**Task 6.1.1: Create Updates Collection Schema**
- **Collection:** `group_updates`
- **Document Structure:**
```dart
{
  id: string,
  groupId: string,
  authorCpId: string,
  
  // Content
  type: 'progress' | 'milestone' | 'checkin' | 'general' | 'encouragement',
  title: string,                  // Max 100 chars
  content: string,                // Max 1000 chars
  imageUrl: string?,
  
  // Links to user data
  linkedFollowupId: string?,      // Link to user's followup entry
  linkedChallengeId: string?,     // Link to challenge if relevant
  linkedMilestoneId: string?,     // Link to achievement/milestone
  
  // Metadata
  isAnonymous: boolean,
  visibility: 'public' | 'members_only',
  
  // Engagement
  reactions: map<string, array<string>>, // emoji -> [cpIds]
  commentCount: int,
  supportCount: int,              // count of support reactions
  
  // Status
  isPinned: boolean,
  isHidden: boolean,
  
  // Timestamps
  createdAt: timestamp,
  updatedAt: timestamp
}
```
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 6.1.2: Create Update Comments Collection**
- **Collection:** `update_comments`
- **Document Structure:**
```dart
{
  id: string,
  updateId: string,
  groupId: string,
  authorCpId: string,
  content: string,               // Max 500 chars
  isAnonymous: boolean,
  isHidden: boolean,
  reactions: map<string, array<string>>,
  createdAt: timestamp
}
```
- **Estimated Time:** 30 minutes
- **Assignee:** Backend Developer

#### Backend - Domain Layer

**Task 6.1.3: Create Update Entity**
- **File:** `lib/features/groups/domain/entities/group_update_entity.dart` (new file)
- **Properties:** Map all fields
- **Methods:**
  1. `getReactionCount(String emoji)`
  2. `hasUserReacted(String cpId, String emoji)`
  3. `getTotalReactions()`
  4. `canEdit(String cpId)` - check if user can edit
  5. `canDelete(String cpId, bool isAdmin)` - check permissions
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 6.1.4: Create Update Comment Entity**
- **File:** `lib/features/groups/domain/entities/update_comment_entity.dart` (new file)
- **Properties:** Map all fields
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 6.1.5: Create Updates Repository Interface**
- **File:** `lib/features/groups/domain/repositories/updates_repository.dart` (new file)
- **Methods:**
```dart
// Update CRUD
Future<String> createUpdate(GroupUpdateEntity update);
Future<GroupUpdateEntity?> getUpdateById(String updateId);
Future<void> updateUpdate(GroupUpdateEntity update);
Future<void> deleteUpdate(String updateId);

// Update queries
Stream<List<GroupUpdateEntity>> getGroupUpdates(String groupId);
Future<List<GroupUpdateEntity>> getRecentUpdates(String groupId, int limit);
Future<List<GroupUpdateEntity>> getUserUpdates(String groupId, String cpId);
Future<List<GroupUpdateEntity>> getUpdatesByType(String groupId, String type);

// Reactions
Future<void> toggleReaction(String updateId, String cpId, String emoji);

// Comments
Future<String> addComment(UpdateCommentEntity comment);
Future<void> deleteComment(String commentId);
Stream<List<UpdateCommentEntity>> getUpdateComments(String updateId);

// Moderation
Future<void> hideUpdate(String updateId, String adminCpId);
Future<void> unhideUpdate(String updateId, String adminCpId);
Future<void> pinUpdate(String updateId, String adminCpId);
Future<void> unpinUpdate(String updateId, String adminCpId);
```
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

#### Backend - Data Layer

**Task 6.1.6: Create Update Model**
- **File:** `lib/features/groups/data/models/group_update_model.dart` (new file)
- **Standard model methods**
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

**Task 6.1.7: Create Update Comment Model**
- **File:** `lib/features/groups/data/models/update_comment_model.dart` (new file)
- **Standard model methods**
- **Estimated Time:** 1 hour
- **Assignee:** Backend Developer

**Task 6.1.8: Implement Updates Repository**
- **File:** `lib/features/groups/data/repositories/updates_repository_impl.dart` (new file)
- **Implement all methods with Firestore**
- **Add validation and error handling**
- **Estimated Time:** 8 hours
- **Assignee:** Backend Developer

#### Backend - Application Layer

**Task 6.1.9: Create Updates Service**
- **File:** `lib/features/groups/domain/services/updates_service.dart` (new file)
- **Methods:**
```dart
// Post update
Future<PostUpdateResult> postUpdate({...});

// Link to followup system
Future<GroupUpdateEntity> createUpdateFromFollowup(String followupId, String groupId);

// Link to milestone
Future<GroupUpdateEntity> createMilestoneUpdate(String milestoneId, String groupId);

// Auto-suggest updates
Future<List<UpdateSuggestion>> getSuggestedUpdates(String cpId, String groupId);

// Engagement
Future<void> reactToUpdate(String updateId, String cpId, String emoji);
Future<void> commentOnUpdate(String updateId, String cpId, String content);
```
- **Estimated Time:** 6 hours
- **Assignee:** Backend Developer

**Task 6.1.10: Create Followup Integration Service**
- **File:** `lib/features/groups/domain/services/followup_integration_service.dart` (new file)
- **Purpose:** Bridge between followup system and updates
- **Methods:**
```dart
// Get user's recent followups
Future<List<FollowupEntry>> getRecentFollowups(String cpId);

// Check if followup already shared
Future<bool> isFollowupShared(String followupId, String groupId);

// Get suggested content from followup
String generateUpdateContent(FollowupEntry followup);

// Link update to followup
Future<void> linkUpdateToFollowup(String updateId, String followupId);
```
- **Estimated Time:** 4 hours
- **Assignee:** Backend Developer

#### Frontend - Providers

**Task 6.1.11: Create Updates Providers**
- **File:** `lib/features/groups/providers/updates_providers.dart` (new file)
- **Providers:**
```dart
@riverpod Stream<List<GroupUpdateEntity>> groupUpdates(ref, groupId);
@riverpod Future<GroupUpdateEntity?> updateById(ref, updateId);
@riverpod Stream<List<UpdateCommentEntity>> updateComments(ref, updateId);
@riverpod Future<List<UpdateSuggestion>> updateSuggestions(ref, cpId, groupId);
```
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 6.1.12: Create Updates Controller**
- **File:** `lib/features/groups/application/updates_controller.dart` (new file)
- **Controller methods with state management**
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

#### Firestore Setup

**Task 6.1.13: Create Indexes and Security Rules**
- **Indexes:**
  1. `group_updates`: `groupId` + `createdAt` + `isPinned`
  2. `update_comments`: `updateId` + `createdAt`
- **Security Rules:** Read/write permissions
- **Estimated Time:** 2 hours
- **Assignee:** Backend Developer

#### Testing Tasks

**Task 6.1.14: Unit Tests**
- **Test all repository and service methods**
- **Estimated Time:** 6 hours
- **Assignee:** QA Engineer

### Deliverables - Sprint 6 Week 1

- [ ] Database schema implemented
- [ ] Domain entities created
- [ ] Repository complete
- [ ] Services with business logic
- [ ] Followup integration working
- [ ] Providers created
- [ ] Tests passing

---

## Feature 6.2: Updates Feed UI

**User Story:** As a group member, I want to view and interact with updates so that I can support others and stay connected.

### Technical Tasks

#### UI Components

**Task 6.2.1: Create Updates Feed Screen**
- **File:** `lib/features/groups/presentation/screens/updates/group_updates_feed_screen.dart` (new file)
- **Sections:**
  1. **Header:**
     - "Updates" title
     - Filter button (All, Progress, Milestones, Check-ins)
     - Post button (FAB)
  2. **Pinned Updates:**
     - Horizontal scrollable cards
     - Max 3 pinned
  3. **Feed:**
     - Infinite scroll list
     - Pull-to-refresh
     - Update cards
     - "Load More" at bottom
  4. **Empty State:**
     - "No updates yet"
     - "Be the first to share!" button
- **Estimated Time:** 5 hours
- **Assignee:** Frontend Developer

**Task 6.2.2: Create Update Card Widget**
- **File:** `lib/features/groups/presentation/widgets/updates/update_card_widget.dart` (new file)
- **Display:**
  1. **Header:**
     - Avatar (or anonymous icon)
     - Name (or "Anonymous Member")
     - Update type badge
     - Timestamp
     - Options menu (3 dots)
  2. **Content:**
     - Title (if exists)
     - Content text (expand/collapse if long)
     - Image (if exists)
     - Linked challenge badge (if applicable)
  3. **Engagement Bar:**
     - Reactions row (emoji counts)
     - Add reaction button
     - Comment count with icon
     - Support button (heart)
  4. **Comments Preview:**
     - Show first 2 comments
     - "View all X comments" button
- **Interactions:**
  - Tap image to view full screen
  - Tap reactions to see who reacted
  - Tap comments to expand all
  - Long press for quick actions
- **Estimated Time:** 6 hours
- **Assignee:** Frontend Developer

**Task 6.2.3: Create Post Update Modal**
- **File:** `lib/features/groups/presentation/widgets/updates/post_update_modal.dart` (new file)
- **UI:**
  1. **Type Selector:**
     - Chips: Progress, Milestone, Check-in, General
  2. **Content Input:**
     - Title field (optional, 100 chars)
     - Content textarea (required, 1000 chars)
     - Character counter
  3. **Options:**
     - Add image button (camera/gallery)
     - Link followup toggle (if applicable)
     - Anonymous posting toggle
     - Link challenge selector (if in challenge)
  4. **Followup Integration Section:**
     - "Share from your followup" button
     - Shows recent followups
     - Auto-fill content option
  5. **Preview:**
     - Show how update will look
  6. **Actions:**
     - Cancel button
     - Post button (disabled if invalid)
- **Estimated Time:** 6 hours
- **Assignee:** Frontend Developer

**Task 6.2.4: Create Followup Selector Modal**
- **File:** `lib/features/groups/presentation/widgets/updates/followup_selector_modal.dart` (new file)
- **UI:**
  1. List of recent followups (last 7 days)
  2. Each shows:
     - Date
     - Type (prayer, activity, etc.)
     - Preview of content
     - "Already shared" badge if applicable
  3. Select button
  4. Auto-populate update with followup data
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 6.2.5: Create Comment Section Widget**
- **File:** `lib/features/groups/presentation/widgets/updates/update_comments_widget.dart` (new file)
- **UI:**
  1. Comments list
  2. Each comment shows:
     - Avatar
     - Name
     - Content
     - Timestamp
     - Reactions
     - Reply button (future feature)
  3. Add comment field at bottom
  4. Send button
- **Estimated Time:** 4 hours
- **Assignee:** Frontend Developer

**Task 6.2.6: Create Update Details Screen**
- **File:** `lib/features/groups/presentation/screens/updates/update_detail_screen.dart` (new file)
- **Purpose:** Full screen view of single update
- **Sections:**
  1. Full update card
  2. All comments
  3. Engagement details
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

**Task 6.2.7: Create Weekly Check-in Prompt**
- **File:** `lib/features/groups/presentation/widgets/updates/weekly_checkin_prompt_widget.dart` (new file)
- **UI:**
  1. Friendly prompt card at top of feed
  2. "How was your week?" message
  3. Quick post button
  4. Dismiss for this week option
- **Show logic:**
  - Only once per week
  - Only if user hasn't posted in 7 days
  - Dismissible
- **Estimated Time:** 3 hours
- **Assignee:** Frontend Developer

#### Integration Points

**Task 6.2.8: Add Updates to Group Screen**
- **File:** `lib/features/groups/presentation/screens/group_screen.dart`
- **Actions:**
  1. Replace "Coming Soon" card with real Updates button
  2. Show recent update count
  3. Navigate to updates feed
- **Estimated Time:** 1 hour
- **Assignee:** Frontend Developer

**Task 6.2.9: Link from Challenges**
- **File:** Challenge detail screen
- **Actions:**
  1. Add "Share Update" button
  2. Pre-fill with challenge info
  3. Auto-link to challenge
- **Estimated Time:** 2 hours
- **Assignee:** Frontend Developer

#### Localization

**Task 6.2.10: Add Localization Keys**
- **Files:** 
  - `lib/i18n/en_translations.dart`
  - `lib/i18n/ar_translations.dart`
- **Keys:** (80+ keys)
```json
{
  "updates": "Updates",
  "updates-feed": "Updates Feed",
  "post-update": "Post Update",
  "share-update": "Share Update",
  "update-types": "Update Types",
  "progress-update": "Progress Update",
  "milestone-update": "Milestone",
  "checkin-update": "Check-in",
  "general-update": "General",
  "encouragement": "Encouragement",
  "update-title": "Title (optional)",
  "update-content": "What's your update?",
  "add-image": "Add Image",
  "post-anonymously": "Post Anonymously",
  "link-followup": "Link to Followup",
  "link-challenge": "Link to Challenge",
  "post-update-button": "Post Update",
  "update-posted": "Update posted!",
  "select-from-followup": "Share from Followup",
  "recent-followups": "Recent Followups",
  "already-shared": "Already Shared",
  "no-recent-followups": "No recent followups",
  "view-all-comments": "View all {count} comments",
  "add-comment": "Add a comment...",
  "send-comment": "Send",
  "comment-added": "Comment added",
  "delete-update": "Delete Update",
  "edit-update": "Edit Update",
  "hide-update": "Hide Update",
  "pin-update": "Pin Update",
  "report-update": "Report Update",
  "confirm-delete-update": "Are you sure you want to delete this update?",
  "update-deleted": "Update deleted",
  "no-updates-yet": "No updates yet",
  "be-first-to-share": "Be the first to share your progress!",
  "filter-updates": "Filter Updates",
  "weekly-checkin-prompt": "How was your week? Share an update with the group!",
  "dismiss-checkin": "Ask me next week",
  "linked-to-challenge": "Linked to challenge: {challengeName}",
  "linked-to-followup": "Shared from followup"
}
```
- **Estimated Time:** 2 hours
- **Assignee:** Developer + Translator

#### Testing Tasks

**Task 6.2.11: Widget Tests**
- **Test all update widgets**
- **Estimated Time:** 6 hours
- **Assignee:** QA Engineer

**Task 6.2.12: Manual Testing Checklist**
- [ ] Can post all update types
- [ ] Can link followup data
- [ ] Can link challenges
- [ ] Images upload correctly
- [ ] Anonymous posting works
- [ ] Comments work
- [ ] Reactions work
- [ ] Feed loads smoothly
- [ ] Pull-to-refresh works
- [ ] Infinite scroll works
- [ ] Edit/delete works (own updates)
- [ ] Admin can hide updates
- [ ] Pin/unpin works
- [ ] Empty states display
- **Estimated Time:** 3 hours
- **Assignee:** QA Engineer

### Deliverables - Sprint 6 Week 2

- [ ] Updates feed complete
- [ ] Post update flow working
- [ ] Followup integration functional
- [ ] Challenge linking works
- [ ] Comments system complete
- [ ] Reactions working
- [ ] All UI polished
- [ ] Localization complete
- [ ] Tests passing

---

## Sprint 6 Summary

**Total Estimated Time:** 10 working days (2 weeks)

**Sprint Deliverables:**
- [ ] Complete updates feed system
- [ ] Post/view/interact with updates
- [ ] Followup integration working
- [ ] Challenge integration working
- [ ] Comments and reactions functional
- [ ] UI polished
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo posting update
- [ ] Demo followup integration
- [ ] Demo challenge linking
- [ ] Demo engagement features
- [ ] Show real-time updates
- [ ] Review performance

---

## Firestore Schema Verification

**New Collections Created:**
1. ✅ `group_updates` - Updates feed
2. ✅ `update_comments` - Comments on updates

**Indexes Required:**
```json
{
  "indexes": [
    {
      "collectionGroup": "group_updates",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "isPinned", "order": "DESCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "update_comments",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "updateId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

**Security Rules Required:**
```javascript
match /group_updates/{updateId} {
  allow read: if isGroupMember(resource.data.groupId);
  allow create: if isAuthenticated() && 
                  isGroupMember(request.resource.data.groupId);
  allow update: if isAuthenticated() && 
                  (resource.data.authorCpId == request.auth.uid ||
                   isGroupAdmin(resource.data.groupId));
  allow delete: if isAuthenticated() && 
                  (resource.data.authorCpId == request.auth.uid ||
                   isGroupAdmin(resource.data.groupId));
}

match /update_comments/{commentId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update: if isAuthenticated() && 
                  resource.data.authorCpId == request.auth.uid;
  allow delete: if isAuthenticated() && 
                  (resource.data.authorCpId == request.auth.uid ||
                   isGroupAdmin(resource.data.groupId));
}
```

---

## Integration Requirements

**External System Dependencies:**
1. **Followup System:** Must have API to access user's followup entries
2. **Milestone System:** Must have API to access user achievements
3. **Image Upload:** Firebase Storage integration
4. **Notifications:** FCM for update notifications

**Action Items Before Sprint Start:**
- [ ] Verify followup system API access
- [ ] Confirm milestone system integration points
- [ ] Test Firebase Storage permissions
- [ ] Review notification system capacity

---

**Sprint 6 Status:** 📋 READY TO START

**Dependencies:** Sprint 5 completed, Followup system API available

