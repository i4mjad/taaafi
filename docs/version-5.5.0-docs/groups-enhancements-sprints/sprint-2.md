# Sprint 2: Member Management Enhancements (2 weeks)

**Sprint Goal:** Improve member management tools and insights for admins

**Duration:** 2 weeks  
**Priority:** MEDIUM  
**Dependencies:** Sprint 1 completed

---

## Feature 2.1: Member Activity Insights

**User Story:** As a group admin, I want to see member activity insights so that I can identify inactive members and engagement levels.

### Technical Tasks

#### Backend Tasks

**Task 2.1.1: Add Activity Tracking to Messages**
- **File:** `lib/features/groups/data/datasources/group_messages_firestore_datasource.dart`
- **Actions:**
  1. Update `sendMessage` to record last activity
  2. Update communityProfile's `lastActiveInGroup` field
  3. Use Firestore transaction
- **Estimated Time:** 2 hours

**Task 2.1.2: Add Activity Tracking to Membership**
- **File:** `lib/features/groups/data/models/group_membership_model.dart`
- **Actions:**
  1. Add `lastActiveAt` field (optional, nullable)
  2. Add `messageCount` field (default 0)
  3. Add `engagementScore` field (calculated, default 0)
  4. Update `fromFirestore` and `toFirestore` methods
- **Estimated Time:** 1 hour

**Task 2.1.3: Update Entity**
- **File:** `lib/features/groups/domain/entities/group_membership_entity.dart`
- **Actions:**
  1. Add `lastActiveAt` property
  2. Add `messageCount` property
  3. Add `engagementScore` property
  4. Update `copyWith` method
  5. Add computed property `isInactive` (> 7 days)
- **Estimated Time:** 1 hour

**Task 2.1.4: Create Activity Service**
- **File:** `lib/features/groups/domain/services/group_activity_service.dart` (new file)
- **Methods:**
  1. `updateMemberActivity(String groupId, String cpId)` - called on any activity
  2. `calculateEngagementScore(GroupMembershipEntity member)` - calculate score
  3. `getInactiveMembers(String groupId, int days)` - get inactive list
  4. `getMemberActivityStats(String groupId, String cpId)` - get stats
- **Engagement Score Formula:**
  - Base: messageCount × 2
  - Bonus: +10 for active in last 24 hours
  - Bonus: +5 for active in last 7 days
  - Penalty: -5 for inactive > 7 days
- **Estimated Time:** 4 hours

**Task 2.1.5: Add Repository Methods**
- **File:** `lib/features/groups/domain/repositories/groups_repository.dart`
- **Methods to Add:**
```dart
/// Get members with activity data
Future<List<GroupMembershipEntity>> getMembersWithActivity(String groupId);

/// Get inactive members (not active for X days)
Future<List<GroupMembershipEntity>> getInactiveMembers(
  String groupId,
  int inactiveDays,
);

/// Update member last active timestamp
Future<void> updateMemberActivity(String groupId, String cpId);
```
- **Estimated Time:** 2 hours

**Task 2.1.6: Implement Repository Methods**
- **File:** `lib/features/groups/data/repositories/groups_repository_impl.dart`
- **Actions:**
  1. Implement all activity-related methods
  2. Add proper error handling
  3. Optimize queries for performance
- **Estimated Time:** 3 hours

**Task 2.1.7: Create Background Activity Updater**
- **File:** `lib/features/groups/application/group_activity_updater.dart` (new file)
- **Actions:**
  1. Listen to message events
  2. Update lastActiveAt automatically
  3. Increment messageCount
  4. Recalculate engagement score
- **Estimated Time:** 2 hours

#### Frontend Tasks

**Task 2.1.8: Create Activity Insights Provider**
- **File:** `lib/features/groups/providers/group_activity_provider.dart` (new file)
- **Providers:**
  1. `groupMembersWithActivityProvider(groupId)` - members with activity data
  2. `inactiveMembersProvider(groupId, days)` - inactive members list
  3. `memberEngagementStatsProvider(groupId)` - overall stats
- **Estimated Time:** 2 hours

**Task 2.1.9: Update Member List Widget**
- **File:** `lib/features/groups/presentation/widgets/group_members_list.dart`
- **Actions:**
  1. Add activity indicator (green dot if active in 24h)
  2. Add "Last active" timestamp
  3. Add message count display
  4. Add engagement badge (high/medium/low)
  5. Sort options: by activity, by engagement
- **UI Changes:**
  - Add activity status indicator
  - Show "Active now", "Active 2h ago", etc.
  - Show message count with icon
  - Add filter: "Show inactive only"
- **Estimated Time:** 4 hours

**Task 2.1.10: Create Activity Insights Screen**
- **File:** `lib/features/groups/presentation/screens/group_activity_insights_screen.dart` (new file)
- **Sections:**
  1. **Overview Cards:**
     - Total active members (last 7 days)
     - Total inactive members (> 7 days)
     - Average engagement score
     - Most active member
  2. **Activity List:**
     - All members sorted by activity
     - Show last active time
     - Show message count
     - Show engagement score
  3. **Inactive Members Alert:**
     - Highlighted list of inactive members
     - "X members haven't been active in 7+ days"
     - Quick action to send reminder
- **Estimated Time:** 5 hours

**Task 2.1.11: Integrate into Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Activity Insights" card for admins
  2. Show preview: "X active, Y inactive"
  3. Navigate to full insights screen
- **Estimated Time:** 1 hour

#### Localization Tasks

**Task 2.1.12: Add Localization Keys**
- **Keys to Add:**
```json
{
  "activity-insights": "Activity Insights",
  "member-activity": "Member Activity",
  "active-members": "Active Members",
  "inactive-members": "Inactive Members",
  "last-active": "Last Active",
  "message-count": "Messages",
  "engagement-score": "Engagement",
  "active-now": "Active now",
  "active-recently": "Active {time} ago",
  "inactive-for-days": "Inactive for {days} days",
  "never-active": "Never active",
  "high-engagement": "High Engagement",
  "medium-engagement": "Medium Engagement",
  "low-engagement": "Low Engagement",
  "most-active-member": "Most Active Member",
  "average-engagement": "Average Engagement",
  "inactive-warning": "{count} members haven't been active in 7+ days",
  "sort-by-activity": "Sort by Activity",
  "sort-by-engagement": "Sort by Engagement",
  "show-inactive-only": "Show Inactive Only"
}
```
- **Estimated Time:** 1 hour

#### Testing Tasks

**Task 2.1.13: Unit Tests**
- **Test Cases:**
  1. Activity timestamp updates on message send
  2. Message count increments correctly
  3. Engagement score calculated correctly
  4. Inactive members filtered correctly
  5. Activity service methods work
- **Estimated Time:** 4 hours

**Task 2.1.14: Integration Tests**
- **Test Cases:**
  1. Send message → activity updates
  2. UI shows correct activity status
  3. Sorting works correctly
  4. Filters work
- **Estimated Time:** 2 hours

**Task 2.1.15: Manual Testing Checklist**
- [ ] Activity updates when message sent
- [ ] Last active shows correct time
- [ ] Message counts accurate
- [ ] Engagement scores reasonable
- [ ] Activity indicators display correctly
- [ ] Sorting by activity works
- [ ] Sorting by engagement works
- [ ] Inactive filter works
- [ ] Insights screen shows accurate data
- [ ] Performance acceptable with 50 members
- **Estimated Time:** 2 hours

### Deliverables

- [ ] Activity tracking implemented
- [ ] Engagement scoring working
- [ ] Member list shows activity data
- [ ] Activity insights screen complete
- [ ] All tests passing
- [ ] Performance optimized

---

## Feature 2.2: Bulk Member Management

**User Story:** As a group admin, I want to perform bulk actions on members so that I can manage the group more efficiently.

### Technical Tasks

#### Backend Tasks

**Task 2.2.1: Add Bulk Operation Methods**
- **File:** `lib/features/groups/domain/repositories/groups_repository.dart`
- **Methods to Add:**
```dart
/// Promote multiple members to admin
Future<BulkOperationResult> bulkPromoteMembersToAdmin({
  required String groupId,
  required String adminCpId,
  required List<String> memberCpIds,
});

/// Remove multiple members from group
Future<BulkOperationResult> bulkRemoveMembers({
  required String groupId,
  required String adminCpId,
  required List<String> memberCpIds,
});

/// Export member list with stats
Future<String> exportMemberList({
  required String groupId,
  required String adminCpId,
  bool includeInactive = false,
});
```
- **Estimated Time:** 1 hour

**Task 2.2.2: Create Bulk Operation Result Entity**
- **File:** `lib/features/groups/domain/entities/bulk_operation_result.dart` (new file)
- **Properties:**
```dart
class BulkOperationResult {
  final int successCount;
  final int failureCount;
  final List<String> failedCpIds;
  final List<String> failureReasons;
  final bool allSucceeded;
}
```
- **Estimated Time:** 30 minutes

**Task 2.2.3: Implement Bulk Operations**
- **File:** `lib/features/groups/data/repositories/groups_repository_impl.dart`
- **Actions:**
  1. Verify admin permissions first
  2. Loop through each member
  3. Try operation, catch errors
  4. Track successes and failures
  5. Return detailed result
  6. Use batched writes for performance
- **Validations:**
  - Max 20 members per bulk operation
  - Cannot remove/demote group creator
  - Cannot operate on yourself
- **Estimated Time:** 5 hours

**Task 2.2.4: Create Export Service**
- **File:** `lib/features/groups/domain/services/group_export_service.dart` (new file)
- **Actions:**
  1. Generate CSV with member data
  2. Include: name, role, joined date, last active, message count, engagement
  3. Save to temporary file
  4. Return file path
- **Dependencies:** Add `csv` package to pubspec.yaml
- **Estimated Time:** 3 hours

#### Frontend Tasks

**Task 2.2.5: Add Selection Mode to Member List**
- **File:** `lib/features/groups/presentation/widgets/group_members_list.dart`
- **Actions:**
  1. Add selection mode toggle
  2. Add checkboxes to member items
  3. Add "Select All" button
  4. Show selected count
  5. Add bottom action bar when items selected
- **Estimated Time:** 4 hours

**Task 2.2.6: Create Bulk Actions Bottom Sheet**
- **File:** `lib/features/groups/presentation/widgets/bulk_member_actions_modal.dart` (new file)
- **Actions Available:**
  1. Promote to Admin (if all selected are members)
  2. Remove from Group
  3. Export Selected
- **UI Elements:**
  - Action list
  - Confirmation dialog for destructive actions
  - Progress indicator during operation
  - Result summary after completion
- **Estimated Time:** 3 hours

**Task 2.2.7: Create Export Dialog**
- **File:** `lib/features/groups/presentation/widgets/export_members_dialog.dart` (new file)
- **Options:**
  1. Include inactive members checkbox
  2. Export format (CSV only for now)
  3. Export button
  4. Share functionality
- **Estimated Time:** 2 hours

**Task 2.2.8: Create Bulk Operation Result Screen**
- **File:** `lib/features/groups/presentation/widgets/bulk_operation_result_modal.dart` (new file)
- **Display:**
  1. Success count with checkmark
  2. Failure count with X
  3. List of failed operations with reasons
  4. "Done" button
- **Estimated Time:** 2 hours

**Task 2.2.9: Update Group Settings**
- **File:** `lib/features/groups/presentation/screens/group_settings_screen.dart`
- **Actions:**
  1. Add "Export Members" button for admins
  2. Navigate to export dialog
- **Estimated Time:** 1 hour

#### Localization Tasks

**Task 2.2.10: Add Localization Keys**
- **Keys to Add:**
```json
{
  "bulk-actions": "Bulk Actions",
  "select-members": "Select Members",
  "selected-count": "{count} selected",
  "select-all": "Select All",
  "deselect-all": "Deselect All",
  "bulk-promote": "Promote Selected to Admin",
  "bulk-remove": "Remove Selected Members",
  "export-selected": "Export Selected",
  "export-all-members": "Export All Members",
  "include-inactive-members": "Include Inactive Members",
  "confirm-bulk-promote": "Are you sure you want to promote {count} members to admin?",
  "confirm-bulk-remove": "Are you sure you want to remove {count} members from the group?",
  "bulk-operation-in-progress": "Processing {current} of {total}...",
  "bulk-operation-complete": "Operation Complete",
  "bulk-success-summary": "{successCount} succeeded, {failureCount} failed",
  "bulk-failures-title": "Failed Operations",
  "export-members": "Export Members",
  "export-format": "Export Format",
  "export-generating": "Generating export...",
  "export-ready": "Export ready to share",
  "cannot-bulk-operate-creator": "Cannot perform bulk operations on group creator",
  "max-bulk-selection": "Maximum 20 members can be selected for bulk operations"
}
```
- **Estimated Time:** 1 hour

#### Testing Tasks

**Task 2.2.11: Unit Tests**
- **Test Cases:**
  1. Bulk promote succeeds for valid members
  2. Bulk remove succeeds for valid members
  3. Partial success tracked correctly
  4. Creator protection works
  5. Max 20 member limit enforced
  6. Export generates valid CSV
  7. Export includes correct data
- **Estimated Time:** 4 hours

**Task 2.2.12: Integration Tests**
- **Test Cases:**
  1. Select members → perform action → see result
  2. Export → share → verify file
  3. Partial failure shows correct UI
- **Estimated Time:** 2 hours

**Task 2.2.13: Manual Testing Checklist**
- [ ] Selection mode activates correctly
- [ ] Checkboxes work
- [ ] Select all works
- [ ] Bottom action bar appears
- [ ] Actions disabled for invalid selections
- [ ] Confirmation dialogs show
- [ ] Progress indicator works
- [ ] Result summary accurate
- [ ] Export generates valid CSV
- [ ] Share functionality works
- [ ] Cannot select more than 20
- [ ] Creator protected from bulk actions
- **Estimated Time:** 2 hours

### Deliverables

- [ ] Selection mode implemented
- [ ] Bulk operations working
- [ ] Export functionality complete
- [ ] Result feedback clear
- [ ] All tests passing
- [ ] Performance acceptable

---

## Sprint 2 Summary

**Total Estimated Time:** 10 working days (2 weeks)

**Sprint Deliverables:**
- [ ] Activity insights visible to admins
- [ ] Member list shows activity data
- [ ] Bulk selection mode working
- [ ] Bulk operations functional
- [ ] Member export working
- [ ] All tests passing

**Sprint Review Checklist:**
- [ ] Demo activity insights
- [ ] Demo bulk operations
- [ ] Demo export functionality
- [ ] Show error handling
- [ ] Review performance with 50 members
- [ ] Review test coverage

